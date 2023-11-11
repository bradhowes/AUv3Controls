//import AVFoundation
//import Clocks
//import ComposableArchitecture
//import SwiftUI
//
//public struct ToggleReducer: Reducer {
//
//  public struct State: Equatable {
//    public let parameter: AUParameter
//    public var isOn: Bool
//    public var observerToken: AUParameterObserverToken?
//
//    public init(parameter: AUParameter, isOn: Bool = false) {
//      self.parameter = parameter
//      self.isOn = isOn
//      self.parameter.setValue(isOn.asValue, originator: nil)
//    }
//  }
//
//  public enum Action: Equatable {
//    case observedValueChanged(AUValue)
//    case stoppedObserving
//    case toggleTapped
//    case viewAppeared
//  }
//
//  private enum CancelID { case observingParameterTask }
//
//  @Dependency(\.continuousClock) var clock
//
//  public func reduce(into state: inout State, action: Action) -> Effect<Action> {
//    switch action {
//
//    case let .observedValueChanged(value):
//      print("observedValueChanged: \(value)")
//      state.isOn = value.asBool
//      return .none
//
//    case .stoppedObserving:
//      print("stoppedObserving: \(state.observerToken!)")
//      state.observerToken = nil
//      return .cancel(id: CancelID.observingParameterTask)
//
//    case .toggleTapped:
//      print("toggleTapped")
//      state.isOn.toggle()
//      state.parameter.setValue(state.isOn.asValue, originator: state.observerToken)
//      return .none
//
//    case .viewAppeared:
//      print("viewAppeared")
//      let valueUpdates = state.parameter.startObserving(&state.observerToken)
//      return .run { send in
//        print("start of observer task")
//        for await value in valueUpdates {
//          print("observer saw value: \(value)")
//          await send(.observedValueChanged(value))
//        }
//        print("stop of observer task")
//        await send(.stoppedObserving)
//      }.cancellable(id: CancelID.observingParameterTask, cancelInFlight: true)
//    }
//  }
//}
//
//public struct ToggleView: View {
//  let store: StoreOf<ToggleReducer>
//  let theme: Theme
//
//  public var body: some View {
//    WithViewStore(self.store, observe: { $0 }, content: { viewStore in
//      Toggle(isOn: viewStore.binding(get: \.isOn, send: .toggleTapped)) { Text(viewStore.parameter.displayName) }
//        .toggleStyle(.checked(theme: theme))
//        .task { await viewStore.send(.viewAppeared).finish() }
//    })
//  }
//}
//
//struct ToggleViewPreview: PreviewProvider {
//  static let param1 = AUParameterTree.createBoolean(withIdentifier: "Retrigger", name: "Retrigger", address: 1)
//  static let param2 = AUParameterTree.createBoolean(withIdentifier: "Monophonic", name: "Monophonic", address: 2)
//
//  @State static var store1 = Store(initialState: ToggleReducer.State(parameter: param1)) {
//    ToggleReducer()
//  }
//
//  @State static var store2 = Store(initialState: ToggleReducer.State(parameter: param2, isOn: true)) {
//    ToggleReducer()
//  }
//
//  static var previews: some View {
//    VStack(alignment: .leading, spacing: 12) {
//      ToggleView(store: store1, theme: Theme())
//      ToggleView(store: store2, theme: Theme())
//    }
//  }
//}
