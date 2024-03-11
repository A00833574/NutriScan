//
//  ConclussionView.swift
//  NutriScan
//
//  Created by Gabriel Diaz Roa on 21/02/24.
//

import SwiftUI

struct ConclussionView: View {
    @State var startAgain = false
    var body: some View {
        GeometryReader { geo in
            VStack {
                Image("Memoji TY")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: geo.size.width/3)
                Text("Thank you for your consideration")
                    .multilineTextAlignment(.center)
                    .bold()
                    .font(.title)
                    .padding(.top, 25)
                    .frame(width: 300)
                Text("Thank you for using NutriScan to visualize your portions. Now try again with another of the built-in labels or, if you can, try with one of your own.")
                    .multilineTextAlignment(.center)
                    .padding()
                    .frame(width: 375)
                Button(action: {
                    startAgain = true
                }, label: {
                    Text("Try Again")
                })
                .buttonStyle(.borderedProminent)
                .padding(.top, 120)
            }
            .position(x: geo.size.width/2, y: geo.size.height/2)
        }
        .fullScreenCover(isPresented: $startAgain, content: {
            TextView()
        })
    }
}

#Preview {
    ConclussionView()
}
