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
           case .presented = valueEditorInfo.action {
          value = valueEditorInfo.value
          isEditing = true
        } else {
          isEditing = false
        }
      }
#if os(iOS)
      .alert(valueEditorInfo?.displayName ?? "???", isPresented: $isEditing) {
        if let valueEditorInfo {
          TextField("New Value", text: $value)
            // .clearButton(text: $value, offset: 14)
            // .textFieldStyle(.roundedBorder)
            .keyboardType(.numbersAndPunctuation)
            .focused($focusState)
            .numericValueEditing(value: $value, valueEditorInfo: valueEditorInfo)
            .onSubmit { dismiss(accepted: true) }
//            .onAppear {
//              focusState = true
//            }
//            .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification)) { obj in
//              if let textField = obj.object as? UITextField {
//                textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument)
//              }
//            }
          Button {
            dismiss(accepted: true)
          } label: {
            Text("OK")
              .foregroundStyle(valueEditorInfo.theme.editorOKButtonColor)
          }
          Button(role: .cancel) {
            dismiss(accepted: false)
          } label: {
            Text("Cancel")
              .foregroundStyle(valueEditorInfo.theme.editorCancelButtonColor)
          }
        }
      }
#endif
#if os(macOS)
      .sheet(isPresented: $isEditing) {
        VStack(spacing: 16) {
          if let valueEditorInfo {
            Text(valueEditorInfo.displayName)
            TextField("", text: $value)
              .onSubmit { dismiss(accepted: true) }
            HStack(spacing: 32) {
              Button {
                dismiss(accepted: true)
              } label: {
                Text("OK")
                  .foregroundStyle(valueEditorInfo.theme.editorOKButtonColor)
              }
              Button(role: .cancel) {
                dismiss(accepted: false)
              } label: {
                Text("Cancel")
                  .foregroundStyle(valueEditorInfo.theme.editorCancelButtonColor)
              }
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
