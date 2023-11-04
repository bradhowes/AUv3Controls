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
      .trim(from: config.minimumAngle.degrees / 360.0,
            to: config.maximumAngle.degrees / 360.0)
      .stroke(config.theme.controlBackgroundColor,
              style: StrokeStyle(lineWidth: 2, lineCap: .round))
      .frame(width: config.controlRadius,
             height: config.controlRadius,
             alignment: .center)
      .padding(.horizontal, 4.0)
  }

  var indicator: some View {
    WithViewStore(store, observe: \.norm) { norm in
      rotatedCircle
        .trim(from: config.minimumAngle.degrees / 360.0,
              to: config.normToTrim(norm.state))
        .stroke(config.theme.controlForegroundColor,
                style: StrokeStyle(lineWidth: config.indicatorStrokeWidth,
                                   lineCap: .round))
        .frame(width: config.controlRadius, height: config.controlRadius, alignment: .center)
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
        viewStore.send(.labelTapped, animation: .smooth)
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
          .frame(width: config.controlWidthIf(viewStore.state), height: config.controlRadius)
          .overlay {
            track
            indicator
          }
          .gesture(dragGesture
            .onChanged { viewStore.send(.dragChanged($0)) }
            .onEnded { viewStore.send(.dragEnded($0)) }
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
      .clipShape(.rect(cornerRadius: 6))
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
          TextField("", text: viewStore.binding(get: \.formattedValue, send: { .textChanged($0) }))
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
    }
  }

  var editorButtons: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      HStack(spacing: 24) {
        Button(action: { viewStore.send(.acceptButtonPressed, animation: .smooth) }) {
          Text("Accept")
        }
        .buttonStyle(.bordered)
        .foregroundColor(config.theme.textColor)

        Button(action: { viewStore.send(.cancelButtonPressed, animation: .smooth) }) {
          Text("Cancel")
        }
        .buttonStyle(.borderless)
        .foregroundColor(config.theme.textColor)
      }
    }
  }
}

struct KnobViewPreview : PreviewProvider {
  static let config = KnobConfig(title: "Release", id: 1, minimumValue: 0.0, maximumValue: 100.0,
                                 logScale: false, theme: Theme())
  static let param = AUParameterTree.createParameter(withIdentifier: "RELEASE", name: "Release", address: 1,
                                                     min: 0.0, max: 100.0, unit: .generic, unitName: nil,
                                                     valueStrings: nil, dependentParameters: nil)
  @State static var store = Store(initialState: KnobReducer.State(parameter: param, value: 0.0)) {
    KnobReducer(config: config)
  }

  static var previews: some View {
    KnobView(store: store, config: config, scrollViewProxy: nil)
  }
}
