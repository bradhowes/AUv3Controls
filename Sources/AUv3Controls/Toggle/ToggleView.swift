import ComposableArchitecture
import AVFoundation
import SwiftUI

public struct ToggleReducer: Reducer {

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

  public enum Action: Equatable {
    case observedValueChanged(AUValue)
    case stoppedObserving
    case toggleTapped
    case viewAppeared
  }

  public func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {

    case let .observedValueChanged(value):
      state.isOn = value.asBool
      return .none

    case .stoppedObserving:
      state.observerToken = nil
      return .none

    case .toggleTapped:
      state.isOn.toggle()
      state.parameter.setValue(state.isOn.asValue, originator: state.observerToken)
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

public struct ToggleView : View {
  let store: StoreOf<ToggleReducer>
  let theme: Theme

  public var body: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      Toggle(isOn: viewStore.binding(get: \.isOn, send: .toggleTapped)) { Text(viewStore.parameter.displayName) }
        .toggleStyle(.checked(theme: theme))
        .task { await viewStore.send(.viewAppeared).finish() }
    }
  }
}

struct ToggleViewPreview : PreviewProvider {
  static let param1 = AUParameterTree.createBoolean(withIdentifier: "Retrigger", name: "Retrigger", address: 1)
  static let param2 = AUParameterTree.createBoolean(withIdentifier: "Monophonic", name: "Monophonic", address: 2)

  @State static var store1 = Store(initialState: ToggleReducer.State(parameter: param1)) {
    ToggleReducer()
  }

  @State static var store2 = Store(initialState: ToggleReducer.State(parameter: param2, isOn: true)) {
    ToggleReducer()
  }

  static var previews: some View {
    VStack(alignment: .leading, spacing: 12) {
      ToggleView(store: store1, theme: Theme())
      ToggleView(store: store2, theme: Theme())
    }
  }
}
