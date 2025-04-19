import AsyncAlgorithms
import AVFoundation
import ComposableArchitecture
import SwiftUI

/***
 A modern rotary knob that shows and controls the floating-point value of an associated AUParameter. The knob control
 consists of three components:

 - circular indicator representing the current value and that reponds to touch/nouse drags for value changes
 - title label that shows the name of the control and that temporarily shows the current value when it changes
 - value editor that appears when tapping/mouse clicking on the title

 On iOS platforms, the editor will replace the knob control while it is active. On macOS, the editor appears as a modal
 dialog. The functionality is the same otherwise.
 */
@Reducer
public struct KnobFeature {

  @ObservableState
  public struct State: Equatable {
    let config: KnobConfig
    let valueObservationCancelId: String
    var control: ControlFeature.State
    var editor: EditorFeature.State
    var observerToken: AUParameterObserverToken?
    var scrollToDestination: UInt64?

    public init(config: KnobConfig) {
      self.config = config
      self.valueObservationCancelId = "valueObservationCancelId[AUParameter: \(config.id)])"
      self.control = .init(config: config, value: Double(config.parameter.value))
      self.editor = .init(config: config)
    }
  }

  public enum Action: Equatable, Sendable {
    case control(ControlFeature.Action)
    case editor(EditorFeature.Action)
    case performScrollTo(UInt64?)
    case observedValueChanged(AUValue)
    case stopValueObservation
    case task
  }

  public init() {}

  public var body: some Reducer<State, Action> {
    Scope(state: \.control, action: \.control) { ControlFeature() }
    Scope(state: \.editor, action: \.editor) { EditorFeature() }

    Reduce { state, action in

      switch action {

      case .control(let controlAction):
        switch controlAction {

          // Update the associated AUParameter when the track changes value
        case .track(let trackAction):
          let value = state.config.normToValue(state.control.track.norm)
          return setParameterEffect(state: state, value: value, cause: trackAction.cause)

          // Show the value editor when the title is tapped
        case .title(let titleAction) where titleAction == .titleTapped:
          let value = state.config.normToValue(state.control.track.norm)
          return reduce(into: &state, action: .editor(.beginEditing(value)))

        default:
          break
        }
        return .none

      case .editor(let editorAction):
        guard editorAction == .acceptButtonTapped else { return .none }
        guard let editorValue = Double(state.editor.value) else { return .none }
        let value = state.config.normToValue(state.config.valueToNorm(editorValue))
        return .merge(
          setParameterEffect(state: state, value: value, cause: .value),
          reduce(into: &state, action: .control(.valueChanged(Double(value))))
        )

      case .performScrollTo(let id):
        state.scrollToDestination = id
        return .none

      case .stopValueObservation:
        if let token = state.observerToken {
          state.config.parameter.removeParameterObserver(token)
          state.observerToken = nil
        }
        return .merge(
          .cancel(id: state.valueObservationCancelId),
          reduce(into: &state, action: .control(.title(.cancelValueDisplayTimer)))
        )

      case .task:
        let duration = state.config.debounceDuration
        let stream: AsyncStream<AUValue>
        (state.observerToken, stream) = state.config.parameter.startObserving()
        return .run { send in
          for await value in stream.debounce(for: duration) {
            await send(.observedValueChanged(value))
          }
        }.cancellable(id: state.valueObservationCancelId, cancelInFlight: true)

      case .observedValueChanged(let value):
        return reduce(into: &state, action: .control(.valueChanged(Double(value))))
      }
    }
  }
}

private extension KnobFeature {

  func setParameterEffect(state: State, value: Double, cause: AUParameterAutomationEventType?) -> Effect<Action> {
    guard let cause else { return .none }
    let parameter = state.config.parameter
    let newValue = AUValue(value)
    if parameter.value != newValue {
      parameter.setValue(newValue, originator: state.observerToken, atHostTime: 0, eventType: cause)
      state.config.theme.parameterValueChanged?(parameter.address)
    }
    return .none
  }
}

public struct KnobView: View {
  private let store: StoreOf<KnobFeature>
  private let proxy: ScrollViewProxy?
  private var config: KnobConfig { store.config }
#if os(macOS)
  private let showBinding: Binding<Bool>
#endif

  public init(store: StoreOf<KnobFeature>, proxy: ScrollViewProxy? = nil) {
    self.store = store
    self.proxy = proxy
#if os(macOS)
    self.showBinding = Binding<Bool>(
      get: { store.editor.hasFocus },
      set: { _ in }
    )
#endif
  }

#if os(iOS)
  public var body: some View {
    ZStack {
      ControlView(store: store.scope(state: \.control, action: \.control), config: config)
        .visible(when: !store.editor.hasFocus)
      EditorView(store: store.scope(state: \.editor, action: \.editor), config: config)
        .visible(when: store.editor.hasFocus)
    }
    .id(config.id)
    .frame(maxWidth: config.controlWidthIf(store.editor.focus), maxHeight: config.controlHeight)
    .frame(width: config.controlWidthIf(store.editor.focus), height: config.controlHeight)
    .task { await store.send(.task).finish() }
    .onDisappear { store.send(.stopValueObservation) }
    .onChange(of: store.editor.hasFocus) { _, newValue in
      if newValue && proxy != nil {
        store.send(.performScrollTo(config.id))
      }
    }
    .onChange(of: store.scrollToDestination) { _, newValue in
      if let newValue,
         let proxy = proxy {
        withAnimation {
          proxy.scrollTo(newValue)
        }
        store.send(.performScrollTo(nil))
      }
    }
  }
#elseif os(macOS)
  public var body: some View {
    ControlView(store: store.scope(state: \.control, action: \.control), config: config)
      .frame(maxWidth: config.controlDiameter, maxHeight: config.controlHeight)
      .frame(width: config.controlDiameter, height: config.controlHeight)
      .task { await store.send(.task).finish() }
      .onDisappear { store.send(.stopValueObservation) }
      .sheet(isPresented: showBinding) {
      } content: {
        EditorView(store: store.scope(state: \.editor, action: \.editor), config: config)
      }
  }
#endif
}

struct KnobViewPreview: PreviewProvider {
  static let param = AUParameterTree.createParameter(
    withIdentifier: "RELEASE",
    name: "Release",
    address: 1,
    min: 0.0,
    max: 100.0,
    unit: .generic,
    unitName: nil,
    valueStrings: nil,
    dependentParameters: nil
  )
  static let config = KnobConfig(parameter: param, theme: Theme())
  static var store = Store(initialState: KnobFeature.State(config: config)) {
    KnobFeature()
  }

  static var previews: some View {
    VStack {
      KnobView(store: store, proxy: nil)
      Button {
        store.send(.observedValueChanged(0.0))
      } label: {
        Text("Go to 0")
      }
      Button {
        store.send(.observedValueChanged(50.0))
      } label: {
        Text("Go to 50")
      }
      Button {
        store.send(.observedValueChanged(100.0))
      } label: {
        Text("Go to 100")
      }
    }
  }
}
