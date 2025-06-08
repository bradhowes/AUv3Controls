// Copyright © 2025 Brad Howes. All rights reserved.

import SwiftUI

/**
 Dim content of a view when not enabled.
 */
public struct DimmedAppearanceModifier: ViewModifier {
  let enabled: Bool
  @Environment(\.colorScheme) var colorScheme

  public func body(content: Content) -> some View {
    ZStack {
      content
        .disabled(!enabled)
      Rectangle()
        .fill(colorScheme == .dark ? .black : .white)
        .padding(.all, -2)
        .blendMode(colorScheme == .dark ? .multiply : .screen)
        .opacity(enabled ? 0.0 : 0.5)
        .animation(.smooth, value: enabled)
    }
  }
}

extension View {
  public func dimmedAppearanceModifier(enabled: Bool) -> some View {
    modifier(DimmedAppearanceModifier(enabled: enabled))
  }
}

#Preview {
  EnvelopeViewPreview.previews
}
