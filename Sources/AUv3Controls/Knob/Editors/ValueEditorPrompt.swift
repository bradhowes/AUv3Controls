#if false

import ComposableArchitecture
import CustomAlert
import SwiftUI
import SwiftUIIntrospect


struct ValueEditorPrompt: ViewModifier {
  @Bindable private var store: StoreOf<KnobFeature>
  @Environment(\.auv3ControlsTheme) var theme
  @FocusState var focused: String?

  init(store: StoreOf<KnobFeature>) {
    self.store = store
  }

  func body(content: Content) -> some View {
    content
      .customAlert(isPresented: $store.showingEditor) {
        Text(store.displayName)
          .font(.system(size: 24))
          .foregroundStyle(theme.textColor)
        TextField("New Value", text: $store.editorValue)
          .clearButton(text: $store.editorValue, offset: 8)
          .textFieldStyle(.roundedBorder)
          .keyboardType(.decimalPad)
          .onSubmit {
            store.send(.editorAccepted(store.editorValue))
          }
#if os(iOS)
          .introspect(.textField, on: .iOS(.v17, .v18)) {
            if store.showingEditor {
              $0.becomeFirstResponder()
            }
          }
#endif
          .lineLimit(1)
          .multilineTextAlignment(.leading)
          .focused($focused, equals: store.displayName)
          .font(.body)
          .padding(8)
          .onChange(of: store.showingEditor) {
            if store.showingEditor {
              focused = store.displayName
            }
          }
      } actions: {
        MultiButton {
          Button {
            store.send(.editorAccepted(store.editorValue))
          } label: {
            Text("OK")
          }
          Button(role: .cancel) {
            store.send(.editorCancelled)
          } label: {
            Text("Cancel")
          }
        }
      }
  }
}

extension View {
  func valueEditorPrompt(store: StoreOf<KnobFeature>, focused: FocusState<String?>.Binding? = nil) -> some View {
    modifier(ValueEditorPrompt(store: store))
  }
}

#endif

