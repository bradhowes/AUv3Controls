# AUv3 integration

Learn how to integrate a knob or toggle with an AUv3 parameter.

## Overview

The ``KnobFeature`` and ``ToggleFeature`` work just fine on their own as custom SwiftUI views, but their real power
becomes apparent when they are used with AUParameter values from an AUParameterTree.

The following is sample code taken from a demo application generated using the
[auv3-support](http://github.com/bradhowes/auv3-support) package. The code defines the UI for a toy audio unit that simply acts 
like a volume control. As such, the audio unit only has one parameter called "gain".

```swift
import AUv3Controls
import ComposableArchitecture
import SwiftUI

struct AUMainView: View {
  let gainStore: StoreOf<KnobFeature>
  let knobWidth: CGFloat = 160

  init(gain: AUParameter) {
    gainStore = Store(initialState: KnobFeature.State(parameter: gain)) { KnobFeature(parameter: gain) }
  }

  var body: some View {
    Group {
      VStack {
        KnobView(store: gainStore)
          .frame(maxWidth: topKnobWidth)
      }
    }
  }
}
```

That is pretty much all that is necessary to integrate with AUv3 component.
