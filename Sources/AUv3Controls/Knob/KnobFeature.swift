// Copyright © 2025 Brad Howes. All rights reserved.

import AsyncAlgorithms
import AVFoundation
import ComposableArchitecture
import Sharing
import SwiftUI

/**
 A modern rotary knob that shows and controls the floating-point value of an associated AUParameter.

 The knob control consists of two child features:

 - circular indicator representing the current value and that reponds to touch/nouse drags for value changes
 (``TrackFeature``)
 - title label that shows the name of the control and that temporarily shows the current value when it changes
 (``TitleFeature``)

 */
@Reducer
public struct KnobFeature {

  @ObservableState
  public struct State: Equatable {
    public let id: UInt64
    public let parameter: AUParameter?
    public let valueObservationCancelId: String?
    public let displayName: String

    public var track: TrackFeature.State
    public var title: TitleFeature.State
    public var scrollToDestination: UInt64?

    @ObservationStateIgnored
    public let normValueTransform: NormValueTransform
    @ObservationStateIgnored
    public let formatter: KnobValueFormatter

    @Shared(.valueEditorInfo) var valueEditorInfo
    @ObservationStateIgnored public var observerToken: AUParameterObserverToken?

    @ObservationStateIgnored
    public var theme: Theme?

    @ObservationStateIgnored
    public var value: Double { normValueTransform.normToValue(track.norm) }

    /**
     Initialze reducer with values from AUParameter definition.

     - parameter parameter: the `AUParameter` to use
     - parameter formatter: optional KnobValueFormatter to use
     */
    public init(parameter: AUParameter, formatter: KnobValueFormatter? = nil) {
      self.id = parameter.address
      self.parameter = parameter
      self.valueObservationCancelId = "valueObservationCancelId[AUParameter: \(parameter.address)])"
      self.displayName = parameter.displayName

      let normValueTransform = NormValueTransform(parameter: parameter)
      self.normValueTransform = normValueTransform

      let formatter = formatter ?? KnobValueFormatter.for(parameter.unit)
      self.formatter = formatter

      self.title = .init(displayName: parameter.displayName, formatter: formatter)
      self.track = .init(normValueTransform: normValueTransform, norm: normValueTransform.valueToNorm(Double(parameter.value)))
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
      self.normValueTransform = normValueTransform
      let formatter = KnobValueFormatter.general()
      self.formatter = formatter
      self.id = UUID().asUInt64
      self.parameter = nil
      self.valueObservationCancelId = nil
      self.displayName = displayName
      self.track = .init(normValueTransform: normValueTransform, norm: normValueTransform.valueToNorm(value))
      self.title = .init(displayName: displayName, formatter: formatter)
    }
  }

  public enum Action: BindableAction, Equatable, Sendable {
    case binding(BindingAction<State>)
    case editorDismissed(String?)
    case observedValueChanged(AUValue)
    case performScrollTo(UInt64?)
    case setValue(Double)
    case setValueSilently(Double)
    case stopValueObservation
    case task(theme: Theme)
    case title(TitleFeature.Action)
    case track(TrackFeature.Action)
    case valueChanged(Double)
  }

  public init() {
    self.parameterValueChanged = nil
  }

  // Only used for unit tests
  private let parameterValueChanged: ((AUParameterAddress) -> Void)?

  /**
   Intitialize instance (testing only)

   - parameter parameterValueChanged closure to invoke when the parameter value changes.
   */
  init(_ parameterValueChanged: ((AUParameterAddress) -> Void)? = nil) {
    self.parameterValueChanged = parameterValueChanged
  }

  public var body: some Reducer<State, Action> {
    BindingReducer()

    Scope(state: \.track, action: \.track) { TrackFeature() }
    Scope(state: \.title, action: \.title) { TitleFeature() }

    Reduce { state, action in
      switch action {
      case .binding: return .none
      case let .editorDismissed(value): return editorDismissed(&state, value: value)
      case let .observedValueChanged(value): return valueChanged(&state, value: Double(value))
      case .performScrollTo(let id): return scrollTo(&state, id: id)
      case let .setValue(value): return setValue(&state, value: value, silently: false)
      case let .setValueSilently(value): return setValue(&state, value: value, silently: true)
      case .stopValueObservation: return stopObserving(&state)
      case .task(theme: let theme): return startObserving(&state, theme: theme)
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
      let newValue = state.normValueTransform.normToValue(state.normValueTransform.valueToNorm(editorValue))
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
    case .viewTapped(let taps):
      if taps == 1 {
        return showValue(&state)
      } else if taps == 2 {
        if let theme = state.theme {
          return showEditor(&state, theme: theme)
        }
      }
      return .none
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

  func setValue(_ state: inout State, value: Double, silently: Bool) -> Effect<Action> {
    if let parameter = state.parameter,
       let observerToken = state.observerToken {
      parameter.setValue(
        Float(value),
        originator: observerToken,
        atHostTime: 0,
        eventType: .value
      )
    }
    return silently ? reduce(into: &state, action: .track(.valueChanged(value))) : valueChanged(&state, value: value)
  }

  func showEditor(_ state: inout State, theme: Theme) -> Effect<Action> {
    let value = state.normValueTransform.normToValue(state.track.norm)
    state.$valueEditorInfo.withLock {
      $0 = .init(
        id: state.id,
        displayName: state.displayName,
        value: state.formatter.forEditing(value),
        theme: theme,
        decimalAllowed: .allowed,
        signAllowed: state.normValueTransform.minimumValue < 0.0 ? .allowed : .none
      )
    }
    return .none
  }

  func showValue(_ state: inout State) -> Effect<Action> {
    let value = state.normValueTransform.normToValue(state.track.norm)
    return reduce(into: &state, action: .title(.valueChanged(value)))
  }

  func startObserving(_ state: inout State, theme: Theme) -> Effect<Action> {
    state.theme = theme
    guard
      let parameter = state.parameter,
      let valueObservationCancelId = state.valueObservationCancelId
    else {
      return .none
    }

    let stream: AsyncStream<AUValue>
    (state.observerToken, stream) = parameter.startObserving()

    return .run { [duration = KnobConfig.default.debounceMilliseconds] send in
      if Task.isCancelled { return }
      for await value in stream.debounce(for: .milliseconds(duration)) {
        if Task.isCancelled { break }
        await send(.observedValueChanged(value))
      }
    }.cancellable(id: valueObservationCancelId, cancelInFlight: true)
  }

  func stopObserving(_ state: inout State) -> Effect<Action> {

    // This will tear down the AsyncStream since it causes the stream's continuation value to go out of scope. It should also
    // cause the Task created to monitor the stream to stop, but we cancel it anyway just to be safe.
    if let observerToken = state.observerToken,
       let parameter = state.parameter {
      parameter.removeParameterObserver(observerToken)
      state.observerToken = nil
    }

    if let valueObservationCancelId = state.valueObservationCancelId {
      return .cancel(id: valueObservationCancelId)
    }

    return .none
  }

  func trackChanged(_ state: inout State, action: TrackFeature.Action) -> Effect<Action> {
    let value = state.normValueTransform.normToValue(state.track.norm)
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
    .task { await store.send(.task(theme: theme)).finish() }
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

#if DEBUG

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
  static var store = Store(initialState: KnobFeature.State(parameter: param)) { KnobFeature() }

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
      .knobValueEditor()
    }
  }
}

#endif // DEBUG
