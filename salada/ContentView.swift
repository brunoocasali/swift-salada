import SwiftUI
import UIKit
import Combine

var pub: AnyPublisher<[Currency], any Error>? = nil
var sub: Cancellable? = nil

var data: Currency? = nil
var response: URLResponse? = nil
var list = [100.0, 1000.0, 9306.0]

let baseURL = "https://paegx14xte.execute-api.us-east-1.amazonaws.com/dev/quote"

struct ContentView: View {
  @ObservedObject var data = CurrencyDataStore()
//  let data: CurrencyDataStore

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
        LoadedView(data: self.data)
      }
    }.onAppear { loadCurrency(from: "EUR", data: self.data) }
  }
}

func loadCurrency(from: String = "EUR", data: CurrencyDataStore = CurrencyDataStore()) {
  let url = URL(string: "\(baseURL)?from=\(from)&to=BRL")!
  let decoder = JSONDecoder()
  decoder.dateDecodingStrategy = .millisecondsSince1970

  pub = URLSession.shared.dataTaskPublisher(for: url)
//      .print("Test")
    .tryMap() { element -> Data in
      guard let httpResponse = element.response as? HTTPURLResponse,
        httpResponse.statusCode == 200 else {
          throw URLError(.badServerResponse)
        }
//        usleep(500000); // half second

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
          data.state = .failed(error)
          print(error.localizedDescription)
        }
    },
    receiveValue: { data.setCurrent(currency: $0.first) }
  )
}

extension CurrencyDataStore {
  static func previewData() -> CurrencyDataStore {
    let currency = Currency(
      lastUpdated: Date.now,
      sourceA: 5.12,
      sourceB: 0,
      sourceP: 4.142,
      rawExchange: "EUR/BRL"
    )

    return CurrencyDataStore(current: currency, state: .loaded)
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
      Group {
        ContentView(data: .previewData())
      }
    }
}

struct TileView: View {
  @ObservedObject var data = CurrencyDataStore()

  var body: some View {
    ZStack(alignment: .topTrailing) {
      Image("flag-\(data.current.from)")
        .resizable()
        .scaledToFill()
        .edgesIgnoringSafeArea(.all)
        .clipShape(Circle())
        .opacity(0.78)
        .frame(width: UIScreen.main.bounds.width / 1.5, height: UIScreen.main.bounds.height / 3)
        .offset(x: 50, y: -100)

      HStack {
        Text(data.current.fromStylized())
          .font(Font.custom("Ubuntu-Medium", size: 62))
          .padding(.all, 10)

        Spacer(minLength: 0)
      }.padding(.all, 10)
    }.onTapGesture {
      if self.data.current.from == "USD" {
        loadCurrency(from: "EUR", data: self.data)
      } else {
        loadCurrency(from: "USD", data: self.data)
      }
    }
  }
}

struct LoadedView: View {
  @ObservedObject var data = CurrencyDataStore()

  var body: some View {
    ZStack {
      Color.gray
          .opacity(0.18)
          .edgesIgnoringSafeArea(.all)

      VStack(alignment: .leading) {
        TileView(data: data)

        Spacer(minLength: 0)
      }.padding(.all, 1)

      VStack(alignment: .center) {
        HStack(alignment: .lastTextBaseline) {
          Text(data.current.amount(), format: .currency(code: data.current.to))
            .font(Font.custom("Ubuntu-Medium", size: 74))

          Text(data.current.to)
            .font(Font.custom("Ubuntu-Medium", size: 32))
            .multilineTextAlignment(.trailing)
        }

        HStack {
          VStack(alignment: .leading) {
            ForEach(list, id: \.self) { amount in
              Text("\(amount, format: .currency(code: data.current.from))  👉 \(data.current.amount() * amount, format: .currency(code: data.current.to))")
                .font(Font.custom("Ubuntu-Medium", size: 22))
                .padding(0.4)
            }
          }

          Spacer(minLength: 0)
        }.padding(.leading, 50.0)
      }
    }
  }
}
