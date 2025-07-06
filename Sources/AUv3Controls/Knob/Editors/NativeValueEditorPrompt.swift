import ComposableArchitecture
import SwiftUI


struct NativeValueEditorPrompt: ViewModifier {
  @Bindable private var store: StoreOf<KnobFeature>
  @Environment(\.auv3ControlsTheme) var theme

  init(store: StoreOf<KnobFeature>) {
    self.store = store
  }

  func body(content: Content) -> some View {
    content
      .alert(store.displayName, isPresented: $store.showingEditor) {
        TextField("New Value", text: $store.editorValue)
#if os(iOS)
          .keyboardType(.decimalPad)
#endif
          .onSubmit {
            store.send(.editorAccepted(store.editorValue))
          }
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

extension View {
  func nativeValueEditorPrompt(store: StoreOf<KnobFeature>, focused: FocusState<String?>.Binding? = nil) -> some View {
    modifier(NativeValueEditorPrompt(store: store))
  }
}
