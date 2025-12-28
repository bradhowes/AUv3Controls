// Copyright © 2025 Brad Howes. All rights reserved.

import AsyncAlgorithms
import AVFoundation
import ComposableArchitecture
import Sharing
import SwiftUI

/**
 A modern rotary knob that shows and controls the floating-point value of an associated AUParameter.

 The knob control consists of three child features:

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
  /// Formatters to use in the knob presentations
  let formatter: any KnobValueFormattingProvider
  /// Value transformations to/from a normalized value
  let normValueTransform: NormValueTransform
  /// Delay to wait for new internal value change events before emitting one.
  let debounceMilliseconds: Int
  /// Duration to show new value in title before reverting to showing title
  let showValueMilliseconds: Int

  // Only used for unit tests
  private let parameterValueChanged: ((AUParameterAddress) -> Void)?

  /**
   Create feature based on a AUParameter definition.

   - parameter parameter: the AUParameter to use
   */
  public init(parameter: AUParameter) {
    self.formatter = KnobValueFormatter.for(parameter.unit)
    self.normValueTransform = .init(parameter: parameter)
    self.debounceMilliseconds = KnobConfig.default.debounceMilliseconds
    self.showValueMilliseconds = KnobConfig.default.showValueMilliseconds
    self.parameterValueChanged = nil
  }

  /**
   Create feature that is not based on an AUParameter.

   - parameter formatter: the value formatter to use when displaying numeric values as text
   - parameter normValueTransform: the ``NormValueTransform`` to use to convert between user values and normalized
   values in range [0-1].
   - parameter debounceMilliseconds: the duration to wait for another value before processing a value from an
   AUParameter.
   - parameter parameterValueChanged: closure invoked when control receives a value from AUParameter. Only used by
   tests.
   */
  public init(
    formatter: any KnobValueFormattingProvider,
    normValueTransform: NormValueTransform,
    debounceMilliseconds: Int = KnobConfig.default.debounceMilliseconds,
    showValueMilliseconds: Int = KnobConfig.default.showValueMilliseconds,
    parameterValueChanged: ((AUParameterAddress) -> Void)? = nil
  ) {
    self.formatter = formatter
    self.normValueTransform = normValueTransform
    self.debounceMilliseconds = debounceMilliseconds
    self.showValueMilliseconds = showValueMilliseconds
    self.parameterValueChanged = parameterValueChanged
  }

  @ObservableState
  public struct State: Equatable {
    public let id: UInt64
    public let parameter: AUParameter?
    public let valueObservationCancelId: String?
    public let displayName: String

    public var track: TrackFeature.State
    public var title: TitleFeature.State
    public var scrollToDestination: UInt64?

    @Shared(.valueEditorInfo) var valueEditorInfo
    @ObservationStateIgnored public var observerToken: AUParameterObserverToken?

    /**
     Initialze reducer with values from AUParameter definition.

     - parameter parameter: the `AUParameter` to use
     */
    public init(parameter: AUParameter) {
      let normValueTransform: NormValueTransform = .init(parameter: parameter)
      self.id = parameter.address
      self.parameter = parameter
      self.valueObservationCancelId = "valueObservationCancelId[AUParameter: \(parameter.address)])"
      self.displayName = parameter.displayName
      self.title = .init(displayName: parameter.displayName)
      self.track = .init(norm: normValueTransform.valueToNorm(Double(parameter.value)))
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
      self.valueObservationCancelId = nil
      self.displayName = displayName
      self.track = .init(norm: normValueTransform.valueToNorm(value))
      self.title = .init(displayName: displayName)
    }
  }

  public enum Action: BindableAction, Equatable, Sendable {
    case binding(BindingAction<State>)
    case editorDismissed(String?)
    case observedValueChanged(AUValue)
    case performScrollTo(UInt64?)
    case setValue(Double)
    case stopValueObservation
    case task
    case title(TitleFeature.Action)
    case track(TrackFeature.Action)
    case valueChanged(Double)
  }

  public var body: some Reducer<State, Action> {
    BindingReducer()

    Scope(state: \.track, action: \.track) { TrackFeature(normValueTransform: normValueTransform) }
    Scope(state: \.title, action: \.title) { TitleFeature(formatter: formatter, showValueMilliseconds: showValueMilliseconds ) }

    Reduce { state, action in
      switch action {
      case .binding: return .none
      case let .editorDismissed(value): return editorDismissed(&state, value: value)
      case let .observedValueChanged(value): return valueChanged(&state, value: Double(value))
      case .performScrollTo(let id): return scrollTo(&state, id: id)
      case let .setValue(value): return setValue(&state, value: value)
      case .stopValueObservation: return stopObserving(&state)
      case .task: return startObserving(&state)
      case .title(let action): return monitorTitleAction(&state, action: action)
      case .track(let action): return .concatenate(monitorTrackAction(&state, action: action), trackChanged(&state, action: action))
      case .valueChanged(let value): return valueChanged(&state, value: value)
      }
    }
  }
}

