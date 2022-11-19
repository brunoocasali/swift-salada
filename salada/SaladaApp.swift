//
//  saladaApp.swift
//  salada
//
//  Created by Bruno on 17/11/22.
//

import SwiftUI

@main
struct SaladaApp: App {
  let persistentContainer = CoreDataManager.shared.persistentContainer

  var body: some Scene {
    WindowGroup {
      ContentView(data: CurrencyDataStore()).environment(\.managedObjectContext, persistentContainer.viewContext)
    }
  }
}
