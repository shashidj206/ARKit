//
//  ViewController.swift
//  MidigiTransAR
//
//  Created by Shashidhar Jagatap on 21/02/24.
//


import SceneKit
import UIKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    var imageNode: SCNNode?
    var refreshButton: UIButton!
    var collectionView: UICollectionView!
    var selectedImage = UIImage(named: "tile1")
    var isCollectionViewVisible = false
    var isImageSelected = false
    var detectedPlanes = Set<ARAnchor>()
    
    let images = ["tile1", "tile2", "tile1"] // Replace with your image names
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configeSceneSession()
        self.addGestures()
        self.setupUI()
    }
    
    private func configeSceneSession(){
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        //sceneView.showsStatistics = true
        //self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        
        // Enable plane detection
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
    }
    
    private func addGestures(){
        // Add pinch and rotation, pan gesture recognizers
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
        sceneView.addGestureRecognizer(pinchGestureRecognizer)
        
        let rotationGestureRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(handleRotationGesture(_:)))
        sceneView.addGestureRecognizer(rotationGestureRecognizer)
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        sceneView.addGestureRecognizer(panGestureRecognizer)
        
        // Ensure gestures are forwarded properly
        for gestureRecognizer in sceneView.gestureRecognizers ?? [] {
            gestureRecognizer.delegate = self
        }
    }
    
    private func setupUI(){
        self.addRefreshButton()
        self.addShowCollectionButton()
    }
    
    private func addRefreshButton(){
        // Add refresh button as an overlay
        refreshButton = UIButton(type: .system)
        refreshButton.setTitle("Refresh", for: .normal)
        refreshButton.addTarget(self, action: #selector(refreshButtonTapped), for: .touchUpInside)
        refreshButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(refreshButton)
        
        // Constraints for the refresh button
        NSLayoutConstraint.activate([
            refreshButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            refreshButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    private func addShowCollectionButton(){
        // Add button to toggle collection view visibility
        let toggleButton = UIButton(type: .system)
        toggleButton.setTitle("Show Collections", for: .normal)
        toggleButton.addTarget(self, action: #selector(toggleButtonTapped), for: .touchUpInside)
        toggleButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toggleButton)
        
        // Add UICollectionView
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 10.0
        layout.itemSize = CGSize(width: 100, height: 100) // Adjust item size as needed
        
        collectionView = UICollectionView(frame: CGRect(x: 10, y: toggleButton.frame.origin.y + 100.0, width: view.frame.width - 10.0, height: 150), collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.backgroundColor = UIColor.clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isHidden = true
        view.addSubview(collectionView)
        
        // Constraints for the toggle button
        NSLayoutConstraint.activate([
            toggleButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),// Position below refresh button
            toggleButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10)
        ])
    }
}

// MARK: ARSCNViewDelegate
extension ViewController{
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // Check if the anchor is of type ARPlaneAnchor
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        // Check if this plane has already been detected
        if detectedPlanes.count > 0 {
            if let planeNode = imageNode {
                let material = SCNMaterial()
                material.diffuse.contents = selectedImage
                planeNode.geometry?.firstMaterial = material
            }
            return // Plane already detected and processed
        }
        
        // Add the plane anchor to the set of detected planes
        detectedPlanes.insert(planeAnchor)
        
        // Create a plane geometry
        let planeGeometry = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        
        // Create a material with the selected image
        let material = SCNMaterial()
        material.diffuse.contents = selectedImage
        
        // Apply the material to the plane geometry
        planeGeometry.materials = [material]
        
        // Create a node with the plane geometry
        let planeNode = SCNNode(geometry: planeGeometry)
        
        // Position the plane node based on the anchor
        planeNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
        
        // Rotate the plane to match the orientation of the detected plane
        planeNode.eulerAngles.x = -.pi / 2
        
        // Add the plane node to the scene
        node.addChildNode(planeNode)
        
        // Set imageNode for future reference
        imageNode = planeNode
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        // Check if the updated plane is already detected
        if detectedPlanes.count > 0 {
            if let planeNode = imageNode {
                let material = SCNMaterial()
                material.diffuse.contents = selectedImage
                planeNode.geometry?.firstMaterial = material
            }
            return // Plane already detected and processed
        }
        
        // Add the plane anchor to the set of detected planes
        detectedPlanes.insert(planeAnchor)
        
        // Create a plane geometry
        let planeGeometry = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        
        // Create a material with the selected image
        let material = SCNMaterial()
        material.diffuse.contents = selectedImage
        
        // Apply the material to the plane geometry
        planeGeometry.materials = [material]
        
        // Create a node with the plane geometry
        let planeNode = SCNNode(geometry: planeGeometry)
        
        // Position the plane node based on the anchor
        planeNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
        
        // Rotate the plane to match the orientation of the detected plane
        planeNode.eulerAngles.x = -.pi / 2
        
        // Add the plane node to the scene
        node.addChildNode(planeNode)
        
        // Set imageNode for future reference
        imageNode = planeNode
    }
}

// MARK: Actions
extension ViewController{
    @objc func refreshButtonTapped() {
        // Reset AR session configuration to enable plane detection
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration, options: [.removeExistingAnchors])
        
        // Clear existing nodes
        sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
            node.removeFromParentNode()
        }
        
        // Clear detected planes
        detectedPlanes.removeAll()
    }
    
    @objc func toggleButtonTapped() {
        isCollectionViewVisible.toggle()
        collectionView.isHidden = !isCollectionViewVisible
        if !isImageSelected {
            collectionView.reloadData()
        }
    }
}

