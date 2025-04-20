import AVFoundation
import Clocks
import ComposableArchitecture
import SwiftUI

@Reducer
public struct ToggleFeature {

  @ObservableState
  public struct State: Equatable {
    let parameter: AUParameter
    let valueObservationCancelId: String
    var isOn: Bool
    var observerToken: AUParameterObserverToken?

    public init(
      parameter: AUParameter,
      isOn: Bool = false
    ) {
      self.valueObservationCancelId = "valueObservationCancelId[AUParameter: \(parameter.address)])"
      self.parameter = parameter
      self.isOn = isOn
      self.parameter.setValue(isOn.asValue, originator: nil)
    }
  }

  public enum Action: Equatable, Sendable {
    case animatedObservedValueChanged(Bool)
    case observedValueChanged(AUValue)
    case stopValueObservation
    case task
    case toggleTapped
  }

  // Only used for unit tests
  private let parameterValueChanged: ((AUParameterAddress) -> Void)?

  public init(parameterValueChanged: ((AUParameterAddress) -> Void)? = nil) {
    self.parameterValueChanged = parameterValueChanged
  }

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .stopValueObservation:
        if let token = state.observerToken {
          state.parameter.removeParameterObserver(token)
          state.observerToken = nil
        }
        return .cancel(id: state.valueObservationCancelId)

      case let .observedValueChanged(value):
        return .run { send in await send(.animatedObservedValueChanged(value.asBool)) }.animation()

      case let .animatedObservedValueChanged(value):
        state.isOn = value
        return .none

      case .task:
        let stream: AsyncStream<AUValue>
        (state.observerToken, stream) = state.parameter.startObserving()
        return .run { send in
          for await value in stream {
            await send(.observedValueChanged(value))
          }
        }.cancellable(id: state.valueObservationCancelId, cancelInFlight: true)

      case .toggleTapped:
        state.isOn.toggle()
        return setParameterEffect(state: state)
      }
    }
  }

  private func setParameterEffect(state: State) -> Effect<Action> {
    let parameter = state.parameter
    let newValue = state.isOn.asValue
    if parameter.value != newValue {
      parameter.setValue(newValue, originator: state.observerToken, atHostTime: 0, eventType: .value)
      parameterValueChanged?(parameter.address)
    }
    return .none
  }
}

public struct ToggleView: View {
  private let store: StoreOf<ToggleFeature>
  @Environment(\.auv3ControlsTheme) private var theme

  public init(store: StoreOf<ToggleFeature>) {
    self.store = store
  }

  public var body: some View {
    WithViewStore(self.store, observe: { $0 }, content: { viewStore in
      Toggle(isOn: viewStore.binding(get: \.isOn, send: .toggleTapped)) { Text(viewStore.parameter.displayName) }
        .toggleStyle(.checked(theme: theme))
        .task { await viewStore.send(.task).finish() }
        .onDisappear { viewStore.send(.stopValueObservation) }
    })
  }
}

struct ToggleViewPreview: PreviewProvider {
  static let param1 = AUParameterTree.createBoolean(withIdentifier: "Retrigger", name: "Retrigger", address: 1)
  static let param2 = AUParameterTree.createBoolean(withIdentifier: "Monophonic", name: "Monophonic", address: 2)

  @State static var store1 = Store(initialState: ToggleFeature.State(parameter: param1)) {
    ToggleFeature()
  }

  @State static var store2 = Store(initialState: ToggleFeature.State(parameter: param2, isOn: true)) {
    ToggleFeature()
  }

  static var previews: some View {
    VStack(alignment: .leading, spacing: 12) {
      ToggleView(store: store1)
      ToggleView(store: store2)
      Button {
        store1.send(.observedValueChanged(store1.isOn ? 0.0 : 1.0))
      } label: {
        Text("Toggle Parameter 1")
      }
      Button {
        store2.send(.observedValueChanged(store2.isOn ? 0.0 : 1.0))
      } label: {
        Text("Toggle Parameter 2")
      }
    }.auv3ControlsTheme(.init())
  }
}
