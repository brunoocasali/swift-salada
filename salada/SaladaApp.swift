//
//  saladaApp.swift
//  salada
//
//  Created by Bruno on 17/11/22.
//

import SwiftUI

@main
struct SaladaApp: App {
    var body: some Scene {
        WindowGroup {
          ContentView(data: CurrencyDataStore())
        }
    }
}
