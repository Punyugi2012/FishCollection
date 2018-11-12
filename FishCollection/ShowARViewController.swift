//
//  ShowARViewController.swift
//  FishCollection
//
//  Created by punyawee  on 6/11/2561 BE.
//  Copyright © 2561 Punyugi. All rights reserved.
//

import UIKit
import ARKit
import SceneKit

class ShowARViewController: UIViewController {
    
    @IBOutlet weak var loader: UIActivityIndicatorView! {
        didSet {
            loader.transform = CGAffineTransform(scaleX: 2.0, y: 2.0)
        }
    }
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var resetBtn: UIButton! {
        didSet {
            resetBtn.layer.cornerRadius = resetBtn.bounds.height / 2.0
        }
    }
    @IBOutlet weak var closeBtn: UIButton! {
        didSet {
            closeBtn.layer.cornerRadius = closeBtn.bounds.height / 2.0
        }
    }
    
    var fishNode: SCNNode?
    var getFishModel: FishModel?
    let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        loader.stopAnimating()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        fishNode?.removeFromParentNode()
        fishNode = nil
        currentAngleY  = -1.57
        let configuration = ARWorldTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        loader.startAnimating()
        view.isUserInteractionEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.loadFishNode()
            self.loader.stopAnimating()
            self.view.isUserInteractionEnabled = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        sceneView.addGestureRecognizer(panGesture)
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(gesture:)))
        
        sceneView.addGestureRecognizer(pinchGesture)
        let configuration = ARWorldTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        sceneView.session.run(configuration, options: [])
        
        loader.startAnimating()
        view.isUserInteractionEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.loadFishNode()
            self.loader.stopAnimating()
            self.view.isUserInteractionEnabled = true
        }
    }
    
    
    func loadFishNode() {
        if
            let modelURLString = getFishModel?.modelURL,
            let modelURL = URL(string: modelURLString)
        {
            let localModelURL = documentURL.appendingPathComponent(modelURL.lastPathComponent)
            do {
                let scene = try SCNScene(url: localModelURL, options: [:])
                let fishNode = SCNNode()
                fishNode.position = SCNVector3(0, 0, 0)
                let childFish = scene.rootNode.childNode(withName: "Fish", recursively: false)
                childFish?.geometry?.materials = []
                let material = SCNMaterial()
                for texture in getFishModel?.textureURLs ?? [] {
                    if let textureURL = URL(string: texture) {
                        let localTextureURL = self.documentURL.appendingPathComponent(textureURL.lastPathComponent)
                        let data = try? Data(contentsOf: localTextureURL)
                        if let data = data {
                            material.diffuse.contents = data
                        }
                    }
                }
                childFish?.geometry?.materials = [material]
                childFish?.scale = SCNVector3(0.03, 0.03, 0.03)
                childFish?.position = SCNVector3(0, 0, -0.3)
                childFish?.eulerAngles = SCNVector3(0, 0, 0)
                childFish?.eulerAngles.y = Float(-90) * Float(Double.pi / 180)
                if let childFish = childFish {
                    fishNode.addChildNode(childFish)
                }
                self.fishNode = fishNode
                sceneView.scene.rootNode.addChildNode(fishNode)
            }catch {
                print(error.localizedDescription)
            }
        }
    }
    
    @IBAction func tappedCloseBtn(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func tappedResetBtn(_ sender: UIButton) {
        fishNode?.removeFromParentNode()
        fishNode = nil
        currentAngleY  = -1.57
        let configuration = ARWorldTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        loader.startAnimating()
        view.isUserInteractionEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.loadFishNode()
            self.loader.stopAnimating()
            self.view.isUserInteractionEnabled = true
        }
    }
    
    var currentAngleY: Float = -1.57
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        if let node = fishNode, let fishNode = node.childNode(withName: "Fish", recursively: true) {
            var newAngleY: Float = 0.0
            let translation = gesture.translation(in: sceneView)
            newAngleY = Float(translation.x) * Float(Double.pi / 180)
            newAngleY += currentAngleY
            fishNode.eulerAngles.y = newAngleY
            if gesture.state == .ended {
                currentAngleY = newAngleY
            }
        }
    }
    
    @objc func handlePinch(gesture: UIPinchGestureRecognizer) {
        guard let node = fishNode, let fishNode = node.childNode(withName: "Fish", recursively: true) else { return }
        print(gesture.scale)
        switch gesture.state {
        case .began:
            gesture.scale = CGFloat(fishNode.scale.x)
        case .changed:
            var newScale = SCNVector3(0, 0, 0)
            if gesture.scale < 0.01 {
                newScale = SCNVector3(0.01, 0.01, 0.01)
            }
            else if gesture.scale > 0.3 {
                newScale = SCNVector3(0.3, 0.3, 0.3)
            }
            else {
                newScale = SCNVector3(gesture.scale, gesture.scale, gesture.scale)
            }
            fishNode.scale = newScale
        case .ended:
            var newScale = SCNVector3(0, 0, 0)
            if gesture.scale < 0.01 {
                newScale = SCNVector3(0.01, 0.01, 0.01)
            }
            else if gesture.scale > 0.3 {
                newScale = SCNVector3(0.3, 0.3, 0.3)
            }
            else {
                newScale = SCNVector3(gesture.scale, gesture.scale, gesture.scale)
            }
            fishNode.scale = newScale
        default:
            break
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }


}
