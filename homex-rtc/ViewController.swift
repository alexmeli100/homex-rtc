//
//  ViewController.swift
//  homex-rtc
//
//  Created by Alex Meli on 2021-12-10.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController {

    @IBOutlet var sceneView: ARSCNView!
    var colorPickerButton: UIButton!
    var clearButtonBackground: UIVisualEffectView!
    var undoButtonBackground: UIVisualEffectView!
    var clearButton: UIButton!
    var undoButton: UIButton!
    var buttonStackView: UIStackView!
    var colorPickerViewController: UIColorPickerViewController!
    var currentColor = UIColor.systemGreen

    var previousPoint: SCNVector3?
    var currentFingerPosition: CGPoint?
    var screenShotOverlayImageView: UIImageView?
    var strokeAnchorIDs: [UUID] = []
    var currentStrokeAnchorNode: SCNNode?
    let sphereNodesManager = SphereNodesManager()

    private func createSphereAndInsert(atPositions positions: [SCNVector3], andAddToStrokeAnchor strokeAnchor: StrokeAnchor) {
        for position in positions {
            createSphereAndInsert(atPosition: position, andAddToStrokeAnchor: strokeAnchor)
        }
    }

    private func createSphereAndInsert(atPosition position: SCNVector3, andAddToStrokeAnchor strokeAnchor: StrokeAnchor) {
        guard let currentStrokeNode = currentStrokeAnchorNode else {
            return
        }
        // Get the reference sphere node and clone it
        let referenceSphereNode = sphereNodesManager.getReferenceSphereNode(forStrokeColor: strokeAnchor.color)
        let newSphereNode = referenceSphereNode.clone()
        // Convert the position from world transform to local transform (relative to the anchors default node)
        let localPosition = currentStrokeNode.convertPosition(position, from: nil)
        newSphereNode.position = localPosition
        // Add the node to the default node of the anchor
        currentStrokeNode.addChildNode(newSphereNode)
        // Add the position of the node to the stroke anchors sphereLocations array (Used for saving/loading the world map)
        strokeAnchor.sphereLocations.append([newSphereNode.position.x, newSphereNode.position.y, newSphereNode.position.z])
    }

    private func anchorForID(_ anchorID: UUID) -> StrokeAnchor? {
        return sceneView.session.currentFrame?.anchors.first(where: { $0.identifier == anchorID }) as? StrokeAnchor
    }

    private func sortStrokeAnchorIDsInOrderOfDateCreated() {
        var strokeAnchorsArray: [StrokeAnchor] = []
        for anchorID in strokeAnchorIDs {
            if let strokeAnchor = anchorForID(anchorID) {
                strokeAnchorsArray.append(strokeAnchor)
            }
        }
        strokeAnchorsArray.sort(by: { $0.dateCreated < $1.dateCreated })

        strokeAnchorIDs = []
        for anchor in strokeAnchorsArray {
            strokeAnchorIDs.append(anchor.identifier)
        }
    }
    
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
        sceneView.session.delegate = self

        UIApplication.shared.isIdleTimerDisabled = true
        
        colorPickerViewController = UIColorPickerViewController()
        colorPickerViewController.delegate = self
        
        undoButtonBackground = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))
        undoButtonBackground.translatesAutoresizingMaskIntoConstraints = false
        undoButtonBackground.clipsToBounds = true
        undoButtonBackground.layer.cornerRadius = 20
        
        clearButtonBackground = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))
        clearButtonBackground.translatesAutoresizingMaskIntoConstraints = false
        clearButtonBackground.layer.cornerRadius = 20
        clearButtonBackground.clipsToBounds = true
        
        undoButton = UIButton()
        undoButton.setImage(UIImage(systemName: "arrow.uturn.left", withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .regular, scale: .default)), for: .normal)
        undoButton.tintColor = .white
        undoButton.translatesAutoresizingMaskIntoConstraints = false
        undoButton.addTarget(self, action: #selector(undoButtonPressed), for: .touchUpInside)
        undoButtonBackground.contentView.addSubview(undoButton)
        
        clearButton = UIButton()
        clearButton.setImage(UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .regular, scale: .default)), for: .normal)
        clearButton.tintColor = .white
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        clearButton.addTarget(self, action: #selector(clearButtonPressed), for: .touchUpInside)
        clearButtonBackground.contentView.addSubview(clearButton)
        
        colorPickerButton = UIButton()
        colorPickerButton.setImage(UIImage(systemName: "paintbrush.pointed", withConfiguration: UIImage.SymbolConfiguration(pointSize: 25, weight: .regular, scale: .default)), for: .normal)
        colorPickerButton.backgroundColor = currentColor
        colorPickerButton.tintColor = .white
        colorPickerButton.layer.cornerRadius = 35
        colorPickerButton.translatesAutoresizingMaskIntoConstraints = false
        colorPickerButton.addTarget(self, action: #selector(presentColorPicker), for: .touchUpInside)
        view.addSubview(colorPickerButton)
        
        buttonStackView = UIStackView(arrangedSubviews: [undoButtonBackground, clearButtonBackground])
        buttonStackView.axis = .vertical
        buttonStackView.spacing = 10
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonStackView)
        
        
        NSLayoutConstraint.activate([
            colorPickerButton.heightAnchor.constraint(equalToConstant: 70),
            colorPickerButton.widthAnchor.constraint(equalToConstant: 70),
            colorPickerButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -15),
            colorPickerButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -35),
            
            clearButtonBackground.heightAnchor.constraint(equalToConstant: 40),
            clearButtonBackground.widthAnchor.constraint(equalToConstant: 40),
            
            clearButton.heightAnchor.constraint(equalToConstant: 25),
            clearButton.widthAnchor.constraint(equalToConstant: 25),
            clearButton.centerXAnchor.constraint(equalTo: clearButtonBackground.centerXAnchor),
            clearButton.centerYAnchor.constraint(equalTo: clearButtonBackground.centerYAnchor),
            
            undoButtonBackground.heightAnchor.constraint(equalToConstant: 40),
            undoButtonBackground.widthAnchor.constraint(equalToConstant: 40),
            
            undoButton.heightAnchor.constraint(equalToConstant: 25),
            undoButton.widthAnchor.constraint(equalToConstant: 25),
            undoButton.centerXAnchor.constraint(equalTo: undoButtonBackground.centerXAnchor),
            undoButton.centerYAnchor.constraint(equalTo: undoButtonBackground.centerYAnchor),
            
            buttonStackView.centerXAnchor.constraint(equalTo: colorPickerButton.centerXAnchor),
            buttonStackView.bottomAnchor.constraint(equalTo: colorPickerButton.topAnchor, constant: -15)
        ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        colorPickerButton.layer.shadowColor = UIColor.black.cgColor
        colorPickerButton.layer.shadowOffset = CGSize(width: 3, height: 4)
        colorPickerButton.layer.shadowRadius = 6
        colorPickerButton.layer.shadowOpacity = 0.2
        colorPickerButton.layer.shadowPath = UIBezierPath(roundedRect: colorPickerButton.bounds, cornerRadius: 35).cgPath
        colorPickerButton.layer.masksToBounds = false
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
//    override func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
//        // Remove the anchorID from the strokes array
//        print("Anchor removed")
//        strokeAnchorIDs.removeAll(where: { $0 == anchor.identifier })
//    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Create a StrokeAnchor and add it to the Scene (One Anchor will be added to the exaction position of the first sphere for every new stroke)
        guard let touch = touches.first else { return }
        guard let touchPositionInFrontOfCamera = getPosition(ofPoint: touch.location(in: sceneView), atDistanceFromCamera: 0.2, inView: sceneView) else { return }
        // Convert the position from SCNVector3 to float4x4
        let strokeAnchor = StrokeAnchor(name: "strokeAnchor", transform: float4x4(float4(1, 0, 0, 0),
                float4(0, 1, 0, 0),
                float4(0, 0, 1, 0),
                float4(touchPositionInFrontOfCamera.x,
                        touchPositionInFrontOfCamera.y,
                        touchPositionInFrontOfCamera.z,
                        1)))
        strokeAnchor.color = currentColor
        sceneView.session.add(anchor: strokeAnchor)
        currentFingerPosition = touch.location(in: sceneView)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        currentFingerPosition = touch.location(in: sceneView)
        //print(currentFingerPosition.debugDescription)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        previousPoint = nil
        currentStrokeAnchorNode = nil
        currentFingerPosition = nil
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        previousPoint = nil
        currentStrokeAnchorNode = nil
        currentFingerPosition = nil
    }

    
    @objc private func presentColorPicker() {
        present(colorPickerViewController, animated: true, completion: nil)
    }
    
    @objc private func undoButtonPressed() {
        playHapticFeeback()
        
        // Add code for undo here
    }
    
    @objc private func clearButtonPressed() {
        playHapticFeeback()
        
        // Add code for clear here
    }
    
    private func playHapticFeeback() {
        let selectorFeedbackGenerator = UISelectionFeedbackGenerator()
        selectorFeedbackGenerator.prepare()
        selectorFeedbackGenerator.selectionChanged()
    }
}

