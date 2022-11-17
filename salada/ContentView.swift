//
//  ContentView.swift
//  salada
//
//  Created by Bruno on 17/11/22.
//

import SwiftUI
import UIKit
import Combine

struct ContentView: View {
    // @ObservedObject is a property wrapper that gives the views (User Interface) a way to watch the state of an object. For example, a datastore.
    // Here we create a taskStore observedObject that references to TaskDataStore (We will be defining this later on).
//    let myData: CurrencyDataStore

    @ObservedObject var currency = CurrencyDataStore()

    // The state property wrapper is used to move the variable storage outside of the current struct into shared storage.
    // We create a variable newTask to maintain the current task that is entered on the screen.
    @State var newTask : String = ""

    // Body of the ContentView
    var body: some View {
      NavigationView {
        VStack {
          Text(String(currency.current?.value ?? "loading"))
          Text(String(currency.current?.amount ?? 0))
//          Color.blue
          HStack {
            Text("last updated: ").padding()
            HStack {
              Text(currency.current?.lastUpdated ?? Date.now, style: .date)
              Text(currency.current?.lastUpdated ?? Date.now, style: .time)
//              Color.yellow
            }
          }
        }
      }.onAppear { self.loadCurrency() }
//      var body: some View {
//          Grid(alignment: .topLeading,
//               horizontalSpacing: 1,
//               verticalSpacing: 30) {
//              GridRow {
//                  ForEach(0..<5) { _ in
//                      ColorSquare(color: .pink)
//                  }
//              }
//              GridRow(alignment: .bottom) {
//                  SmallColorSquare(color: .yellow)
//                      .gridColumnAlignment(.center)
//                  SmallColorSquare(color: .yellow)
//                  SmallColorSquare(color: .yellow)
//                  SmallColorSquare(color: .yellow)
//                  ColorSquare(color: .yellow)
//              }
//          GridRow(alignment: .center) {
//                  SmallColorSquare(color: .mint)
//                  SmallColorSquare(color: .mint)
//                      .gridColumnAlignment(.trailing)
//                  SmallColorSquare(color: .mint)
//                  SmallColorSquare(color: .mint)
//                  ColorSquare(color: .mint)
//
//              }
//              GridRow {
//                  SmallColorSquare(color: .purple)
//                      .gridCellAnchor(.bottomTrailing)
//
//                  SmallColorSquare(color: .purple)
//                      .gridCellAnchor(.bottomLeading)
//
//                  SmallColorSquare(color: .purple)
//                  SmallColorSquare(color: .purple)
//                  ColorSquare(color: .purple)
//
//              }
//          }
//      }
    }


  func loadCurrency() {
    let url = URL(string: "https://paegx14xte.execute-api.us-east-1.amazonaws.com/dev/quote?from=EUR&to=BRL")!

    let task = URLSession.shared.dataTask(with: url) { data, response, error in
        if let data = data {
          print(String(data: data, encoding: String.Encoding.utf8) ?? "something")
          let decoder = JSONDecoder()
          decoder.dateDecodingStrategy = .millisecondsSince1970

          if let currencies = try? decoder.decode([Currency].self, from: data) {
              print(currencies)
            self.currency.current = currencies.first

            } else {
                print("Invalid Response")
            }
        } else if let error = error {
            print("HTTP Request Failed \(error)")
        }
    }

    task.resume()
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
