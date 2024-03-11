//
//  ARCameraView.swift
//  NutriScan
//
//  Created by Gabriel Diaz Roa on 04/02/24.
//

import SwiftUI
import RealityKit
import ARKit

struct ARCameraView : View {
    @Binding var image : UIImage?
    @State var NF_Image: UIImage? = UIImage(named: "NF_SweetT")
    @State var showModal = true
    @State private var distance : Float = 0.0
    var onDismiss: () -> Void
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom){
                ARCameraViewContainer(NF_Image: $NF_Image, distance: $distance).ignoresSafeArea(.all)
                VStack {
                    HStack(spacing: 5){
                        Button {
                            NF_Image = UIImage(named: "NF_SweetT")
                        } label: {
                            if NF_Image == UIImage(named: "NF_SweetT"){
                                Image("SweetTarts")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width:80, height:40)
                                    .background(.white)
                                    .cornerRadius(10)
                            } else {
                                Image("SweetTarts")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width:80, height:40)
                                    .background(.white.opacity(0.5))
                                    .cornerRadius(10)
                            }
                        }
                        Button {
                            NF_Image = UIImage(named: "NF_FiberOne")
                        } label: {
                            if NF_Image == UIImage(named: "NF_FiberOne") {
                                Image("FiberOne")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width:80, height:40)
                                    .background(.white)
                                    .cornerRadius(10)
                            } else {
                                Image("FiberOne")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width:80, height:40)
                                    .background(.white.opacity(0.5))
                                    .cornerRadius(10)
                            }
                        }
                    }
                    Button {
                        ARVariables.arView.snapshot(saveToHDR: false) { snapshot in
                            let compressedImage = UIImage(data: (snapshot?.pngData())!)
                            image = compressedImage
                        }
                    } label: {
                        Image(systemName: "camera")
                            .frame(width:60, height:60)
                            .font(.title)
                            .background(.white.opacity(0.75))
                            .cornerRadius(30)
                            .padding()
                    }
                }
                .padding()
                if showModal {
                    Rectangle()
                        .fill(Color.black.opacity(0.5))
                        .ignoresSafeArea(.all)
                        .onTapGesture {
                            self.showModal = false
                        }
                    VStack {
                        Text("Point towards a flat surface")
                            .multilineTextAlignment(.center)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("An AR object should appear")
                            .font(.footnote)
                            .foregroundColor(.white)
                        Text("(Tap to dismiss)")
                            .font(.footnote)
                            .foregroundColor(.white)
                    }
                    .position(x:geo.size.width/2 ,y:geo.size.height/2)
                } else {
                    if distance < 10 {
                        Rectangle()
                            .fill(Color.black.opacity(0.5))
                            .ignoresSafeArea(.all)
                        VStack {
                            Text("Move back please")
                                .multilineTextAlignment(.center)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Text("Distance: \(String(format: "%.2f", distance)) cm")
                                .font(.footnote)
                                .foregroundColor(.white)
                        }
                        .position(x:geo.size.width/2 ,y:geo.size.height/2)
                    }
                }
            }
        }
    }
}


struct ARVariables{
    static var arView: ARView!
    static var NF_Image: UIImage!
}

struct ARCameraViewContainer: UIViewRepresentable {
    @Binding var NF_Image: UIImage?
    @Binding var distance : Float
    
    func makeUIView(context: Context) -> ARView {
        ARVariables.arView = ARView(frame: .zero)
        
        ARVariables.arView.session.delegate = context.coordinator
        
        updateUIView(ARVariables.arView, context: context)
        return ARVariables.arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // Clear all anchors
        uiView.scene.anchors.removeAll()
        
        // Create a plane model with the nutrition facts image
        let mesh = MeshResource.generatePlane(width: 0.3, height: 0.5)
        var material = UnlitMaterial()
        if let cgImage = NF_Image?.cgImage {
            let texture = try! TextureResource.generate(from: cgImage, options: .init(semantic: .normal))
            material.color = .init(texture: .init(texture))
        } else {
            material.color.tint = .blue
        }
        let model = ModelEntity(mesh: mesh, materials: [material])
        
        // Create horizontal plane anchor for the content
        let anchor = AnchorEntity(.plane(.horizontal, classification: .table, minimumBounds: SIMD2<Float>(0.2, 0.2)))
        anchor.children.append(model)
        
        // Add the horizontal plane anchor to the scene
        uiView.scene.anchors.append(anchor)
    }
    
    func makeCoordinator() -> ARSessionDelegateCoordinator {
        return ARSessionDelegateCoordinator(distance: $distance)
    }
}

class ARSessionDelegateCoordinator : NSObject, ARSessionDelegate {
    @Binding var distance : Float
    init(distance: Binding<Float>) {
        _distance = distance
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard let currentPointCloud = frame.rawFeaturePoints else {return}
        let cameraTransform = frame.camera.transform
        
        var closestDistance : Float = Float.greatestFiniteMagnitude
        
        for point in currentPointCloud.points {
            let pointInCameraSpace = cameraTransform.inverse*simd_float4(point,1)
            let distanceToCamera = sqrt(pointInCameraSpace.x*pointInCameraSpace.x+pointInCameraSpace.y*pointInCameraSpace.y+pointInCameraSpace.z*pointInCameraSpace.z)
            
            if distanceToCamera < closestDistance {
                closestDistance = distanceToCamera
            }
        }
        
        distance = closestDistance * 100
    }
}
