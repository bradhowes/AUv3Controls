import AVFoundation
import Clocks
import ComposableArchitecture
import SwiftUI

/**
 A text label that usually shows a fixed name/title value, but will show another value for short duration before
 reverting back to the name/title value.
 */
@Reducer
public struct TitleFeature {

  @ObservableState
  public struct State: Equatable {
    let config: KnobConfig
    var formattedValue: String?
    var showingValue: Bool { formattedValue != nil }
  }

  public enum Action: Equatable, Sendable {
    case cancelValueDisplayTimer
    case titleTapped
    case valueChanged(Double)
  }

  @Dependency(\.continuousClock) var clock

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .cancelValueDisplayTimer: return showTitleEffect(state: &state)
      case .titleTapped: return showTitleEffect(state: &state)
      case .valueChanged(let value): return showValueEffect(state: &state, value: value)
      }
    }
  }
}

private extension TitleFeature {

  func showTitleEffect(state: inout State) -> Effect<Action> {
    state.formattedValue = nil
    return .cancel(id: state.config.showValueCancelId)
  }

  func showValueEffect(state: inout State, value: Double) -> Effect<Action> {
    state.formattedValue = state.config.formattedValue(value)
    let duration: Duration = .seconds(state.config.theme.controlShowValueDuration)
    let clock = self.clock
    let cancelId = state.config.showValueCancelId
    return .run { send in
      try await withTaskCancellation(id: cancelId, cancelInFlight: true) {
        try await clock.sleep(for: duration)
        await send(.cancelValueDisplayTimer, animation: .linear)
      }
    }
  }
}

/**
 Two Text views, one that shows the title and the other that shows the current value. Normally, the
 title is shown, but when the view state receives the `.valueChanged` action, the value view will appear for N
 seconds before it disappears and the title reappears.
 */
public struct TitleView: View {
  private let store: StoreOf<TitleFeature>
  private let config: KnobConfig

  public init(store: StoreOf<TitleFeature>, config: KnobConfig) {
    self.store = store
    self.config = config
  }

  public var body: some View {
    ZStack {
      if store.showingValue {
        Text(store.formattedValue ?? "")
          .transition(.opacity)
          .fadeIn(when: store.showingValue)
      } else {
        Text(config.parameter.displayName)
          .fadeOut(when: store.showingValue)
      }
    }
    .font(config.theme.font)
    .foregroundColor(config.theme.textColor)
    .onTapGesture(count: 1) {
      withAnimation {
        _ = store.send(.titleTapped)
      }
    }
  }
}

struct TitleViewPreview: PreviewProvider {
  static let param = AUParameterTree.createParameter(withIdentifier: "RELEASE", name: "Release", address: 1,
                                                     min: 0.0, max: 100.0, unit: .generic, unitName: nil,
                                                     valueStrings: nil, dependentParameters: nil)
  static let config = KnobConfig(parameter: param, theme: Theme())
  @State static var store = Store(initialState: TitleFeature.State(config: config)) {
    TitleFeature()
  }

  static var previews: some View {
    VStack(spacing: 24) {
      Button(action: { self.store.send(.valueChanged(1.24), animation: .linear) }) { Text("Send") }
      TitleView(store: store, config: config)
        .task { store.send(.valueChanged(1.24), animation: .linear) }
    }
  }
}
