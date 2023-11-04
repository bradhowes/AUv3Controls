# AUv3Controls

SwiftUI knob and toggle controls for use with AUv3 components.
Uses the [Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture)
by [Point-Free](https://www.pointfree.co).

The controls are attached to AUParameter entities, so changes in the control will affect their associated AUParameter
value. This works the other way as well: external changes to the AUParameter -- say from a MIDI controller or
preset load -- will be reflected in the control.

[!](demo.gif)
