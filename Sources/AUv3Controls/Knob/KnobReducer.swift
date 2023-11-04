import ComposableArchitecture
import AVFoundation
import SwiftUI

public struct KnobReducer: Reducer {

  public struct State: Equatable {

    let parameter: AUParameter
    var value: Double

    public init(parameter: AUParameter, value: Double = 0.0) {
      self.parameter = parameter
      self.value = value
      self.parameter.setValue(AUValue(value), originator: nil)
    }

    var formattedValue: String = ""
    var observerToken: AUParameterObserverToken?
    var showingValue: Bool = false
    var showingValueEditor: Bool = false
    var lastY: CGFloat?
    @BindingState var focusedField: Field?

    var norm: Double = 0.0
  }

  private enum CancelID { case showingValueTask }

  enum Field: Hashable { case value }

  public enum Action: BindableAction, Equatable {
    case binding(BindingAction<State>)
    case acceptButtonPressed
    case cancelButtonPressed
    case clearButtonPressed
    case gainedFocus
    case labelTapped
    case observedValueChanged(AUValue)
    case stoppedObserving
    case dragChanged(DragGesture.Value)
    case dragEnded(DragGesture.Value)
    case showingValueTimerStopped
    case textChanged(String)
    case viewAppeared
    case viewDisappeared
  }

  let config: KnobConfig
}

extension KnobReducer {

  public func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {

    case .acceptButtonPressed:
      state.focusedField = nil
      state.showingValueEditor = false
      if let newValue = Double(state.formattedValue) {
        setNorm(state: &state, config: config, norm: config.valueToNorm(newValue))
      }
      return showingValueEffect(state: &state)

    case .binding:
      return .none

    case .cancelButtonPressed:
      state.focusedField = nil
      state.showingValueEditor = false
      return .none

    case .clearButtonPressed:
      state.formattedValue = ""
      return .none

    case .gainedFocus:
      return .none

    case .labelTapped:
      state.showingValueEditor = true
      state.formattedValue = config.formattedValue(state.value)
      state.focusedField = .value
      return .none

    case let.observedValueChanged(value):
      state.value = Double(value)
      return showingValueEffect(state: &state)

    case .stoppedObserving:
      state.observerToken = nil
      return .none

    case let .dragChanged(dragValue):
      setNorm(state: &state,
              config: config,
              norm: max(min(config.dragChangeValue(lastY: state.lastY ?? dragValue.startLocation.y,
                                                   dragValue: dragValue) +
                            state.norm, 1.0), 0.0))
      state.lastY = dragValue.location.y
      state.showingValue = true
      return .cancel(id: CancelID.showingValueTask)

    case .dragEnded:
      state.lastY = nil
      return showingValueEffect(state: &state)

    case .showingValueTimerStopped:
      state.showingValue = false
      return .none

    case let .textChanged(newValue):
      state.formattedValue = newValue
      return .none

    case .viewAppeared:
      let valueUpdates = state.parameter.startObserving(&state.observerToken)
      return .run { send in
        for await value in valueUpdates {
          await send(.observedValueChanged(value))
        }
        await send(.stoppedObserving)
      }.cancellable(id: CancelID.showingValueTask)

    case .viewDisappeared:
      return .cancel(id: CancelID.showingValueTask)
    }
  }
}

extension KnobReducer {

  func setNorm(state: inout State, config: KnobConfig, norm: Double) {
    state.norm = norm
    state.value = config.normToValue(norm)
    state.formattedValue = config.normToFormattedValue(norm)
  }

  func showingValueEffect(state: inout State) -> Effect<Action> {
    state.showingValue = true
    state.formattedValue = config.formattedValue(state.value)
    return .run { send in
      try await Task.sleep(for: .seconds(1.25))
      await send(.showingValueTimerStopped)
    }
  }
}
