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
  private let config: KnobConfig
  private let controlFeature: ControlFeature
  private let editorFeature: EditorFeature

  public init(config: KnobConfig) {
    self.config = config
    self.controlFeature = ControlFeature(config: config)
    self.editorFeature = EditorFeature(config: config)
  }

  @ObservableState
  public struct State: Equatable {
    var control: ControlFeature.State
    var editor: EditorFeature.State
    var observerToken: AUParameterObserverToken?
    var scrollToDestination: UInt64?

    public init(config: KnobConfig) {
      self.control = .init(config: config, value: Double(config.parameter.value))
      self.editor = .init()
    }
  }

  public enum Action: Equatable, Sendable {
    case control(ControlFeature.Action)
    case editor(EditorFeature.Action)
    case performScrollTo(UInt64?)
    case observedValueChanged(AUValue)
    case startValueObservation
    case stopValueObservation
  }

  public var body: some Reducer<State, Action> {
    Scope(state: \.control, action: \.control) { controlFeature }
    Scope(state: \.editor, action: \.editor) { editorFeature }

    Reduce { state, action in

      switch action {

      case .control(let controlAction):
        switch controlAction {

          // Update the associated AUParameter when the track changes value
        case .track(let trackAction):
          let value = config.normToValue(state.control.track.norm)
          return setParameterEffect(state: state, value: value, cause: trackAction.cause)

          // Show the value editor when the title is tapped
        case .title(let titleAction) where titleAction == .titleTapped:
          let value = config.normToValue(state.control.track.norm)
          return beginEditingEffect(state: &state.editor, value: value)

        default:
          break
        }
        return .none

      case .editor(let editorAction):
        guard editorAction == .acceptButtonTapped else { return .none }
        guard let editorValue = Double(state.editor.value) else { return .none }
        let value = config.normToValue(config.valueToNorm(editorValue))
        return .merge(
          setParameterEffect(state: state, value: value, cause: .value),
          updateControlEffect(state: &state.control, value: value)
        )

      case .performScrollTo(let id):
        state.scrollToDestination = id
        return .none

      case .startValueObservation:
        let stream: AsyncStream<AUValue>
        (state.observerToken, stream) = config.parameter.startObserving()
        return .run { send in
          for await value in stream {
            await send(.observedValueChanged(value))
          }
          await send(.stopValueObservation)
        }.cancellable(id: config.id, cancelInFlight: true)

      case .stopValueObservation:
        if let token = state.observerToken {
          config.parameter.removeParameterObserver(token)
          state.observerToken = nil
        }
        return .merge(
          .cancel(id: config.id),
          cancelAnyTitleEffect(state: &state.control)
        )

      case .observedValueChanged(let value):
        return updateControlEffect(state: &state.control, value: Double(value))
      }
    }
  }
}

private extension KnobFeature {

  func cancelAnyTitleEffect(state: inout ControlFeature.State) -> Effect<Action> {
    controlFeature.reduce(into: &state, action: .title(.cancelValueDisplayTimer))
      .map(Action.control)
  }

  func updateControlEffect(state: inout ControlFeature.State, value: Double) -> Effect<Action> {
    controlFeature.reduce(into: &state, action: .valueChanged(value))
      .map(Action.control)
  }

  func beginEditingEffect(state: inout EditorFeature.State, value: Double) -> Effect<Action> {
    editorFeature.reduce(into: &state, action: .beginEditing(value))
      .map(Action.editor)
  }

  func setParameterEffect(state: State, value: Double, cause: AUParameterAutomationEventType?) -> Effect<Action> {
    guard let token = state.observerToken, let cause else { return .none }
    let parameter = config.parameter
    parameter.setValue(AUValue(value), originator: token, atHostTime: 0, eventType: cause)
    return .none
  }
}

public struct KnobView: View {
  private let store: StoreOf<KnobFeature>
  private let config: KnobConfig
  private let proxy: ScrollViewProxy?
#if os(macOS)
  private let showBinding: Binding<Bool>
#endif

  public init(store: StoreOf<KnobFeature>, config: KnobConfig, proxy: ScrollViewProxy? = nil) {
    self.store = store
    self.config = config
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
    .task { await store.send(.startValueObservation).finish() }
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
      .task { await store.send(.startValueObservation).finish() }
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
    KnobFeature(config: config)
  }

  static var previews: some View {
    VStack {
      KnobView(store: store, config: config, proxy: nil)
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
