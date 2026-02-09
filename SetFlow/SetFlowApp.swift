//
//  SetFlowApp.swift
//  SetFlow
//
//  Created by Виктор on 09.02.2026.
//

import SwiftUI
import CoreData

@main
struct SetFlowApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
