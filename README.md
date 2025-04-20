[![CI](https://github.com/bradhowes/AUv3Controls/workflows/CI/badge.svg)](.github/workflows/CI.yml)
[![COV](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/bradhowes/09b95180719ff3c213d0d57a87f5202e/raw/AUv3Controls-coverage.json)](.github/workflows/CI.yml)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fbradhowes%2FAUv3Controls%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/bradhowes/AUv3Controls)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fbradhowes%2FAUv3Controls%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/bradhowes/AUv3Controls)

# AUv3Controls

SwiftUI knob and toggle controls for use with AUv3 components. Uses the excellent
[Composable Architecture](https://github.com/pointfreeco/swift-composable-architecture) for Swift by
[Point-Free](https://www.pointfree.co).

The controls are attached to AUParameter entities, so changes in the control will affect their associated AUParameter
value. This works the other way as well: external changes to the AUParameter -- say from a MIDI controller or
preset load -- will be reflected in the control. Below is a demonstration on iOS:

![](Duality.gif?raw=true)

And below shows rendering on macOS:

![](Duality_macos.gif?raw=true)

## Controls

There is a circular knob -- [KnobFeature](Sources/Knob/KnobFeature.swift) -- that acts like a vertical slider.
It normally shows the setting's name, but when being 
manipulated it shows the current value. Additionally, tapping/clicking on the name will bring up an editor in which
one can edit the value.

The other control is a toggle -- [ToggleFeature](Sources/Toggle/ToggleFeature.swift). It simply offers a boolean on/off
setting.

Both controls support a way to configure their display via a [Theme](Sources/Theme.swift) definition. To apply it one
must supply a custom theme via the View `.auv3ControlsTheme` modifier.

The `KnobFeature` offers a large number of configuration parameters in the [KnobConfig](Sources/Knob/KnobConfig.swift).
A custom value can be provided in the constructor of the `KnobFeature`.

![](demo.gif?raw=true)

* Vertical dragging changes the value of the knob
* Moving horizontally away from the center of the knob will increase resolution of vertical movements
* Touching the title will show an editor to allow typing a value
* When present, uses `ScrollViewProxy` to make sure that the editor is visible when it appears

The toggle view just works on boolean values:

![](toggle.gif?raw=true)

Here is a combination of several knobs into two distinct groups. The groups are embedded in a scroll view so as to
operate under narrow device width constrains:

![](envelopes.gif?raw=true)

# Configuration and Theme

The KnobFeature 

# Demo App

There is a simple demonstration application that runs on both macOS and iOS which shows the linkage via AUv3 parameters
between AUv3 controls and AppKit/UIKit controls -- changes to one control cause a change in a specific AUParameter, 
which is then seen by the other control. To build and run, open the Xcode project file in the [Demo](Demo) 
folder. Make sure that the AUv3Controls package [Package.swift](Package.swift) file is not current open or else the demo
will fail to build. 
