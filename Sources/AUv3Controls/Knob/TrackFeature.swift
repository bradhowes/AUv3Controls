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
  private let config: KnobConfig

  init(config: KnobConfig) {
    self.config = config
  }

  @ObservableState
  public struct State: Equatable, Sendable {
    var norm: Double
    var lastDrag: CGPoint?
  }

  public enum Action: Equatable, Sendable {
    case dragStarted(start: CGPoint, position: CGPoint)
    case dragChanged(start: CGPoint, position: CGPoint)
    case dragEnded(start: CGPoint, position: CGPoint)
    case valueChanged(Double)
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

  public var body: some Reducer<State, Action> {
    Reduce { state, action in

      switch action {
      case let .dragStarted(start, position), let .dragChanged(start, position):
        return updateFromDragEffect(state: &state, start: state.lastDrag ?? start, position: position,
                                    atEnd: false)

      case let .dragEnded(start, position):
        return updateFromDragEffect(state: &state, start: state.lastDrag ?? start, position: position,
                                    atEnd: true)

      case let .valueChanged(value):
        let normValue = config.valueToNorm(value)
        return .run { send in
          await send(.normChanged(normValue))
        }.animation(.easeInOut(duration: config.theme.controlChangeAnimationDuration))

      case let .normChanged(value):
        state.norm = value
        return .none
      }
    }
  }
}

private extension TrackFeature {

  func updateFromDragEffect(state: inout State, start: CGPoint, position: CGPoint, atEnd: Bool) -> Effect<Action> {
    state.norm = (state.norm + config.dragChangeValue(last: start, position: position)).clamped(to: 0.0...1.0)
    state.lastDrag = atEnd ? nil : position
    return .none
  }
}

/**
 View that shows a circular track and an overlay indicator track that represents the current value.
 Dragging vertically on the view will change the current value.
 */
public struct TrackView: View {
  private let store: StoreOf<TrackFeature>
  private let config: KnobConfig

  public init(store: StoreOf<TrackFeature>, config: KnobConfig) {
    self.store = store
    self.config = config
  }

  public var body: some View {
    Rectangle()
      .fill(.background)
      .frame(width: config.controlDiameter, height: config.controlDiameter)
      .overlay {
        rotatedCircle
          .trackStroke(config: config)
        rotatedCircle
          .progressStroke(config: config, norm: store.norm)
        rotatedIndicator
          .stroke(config.theme.controlForegroundColor, style: config.theme.controlValueStrokeStyle)
      }
      .gesture(DragGesture(minimumDistance: 0.0, coordinateSpace: .local)
        .onChanged {
          let action: TrackFeature.Action = store.lastDrag == nil ?
            .dragStarted(start: $0.startLocation, position: $0.location) :
            .dragChanged(start: $0.startLocation, position: $0.location)
          store.send(action)
        }
        .onEnded { store.send(.dragEnded(start: $0.startLocation, position: $0.location))
        })
  }

  var rotatedCircle: some Shape {
    Circle()
      .rotation(.degrees(-270))
  }

  var indicator: some Shape {
    var path = Path()
    path.move(to: .init(x: 0.0, y: config.controlRadius))
    path.addLine(to: .init(x: config.theme.controlIndicatorLength, y: config.controlRadius))
    return path
  }

  var rotatedIndicator: some Shape {
    indicator
      .rotation(.degrees(-50 + store.norm * 280))
  }
}

private extension Shape {

  func trackStroke(config: KnobConfig) -> some View {
    self.trim(from: config.indicatorStartAngle.normalized, to: config.indicatorEndAngle.normalized)
      .stroke(config.theme.controlBackgroundColor, style: config.theme.controlTrackStrokeStyle)
      .frame(width: config.controlDiameter, height: config.controlDiameter, alignment: .center)
  }

  func progressStroke(config: KnobConfig, norm: Double) -> some View {
    self.trim(from: config.indicatorStartAngle.normalized, to: config.normToTrim(norm))
      .stroke(config.theme.controlForegroundColor, style: config.theme.controlValueStrokeStyle)
      .frame(width: config.controlDiameter, height: config.controlDiameter, alignment: .center)
  }
}

struct TrackViewPreview: PreviewProvider {
  static let param = AUParameterTree.createParameter(withIdentifier: "RELEASE", name: "Release", address: 1,
                                                     min: 0.0, max: 100.0, unit: .generic, unitName: nil,
                                                     valueStrings: nil, dependentParameters: nil)
  static let config = KnobConfig(parameter: param, theme: Theme())
  @State static var store = Store(initialState: TrackFeature.State(norm: 0.5)) {
    TrackFeature(config: config)
  }

  static var previews: some View {
    VStack {
      TrackView(store: store, config: config)
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
