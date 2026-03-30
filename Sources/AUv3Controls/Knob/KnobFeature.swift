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
    public let valueObservationCancelId: UUID?
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
      @Dependency(\.uuid) var uuid
      self.id = parameter.address
      self.parameter = parameter
      self.valueObservationCancelId = uuid()
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
      @Dependency(\.uuid) var uuid
      let normValueTransform: NormValueTransform = .init(
        minimumValue: minimumValue,
        maximumValue: maximumValue,
        logScale: logarithmic
      )
      self.normValueTransform = normValueTransform
      let formatter = KnobValueFormatter.general()
      self.formatter = formatter
      self.id = uuid().asUInt64
      self.parameter = nil
      self.valueObservationCancelId = nil
      self.displayName = displayName
      self.track = .init(normValueTransform: normValueTransform, norm: normValueTransform.valueToNorm(value))
      self.title = .init(displayName: displayName, formatter: formatter)
    }
  }

  // public enum Action: BindableAction, Equatable, Sendable {
  public enum Action: Equatable, Sendable {
    // case binding(BindingAction<State>)
    case editorDismissed(String?)
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
    self.notifyTrackValueChanged = nil
  }

  // Only used for unit tests
  private let notifyTrackValueChanged: ((AUParameterAddress) -> Void)?

  /**
   Intitialize instance (testing only)

   - parameter parameterValueChanged closure to invoke when the parameter value changes.
   */
  init(_ notifyTrackValueChanged: ((AUParameterAddress) -> Void)? = nil) {
    self.notifyTrackValueChanged = notifyTrackValueChanged
  }

  public var body: some Reducer<State, Action> {
    // BindingReducer()

    Scope(state: \.track, action: \.track) { TrackFeature() }
    Scope(state: \.title, action: \.title) { TitleFeature() }

    Reduce { state, action in
      switch action {
      // case .binding: return .none
      case .editorDismissed(let value): return editorDismissed(&state, value: value)
      case .performScrollTo(let id): return scrollTo(&state, id: id)
      case .setValue(let value): return setValue(&state, value: value, silently: false)
      case .setValueSilently(let value): return setValue(&state, value: value, silently: true)
      case .stopValueObservation: return stopValueObservation(&state)
      case .task(theme: let theme): return startValueObservation(&state, theme: theme)
      case .title(let action): return processTitleAction(&state, action: action)
      case .track(let action): return processTrackAction(&state, action: action)
      case .valueChanged(let value): return parameterValueChanged(&state, value: value)
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
        trackValueChanged(state: state, value: newValue, cause: .value),
        parameterValueChanged(&state, value: newValue)
      )
    }
    return .none
  }

  func processTitleAction(_ state: inout State, action: TitleFeature.Action) -> Effect<Action> {
    if case .titleTapped(let theme) = action {
      return showEditor(&state, theme: theme)
    }
    return .none
  }

  func processTrackAction(_ state: inout State, action: TrackFeature.Action) -> Effect<Action> {
    let effect: Effect<Action>
    switch action {
    case .dragStarted: effect = .send(.title(.dragActive(true)))
    case .dragChanged: effect = showValue(&state)
    case .dragEnded: effect = .send(.title(.dragActive(false)))
    case .normChanged(_): effect = .none
    case .valueChanged(_): effect = .none
    case .viewTapped(let taps):
      if taps == 1 {
        effect = showValue(&state)
      } else if taps == 2 {
        if let theme = state.theme {
          effect = showEditor(&state, theme: theme)
        } else {
          effect = .none
        }
      } else {
        effect = .none
      }
    }

    let value = state.normValueTransform.normToValue(state.track.norm)
    return .merge(effect, trackValueChanged(state: state, value: value, cause: action.cause))
  }

  func scrollTo(_ state: inout State, id: UInt64?) -> Effect<Action> {
    state.scrollToDestination = id
    return .none
  }

  func setValue(_ state: inout State, value: Double, silently: Bool) -> Effect<Action> {
    if let observerToken = state.observerToken,
       let parameter = state.parameter {
      parameter.setValue(AUValue(value), originator: observerToken, atHostTime: 0, eventType: .value)
    }
    return silently ? .send(.track(.valueChanged(value))) : parameterValueChanged(&state, value: value)
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
    return .send(.title(.valueChanged(value)))
  }

  func startValueObservation(_ state: inout State, theme: Theme) -> Effect<Action> {
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
        await send(.valueChanged(Double(value)))
      }
    }.cancellable(id: valueObservationCancelId, cancelInFlight: true)
  }

  func stopValueObservation(_ state: inout State) -> Effect<Action> {
    if let observerToken = state.observerToken {
      state.parameter?.removeParameterObserver(observerToken)
      state.observerToken = nil
    }
    if let valueObservationCancelId = state.valueObservationCancelId {
      return .cancel(id: valueObservationCancelId)
    }
    return .none
  }

  func trackValueChanged(state: State, value: Double, cause: AUParameterAutomationEventType?) -> Effect<Action> {
    if let cause, let parameter = state.parameter {
      let newValue = AUValue(value)
      if parameter.value != newValue {
        parameter.setValue(newValue, originator: state.observerToken, atHostTime: 0, eventType: cause)
        notifyTrackValueChanged?(parameter.address)
      }
    }
    return .none
  }

  func parameterValueChanged(_ state: inout State, value: Double) -> Effect<Action> {
    return .merge(
      .send(.title(.valueChanged(value))),
      .send(.track(.valueChanged(value)))
    )
  }
}

public struct KnobView: View {
  @State private var store: StoreOf<KnobFeature>
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
  struct Demo: View {
    @State private var parameterValue: AUValue = 0.0
    let store: StoreOf<KnobFeature>
    let param: AUParameter
    let tree: AUParameterTree

    init() {
      let param = AUParameterTree.createParameter(
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
      self.tree = AUParameterTree.createTree(withChildren: [param])
      self.param = self.tree.parameter(withAddress: 1)!
      self.store = Store(initialState: KnobFeature.State(parameter: param)) { KnobFeature() }
    }

    var body: some View {
      NavigationStack {
        VStack {
          KnobView(store: store)
            .frame(width: 140, height: 140)
            .padding([.top, .bottom], 16)
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
          Text("AUParameter value: \(parameterValue)")
        }
        .knobValueEditor()
        .onAppear {
          Task {
            let observationState = self.param.startObserving()
            for await value in observationState.1 {
              parameterValue = value
            }
          }
        }
      }
    }
  }

  static var previews: some View {
    Demo()
  }
}

#endif // DEBUG
