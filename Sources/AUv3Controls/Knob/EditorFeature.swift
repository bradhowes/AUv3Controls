import AVFoundation
import ComposableArchitecture
import SwiftUI

/***
 A value editor for a `KnobFeature` control. Provides a text field for editing the current value of the control, and
 two buttons, one to accept the changes, and another to cancel them.
 */
@Reducer
public struct EditorFeature {

  @ObservableState
  public struct State: Equatable {
    let config: KnobConfig
    var value: String
    var focus: Field?
    var hasFocus: Bool { focus != nil }

    public init(config: KnobConfig) {
      self.config = config
      self.value = ""
      self.focus = nil
    }

    enum Field: String, Hashable {
      case value
    }
  }

  public enum Action: BindableAction, Equatable, Sendable {
    case acceptButtonTapped
    case beginEditing(Double)
    case binding(BindingAction<State>)
    case cancelButtonTapped
    case clearButtonTapped
    case valueChanged(String)
  }

  public var body: some Reducer<State, Action> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .acceptButtonTapped: state.focus = nil
      case .beginEditing(let value):
        state.value = state.config.formattedValue(value)
        state.focus = .value
      case .binding: break
      case .cancelButtonTapped: state.focus = nil
      case .clearButtonTapped: state.value = ""
      case let .valueChanged(newValue): state.value = newValue
      }
      return .none
    }
  }
}

struct EditorView: View {
  @Bindable private var store: StoreOf<EditorFeature>
  @FocusState private var focus: EditorFeature.State.Field?
  private let config: KnobConfig

  init(store: StoreOf<EditorFeature>, config: KnobConfig) {
    self.store = store
    self.config = config
  }

  var body: some View {
    VStack(alignment: .center, spacing: 12) {
      HStack(spacing: 12) {
        Text(config.title)
          .lineLimit(1, reservesSpace: false)
        ZStack(alignment: .trailing) {
#if os(iOS)
          TextField(store.value, text: $store.value)
            .keyboardType(.numbersAndPunctuation)
            .focused($focus, equals: .value)
            .submitLabel(.go)
            .onSubmit { sendAcceptButtonTapped() }
            .disableAutocorrection(true)
            .textFieldStyle(.roundedBorder)
#elseif os(macOS)
          TextField(store.value, text: $store.value)
            .onSubmit { sendAcceptButtonTapped() }
            .textFieldStyle(.roundedBorder)
#endif
          Image(systemName: "xmark.circle.fill")
            .foregroundColor(.secondary)
            .onTapGesture(count: 1) { store.send(.clearButtonTapped, animation: .linear) }
            .padding(.trailing, 4)
        }
      }
      HStack(spacing: 24) {
        Button {
          sendAcceptButtonTapped()
        } label: {
          Text("Accept", comment: "Name of button that accepts an edited value")
        }
        .buttonStyle(.bordered)
        .foregroundColor(config.theme.textColor)
        Button {
          sendCancelButtonTapped()
        } label: {
          Text("Cancel", comment: "Name of button that cancels editing")
        }
        .buttonStyle(.borderless)
        .foregroundColor(config.theme.textColor)
      }
    }
    .padding()
    .background(.quaternary)
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .bind($store.focus, to: $focus)
  }

  func sendAcceptButtonTapped() {
    store.send(.acceptButtonTapped, animation: .linear)
  }

  func sendCancelButtonTapped() {
    store.send(.acceptButtonTapped, animation: .linear)
  }
}

struct EditorViewPreview: PreviewProvider {
  static let param = AUParameterTree.createParameter(withIdentifier: "RELEASE", name: "Release", address: 1,
                                                     min: 0.0, max: 100.0, unit: .generic, unitName: nil,
                                                     valueStrings: nil, dependentParameters: nil)
  static let config = KnobConfig(parameter: param, theme: Theme())
  @State static var store = Store(initialState: EditorFeature.State(config: config)) {
    EditorFeature()
  }

  static var previews: some View {
    EditorView(store: store, config: config)
  }
}
