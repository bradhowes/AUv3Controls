# Examples

This folder contains two Swift previews that are also the basis for the views in the demo application.

## Duality View

This view shows a collection of two float parameters and two boolean ones. The top of the view contains controls from
the AUv3Controls package, while the botton shows native macOS/iOS controls. Both sets of controls monitor the same set
of AUParameter entities, so when one set changes the AUParameter value, the other controls update automatically when
they receive notice of the change in value. All of this monitoring and signalling is done using the AUParameterTree data
structure that holds the collection of AUParameter entities defined by the app.

## Envelope View

The second view shows two sets of envelope settings for a hypothetical synthesizer. The collection scrolls if the device
is too small to show all of the knobs at the same time. Tapping/clicking on a knob's title will bring up an editor for
setting a value using the keyboard.
