//
//  WaveApp.swift
//  Wave
//
//  Created by Jainesh Panchal on 4/11/25.
//

import SwiftUI
import Firebase
import FirebaseAppCheck

@main
struct WaveApp: App {
    init() {
        // Enable debug mode
        UserDefaults.standard.set(true, forKey: "FirebaseAppCheckDebugMode")
        print("🔑 App Check Debug Mode is ON")

        FirebaseApp.configure()

        // Use debug provider instead of App Attest for development
        AppCheck.setAppCheckProviderFactory(DebugAppCheckProviderFactory())

        print("🚀 Firebase and App Check (Debug Provider) initialized")
    }

    var body: some Scene {
        WindowGroup {
            PhoneAuthView()
        }
    }
}



