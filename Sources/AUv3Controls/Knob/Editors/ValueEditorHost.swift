import ComposableArchitecture
import Sharing
import SwiftUI

/**
 Presents a custom SwiftUI alert-like modal view with a TextField to edit the value of a KnobFeature. Used for experimentation.
 It lacks some functionality that is provided by CustomAlert package.
 */
struct ValueEditorHost: ViewModifier {
  @Shared(.valueEditorInfo) var valueEditorInfo
  @FocusState private var focusState: Bool
  @State private var value: String = ""

  private var isEditing: Bool { valueEditorInfo?.action == .presented }

  func body(content: Content) -> some View {
    content
      .disabled(isEditing)
      .overlay {
        if isEditing {
          Color.black.opacity(0.1)
            .ignoresSafeArea()
        }
      }
      .overlay(isEditing ? valueEditor(valueEditorInfo!) : nil)
      .animation(.default, value: isEditing)
      .onChange(of: isEditing) {
        focusState = isEditing
        if let valueEditorInfo {
          value = valueEditorInfo.value
        }
      }
  }

  private func valueEditor(_ info: ValueEditorInfo) -> some View {
    VStack(spacing: 20) {
      Text(info.displayName)
        .font(.headline)
        .foregroundStyle(info.theme.textColor)
      TextField("New Value", text: $value)
        .clearButton(text: $value, offset: 4)
        .textFieldStyle(.roundedBorder)
        .focused($focusState)
        .numericValueEditing(value: $value, valueEditorInfo: info)
        .onSubmit { dismiss(accepted: true) }
      HStack(spacing: 32) {
        Button {
          dismiss(accepted: true)
        } label: {
          Text("OK")
            .foregroundStyle(info.theme.editorOKButtonColor)
            .bold()
        }
        Button {
          dismiss(accepted: false)
        } label: {
          Text("Cancel")
            .foregroundStyle(info.theme.editorCancelButtonColor)
        }
      }
    }
    .padding(16)
    .frame(width: 240)
    .background(info.theme.editorBackgroundColor)
    .cornerRadius(20)
    .overlay(
      RoundedRectangle(cornerRadius: 20)
        .stroke(.black, lineWidth: 0.5)
    )
    .transition(AnyTransition.opacity.combined(with: .scale(scale: 1.1)))
  }

  private func dismiss(accepted: Bool) {
    if var valueEditorInfo {
      // Communicate the change to the knob -- the knob is responsible for setting the shared value to nil.
      valueEditorInfo.action = .dismissed(accepted ? value : nil)
      $valueEditorInfo.withLock { $0 = valueEditorInfo }
    }
  }
}
