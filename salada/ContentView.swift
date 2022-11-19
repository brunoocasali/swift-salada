import SwiftUI
import UIKit
import Combine
import CoreData

var pub: AnyPublisher<[Currency], any Error>? = nil
var sub: Cancellable? = nil

var data: Currency? = nil
var response: URLResponse? = nil


let baseURL = "https://paegx14xte.execute-api.us-east-1.amazonaws.com/dev/quote"

struct ContentView: View {
  @Environment(\.scenePhase) var scenePhase
  
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
          Text("Loading currencies!")
        }
      case .loaded:
        LoadedView(data: self.data, newConversion: "")
      }
    }.onAppear { loadCurrency(from: "EUR", data: self.data) }
      .onChange(of: scenePhase) { newPhase in
        if newPhase == .active {
          loadCurrency(from: "EUR", data: self.data)
        }
      }
  }
}

func styleCode(from: String) -> String {
  if from == "eur" {
    return "Euro"
  } else if from == "usd" {
    return "US Dollar"
  } else if from == "gbp" {
    return "UK Pound"
  }

  return from
}

func loadCurrency(from: String = "EUR", data: CurrencyDataStore = CurrencyDataStore()) {
//  data.state = .loading

  let url = URL(string: "\(baseURL)?from=\(from)&to=BRL")!
  let decoder = JSONDecoder()
  decoder.dateDecodingStrategy = .millisecondsSince1970

  pub = URLSession.shared.dataTaskPublisher(for: url)
    .tryMap() { element -> Data in
      guard let httpResponse = element.response as? HTTPURLResponse,
        httpResponse.statusCode == 200 else {
          throw URLError(.badServerResponse)
        }
        usleep(50000); // 50ms

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

  private let currencies: [String] = ["eur", "usd", "gbp"]
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
          }.padding()
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
  @State var newConversion: String
  @FocusState private var numIsFocused: Bool

  var body: some View {
    ZStack {
      Color.gray
        .opacity(0.18)
        .edgesIgnoringSafeArea(.all)

      VStack(alignment: .leading) {
        TileView(data: self.data)

        Spacer(minLength: 0)
      }.padding(.all, 1)

      VStack(alignment: .center) {
        HStack(alignment: .lastTextBaseline) {
          Text(self.data.current.amount(), format: .currency(code: self.data.current.to))
            .font(Font.custom("Ubuntu-Medium", size: 74))

          Text(self.data.current.to)
            .font(Font.custom("Ubuntu-Medium", size: 32))
            .multilineTextAlignment(.trailing)
        }.padding(.top, 80)
          .frame(height: 300, alignment: .center)

        Divider()
          .frame(width: UIScreen.main.bounds.width / 3, height: 1)
          .overlay(.gray)
          .padding(.bottom, 20)

        VStack {
          ZStack(alignment: .leading) {
            HStack {
              TextField("Number", text: $newConversion)
                .keyboardType(.decimalPad)
                .focused($numIsFocused)
                .modifier(TextFieldClearButton(text: $newConversion))
                .overlay(VStack { Divider().offset(x: 0, y: 15) })

              Spacer(minLength: 50)

              Button {
                self.data.upsertConversions(value: Double(newConversion))
                numIsFocused = false
                $newConversion.wrappedValue = ""
              } label: {
                Label("Conversion", systemImage: "plus")
                  .font(Font.custom("Ubuntu-Light", size: 18))
              }.buttonStyle(.bordered)
                .tint(.gray)

            }.padding()
          }

          ForEach(self.data.conversions, id: \.self) { amount in
            LineItemView(rate: amount, data: self.data)
          }

          if self.data.conversions.isEmpty {
            Text("No quick conversions added yet!")
              .font(Font.custom("Ubuntu-Light", size: 18))
          }
        }
      }
    }
  }
}

struct LineItemView: View {
  @State var rate: Double = 0.0
  var data = CurrencyDataStore()

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 6.0)
        .foregroundColor(Color.gray.opacity(0.08))
        .frame(height: 50)

      VStack {
        HStack {
          Text(rate, format: .currency(code: data.current.from))
            .font(Font.custom("Ubuntu-Light", size: 22))

          Spacer()

          Text(data.current.amount() * rate, format: .currency(code: data.current.to))
            .font(Font.custom("Ubuntu-Light", size: 22))
        }
      }.padding(.horizontal)
        .onTapGesture {
          if let index = self.data.conversions.firstIndex(of: rate) {
            self.data.conversions.remove(at: index)
          }
        }
    }.padding(.horizontal)
  }
}


struct TextFieldClearButton: ViewModifier {
    @Binding var text: String

    func body(content: Content) -> some View {
        HStack {
            content

            if !text.isEmpty {
                Button(
                    action: { self.text = "" },
                    label: {
                        Image(systemName: "delete.left")
                            .foregroundColor(Color(UIColor.opaqueSeparator))
                    }
                )
            }
        }
    }
}
