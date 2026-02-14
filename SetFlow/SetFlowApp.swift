//
//  SetFlowApp.swift
//  SetFlow
//
//  Created by Виктор on 09.02.2026.
//

import SwiftUI
import FirebaseCore
#if canImport(UIKit)
import UIKit
#endif

#if canImport(UIKit)
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        return true
    }
}
#endif

@main
struct SetFlowApp: App {
    @StateObject private var appState = AppState()
#if canImport(UIKit)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
#endif

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
    }
}
