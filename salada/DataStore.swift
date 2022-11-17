import Foundation
import SwiftUI
import Combine

// Here we define an ID and a TaskItem for every Task.
struct Task : Identifiable {
    var id = String()
    var taskItem = String()
}

// We define the DataStore as an array of Tasks.
class TaskDataStore: ObservableObject {
    // @Published is a property wrapper that announces when changes occur to the DataStore.
    @Published var tasks = [Task]()
}


// Here we define an ID and a TaskItem for every Task.
struct Currency: Decodable {
//  let from: String
  let amount: Double
  let value: String
  let lastUpdated: Date

  init(
    lastUpdated: Date,
    amount: Double,
    value: String) {
    self.amount = amount
//    self.to = to
    self.value = value
      self.lastUpdated = lastUpdated
  }

  enum CodingKeys: String, CodingKey {
    case value = "s"
    case amount = "a"
    case lastUpdated = "t"
//    case from, to = "s"
  }
}

// We define the DataStore as an array of Tasks.
class CurrencyDataStore: ObservableObject {
    // @Published is a property wrapper that announces when changes occur to the DataStore.
  @Published var current: Currency?
}
