import AVFoundation
import ComposableArchitecture
import SwiftUI

@Reducer
public struct EditorFeature {
  let config: KnobConfig

  @ObservableState
  public struct State: Equatable {
    var value: String
    var focus: Field?
    var hasFocus: Bool { focus != nil }

    public init() {
      self.value = ""
      self.focus = nil
    }

    public enum Field: String, Hashable {
      case value
    }
  }

  public enum Action: BindableAction, Equatable {
    case acceptButtonTapped
    case binding(BindingAction<State>)
    case cancelButtonTapped
    case clearButtonTapped
    case start(Double)
    case valueChanged(String)
  }

  public var body: some Reducer<State, Action> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .acceptButtonTapped:
        state.focus = nil
        return .none

      case .binding:
        return .none

      case .cancelButtonTapped:
        state.focus = nil
        return .none

      case .clearButtonTapped:
        state.value = ""
        return .none

      case .start(let value):
        return start(state: &state, value: value)

      case let .valueChanged(newValue):
        state.value = newValue
        return .none
      }
    }
  }
}

extension EditorFeature {

  func start(state: inout State, value: Double) -> Effect<Action> {
    state.value = config.formattedValue(value)
    state.focus = .value
    return .none
  }
}

/**
 A pseudo-dialog box that hosts a TextField containing the current control's value for editing,
 and Accept and Cancel buttons to dismiss the dialog.
 */
public struct EditorView: View {
  @Bindable var store: StoreOf<EditorFeature>
  @FocusState var focus: EditorFeature.State.Field?
  let config: KnobConfig

  public init(store: StoreOf<EditorFeature>, config: KnobConfig) {
    self.store = store
    self.config = config
  }

  public var body: some View {
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
            .onSubmit { store.send(.acceptButtonTapped, animation: .linear) }
            .disableAutocorrection(true)
            .textFieldStyle(.roundedBorder)
#elseif os(macOS)
          TextField(store.value, text: $store.value)
            .focused(self.$focus, equals: .value)
            .onSubmit { store.send(.acceptButtonTapped, animation: .linear) }
            .textFieldStyle(.roundedBorder)
#endif
          Image(systemName: "xmark.circle.fill")
            .foregroundColor(.secondary)
            .onTapGesture(count: 1) { store.send(.clearButtonTapped, animation: .linear) }
            .padding(.trailing, 4)
        }
      }
      HStack(spacing: 24) {
        Button(action: { store.send(.acceptButtonTapped, animation: .linear) }) {
          Text("Accept")
        }
        .buttonStyle(.bordered)
        .foregroundColor(config.theme.textColor)
        Button(action: { store.send(.cancelButtonTapped, animation: .linear) }) {
          Text("Cancel")
        }
        .buttonStyle(.borderless)
        .foregroundColor(config.theme.textColor)
      }
    }
#if os(macOS)
    .frame(width: 200)
#endif
    .padding()
    .background(.quaternary)
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .bind($store.focus, to: $focus)
  }
}

struct EditorViewPreview: PreviewProvider {
  static let param = AUParameterTree.createParameter(withIdentifier: "RELEASE", name: "Release", address: 1,
                                                     min: 0.0, max: 100.0, unit: .generic, unitName: nil,
                                                     valueStrings: nil, dependentParameters: nil)
  static let config = KnobConfig(parameter: param, logScale: false, theme: Theme())
  @State static var store = Store(initialState: EditorFeature.State()) {
    EditorFeature(config: config)
  }

  static var previews: some View {
    EditorView(store: store, config: config)
  }
}
