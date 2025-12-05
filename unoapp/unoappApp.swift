//
//  unoappApp.swift
//  unoapp
//
//  Created by Kawus Nouri on 05/12/2025.
//

import SwiftUI
import CoreData

@main
struct unoappApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
