import SceneKit

class SphereNodesManager {

    private let defaultSphereRadius: CGFloat = 0.0018

    private var sphereNodeCache = [UIColor: SCNNode]()

    // Creating thousands of nodes uses up a lot of memory so instead we use cloning. Reference spheres are created once and then cloned instead of creating new spheres every time.
    private lazy var redReferenceSphereNode: SCNNode = {
        return createSphereNode(color: UIColor.red)
    }()

    private lazy var greenReferenceSphereNode: SCNNode = {
        return createSphereNode(color: UIColor.green)
    }()

    private lazy var blueReferenceSphereNode: SCNNode = {
        return createSphereNode(color: UIColor.blue)
    }()

    private lazy var whiteReferenceSphereNode: SCNNode = {
        return createSphereNode(color: UIColor.white)
    }()

    private lazy var blackReferenceSphereNode: SCNNode = {
        return createSphereNode(color: UIColor.black)
    }()

    private func createSphereNode(color: UIColor) -> SCNNode {
        let sphere = SCNSphere(radius: defaultSphereRadius)
        sphere.firstMaterial?.diffuse.contents = color
        return SCNNode(geometry: sphere)
    }

    func getReferenceSphereNode(forStrokeColor color: UIColor) -> SCNNode {
        if let node = sphereNodeCache[color] {
            return node
        } else {
            let node = createSphereNode(color: color)
            sphereNodeCache[color] = node

            return node
        }
    }
}