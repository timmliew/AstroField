//
//  GameScene.swift
//  HitEat
//
//  Created by Timothy Liew on 7/5/16.
//  Copyright (c) 2016 Tim Liew. All rights reserved.
//

import SpriteKit
import CoreMotion
import AudioToolbox

enum BulletType {
    case PlayerFired
}

enum GameState{
    case Active, Ready, GameOver, Pause
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    let motionManager = CMMotionManager()
    var tapQueue = [Int]()
    let player = SKSpriteNode(imageNamed: "player")
    var scrollLayer: SKNode!
    let fixedDelta: CFTimeInterval = 1.0/60.0 /* 60 FPS */
    let scrollSpeed: CGFloat = 160
    var obstacleLayer: SKNode!
    var spawnTimer: CFTimeInterval = 0
    var lastShootTime: CFTimeInterval = 1
    var restartButton: MSButtonNode!
    var menuButton: MSButtonNode!
    var homeButton: MSButtonNode!
    var continueButton: MSButtonNode!
    var gameState: GameState = .Active
    var noBullets = false
    var numBullets: Int = 10
    var numBulletsLabel: SKLabelNode!
    var pointsLabel: SKLabelNode!
    var points: Int = 0
    var bestLabel: SKLabelNode!
    var healthBar: SKSpriteNode!
    var health: CGFloat = 1.0 {
        didSet {
            if health > 1.0 {
                health = 1.0
            }
            healthBar.xScale = health
        }
    }
    
    override func didMoveToView(view: SKView) {
        // center the player on the screen
        player.position = CGPoint(x: 0, y: -195)
        player.size.width = 30
        player.size.height = 30
        
        // add it to the scene!
        self.addChild(player)
        
        /* Set reference to scroll layer node */
        scrollLayer = self.childNodeWithName("scrollLayer")
        
        /* Set reference to obstacle layer node */
        obstacleLayer = self.childNodeWithName("obstacleLayer")
        
        /* Set reference to score label */
        numBulletsLabel = self.childNodeWithName("scoreLabel") as! SKLabelNode
        numBulletsLabel.text = String(numBullets)
        
        pointsLabel = self.childNodeWithName("pointsLabel") as! SKLabelNode
        
        bestLabel = self.childNodeWithName("bestLabel") as! SKLabelNode
        bestLabel.text = String(NSUserDefaults.standardUserDefaults().integerForKey("bestLabel"))
        
        healthBar = self.childNodeWithName("healthBar") as! SKSpriteNode
        
        menuButton = self.childNodeWithName("menuButton") as! MSButtonNode
        
        homeButton = self.childNodeWithName("homeButton") as! MSButtonNode
        
        continueButton = self.childNodeWithName("continueButton") as! MSButtonNode
        
        /* UI Connection */
        restartButton = self.childNodeWithName("replayButton") as! MSButtonNode
        
        homeButton.state = .Hidden
        restartButton.state = .Hidden
        continueButton.state = .Hidden
        
        menuButton.selectedHandler = {
            self.homeButton.state = .Active
            self.restartButton.state = .Active
            self.continueButton.state = .Active
            self.gameState = .Pause
            self.physicsWorld.speed = 0
        }
        
        homeButton.selectedHandler = {
            let skView = self.view as SKView!

            let scene = MainScene(fileNamed: "MainScene") as MainScene!
            
            scene.scaleMode = .AspectFit
            
            /* Show debug */
            skView.showsPhysics = false
            skView.showsDrawCount = true
            skView.showsFPS = false
            
            /* Restart game scene */
            skView.presentScene(scene)

        }
        
        continueButton.selectedHandler = {
            self.gameState = .Active
            self.homeButton.state = .Hidden
            self.restartButton.state = .Hidden
            self.continueButton.state = .Hidden
            self.physicsWorld.speed = 1
        }
        
        /* Setup restart button selection handler */
        restartButton.selectedHandler = {
            
            /* Grab reference to our SpriteKit view */
            let skView = self.view as SKView!
            
            /* Load game scene */
            let scene = GameScene(fileNamed: "GameScene") as GameScene!
            
            /* Ensure correct aspect mode */
            scene.scaleMode = .AspectFit
            
            /* Show debug */
            skView.showsPhysics = false
            skView.showsDrawCount = true
            skView.showsFPS = false
            
            /* Restart game scene */
            skView.presentScene(scene)
        }

        restartButton.state = .Hidden
        
        
        // set up blob physics
        player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width * 0.5)
        player.physicsBody!.mass = 0.02
        player.physicsBody!.dynamic = true
        player.physicsBody!.allowsRotation = false
        player.physicsBody!.categoryBitMask = 1
        player.physicsBody!.contactTestBitMask = 0
        
