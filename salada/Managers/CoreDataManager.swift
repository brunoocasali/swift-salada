//
//  CoreDataManager.swift
//  salada
//
//  Created by Bruno on 19/11/22.
//

import Foundation
import CoreData

class CoreDataManager {
  let persistentContainer: NSPersistentContainer
  static let shared: CoreDataManager = CoreDataManager()

  private init() {
    persistentContainer = NSPersistentContainer(name: "SaladaModel")
    persistentContainer.loadPersistentStores { description, error in
      if let error = error {
        fatalError("Unable to initialize Core Data \(error)")
      }
    }
  }
}
