//
//  Preferences.swift
//  salada
//
//  Created by Bruno on 19/11/22.
//

import Foundation

struct Preferences {
  static var currencyCode: String {
    get {
      return UserDefaults.standard.object(forKey: "lastCode") as? String ?? "EUR"
    }

    set(code) {
      UserDefaults.standard.set(code, forKey: "lastCode")
    }
  }
}
