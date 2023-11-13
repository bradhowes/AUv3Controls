import AVFoundation
import ComposableArchitecture
import SwiftUI

public struct EditorFeature: Reducer {
  let config: KnobConfig

  public struct State: Equatable {
    var value: String
    @BindingState var focus: Field?

    public init() {
      self.value = ""
      self.focus = nil
    }

    enum Field: Hashable {
      case value
    }
  }

  public enum Action: BindableAction, Equatable, Sendable {
    case acceptButtonTapped
    case binding(BindingAction<State>)
    case cancelButtonTapped
    case clearButtonTapped
    case start(Double)
    case valueChanged(String)
  }

  public func reduce(into state: inout State, action: Action) -> Effect<Action> {
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

extension EditorFeature {

  func start(state: inout State, value: Double) -> Effect<Action> {
    state.value = config.formattedValue(value)
    state.focus = .value
    return .none
  }
}

struct EditorView: View {
  let store: StoreOf<EditorFeature>
  let config: KnobConfig
  @FocusState var focus: EditorFeature.State.Field?

  var body: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      VStack(alignment: .center, spacing: 12) {
        HStack(spacing: 12) {
          Text(config.title)
            .lineLimit(1, reservesSpace: false)
          ZStack(alignment: .trailing) {
#if os(iOS)
            TextField(viewStore.value, text: viewStore.binding(get: \.value, send: { .valueChanged($0) }))
              .keyboardType(.numbersAndPunctuation)
              .focused(self.$focus, equals: .value)
              .submitLabel(.go)
              .onSubmit { viewStore.send(.acceptButtonTapped, animation: .linear) }
              .disableAutocorrection(true)
              .textFieldStyle(.roundedBorder)
#elseif os(macOS)
            TextField(viewStore.value, text: viewStore.binding(get: \.value, send: { .valueChanged($0) }))
              .focused(self.$focus, equals: .value)
              .onSubmit { viewStore.send(.acceptButtonTapped, animation: .linear) }
              .textFieldStyle(.roundedBorder)
#endif
            Image(systemName: "xmark.circle.fill")
              .foregroundColor(.secondary)
              .onTapGesture(count: 1) { viewStore.send(.clearButtonTapped, animation: .linear) }
              .padding(.trailing, 4)
          }
        }
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
      .padding()
      .background(.quaternary)
      .clipShape(RoundedRectangle(cornerRadius: 12))
      .bind(viewStore.$focus, to: self.$focus)
    }
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
