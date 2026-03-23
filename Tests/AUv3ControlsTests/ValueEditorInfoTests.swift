// Copyright © 2025 Brad Howes. All rights reserved.

import Sharing
import Testing
@testable import AUv3Controls

@Suite
struct ValueEditorInfoTests {

  @Test
  func isValidDecimalSign() {
    let vei = ValueEditorInfo(id: 1, displayName: "Foo", value: "0.0", theme: .init(), decimalAllowed: .allowed, signAllowed: .allowed)
    #expect(vei.isValid(""))
    #expect(vei.isValid("+"))
    #expect(vei.isValid("+1"))
    #expect(vei.isValid("+10.0"))

    #expect(!vei.isValid("a"))
    #expect(!vei.isValid("+a"))
    #expect(!vei.isValid("+1a"))
    #expect(!vei.isValid("+10-"))
    #expect(!vei.isValid("+10.0."))
    #expect(!vei.isValid("+10.0.0"))
  }

  @Test
  func isValidNoDecimalSign() {
    let vei = ValueEditorInfo(id: 1, displayName: "Foo", value: "0.0", theme: .init(), decimalAllowed: .none, signAllowed: .allowed)
    #expect(vei.isValid(""))
    #expect(vei.isValid("+"))
    #expect(vei.isValid("+1"))
    #expect(vei.isValid("+100"))

    #expect(!vei.isValid("a"))
    #expect(!vei.isValid("+a"))
    #expect(!vei.isValid("+1a"))
    #expect(!vei.isValid("+10."))
  }

  @Test
  func isValidNoDecimalNoSign() {
    let vei = ValueEditorInfo(id: 1, displayName: "Foo", value: "0.0", theme: .init(), decimalAllowed: .none, signAllowed: .none)
    #expect(vei.isValid(""))
    #expect(vei.isValid("1"))
    #expect(vei.isValid("12"))

    #expect(!vei.isValid("+"))
    #expect(!vei.isValid("+1"))
    #expect(!vei.isValid("+100"))
    #expect(!vei.isValid("-100"))

    #expect(!vei.isValid("a"))
    #expect(!vei.isValid("+a"))
    #expect(!vei.isValid("+1a"))
    #expect(!vei.isValid("10."))
  }

  @Test
  func nilSharedKey() {
    @Shared(.valueEditorInfo) var vei
    #expect(vei == nil)
  }

  @Test
  func sharedKey() {
    @Shared(.valueEditorInfo) var vei = .init(id: 1, displayName: "Foo", value: "0.0", theme: .init(), decimalAllowed: .allowed, signAllowed: .allowed)
    #expect(vei?.isValid("-1.23") == true)
  }
}
