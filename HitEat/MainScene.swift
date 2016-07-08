//
//  MainScene.swift
//  HitEat
//
//  Created by Timothy Liew on 7/7/16.
//  Copyright © 2016 Tim Liew. All rights reserved.
//

import SpriteKit

class MainScene: SKScene {
    var playButton: MSButtonNode!
    var scrollLayer: SKNode!
    let scrollSpeed: CGFloat = 160
    let fixedDelta: CFTimeInterval = 1.0/60.0 /* 60 FPS */
    var bestLabel: SKLabelNode!
    
    override func didMoveToView(view: SKView) {
        scrollLayer = self.childNodeWithName("scrollLayer")
        
        playButton = self.childNodeWithName("playButton") as! MSButtonNode
        
        bestLabel = self.childNodeWithName("bestLabel") as! SKLabelNode
        bestLabel.text = String(NSUserDefaults.standardUserDefaults().integerForKey("bestLabel"))
        
        /* Setup restart button selection handler */
        playButton.selectedHandler = {
            
            /* Grab reference to our SpriteKit view */
            let skView = self.view as SKView!
            
            /* Load Game scene */
            let scene = GameScene(fileNamed:"GameScene") as GameScene!
            
            /* Ensure correct aspect mode */
            scene.scaleMode = .AspectFill
            
            /* Show debug */
            skView.showsPhysics = false
            skView.showsDrawCount = true
            skView.showsFPS = true
            
            /* Start game scene */
            skView.presentScene(scene)
        }
        
    }
    
    override func update(currentTime: NSTimeInterval) {
        scrollWorld()
    }
    
    func scrollWorld(){
        /* Scroll World */
        scrollLayer.position.y -= scrollSpeed * CGFloat(fixedDelta)
        
        /* Loop through scroll layer nodes*/
        for ground in scrollLayer.children as! [SKSpriteNode]{
            
            /* Get ground node position, convert node position to scene space*/
            let backgroundPosition = scrollLayer.convertPoint(ground.position, toNode: self)
            
            /* Check if ground sprite has left the scene */
            if backgroundPosition.y <= -ground.size.height / 2 - self.size.height / 2 {
                
                /* Convert new node position back to scroll layer space */
                ground.position.y += ground.size.height * 2
            }
        }
    }
    
}
