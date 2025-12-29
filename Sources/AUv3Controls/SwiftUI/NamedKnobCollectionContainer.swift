// Copyright © 2025 Brad Howes. All rights reserved.

import SwiftUI

public struct NamedKnobCollectionContainer<T1: View, T2: View, C: View>: View {
  let enabled: Bool
  let titleStack: NamedKnobCollectionTitleOnOff<T1, T2>
  let contentStack: C

  public init(
    enabled: Bool,
    title: String,
    onOff: T1,
    globalLock: T2,
    @ViewBuilder content: () -> C
  ) {
    self.enabled = enabled
    self.titleStack = .init(title: title, onOffToggleView: onOff, globalLockToggleView: globalLock)
    self.contentStack = content()
  }

  public var body: some View {
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

@available(*, deprecated, renamed: "NamedKnobCollectionContainer")
public typealias EffectsContainer = NamedKnobCollectionContainer
