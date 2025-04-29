// Copyright © 2025 Brad Howes. All rights reserved.

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
    let displayName: String
    let formatter: KnobValueFormatter
    let showValueDuration: Double
    let showValueCancelId: String
    var dragActive: Bool = false
    var formattedValue: String?
    var showingValue: Bool { formattedValue != nil }

    public init(displayName: String, formatter: KnobValueFormatter, showValueDuration: Double) {
      self.displayName = displayName
      self.formatter = formatter
      self.showValueDuration = showValueDuration
      self.showValueCancelId = "ShowValueCancelId[\(UUID().uuidString)]"
    }
  }

  public enum Action: Equatable, Sendable {
    case cancelValueDisplayTimer
    case dragActive(Bool)
    case titleTapped
    case valueChanged(Double)
  }

  @Dependency(\.continuousClock) var clock

  public init() {}

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .cancelValueDisplayTimer: return showTitleEffect(state: &state)
      case let .dragActive(value): return dragActive(&state, value: value)
      case .titleTapped: return showTitleEffect(state: &state)
      case .valueChanged(let value): return showValueEffect(state: &state, value: value)
      }
    }
  }
}

private extension TitleFeature {

  func dragActive(_ state: inout State, value: Bool) -> Effect<Action> {
    state.dragActive = value
    return value ? .none : startTitleTimerEffect(&state)
  }

  func showTitleEffect(state: inout State) -> Effect<Action> {
    state.formattedValue = nil
    return .cancel(id: state.showValueCancelId)
  }

  func showValueEffect(state: inout State, value: Double) -> Effect<Action> {
    state.formattedValue = state.formatter.forDisplay(value)
    return state.dragActive ? .none : startTitleTimerEffect(&state)
  }

  func startTitleTimerEffect(_ state: inout State) -> Effect<Action> {
    let duration: Duration = .seconds(state.showValueDuration)
    let clock = self.clock
    let cancelId = state.showValueCancelId
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
  @Environment(\.isEnabled) private var enabled
  @Environment(\.auv3ControlsTheme) private var theme

  public init(store: StoreOf<TitleFeature>) {
    self.store = store
  }

  public var body: some View {
    ZStack {
      if store.showingValue {
        Text(store.formattedValue ?? "")
          .transition(.move(edge: store.showingValue ? .top : .bottom))
      } else {
        Text(store.displayName)
          .transition(.move(edge: store.showingValue ? .top : .bottom))
      }
    }
    .font(theme.font)
    .frame(width: 120, height: 20)
    .foregroundColor(theme.textColor)
    .clipped(antialiased: true)
    .animation(.smooth, value: store.showingValue)
    .animation(.smooth, value: store.formattedValue)
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
  static let theme = Theme()
  @State static var store = Store(initialState: TitleFeature.State(
    displayName: param.displayName,
    formatter: .duration(2...2),
    showValueDuration: theme.controlShowValueDuration
  )) {
    TitleFeature()
  }

  static var previews: some View {
    VStack(spacing: 24) {
      Button(action: { self.store.send(.valueChanged(1.24), animation: .linear) }) { Text("Send") }
      TitleView(store: store)
        .task { store.send(.valueChanged(1.24), animation: .linear) }
    }
  }
}