// MARK: Gestures
extension ViewController{
    @objc func handlePinchGesture(_ gestureRecognizer: UIPinchGestureRecognizer) {
        guard let sceneView = gestureRecognizer.view as? ARSCNView else { return }
        guard let imageNode = imageNode else { return }
        
        let pinchScaleX = Float(gestureRecognizer.scale) * imageNode.scale.x
        let pinchScaleY = Float(gestureRecognizer.scale) * imageNode.scale.y
        let pinchScaleZ = Float(gestureRecognizer.scale) * imageNode.scale.z
        
        imageNode.scale = SCNVector3(pinchScaleX, pinchScaleY, pinchScaleZ)
        
        gestureRecognizer.scale = 1
    }
    
    @objc func handleRotationGesture(_ gestureRecognizer: UIRotationGestureRecognizer) {
        guard let sceneView = gestureRecognizer.view as? ARSCNView else { return }
        guard let imageNode = imageNode else { return }
        
        let rotation = Float(gestureRecognizer.rotation)
        
        imageNode.eulerAngles.y -= rotation
        
        gestureRecognizer.rotation = 0
    }
    
    @objc func handlePanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard let sceneView = gestureRecognizer.view as? ARSCNView else { return }
        guard let imageNode = imageNode else { return }
        
        let translation = gestureRecognizer.translation(in: sceneView)
        let xTranslation = Float(translation.x) / Float(sceneView.bounds.width) * 2.0 // Adjust multiplier as needed
        let zTranslation = Float(translation.y) / Float(sceneView.bounds.height) * 2.0 // Adjust multiplier as needed
        
        let currentPosition = imageNode.position
        imageNode.position = SCNVector3(currentPosition.x + xTranslation, currentPosition.y, currentPosition.z - zTranslation)
        
        gestureRecognizer.setTranslation(.zero, in: sceneView)
    }
}

extension ViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

// MARK: UICollectionViewDelegate
extension ViewController:UICollectionViewDelegate,UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        let imageView = UIImageView(frame: cell.bounds)
        imageView.image = UIImage(named: images[indexPath.item])
        cell.contentView.addSubview(imageView)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedImage = UIImage(named: images[indexPath.item])
        isImageSelected = true
        collectionView.isHidden = true
        isCollectionViewVisible = false
        
        // Update the material of the plane node with the selected image
        if let planeNode = imageNode {
            let material = SCNMaterial()
            material.diffuse.contents = selectedImage
            planeNode.geometry?.firstMaterial = material
        }
    }
}
