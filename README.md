[![CI][status]][ci]
[![COV][cov]][ci]
[![][spiv]][spi]
[![][spip]][spi]
[![][mit]][license]

# AUv3Controls -- SwiftUI knob and toggle for AUv3 audio components

Uses the excellent [Composable Architecture][tca] for Swift by [Point-Free][pf] to structure the controls into units or
"features" that are composable and well-tested.

The controls can be attached to AUParameter entities, so changes in the control will affect their associated AUParameter
value. This works the other way as well: external changes to the AUParameter value -- say from a MIDI controller or a
preset load -- will be reflected in the control. Below is a demonstration on iOS in the "light" color scheme:

![][duality-ios]

And below is a rendering of the same component on macOS using the "dark" color scheme:

![][duality-macos]

## Controls

There is a circular knob -- [KnobFeature][knob] -- that acts like a vertical slider. It normally shows the setting's
name, but when manipulated it shows the current value. Additionally, tapping/clicking on the name will bring up an
editor to type in a new value.

The other control is a toggle -- [ToggleFeature][toggle]. It simply offers a boolean on/off setting.

![][knob-demo]

* Vertical dragging changes the value of the knob
* Moving horizontally away from the center of the knob will increase resolution of vertical movements allowing for finer 
adjustments to the knob's value
* Touching the title will show an editor to allow typing a value

The toggle view just works on boolean values:

![][toggle-demo]

Here is a combination of several knobs into two distinct groups. The groups are embedded in a scroll view so as to
operate under narrow device width constrains. This also illustrates the use of two different themes:

![][envelopes]

# Theme Configuration

Both controls support a way to configure their display via a [Theme][theme] definition. To use it, one provides it to
the view using the `.auv3ControlsTheme` view modifier. The theme applies to all views in the view hierarchy starting at
the one with the view modifier. This allows one to provide different themes to different collections of controls.

```swift
TabView {
  FirstView()
    .auv3ControlsTheme(theme1)
    .tabItem { Label("First", systemImage: "1.circle") }
    .tag(1)
  SecondView()
    .auv3ControlsTheme(theme2)
    .tabItem { Label("Second", systemImage: "2.circle") }
    .tag(2)
}
```

There are currently six (6) color settings that are configurable:

- `controlBackgroundColor` -- color of the knob control's track background
- `controlForegroundColor` -- color the knob control's track foreground and the toggle icon
- `editorBackgroundColor` -- color of the editor's background (not used)
- `editorCancelButtonColor` -- text color of the editor's cancel button
- `editorOKButtonColor` -- text color of the editor's OK button
- `textColor` -- text color for text labels not covered by the above color settings

Each color setting can provide a unique value for the current _color scheme_ of the device (_light_ or _dark_). For
instance, the default theme defines the `controlBackroundColor` to be `Color.gray.mix(with: Color.white, by: 0.5)` when
in _light_ mode, but it is set to `Color.black.mix(with: Color.white, by: 0.2)` when in _dark_ mode. The color settings
can also provide the same value for both color schemes.

> **NOTE**: for this to work properly, one must create a [Theme][theme] in a SwiftUI view context, and provide the theme
> the value from `@Environment(\.colorScheme)`. See the [EnvelopeView][demo-code] demo code for an example of how this
> is done.


A [Theme][theme] instance can look for color assets in a bundle if desired. When constructed, a theme takes two
(optional) parameters -- a _prefix_ `String` and a _bundle_ pointer -- that indicate where the assets will be found and
under what name. For instance, if `prefix` is "VFO" and `bundle` is `Bundle.main` then a theme will look for a color
asset with the name "VFO_controlBackgroundColor" in the application's main bundle, and use it if it is found. Otherwise,
it will fallback to the default values. The use of a non-empty `prefix` value allows for multiple instances of a
`controlBackgroundColor` value in the same bundle.

```swift
.auv3ControlsTheme(.init(colorScheme: colorScheme, prefix: "VFO", bundle: Bundle.main))
```

# Demo App

There is a simple demonstration application that runs on both macOS and iOS which shows the linkage via AUv3 parameters
between AUv3 controls and AppKit/UIKit controls -- changes to one control cause a change in a specific AUParameter, 
which is then seen by the other control. To build and run, open the Xcode project file in the [Demo](Demo) 
folder. 

> **NOTE** : Make sure that the AUv3Controls package [Package.swift](Package.swift) file is not current open or else the
> demo will fail to build.

[ci]: https://github.com/bradhowes/AUv3Controls/actions/workflows/CI.yml
[status]: https://github.com/bradhowes/AUv3Controls/workflows/CI/badge.svg
[cov]: https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/bradhowes/09b95180719ff3c213d0d57a87f5202e/raw/AUv3Controls-coverage.json
[spi]: https://swiftpackageindex.com/bradhowes/AUv3Controls
[spiv]: https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fbradhowes%2FAUv3Controls%2Fbadge%3Ftype%3Dswift-versions
[spip]: https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fbradhowes%2FAUv3Controls%2Fbadge%3Ftype%3Dplatforms
[mit]: https://img.shields.io/badge/License-MIT-A31F34.svg
[license]: https://opensource.org/licenses/MIT
[tca]: https://github.com/pointfreeco/swift-composable-architecture
[pf]: https://www.pointfree.co
[duality-ios]: media/duality-ios.gif?raw=true
[duality-macos]: media/duality-macos.gif?raw=true
[knob]: Sources/AUv3Controls/Knob/KnobFeature.swift
[toggle]: Sources/AUv3Controls/Toggle/ToggleFeature.swift
[theme]: Sources/AUv3Controls/Theme.swift
[knob-demo]: media/knob.gif?raw=true
[toggle-demo]: media/toggle.gif?raw=true
[envelopes]: media/envelopes.gif?raw=true
[demo-code]: https://github.com/bradhowes/AUv3Controls/blob/2942bb4da342d76d0139d19e224cfdb2c970fba4/Sources/AUv3Controls/Examples/Envelope.swift#L220
