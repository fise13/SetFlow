//
//  SetFlowApp.swift
//  SetFlow
//
//  Created by Виктор on 09.02.2026.
//

import SwiftUI

@main
struct SetFlowApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
    }
}
