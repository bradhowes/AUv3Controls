import AVFoundation
import Clocks
import ComposableArchitecture
import SwiftUI


public struct ToggleFeature: Reducer {

  public init() {}

  public struct State: Equatable, Identifiable {
    public var id: ID { ObjectIdentifier(parameter) }

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
    case observedValueChanged(AUValue)
    case startValueObservation
    case stopValueObservation
    case toggleTapped
  }

  public func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {

    case .startValueObservation:
      print("starting observation")
      let stream: AsyncStream<AUValue>
      (state.observerToken, stream) = state.parameter.startObserving()
      return .run { send in
        for await value in stream {
          print("got value: \(value)")
          await send(.observedValueChanged(value))
        }
        await send(.stopValueObservation)
      }.cancellable(id: state.id, cancelInFlight: true)

    case .stopValueObservation:
      if let token = state.observerToken {
        state.parameter.removeParameterObserver(token)
        state.observerToken = nil
      }
      return .cancel(id: state.id)

    case let .observedValueChanged(value):
      print("observedValueChanged: \(value)")
      state.isOn = value.asBool
      return .none

    case .toggleTapped:
      state.isOn.toggle()
      state.parameter.setValue(state.isOn.asValue, originator: state.observerToken)
      return .none

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
    }
  }
}