        // initialize accelerometer
        if motionManager.accelerometerAvailable {
            motionManager.startAccelerometerUpdates()
        }
        
        // no gravity by default
        self.physicsWorld.gravity = CGVectorMake(0, 0)
        
        self.physicsWorld.contactDelegate = self
        
    }
    
    override func update(currentTime: CFTimeInterval) {
        /* Skip any updates */
        
        if health <= 0 {
            health = 0
            gameState = .GameOver
            
            for bullet in self.children {
                if bullet.name == "bullet"{
                    bullet.removeFromParent()
                }
            }
            
            player.removeFromParent()
            
            /* Show buttons */
            restartButton.state = .Active
            homeButton.state = .Active
            menuButton.state = .Hidden
            continueButton.state = .Hidden
            
        }
        
        if numBullets == 0 {
            noBullets = true
        }
        
        if points > Int(bestLabel.text!) {
            bestLabel.text = String(points)
        }
        
        if points > NSUserDefaults.standardUserDefaults().integerForKey("bestLabel") {
            NSUserDefaults.standardUserDefaults().setInteger(points, forKey: "bestLabel")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        
        bestLabel.text = String(NSUserDefaults.standardUserDefaults().integerForKey("bestLabel"))
        
        
        if gameState != .Active{
            return
        }

        
        if let data = motionManager.accelerometerData {
            self.physicsWorld.gravity = CGVectorMake(CGFloat(data.acceleration.x*3), 0)
        }
        player.position.y = -170
        
        if player.position.x < -160{
//            player.physicsBody?.applyImpulse(CGVector(dx: 0.5, dy: 0))
              player.position.x = 160
        } else if player.position.x > 160{
//            player.physicsBody?.applyImpulse(CGVector(dx: -0.5, dy: 0))
              player.position.x = -160
        }
        
        if player.position.y <= -255{
            player.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 0.2))
        } else if player.position.y >= 284 {
            player.physicsBody?.applyImpulse(CGVector(dx: 0, dy: -0.2))
        }
        
        
        scrollWorld()
        updateObstacles()
        
    }
    
    func updateObstacles(){
        /* Update Obstacles */
        let speed = CGFloat(scrollSpeed + (CGFloat(points) * 2))
        obstacleLayer.position.y -= speed * CGFloat(fixedDelta)
        
        /* Loop through obstacle layer nodes */
        for obstacle in obstacleLayer.children {
            
            /* Get obstacle node position, convert node position to scene space */
            let obstaclePosition = obstacleLayer.convertPoint(obstacle.position, toNode: self)
            if obstaclePosition.y < -self.size.height / 2 - 20 {
                obstacle.removeFromParent()
            }
        }
        spawnTimer += fixedDelta
        
        /* Time to add new obstacle */
        if spawnTimer >= 1.0 {
            /* Create a new obstacle reference object using our obstacle resource */
            let resourcePath = NSBundle.mainBundle().pathForResource("Obstacles", ofType: "sks")
            let newObstacle = SKReferenceNode (URL: NSURL (fileURLWithPath: resourcePath!))
            obstacleLayer.addChild(newObstacle)
            
            //obstacle
            let resourcePath2 = NSBundle.mainBundle().pathForResource("Obstacles2", ofType: "sks")
            let newObstacle2 = SKReferenceNode (URL: NSURL (fileURLWithPath: resourcePath2!))
            let newObstacle3 = SKReferenceNode (URL: NSURL (fileURLWithPath: resourcePath2!))
            obstacleLayer.addChild(newObstacle2)
            obstacleLayer.addChild(newObstacle3)
            
            
            //live
            let resourcePath4 = NSBundle.mainBundle().pathForResource("Obstacles3", ofType: "sks")
            let newObstacle4 = SKReferenceNode (URL: NSURL (fileURLWithPath: resourcePath4!))
            obstacleLayer.addChild(newObstacle4)
            
            //bullets
            let resourcePath5 = NSBundle.mainBundle().pathForResource("Bullets", ofType: "sks")
            let newObstacle5 = SKReferenceNode (URL: NSURL (fileURLWithPath: resourcePath5!))
            obstacleLayer.addChild(newObstacle5)
            
            /* Generate new obstacle position, start just outside screen and with a random y value */
            let randomPosition = CGPointMake(CGFloat.random(min: -self.size.width / 2, max: self.size.width / 2), self.size.height / 2 + 50)
            
            let randomPosition2 = CGPointMake(CGFloat.random(min: -self.size.width / 2, max: self.size.width / 2), self.size.height / 2 + 50)
            
            let randomPosition3 = CGPointMake(CGFloat.random(min: -self.size.width / 2, max: self.size.width / 2), self.size.height / 2 + 50)
            
            let randomPosition4 = CGPointMake(CGFloat.random(min: -self.size.width / 2, max: self.size.width / 2), self.size.height / 2 + 50)
            
            let randomPosition5 = CGPointMake(CGFloat.random(min: -self.size.width / 2, max: self.size.width / 2), self.size.height / 2 + 50)
            
            
            /* Convert new node position back to obstacle layer space */
            newObstacle.position = self.convertPoint(randomPosition, toNode: obstacleLayer)
            
            newObstacle2.position = self.convertPoint(randomPosition2, toNode: obstacleLayer)
            
            newObstacle3.position = self.convertPoint(randomPosition3, toNode: obstacleLayer)
            
            newObstacle4.position = self.convertPoint(randomPosition4, toNode: obstacleLayer)
            
            newObstacle5.position = self.convertPoint(randomPosition5, toNode: obstacleLayer)
            
  
            /* Reset spawn timer */
            spawnTimer = 0
            
        }
    }
    
    func scrollWorld(){
        /* Scroll World */
        let speed = CGFloat(scrollSpeed * 2 + CGFloat(points))
        scrollLayer.position.y -= speed * CGFloat(fixedDelta)
        
        
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
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        shoot()
        numBullets -= 1
        if numBullets < 0 { numBullets = 0 }
        numBulletsLabel.text = String(numBullets)
        
        for touch in touches {
           let location = touch.locationInNode(self)
            if location == continueButton.position{
                continueButton.state = .Hidden
            }
        }
    }
    
    // Shoot in direction of spriteToShoot
    func shoot() {
        if gameState == .Active && noBullets == false {
            // Create the bullet sprite
            let bullet = SKSpriteNode(imageNamed: "laserBlue03")
            bullet.name = "bullet"
            bullet.size = CGSize(width: 5,height: 15)
            bullet.position = CGPointMake(player.position.x+5, player.position.y+5)
            /* Create catapult arm physics body of type alpha */
            let bulletBody = SKPhysicsBody (texture: bullet.texture!, size: bullet.size)
            bulletBody.affectedByGravity = false
            bulletBody.allowsRotation = false
            //bulletBody.dynamic = false
            bullet.physicsBody = bulletBody
            bullet.physicsBody!.categoryBitMask = 0b100
            bullet.physicsBody!.contactTestBitMask = 0b010
            bullet.physicsBody!.collisionBitMask = 0b010
            self.addChild(bullet)
            
            // Determine vector to targetSprite
            let vector = CGVectorMake(0, 150)
            
            let bulletSFX = SKAction.playSoundFileNamed("sfx_laserlaser", waitForCompletion: false)
            
            // Create the action to move the bullet. Don't forget to remove the bullet!
            let bulletAction = SKAction.sequence([SKAction.repeatAction(SKAction.moveBy(vector, duration: 1), count: 10) ,  SKAction.waitForDuration(30.0/60.0), SKAction.removeFromParent()])
            bullet.runAction(bulletAction)
            if gameState != .GameOver {
                self.runAction(bulletSFX)
            }
        }
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        /* Ensure only called while game running */
        if gameState != .Active { return }
        
        
        let contactA: SKPhysicsBody = contact.bodyA
        let contactB: SKPhysicsBody = contact.bodyB
        
        guard let nodeA = contactA.node, nodeB = contactB.node else {
            return
        }
        
        let resourcePath = NSBundle.mainBundle().pathForResource("Damages", ofType: "sks")
        let damages = SKReferenceNode (URL: NSURL (fileURLWithPath: resourcePath!))
        
        /* Load our particle effect */
        let particles = SKEmitterNode(fileNamed: "CrashExplosion")!
        
        let powerUp = SKAction.playSoundFileNamed("sfx_powerUp", waitForCompletion: false)
        
        let laserUp = SKAction.playSoundFileNamed("sfx_laserUp", waitForCompletion: false)
        
        //check for lives and players
        if (nodeA.name == "live" && nodeB == player) || (nodeB.name == "live" && nodeA == player) {
            health += 0.1
            self.runAction(powerUp)
            if nodeA.name == "live" {
                nodeA.removeFromParent()
            } else {
                nodeB.removeFromParent()
            }
            //check for player and bullets
        }  else if (nodeA.name == "bulletBullet" && nodeB == player) || (nodeB.name == "bulletBullet" && nodeA == player) {
            numBullets += 5
            numBulletsLabel.text = String(numBullets)
            self.runAction(laserUp)
            noBullets = false
            if nodeA.name == "bulletBullet" {
                nodeA.removeFromParent()
            } else if nodeB.name == "bulletBullet"{
                nodeB.removeFromParent()
            }
            
            //check for obstacles and bullets
        } else if (nodeA.name == "bullet" || nodeB.name == "bullet" ) && (nodeA.name == "obstacle" || nodeA.name == "obstacle2" || nodeA.name == "obstacle3" || nodeB.name == "obstacle" || nodeB.name == "obstacle2" || nodeB.name == "obstacle3") {
            points += 1
            pointsLabel.text = String(points)
            damages.position = nodeA.convertPoint(CGPoint(x: 0, y: 0), toNode: obstacleLayer)
            particles.position = damages.position
            obstacleLayer.addChild(damages)
            obstacleLayer.addChild(particles)
            nodeA.removeFromParent()
            nodeB.removeFromParent()
            particles.numParticlesToEmit = 25
//            AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
            
            //obstacles and player
        } else {
            
            if (nodeA.name == "obstacle" && nodeB == player) || (nodeA.name == "obstacle2" && nodeB == player) {
                health -= 0.2
                points -= 1
                pointsLabel.text = String(points)
                damages.position = nodeA.convertPoint(CGPoint(x: 0, y: 0), toNode: obstacleLayer)
                particles.position = damages.position
                nodeA.removeFromParent()
                obstacleLayer.addChild(damages)
                obstacleLayer.addChild(particles)
                
                /* Restrict total particles to reduce runtime of particle */
                particles.numParticlesToEmit = 25
                AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
            }
            
            if (nodeB.name == "obstacle"  && nodeA == player) || (nodeB.name == "obstacle2" && nodeA == player) {
                health -= 0.2
                points -= 1
                pointsLabel.text = String(points)
                damages.position = nodeB.convertPoint(CGPoint(x: 0, y: 0), toNode: obstacleLayer)
                particles.position = damages.position
                nodeB.removeFromParent()
                obstacleLayer.addChild(damages)
                obstacleLayer.addChild(particles)
                
                /* Restrict total particles to reduce runtime of particle */
                particles.numParticlesToEmit = 25
                AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
            }
            
        }
        
    }
}