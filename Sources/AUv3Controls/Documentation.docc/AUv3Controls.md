# ``AUv3Controls``

SwiftUI knob and toggle controls for use with AUv3 component displays. 

These SwiftUI controls track and update parameters found in an AUParameterTree. Manipulating the control will cause a change to the
underlying AUParameter value which would presumably cause a change in a AUv3 component (synthesizer, audio effect, etc.). Likewise,
if another entity changed the AUParameter value, the control would automatically update to show the changed value. Such changes 
might come from a MIDI device or from a user selecting a preset.

These controls utilize [The Composable Architecture (TCA)](https://github.com/pointfreeco/swift-composable-architecture) package
for Swift by [Point-Free](https://www.pointfree.co). The code for the controls has very good testing coverage for SwiftUI
components, mainly due to use of the "feature" architecture recommended by the TCA documentation.

## Additional Resources

- [GitHub Repo](https://github.com/bradhowes/AUv3Controls)
- [The Composable Architecture (TCA)](https://github.com/pointfreeco/swift-composable-architecture)

## Controls

The package contains defines two Swift UI controls. There is a circular knob (``KnobFeature``) that acts like a SwiftUI
slider. Touching on the knob and moving up or down increases or decreases the value represented by the knob. Usually the
know shows the value's name in a text field at the bottom, but when the knob is being manipulated, the text field shows
the current value. You can see the current value at any time by tapping on the knob.

For precise data entry, the knob can transform into an input editor (``EditorFeature``) where the value can be edited
and manipulated. Tapping on the name of the knob brings up the editor.

![demo image](media/demo.gif)

The second custom control (``ToggleFeature``) offers a simple boolean on/off setting.

![](media/toggle.gif)

Both controls support customization via ``Theme`` definitions. Themes are set on a SwiftUI view hierarchy using
the ``/SwiftUICore/EnvironmentValues/auv3ControlsTheme`` view modifier.

## Topics

### Views

- ``KnobFeature``
- ``ToggleFeature``
- ``EditorFeature``

### Customization

- ``Theme``
- ``KnobConfig``
- ``/SwiftUICore/EnvironmentValues/auv3ControlsTheme``
- ``/SwiftUICore/EnvironmentValues/auv3ControlsKnobConfig``

### Integration

- <doc:AUv3Integration>
