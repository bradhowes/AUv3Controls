import Sharing
import SwiftUI

/**
 Modifier for TextField views that provides for value filtering. If a change to the TextField value fails to pass the filter,
 the old value is restored. Also picks a reasonable keyboard type to apply.
 */
public struct NumericValueEditing: ViewModifier {

  @Binding private var value: String
  private let valueEditorInfo: ValueEditorInfo
  private let keyboardType: UIKeyboardType

  init(value: Binding<String>, valueEditorInfo: ValueEditorInfo) {
    self._value = value
    self.valueEditorInfo = valueEditorInfo

    self.keyboardType = switch (valueEditorInfo.decimalAllowed, valueEditorInfo.signAllowed) {
    case (.none, .none): .numberPad
    case (.allowed, .none): .decimalPad
    default: .numbersAndPunctuation
    }
  }

  public func body(content: Content) -> some View {
    content
      .keyboardType(keyboardType)
//      .onReceive(NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification)) { obj in
//        print("notification")
//        if let textField = obj.object as? UITextField {
//          print("is textField")
//          textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument)
//        }
//      }
      .onChange(of: value) { oldValue, newValue in
        if !valueEditorInfo.isValid(newValue) {
          value = oldValue
        }
      }
  }
}

extension View {
  public func numericValueEditing(value: Binding<String>, valueEditorInfo: ValueEditorInfo) -> some View {
    modifier(NumericValueEditing(value: value, valueEditorInfo: valueEditorInfo))
  }
}
