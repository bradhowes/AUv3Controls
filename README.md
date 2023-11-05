# AUv3Controls

SwiftUI knob and toggle controls for use with AUv3 components. Uses the excellent
[Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture) for Swift by
[Point-Free](https://www.pointfree.co).

The controls are attached to AUParameter entities, so changes in the control will affect their associated AUParameter
value. This works the other way as well: external changes to the AUParameter -- say from a MIDI controller or
preset load -- will be reflected in the control.

![](https://github.com/bradhowes/AUv3Controls/blob/main/demo.gif?raw=true)

* Vertical dragging changes the value of the knob
* Moving horizontally away from the center of the knob will increase resolution of vertical movements
* Touching the title will show an editor to allow typing a value
* When present, uses `ScrollViewProxy` to make sure that the editor is visible when it appears

The toggle view just works on boolean values:

![](https://github.com/bradhowes/AUv3Controls/blob/main/toggle.gif?raw=true)

Here is a combination of several knobs into two distinct groups. The groups are embedded in a scroll view so as to
operate under narrow device width constrains:

![](https://github.com/bradhowes/AUv3Controls/blob/main/envelopes.gif?raw=true)
