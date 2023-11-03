import ComposableArchitecture
import AVFoundation
import SwiftUI

public struct KnobReducer: Reducer {

  public struct State: Equatable {

    let parameter: AUParameter
    var value: Double
    let config: KnobConfig

    var formattedValue: String = ""
    var observerToken: AUParameterObserverToken?
    var showingValue: Bool = false
    var showingValueEditor: Bool = false
    var lastY: CGFloat?
    @BindingState var focusedField: Field?
    
    var controlWidth: CGFloat { showingValueEditor ? 200 : config.controlWidth }

    var norm: Double = 0.0 {
      didSet {
        self.value = config.normToValue(norm)
        self.formattedValue = config.normToFormattedValue(norm)
      }
    }

    public init(parameter: AUParameter, value: Double = 0.0, config: KnobConfig) {
      self.parameter = parameter
      self.value = value
      self.parameter.setValue(AUValue(value), originator: nil)
      self.config = config
    }
  }

  @Dependency(\.continuousClock) var clock

  private enum CancelID { case showingValueTask }

  public enum Field: Hashable { case value }

  public enum Action: BindableAction, Equatable {
    case binding(BindingAction<State>)
    case acceptButtonPressed
    case cancelButtonPressed
    case clearButtonPressed
    case gainedFocus
    case labelTapped
    case observedValueChanged(AUValue)
    case stoppedObserving
    case dragChanged(DragGesture.Value)
    case dragEnded(DragGesture.Value)
    case showingValueTimerStopped
    case textChanged(String)
    case viewAppeared
    case viewDisappeared
  }

  func showingValueEffect(state: inout State) -> Effect<Action> {
    state.showingValue = true
    state.formattedValue = state.config.formattedValue(state.value)
    return .run { send in
      try await Task.sleep(for: .seconds(1.25))
      await send(.showingValueTimerStopped)
    }
  }

  public func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {

    case .acceptButtonPressed:
      state.focusedField = nil
      state.showingValueEditor = false
      if let newValue = Double(state.formattedValue) {
        state.norm = state.config.valueToNorm(newValue)
      }
      return showingValueEffect(state: &state)

    case .binding:
      return .none

    case .cancelButtonPressed:
      state.focusedField = nil
      state.showingValueEditor = false
      return .none

    case .clearButtonPressed:
      state.formattedValue = ""
      return .none

    case .gainedFocus:
      return .none

    case .labelTapped:
      state.showingValueEditor = true
      state.formattedValue = state.config.formattedValue(state.value)
      state.focusedField = .value
      return .none

    case let.observedValueChanged(value):
      state.value = Double(value)
      return showingValueEffect(state: &state)

    case .stoppedObserving:
      state.observerToken = nil
      return .none

    case let .dragChanged(dragValue):
      let lastY = state.lastY ?? dragValue.startLocation.y
      let dY = lastY - dragValue.location.y
      // Calculate dX for dY scaling effect -- max value must be < 1/2 of controlSize
      let dX = min(abs(dragValue.location.x - state.config.halfControlSize), state.config.halfControlSize - 1)
      // Calculate scaling effect -- no scaling if in small vertical path in the middle of the knob, otherwise the
      // value gets smaller than 1.0 as the touch moves farther away from the center.
      let scrubberScaling = (dX < state.config.maxChangeRegionWidthHalf ? 1.0 : (1.0 - dX / state.config.halfControlSize))
      // Finally, calculate change to `norm` value
      let normChange = dY * state.config.dragScaling * scrubberScaling
      // print(lastY, dragValue.location.y)
      let newNorm = max(min(normChange + state.norm, 1.0), 0.0)
      state.norm = newNorm
      state.lastY = dragValue.location.y
      state.showingValue = true
      return .cancel(id: CancelID.showingValueTask)

    case .dragEnded:
      state.lastY = nil
      return showingValueEffect(state: &state)

    case .showingValueTimerStopped:
      state.showingValue = false
      return .none

    case let .textChanged(newValue):
      state.formattedValue = newValue
      return .none

    case .viewAppeared:
      let valueUpdates = state.parameter.startObserving(&state.observerToken)
      return .run { send in
        for await value in valueUpdates {
          await send(.observedValueChanged(value))
        }
        await send(.stoppedObserving)
      }

    case .viewDisappeared:
      return .cancel(id: CancelID.showingValueTask)
    }
  }
}

struct KnobView: View {
  let store: StoreOf<KnobReducer>
  let scrollViewProxy: ScrollViewProxy?
  @FocusState var focusedField: KnobReducer.Field?

