//
//  AUv3Controls_DemoApp.swift
//  AUv3Controls Demo
//
//  Created by Brad Howes on 12/11/2023.
//

import SwiftUI

@main
struct AUv3Controls_DemoApp: App {
  var body: some Scene {
    WindowGroup {
      TabView {
        DualityView()
          .padding()
          .tabItem {
            Label("Duality", systemImage: "1.circle")
          }
          .tag(1)
        VStack {
          EnvelopeView(title: "Amp")
          EnvelopeView(title: "Filter")
        }
        .padding()
        .tabItem {
          Label("Envelope", systemImage: "1.circle")
        }
        .tag(2)
      }
    }
  }
}
