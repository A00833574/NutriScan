//
//  ContentView.swift
//  NutriScan
//
//  Created by Gabriel Diaz Roa on 28/01/24.
//

import SwiftUI

struct Item: Identifiable {
    var id = UUID()
    var name: String
    var text: String
    var imageName: String
}

struct ItemView: View {
    var item: Item
    
    var body: some View {
        VStack {
            Image(item.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity)
            Text(item.name)
                .multilineTextAlignment(.center)
                .bold()
                .font(.title)
                .padding(.top, 25)
                .frame(width: 300)
            Text(item.text)
                .multilineTextAlignment(.center)
                .padding()
        }
    }
}

struct CarouselView: View {
    var items: [Item]
    @Binding var currentIndex: Int
    
    var body: some View {
        TabView(selection: $currentIndex) {
            ForEach(items.indices, id: \.self) { index in
                ItemView(item: items[index])
                    .tag(index)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
    }
}


struct PageIndicator: View {
    var currentIndex: Int
    var itemCount: Int
    
    var body: some View {
        HStack {
            ForEach(0..<itemCount, id: \.self) { index in
                Circle()
                    .fill(index == currentIndex ? Color.accentColor : Color.gray)
                    .frame(width: 8, height: 8)
            }
        }
    }
}


struct ContentView: View {
    @State var showCameraView = false
    @State private var currentIndex: Int = 0
    let items = [
        Item(name: "Welcome to NutriScan", text: "Simply scan the Nutrition Facts label of your favorite snacks and find out how much you should eat", imageName: "Logo"),
        Item(name: "What is NutriScan?", text: "NutriScan is meant to help you eat healthier by making it easy to control your snack intake, helping you manage your eating habits without needing to measure every portion", imageName: "Memoji Doubt"),
        Item(name: "Who am I?", text: "Hi, my name is Gabriel Eduardo Diaz Roa, I'm 21 years old, I'm a Mexican student pursuing a B.S. in Computer Science and Technology @ Tecnológico de Monterrey in Nuevo León", imageName: "Memoji"),
        Item(name: "Why did I develop NutriScan?", text: "As a university student struggling between affordable meals and keeping in shape, I found myself buying junk food to avoid hunger after long classes but this didn't help much because I was still hungry and ended up losing money", imageName: "Memoji Lap"),
        Item(name: "The Idea", text: "But with little time and money, following a strict diet and consulting a nutrionist was a lot harder than I expected, so that's when I came up with NutriScan, a tool to help you visualize your snacks' portions", imageName: "Memoji Idea")
    ]
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                VStack {
                    VStack {
                        CarouselView(items: items, currentIndex: $currentIndex)
                            .frame(height: 400)
                        PageIndicator(currentIndex: currentIndex, itemCount: items.count)
                            .padding(.top, 20)
                    }
                    .position(x: geo.size.width/2, y: geo.size.height/2.5)
                    if currentIndex == items.count - 1 {
                        Button("Begin") {
                            showCameraView = true
                        }
                        .buttonStyle(.borderedProminent)
                        .position(x: geo.size.width/2, y: geo.size.height/2.5)
                    } else {
                        Button("Begin") {
                            showCameraView = true
                        }
                        .disabled(true)
                        .buttonStyle(.borderedProminent)
                        .position(x: geo.size.width/2, y: geo.size.height/2.5)
                    }
                }
                .navigationDestination(isPresented: $showCameraView) {
                    TextView()
                }
            }
        }
    }
}
