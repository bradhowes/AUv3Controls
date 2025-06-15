//
//  AUv3Controls_DemoApp.swift
//  AUv3Controls Demo
//
//  Created by Brad Howes on 12/11/2023.
//

import AUv3Controls
import SwiftUI

@main
struct AUv3Controls_DemoApp: App {
  var body: some Scene {
    var theme = Theme()
    theme.controlTrackStrokeStyle = StrokeStyle(lineWidth: 5, lineCap: .round)
    theme.controlValueStrokeStyle = StrokeStyle(lineWidth: 3, lineCap: .round)
    theme.toggleOnIndicatorSystemName = "arrowtriangle.down.fill"
    theme.toggleOffIndicatorSystemName = "arrowtriangle.down"

    return WindowGroup {
      TabView {
        DualityView()
          .padding()
          .tabItem {
            Label("Duality", systemImage: "1.circle")
          }
          .tag(1)
        EnvelopeViews()
          .padding()
          .tabItem {
            Label("Envelopes", systemImage: "1.circle")
          }
          .tag(2)
      }
    }
  }
}
