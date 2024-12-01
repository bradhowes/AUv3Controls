import AVFoundation
import Clocks
import ComposableArchitecture
import SwiftUI

@Reducer
public struct ToggleFeature {

  @ObservableState
  public struct State: Equatable {
    public let parameter: AUParameter
    public var isOn: Bool
    public var observerToken: AUParameterObserverToken?

    public init(parameter: AUParameter, isOn: Bool = false) {
      self.parameter = parameter
      self.isOn = isOn
      self.parameter.setValue(isOn.asValue, originator: nil)
    }
  }

  public enum Action: Equatable, Sendable {
    case animatedObservedValueChanged(Bool)
    case observedValueChanged(AUValue)
    case startValueObservation
    case stopValueObservation
    case toggleTapped
  }

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .startValueObservation:
        let stream: AsyncStream<AUValue>
        (state.observerToken, stream) = state.parameter.startObserving()
        return .run { send in
          for await value in stream {
            await send(.observedValueChanged(value))
          }
          await send(.stopValueObservation)
        }.cancellable(id: state.parameter.address, cancelInFlight: true)

      case .stopValueObservation:
        if let token = state.observerToken {
          state.parameter.removeParameterObserver(token)
          state.observerToken = nil
        }
        return .cancel(id: state.parameter.address)

      case let .observedValueChanged(value):
        return .run { send in await send(.animatedObservedValueChanged(value.asBool)) }.animation()

      case let .animatedObservedValueChanged(value):
        state.isOn = value
        return .none

      case .toggleTapped:
        state.isOn.toggle()
        state.parameter.setValue(
          state.isOn.asValue,
          originator: state.observerToken,
          atHostTime: 0,
          eventType: .value
        )
        return .none
      }
    }
  }
}

public struct ToggleView: View {
  let store: StoreOf<ToggleFeature>
  let theme: Theme

  public init(store: StoreOf<ToggleFeature>, theme: Theme) {
    self.store = store
    self.theme = theme
  }

  public var body: some View {
    WithViewStore(self.store, observe: { $0 }, content: { viewStore in
      Toggle(isOn: viewStore.binding(get: \.isOn, send: .toggleTapped)) { Text(viewStore.parameter.displayName) }
        .toggleStyle(.checked(theme: theme))
        .task { viewStore.send(.startValueObservation) }
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
      ToggleView(store: store1, theme: Theme())
      ToggleView(store: store2, theme: Theme())
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
    }
  }
}
