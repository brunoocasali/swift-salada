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
        LoadedView(data: self.data)
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
              .font(Font.custom("Ubuntu-Light", size: 54))
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
  let maxConversions = 5

  @ObservedObject var data = CurrencyDataStore()
  @State var newConversion: String = ""
  @FocusState private var numIsFocused: Bool
  @Environment(\.managedObjectContext) private var viewContext
  @FetchRequest private var conversions: FetchedResults<Conversion>

  init(data: CurrencyDataStore) {
    let request: NSFetchRequest<Conversion> = Conversion.fetchRequest()
    request.fetchLimit = maxConversions
    request.sortDescriptors = [
      NSSortDescriptor(key: "date", ascending: false)
    ]

    _conversions = FetchRequest(fetchRequest: request)
    self.data = data
  }

  private func addConversion() {
    let value = Double(newConversion) ?? 0

    if conversions.count >= maxConversions {
      if let c = conversions.last {
        do {
          viewContext.delete(c)

          try viewContext.save()
        } catch {
          print(error.localizedDescription)
        }
      }
    }

    do {
      let conversion = Conversion(context: viewContext)

      conversion.id = UUID()
      conversion.currency = self.data.current.from
      conversion.total = value
      conversion.exchangeRate = self.data.current.amount()
      conversion.date = Date()

      try viewContext.save()
    } catch {
      print(error.localizedDescription)
    }
  }

  func deleteConversion(conversion: Conversion) {
    do {
      viewContext.delete(conversion)

      try viewContext.save()
    } catch {
      print(error.localizedDescription)
    }
  }

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
          // R$ 5.12
          Text(self.data.current.amount(), format: .currency(code: self.data.current.to))
            .font(Font.custom("Ubuntu-Light", size: 74))

          // BRL
          Text(self.data.current.to)
            .font(Font.custom("Ubuntu-Medium", size: 32))
            .multilineTextAlignment(.trailing)
        }.padding(.top, 140)
          .frame(height: UIScreen.main.bounds.height / 3)

        Divider()
          .frame(width: UIScreen.main.bounds.width / 3, height: UIScreen.main.bounds.height / 6000)
          .overlay(.gray)
          .background(Color.red)
          .padding(.bottom, UIScreen.main.bounds.height / 50)

        ZStack(alignment: .leading) {
          HStack {
            TextField("Number", text: $newConversion)
              .font(Font.custom("Ubuntu-Light", size: 18))
              .keyboardType(.decimalPad)
              .focused($numIsFocused)
              .modifier(TextFieldClearButton(text: $newConversion))
              .overlay(VStack { Divider().offset(x: 0, y: 15) })

            Spacer(minLength: 50)

            Button {
              addConversion()
              numIsFocused = false
              $newConversion.wrappedValue = ""
            } label: {
              Label("Conversion", systemImage: "plus")
                .font(Font.custom("Ubuntu-Light", size: 18))
            }.buttonStyle(.bordered)
              .tint(newConversion.isEmpty ? .gray : .blue)
              .disabled(newConversion.isEmpty)
          }.padding()
        }.frame(height: UIScreen.main.bounds.height / 14)

        VStack {
          ForEach(conversions) { conversion in
            LineItemView(
              conversion: conversion,
              rate: conversion.total,
              data: self.data,
              onDelete: deleteConversion
            )
          }

          if self.conversions.isEmpty {
            Text("No quick conversions added yet!")
              .font(Font.custom("Ubuntu-Light", size: 18))
          }
        }
        .frame(maxHeight: UIScreen.main.bounds.height / 2.8)
        .edgesIgnoringSafeArea(.bottom)
      }
    }
  }
}

struct LineItemView: View {
  @State var conversion: Conversion
  @State var rate: Double = 0.0
  var data = CurrencyDataStore()
  var onDelete: (_ item: Conversion) -> Void

  init(conversion: Conversion, rate: Double, data: CurrencyDataStore = CurrencyDataStore(), onDelete: @escaping (_ item: Conversion) -> Void) {
    self.conversion = conversion
    self.rate = rate
    self.data = data
    self.onDelete = onDelete
  }

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
    }.padding(.horizontal)
      .onTapGesture {
        self.onDelete(conversion)
      }.tag(conversion.id)
  }
}

// Modifier to add a button that can clear the value of an input
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
