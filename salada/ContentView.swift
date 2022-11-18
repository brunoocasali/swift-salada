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

func styleCode(from: String) -> String {
  if from == "eur" {
    return "Euro"
  } else if from == "usd" {
    return "US Dollar"
  }

  return from
}

func loadCurrency(from: String = "EUR", data: CurrencyDataStore = CurrencyDataStore()) {
//  data.state = .loading

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
        usleep(200000); // 200ms

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

  private let currencies: [String] = ["eur", "usd"]
  @State var activeCurrency: String = "eur"

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

      TabView(selection: $activeCurrency) {
        ForEach(currencies, id: \.self) { code in
          HStack {
            Text(styleCode(from: code))
              .font(Font.custom("Ubuntu-Medium", size: 62))
              .padding(.all, 10)

            Spacer(minLength: 0)
          }.padding(.all, 10)
           .tag(code)
        }
      }.tabViewStyle(.page(indexDisplayMode: .always))
        .frame(height: 190)
        .edgesIgnoringSafeArea(.all)
        .onChange(of: activeCurrency, perform: { code in
          loadCurrency(from: code, data: self.data)
        })
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

        Divider()
          .frame(width: UIScreen.main.bounds.width / 3, height: 1)
          .overlay(.gray)
          .padding(.bottom, 20)



        VStack {
          ZStack(alignment: .leading) {
            Text("Quick conversions:").padding(.bottom)
              .font(Font.custom("Ubuntu-Light", size: 20))
              .multilineTextAlignment(.leading)
          }

          ForEach(list, id: \.self) { amount in
            LineItemView(rate: amount, data: self.data)
          }
        }
      }
    }
  }
}

struct LineItemView: View {
  var rate: Double = 0.0
  var data = CurrencyDataStore()

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 6.0)
        .foregroundColor(Color.gray.opacity(0.08))
        .frame(height: 60)

      VStack {
        HStack {
          Text(rate, format: .currency(code: data.current.from))
            .font(Font.custom("Ubuntu-Light", size: 22))

          Spacer()

          Text(data.current.amount() * rate, format: .currency(code: data.current.to))
            .font(Font.custom("Ubuntu-Light", size: 22))
        }
      }.padding(.horizontal)
    }.padding(.horizontal)
  }
}
