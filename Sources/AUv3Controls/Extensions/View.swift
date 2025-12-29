// Copyright © 2025 Brad Howes. All rights reserved.

import SwiftUI

extension View {

  @ViewBuilder
  public func knobValueEditor(_ kind: ValueEditorKind = .defaultValue) -> some View {
    switch kind {
    case .nativePrompt: modifier(NativeValueEditor())
#if os(iOS)
    case .customPrompt: modifier(CustomValueEditor())
#endif
    }
  }
}
