import AVFoundation
import ComposableArchitecture
import SwiftUI

struct ControlFeature: Reducer {
  let config: KnobConfig
  let trackFeature: TrackFeature
  let titleFeature: TitleFeature

  init(config: KnobConfig) {
    self.config = config
    self.trackFeature = TrackFeature(config: config)
    self.titleFeature = TitleFeature(config: config)
  }

  struct State: Equatable {
    var track: TrackFeature.State
    var title: TitleFeature.State

    init(track: TrackFeature.State, title: TitleFeature.State) {
      self.track = track
      self.title = title
    }

    init(config: KnobConfig) {
      self.track = .init(norm: config.valueToNorm(Double(config.parameter.value)))
      self.title = .init()
    }
  }

  enum Action: Equatable, Sendable {
    case track(TrackFeature.Action)
    case title(TitleFeature.Action)
  }

  var body: some Reducer<State, Action> {
    Scope(state: \.track, action: /Action.track) {
      trackFeature
    }
    Scope(state: \.title, action: /Action.title) {
      titleFeature
    }
    Reduce { state, action in
      switch action {
      case let .track(trackAction):
        switch trackAction {
        case .dragChanged:
          let value = config.normToValue(state.track.norm)
          return titleFeature.reduce(into: &state.title, action: .valueChanged(value))
            .map { Action.title($0) }
        case .dragEnded:
            return .none
        }
      case .title:
        return .none
      }
    }
  }
}

struct ControlView: View {
  let store: StoreOf<ControlFeature>
  let config: KnobConfig

  var body: some View {
    VStack(spacing: 0.0) {
      TrackView(store: store.scope(state: \.track, action: { .track($0) }), config: config)
      TitleView(store: store.scope(state: \.title, action: { .title($0) }), config: config)
    }
  }
}

struct ControlViewPreview: PreviewProvider {
  static let param = AUParameterTree.createParameter(withIdentifier: "RELEASE", name: "Release", address: 1,
                                                     min: 0.0, max: 100.0, unit: .generic, unitName: nil,
                                                     valueStrings: nil, dependentParameters: nil)
  static let config = KnobConfig(parameter: param, logScale: false, theme: Theme())
  @State static var store = Store(initialState: ControlFeature.State(config: config)) {
    ControlFeature(config: config)
  }

  static var previews: some View {
    ControlView(store: store, config: config)
  }
}
