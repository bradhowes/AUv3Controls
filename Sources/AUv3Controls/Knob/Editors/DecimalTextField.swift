import Sharing
import SwiftUI

/// Custom TextField that only accepts decimal values.
struct DecimalTextField: View {
  @Shared(.valueEditorInfo) var valueEditorInfo

  @Binding private var value: String

  private var focusState: FocusState<Bool>.Binding
  private let decimalSeparator: String
  private let validCharacters: String

  init(value: Binding<String>, focusState: FocusState<Bool>.Binding) {
    self._value = value
    self.focusState = focusState
    self.decimalSeparator = Locale.current.decimalSeparator ?? "."
    self.validCharacters = "0123456789" + self.decimalSeparator
  }

  var body: some View {
    TextField("New Value", text: $value)
      .clearButton(text: $value, offset: 4)
      .textFieldStyle(.roundedBorder)
#if os(iOS)
      .keyboardType(.decimalPad)
#endif
      .focused(focusState.projectedValue)
      .onChange(of: value) { oldValue, newValue in
        // One decimalSeparator will lead to two components, more than one will lead to more than 2.
        if newValue.components(separatedBy: decimalSeparator).count > 2 || !newValue.allSatisfy({ validCharacters.contains($0) }) {
          value = oldValue
        }
      }
  }
}