extension ViewController: ARSCNViewDelegate {

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // This is only used when loading a worldMap
        if let strokeAnchor = anchor as? StrokeAnchor {
            currentStrokeAnchorNode = node
            strokeAnchorIDs.append(strokeAnchor.identifier)
            for sphereLocation in strokeAnchor.sphereLocations {
                createSphereAndInsert(atPosition: SCNVector3Make(sphereLocation[0], sphereLocation[1], sphereLocation[2]), andAddToStrokeAnchor: strokeAnchor)
            }
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        // Remove the anchorID from the strokes array
        print("Anchor removed")
        strokeAnchorIDs.removeAll(where: { $0 == anchor.identifier })
    }
}

extension ViewController: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Draw the spheres
        guard let currentStrokeAnchorID = strokeAnchorIDs.last else { return }
        let currentStrokeAnchor = anchorForID(currentStrokeAnchorID)
        if currentFingerPosition != nil && currentStrokeAnchor != nil {
            guard let currentPointPosition = getPosition(ofPoint: currentFingerPosition!, atDistanceFromCamera: 0.2, inView: sceneView) else { return }

            if let previousPoint = previousPoint {
                // Do not create any new spheres if the distance hasn't changed much
                let distance = abs(previousPoint.distance(vector: currentPointPosition))
                if distance > 0.00104 {
                    createSphereAndInsert(atPosition: currentPointPosition, andAddToStrokeAnchor: currentStrokeAnchor!)
                    // Draw spheres between the currentPoint and previous point if they are further than the specified distance (Otherwise fast movement will make the line blocky)
                    // TODO: The spacing should depend on the brush size
                    let positions = getPositionsOnLineBetween(point1: previousPoint, andPoint2: currentPointPosition, withSpacing: 0.001)
                    createSphereAndInsert(atPositions: positions, andAddToStrokeAnchor: currentStrokeAnchor!)
                    self.previousPoint = currentPointPosition
                }
            } else {
                createSphereAndInsert(atPosition: currentPointPosition, andAddToStrokeAnchor: currentStrokeAnchor!)
                previousPoint = currentPointPosition
            }
        }
    }
}

