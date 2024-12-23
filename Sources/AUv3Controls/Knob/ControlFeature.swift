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
  private let trackFeature: TrackFeature
  private let titleFeature: TitleFeature

  public init(config: KnobConfig) {
    self.trackFeature = TrackFeature()
    self.titleFeature = TitleFeature()
  }

  public struct State: Equatable {
    let config: KnobConfig
    var title: TitleFeature.State
    var track: TrackFeature.State

    public init(config: KnobConfig, value: Double) {
      self.config = config
      self.title = .init(config: config)
      self.track = .init(config: config, norm: config.valueToNorm(value))
    }
  }

  public enum Action: Equatable, Sendable {
    case title(TitleFeature.Action)
    case track(TrackFeature.Action)
    case valueChanged(Double)
  }

  public var body: some Reducer<State, Action> {
    Scope(state: \.track, action: \.track) { trackFeature }
    Scope(state: \.title, action: \.title) { titleFeature }

    Reduce { state, action in
      switch action {

      case .title:
        return .none

      case .track:
        let value = state.config.normToValue(state.track.norm)
        return updateTitleEffect(state: &state.title, value: value)

      case let .valueChanged(value):
        return .merge(
          updateTitleEffect(state: &state.title, value: value),
          updateTrackEffect(state: &state.track, value: value)
        )
      }
    }
  }
}

private extension ControlFeature {

  func updateTitleEffect(state: inout TitleFeature.State, value: Double) -> Effect<Action> {
    titleFeature.reduce(into: &state, action: .valueChanged(value))
      .map(Action.title)
  }

  func updateTrackEffect(state: inout TrackFeature.State, value: Double) -> Effect<Action> {
    trackFeature.reduce(into: &state, action: .valueChanged(value))
      .map(Action.track)
  }
}

struct ControlView: View {
  private let store: StoreOf<ControlFeature>
  private let config: KnobConfig

  init(store: StoreOf<ControlFeature>, config: KnobConfig) {
    self.store = store
    self.config = config
  }

  var body: some View {
    VStack(spacing: config.theme.controlTitleGap) {
      TrackView(store: store.scope(state: \.track, action: \.track), config: config)
      TitleView(store: store.scope(state: \.title, action: \.title), config: config)
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
  static let config = KnobConfig(parameter: param, theme: Theme())
  static var store = Store(
    initialState: ControlFeature.State(
      config: config,
      value: Double(param.value)
    )
  ) {
    ControlFeature(config: config)
  }

  static var previews: some View {
    VStack {
      ControlView(store: store, config: config)
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
