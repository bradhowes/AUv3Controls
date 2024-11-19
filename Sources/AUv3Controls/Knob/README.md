# Knob Control

Collection of Composable Architecture features that together make up a knob that can monitor and update an AUParameter
value. The top-level feature is the [KnobFeature](KnobFeature.swift). It serves as the coordinator for the other
features that perform specialized tasks.

- [ControlFeature](ControlFeature.swift) -- holds the 'track' of the knob and its title, and keeps them up to date when
an AUParameter changes.
- [EditorFeature](EditorFeature.swift) -- provides a view that allows for editing of a AUParameter value using the 
keyboard.
- [KnobConfig](KnobConfig.swift) -- configurable attributes for a `KnobFeature` view and store.
- [KnobFeature](KnobFeature.swift) -- the main feature for a floating-point control. It contains and relies on other
features. Tapping on the title of the knob will bring up an editor to allow you to change the value via the keyboard.
Otherwise, changing the value is done by tapping (iOS) or clicking (macOS) on the control and dragging up or down.
- [TitleFeature](TitleFeature.swift) -- shows the title of the knob, and when the value changes, it briefly shows it
before reverting back to the title.
- [TrackFeature](TrackFeature.swift) -- manages the indicator track of the knob. Handles the tracking of touch drags
(iOS) or mouse movements with the button pressed (macOS).
