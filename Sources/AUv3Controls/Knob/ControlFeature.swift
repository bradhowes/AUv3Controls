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

  @ObservableState
  public struct State: Equatable {
    let normValueTransform: NormValueTransform
    var title: TitleFeature.State
    var track: TrackFeature.State

    public init(value: Double, normValueTransform: NormValueTransform, config: KnobConfig) {
      self.normValueTransform = normValueTransform
      self.title = .init(
        displayName: config.displayName,
        formatter: config.valueFormatter,
        showValueDuration: config.controlShowValueDuration
      )
      self.track = .init(norm: normValueTransform.valueToNorm(value), normValueTransform: normValueTransform, config: config)
    }
  }

  public enum Action: Equatable, Sendable {
    case title(TitleFeature.Action)
    case track(TrackFeature.Action)
    case valueChanged(Double)
  }

  public init() {}

  public var body: some Reducer<State, Action> {
    Scope(state: \.track, action: \.track) { TrackFeature() }
    Scope(state: \.title, action: \.title) { TitleFeature() }

    Reduce { state, action in
      switch action {

      case .title:
        return .none

      case .track:
        let value = state.normValueTransform.normToValue(state.track.norm)
        return reduce(into: &state, action: .title(.valueChanged(value)))

      case let .valueChanged(value):
        return .merge(
          reduce(into: &state, action: .title(.valueChanged(value))),
          reduce(into: &state, action: .track(.valueChanged(value)))
        )
      }
    }
  }
}

struct ControlView: View {
  private let store: StoreOf<ControlFeature>
  @Environment(\.auv3ControlsTheme) private var theme

  init(store: StoreOf<ControlFeature>) {
    self.store = store
  }

  var body: some View {
    VStack(spacing: theme.controlTitleGap) {
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
  static let config = KnobConfig(parameter: param)
  static var store = Store( initialState: ControlFeature.State(
    value: Double(param.value),
    normValueTransform: .init(parameter: param),
    config: config
  )) {
    ControlFeature()
  }

  static var previews: some View {
    VStack {
      ControlView(store: store)
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