  var body: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      ZStack(alignment: .bottom) {
        VStack(spacing: 0.0) {
          Rectangle()
            .fill(.background)
            .frame(width: viewStore.config.controlWidth, height: viewStore.config.controlWidth)
            .overlay {
              Circle()
                .rotation(.degrees(-270))
                .trim(from: viewStore.config.minimumAngle.degrees / 360.0,
                      to: viewStore.config.maximumAngle.degrees / 360.0)
                .stroke(Color("knobBackground", bundle: nil),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .frame(width: viewStore.config.controlWidth,
                       height: viewStore.config.controlWidth,
                       alignment: .center)
                .padding(.horizontal, 4.0)
              Circle()
                .rotation(.degrees(-270))
                .trim(from: viewStore.config.minimumAngle.degrees / 360.0, 
                      to: viewStore.config.normToTrim(viewStore.norm))
                .stroke(Color("knobForeground", bundle: nil),
                        style: StrokeStyle(lineWidth: viewStore.config.valueStrokeWidth, lineCap: .round))
                .frame(width: viewStore.config.controlWidth, height: viewStore.config.controlWidth, alignment: .center)
            } // NOTE: coordinateSpace *must* be `.local` for the drag scaling calculations
            .gesture(DragGesture(minimumDistance: 0.0, coordinateSpace: .local)
              .onChanged { value in
                viewStore.send(.dragChanged(value))
              }
              .onEnded { value in
                viewStore.send(.dragEnded(value))
              })
          ZStack {
            Text(viewStore.config.title)
              .opacity(viewStore.showingValue ? 0.0 : 1.0)  // fade OUT when value changes
            Text(viewStore.formattedValue)
              .opacity(viewStore.showingValue ? 1.0 : 0.0)  // fade IN when value changes
          }
          .font(viewStore.config.font)
          .foregroundColor(Color("textColor", bundle: nil))
          .animation(.linear, value: viewStore.showingValue)
          .onTapGesture(count: 1) {
            viewStore.send(.labelTapped, animation: .smooth)
            scrollViewProxy?.scrollTo(viewStore.parameter.address)
          }
        }
        .opacity(viewStore.showingValueEditor ? 0.0 : 1.0)
        .scaleEffect(viewStore.showingValueEditor ? 0.0 : 1.0)

        // Editor
        VStack(alignment: .center, spacing: 12) {
          HStack(spacing: 12) {
            Text(viewStore.config.title)
            ZStack(alignment: .trailing) {
              TextField("",
                        text: viewStore.binding(get: \.formattedValue, send: { .textChanged($0) }))
                .keyboardType(.numbersAndPunctuation)
                .focused($focusedField, equals: .value)
                .submitLabel(.go)
                .onSubmit { viewStore.send(.acceptButtonPressed, animation: .smooth) }
                .disableAutocorrection(true)
                .textFieldStyle(.roundedBorder)
              Image(systemName: "xmark.circle.fill")
                .foregroundColor(.secondary)
                .onTapGesture(count: 1) { viewStore.send(.clearButtonPressed, animation: .smooth) }
                .padding(.trailing, 4)
            }
          }
          HStack(spacing: 24) {
            Button(action: { viewStore.send(.acceptButtonPressed, animation: .smooth) }) {
              Text("Accept")
            }.buttonStyle(.bordered)

            Button(action: { viewStore.send(.cancelButtonPressed, animation: .smooth) }) {
              Text("Cancel")
            }.buttonStyle(.borderless)
          }
        }
        .padding()
        .background(.quaternary)
        .clipShape(.rect(cornerRadius: 6))
        .opacity(viewStore.showingValueEditor ? 1.0 : 0.0)
        .scaleEffect(viewStore.showingValueEditor ? 1.0 : 0.0)
        .bind(viewStore.$focusedField, to: self.$focusedField)
      }
      .frame(maxWidth: viewStore.controlWidth, maxHeight: viewStore.config.maxHeight)
      .frame(width: viewStore.controlWidth, height: viewStore.config.maxHeight)
      .id(viewStore.parameter.address)
      .animation(.linear, value: viewStore.showingValueEditor)
    }
  }
}

struct KnobViewPreview : PreviewProvider {
  static let config = KnobConfig(title: "Release", id: 1, minimumValue: 0.0, maximumValue: 100.0,
                                 logScale: false)
  static let param = AUParameterTree.createParameter(withIdentifier: "RELEASE", name: "Release", address: 1,
                                                     min: 0.0, max: 100.0, unit: .generic, unitName: nil,
                                                     valueStrings: nil, dependentParameters: nil)
  @State static var store = Store(initialState: KnobReducer.State(parameter: param, value: 0.0, config: config)) {
    KnobReducer()
  }

  static var previews: some View {
    KnobView(store: store, scrollViewProxy: nil)
  }
}
