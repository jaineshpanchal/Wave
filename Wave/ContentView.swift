//
//  ContentView.swift
//  Wave
//
//  Created by Jainesh Panchal on 4/11/25.
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {
    @State private var isUserLoggedIn = Auth.auth().currentUser != nil

    var body: some View {
        Group {
            if isUserLoggedIn {
                TabView {
                    HomeView()
                        .tabItem {
                            Label("Bubbles", systemImage: "bubble.left.and.bubble.right")
                        }
                    ReminderView()
                        .tabItem {
                            Label("Reminders", systemImage: "alarm")
                        }
                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gearshape")
                        }
                }
            } else {
                PhoneAuthView()
            }
        }
        .onAppear {
            isUserLoggedIn = Auth.auth().currentUser != nil
        }
    }
}

