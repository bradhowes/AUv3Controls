import AVFoundation
import Clocks
import ComposableArchitecture
import SwiftUI

public struct TitleFeature: Reducer {
  let config: KnobConfig

  public struct State: Equatable {
    var formattedValue: String?
  }

  private enum CancelID { case showingValueTask }

  public enum Action: Equatable, Sendable {
    case valueChanged(Double)
    case stoppedShowingValue
    case tapped
  }

  @Dependency(\.continuousClock) var clock

  public func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {

    case let .valueChanged(value):
      return updateValue(state: &state, value: value)

    case .stoppedShowingValue:
      state.formattedValue = nil
      return .cancel(id: CancelID.showingValueTask)

    case .tapped:
      return .cancel(id: CancelID.showingValueTask)
    }
  }
}

extension TitleFeature {

  func updateValue(state: inout State, value: Double) -> Effect<TitleFeature.Action> {
    state.formattedValue = config.formattedValue(value)
    let duration: Duration = .seconds(config.showValueDuration)
    let clock = self.clock
    return .run { send in
      try await clock.sleep(for: duration)
      await send(.stoppedShowingValue)
    }.cancellable(id: CancelID.showingValueTask, cancelInFlight: true)
  }
}

struct TitleView: View {
  let store: StoreOf<TitleFeature>
  let config: KnobConfig
  let proxy: ScrollViewProxy?

  var body: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      ZStack {
        Text(config.parameter.displayName)
          .opacity(viewStore.formattedValue != nil ? 0.0 : 1.0)
        if viewStore.formattedValue != nil {
          Text(viewStore.formattedValue ?? "")
            .transition(.opacity)
            .opacity(viewStore.formattedValue != nil ? 1.0 : 0.0)
        }
      }
      .animation(.linear(duration: 0.25), value: viewStore.formattedValue)
      .font(config.theme.font)
      .foregroundColor(config.theme.textColor)
      .onTapGesture(count: 1, perform: {
        store.send(.tapped)
        withAnimation {
          proxy?.scrollTo(config.id, anchor: UnitPoint(x: 0.6, y: 0.5))
        }
      })
    }
  }
}

struct TitleViewPreview: PreviewProvider {
  static let param = AUParameterTree.createParameter(withIdentifier: "RELEASE", name: "Release", address: 1,
                                                     min: 0.0, max: 100.0, unit: .generic, unitName: nil,
                                                     valueStrings: nil, dependentParameters: nil)
  static let config = KnobConfig(parameter: param, logScale: false, theme: Theme())
  @State static var store = Store(initialState: TitleFeature.State()) {
    TitleFeature(config: config)
  }

  static var previews: some View {
    TitleView(store: store, config: config, proxy: nil)
      .task { store.send(.valueChanged(1.24)) }
  }
}
