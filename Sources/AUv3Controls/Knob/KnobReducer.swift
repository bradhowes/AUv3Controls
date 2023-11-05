import AVFoundation
import Clocks
import ComposableArchitecture
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
    var lastDrag: CGPoint?
    @BindingState var focusedField: Field?

    var norm: Double = 0.0
  }

  private enum CancelID { case showingValueTask }

  enum Field: Hashable { case value }

  public enum Action: BindableAction, Equatable {
    case binding(BindingAction<State>)
    case acceptButtonTapped
    case cancelButtonTapped
    case clearButtonTapped
    case labelTapped
    case observedValueChanged(AUValue)
    case stoppedObserving
    case dragChanged(start: CGPoint, position: CGPoint)
    case dragEnded(start: CGPoint, position: CGPoint)
    case showingValueTimerStopped
    case textChanged(String)
    case viewAppeared
  }

  @Dependency(\.continuousClock) var clock

  let config: KnobConfig
}

extension KnobReducer {

  public func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {

    case .acceptButtonTapped:
      state.focusedField = nil
      state.showingValueEditor = false
      if let newValue = Double(state.formattedValue) {
        setNorm(state: &state, norm: config.valueToNorm(newValue))
      }
      return showingValueEffect(state: &state)

    case .binding:
      return .none

    case .cancelButtonTapped:
      state.focusedField = nil
      state.showingValueEditor = false
      return .none

    case .clearButtonTapped:
      state.formattedValue = ""
      return .none

    case .labelTapped:
      state.showingValueEditor = true
      state.formattedValue = config.formattedValue(state.value)
      state.focusedField = .value
      return .none

    case let.observedValueChanged(value):
      self.setNorm(state: &state, norm: config.valueToNorm(Double(value)))
      return showingValueEffect(state: &state)

    case .stoppedObserving:
      state.observerToken = nil
      return .none

    case let .dragChanged(start, position):
      setNorm(state: &state,
              norm: (state.norm +
                     config.dragChangeValue(last: state.lastDrag ?? start, position: position))
                .clamped(to: 0.0...1.0))
      state.lastDrag = position
      state.showingValue = true
      return .cancel(id: CancelID.showingValueTask)

    case .dragEnded:
      state.lastDrag = nil
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
      }
    }
  }
}

extension KnobReducer {

  func setNorm(state: inout State, norm: Double) {
    state.norm = norm
    state.value = config.normToValue(norm)
    state.formattedValue = config.formattedValue(state.value)
  }

  func showingValueEffect(state: inout State) -> Effect<Action> {
    state.showingValue = true
    state.formattedValue = config.formattedValue(state.value)
    return .run { send in
      try await self.clock.sleep(for: .seconds(config.showValueDuration))
      await send(.showingValueTimerStopped)
    }
  }
}