extension ViewController: UIColorPickerViewControllerDelegate {
    func colorPickerViewController(_ viewController: UIColorPickerViewController, didSelect color: UIColor, continuously: Bool) {
        currentColor = color
        colorPickerButton.backgroundColor = color
        colorPickerViewController.dismiss(animated: true, completion: nil)
    }
}

func getCameraPosition(in view: ARSCNView) -> SCNVector3? {
    guard let lastFrame = view.session.currentFrame else {
        return nil
    }
    let position = lastFrame.camera.transform * float4(x: 0, y: 0, z: 0, w: 1)
    let camera: SCNVector3 = SCNVector3(position.x, position.y, position.z)

    return camera
}

// Gets the real world position of the touch point at x distance away from the camera
func getPosition(ofPoint point: CGPoint,
                 atDistanceFromCamera distance: Float,
                 inView view: ARSCNView) -> SCNVector3? {
    guard let cameraPosition = getCameraPosition(in: view) else {
        return nil
    }
    let directionOfPoint = getDirection(for: point, in: view).normalized()
    return (directionOfPoint * distance) + cameraPosition
}

// Takes the coordinates of the 2D point and converts it to a vector in the real world
func getDirection(for point: CGPoint, in view: SCNView) -> SCNVector3 {
    let farPoint  = view.unprojectPoint(SCNVector3Make(Float(point.x), Float(point.y), 1))
    let nearPoint = view.unprojectPoint(SCNVector3Make(Float(point.x), Float(point.y), 0))

    return SCNVector3Make(farPoint.x - nearPoint.x, farPoint.y - nearPoint.y, farPoint.z - nearPoint.z)
}

