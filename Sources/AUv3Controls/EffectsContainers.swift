import SwiftUI

struct TitleOnOff<T1: View, T2: View>: View {
  @Environment(\.auv3ControlsTheme) var theme

  let title: String
  let onOffToggleView: T1
  let globalLockToggleView: T2

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text(title)
        .foregroundStyle(theme.controlForegroundColor)
      onOffToggleView
      globalLockToggleView
    }
  }
}

struct EffectsContainer<T1: View, T2: View, C: View>: View {
  let enabled: Bool
  let titleStack: TitleOnOff<T1, T2>
  let contentStack: C

  init(
    enabled: Bool,
    title: String,
    onOff: T1,
    globalLock: T2,
    @ViewBuilder content: () -> C
  ) {
    self.enabled = enabled
    self.titleStack = TitleOnOff(title: title, onOffToggleView: onOff, globalLockToggleView: globalLock)
    self.contentStack = content()
  }

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      titleStack
      contentStack
        .padding(.init(top: 4, leading: 0, bottom: 4, trailing: 0))
        .dimmedAppearanceModifier(enabled: enabled)
    }
    .frame(maxHeight: 102)
    .frame(height: 102)
    .padding(.init(top: 8, leading: 8, bottom: 8, trailing: 8))
  }
}
