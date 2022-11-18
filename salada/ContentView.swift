import SwiftUI
import UIKit
import Combine

var pub: AnyPublisher<[Currency], any Error>? = nil
var sub: Cancellable? = nil

var data: Currency? = nil
var response: URLResponse? = nil

let baseURL = "https://paegx14xte.execute-api.us-east-1.amazonaws.com/dev/quote"

struct ContentView: View {
  @ObservedObject var data = CurrencyDataStore()

  var body: some View {
    NavigationView {

      switch self.data.state {
      case .failed(_):
        VStack {
          Text("Failed loading currencies").foregroundColor(Color.red)
        }
      case .loading:
        VStack {
          Text("Loading currencies")
        }
      case .loaded:
        VStack {
          Text(data.current.from)
          Text(String(format: "%.2f", data.current.amount()))
  //          Color.blue
          HStack {
            Text("last updated: ").padding()
            HStack {
              Text(data.current.lastUpdated, style: .date)
              Text(data.current.lastUpdated, style: .time)
  //              Color.yellow
            }
          }
        }
      }

    }.onAppear { self.loadCurrency() }
  }

  func loadCurrency() {
    let url = URL(string: "\(baseURL)?from=EUR&to=BRL")!
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .millisecondsSince1970

    pub = URLSession.shared.dataTaskPublisher(for: url)
//      .print("Test")
      .tryMap() { element -> Data in
        guard let httpResponse = element.response as? HTTPURLResponse,
          httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
          }
        usleep(500000); // half second

        return element.data
      }
      .decode(type: [Currency].self, decoder: decoder)
      .receive(on: RunLoop.main)
      .eraseToAnyPublisher()

    sub = pub?.sink(
      receiveCompletion: { completion in
          switch completion {
          case .finished:
              break
          case .failure(let error):
            self.data.state = .failed(error)
            print(error.localizedDescription)
          }
      },
      receiveValue: { self.data.setCurrent(currency: $0.first) }
    )
  }
}

struct ColorSquare: View {
  let color: Color

  var body: some View {
    color
    .frame(width: 50, height: 50)
  }
}

struct SmallColorSquare: View {
    let color: Color

    var body: some View {
        color
        .frame(width: 10, height: 10)
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
      Group {
//        ContentView(myData: .current)
        ContentView()
      }
    }
}
