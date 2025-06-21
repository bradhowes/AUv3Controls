// Copyright © 2025 Brad Howes. All rights reserved.

import AsyncAlgorithms
import AVFoundation
import ComposableArchitecture
import SwiftUI

/**
 A modern rotary knob that shows and controls the floating-point value of an associated AUParameter.

 The knob control consists of three components:

 - circular indicator representing the current value and that reponds to touch/nouse drags for value changes
 (``TrackFeature``)
 - title label that shows the name of the control and that temporarily shows the current value when it changes
 (``TitleFeature``)
 - value editor that appears when tapping/mouse clicking on the title
 (``EditorFeature``)

 On iOS platforms, the editor will replace the knob control while it is active. On macOS, the editor appears as a modal
 dialog. The functionality is the same otherwise.
 */
@Reducer
public struct KnobFeature {
  let formatter: any KnobValueFormattingProvider
  let normValueTransform: NormValueTransform
  let debounceMilliseconds: Int
  // Only used for unit tests
  private let parameterValueChanged: ((AUParameterAddress) -> Void)?

  /**
   Create feature state based on a AUParameter definition.

   - parameter parameter: the AUParameter to use
   */
  public init(
    parameter: AUParameter
  ) {
    self.formatter = KnobValueFormatter.for(parameter.unit)
    self.normValueTransform = .init(parameter: parameter)
    self.debounceMilliseconds = KnobConfig.default.debounceMilliseconds
    self.parameterValueChanged = nil
  }

  /**
   Create feature state that is not based on an AUParameter.

   - parameter formatter: the value formatter to use when displaying numeric values as text
   - parameter normValueTransform: the ``NormValueTransform`` to use to convert between user values and normalized
   values in range [0-1].
   - parameter debounceDuration: the number of seconds to wait for another value before processing a value from  an
   AUParameter.
   - parameter parameterValueChanged: closure invoked when control receives a value from AUParameter. Only used by
   tests.
   */
  public init(
    formatter: any KnobValueFormattingProvider,
    normValueTransform: NormValueTransform,
    debounceMilliseconds: Int = KnobConfig.default.debounceMilliseconds,
    parameterValueChanged: ((AUParameterAddress) -> Void)? = nil
  ) {
    self.formatter = formatter
    self.normValueTransform = normValueTransform
    self.debounceMilliseconds = debounceMilliseconds
    self.parameterValueChanged = parameterValueChanged
  }

  @ObservableState
  public struct State: Equatable {
    let id: UInt64
    let parameter: AUParameter?
    let normValueTransform: NormValueTransform
    let valueObservationCancelId: String?
    var control: ControlFeature.State
    var editor: EditorFeature.State
    var scrollToDestination: UInt64?
    var showingEditor: Bool = false

    @ObservationStateIgnored var observerToken: AUParameterObserverToken?

    public var value: Double {
      get { normValueTransform.normToValue(control.track.norm) }
    }

    /**
     Initialze reducer with values from AUParameter definition.

     - parameter parameter: the `AUParameter` to use
     */
    public init(parameter: AUParameter) {
      let normValueTransform: NormValueTransform = .init(parameter: parameter)
      self.id = parameter.address
      self.parameter = parameter
      self.normValueTransform = normValueTransform
      self.valueObservationCancelId = "valueObservationCancelId[AUParameter: \(parameter.address)])"
      self.control = .init(
        displayName: parameter.displayName,
        norm: normValueTransform.valueToNorm(Double(parameter.value))
      )
      self.editor = .init(displayName: parameter.displayName)
    }

    /**
     Initialize reducer.

     - parameter value: initial value to use in control
     - parameter displayName: the display name for the control
     - parameter minimumValue: the minimum value of the control
     - parameter maximumValue: the maximum value of the control
     - parameter logarithmic: if `true` the control works in the logarithmic scale
     */
    public init(
      value: Double,
      displayName: String,
      minimumValue: Double,
      maximumValue: Double,
      logarithmic: Bool
    ) {
      let normValueTransform: NormValueTransform = .init(
        minimumValue: minimumValue,
        maximumValue: maximumValue,
        logScale: logarithmic
      )
      self.id = UUID().asUInt64
      self.parameter = nil
      self.normValueTransform = normValueTransform
      self.valueObservationCancelId = nil
      self.control = .init(
        displayName: displayName,
        norm: normValueTransform.valueToNorm(value)
      )
      self.editor = .init(displayName: displayName)
    }
  }

