import Combine
import ComposableArchitecture
import Sharing
import SwiftUI

/**
 Presents a native SwiftUI alert with a TextField to edit the value of a KnobFeature.
 */
struct NativeValueEditorHost: ViewModifier {
  @Shared(.valueEditorInfo) var valueEditorInfo
  @State private var value: String = ""
  @State private var isEditing: Bool = false
  @FocusState private var focusState: Bool

  func body(content: Content) -> some View {
    content
      .onChange(of: valueEditorInfo) {
        if let valueEditorInfo,
           case let .presented = valueEditorInfo.action {
          value = valueEditorInfo.value
          isEditing = true
        } else {
          isEditing = false
        }
      }
#if os(iOS)
      .alert(valueEditorInfo?.displayName ?? "???", isPresented: $isEditing) {
        TextField("New Value", text: $value)
          .keyboardType(.decimalPad)
          .focused($focusState)
          .onSubmit { dismiss(accepted: true) }
          .onAppear {
            focusState = true
          }
          .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification)) { obj in
            if let textField = obj.object as? UITextField {
              textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument)
            }
          }
        Button {
          dismiss(accepted: true)
        } label: {
          Text("OK")
        }
        Button(role: .cancel) {
          dismiss(accepted: false)
        } label: {
          Text("Cancel")
        }
      }
#endif
#if os(macOS)
      .sheet(isPresented: $isEditing) {
        VStack(spacing: 16) {
          Text(valueEditorInfo?.displayName ?? "???")
          TextField("", text: $value)
            .onSubmit { dismiss(accepted: true) }
          HStack(spacing: 24) {
            Button(role: .cancel) {
              dismiss(accepted: false)
            } label: {
              Text("Cancel")
            }
            Button {
              dismiss(accepted: true)
            } label: {
              Text("OK")
            }
          }
        }
        .padding(16)
        .frame(maxWidth: 200)
      }
#endif
  }

  private func dismiss(accepted: Bool) {
    if var valueEditorInfo {
      // Communicate the change to the knob -- the knob is responsible for setting the shared value to nil.
      valueEditorInfo.action = .dismissed(accepted ? value : nil)
      $valueEditorInfo.withLock { $0 = valueEditorInfo }
    }
  }
}

extension View {
  public func knobNativeValueEditorHost() -> some View {
    modifier(NativeValueEditorHost())
  }
}
