//
//  MemoViewController.swift
//  ARkit-Emperor
//
//  Created by Ren Matsushita on 2019/02/13.
//  Copyright © 2019 Ren Matsushita. All rights reserved.
//

import UIKit
import ARKit

class MemoViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var textfield: UITextField!
    
    var text: String!
    
    let defaultConfiguration: ARWorldTrackingConfiguration = {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.environmentTexturing = .automatic
        return configuration
    }()
    
    lazy var memoSaveURL: URL = {
        do {
            return try FileManager.default
                .url(for: .documentDirectory,
                     in: .userDomainMask,
                     appropriateFor: nil,
                     create: true)
                .appendingPathComponent("map.arexperience")
        } catch {
            fatalError("Can't get file save URL: \(error.localizedDescription)")
        }
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textfield.delegate = self
        sceneView.delegate = self
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        sceneView.session.run(defaultConfiguration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textfield.text != nil {
            text = textfield.text!
        }
        
        textfield.resignFirstResponder()
        return true
    }
    
    @IBAction func save(_ sender: Any) {
        sceneView.session.getCurrentWorldMap(completionHandler: { worldMap, error  in
            guard let map = worldMap else { return }
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
                try data.write(to: self.memoSaveURL)
            } catch {
                print(error)
            }
        })
    }
    
    @IBAction func load(_ sender: Any) {
        do {
            let data = try Data(contentsOf: memoSaveURL)
            let worldMap: ARWorldMap? = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data)
            // WorldMapをConfiguretionに渡してARSessionを再開
            guard let map = worldMap else { return }
            setWorldMapToSession(worldMap: map)
        } catch {
            
        }
    }
    
    private func setWorldMapToSession(worldMap: ARWorldMap) {
        let configuration = ARWorldTrackingConfiguration()
        configuration.initialWorldMap = worldMap
        sceneView.session.run(configuration)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let location = touches.first?.location(in: sceneView) else { return }
        guard let hitTest = sceneView.hitTest(location, types: [.existingPlane]).first else { return }
        
        let memoAnchor = ARAnchor(name: "Memo", transform: hitTest.worldTransform)
        sceneView.session.add(anchor: memoAnchor)
    }
    
}

extension MemoViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if anchor.name == "Memo" {
            let textGeometry = SCNText(string: text, extrusionDepth: 10)
            let textnode = SCNNode(geometry: textGeometry)
            textnode.scale = SCNVector3Make(0.005, 0.005, 0.005)
            node.addChildNode(textnode)
            
        }
    }
}
