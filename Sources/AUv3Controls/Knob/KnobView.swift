import ComposableArchitecture
import AVFoundation
import SwiftUI

/**
 A circular knob that whose value is controlled by vertical motion inside it. Changing the value causes the current
 value to be displayed instead of the control's name. Tapping on the name transforms the know into a dialog box with
 a text field containing the current value and two buttons to accept and cancel any changes made to the value.
 */
struct KnobView: View {

  let store: StoreOf<KnobReducer>
  let config: KnobConfig
  let scrollViewProxy: ScrollViewProxy?

  var body: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      ZStack(alignment: .bottom) {
        control
        editor
          .bind(viewStore.$focusedField, to: self.$focusedField)
      }
      .frame(maxWidth: config.controlWidthIf(viewStore.showingValueEditor), maxHeight: config.maxHeight)
      .frame(width: config.controlWidthIf(viewStore.showingValueEditor), height: config.maxHeight)
      .id(viewStore.parameter.address)
      .animation(.linear, value: viewStore.showingValueEditor)
      .task { await viewStore.send(.viewAppeared).finish() }
    }
  }

  @FocusState var focusedField: KnobReducer.Field?
}

extension KnobView {

  var rotatedCircle: some Shape {
    Circle()
      .rotation(.degrees(-270))
  }

  var track: some View {
    rotatedCircle
      .trim(from: config.indicatorStartAngle.normalized,
            to: config.indicatorEndAngle.normalized)
      .stroke(config.theme.controlBackgroundColor,
              style: StrokeStyle(lineWidth: 2, lineCap: .round))
      .frame(width: config.controlDiameter,
             height: config.controlDiameter,
             alignment: .center)
      .padding(.horizontal, 4.0)
  }

  var indicator: some View {
    WithViewStore(store, observe: \.norm) { norm in
      rotatedCircle
        .trim(from: config.indicatorStartAngle.normalized,
              to: config.normToTrim(norm.state))
        .stroke(config.theme.controlForegroundColor,
                style: StrokeStyle(lineWidth: config.indicatorStrokeWidth,
                                   lineCap: .round))
        .frame(width: config.controlDiameter, height: config.controlDiameter, alignment: .center)
    }
  }

  struct LabelsState: Equatable {
    var showingValue: Bool
    var formattedValue: String
    let id: AUParameterAddress

    init(state: KnobReducer.State) {
      self.showingValue = state.showingValue
      self.formattedValue = state.formattedValue
      self.id = state.parameter.address
    }
  }

  var labels: some View {
    WithViewStore(self.store, observe: LabelsState.init) { viewStore in
      ZStack {
        Text(config.title)
          .opacity(viewStore.showingValue ? 0.0 : 1.0)  // fade OUT when value changes
        Text(viewStore.formattedValue)
          .opacity(viewStore.showingValue ? 1.0 : 0.0)  // fade IN when value changes
      }
      .font(config.theme.font)
      .foregroundColor(config.theme.textColor)
      .animation(.linear, value: viewStore.showingValue)
      .onTapGesture(count: 1) {
        viewStore.send(.labelTapped, animation: .linear)
        scrollViewProxy?.scrollTo(viewStore.id)
      }
    }
  }

  // NOTE: coordinateSpace *must* be `.local` for the drag scaling calculations
  var dragGesture: DragGesture { DragGesture(minimumDistance: 0.0, coordinateSpace: .local) }

  var control: some View {
    WithViewStore(self.store, observe: \.showingValueEditor) { viewStore in
      VStack(spacing: 0.0) {
        Rectangle()
          .fill(.background)
          .frame(width: config.controlWidthIf(viewStore.state), height: config.controlDiameter)
          .overlay {
            track
            indicator
          }
          .gesture(dragGesture
            .onChanged { viewStore.send(.dragChanged(start: $0.startLocation, position: $0.location)) }
            .onEnded { viewStore.send(.dragEnded(start: $0.startLocation, position: $0.location)) }
          )
        labels
      }
      .opacity(viewStore.state ? 0.0 : 1.0)
      .scaleEffect(viewStore.state ? 0.0 : 1.0)
    }
  }

