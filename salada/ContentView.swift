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
        ZStack {
          Color.gray
              .opacity(0.18)
              .edgesIgnoringSafeArea(.all)

          VStack(alignment: .leading) {
            HStack {
              Text("\(data.current.fromStylized()) today")
                .font(Font.custom("Ubuntu-Light", size: 42))
                .padding(.all, 10)

              Spacer(minLength: 0)
            }.padding(.all, 10)
//              .background(RoundedRectangle(cornerRadius: 6).fill(Color("Euro")))
//              .background(ContainerRelativeShape().fill(Color.blue))

            Spacer(minLength: 0)
          }.padding(.all, 10)

          VStack(alignment: .center) {
            HStack {
              Text(data.current.amount(), format: .currency(code: data.current.to))
                .font(Font.custom("Ubuntu-Medium", size: 72))
            }

            HStack {
              Text("🕑")

              HStack {
                Text("\(data.current.lastUpdated, style: .relative) ago")
              }
            }.padding([.top, .bottom], 50)


//          Text("Saved values:")

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
        ContentView()
      }
    }
}
