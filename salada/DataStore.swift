import Foundation
import SwiftUI
import Combine

struct Currency: Decodable {
  var sourceA: Double = 0
  var sourceB: Double = 0
  var sourceP: Double = 0
  var rawExchange: String = ""
  var lastUpdated: Date = Date.now
  var from: String = ""
  var to: String = ""

  init(lastUpdated: Date, sourceA: Double, sourceB: Double, sourceP: Double, rawExchange: String) {
    self.sourceA = sourceA
    self.sourceB = sourceB
    self.sourceP = sourceP
    self.rawExchange = rawExchange
    self.lastUpdated = lastUpdated

    self.setItems()
  }

  enum CodingKeys: String, CodingKey {
    case sourceA = "a"
    case sourceB = "b"
    case sourceP = "p"
    case rawExchange = "s"
    case lastUpdated = "t"
  }

  func amount() -> Double {
    [self.sourceA, self.sourceB, self.sourceP].max() ?? 0
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    self.sourceA = try container.decode(Double.self, forKey: .sourceA)
    self.sourceB = try container.decode(Double.self, forKey: .sourceB)
    self.sourceP = try container.decode(Double.self, forKey: .sourceP)
    self.rawExchange = try container.decode(String.self, forKey: .rawExchange)
    self.lastUpdated = try container.decode(Date.self, forKey: .lastUpdated)

    self.setItems()
  }

  init() { }

  private mutating func setItems() {
    let list = self.rawExchange.components(separatedBy: "/")

    self.from = list[0]
    self.to = list[1]
  }
}

// We define the DataStore as a Currency object
class CurrencyDataStore: ObservableObject {
  // @Published is a property wrapper that announces when changes occur to the DataStore.
  @Published var current = Currency()
  @Published var state = State.loading
  @Published var conversions: [Double] = [1000, 500]

  let maxConversions = 4

  init(current: Currency = Currency(), state: State = State.loading) {
    self.current = current
    self.state = state
  }

  enum State {
    case loading
    case failed(Error)
    case loaded
  }

  func setCurrent(currency: Currency?) {
    guard let data = currency else {
      return;
    }

    self.current = data
    self.state = .loaded
  }

  func upsertConversions(value: Double?) {
    guard let value = value else {
      return;
    }

    if conversions.contains(value) {
      return;
    }

    if conversions.count < maxConversions {
      conversions.insert(value, at: 0)
    } else {
      conversions.insert(value, at: 0)
      conversions.removeLast()
    }
  }
}