  var editor: some View {
    WithViewStore(self.store, observe: \.showingValueEditor) { viewStore in
      VStack(alignment: .center, spacing: 12) {
        editorField
        editorButtons
      }
      .padding()
      .background(.quaternary)
      .clipShape(RoundedRectangle(cornerRadius: 12))
      .opacity(viewStore.state ? 1.0 : 0.0)
      .scaleEffect(viewStore.state ? 1.0 : 0.0)
    }
  }

  struct EditorState: Equatable {
    var formattedValue: String

    init(state: KnobReducer.State) {
      self.formattedValue = state.formattedValue
    }
  }

  var editorField: some View {
    WithViewStore(self.store, observe: EditorState.init) { viewStore in
      HStack(spacing: 12) {
        Text(config.title)
        ZStack(alignment: .trailing) {
          textField
          Image(systemName: "xmark.circle.fill")
            .foregroundColor(.secondary)
            .onTapGesture(count: 1) { viewStore.send(.clearButtonTapped, animation: .linear) }
            .padding(.trailing, 4)
        }
      }
    }
  }

#if os(iOS)
  var textField: some View {
    WithViewStore(self.store, observe: EditorState.init) { viewStore in
      TextField("", text: viewStore.binding(get: \.formattedValue, send: { .textChanged($0) }))
        .keyboardType(.numbersAndPunctuation)
        .focused($focusedField, equals: .value)
        .submitLabel(.go)
        .onSubmit { viewStore.send(.acceptButtonTapped, animation: .linear) }
        .disableAutocorrection(true)
        .textFieldStyle(.roundedBorder)
    }
  }
#elseif os(macOS)
  var textField: some View {
    WithViewStore(self.store, observe: EditorState.init) { viewStore in
      TextField("", text: viewStore.binding(get: \.formattedValue, send: { .textChanged($0) }))
        .focused($focusedField, equals: .value)
        .onSubmit { viewStore.send(.acceptButtonTapped, animation: .linear) }
        .textFieldStyle(.roundedBorder)
    }
  }
#endif

  var editorButtons: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      HStack(spacing: 24) {
        Button(action: { viewStore.send(.acceptButtonTapped, animation: .linear) }) {
          Text("Accept")
        }
        .buttonStyle(.bordered)
        .foregroundColor(config.theme.textColor)

        Button(action: { viewStore.send(.cancelButtonTapped, animation: .linear) }) {
          Text("Cancel")
        }
        .buttonStyle(.borderless)
        .foregroundColor(config.theme.textColor)
      }
    }
  }
}

struct EnvelopeView: View {
  let title: String
  let theme = Theme()