  public enum Action: Equatable, Sendable {
    case control(ControlFeature.Action)
    case editor(EditorFeature.Action)
    case observedValueChanged(AUValue)
    case performScrollTo(UInt64?)
    case setValue(Double)
    case stopValueObservation
    case task
  }

  public var body: some Reducer<State, Action> {
    Scope(state: \.control, action: \.control) {
      ControlFeature(formatter: formatter, normValueTransform: normValueTransform)
    }
    Scope(state: \.editor, action: \.editor) { EditorFeature(formatter: formatter) }

    Reduce { state, action in
      switch action {
      case .control(let controlAction): return controlChanged(&state, action: controlAction)
      case .editor(let editorAction): return editorChanged(&state, action: editorAction)
      case let .observedValueChanged(value): return reduce(into: &state, action: .control(.valueChanged(Double(value))))
      case .performScrollTo(let id): return scrollTo(&state, id: id)
      case let .setValue(value): return setValue(&state, value: value)
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

  func editorChanged(_ state: inout State, action: EditorFeature.Action) -> Effect<Action> {
    switch action {
    case .acceptButtonTapped:
      if let editorValue = Double(state.editor.value) {
        let value = state.normValueTransform.normToValue(state.normValueTransform.valueToNorm(editorValue))
        state.showingEditor = false
        state.scrollToDestination = nil
        return .merge(
          setParameterEffect(state: state, value: value, cause: .value),
          reduce(into: &state, action: .control(.valueChanged(Double(value))))
        )
      }

    case .cancelButtonTapped:
      state.showingEditor = false
      state.scrollToDestination = nil
      return .none

    default:
      break
    }

    return .none
  }

  func setValue(_ state: inout State, value: Double) -> Effect<Action> {
    if let parameter = state.parameter,
       let observerToken = state.observerToken {
      parameter.setValue(
        Float(value),
        originator: observerToken,
        atHostTime: 0,
        eventType: .value
      )
    }
    return reduce(into: &state, action: .control(.valueChanged(value)))
  }

  func scrollTo(_ state: inout State, id: UInt64?) -> Effect<Action> {
    state.scrollToDestination = id
    return .none
  }

  func showEditor(_ state: inout State) -> Effect<Action> {
    state.showingEditor = true
    state.scrollToDestination = state.id
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
    let duration = debounceMilliseconds
    let stream: AsyncStream<AUValue>
    (state.observerToken, stream) = parameter.startObserving()
    return .run { send in
      for await value in stream.debounce(for: .milliseconds(duration)) {
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
    print("stopObserving: \(valueObservationCancelId)")
    return .merge(
      .cancel(id: valueObservationCancelId),
      reduce(into: &state, action: .control(.title(.valueDisplayTimerFired)))
    )
  }

  func setParameterEffect(state: State, value: Double, cause: AUParameterAutomationEventType?) -> Effect<Action> {
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
  @Environment(\.isEnabled) var enabled
  @Environment(\.auv3ControlsTheme) var theme
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
    ZStack(alignment: .top) {
      if store.showingEditor {
        EditorView(store: store.scope(state: \.editor, action: \.editor))
          .frame(width: theme.controlEditorWidth)
          .transition(.scale)
      } else {
        ControlView(store: store.scope(state: \.control, action: \.control))
          .transition(.scale)
      }
    }
    .task { await store.send(.task).finish() }
    .onChange(of: store.scrollToDestination) { _, newValue in
      guard let newValue, let proxy = proxy else { return }
      withAnimation {
        proxy.scrollTo(newValue)
      }
    }
    .id(store.id)
  }
#elseif os(macOS)
  public var body: some View {
    ControlView(store: store.scope(state: \.control, action: \.control))
      .task { await store.send(.task).finish() }
      .sheet(isPresented: showBinding) {
      } content: {
        EditorView(store: store.scope(state: \.editor, action: \.editor))
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
  static var store = Store(initialState: KnobFeature.State(parameter: param)) {
    KnobFeature(formatter: KnobValueFormatter.general(), normValueTransform: .init(parameter: param))
  }

  static var previews: some View {
    VStack {
      KnobView(store: store)
        .frame(width: 140, height: 140)
      Text("observerdValueChanged:")
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
      Text("setValue:")
      Button {
        store.send(.setValue(0.0))
      } label: {
        Text("Go to 0")
      }
      Button {
        store.send(.setValue(50.0))
      } label: {
        Text("Go to 50")
      }
      Button {
        store.send(.setValue(100.0))
      } label: {
        Text("Go to 100")
      }
    }
  }
}
