//
//  ViewController.swift
//  InterpolatedColour
//
//  Created by Mark Lim Pak Mun on 31/03/2019.
//  Copyright © 2019 Incremental Innovation. All rights reserved.

import Cocoa
import SceneKit
import MetalKit

class ViewController: NSViewController, SCNSceneRendererDelegate {

    var scnView: SCNView {
        return self.view as! SCNView
    }
    var textureLayer: UInt32 = 1
    let nodeName = "textured plane"
    // Names of the input parameters to the fragment function.
    let bufferName = "layer"
    let textureBufferName = "diffuseTexture"

    var device: MTLDevice!
    var arrayTexture: MTLTexture!

    override func viewDidLoad() {
        super.viewDidLoad()
        device = MTLCreateSystemDefaultDevice()
        arrayTexture = loadTexture(device: device)

        scnView.scene = buildScene()
        scnView.allowsCameraControl = true
        scnView.showsStatistics = true
        scnView.delegate = self
        scnView.backgroundColor = NSColor.lightGray
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }

    // Instantiate a texture object; the ktx file contains a texture2d array.
    func loadTexture(device: MTLDevice) -> MTLTexture {
        // Instantiate a texture descriptor with the appropriate properties.
        let url = Bundle.main.url(forResource: "DiffuseArray",
                                  withExtension: "ktx")!
        let textureLoader = MTKTextureLoader(device: self.device)
        var textureIn: MTLTexture!
        do {
            textureIn = try textureLoader.newTexture(withContentsOf: url,
                                                     options: [:])
        }
        catch let error {
            print("Error \(error) loading texture")
        }

        return textureIn
    }

    func buildScene() -> SCNScene {

        let geometry = SCNPlane(width:10, height:10)
        let geometryNode = SCNNode(geometry: geometry)
        geometryNode.name = nodeName

        let program = SCNProgram()
        program.vertexFunctionName = "vertex_function"
        program.fragmentFunctionName = "fragment_function"

        let imageProperty = SCNMaterialProperty(contents: arrayTexture)
        geometryNode.geometry?.firstMaterial?.specular.contents = NSColor.white // these 3 statements ...
        geometryNode.geometry?.firstMaterial?.locksAmbientWithDiffuse = true
        geometryNode.geometry?.firstMaterial?.lightingModel = .constant         // ... are not necessary
        geometryNode.geometry?.firstMaterial?.isDoubleSided = true

        geometryNode.geometry?.firstMaterial?.program = program
        // The Metal SCNProgram method handleBinding(ofBufferNamed:frequency:handler:)
        // is not used since the custom data is passed once.
        geometryNode.geometry?.firstMaterial?.setValue(imageProperty,
                                                       forKey: textureBufferName)
        // Encapsulate the layer number in an instance of Data ...
        let layerData = Data(bytes: &textureLayer, count: MemoryLayout<UInt32>.stride)
        // ... and pass it to the fragment function.
        // The method setValue:forKey: works in Metal but not in OpenGL
        geometryNode.geometry?.firstMaterial?.setValue(layerData,
                                                       forKey: bufferName)
        let scene = SCNScene()

        scene.rootNode.addChildNode(geometryNode)
        return scene
    }

    override func keyDown(with event: NSEvent) {
        var textureChanged: Bool = true

        switch (event.characters!) {
        case "0":
            textureLayer = 0
        case "1":
            textureLayer = 1
        case "2":
            textureLayer = 2
        case "3":
            textureLayer = 3
        default:
            textureChanged = false
            break
        }
        if textureChanged {
            guard let scene = scnView.scene
            else {
                return
            }
            let childNodes = scene.rootNode.childNodes(passingTest: {
                (child: SCNNode, stop: UnsafeMutablePointer<ObjCBool>)-> Bool in
                if child.name == nodeName {
                    return true
                }
                else {
                    return false
                }
            })
            let layerData = Data(bytes: &textureLayer, count: MemoryLayout<UInt32>.stride)
            for (_, child) in childNodes.enumerated() {
                child.geometry?.firstMaterial?.setValue(layerData,
                                                        forKey: bufferName)
            }
        }
    }
}
