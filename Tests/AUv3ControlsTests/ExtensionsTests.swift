import AudioToolbox
import SwiftUI
import Testing
import AUv3Controls

@Test func normalizedAngle() {
  #expect(Angle(degrees: 0).normalized == 0)
  #expect(Angle(degrees: 360).normalized == 0)
  #expect(Angle(degrees: 365).normalized == 5.0 / 360.0)
  #expect(Angle(degrees: -355).normalized == 5.0 / 360.0)
  #expect(Angle(degrees: -360).normalized == 0.0 / 360.0)
  #expect(Angle(degrees: -365).normalized == 355.0 / 360.0)
  #expect(Angle(degrees: -5).normalized == 355.0 / 360.0)
}

@Test func parameterRange() {
  let p1 = AUParameterTree.createBoolean(withIdentifier: "foo", name: "foo", address: 1)
  #expect(p1.range == 0...1)
  #expect(!p1.value.asBool)
  p1.setValue(1.0, originator: nil)
  #expect(p1.value.asBool)
  p1.setValue(false.asValue, originator: nil)
  #expect(!p1.value.asBool)
  p1.setValue(true.asValue, originator: nil)
  #expect(p1.value.asBool)

  let p2 = AUParameterTree.createFloat(withIdentifier: "a", name: "a", address: 2, range: -20...34, unit: .cents)
  #expect(p2.range == -20...34)
  #expect(p2.minValue == -20)
  #expect(p2.maxValue == 34)
}

@Test func clamp() {
  let p2 = AUParameterTree.createFloat(withIdentifier: "a", name: "a", address: 2, range: -20...34, unit: .cents)
  #expect(p2.range.clamp(-99.0) == -20)
  #expect(p2.range.clamp(0.0) == 0.0)
  #expect(p2.range.clamp(35) == 34)

  #expect(31.54.clamped(to: -20...34) == 31.54)
}

@Test func hexColor() {
  #expect(Color(hex: "FF0000")?.resolve(in: .init()).red == 1.0)
  #expect(Color(hex: "  0xFF807F")?.resolve(in: .init()).red == 1.0)
  #expect(Color(hex: "#FF807F")?.resolve(in: .init()).green == 0.5019608)
  #expect(Color(hex: "0xFF807F")?.resolve(in: .init()).blue == 0.49803925)
}

@Test func uuid_asUInt64() {
  let uuid = UUID(123)
  #expect(uuid.asUInt64 == 8863084066665136128)
}
