#if os(iOS)

import ComposableArchitecture
import CustomAlert
import SwiftUI

/**
 Presents a custom SwiftUI alert-like modal view with a TextField to edit the value of a KnobFeature.
 */
struct CustomValueEditor: ViewModifier {
  @Shared(.valueEditorInfo) var valueEditorInfo
  @State private var value: String = ""
  @State private var isEditing: Bool = false
  @State private var dismissAction: ((Bool) -> Void)? = nil

  private var alertConfig: CustomAlertConfiguration {
    var config: CustomAlertConfiguration
    if #available(iOS 26, *) {
      config = .liquidGlass
    } else {
      config = .classic
    }
    config = config.alert { $0.titleColor(.gray) }
    return config.button { $0.tintColor(valueEditorInfo?.theme.textColor ?? .blue) }
  }

  func body(content: Content) -> some View {
    content
      .onChange(of: valueEditorInfo) {
        if let valueEditorInfo {
          isEditing = valueEditorInfo.action == .presented
          value = valueEditorInfo.value
          dismissAction = { accepted in self.dismiss(accepted: accepted) }
        } else {
          isEditing = false
          dismissAction = nil
        }
      }
      .customAlert(valueEditorInfo?.displayName ?? "", isPresented: $isEditing) {
        if let valueEditorInfo {
          AlertContent(value: $value, valueEditorInfo: valueEditorInfo, dismissAction: dismissAction)
        }
      } actions: {
        MultiButton {
          Button {
            dismissAction?(true)
          } label: {
            Text("OK")
          }
          Button(role: .cancel) {
            dismissAction?(false)
          } label: {
            Text("Cancel")
          }
        }
      }
      .configureCustomAlert(alertConfig)
  }

  private func dismiss(accepted: Bool) {
    // Communicate the change to the knob -- the knob is responsible for setting the shared value to nil.
    $valueEditorInfo.withLock { $0?.action = .dismissed(accepted ? value : nil) }
  }
}

/**
 Custom view that contains the TextField -- necessary to get field focusing to work properly.
 */
private struct AlertContent: View {
  @Binding private var value: String
  private let valueEditorInfo: ValueEditorInfo
  private let dismissAction: ((Bool) -> Void)?
  @FocusState private var isFocused

  init(value: Binding<String>, valueEditorInfo: ValueEditorInfo, dismissAction: ((Bool) -> Void)?) {
    self._value = value
    self.valueEditorInfo = valueEditorInfo
    self.dismissAction = dismissAction
    self.isFocused = isFocused
  }

  var body: some View {
    TextField("New Value", text: $value)
      .clearButton(text: $value, offset: 8)
      .focused($isFocused)
      .numericValueEditing(value: $value, valueEditorInfo: valueEditorInfo)
      .font(.body)
      .foregroundColor(valueEditorInfo.theme.textColor)
      .padding(4)
      .background {
        RoundedRectangle(cornerRadius: 8)
          .fill(Color(uiColor: .systemBackground))
      }
      .onSubmit { dismissAction?(true) }
      .onAppear {
        isFocused = true
      }
  }
}

extension View {
  public func knobCustomValueEditor() -> some View {
    modifier(CustomValueEditor())
  }
}

#endif

