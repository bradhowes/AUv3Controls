// Copyright © 2025 Brad Howes. All rights reserved.

import AVFoundation
import ComposableArchitecture
import SwiftUI

/**
 Combination of a TrackFeature and a TitleFeature. Changes to the track value will cause the title to show the
 current value for a short duration before reverting back to the configured title value.

 Does not support value editing.
 */
@Reducer
public struct ControlFeature {
  let formatter: any KnobValueFormattingProvider
  let normValueTransform: NormValueTransform
  let showValueMilliseconds: Int

  public init(
    formatter: any KnobValueFormattingProvider,
    normValueTransform: NormValueTransform,
    showValueMilliseconds: Int = KnobConfig.default.controlShowValueMilliseconds
  ) {
    self.formatter = formatter
    self.normValueTransform = normValueTransform
    self.showValueMilliseconds = showValueMilliseconds
  }

  @ObservableState
  public struct State: Equatable {
    var title: TitleFeature.State
    var track: TrackFeature.State

    public init(
      displayName: String,
      norm: Double
    ) {
      self.title = .init(displayName: displayName)
      self.track = .init(norm: norm)
    }
  }

  public enum Action: Equatable, Sendable {
    case title(TitleFeature.Action)
    case track(TrackFeature.Action)
    case valueChanged(Double)
  }

  public var body: some Reducer<State, Action> {
    Scope(state: \.track, action: \.track) { TrackFeature(normValueTransform: normValueTransform) }
    Scope(state: \.title, action: \.title) { TitleFeature(formatter: formatter, showValueMilliseconds: showValueMilliseconds ) }

    Reduce { state, action in
      switch action {
      case .title: return .none
      case .track(.dragStarted): return reduce(into: &state, action: .title(.dragActive(true)))
      case .track(.dragEnded): return reduce(into: &state, action: .title(.dragActive(false)))
      case .track(.viewTapped): return showValue(&state)
      case .track(.dragChanged): return trackChanged(&state)
      case .valueChanged(let value): return valueChanged(&state, value: value)
      case .track: return .none
      }
    }
  }

  private func showValue(_ state: inout State) -> Effect<Action> {
    let value = normValueTransform.normToValue(state.track.norm)
    return reduce(into: &state, action: .title(.valueChanged(value)))
  }

  private func trackChanged(_ state: inout State) -> Effect<Action> {
    let value = normValueTransform.normToValue(state.track.norm)
    return reduce(into: &state, action: .title(.valueChanged(value)))
  }

  private func valueChanged(_ state: inout State, value: Double) -> Effect<Action> {
    return .merge(
      reduce(into: &state, action: .title(.valueChanged(value))),
      reduce(into: &state, action: .track(.valueChanged(value)))
    )
  }
}

struct ControlView: View {
  private let store: StoreOf<ControlFeature>
  @Environment(\.auv3ControlsTheme) private var theme

  init(store: StoreOf<ControlFeature>) {
    self.store = store
  }

  var body: some View {
    VStack(alignment: .center, spacing: -8) {
      TrackView(store: store.scope(state: \.track, action: \.track))
      TitleView(store: store.scope(state: \.title, action: \.title))
    }
  }
}

struct ControlViewPreview: PreviewProvider {
  static let param = AUParameterTree.createParameter(
    withIdentifier: "RELEASE",
    name: "Release",
    address: 1,
    min: 0.0,
    max: 100.0,
    unit: .generic,
    unitName: nil,
    valueStrings: nil,
    dependentParameters: nil
  )
  static let config = KnobConfig()
  static var store = Store( initialState: ControlFeature.State(
    displayName: param.displayName,
    norm: 0.0
  )) {
    ControlFeature(formatter: KnobValueFormatter.duration(), normValueTransform: .init(parameter: param))
  }

  static var previews: some View {
    VStack {
      ControlView(store: store)
        .frame(width: 140, height: 140)
      Button {
        store.send(.valueChanged(0))
      } label: {
        Text("Go to 0")
      }
      Button {
        store.send(.valueChanged(40))
      } label: {
        Text("Go to 40")
      }
    }
  }
}
