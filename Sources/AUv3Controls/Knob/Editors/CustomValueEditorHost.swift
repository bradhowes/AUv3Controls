#if useCustomAlert

import ComposableArchitecture
import CustomAlert
import SwiftUI

/**
 A custom SwiftUI alert-like modal view with a TextField to edit the value of a KnobFeature.
 */
struct CustomValueEditorView: View {
  @Shared(.valueEditorInfo) var valueEditorInfo
  @State private var displayName: String = ""
  private var value: Binding<String>
  @FocusState private var isFocused
  private let dismiss: (Bool) -> Void

  init(value: Binding<String>, dismiss: @escaping (Bool) -> Void) {
    self.value = value
    self.dismiss = dismiss
  }

  var body: some View {
    Text(displayName)
      .font(.system(size: 18))
      .foregroundStyle(theme.textColor)
    TextField("New Value", text: value)
      .clearButton(text: value, offset: 8)
      .textFieldStyle(.roundedBorder)
#if os(iOS)
      .keyboardType(.decimalPad)
      .onSubmit { dismiss(true) }
#endif
      .focused($isFocused)
      .lineLimit(1)
      .multilineTextAlignment(.leading)
      .font(.body)
      .padding(8)
      .onAppear {
        isFocused = true
        displayName = valueEditorInfo?.displayName ?? "???"
      }
  }
}

/**
 Presents a custom SwiftUI alert-like modal view with a TextField to edit the value of a KnobFeature.
 */
struct CustomValueEditorHost: ViewModifier {
  @Shared(.valueEditorInfo) var valueEditorInfo
  @State private var value: String = ""
  @State private var isEditing: Bool = false

  func body(content: Content) -> some View {
    content
      .onChange(of: valueEditorInfo) {
        if let valueEditorInfo {
          isEditing = true
          value = valueEditorInfo.value
        } else {
          isEditing = false
        }
      }
      .customAlert(isPresented: $isEditing) {
        CustomValueEditorView(value: $value, dismiss: dismiss)
      } actions: {
        MultiButton {
          Button {
            dismiss(accepted: true)
          } label: {
            Text("OK")
              .foregroundStyle(valueEditorInfo!.theme.editorOKButtonColor)
          }
          Button(role: .cancel) {
            dismiss(accepted: false)
          } label: {
            Text("Cancel")
              .foregroundStyle(valueEditorInfo!.theme.editorCancelButtonColor)
          }
        }
      }
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
  public func knobCustomValueEditorHost() -> some View {
    modifier(CustomValueEditorHost())
  }
}

#endif
