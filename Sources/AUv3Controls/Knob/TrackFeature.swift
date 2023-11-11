import AVFoundation
import Clocks
import ComposableArchitecture
import SwiftUI


struct TrackFeature: Reducer {
  let config: KnobConfig
  
  struct State: Equatable {
    var norm: Double
    var lastDrag: CGPoint?
  }

  enum Action: Equatable, Sendable {
    case dragChanged(start: CGPoint, position: CGPoint)
    case dragEnded(start: CGPoint, position: CGPoint)
  }

  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case let .dragChanged(start, position):
      print("dragChanged:", start, position)
      let newNorm = (state.norm +
                     config.dragChangeValue(last: state.lastDrag ?? start, position: position))
        .clamped(to: 0.0...1.0)
      state.norm = newNorm
      state.lastDrag = position
      return .none

    case let .dragEnded(start, position):
      print("dragEnded:", start, position)
      let newNorm = (state.norm +
                     config.dragChangeValue(last: state.lastDrag ?? start, position: position))
        .clamped(to: 0.0...1.0)
      state.norm = newNorm
      state.lastDrag = nil
      return .none
    }
  }
}

struct TrackView: View {
  let store: StoreOf<TrackFeature>
  let config: KnobConfig
  
  var body: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      Rectangle()
        .fill(.background)
        .frame(width: config.controlDiameter, height: config.controlDiameter)
        .overlay {
          Circle()
            .rotation(.degrees(-270))
            .trim(from: config.indicatorStartAngle.normalized,
                  to: config.indicatorEndAngle.normalized)
            .stroke(config.theme.controlBackgroundColor,
                    style: StrokeStyle(lineWidth: 2, lineCap: .round))
            .frame(width: config.controlDiameter, height: config.controlDiameter, alignment: .center)
          Circle()
            .rotation(.degrees(-270))
            .trim(from: config.indicatorStartAngle.normalized, to: config.normToTrim(viewStore.norm))
            .stroke(config.theme.controlForegroundColor,
                    style: StrokeStyle(lineWidth: config.indicatorStrokeWidth, lineCap: .round))
            .frame(width: config.controlDiameter, height: config.controlDiameter, alignment: .center)
        }
        .gesture(DragGesture(minimumDistance: 0.0, coordinateSpace: .local)
          .onChanged { value in
            viewStore.send(.dragChanged(start: value.startLocation, position: value.location))
          }
          .onEnded { value in
            viewStore.send(.dragEnded(start: value.startLocation, position: value.location))
          })
    }
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
