import ComposableArchitecture
import CustomAlert
import SwiftUI


struct ValueEditorPrompt: ViewModifier {
  @Bindable private var store: StoreOf<KnobFeature>
  @Environment(\.auv3ControlsTheme) var theme

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
          .clearButton(text: $store.editorValue, offset: 0)
          .onSubmit {
            store.send(.editorAccepted(store.editorValue))
          }
          .lineLimit(1)
          .multilineTextAlignment(.leading)
          .font(.body)
          .padding(8)
          .background {
            RoundedRectangle(cornerRadius: 8)
              .fill(Color(uiColor: .systemBackground))
          }
          .padding(12)
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
  func valueEditorPrompt(store: StoreOf<KnobFeature>) -> some View {
    modifier(ValueEditorPrompt(store: store))
  }
}
