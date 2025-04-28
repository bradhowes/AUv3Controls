// Copyright © 2025 Brad Howes. All rights reserved.

import Foundation

#if compiler(<6.0) || !hasFeature(InferSendableFromCaptures)
#if hasFeature(RetroactiveAttribute)
extension KeyPath: @retroactive @unchecked Sendable {}
#else
extension KeyPath: @unchecked Sendable {}
#endif
#endif
