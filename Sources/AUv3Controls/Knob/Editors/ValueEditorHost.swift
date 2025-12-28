import ComposableArchitecture
import Sharing
import SwiftUI

/**
 Presents a custom SwiftUI alert-like modal view with a TextField to edit the value of a KnobFeature.
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
          Color.black.opacity(0.15)
            .cornerRadius(10)
        }
      }
      .clipped()
      .overlay(isEditing ? valueEditor(valueEditorInfo!) : nil)
      .animation(.default, value: isEditing)
      .onChange(of: isEditing) {
        focusState = isEditing
        if let valueEditorInfo {
          value = valueEditorInfo.value
        }
      }
  }

  @ViewBuilder
  private func valueEditor(_ info: ValueEditorInfo) -> some View {
    VStack(spacing: 24) {
      Text(info.displayName)
        .font(.headline)
        .foregroundStyle(info.theme.textColor)
      DecimalTextField(value: $value, focusState: $focusState)
        .onSubmit { dismiss(accepted: true) }
      HStack(spacing: 24) {
        Button {
          dismiss(accepted: false)
        } label: {
          Text("Cancel")
            .foregroundStyle(info.theme.editorCancelButtonColor)
        }
        Button {
          dismiss(accepted: true)
        } label: {
          Text("OK")
            .foregroundStyle(info.theme.editorOKButtonColor)
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

extension View {
  public func knobValueEditorHost() -> some View {
    modifier(ValueEditorHost())
  }
}
