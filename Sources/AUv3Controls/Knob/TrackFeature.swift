import AVFoundation
import ComposableArchitecture
import SwiftUI

@Reducer
public struct TrackFeature {
  let config: KnobConfig

  @ObservableState
  public struct State: Equatable, Sendable {
    var norm: Double
    var lastDrag: CGPoint?
  }

  public enum Action: Equatable {
    case dragChanged(start: CGPoint, position: CGPoint)
    case dragEnded(start: CGPoint, position: CGPoint)
  }

  public var body: some Reducer<State, Action> {
    Reduce { state, action in

      func calcNorm(last: CGPoint, position: CGPoint) -> Double {
        (state.norm + config.dragChangeValue(last: last, position: position)).clamped(to: 0.0...1.0)
      }

      switch action {
      case let .dragChanged(start, position):
        state.norm = calcNorm(last: state.lastDrag ?? start, position: position)
        state.lastDrag = position
        return .none

      case let .dragEnded(start, position):
        state.norm = calcNorm(last: state.lastDrag ?? start, position: position)
        state.lastDrag = nil
        return .none
      }
    }
  }
}

/**
 View that shows a circular track and an overlay indicator track that represents the current value.
 Dragging vertically on the view will change the current value.
 */
struct TrackView: View {
  let store: StoreOf<TrackFeature>
  let config: KnobConfig

  var body: some View {
    Rectangle()
      .fill(.background)
      .frame(width: config.controlDiameter, height: config.controlDiameter)
      .overlay {
        rotatedCircle
          .trackStroke(config: config)
        rotatedCircle
          .indicatorStroke(config: config, norm: store.norm)
      }
      .gesture(DragGesture(minimumDistance: 0.0, coordinateSpace: .local)
        .onChanged { store.send(.dragChanged(start: $0.startLocation, position: $0.location)) }
        .onEnded { store.send(.dragEnded(start: $0.startLocation, position: $0.location))
        })
  }

  var rotatedCircle: some Shape {
    Circle()
      .rotation(.degrees(-270))
  }
}

private extension Shape {

  func trackStroke(config: KnobConfig) -> some View {
    self.trim(from: config.indicatorStartAngle.normalized, to: config.indicatorEndAngle.normalized)
      .stroke(config.theme.controlBackgroundColor, style: StrokeStyle(lineWidth: 2, lineCap: .round))
      .frame(width: config.controlDiameter, height: config.controlDiameter, alignment: .center)
  }

  func indicatorStroke(config: KnobConfig, norm: Double) -> some View {
    self.trim(from: config.indicatorStartAngle.normalized, to: config.normToTrim(norm))
      .stroke(config.theme.controlForegroundColor, style: StrokeStyle(lineWidth: config.indicatorStrokeWidth,
                                                                      lineCap: .round))
      .frame(width: config.controlDiameter, height: config.controlDiameter, alignment: .center)
  }
}

struct TrackViewPreview: PreviewProvider {
  static let param = AUParameterTree.createParameter(withIdentifier: "RELEASE", name: "Release", address: 1,
                                                     min: 0.0, max: 100.0, unit: .generic, unitName: nil,
                                                     valueStrings: nil, dependentParameters: nil)
  static let config = KnobConfig(parameter: param, logScale: false, theme: Theme())
  @State static var store = Store(initialState: TrackFeature.State(norm: 0.5)) {
    TrackFeature(config: config)
  }

  static var previews: some View {
    TrackView(store: store, config: config)
  }
}
