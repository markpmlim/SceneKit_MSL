//
//  ViewController.swift
//  MetalTexture2
//
//  Created by Mark Lim Pak Mun on 30/06/2019.
//  Copyright © 2019 Incremental Innovation. All rights reserved.
//

import Cocoa
import SceneKit
import MetalKit

class ViewController: NSViewController, SCNSceneRendererDelegate, SCNProgramDelegate {

    var scnView: SCNView {
        return self.view as! SCNView
    }

    var device: MTLDevice!
    var fadeFactor: Float = 0
    var fadeFactorDelta: Float = 0.05
    var resolution = float2(0, 0)
    var startTime = CFAbsoluteTimeGetCurrent()
    var time: Float = 0
    var isWindowResized = false

    override func viewDidLoad() {
        super.viewDidLoad()
        device = MTLCreateSystemDefaultDevice()
        scnView.allowsCameraControl = true
        scnView.showsStatistics = true
        scnView.delegate = self
        scnView.backgroundColor = NSColor.lightGray
        scnView.scene = buildScene()
        let nc = NotificationCenter.default
        nc.addObserver(self,
                       selector: #selector(self.windowDidResize),
                       name: .NSWindowDidResize,
                       object: nil)
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }

    func windowDidResize() {
        isWindowResized = true
    }

    func buildScene() -> SCNScene {

        let program = SCNProgram()
        // The vertex and fragment MTLFunctions must be called
        // through the vertexFunctionName & fragmentFunctionName properties.
        // SceneKit will take care of the details.
        program.vertexFunctionName = "vertex_function"
        program.fragmentFunctionName = "fragment_function"

        // Bind the name of the fragment function parameters to the program.
        program.handleBinding(ofBufferNamed: "resolution",
                              frequency: .perFrame,
                              handler: {
            (buffer: SCNBufferStream, node: SCNNode, shadable: SCNShadable, renderer: SCNRenderer) -> Void in
            buffer.writeBytes(&self.resolution,
                              count: MemoryLayout<float2>.stride)
        })

        program.handleBinding(ofBufferNamed: "time",
                              frequency: .perNode,
                              handler: {
            (buffer: SCNBufferStream, node: SCNNode, shadable: SCNShadable, renderer: SCNRenderer) -> Void in
            buffer.writeBytes(&self.time,
                              count: MemoryLayout<Float>.stride)
        })

        program.handleBinding(ofBufferNamed: "fadeFactor",
                              frequency: .perNode,
                              handler: {
            (buffer: SCNBufferStream, node: SCNNode, shadable: SCNShadable, renderer: SCNRenderer) -> Void in
            self.fadeFactor = max(0, min(1, self.fadeFactor + self.fadeFactorDelta))
            buffer.writeBytes(&self.fadeFactor,
                              count: MemoryLayout<Float>.stride)
        })

        let geometry = SCNPlane(width: 10, height: 10)
        let geometryNode = SCNNode(geometry: geometry)

        // Alternative: use geometry.firstMaterial?.program
        geometryNode.geometry?.firstMaterial?.program = program
        geometryNode.geometry?.firstMaterial?.lightingModel = .constant
        geometryNode.geometry?.firstMaterial?.isDoubleSided = true

        let scene = SCNScene()
        scene.rootNode.addChildNode(geometryNode)

        return scene
    }

    override func keyDown(with event: NSEvent) {
        let chars = event.characters!.uppercased()
        switch chars {
        case "F":
            fadeFactorDelta *= -1       // fade out
        default:
            print("keyDown: \(event.characters!) keyCode: \(event.keyCode)")
        }
    }


    deinit {
        let nc = NotificationCenter.default
        nc.removeObserver(self,
                          name: .NSWindowDidResize,
                          object: nil)
    }


    // Implementation of an SCNSceneRendererDelegate method
    func renderer(_ renderer: SCNSceneRenderer,
                  willRenderScene scene: SCNScene,
                  atTime time: TimeInterval) {
        self.time = Float(CFAbsoluteTimeGetCurrent() - startTime)
        if isWindowResized {
            // The SCNSceneRenderer class in macOS 10.15 has a property  "currentViewPort"
            self.resolution = float2(Float(scnView.frame.width), Float(scnView.frame.height))
            isWindowResized = false
        }
    }

    // Implementation of SCNProgramDelegate
    func program(_ program: SCNProgram, handleError error: Error) {
        Swift.print(error)
    }
    
}