// Gets the positions of the points on the line between point1 and point2 with the given spacing
func getPositionsOnLineBetween(point1: SCNVector3,
                               andPoint2 point2: SCNVector3,
                               withSpacing spacing: Float) -> [SCNVector3] {
    var positions: [SCNVector3] = []
    // Calculate the distance between previous point and current point
    let distance = point1.distance(vector: point2)
    let numberOfCirclesToCreate = Int(distance / spacing)

    // https://math.stackexchange.com/a/83419
    // Begin by creating a vector BA by subtracting A from B (A = previousPoint, B = currentPoint)
    let vectorBA = point2 - point1
    // Normalize vector BA by dividng it by it's length
    let vectorBANormalized = vectorBA.normalized()
    // This new vector can now be scaled and added to A to find the point at the specified distance
    for i in 0...((numberOfCirclesToCreate > 1) ? (numberOfCirclesToCreate - 1) : numberOfCirclesToCreate) {
        let position = point1 + (vectorBANormalized * (Float(i) * spacing))
        positions.append(position)
    }
    return positions
}

extension SCNVector3
{
    /**
     * Negates the vector described by SCNVector3 and returns
     * the result as a new SCNVector3.
     */
    func negate() -> SCNVector3 {
        return self * -1
    }

    /**
     * Negates the vector described by SCNVector3
     */
    mutating func negated() -> SCNVector3 {
        self = negate()
        return self
    }

    /**
     * Returns the length (magnitude) of the vector described by the SCNVector3
     */
    func length() -> Float {
        return sqrtf(x*x + y*y + z*z)
    }

    /**
     * Normalizes the vector described by the SCNVector3 to length 1.0 and returns
     * the result as a new SCNVector3.
     */
    func normalized() -> SCNVector3 {
        return self / length()
    }

    /**
     * Normalizes the vector described by the SCNVector3 to length 1.0.
     */
    mutating func normalize() -> SCNVector3 {
        self = normalized()
        return self
    }

    /**
     * Calculates the distance between two SCNVector3. Pythagoras!
     */
    func distance(vector: SCNVector3) -> Float {
        return (self - vector).length()
    }

    /**
     * Calculates the dot product between two SCNVector3.
     */
    func dot(vector: SCNVector3) -> Float {
        return x * vector.x + y * vector.y + z * vector.z
    }

    /**
     * Calculates the cross product between two SCNVector3.
     */
    func cross(vector: SCNVector3) -> SCNVector3 {
        return SCNVector3Make(y * vector.z - z * vector.y, z * vector.x - x * vector.z, x * vector.y - y * vector.x)
    }

    // MARK: These two methods were added from SCNVector3+MathUtils.swift

    /// Calculate the magnitude of this vector
    var magnitude:SCNFloat {
        get {
            return sqrt(dot(vector: self))
        }
    }

    /**
     Calculate the angle between two vectors

     - parameter vectorB: Other vector in the calculation
     */
    func angleBetweenVectors(_ vectorB:SCNVector3) -> SCNFloat {

        //cos(angle) = (A.B)/(|A||B|)
        let cosineAngle = (dot(vector: vectorB) / (magnitude * vectorB.magnitude))
        return SCNFloat(acos(cosineAngle))
    }
}

/**
 * Adds two SCNVector3 vectors and returns the result as a new SCNVector3.
 */
func + (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}

/**
 * Increments a SCNVector3 with the value of another.
 */
func += ( left: inout SCNVector3, right: SCNVector3) {
    left = left + right
}

/**
 * Subtracts two SCNVector3 vectors and returns the result as a new SCNVector3.
 */
func - (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x - right.x, left.y - right.y, left.z - right.z)
}

/**
 * Decrements a SCNVector3 with the value of another.
 */
