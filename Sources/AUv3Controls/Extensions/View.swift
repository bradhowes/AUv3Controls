// Copyright © 2025 Brad Howes. All rights reserved.

import SwiftUI

extension View {

  @ViewBuilder
  public func knobValueEditor() -> some View {
#if os(macOS)
    modifier(NativeValueEditor())
#endif
#if os(iOS)
    modifier(CustomValueEditor())
#endif
  }
}
