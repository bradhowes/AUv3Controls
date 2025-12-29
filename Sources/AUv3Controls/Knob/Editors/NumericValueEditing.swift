import Sharing
import SwiftUI

/**
 Modifier for TextField views that provides for value filtering. If a change to the TextField value fails to pass the filter,
 the old value is restored. Also picks a reasonable keyboard type to apply.
 */
public struct NumericValueEditing: ViewModifier {

  @Binding private var value: String
  private let valueEditorInfo: ValueEditorInfo
#if os(iOS)
  private let keyboardType: UIKeyboardType
#endif

  init(value: Binding<String>, valueEditorInfo: ValueEditorInfo) {
    self._value = value
    self.valueEditorInfo = valueEditorInfo

#if os(iOS)
    self.keyboardType = switch (valueEditorInfo.decimalAllowed, valueEditorInfo.signAllowed) {
    case (.none, .none): .numberPad
    case (.allowed, .none): .decimalPad
    default: .numbersAndPunctuation
    }
#endif
  }

  public func body(content: Content) -> some View {
    content
#if os(iOS)
      .keyboardType(keyboardType)
#endif
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
