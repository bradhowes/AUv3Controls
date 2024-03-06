import AVFoundation
import ComposableArchitecture
import SwiftUI

@Reducer
public struct ControlFeature {
  let config: KnobConfig

  public struct State: Equatable {
    var title: TitleFeature.State
    var track: TrackFeature.State

    public init(config: KnobConfig, value: Double) {
      self.title = .init()
      self.track = .init(norm: config.valueToNorm(value))
    }
  }

  public enum Action: Equatable {
    case title(TitleFeature.Action)
    case track(TrackFeature.Action)
    case valueChanged(Double)
  }

  public var body: some Reducer<State, Action> {
    Scope(state: \.track, action: /Action.track) { TrackFeature(config: config) }
    Scope(state: \.title, action: /Action.title) { TitleFeature(config: config) }

    Reduce { state, action in
      switch action {

      case let .track(trackAction):
        let value = config.normToValue(state.track.norm)
        return .send(.title(.valueChanged(value)))

      case let .valueChanged(value):
        return .merge(
          .send(.title(.valueChanged(value))),
          .send(.track(.valueChanged(value)))
        )

      default:
        return .none
      }
    }
  }
}

struct ControlView: View {
  let store: StoreOf<ControlFeature>
  let config: KnobConfig
  let proxy: ScrollViewProxy?

  init(store: StoreOf<ControlFeature>, config: KnobConfig, proxy: ScrollViewProxy?) {
    self.store = store
    self.config = config
    self.proxy = proxy
  }

  var body: some View {
    VStack(spacing: 0.0) {
      TrackView(store: store.scope(state: \.track, action: \.track), config: config)
      TitleView(store: store.scope(state: \.title, action: \.title), config: config, proxy: proxy)
    }
  }
}

struct ControlViewPreview: PreviewProvider {
  static let param = AUParameterTree.createParameter(withIdentifier: "RELEASE", name: "Release", address: 1,
                                                     min: 0.0, max: 100.0, unit: .generic, unitName: nil,
                                                     valueStrings: nil, dependentParameters: nil)
  static let config = KnobConfig(parameter: param, logScale: false, theme: Theme())
  @State static var store = Store(initialState: ControlFeature.State(config: config,
                                                                     value: Double(param.value))) {
    ControlFeature(config: config)
  }

  static var previews: some View {
    ControlView(store: store, config: config, proxy: nil)
      .padding()
  }
}
