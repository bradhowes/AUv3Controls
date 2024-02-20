import AVFoundation
import Clocks
import ComposableArchitecture
import SwiftUI

public struct TitleFeature: Reducer {
  let config: KnobConfig

  public struct State: Equatable {
    var formattedValue: String?
    var showingValue: Bool { formattedValue != nil }
  }

  public enum Action: Equatable, Sendable {
    case valueChanged(Double)
    case stoppedShowingValue
    case tapped
  }

  @Dependency(\.continuousClock) var clock

  public func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case let .valueChanged(value): return updateAndShowValue(state: &state, value: value)
    case .stoppedShowingValue: return showTitle(state: &state)
    case .tapped: return showTitle(state: &state)
    }
  }
}

extension TitleFeature {

  func showTitle(state: inout State) -> Effect<TitleFeature.Action> {
    state.formattedValue = nil
    return .none
  }

  func updateAndShowValue(state: inout State, value: Double) -> Effect<TitleFeature.Action> {
    state.formattedValue = config.formattedValue(value)
    let duration: Duration = .seconds(config.showValueDuration)
    let clock = self.clock
    return .run { send in
      try await clock.sleep(for: duration)
      await send(.stoppedShowingValue, animation: .linear)
    }
  }
}

/**
 Two Text views, one that shows the title and the other that shows the current value. Normally, the
 title is shown, but when the view state receives the `.valueChanged` action, the value view will appear for N
 seconds before it disappears and the title reappears.
 */
struct TitleView: View {
  let store: StoreOf<TitleFeature>
  let config: KnobConfig
  let proxy: ScrollViewProxy?

  var body: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      ZStack {
        if viewStore.showingValue {
          Text(viewStore.formattedValue ?? "")
            .transition(.opacity)
            .fadeIn(when: viewStore.showingValue)
        } else {
          Text(config.parameter.displayName)
            .fadeOut(when: viewStore.showingValue)
        }
      }
      .font(config.theme.font)
      .foregroundColor(config.theme.textColor)
      .onTapGesture(count: 1, perform: {
        withAnimation {
          store.send(.tapped)
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
    VStack(spacing: 24) {
      Button(action: { self.store.send(.valueChanged(1.24), animation: .linear) }) { Text("Send") }
      TitleView(store: store, config: config, proxy: nil)
        .task { store.send(.valueChanged(1.24), animation: .linear) }
    }
  }
}
