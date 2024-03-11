//
//  TextView.swift
//  NutriScan
//
//  Created by Gabriel Diaz Roa on 28/01/24.
//

import SwiftUI
import Vision
import Foundation

struct TextView: View {
    
    @State private var imageTaken : UIImage?
    @State private var nutritionFacts = [String: String]()
    @State private var isLoading = false
    @State private var showPortion = false
    @State private var showAlert = false
    @State private var volume : Float = 0
    
    func recognizeAndParseText() {
        print("reading text")
        let requestHandler = VNImageRequestHandler(cgImage: self.imageTaken!.cgImage!)
        
        let recognizeTextRequest = VNRecognizeTextRequest { (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            
            self.parseText(from: observations)
        }
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try requestHandler.perform([recognizeTextRequest])
                
                self.isLoading = false
            }
            catch {
                print(error)
            }
        }
    }
    
    func parseText(from observations: [VNRecognizedTextObservation]) {
        var nutritionFacts: [String: String] = [:]
        let keysOfInterest = ["Serving size", "Calories", "Total Fat", "Sodium", "Total Carbohydrate", "Total Sugars", "Protein"]
        
        for observation in observations {
            if let topCandidate = observation.topCandidates(1).first {
                let text = topCandidate.string
                
                for key in keysOfInterest {
                    if text.hasPrefix(key) {
                        var value = String(text.dropFirst(key.count)).trimmingCharacters(in: .whitespaces)
                        
                        // If the key is "Serving size", extract the text within parentheses
                        if key == "Serving size" {
                            let pattern = "\\((.*?)\\)"
                            let regex = try? NSRegularExpression(pattern: pattern)
                            if let match = regex?.firstMatch(in: value, options: [], range: NSRange(location: 0, length: value.utf16.count)) {
                                if let range = Range(match.range(at: 1), in: value) {
                                    value = String(value[range])
                                }
                            }
                        }
                        
                        nutritionFacts[key] = value
                        break
                    }
                }
            }
        }
        
        DispatchQueue.main.async {
            self.nutritionFacts = nutritionFacts
        }
    }
    
    var pictureTakenView : some View {
        VStack {
            Image(uiImage: self.imageTaken!)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 200, height: 200)
            Button(action: {
                self.imageTaken = nil
                self.nutritionFacts = [:]
            }, label: {
                HStack {
                    Image(systemName: "camera")
                    Text("Re-take picture")
                }
            })
            List {
                ForEach(self.nutritionFacts.keys.sorted(), id: \.self) { key in
                    Text("\(key): \(self.nutritionFacts[key]!)")
                }
            }
            Button {
                if let servingSize = nutritionFacts["Serving size"] {
                    var components = servingSize.components(separatedBy: " ")
                    if components.count == 2 {
                        if let quantityString = components.first, let quantity = Float(quantityString) {
                            volume = quantity
                            showPortion = true
                        } else {
                            // Handle error: quantity cannot be converted into a number
                            print("Quantity cannot be converted into a number")
                            showAlert = true
                        }
                    } else {
                        // Handle error: serving size does not contain at least two components
                        let pattern = "(\\d)(\\D)"
                        if let regex = try? NSRegularExpression(pattern: pattern) {
                            let modifiedString = regex.stringByReplacingMatches(in: servingSize, options: [], range: NSRange(location: 0, length: servingSize.count), withTemplate: "$1 $2")
                            components = modifiedString.components(separatedBy: " ")
                            if let quantityString = components.first, let quantity = Float(quantityString) {
                                volume = quantity
                                showPortion = true
                            } else {
                                // Handle error: quantity cannot be converted into a number
                                print("Quantity cannot be converted into a number")
                                showAlert = true
                            }
                        } else {
                            // Handle error: serving size can not be separated in quantity and unit
                            print("Serving size can not be separated in quantity and unit")
                            showAlert = true
                        }
                    }
                } else {
                    // Handle error: serving size is nil
                    print("Serving size is nil")
                    showAlert = true
                }
            } label: {
                Image(systemName: "mug")
                Text("See your portion in AR")
            }
        }
        .padding(.vertical, 80)
        .navigationDestination(isPresented: $showPortion) {
            ARPortionView(volume: $volume, nutritionFacts: $nutritionFacts)
        }
        .alert("Re-scan the label, the data is not clear", isPresented: $showAlert, actions: {})
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if (self.imageTaken == nil) {
                    ARCameraView(image: self.$imageTaken) {
                        self.imageTaken = nil
                    }
                } else {
                    if (!self.isLoading) {
                        self.pictureTakenView
                            .onAppear {
                                self.recognizeAndParseText()
                            }
                    }
                    else {
                        ProgressView()
                    }
                }
            }
            .edgesIgnoringSafeArea(.all)
        }
    }
}