private extension KnobFeature {

  func editorDismissed(_ state: inout State, value: String?) -> Effect<Action> {
    state.scrollToDestination = nil
    state.$valueEditorInfo.withLock { $0 = nil }
    if let value,
       let editorValue = Double(value) {
      let newValue = normValueTransform.normToValue(normValueTransform.valueToNorm(editorValue))
      return .merge(
        setParameterEffect(state: state, value: newValue, cause: .value),
        valueChanged(&state, value: newValue)
      )
    }
    return .none
  }

  func monitorTitleAction(_ state: inout State, action: TitleFeature.Action) -> Effect<Action> {
    if case .titleTapped(let theme) = action {
      return showEditor(&state, theme: theme)
    }
    return .none
  }

  func monitorTrackAction(_ state: inout State, action: TrackFeature.Action) -> Effect<Action> {
    switch action {
    case .dragStarted: return reduce(into: &state, action: .title(.dragActive(true)))
    case .dragChanged: return showValue(&state)
    case .dragEnded: return reduce(into: &state, action: .title(.dragActive(false)))
    case .normChanged(_): return .none
    case .valueChanged(_): return .none
    case .viewTapped: return showValue(&state)
    }
  }

  func scrollTo(_ state: inout State, id: UInt64?) -> Effect<Action> {
    state.scrollToDestination = id
    return .none
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
    return valueChanged(&state, value: value)
  }

  func showEditor(_ state: inout State, theme: Theme) -> Effect<Action> {
    let value = normValueTransform.normToValue(state.track.norm)
    state.$valueEditorInfo.withLock {
      $0 = .init(
        id: state.id,
        displayName: state.displayName,
        value: formatter.forEditing(value),
        theme: theme
      )
    }
    return .none
  }

  func showValue(_ state: inout State) -> Effect<Action> {
    let value = normValueTransform.normToValue(state.track.norm)
    return reduce(into: &state, action: .title(.valueChanged(value)))
  }

  func startObserving(_ state: inout State) -> Effect<Action> {
    guard
      let parameter = state.parameter,
      let valueObservationCancelId = state.valueObservationCancelId
    else {
      return .none
    }

    let stream: AsyncStream<AUValue>
    (state.observerToken, stream) = parameter.startObserving()

    return .run { [duration = debounceMilliseconds] send in
      if Task.isCancelled { return }
      for await value in stream.debounce(for: .milliseconds(duration)) {
        if Task.isCancelled { break }
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

    // This will tear down the AsyncStream since it causes the stream's continuation value to go out of scope. It should also
    // cause the Task created to monitor the stream to stop, but we cancel it anyway just to be safe.
    parameter.removeParameterObserver(token)
    state.observerToken = nil

    return .merge(
      .cancel(id: valueObservationCancelId),
      reduce(into: &state, action: .title(.valueDisplayTimerFired))
    )
  }

  func trackChanged(_ state: inout State, action: TrackFeature.Action) -> Effect<Action> {
    let value = normValueTransform.normToValue(state.track.norm)
    return setParameterEffect(state: state, value: value, cause: action.cause)
  }

  func valueChanged(_ state: inout State, value: Double) -> Effect<Action> {
    return .merge(
      reduce(into: &state, action: .title(.valueChanged(value))),
      reduce(into: &state, action: .track(.valueChanged(value)))
    )
  }
}

public struct KnobView: View {
  @Bindable private var store: StoreOf<KnobFeature>
  @Environment(\.isEnabled) var enabled
  @Environment(\.auv3ControlsTheme) var theme
  @Environment(\.scrollViewProxy) var proxy: ScrollViewProxy?

  public init(store: StoreOf<KnobFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(alignment: .center, spacing: -8) {
      TrackView(store: store.scope(state: \.track, action: \.track))
      TitleView(store: store.scope(state: \.title, action: \.title))
    }
    .task { await store.send(.task).finish() }
    .onChange(of: store.valueEditorInfo) {
      if let info = store.valueEditorInfo,
         info.id == store.id,
         case .dismissed(let value) = info.action {
        store.send(.editorDismissed(value))
      }
    }
    .onChange(of: store.scrollToDestination) { _, newValue in
      guard let newValue, let proxy = proxy else { return }
      withAnimation {
        proxy.scrollTo(newValue)
      }
    }
    .id(store.id)
  }
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
  static var store = Store(initialState: KnobFeature.State(parameter: param)) {
    KnobFeature(formatter: KnobValueFormatter.general(), normValueTransform: .init(parameter: param))
  }

  static var previews: some View {
    NavigationStack {
      VStack {
        KnobView(store: store)
          .frame(width: 140, height: 140)
          .padding([.top, .bottom], 16)
        Text("observedValueChanged:")
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
#if useCustomAlert
      .knobCustomValueEditorHost()
#elseif useNativeAlert
      .knobNativeValueEditorHost()
#else
      .knobValueEditorHost()
#endif
    }
  }
}
