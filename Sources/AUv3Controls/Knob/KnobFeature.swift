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
    let id: UInt64
    let config: KnobConfig
    let parameter: AUParameter?
    let normValueTransform: NormValueTransform
    var control: ControlFeature.State
    var editor: EditorFeature.State
    var scrollToDestination: UInt64?
    let valueObservationCancelId: String?
    var observerToken: AUParameterObserverToken?

    public init(parameter: AUParameter,
                formatter: KnobValueFormatter = .general(),
                config: KnobConfig = .default
    ) {
      let normValueTransform: NormValueTransform = .init(parameter: parameter)
      self.id = parameter.address
      self.config = config
      self.parameter = parameter
      self.normValueTransform = normValueTransform
      self.valueObservationCancelId = "valueObservationCancelId[AUParameter: \(parameter.address)])"
      self.control = .init(
        displayName: parameter.displayName,
        value: Double(parameter.value),
        normValueTransform: normValueTransform,
        formatter: formatter,
        config: config
      )
      self.editor = .init(displayName: parameter.displayName, formatter: formatter)
    }

    public init(
      value: Double,
      displayName: String,
      minimumValue: Double,
      maximumValue: Double,
      logarithmic: Bool,
      formatter: KnobValueFormatter = .general(1...4),
      config: KnobConfig = .default
    ) {
      let normValueTransform: NormValueTransform = .init(
        minimumValue: minimumValue,
        maximumValue: maximumValue,
        logScale: logarithmic
      )
      self.id = UUID().asUInt64
      self.config = config
      self.parameter = nil
      self.normValueTransform = normValueTransform
      self.valueObservationCancelId = nil
      self.control = .init(
        displayName: displayName,
        value: value,
        normValueTransform: normValueTransform,
        formatter: formatter,
        config: config
      )
      self.editor = .init(displayName: displayName, formatter: formatter)
    }
  }

  public enum Action: Equatable, Sendable {
    case control(ControlFeature.Action)
    case editor(EditorFeature.Action)
    case observedValueChanged(AUValue)
    case performScrollTo(UInt64?)
    case stopValueObservation
    case task
  }

  // Only used for unit tests
  private let parameterValueChanged: ((AUParameterAddress) -> Void)?

  public init(parameterValueChanged: ((AUParameterAddress) -> Void)? = nil) {
    self.parameterValueChanged = parameterValueChanged
  }

  public var body: some Reducer<State, Action> {
    Scope(state: \.control, action: \.control) { ControlFeature() }
    Scope(state: \.editor, action: \.editor) { EditorFeature() }

    Reduce { state, action in
      switch action {
      case .control(let controlAction): return controlChanged(&state, action: controlAction)
      case .editor(let editorAction): return editValue(&state, action: editorAction)
      case .observedValueChanged(let value): return reduce(into: &state, action: .control(.valueChanged(Double(value))))
      case .performScrollTo(let id): return scrollTo(&state, id: id)
      case .stopValueObservation: return stopObserving(&state)
      case .task: return startObserving(&state)
      }
    }
  }
}

private extension KnobFeature {

  func controlChanged(_ state: inout State, action: ControlFeature.Action) -> Effect<Action> {
    switch action {
    case .track(let trackAction): return trackChanged(&state, action: trackAction)
    case .title(let titleAction) where titleAction == .titleTapped: return showEditor(&state)
    default: return .none
    }
  }

  func editValue(_ state: inout State, action: EditorFeature.Action) -> Effect<Action> {
    guard
      action == .acceptButtonTapped,
      let editorValue = Double(state.editor.value)
    else {
      return .none
    }
    let value = state.normValueTransform.normToValue(state.normValueTransform.valueToNorm(editorValue))
    print("editValue:", editorValue, value)
    return .merge(
      setParameterEffect(state: state, value: value, cause: .value),
      reduce(into: &state, action: .control(.valueChanged(Double(value))))
    )
  }

  func scrollTo(_ state: inout State, id: UInt64?) -> Effect<Action> {
    state.scrollToDestination = id
    return .none
  }

  func showEditor(_ state: inout State) -> Effect<Action> {
    let value = state.normValueTransform.normToValue(state.control.track.norm)
    return reduce(into: &state, action: .editor(.beginEditing(value)))
  }

  func startObserving(_ state: inout State) -> Effect<Action> {
    guard
      let parameter = state.parameter,
      let valueObservationCancelId = state.valueObservationCancelId
    else {
      return .none
    }
    let duration = state.config.debounceDuration
    let stream: AsyncStream<AUValue>
    (state.observerToken, stream) = parameter.startObserving()
    return .run { send in
      for await value in stream.debounce(for: duration) {
        await send(.observedValueChanged(value))
      }
    }.cancellable(id: valueObservationCancelId, cancelInFlight: true)
  }

  func stopObserving(_ state: inout State) -> Effect<Action> {
    guard
      let token = state.observerToken,
      let parameter = state.parameter,
      let valueObservationCancelId = state.valueObservationCancelId
    else {
      return .none
    }

    parameter.removeParameterObserver(token)
    state.observerToken = nil
    return .merge(
      .cancel(id: valueObservationCancelId),
      reduce(into: &state, action: .control(.title(.cancelValueDisplayTimer)))
    )
  }

  func setParameterEffect(
    state: State,
    value: Double,
    cause: AUParameterAutomationEventType?
  ) -> Effect<Action> {
    guard let cause,
          let parameter = state.parameter
    else {
      return .none
    }
    let newValue = AUValue(value)
    if parameter.value != newValue {
      parameter.setValue(newValue, originator: state.observerToken, atHostTime: 0, eventType: cause)
      parameterValueChanged?(parameter.address)
    }
    return .none
  }

  func trackChanged(_ state: inout State, action: TrackFeature.Action) -> Effect<Action> {
    let value = state.normValueTransform.normToValue(state.control.track.norm)
    return setParameterEffect(state: state, value: value, cause: action.cause)
  }
}

public struct KnobView: View {
  private let store: StoreOf<KnobFeature>
  private var config: KnobConfig { store.config }

  @Environment(\.scrollViewProxy) var proxy: ScrollViewProxy?

#if os(macOS)
  private let showBinding: Binding<Bool>
#endif

  public init(store: StoreOf<KnobFeature>) {
    self.store = store
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
      ControlView(store: store.scope(state: \.control, action: \.control))
        .visible(when: !store.editor.hasFocus)
      EditorView(store: store.scope(state: \.editor, action: \.editor))
        .visible(when: store.editor.hasFocus)
    }
    .frame(maxWidth: config.controlWidthIf(store.editor.focus), maxHeight: config.controlHeight)
    .frame(width: config.controlWidthIf(store.editor.focus), height: config.controlHeight)
    .task { await store.send(.task).finish() }
    .onDisappear { store.send(.stopValueObservation) }
    .onChange(of: store.editor.hasFocus) { _, newValue in
      guard newValue, let proxy else { return }
      store.send(.performScrollTo(store.id))
    }
    .onChange(of: store.scrollToDestination) { _, newValue in
      guard let newValue, let proxy = proxy else { return }
      withAnimation {
        proxy.scrollTo(newValue)
      }
      store.send(.performScrollTo(nil))
    }
    .id(store.id)
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
    unit: .percent,
    unitName: "%",
    valueStrings: nil,
    dependentParameters: nil
  )
  static let config = KnobConfig()
  static var store = Store(initialState: KnobFeature.State(parameter: param, config: config)) {
    KnobFeature()
  }

  static var previews: some View {
    VStack {
      KnobView(store: store)
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
