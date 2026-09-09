//
//  StickerzzApp.swift
//  Stickerzz
//
//  Created by Kathryn Heligman on 9/9/26.
//

import SwiftUI
import CoreData

@main
struct StickerzzApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