  var body: some View {
    let label = Text(title)
      .foregroundStyle(theme.controlForegroundColor)
      .font(.title2.smallCaps())

    let delayParam = AUParameterTree.createParameter(withIdentifier: "DELAY", name: "Delay", address: 1, min: 0.0,
                                                     max: 100.0, unit: .generic, unitName: nil, flags: [],
                                                     valueStrings: nil, dependentParameters: nil)
    let delayConfig = KnobConfig(parameter: delayParam, theme: theme)
    let delayStore = Store(initialState: KnobReducer.State(parameter: delayParam, value: 0.0)) {
      KnobReducer(config: delayConfig)
    }

    let attackParam = AUParameterTree.createParameter(withIdentifier: "ATTACK", name: "Attack", address: 2, min: 0.0,
                                                      max: 100.0, unit: .generic, unitName: nil, flags: [],
                                                      valueStrings: nil, dependentParameters: nil)
    let attackConfig = KnobConfig(parameter: attackParam, theme: theme)
    let attackStore = Store(initialState: KnobReducer.State(parameter: attackParam, value: 0.0)) {
      KnobReducer(config: attackConfig)
    }

    let holdParam = AUParameterTree.createParameter(withIdentifier: "HOLD", name: "Hold", address: 3, min: 0.0,
                                                    max: 100.0, unit: .generic, unitName: nil, flags: [],
                                                    valueStrings: nil, dependentParameters: nil)
    let holdConfig = KnobConfig(parameter: holdParam, theme: theme)
    let holdStore = Store(initialState: KnobReducer.State(parameter: holdParam, value: 0.0)) {
      KnobReducer(config: holdConfig)
    }

    let decayParam = AUParameterTree.createParameter(withIdentifier: "DECAY", name: "Decay", address: 4, min: 0.0,
                                                     max: 100.0, unit: .generic, unitName: nil, flags: [],
                                                     valueStrings: nil, dependentParameters: nil)
    let decayConfig = KnobConfig(parameter: decayParam, theme: theme)
    let decayStore = Store(initialState: KnobReducer.State(parameter: decayParam, value: 0.0)) {
      KnobReducer(config: decayConfig)
    }

    let sustainParam = AUParameterTree.createParameter(withIdentifier: "SUSTAIN", name: "Sustain", address: 5, min: 0.0,
                                                       max: 100.0, unit: .generic, unitName: nil, flags: [],
                                                       valueStrings: nil, dependentParameters: nil)
    let sustainConfig = KnobConfig(parameter: sustainParam, theme: theme)
    let sustainStore = Store(initialState: KnobReducer.State(parameter: sustainParam, value: 0.0)) {
      KnobReducer(config: sustainConfig)
    }

    let releaseParam = AUParameterTree.createParameter(withIdentifier: "RELEASE", name: "Release", address: 6, min: 0.0,
                                                       max: 100.0, unit: .generic, unitName: nil, flags: [],
                                                       valueStrings: nil, dependentParameters: nil)
    let releaseConfig = KnobConfig(parameter: releaseParam, theme: theme)
    let releaseStore = Store(initialState: KnobReducer.State(parameter: releaseParam, value: 0.0)) {
      KnobReducer(config: releaseConfig)
    }

    ScrollViewReader { proxy in
      ScrollView(.horizontal) {
        GroupBox(label: label) {
          HStack(spacing: 12) {
            KnobView(store: delayStore, config: delayConfig, scrollViewProxy: proxy)
            KnobView(store: attackStore, config: attackConfig, scrollViewProxy: proxy)
            KnobView(store: holdStore, config: holdConfig, scrollViewProxy: proxy)
            KnobView(store: decayStore, config: decayConfig, scrollViewProxy: proxy)
            KnobView(store: sustainStore, config: sustainConfig, scrollViewProxy: proxy)
            KnobView(store: releaseStore, config: releaseConfig, scrollViewProxy: proxy)
          }
          .padding(.bottom)
        }
        .border(theme.controlBackgroundColor, width: 1)
      }
    }
  }
}

struct KnobViewPreview: PreviewProvider {
  static let param = AUParameterTree.createParameter(withIdentifier: "RELEASE", name: "Release", address: 1,
                                                     min: 0.0, max: 100.0, unit: .generic, unitName: nil,
                                                     valueStrings: nil, dependentParameters: nil)
  static let config = KnobConfig(parameter: param, logScale: false, theme: Theme())
  @State static var store = Store(initialState: KnobReducer.State(parameter: param, value: 0.0)) {
    KnobReducer(config: config)
  }

  static var previews: some View {
    KnobView(store: store, config: config, scrollViewProxy: nil)
  }
}

struct EnvelopeViewPreview: PreviewProvider {
  static var previews: some View {
    VStack {
      EnvelopeView(title: "Volume")
      EnvelopeView(title: "Modulation")
    }
  }
}
