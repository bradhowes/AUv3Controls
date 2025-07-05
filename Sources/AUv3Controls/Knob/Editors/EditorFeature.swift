// Copyright © 2025 Brad Howes. All rights reserved.

import AVFoundation
import ComposableArchitecture
import SwiftUI

/**
 A value editor for a `KnobFeature` control. Provides a text field for editing the current value of the control, and
 two buttons, one to accept the changes, and another to cancel them.
 */
@Reducer
public struct EditorFeature {
  private let formatter: any KnobValueFormattingProvider

  public init(formatter: any KnobValueFormattingProvider) {
    self.formatter = formatter
  }

  @ObservableState
  public struct State: Equatable {
    let displayName: String
    var value: String
    var focus: Field?
    var hasFocus: Bool { focus != nil }

    public init(displayName: String, value: String = "") {
      self.displayName = displayName
      self.value = value
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
        state.value = formatter.forEditing(value)
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
  @Environment(\.auv3ControlsTheme) private var theme

  init(store: StoreOf<EditorFeature>) {
    self.store = store
  }

  var body: some View {
    VStack(spacing: 2) {
      Text(store.displayName)
        .font(theme.font)
        .foregroundStyle(theme.textColor)
      VStack(alignment: .center, spacing: 4) {
        valueEditor
          .padding(.init(top: 2, leading: 4, bottom: 0, trailing: 4))
        buttons
      }
      .padding(.init(top: 2, leading: 0, bottom: 4, trailing: 0))
      .background {
        RoundedRectangle(cornerRadius: 8)
          .fill(theme.editorBackgroundColor)
          .stroke(.gray, lineWidth: 1)
      }
      .bind($store.focus, to: $focus)
    }
  }

  private var valueEditor: some View {
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
        .onSubmit { store.send(.acceptButtonTapped, animation: .linear) }
        .textFieldStyle(.roundedBorder)
#endif
      Image(systemName: "xmark.circle.fill")
        .foregroundColor(.secondary)
        .onTapGesture(count: 1) { store.send(.clearButtonTapped, animation: .linear) }
        .padding(.trailing, 4)
    }
  }

  private var buttons: some View {
    HStack(spacing: 16) {
      Button {
        store.send(.acceptButtonTapped, animation: .linear)
      } label: {
        Text("OK", comment: "Name of button that accepts an edited value")
          .font(.callout)
          .bold()
      }
      .foregroundColor(theme.textColor)
      Button {
        store.send(.acceptButtonTapped, animation: .linear)
      } label: {
        Text("Cancel", comment: "Name of button that cancels editing")
          .font(.callout)
      }
      .buttonStyle(.borderless)
      .foregroundColor(theme.textColor)
    }
    .padding(.init(top: 2, leading: 0, bottom: 0, trailing: 0))
  }
}

struct EditorViewPreview: PreviewProvider {
  static let theme = Theme()
  static let param = AUParameterTree.createParameter(withIdentifier: "FEEDBACK", name: "Feedback", address: 1,
                                                     min: 0.0, max: 100.0, unit: .generic, unitName: nil,
                                                     valueStrings: nil, dependentParameters: nil)
  static let config = KnobConfig()
  @State static var store = Store(initialState: EditorFeature.State(
    displayName: "Release",
    value: "20000.12345"
  )) {
    EditorFeature(formatter: KnobValueFormatter.duration(1...2))
  }

  static var previews: some View {
    VStack {
      EditorView(store: store)
        .auv3ControlsTheme(theme)
    }
    .frame(width: theme.controlEditorWidth)
  }
}
