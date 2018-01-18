//
//  GameViewController.swift
//  DAE-Model-Viewer
//
//  Created by Bence Feher on 2018/01/18.
//  Copyright © 2018 Bence Feher. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit




class GameViewController: UIViewController {
    // MARK: - Enums and Constants
    // Enum used to determine rotation mode:
    private enum RotationMode: Int {
        case Global = 0, XAxis, YAxis, ZAxis
    }
    
    private var defaultCameraZPosition: Float = 7       // Just a constant that I like. Used to set camera position.
    private var pixelToAngleConstant: Float = .pi / 180 // A handy constant for converting our math into the pixel space.
    private var tapDistanceThreshold: Float = 35.0  /* Used to ignore tiny changes in gesture info, resulting in a smoother, less twitchy animation.
     * This happens often when using 2 fingers to pan or zoom. When the user finishes movement and
     * lifts their fingers up, the gesture recognizer often recognizes very large spikes in movement.
     * This threshold will be used to ignore those very large spikes of change in our gestures.
     */


    // MARK: - Outlets and Properties
    @IBOutlet weak var sceneView: SCNView!                      // Our SCNView.
    @IBOutlet weak var axesVisibilitySwitch: UISwitch!          // Switch controlling if we should display axes arrow markers or not.
    @IBOutlet weak var rotationModeSwitch: UISegmentedControl!  // Switch controlling which axes to rotate on.
    @IBOutlet weak var gestureKeySV: UIStackView!               // Stack View that holds our gesture key images.
    private var rotationMode: RotationMode!             // A flag to control which axes to rotate on.
    private var cameraNode: SCNNode!                    // Holds our camera.
    private var axesMarkersNode: SCNNode!               // Holds our arrows (axis markers) models.
    private var modelNode: SCNNode!                     // Holds our 3D model.
    private var combinedNode: SCNNode!                  // Holds both our 3D model and arrows (axis markers) nodes.
    private var previousPanPoint: CGPoint?              // Used to track panning.
    private var previousScale: Float?                   // Used to track zooming.
    private var previousPinchPointA: CGPoint?           // Used to track distance between touch points.
    private var previousPinchPointB: CGPoint?           // Used to track distance between touch points.

    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Create a new scene:
        let scene = setupScene()
        // Setup our camera:
        cameraNode = setupCamera(for: scene)
        // Setup our lighting:
        setupLighting(for: scene)
        // Setup our models:
        setupCombinedModelAndAxesMarkersNode(in: scene)
        // Setup our scene view:
        setupSceneView(with: scene)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Add our gesture recognizers for handling pan, pinch, and double tapping:
        addGestureRecognizers(to: sceneView)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // Remove our gesture recognizers:
        removeGestureRecognizers(from: sceneView)
        super.viewWillDisappear(animated)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        if UIDevice.current.orientation.isLandscape {
            gestureKeySV.axis = .vertical
        } else {
            gestureKeySV.axis = .horizontal
        }
    }
    
    
    // MARK: - Parent Overrides
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    
    // MARK: - Setup
    private func setupScene() -> SCNScene {
        // We can setup and customize our scene here.
        // Note that we will do almost nothing.
        let scene = SCNScene()
        return scene
    }
    
    private func setupCamera(for scene: SCNScene!) -> SCNNode {
        // Create and add a camera to the scene:
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        // Place the camera:
        cameraNode.position = SCNVector3(x: 0, y: 0, z: defaultCameraZPosition) // Sitting 'z' units out on the horizontal plane, facing the origin (0, 0, 0).
        return cameraNode
    }
    
    private func setupLighting(for scene: SCNScene!) {
        // Create and add a light to the scene:
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(lightNode)
        
        // Create and add an ambient light to the scene:
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)
    }
    
    private func setupCombinedModelAndAxesMarkersNode(in scene: SCNScene!) {
        // Add axis marker arrows:
        let arrowsScene = SCNScene(named: "art.scnassets/arrows.scn")!  // Grabs the scene file containing our arrow objects.
        axesMarkersNode = arrowsScene.rootNode.childNode(withName: "arrows", recursively: true) // Assigns the arrows node to our global variable axesMarkersNode.
        axesMarkersNode.position = SCNVector3Zero   // Positions our node on the origin.
        axesMarkersNode.rotation = SCNVector4Zero   // Clears any rotations that might have been performed in arrowsScene. (Unnecessary, but here for reference.)
        // Add our 3D model:
        let modelScene = SCNScene(named: "art.scnassets/Pokemon.dae")   // Provided for free by artist Simon Telezhkin via TurboSquid. https://www.turbosquid.com/3d-models/free-obj-model-ivysaur-pokemon-sample/1136333
        modelNode = modelScene?.rootNode.childNode(withName: "pokemon", recursively: true)  // Assigns just the pokemon model to our global variable modelNode.
        modelNode.position = SCNVector3Zero   // Positions our node on the origin.
        // Place our two object nodes into a combined node for easy paired manipulations:
        combinedNode = SCNNode()
        combinedNode.addChildNode(axesMarkersNode)
        combinedNode.addChildNode(modelNode)
        // Add our combined node to our scene:
        scene.rootNode.addChildNode(combinedNode)
    }
    
    private func setupSceneView(with scene: SCNScene!) {
        // Set the scene to the view:
        sceneView.scene = scene
        // Disable default camera controls:
        sceneView.allowsCameraControl = false
        // Show statistics such as fps and timing information:
        sceneView.showsStatistics = true
        // Configure the view:
        sceneView.backgroundColor = UIColor.black
    }

    
    // MARK: - Rotation
    private func rotate(node: SCNNode, by angle: Float, around axis: SCNVector3) {
        /* Note:
         * To maintain local rotation, we must first put the node back at (0, 0, 0).
         * Then we rotate it and lastly we put it back where it was.
         */
        var adjustedAxis: SCNVector3
        let selectedSegment = RotationMode(rawValue: rotationModeSwitch.selectedSegmentIndex)!
        switch selectedSegment {
        case .XAxis, .YAxis, .ZAxis:
            // Convert our vector to global coordinates (so we can rotate around global origin (0, 0, 0):
            adjustedAxis = node.convertVector(axis, to: node.parent)
        case .Global:
            // For global, just keep axis as is:
            adjustedAxis = axis
        }
        // Create a rotation matrix:
        let transformRotation = SCNMatrix4MakeRotation(angle, adjustedAxis.x, adjustedAxis.y, adjustedAxis.z)
        // Save the current location of the node:
        let currentLocation = node.position
        // Reposition the node to center (0, 0, 0):
        node.position = SCNVector3Zero
        // Apply the rotation matrix to our transform:
        node.transform = SCNMatrix4Mult(node.transform, transformRotation)
        // Send the nodes back to where it was:
        node.position = currentLocation
    }
    
    private func rotate(node: SCNNode, aroundXAxisAt angle: Float) {    // Rotating around X is like doing front or back flips.
        let axis = SCNVector3Make(1, 0, 0)  // x-axis
        rotate(node: node, by: angle, around: axis)
    }
    
    private func rotate(node: SCNNode, aroundYAxisAt angle: Float) {    // Rotating around Y is like spinning left-to-right or right-to-left.
        let axis = SCNVector3Make(0, 1, 0)  // y-axis
        rotate(node: node, by: angle, around: axis)
    }

    private func rotate(node: SCNNode, aroundZAxisAt angle: Float) {    // Rotating around Z is like a doing a barrel roll.
        let axis = SCNVector3Make(0, 0, 1)  // z-axis
        rotate(node: node, by: angle, around: axis)
    }

    private func handlePanRotate(newPoint: CGPoint) {
        if let previousPoint = previousPanPoint {
            let dx = Float(newPoint.x - previousPoint.x)
            let dy = Float(newPoint.y - previousPoint.y)
            let selectedSegment = RotationMode(rawValue: rotationModeSwitch.selectedSegmentIndex)!
            switch selectedSegment {
            case .Global:
                rotate(node: combinedNode, aroundXAxisAt: dy * pixelToAngleConstant)    // Rotating around X means flipping vertically, hence the dy.
                rotate(node: combinedNode, aroundYAxisAt: dx * pixelToAngleConstant)    // Rotating around Y means spinning horizontally, hence the dx.
            case .XAxis:
                rotate(node: combinedNode, aroundXAxisAt: dy * pixelToAngleConstant)    // Rotating around X means flipping vertically, hence the dy.
            case .YAxis:
                rotate(node: combinedNode, aroundYAxisAt: dx * pixelToAngleConstant)    // Rotating around Y means spinning horizontally, hence the dx.
            case .ZAxis:
                rotate(node: combinedNode, aroundZAxisAt: -dx * pixelToAngleConstant)    // Rotating around Z means doing a barrel roll, so either dx or dy will work (but we pick dx, and we flip it negative because Z moves OUT towards us).
            }
        }
        previousPanPoint = newPoint
    }
    
    
    // MARK: - Translation
    private func translate(node: SCNNode, by vector: SCNVector3) {
        let transform = SCNMatrix4MakeTranslation(vector.x, vector.y, vector.z)
        combinedNode.transform = SCNMatrix4Mult(combinedNode.transform, transform)
    }
    
    private func translate(node: SCNNode, alongXAxisBy amount: Float) { // Translating along X means moving left or right.
        let translationVector = SCNVector3Make(amount, 0, 0)    // x-axis
        translate(node: node, by: translationVector)
    }
    
    private func translate(node: SCNNode, alongYAxisBy amount: Float) { // Translating along Y means moving up or down.
        let translationVector = SCNVector3Make(0, amount, 0)    // y-axis
        translate(node: node, by: translationVector)
    }

    private func translate(node: SCNNode, alongZAxisBy amount: Float) { // Translating along Z means moving in or out.
        let translationVector = SCNVector3Make(0, 0, amount)    // z-axis
        translate(node: node, by: translationVector)
    }

    private func handlePanTranslate(newPoint: CGPoint) {
        if let previousPoint = previousPanPoint {
            let dx = Float(newPoint.x - previousPoint.x)
            let dy = Float(newPoint.y - previousPoint.y)
            let dampening = Float(100)  // This is to slow down the movement.
            translate(node: combinedNode, alongXAxisBy: dx/dampening)
            translate(node: combinedNode, alongYAxisBy: -dy/dampening)  // Negative because (0, 0) is the TOP LEFT!
        }
        previousPanPoint = newPoint
    }

    // MARK: Zoom
    private func handlePinch(newScale: Float) {
        if let scale = previousScale {
            let dz = newScale - scale
            let modifier = Float(3) // This is to speed up the movement.
            translate(node: cameraNode, alongZAxisBy: dz * modifier)
        }
        previousScale = newScale
    }

    
    // MARK: - Gesture Handlers
    @objc
    private func handlePanGesture(_ pan: UIPanGestureRecognizer) {
        switch pan.state {
        case .began:
            previousPanPoint = pan.location(in: pan.view)
        case .changed:
            let newPointA = pan.location(in: pan.view)
            if distanceBetweenPoints(a: newPointA, b: previousPanPoint!) > tapDistanceThreshold { return }  // This lets us ignore large spikes that tend to happen when we lift our fingers up from the screen.
            if pan.numberOfTouches == 1 {
                handlePanRotate(newPoint: newPointA)
            } else {
                handlePanTranslate(newPoint: newPointA)
            }
        default:
            previousPanPoint = nil
        }
    }
    
    @objc
    private func handlePinchGesture(_ pinch: UIPinchGestureRecognizer) {
        // Return if we don't have 2 points:
        if pinch.numberOfTouches < 2 { return }
        // Get the current points so we can compare them to old ones to see if we are beyond our threshold value:
        let newPointA = pinch.location(ofTouch: 0, in: pinch.view)
        let newPointB = pinch.location(ofTouch: 1, in: pinch.view)
        
        switch pinch.state {
        case .began:
            // Update our pinch information:
            previousScale = Float(pinch.scale)
            previousPinchPointA = newPointA
            previousPinchPointB = newPointB
        case .changed:
            let newDistanceBetweenPoints = distanceBetweenPoints(a: newPointA, b: newPointB)
            let previousDistanceBetweenPoints = distanceBetweenPoints(a: previousPinchPointA!, b: previousPinchPointB!)
            if fabs(newDistanceBetweenPoints - previousDistanceBetweenPoints) > tapDistanceThreshold { return } // This lets us ignore large spikes that tend to happen when we lift our fingers up from the screen.
            handlePinch(newScale: Float(pinch.scale))
            previousPinchPointA = newPointA
            previousPinchPointB = newPointB
        default:
            // Reset our saved pinch information:
            previousScale = nil
            previousPinchPointA = nil
            previousPinchPointB = nil
        }
    }

    @objc
    private func handleDoubleTapGesture(_ tap: UITapGestureRecognizer) {
        // Reset Camera to (0, 0, 7):
        cameraNode.position = SCNVector3Make(0, 0, defaultCameraZPosition)
        cameraNode.rotation = SCNVector4Zero    // Technically unnecessary because we never rotate the camera.
        // Reset model and arrow nodes to (0, 0, 0):
        combinedNode.position = SCNVector3Zero
        // Reset model and arrow nodes rotation:
        combinedNode.rotation = SCNVector4Zero
    }
    

    // MARK: - IBAction Handlers
    @IBAction func axesVisibilitySwitched(_ sender: UISwitch) {
        let selectedSegment = RotationMode(rawValue: rotationModeSwitch.selectedSegmentIndex)!
        switch selectedSegment {
        case .Global:
            // Adjust the visibility of our axes markers:
            setXAxisVisible(sender.isOn)
            setYAxisVisible(sender.isOn)
            setZAxisVisible(sender.isOn)
        case .XAxis:
            // Adjust the visibility of our axes markers:
            setXAxisVisible(sender.isOn)
            setYAxisVisible(false)
            setZAxisVisible(false)
        case .YAxis:
            // Adjust the visibility of our axes markers:
            setXAxisVisible(false)
            setYAxisVisible(sender.isOn)
            setZAxisVisible(false)
        case .ZAxis:
            // Adjust the visibility of our axes markers:
            setXAxisVisible(false)
            setYAxisVisible(false)
            setZAxisVisible(sender.isOn)
        }
    }
    
    @IBAction func rotationModeChanged(_ sender: UISegmentedControl) {
        let selectedSegment = RotationMode(rawValue: sender.selectedSegmentIndex)!
        switch selectedSegment {
        case .Global:
            // Set our rotation mode:
            rotationMode = .Global
            // Adjust the tint color of our segmented control:
            sender.tintColor = .white
            // Adjust the visibility of our axes markers:
            setXAxisVisible(axesVisibilitySwitch.isOn)
            setYAxisVisible(axesVisibilitySwitch.isOn)
            setZAxisVisible(axesVisibilitySwitch.isOn)
        case .XAxis:
            // Set our rotation mode:
            rotationMode = .XAxis
            // Adjust the tint color of our segmented control:
            sender.tintColor = UIColor(red: 244.0/255.0, green: 67.0/255.0, blue: 54.0/255.0, alpha: 1)
            // Adjust the visibility of our axes markers:
            setXAxisVisible(axesVisibilitySwitch.isOn)
            setYAxisVisible(false)
            setZAxisVisible(false)
        case .YAxis:
            // Set our rotation mode:
            rotationMode = .YAxis
            // Adjust the tint color of our segmented control:
            sender.tintColor = UIColor(red: 139.0/255.0, green: 195.0/255.0, blue: 74.0/255.0, alpha: 1)
            // Adjust the visibility of our axes markers:
            setXAxisVisible(false)
            setYAxisVisible(axesVisibilitySwitch.isOn)
            setZAxisVisible(false)
        case .ZAxis:
            // Set our rotation mode:
            rotationMode = .ZAxis
            // Adjust the tint color of our segmented control:
            sender.tintColor = UIColor(red: 83.0/255.0, green: 109.0/255.0, blue: 254.0/255.0, alpha: 1)
            // Adjust the visibility of our axes markers:
            setXAxisVisible(false)
            setYAxisVisible(false)
            setZAxisVisible(axesVisibilitySwitch.isOn)
        }
    }
    
    
    // MARK: - Utility Functions
    private func addGestureRecognizers(to sceneView: SCNView!) {
        // Pan gesture recognizer handling 1 finger panning for rotation and 2 finger panning for translation:
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        sceneView.addGestureRecognizer(panRecognizer)
        // Pinch gesture recognizer handling 2 finger pinches for zoom:
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
        sceneView.addGestureRecognizer(pinchRecognizer)
        // Tap gesture recognizer handling double-tapping for resetting the scene:
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTapGesture(_:)))
        doubleTapRecognizer.numberOfTapsRequired = 2
        sceneView.addGestureRecognizer(doubleTapRecognizer)
    }
    
    private func removeGestureRecognizers(from sceneView: SCNView!) {
        sceneView.gestureRecognizers?.removeAll()
    }
    
    private func distanceBetweenPoints(a: CGPoint, b: CGPoint) -> Float {
        // Standard distance between 2 points math (square root of the sum of the differences squared).
        let dx = fabs(b.x - a.x)
        let dy = fabs(b.y - a.y)
        return Float(sqrt(pow(dx, 2) + pow(dy, 2)))
    }
    
    private func setXAxisVisible(_ v: Bool) {
        let arrow = axesMarkersNode.childNode(withName: "x", recursively: true)!
        arrow.isHidden = !v
    }
    
    private func setYAxisVisible(_ v: Bool) {
        let arrow = axesMarkersNode.childNode(withName: "y", recursively: true)!
        arrow.isHidden = !v
    }

    private func setZAxisVisible(_ v: Bool) {
        let arrow = axesMarkersNode.childNode(withName: "z", recursively: true)!
        arrow.isHidden = !v
    }
}
