import Combine
import ComposableArchitecture
import Sharing
import SwiftUI

/**
 Presents a native SwiftUI alert with a TextField to edit the value of a KnobFeature.
 */
struct NativeValueEditor: ViewModifier {
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
            .focused($focusState)
            .numericValueEditing(value: $value, valueEditorInfo: valueEditorInfo)
            .onSubmit { dismiss(accepted: true) }
            .onAppear {
              focusState = true
            }
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
              .foregroundStyle(valueEditorInfo.theme.textColor)
            TextField("New Value", text: $value)
              .focused($focusState)
              .numericValueEditing(value: $value, valueEditorInfo: valueEditorInfo)
              .font(.body)
              .onSubmit { dismiss(accepted: true) }
            HStack(spacing: 32) {
              Button {
                dismiss(accepted: true)
              } label: {
                Text("OK")
              }
              .themedButton(valueEditorInfo.theme, tag: .editorOKButtonColor)
              Button(role: .cancel) {
                dismiss(accepted: false)
              } label: {
                Text("Cancel")
              }
              .themedButton(valueEditorInfo.theme, tag: .editorCancelButtonColor)
            }
          }
        }
        .padding(16)
        .frame(maxWidth: 200)
        .onAppear {
          focusState = true
        }
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
  public func knobNativeValueEditor() -> some View {
    modifier(NativeValueEditor())
  }
}

// Derived from https://stackoverflow.com/a/58423631/629836

extension View {
  func themedButton(_ theme: Theme, tag: Theme.ColorTag) -> some View {
    self.buttonStyle(ThemedButtonStyle(theme: theme, tag: tag))
  }
}

struct ThemedButtonStyle: ButtonStyle {
  let theme: Theme
  let tag: Theme.ColorTag
  let backgroundColor: Color = .white.mix(with: .black, by: 0.7)
  let pressedColor: Color = .white.mix(with: .black, by: 0.5)

  func makeBody(configuration: Self.Configuration) -> some View {
    configuration.label
      .font(.headline)
      .padding(10)
      .foregroundColor(theme.textColor)
      .background(configuration.isPressed ? pressedColor : backgroundColor)
      .cornerRadius(5)
  }
}
