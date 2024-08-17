import Foundation

#if compiler(<6.0) || !hasFeature(InferSendableFromCaptures)
extension KeyPath: @unchecked @retroactive Sendable {}
#endif
