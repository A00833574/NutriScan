//
//  ARPortionView.swift
//  NutriScan
//
//  Created by Gabriel Diaz Roa on 07/02/24.
//

import SwiftUI
import ARKit
import RealityKit

struct ARPortionView: View {
    @Binding var volume: Float
    @State private var showModal = true
    @State private var showConclussion = false
    @Binding var nutritionFacts : [String: String]
    var body: some View {
        GeometryReader { geo in
            ZStack{
                ARPortionViewContainer(volume: $volume).edgesIgnoringSafeArea(.all)
                SlideOverView {
                    GeometryReader { geo in
                        VStack {
                            Text("Nutrition Facts: ")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            List {
                                ForEach(self.nutritionFacts.keys.sorted(), id: \.self) { key in
                                    Text("\(key): \(self.nutritionFacts[key]!)")
                                }
                            }
                            .frame(maxHeight: geo.size.height/2)
                            Button(action: {
                                showConclussion = true
                            }, label: {
                                Text("Continue")
                            })
                            .buttonStyle(.borderedProminent)
                            .padding(.top, 10)
                            Spacer()
                        }
                    }
                }
                if showModal {
                    Rectangle()
                        .fill(Color.black.opacity(0.5))
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            self.showModal = false
                        }
                    VStack {
                        Image(systemName: "hand.tap.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: geo.size.width/3)
                        Text("Tap in a flat surface to place your portion")
                            .multilineTextAlignment(.center)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showConclussion, content: {
            ConclussionView()
        })
    }
}

struct ARPortionViewContainer: UIViewRepresentable {
    @Binding var volume: Float
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // Add a tap gesture recognizer to the ARView
        let tapGestureRecognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGestureRecognizer)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    // Define the coordinator class
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: ARPortionViewContainer
        
        init(_ parent: ARPortionViewContainer) {
            self.parent = parent
        }
        
        @objc func handleTap(_ sender: UITapGestureRecognizer) {
            guard let arView = sender.view as? ARView else { return }
            let location = sender.location(in: arView)
            
            if let result = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .horizontal).first {
                // Remove all existing anchors from the scene
                arView.scene.anchors.removeAll()
                let cubeSize: Float = 0.01  // Cube size
                let initialHeight: Float = 0.5  // Initial height for the first cube
                let rainbowColors: [UIColor] = [ // Define the rainbow colors
                    .red, .orange, .yellow, .green, .blue, .purple, .systemIndigo
                ]
                
                for i in 0..<Int(parent.volume) {
                    var startPosition = result.worldTransform
                    startPosition.columns.3.y += initialHeight + Float(i) * cubeSize
                    
                    // Interpolate color based on the cube's index
                    let colorIndex = CGFloat(i) / CGFloat(parent.volume - 1) * CGFloat(rainbowColors.count - 1)
                    let startIndex = Int(colorIndex)
                    let endIndex = min(startIndex + 1, rainbowColors.count - 1)
                    let t = colorIndex - CGFloat(startIndex)
                    let startColor = rainbowColors[startIndex].cgColor.components!
                    let endColor = rainbowColors[endIndex].cgColor.components!
                    let interpolatedColor = UIColor(
                        red: startColor[0] + (endColor[0] - startColor[0]) * t,
                        green: startColor[1] + (endColor[1] - startColor[1]) * t,
                        blue: startColor[2] + (endColor[2] - startColor[2]) * t,
                        alpha: 1
                    )
                    
                    // Create the cube
                    let mesh = MeshResource.generateBox(size: cubeSize)
                    let material = SimpleMaterial(color: interpolatedColor, roughness: 0.15, isMetallic: false)
                    let cube = ModelEntity(mesh: mesh, materials: [material])
                    
                    // Create the text label
                    let textMesh = MeshResource.generateText(
                        "1gr",
                        extrusionDepth: 0.01,
                        font: .systemFont(ofSize: 0.05),
                        containerFrame: .zero,
                        alignment: .center,
                        lineBreakMode: .byTruncatingTail
                    )
                    let textMaterial = SimpleMaterial(color: .white, isMetallic: false)
                    let textEntity = ModelEntity(mesh: textMesh, materials: [textMaterial])
                    textEntity.scale = SIMD3<Float>(0.1, 0.1, 0.1)  // Scale down the text size
                    textEntity.position = SIMD3<Float>(-cubeSize/3, -cubeSize/3, cubeSize/2)  // Position above the cube
                    
                    // Create an anchor and add the cube and text to it
                    let anchor = AnchorEntity(world: startPosition)
                    anchor.addChild(cube)
                    cube.addChild(textEntity)
                    arView.scene.addAnchor(anchor)
                    
                    // Animate the cube (and its text label) falling to its final position
                    var finalPosition = startPosition
                    finalPosition.columns.3.y = result.worldTransform.columns.3.y + Float(i) * cubeSize
                    let finalTransform = Transform(matrix: finalPosition)
                    // Animate each cube falling with a slight delay for each to create a cascading effect
                    let delay = TimeInterval(i) * 0.2  // Adjust delay as needed
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        anchor.move(to: finalTransform, relativeTo: anchor.parent, duration: 0.25, timingFunction: .linear)
                    }
                }
            }
        }
        
    }
}

struct SlideOverView<Content> : View where Content : View {
    
    var content: () -> Content
    
    public init(content: @escaping () -> Content) {
        self.content = content
    }
    
    public var body: some View {
        ModifiedContent(content: self.content(), modifier: CardView())
    }
}


struct CardView: ViewModifier {
    @State private var dragging = false
    @GestureState private var dragTracker: CGSize = CGSize.zero
    @State private var position: CGFloat = UIScreen.main.bounds.height - 150
    
    func body(content: Content) -> some View {
        withAnimation(dragging ? nil : {
            Animation.interpolatingSpring(stiffness: 250.0, damping: 40.0, initialVelocity: 5.0)
        }()) {
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 2.5)
                    .frame(width: 40, height: 5.0)
                    .foregroundColor(Color.secondary)
                    .padding(10)
                content.padding(.top, 30)
            }
            .frame(minWidth: UIScreen.main.bounds.width)
            .scaleEffect(x: 1, y: 1, anchor: .center)
            .background()
            .cornerRadius(15)
            .shadow(radius: 25)
            .offset(y:  max(0, position + self.dragTracker.height))
            .gesture(DragGesture()
                .updating($dragTracker) { drag, state, transaction in state = drag.translation }
                .onChanged {_ in  dragging = true }
                .onEnded(onDragEnded))
        }
    }
    
    private func onDragEnded(drag: DragGesture.Value) {
        dragging = false
        let low = UIScreen.main.bounds.height - 150
        let high: CGFloat = 200
        let dragDirection = drag.predictedEndLocation.y - drag.location.y
        //can also calculate drag offset to make it more rigid to shrink and expand
        if dragDirection > 0 {
            position = low
        } else {
            position = high
        }
    }
}

struct SlideOverView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

