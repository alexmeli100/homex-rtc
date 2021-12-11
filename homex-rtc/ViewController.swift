//
//  ViewController.swift
//  homex-rtc
//
//  Created by Alex Meli on 2021-12-10.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    var swiped = false
    var lastPosition: SCNVector3?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
        UIApplication.shared.isIdleTimerDisabled = false
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let currentTouchPoint = touches.first?.location(in: self.sceneView),
              let featurePointHitTest = self.sceneView.hitTest(currentTouchPoint, types: .featurePoint).first else { return }

        //3. Get The World Coordinates
        let worldCoordinates = featurePointHitTest.worldTransform
        lastPosition = SCNVector3(worldCoordinates.columns.3.x, worldCoordinates.columns.3.y, worldCoordinates.columns.3.z)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let currentTouchPoint = touches.first?.location(in: sceneView),
              let featurePointHitTest = sceneView.hitTest(currentTouchPoint, types: .featurePoint).first else { return }

        //3. Get The World Coordinates
        let worldCoordinates = featurePointHitTest.worldTransform

        //4. Create An SCNNode With An SCNSphere Geeomtery
        let sphereNode = SCNNode()
        let sphereNodeGeometry = SCNSphere(radius: 0.003)
//
//        //5. Generate A Random Colour For The Node's Geometry
        let colour = UIColor.green
        sphereNodeGeometry.firstMaterial?.diffuse.contents = colour
        sphereNode.geometry = sphereNodeGeometry
        sphereNode.position = SCNVector3(worldCoordinates.columns.3.x,  worldCoordinates.columns.3.y,  worldCoordinates.columns.3.z)


        //6. Position & Add It To The Scene Hierachy
        guard let lastPos = lastPosition else { return }
        //let currPosition = SCNVector3(worldCoordinates.columns.3.x,  worldCoordinates.columns.3.y,  worldCoordinates.columns.3.z)
        sceneView.scene.rootNode.addChildNode(sphereNode)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastPosition = nil

    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}

extension SCNGeometry {
    class func line(from vector1: SCNVector3, to vector2: SCNVector3) -> SCNGeometry {
        let indices: [Int32] = [0, 1]
        let source = SCNGeometrySource(vertices: [vector1, vector2])
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        return SCNGeometry(sources: [source], elements: [element])
    }
}
