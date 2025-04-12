//
//  WaveApp.swift
//  Wave
//
//  Created by Jainesh Panchal on 4/11/25.
//

import SwiftUI

@main
struct WaveApp: App {
    // 👇 Inject the delegate here
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
