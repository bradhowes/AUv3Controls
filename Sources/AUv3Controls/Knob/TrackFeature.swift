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

    public init(norm: Double, normValueTransform: NormValueTransform, config: KnobConfig) {
      self.config = config
      self.normValueTransform = normValueTransform
      self.norm = norm
    }
  }

  public enum Action: Equatable, Sendable {
    case dragStarted(Double)
    case dragChanged(Double)
    case dragEnded(Double)
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
      case let .dragStarted(value): return normChanged(&state, norm: value)
      case let .dragChanged(value): return normChanged(&state, norm: value)
      case let .dragEnded(value): return normChanged(&state, norm: value)
      case let .normChanged(value): return normChanged(&state, norm: value)
      case let .valueChanged(value): return normChanged(&state, norm: state.normValueTransform.valueToNorm(value))
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

  @State private var controlRadius: Double = .zero
  @State private var dragScaling: Double = 1.0
  @State private var maxDragChangeRegionWidthHalf = 8.0
  @State private var lastDrag: CGPoint?

  var foregroundGradient: RadialGradient {
    .init(
      gradient: Gradient(colors: [.white, theme.controlForegroundColor, .black]),
      center: .center,
      startRadius: 0, endRadius: 100
    )
  }

  var backgroundGradient: RadialGradient {
    .init(
      gradient: Gradient(colors: [.white, theme.controlBackgroundColor, .black]),
      center: .center,
      startRadius: 0,
      endRadius: 100
    )
  }

  public init(store: StoreOf<TrackFeature>) {
    self.store = store
  }

  public var body: some View {
    Rectangle()
      .fill(.clear)
      .onGeometryChange(for: CGSize.self) { proxy in
        proxy.size
      } action: { newValue in
        controlRadius = newValue.height / 2
        dragScaling = 1.0 / (newValue.height * theme.touchSensitivity)
        maxDragChangeRegionWidthHalf = max(8, newValue.height * theme.maxChangeRegionWidthPercentage) / 2
      }
      .contentShape(.interaction, Circle())
      .aspectRatio(1, contentMode: .fit)
      .overlay {
        rotatedCircle
          .trackStroke(config: config, theme: theme, gradient: backgroundGradient)
        rotatedCircle
          .progressStroke(config: config, theme: theme, gradient: foregroundGradient, norm: store.norm)
        rotatedIndicator
          .stroke(foregroundGradient, style: theme.controlValueStrokeStyle)
      }
      .offset(y: -16)
      .animation(.smooth, value: store.norm)
      .onTapGesture(count: 1) {
        store.send(.viewTapped)
      }
      .highPriorityGesture(DragGesture(minimumDistance: 0.0, coordinateSpace: .local)
        .onChanged {
          let norm = calcNorm(startLocation: $0.startLocation, location: $0.location)
          if lastDrag == nil {
            store.send(.dragStarted(norm))
          } else {
            store.send(.dragChanged(norm))
          }
          lastDrag = $0.location
        }
        .onEnded {
          store.send(.dragEnded(calcNorm(startLocation: $0.startLocation, location: $0.location)))
          lastDrag = nil
        }
      )
  }

  func calcNorm(startLocation: CGPoint, location: CGPoint) -> Double {
    (store.norm + dragChangeValue(last: lastDrag ?? startLocation, position: location))
      .clamped(to: 0.0...1.0)
  }

  func dragChangeValue(last: CGPoint, position: CGPoint) -> Double {
    let dY = last.y - position.y
    // Calculate dX for dY scaling effect -- max value must be < 1/2 of controlSize
    let dX = min(abs(position.x - controlRadius), controlRadius - 1)
    // Calculate "scrubber" scaling effect, where the change in dx gets smaller the further away from the center one
    // moves the touch/pointer. No scaling if in +/- maxChangeRegionWidthHalf vertical path in the middle of the knob,
    // otherwise the value gets smaller than 1.0 as the touch moves farther away outside of the maxChangeRegionWidthHalf
    let scrubberScaling = (dX < maxDragChangeRegionWidthHalf
                           ? 1.0
                           : (1.0 - (dX - maxDragChangeRegionWidthHalf) / controlRadius))
    // Finally, calculate change to `norm` value
    return dY * dragScaling * scrubberScaling
  }

  var rotatedCircle: some Shape {
    Circle()
      .rotation(.degrees(-270))
      .inset(by: theme.controlValueStrokeLineWidthHalf)
  }

  var indicator: some Shape {
    var path = Path()
    // Starting point at the end of the progress track (once rotated)
    path.move(to: .init(x: theme.controlValueStrokeLineWidthHalf, y: controlRadius))
    // Ending point that is towards the center
    path.addLine(to: .init(x: min(theme.controlIndicatorLength, controlRadius), y: controlRadius))
    return path
  }

  var rotatedIndicator: some Shape {
    return indicator
      .rotation(.degrees(-50 + Double(store.norm) * 280))
  }
}

private extension Shape {

  func trackStroke(config: KnobConfig, theme: Theme, gradient: RadialGradient) -> some View {
    return trim(
      from: theme.controlIndicatorStartAngleNormalized,
      to: theme.controlIndicatorEndAngleNormalized
    )
    .stroke(gradient, style: theme.controlTrackStrokeStyle)
  }

  func progressStroke(config: KnobConfig, theme: Theme, gradient: RadialGradient, norm: Double) -> some View {
    return trim(
      from: theme.controlIndicatorStartAngleNormalized,
      to: theme.endTrim(for: norm)
    )
    .stroke(gradient, style: theme.controlValueStrokeStyle)
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
        .frame(width: 140, height: 140)
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
