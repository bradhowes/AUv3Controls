extension FloatingPoint {

  /**
   Obtain a value that is always within the a given closed range

   - parameter value: the value to work with
   - parameter range: the closed range to use
   - returns: the clamped value
   */
  static func clamp(_ value: Self, to range: ClosedRange<Self>) -> Self { range.clamp(value) }

  /**
   Convert a value into one that is clamped to a given closed range

   - parameter range: the closed range to use
   - returns: the clamped value
   */
  func clamped(to range: ClosedRange<Self>) -> Self { range.clamp(self) }
}
