//
//  DebugAppCheckProviderFactory.swift
//  Wave
//
//  Created by Jainesh Panchal on 4/11/25.
//

import Foundation
import FirebaseAppCheck
import FirebaseCore

class DebugAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        // This will trigger the token to emit
        let provider = AppCheckDebugProvider(app: app)

        // Wait briefly and print token
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if let debugToken = ProcessInfo.processInfo.environment["FIREBASE_APPCHECK_DEBUG_TOKEN"] {
                print("🪪 Firebase Debug Token: \(debugToken)")
            } else {
                print("❗️ Still no Firebase debug token found.")
            }
        }

        return provider
    }
}


