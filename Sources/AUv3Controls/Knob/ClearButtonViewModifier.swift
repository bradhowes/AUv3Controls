// Copyright © 2025 Brad Howes. All rights reserved.

import SwiftUI

/**
 View modifier that adds a 'clear' button that removes all text from a text field and also gives it focus.
 */
struct ClearButtonViewModifier: ViewModifier {
  var text: Binding<String>
  var offset: CGFloat

  func body(content: Content) -> some View {
    ZStack(alignment: .trailing) {
      content
      Image(systemName: "multiply.circle.fill")
        .foregroundStyle(.gray)
        .onTapGesture { text.wrappedValue = "" }
        .opacity(text.wrappedValue.isEmpty ? 0 : 1)
        .disabled(text.wrappedValue.isEmpty)
        .padding(.trailing, offset)
    }
  }
}

extension TextField {
  func clearButton(text: Binding<String>, offset: CGFloat) -> some View {
    modifier(ClearButtonViewModifier(text: text, offset: offset))
  }
}

private struct Demo: View {
  @State var text: String
  @FocusState var displayNameFieldIsFocused: Bool

  init(text: String, displayNameFieldIsFocused: Bool) {
    self.text = text
    self.displayNameFieldIsFocused = displayNameFieldIsFocused
  }

  var body: some View {
    Section(header: Text("Name")) {
      TextField("Display Name", text: $text)
        .clearButton(text: $text, offset: 4)
#if os(iOS)
        .textInputAutocapitalization(.never)
#endif
        // .textFieldStyle(.roundedBorder)
        .focused($displayNameFieldIsFocused)
        .disableAutocorrection(true)
    }
  }
}

#if DEBUG

struct TextFieldClearButton_Previews: PreviewProvider {
  static var previews: some View {
    Form {
      Demo(text: "Testing", displayNameFieldIsFocused: true)
      Demo(text: "Another", displayNameFieldIsFocused: false)
    }
  }
}

#endif
