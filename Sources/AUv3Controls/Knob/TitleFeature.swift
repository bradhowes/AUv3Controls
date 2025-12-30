// Copyright © 2025 Brad Howes. All rights reserved.

import AVFoundation
import ComposableArchitecture
import Foundation
import SwiftUI

/**
 A text label that usually shows a fixed name/title value, but will show another value for short duration before
 reverting back to the name/title value.
 */
@Reducer
public struct TitleFeature {

  @ObservableState
  public struct State: Equatable {
    public let displayName: String
    @ObservationStateIgnored
    public var dragActive: Bool = false
    public var formattedValue: String?
    public var showingValue: Bool { formattedValue != nil }
    public let showValueCancelId = "ShowValueCancelId[\(UUID().uuidString)]"

    @ObservationStateIgnored
    public let formatter: KnobValueFormatter

    public init(displayName: String, formatter: KnobValueFormatter) {
      self.displayName = displayName
      self.formatter = formatter
    }
  }

  public enum Action: Equatable, Sendable {
    case dragActive(Bool)
    case titleTapped(Theme)
    case valueChanged(Double)
    case valueDisplayTimerFired
  }

  @Dependency(\.mainQueue) var mainQueue

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case let .dragActive(value): return dragActive(&state, value: value)
      case .titleTapped: return showTitleEffect(state: &state)
      case .valueChanged(let value): return showValueEffect(state: &state, value: value)
      case .valueDisplayTimerFired: return showTitleEffect(state: &state)
      }
    }
  }
}

private extension TitleFeature {

  func dragActive(_ state: inout State, value: Bool) -> Effect<Action> {
    state.dragActive = value
    return value ? .none : startTitleTimerEffect2(&state)
  }

  func showTitleEffect(state: inout State) -> Effect<Action> {
    state.formattedValue = nil
    return .cancel(id: state.showValueCancelId)
  }

  func showValueEffect(state: inout State, value: Double) -> Effect<Action> {
    state.formattedValue = state.formatter.forDisplay(value)
    return state.dragActive ? .none : startTitleTimerEffect2(&state)
  }

  func startTitleTimerEffect2(_ state: inout State) -> Effect<Action> {
    return .run { send in
      if !Task.isCancelled {
        await send(.valueDisplayTimerFired, animation: .linear)
      }
    }.debounce(id: state.showValueCancelId, for: .milliseconds(KnobConfig.default.showValueMilliseconds), scheduler: mainQueue)
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
  @State private var minWidth: Double = .zero

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
    .onGeometryChange(for: Double.self) {
      $0.size.width
    } action: {
      self.minWidth = max(self.minWidth, $0)
    }
    .font(theme.font)
    .foregroundColor(theme.textColor)
    .frame(minWidth: minWidth)
    .contentShape(Rectangle())
    .clipped(antialiased: true)
    .animation(.smooth, value: store.showingValue)
    .animation(.smooth, value: store.formattedValue)
    .onTapGesture(count: 1) {
      withAnimation {
        _ = store.send(.titleTapped(theme))
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
    formatter: KnobValueFormatter.duration(2...2)
  )) {
    TitleFeature()
  }

  static var previews: some View {
    VStack(spacing: 24) {
      Button(action: { self.store.send(.valueChanged(1.24), animation: .linear) }) { Text("Send") }
      TitleView(store: store)
        .task { store.send(.valueChanged(1.24), animation: .linear) }
    }
    .knobValueEditor()
  }
}