func -= ( left: inout SCNVector3, right: SCNVector3) {
    left = left - right
}

/**
 * Multiplies two SCNVector3 vectors and returns the result as a new SCNVector3.
 */
func * (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x * right.x, left.y * right.y, left.z * right.z)
}

/**
 * Multiplies a SCNVector3 with another.
 */
func *= ( left: inout SCNVector3, right: SCNVector3) {
    left = left * right
}

/**
 * Multiplies the x, y and z fields of a SCNVector3 with the same scalar value and
 * returns the result as a new SCNVector3.
 */
func * (vector: SCNVector3, scalar: Float) -> SCNVector3 {
    return SCNVector3Make(vector.x * scalar, vector.y * scalar, vector.z * scalar)
}

/**
 * Multiplies the x and y fields of a SCNVector3 with the same scalar value.
 */
func *= ( vector: inout SCNVector3, scalar: Float) {
    vector = vector * scalar
}

/**
 * Divides two SCNVector3 vectors abd returns the result as a new SCNVector3
 */
func / (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x / right.x, left.y / right.y, left.z / right.z)
}

/**
 * Divides a SCNVector3 by another.
 */
func /= ( left: inout SCNVector3, right: SCNVector3) {
    left = left / right
}

/**
 * Divides the x, y and z fields of a SCNVector3 by the same scalar value and
 * returns the result as a new SCNVector3.
 */
func / (vector: SCNVector3, scalar: Float) -> SCNVector3 {
    return SCNVector3Make(vector.x / scalar, vector.y / scalar, vector.z / scalar)
}

/**
 * Divides the x, y and z of a SCNVector3 by the same scalar value.
 */
func /= ( vector: inout SCNVector3, scalar: Float) {
    vector = vector / scalar
}

/**
 * Negate a vector
 */
func SCNVector3Negate(vector: SCNVector3) -> SCNVector3 {
    return vector * -1
}

/**
 * Returns the length (magnitude) of the vector described by the SCNVector3
 */
func SCNVector3Length(vector: SCNVector3) -> Float
{
    return sqrtf(vector.x*vector.x + vector.y*vector.y + vector.z*vector.z)
}

/**
 * Returns the distance between two SCNVector3 vectors
 */
func SCNVector3Distance(vectorStart: SCNVector3, vectorEnd: SCNVector3) -> Float {
    return SCNVector3Length(vector: vectorEnd - vectorStart)
}

/**
 * Returns the distance between two SCNVector3 vectors
 */
func SCNVector3Normalize(vector: SCNVector3) -> SCNVector3 {
    return vector / SCNVector3Length(vector: vector)
}

/**
 * Calculates the dot product between two SCNVector3 vectors
 */
func SCNVector3DotProduct(left: SCNVector3, right: SCNVector3) -> Float {
    return left.x * right.x + left.y * right.y + left.z * right.z
}

/**
 * Calculates the cross product between two SCNVector3 vectors
 */
func SCNVector3CrossProduct(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.y * right.z - left.z * right.y, left.z * right.x - left.x * right.z, left.x * right.y - left.y * right.x)
}

/**
 * Calculates the SCNVector from lerping between two SCNVector3 vectors
 */
func SCNVector3Lerp(vectorStart: SCNVector3, vectorEnd: SCNVector3, t: Float) -> SCNVector3 {
    return SCNVector3Make(vectorStart.x + ((vectorEnd.x - vectorStart.x) * t), vectorStart.y + ((vectorEnd.y - vectorStart.y) * t), vectorStart.z + ((vectorEnd.z - vectorStart.z) * t))
}

/**
 * Project the vector, vectorToProject, onto the vector, projectionVector.
 */
func SCNVector3Project(vectorToProject: SCNVector3, projectionVector: SCNVector3) -> SCNVector3 {
    let scale: Float = SCNVector3DotProduct(left: projectionVector, right: vectorToProject) / SCNVector3DotProduct(left: projectionVector, right: projectionVector)
    let v: SCNVector3 = projectionVector * scale
    return v
}

extension float4x4 {
    func convertToSCNVector3() -> SCNVector3 {
        return SCNVector3Make(self.columns.3.x,
                self.columns.3.y,
                self.columns.3.z)
    }
}
