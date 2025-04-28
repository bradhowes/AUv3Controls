// Copyright © 2025 Brad Howes. All rights reserved.

import AVFoundation
import ComposableArchitecture
import SwiftUI

/**
 Shows two circular tracks, one that indicates the total possible values of the control, and the other that shows the
 current control value. The view aspects of the control are configured using properties found in the `KnobConfig`
 instance given when constructed.

 Vertically dragging in the control changes the value. Moving the touch/pointer away from the center will increase the
 sensitivity of the vertical movements (smaller changes for the same distance moved).
 */
@Reducer
public struct TrackFeature {

  @ObservableState
  public struct State: Equatable {
    let config: KnobConfig
    let normValueTransform: NormValueTransform
    var norm: Double
    var lastDrag: CGPoint?

    public init(norm: Double, normValueTransform: NormValueTransform, config: KnobConfig) {
      self.config = config
      self.normValueTransform = normValueTransform
      self.norm = norm
    }
  }

  public enum Action: Equatable, Sendable {
    case dragStarted(norm: Double, position: CGPoint)
    case dragChanged(norm: Double, position: CGPoint)
    case dragEnded(norm: Double)
    case valueChanged(Double)
    case viewTapped
    case normChanged(Double)

    var cause: AUParameterAutomationEventType? {
      switch self {
      case .dragStarted: return .touch
      case .dragChanged: return .value
      case .dragEnded: return .release
      default: return nil
      }
    }
  }

  public init() {}

  public var body: some Reducer<State, Action> {
    Reduce { state, action in

      switch action {
      case let .dragStarted(norm, position), let .dragChanged(norm, position):
        state.norm = norm
        state.lastDrag = position
        return .none

      case let .dragEnded(norm):
        state.lastDrag = nil
        state.norm = norm
        return .none

      case let .valueChanged(value): return normChanged(&state, norm: state.normValueTransform.valueToNorm(value))
      case let .normChanged(value): return normChanged(&state, norm: value)

      case .viewTapped: return .none
      }
    }
  }
}

private extension TrackFeature {

  func normChanged(_ state: inout State, norm: Double) -> Effect<Action> {
    state.norm = norm
    return .none
  }
}

/**
 View that shows a circular track and an overlay indicator track that represents the current value.
 Dragging vertically on the view will change the current value.
 */
public struct TrackView: View {
  private let store: StoreOf<TrackFeature>
  private var config: KnobConfig { store.config }
  @Environment(\.auv3ControlsTheme) private var theme

  public init(store: StoreOf<TrackFeature>) {
    self.store = store
  }

  public var body: some View {
    Rectangle()
      .fill(.clear)
      .frame(width: theme.controlDiameter, height: theme.controlDiameter)
      .contentShape(.interaction, Circle())
      .overlay {
        rotatedCircle
          .trackStroke(config: config, theme: theme)
        rotatedCircle
          .progressStroke(config: config, theme: theme, norm: store.norm)
        rotatedIndicator
          .stroke(theme.controlForegroundColor, style: theme.controlValueStrokeStyle)
      }
      .animation(.smooth, value: store.norm)
      .onTapGesture(count: 1) {
        store.send(.viewTapped)
      }
      .simultaneousGesture(DragGesture(minimumDistance: 0.0, coordinateSpace: .local)
        .onChanged {
          let norm = calcNorm(startLocation: $0.startLocation, location: $0.location)
          let action: TrackFeature.Action = store.lastDrag == nil ?
            .dragStarted(norm: norm, position: $0.location) :
            .dragChanged(norm: norm, position: $0.location)
          store.send(action)
        }
        .onEnded {
          store.send(.dragEnded(norm: calcNorm(startLocation: $0.startLocation, location: $0.location)))
        }
      )
  }

  func calcNorm(startLocation: CGPoint, location: CGPoint) -> Double {
    (store.norm + theme.dragChangeValue(last: store.lastDrag ?? startLocation, position: location))
      .clamped(to: 0.0...1.0)
  }

  var rotatedCircle: some Shape {
    Circle()
      .rotation(.degrees(-270))
      .inset(by: theme.controlValueStrokeLineWidthHalf)
  }

  var indicator: some Shape {
    var path = Path()
    // Starting point at the end of the progress track (once rotated)
    path.move(to: .init(x: theme.controlValueStrokeLineWidthHalf, y: theme.controlRadius))
    // Ending point that is towards the center
    path.addLine(to: .init(x: min(theme.controlIndicatorLength, theme.controlRadius), y: theme.controlRadius))
    return path
  }

  var rotatedIndicator: some Shape {
    indicator
      .rotation(.degrees(-50 + Double(store.norm) * 280))
  }
}

private extension Shape {

  func trackStroke(config: KnobConfig, theme: Theme) -> some View {
    trim(
      from: theme.controlIndicatorStartAngleNormalized,
      to: theme.controlIndicatorEndAngleNormalized
    )
    .stroke(theme.controlBackgroundColor, style: theme.controlTrackStrokeStyle)
    .frame(width: theme.controlDiameter, height: theme.controlDiameter, alignment: .center)
  }

  func progressStroke(config: KnobConfig, theme: Theme, norm: Double) -> some View {
    trim(
      from: theme.controlIndicatorStartAngleNormalized,
      to: theme.endTrim(for: norm)
    )
    .stroke(theme.controlForegroundColor, style: theme.controlValueStrokeStyle)
    .frame(width: theme.controlDiameter, height: theme.controlDiameter, alignment: .center)
  }
}

struct TrackViewPreview: PreviewProvider {
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
  @State static var store = Store(initialState: TrackFeature.State(
    norm: 0.5,
    normValueTransform: .init(parameter: param),
    config: config
  )) {
    TrackFeature()
  }

  static var previews: some View {
    VStack {
      TrackView(store: store)
      Button {
        store.send(.valueChanged(0.0))
      } label: {
        Text("Goto 0")
      }
      Button {
        store.send(.valueChanged(40.0))
      } label: {
        Text("Goto 40")
      }
      Button {
        store.send(.valueChanged(50.0))
      } label: {
        Text("Goto 50")
      }
      Button {
        store.send(.valueChanged(100.0))
      } label: {
        Text("Goto 100")
      }
    }
  }
}
