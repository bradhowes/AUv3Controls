import SwiftUI

public struct ValueEditor: View {
  public var name: String

  public var acceptButtonAction: () -> Void
  public var cancelButtonAction: () -> Void

  public var isShowing: Binding<Bool>
  public var value: Binding<String>

  @Environment(\.colorScheme) private var colorScheme: ColorScheme
  @FocusState private var isFocused: Bool

  public init(
    isShowing: Binding<Bool>,
    name: String,
    value: Binding<String>,
    acceptButtonAction: @escaping () -> Void,
    cancelButtonAction: @escaping () -> Void
  ) {
    self.isShowing = isShowing
    self.name = name
    self.value = value
    self.acceptButtonAction = acceptButtonAction
    self.cancelButtonAction = cancelButtonAction
    self.isFocused = true
  }

  public var body: some View {
    VStack (spacing: 20){
      Text(name)
        .font(Font.headline)
        .bold()

      TextField(value.wrappedValue, text: value)
        .textFieldStyle(.roundedBorder)
        .focused($isFocused)

      HStack {
        Button {
          cancelButtonAction()
        } label: {
          Text("Cancel")
            .fontWeight(.medium)
            .frame(minWidth: 60)
        }
        .buttonStyle(.bordered)
        .tint(colorScheme == ColorScheme.light ? .black : .white)
        Button(action: {
          acceptButtonAction()
        }) {
          Text("OK")
            .fontWeight(.medium)
            .frame(minWidth: 60)
        }
        .buttonStyle(.borderedProminent)
        .tint(.black)
      }
    }
    .padding(24)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(colorScheme == ColorScheme.light ? Color(.white) : Color(.darkGray))
        .shadow(radius: 8)
    )
    .padding(30)
    .frame(maxWidth: 375, maxHeight: 300)
  }
}
