//
//  GameScene.swift
//  StudentChallenge2023
//
//  Created by Dominick Pelaia on 4/10/23.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, JoystickDelegate {
    private let joyStick = Joystick()
    private var joyStickDirection: Direction?
    private var joyStickDistanceFromOrigin = 0.0
    
    private var swipeTouch: UITouch?
    private var moveAmtY: CGFloat = 0
    private var moveAmtX: CGFloat = 0
    private var initialPosition: CGPoint?
    
    private let maxSwipeDistanceY = 350.0
    private let maxSwipeDistanceX = 350.0
    
    private let player = SKSpriteNode(imageNamed: "ChickenBody")
    private let dottedPath = SKSpriteNode(imageNamed: "DottedPath")
    
    private var points: Int = 0 {
        didSet {
            pointsLabel.text = "\(points)"
            
            if points >= 5000, eggDropTime > 1.25 {
                eggDropTime = 1.25
            } else if points >= 10000, eggDropTime > 1.0 {
                eggDropTime = 1.0
            } else if points >= 15000, eggDropTime > 0.75 {
                eggDropTime = 0.75
            } else if points >= 20000, eggDropTime > 0.5 {
                eggDropTime = 0.5
            }
            
            if isMovementEnabled {
                self.removeAction(forKey: "makeFallingEggs")
                self.run(SKAction.repeatForever(SKAction.sequence([
                    .wait(forDuration: eggDropTime),
                    .run { [weak self] in
                        self?.makeFallingEggs()
                    }
                ])), withKey: "makeFallingEggs")
            }
        }
    }
    
    private let pointsLabel = SKLabelNode(fontNamed: "Marker Felt Wide")
    
    private let sceneCamera = SKCameraNode()
    
    private var ammo: Int = 3 {
        didSet {
            ammoCounter.alpha = 1.0

            if ammo == 3 {
                ammoCounter.run(SKAction.setTexture(SKTexture(imageNamed: "FullAmmo"), resize: true))
            } else if ammo == 2 {
                ammoCounter.run(SKAction.setTexture(SKTexture(imageNamed: "TwoAmmo"), resize: true))
            } else if ammo == 1 {
                ammoCounter.run(SKAction.setTexture(SKTexture(imageNamed: "OneAmmo"), resize: true))
            } else {
                ammoCounter.alpha = 0.0
            }
        }
    }
    
    private let ammoCounter = SKSpriteNode(imageNamed: "FullAmmo")
    
    private var comboMeter: Int = 0 {
        didSet {
            if comboMeter == 1 {
                comboLabel.fontColor = .systemYellow
            } else if comboMeter == 2 {
                comboLabel.fontColor = .systemOrange
            } else if comboMeter >= 3 {
                comboLabel.fontColor = .systemRed
            } else {
                comboLabel.fontColor = .white
            }
            
            comboLabel.text = "COMBO: \(comboMeter)"
        }
    }
    
    private let comboLabel = SKLabelNode(fontNamed: "Marker Felt Wide")
    private let comboBar = SKSpriteNode(color: .orange, size: CGSize(width: 600, height: 50))
    
    private var isFrogBall = false
    private var isEnergized = false
    private var isShielded = false
    
    private var eggDropTime = 1.5
    
    private let chickenWing = SKSpriteNode(imageNamed: "ChickenWing")
    private let chickenEyes = SKSpriteNode(imageNamed: "ChickenEyes")
    
    private let fireShader = SKShader(fileNamed: "FragShader.fsh")
    
    private let bouncingLabel = SKLabelNode(fontNamed: "Marker Felt Wide")
    private let energizeLabel = SKLabelNode(fontNamed: "Marker Felt Wide")
    private let shieldLabel = SKLabelNode(fontNamed: "Marker Felt Wide")
    
    private let playCrackingSoundAction = SKAction.playSoundFileNamed("EggCracking.m4a", waitForCompletion: false)
    private let playAttackSoundAction = SKAction.playSoundFileNamed("AttackSound.m4a", waitForCompletion: false)
    private let playPickupSoundAction = SKAction.playSoundFileNamed("PickupSound.m4a", waitForCompletion: false)
    private let playClickSoundAction = SKAction.playSoundFileNamed("ClickSound.m4a", waitForCompletion: false)
    
    private let retryButton = SKSpriteNode(imageNamed: "RetryButton")
    private let homeButton = SKSpriteNode(imageNamed: "HomeButton")
    
    private var isMovementEnabled = true
    
    private let vignette = SKSpriteNode(imageNamed: "Vignette")
    
    private let maxAmmoOnScreen = 9
    private var ammoOnScreen = 0
    
    override func didMove(to view: SKView) {
        joyStick.delegate = self
        joyStick.isUserInteractionEnabled = true
        joyStick.controller.size = CGSize(width: 400, height: 400)
        joyStick.position = CGPoint(x: -450, y: -285)
        joyStick.zPosition = 20
        joyStick.setScale(1.75)
        addChild(joyStick)
        
        view.ignoresSiblingOrder = true
        view.shouldCullNonVisibleNodes = false
        view.isMultipleTouchEnabled = true
        
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        player.physicsBody?.isDynamic = true
        player.physicsBody?.affectedByGravity = true
        player.physicsBody?.collisionBitMask = 2
        player.physicsBody?.categoryBitMask = 1
        player.physicsBody?.allowsRotation = false
        player.physicsBody?.linearDamping = 0.0
        player.physicsBody?.mass = 0.5
        addChild(player)
        
        chickenEyes.position = CGPoint(x: -50, y: 15)
        chickenEyes.zPosition = 1
        chickenEyes.run(SKAction.repeatForever(SKAction.sequence([
            .wait(forDuration: 2.0),
            .scaleY(to: 0.0, duration: 0.2),
            .scaleY(to: 1.0, duration: 0.2)
        ])))
        player.addChild(chickenEyes)
        
        chickenWing.position = CGPoint(x: 10, y: -20)
        chickenWing.anchorPoint = CGPoint(x: 0.4, y: 0.7)
        chickenWing.zPosition = 1
        chickenWing.run(SKAction.repeatForever(SKAction.sequence([
            .rotate(toAngle: -0.2, duration: 0.1),
            .rotate(toAngle: 0, duration: 0.1),
            .wait(forDuration: 0.1)
        ])))
        player.addChild(chickenWing)
        
        let constraintX = SKRange(lowerLimit: -1000, upperLimit: 1000)
        let constraintY = SKRange(lowerLimit: -700, upperLimit: 700)
        player.constraints = [SKConstraint.positionX(constraintX, y: constraintY)]
        
        dottedPath.alpha = 0.0
        dottedPath.size.height = 600
        dottedPath.anchorPoint.y = 0.0
        player.addChild(dottedPath)
        
        self.run(SKAction.repeatForever(SKAction.sequence([
            .wait(forDuration: eggDropTime),
            .run { [weak self] in
                self?.makeFallingEggs()
            }
        ])), withKey: "makeFallingEggs")
        
        self.run(SKAction.repeatForever(SKAction.sequence([
            .wait(forDuration: 1.75),
            .run(spawnAmmo)
        ])))
        
        pointsLabel.fontSize = 200
        pointsLabel.zPosition = -1
        pointsLabel.text = "0"
        pointsLabel.alpha = 0.5
        addChild(pointsLabel)
        
        sceneCamera.setScale(1.75)
        scene?.camera = sceneCamera
        addChild(sceneCamera)
        
        let ammoPosition = CGPoint(x: 0, y: 200)
        let ammoCounterConstraints = SKConstraint.distance(SKRange(lowerLimit: 0, upperLimit: 0), to: ammoPosition, in: player)
        ammoCounter.constraints = [ammoCounterConstraints]
        ammoCounter.zPosition = 2
        addChild(ammoCounter)
        
        comboLabel.position.y = -200
        comboLabel.fontSize = 150
        comboLabel.zPosition = -1
        comboLabel.text = "COMBO: 0"
        comboLabel.alpha = 0.5
        addChild(comboLabel)
        
        comboBar.position.y = -250
        comboBar.size.width = 0
        addChild(comboBar)
        
        let scenePhysicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        self.physicsBody = scenePhysicsBody
        
        let fireUniforms: [SKUniform] = [
            SKUniform(name: "u_speed", float: 20),
            SKUniform(name: "u_strength", float: 3.0),
            SKUniform(name: "u_frequency", float: 15)
        ]
        
        fireShader.uniforms = fireUniforms

        let playerShader = SKShader(fileNamed: "FragShader.fsh")
        
        let playerUniforms: [SKUniform] = [
            SKUniform(name: "u_speed", float: 15),
            SKUniform(name: "u_strength", float: 1.75),
            SKUniform(name: "u_frequency", float: 10)
        ]
        
        playerShader.uniforms = playerUniforms

        player.shader = playerShader
        
        bouncingLabel.fontSize = 55
        bouncingLabel.alpha = 0.0
        bouncingLabel.position.y = 250
        addChild(bouncingLabel)
        
        energizeLabel.fontSize = 55
        energizeLabel.position.y = 300
        energizeLabel.alpha = 0.0
        addChild(energizeLabel)

        shieldLabel.fontSize = 55
        shieldLabel.position.y = 350
        shieldLabel.alpha = 0.0
        addChild(shieldLabel)
        
        vignette.color = .black
        vignette.colorBlendFactor = 1.0
        vignette.alpha = 0.0
        vignette.size = CGSize(width: self.size.width * 2, height: self.size.height * 2)
        vignette.zPosition = 10
        addChild(vignette)
    }
    
    func joystick(_ joystick: Joystick, didChangeDirection direction: Direction?, distance: CGFloat) {
        if joystick == self.joyStick {
            self.joyStickDirection = direction
            self.joyStickDistanceFromOrigin = distance
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let touchLocation = touch.location(in: self)
            
            if isMovementEnabled {
                if touchLocation.x > 0 {
                    joyStick.alpha = 1.0
                    joyStick.position = touchLocation
                    joyStick.touched(touches)
                    joyStick.activeTouch = touch
                    
                    self.physicsWorld.speed = 1.0
                    self.speed = 1.0
                    
                    dottedPath.alpha = 1.0
                    vignette.run(SKAction.fadeIn(withDuration: 0.1))
                    
                    applyImpact(with: 0.8)
                    self.run(playClickSoundAction)
                } else {
                    swipeTouch = touch
                    moveAmtY = 0
                    moveAmtX = 0
                    
                    initialPosition = touch.location(in: self)
                    
                    player.physicsBody?.velocity = CGVector.zero
                    player.physicsBody?.affectedByGravity = false
                    
                    chickenWing.run(SKAction.sequence([
                        .rotate(toAngle: CGFloat(100).convertDegreesToRadians(), duration: 0.1),
                        .rotate(toAngle: 0, duration: 0.1),
                    ]))
                    
                    player.run(SKAction.sequence([
                        .scaleY(to: 1.4, duration: 0.1),
                        .scaleY(to: 1.0, duration: 0.1)
                    ]))
                    
                    makeFlapParticles()
                }
            } else {
                let nodes = nodes(at: touchLocation)
                
                for node in nodes {
                    if node == retryButton {
                        retry()
                        applyImpact(with: 0.8)
                        self.run(playClickSoundAction)
                    } else if node == homeButton {
                        goHome()
                        applyImpact(with: 0.8)
                        self.run(playClickSoundAction)
                    }
                }
            }
        }
    }
    
    func makeFlapParticles() {
        if let flapParticles = SKEmitterNode(fileNamed: "JumpParticles") {
            flapParticles.position = player.position
            flapParticles.run(SKAction.sequence([
                .wait(forDuration: flapParticles.particleLifetime),
                .removeFromParent()
            ]))
            addChild(flapParticles)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if joyStick.alpha == 1.0, joyStick.activeTouch == touch {
                if !joyStick.handleTouchesMoved(touches) {
                    super.touchesMoved(touches, with: event)
                }
                
                let angle = atan2(joyStick.controller.position.y - joyStick.controllerBoundBorder.position.y, joyStick.controller.position.x - joyStick.controllerBoundBorder.position.x)
                player.run(SKAction.rotate(toAngle: angle - CGFloat.pi / 2, duration: 0.033, shortestUnitArc: true))
                
                self.physicsWorld.speed = 0.25
                self.speed = 0.25
            }

            if let swipeTouch = swipeTouch {
                if touches.contains(swipeTouch) {
                    let movingPoint = touch.location(in: self)
                    
                    if let initialPosition = initialPosition {
                        if moveAmtX < 0 {
                            moveAmtX = max(movingPoint.x - initialPosition.x, -maxSwipeDistanceX)
                        } else {
                            moveAmtX = min(movingPoint.x - initialPosition.x, maxSwipeDistanceX)
                        }
                        
                        if moveAmtY < 0 {
                            moveAmtY = max(movingPoint.y - initialPosition.y, -maxSwipeDistanceY)
                        } else {
                            moveAmtY = min(movingPoint.y - initialPosition.y, maxSwipeDistanceY)
                        }
                    }
                }
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if joyStick.alpha == 1.0, joyStick.activeTouch == touch {
                shoot(in: player.zRotation)
                resetPlayer()
            }
        }

        if !joyStick.handleTouchesEnded(touches) {
            super.touchesEnded(touches, with: event)
        }
        
        if let swipeTouch = swipeTouch {
            if touches.contains(swipeTouch) {
                self.swipeTouch = nil
                moveAmtX = 0
                moveAmtY = 0
                initialPosition = nil
                
                player.physicsBody?.affectedByGravity = true
            }
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if joyStick.alpha == 1.0, joyStick.activeTouch == touch {
                shoot(in: player.zRotation)
                resetPlayer()
            }
        }

        if !joyStick.handleTouchesEnded(touches) {
            super.touchesCancelled(touches, with: event)
        }
                        
        if let swipeTouch = swipeTouch {
            if touches.contains(swipeTouch) {
                self.swipeTouch = nil
                moveAmtX = 0
                moveAmtY = 0
                initialPosition = nil
                
                player.physicsBody?.affectedByGravity = true
            }
        }
    }
    
    func resetPlayer() {
        self.physicsWorld.speed = 1.0
        self.speed = 1.0
        dottedPath.alpha = 0.0
        vignette.run(SKAction.fadeOut(withDuration: 0.1))
    }
    
    func shoot(in angle: CGFloat) {
        if !isEnergized {
            guard ammo >= 1 else { return }
            
            ammo -= 1
        }
        
        player.run(SKAction.sequence([
            .scaleY(to: 0.3, duration: 0.1),
            .scaleY(to: 1.0, duration: 0.1)
        ]))
        
        let newAngle = angle + CGFloat.pi / 2
        
        let fireball = SKSpriteNode(imageNamed: "Fireball")
        fireball.zRotation = newAngle
        fireball.setScale(0.6)
        fireball.run(SKAction.sequence([
            .move(by: CGVector(dx: 500 * cos(newAngle), dy: 500 * sin(newAngle)), duration: 0.5),
            .removeFromParent()
        ]))
        fireball.position = player.position
        fireball.name = "fireball"
        fireball.blendMode = .add
        addChild(fireball)
        
        if isFrogBall {
            fireball.physicsBody = SKPhysicsBody(circleOfRadius: 100)
            fireball.physicsBody?.restitution = 1.0
            fireball.physicsBody?.affectedByGravity = true
            fireball.physicsBody?.isDynamic = true
            fireball.physicsBody?.mass = 0.1
            fireball.physicsBody?.linearDamping = 0.0
            fireball.physicsBody?.collisionBitMask = 2
            fireball.physicsBody?.categoryBitMask = 1
            fireball.physicsBody?.contactTestBitMask = 1
            fireball.physicsBody?.applyImpulse(CGVector(dx: 500 * cos(newAngle), dy: 500 * sin(newAngle)))

            fireball.removeAllActions()
            fireball.run(SKAction.sequence([
                .wait(forDuration: 2.8),
                .fadeOut(withDuration: 0.2),
                .removeFromParent()
            ]))
        }
        
        fireball.shader = fireShader
        
        if let fireTrail = SKEmitterNode(fileNamed: "WeaponTrail") {
            fireTrail.targetNode = self
            fireball.addChild(fireTrail)
        }
        
        sceneCamera.run(SKAction.shake(duration: 0.1, amplitudeX: 50, amplitudeY: 50))
        self.run(playAttackSoundAction)
    }
    
    func makeFallingEggs(bouncing: Bool = false) {
        let randomTextures = [
            "regularBall", "regularBall", "regularBall",
            "regularBall", "regularBall", "regularBall",
            "regularBall", "regularBall", "regularBall",
            "regularBall", "regularBall", "regularBall",
            "regularBall", "regularBall", "regularBall",
            "frogBall", "energizeBall", "shieldBall"
        ]
        let randomTexture = randomTextures.randomElement()!
        
        let egg = SKSpriteNode(imageNamed: randomTexture)
        egg.run(SKAction.repeatForever(SKAction.rotate(byAngle: 0.5, duration: 0.1)))
        egg.name = "egg"
        egg.userData = NSMutableDictionary()
        egg.userData?.setValue(randomTexture, forKey: "type")
        addChild(egg)
        
        let direction = Int.random(in: 1...3)
        
        if direction == 1 {
            egg.position.x = CGFloat(Int.random(in: -400...400))
            egg.position.y = 1000
            egg.run(SKAction.sequence([
                .moveTo(y: -1000, duration: CGFloat.random(in: 4.0...6.0)),
                .removeFromParent()
            ]))
        } else if direction == 2 {
            egg.position.x = -1000
            egg.position.y = CGFloat(Int.random(in: -200...200))
            egg.run(SKAction.sequence([
                .moveTo(x: 1000, duration: CGFloat.random(in: 4.0...6.0)),
                .removeFromParent()
            ]))
            
            if player.position.y <= -250 {
                egg.position.y = -250
            }
        } else {
            egg.position.x = 1000
            egg.position.y = CGFloat(Int.random(in: -200...200))
            egg.run(SKAction.sequence([
                .moveTo(x: -1000, duration: CGFloat.random(in: 4.0...6.0)),
                .removeFromParent()
            ]))
            
            if player.position.y <= -250 {
                egg.position.y = -250
            }
        }
        
        if bouncing {
            let randomIntegers = [-1, 1]
            let randomX = randomIntegers.randomElement()!
            let randomY = randomIntegers.randomElement()!
            
            egg.removeAllActions()
            egg.run(SKAction.repeatForever(SKAction.rotate(byAngle: 0.5, duration: 0.1)))
            egg.position.y = 300
            egg.position.x = 0
            egg.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: egg.size.width, height: egg.size.height))
            egg.physicsBody?.isDynamic = true
            egg.physicsBody?.linearDamping = 0.0
            egg.physicsBody?.affectedByGravity = false
            egg.physicsBody?.restitution = 1.0
            egg.physicsBody?.collisionBitMask = 2
            egg.physicsBody?.categoryBitMask = 1
            egg.physicsBody?.contactTestBitMask = 3
            egg.physicsBody?.velocity = CGVector(dx: 500 * randomX, dy: 500 * randomY)
        }
    }
        
    override func didEvaluateActions() {
        checkCollisions()
    }
    
    func checkCollisions() {
        enumerateChildNodes(withName: "egg") { [weak self] egg, _ in
            guard let self = self else { return }
            
            if let eggBody = egg.physicsBody {
                eggBody.velocity.dx.clamp(-500, 500)
                eggBody.velocity.dy.clamp(-500, 500)
            }
            
            let xCloseness = egg.position.x - player.position.x
            let yCloseness = egg.position.y - player.position.y
            let closeness = hypot(xCloseness, yCloseness)
            
            if egg.intersects(self.player), !isShielded {
                egg.removeFromParent()
                showLosingScreen()
            }
            
            self.enumerateChildNodes(withName: "fireball") { fireball, _ in
                if fireball.intersects(egg) {
                    guard let eggType = egg.userData?["type"] as? String else { return }
                    
                    if eggType == "frogBall" {
                        if !self.isFrogBall {
                            self.showMessage(of: "frogBall")
                            self.isFrogBall = true
                        }
                        
                        self.removeAction(forKey: "isFrog")
                        self.run(SKAction.sequence([
                            .wait(forDuration: 3.0),
                            .run {
                                self.isFrogBall = false
                            }
                        ]), withKey: "isFrog")
                    } else if eggType == "energizeBall" {
                        if !self.isEnergized {
                            self.showMessage(of: "energizeBall")
                            self.isEnergized = true
                        }
                        
                        self.removeAction(forKey: "energizeBall")
                        self.run(SKAction.sequence([
                            .wait(forDuration: 5.0),
                            .run {
                                self.isEnergized = false
                            }
                        ]), withKey: "energizeBall")
                    } else if eggType == "shieldBall" {
                        if !self.isShielded {
                            self.showMessage(of: "shieldBall")
                            self.isShielded = true
                        }
                        
                        self.removeAction(forKey: "shieldBall")
                        self.run(SKAction.sequence([
                            .wait(forDuration: 5.0),
                            .run {
                                self.isShielded = false
                            }
                        ]), withKey: "shieldBall")
                    }
                    
                    if fireball.physicsBody == nil {
                        fireball.name = "unused"
                        fireball.run(SKAction.sequence([.fadeOut(withDuration: 0.2), .removeFromParent()]))
                    }
                                        
                    egg.removeFromParent()
                    self.makeEggExplosion(at: egg.position)
                    
                    if closeness <= 300 {
                        self.getPoints(200, at: egg.position, close: true)
                    } else {
                        self.getPoints(100, at: egg.position)
                    }
                    
                    self.enumerateChildNodes(withName: "egg") { otherEgg, _ in
                        guard let otherEggType = otherEgg.userData?["type"] as? String else { return }
                        
                        let xDifference = otherEgg.position.x - egg.position.x
                        let yDifference = otherEgg.position.y - egg.position.y
                        let distance = hypot(xDifference, yDifference)
                        
                        if distance <= 200 {
                            otherEgg.removeFromParent()
                            self.makeEggExplosion(at: otherEgg.position)
                            self.getPoints(100, at: otherEgg.position)
                            
                            if otherEggType == "frogBall" {
                                if !self.isFrogBall {
                                    self.showMessage(of: "frogBall")
                                    self.isFrogBall = true
                                }
                                
                                self.removeAction(forKey: "isFrog")
                                self.run(SKAction.sequence([
                                    .wait(forDuration: 3.0),
                                    .run {
                                        self.isFrogBall = false
                                    }
                                ]), withKey: "isFrog")
                            } else if otherEggType == "energizeBall" {
                                if !self.isEnergized {
                                    self.showMessage(of: "energizeBall")
                                    self.isEnergized = true
                                }
                                
                                self.removeAction(forKey: "energizeBall")
                                self.run(SKAction.sequence([
                                    .wait(forDuration: 5.0),
                                    .run {
                                        self.isEnergized = false
                                    }
                                ]), withKey: "energizeBall")
                            } else if otherEggType == "shieldBall" {
                                if !self.isShielded {
                                    self.showMessage(of: "shieldBall")
                                    self.isShielded = true
                                }
                                
                                self.removeAction(forKey: "shieldBall")
                                self.run(SKAction.sequence([
                                    .wait(forDuration: 5.0),
                                    .run {
                                        self.isShielded = false
                                    }
                                ]), withKey: "shieldBall")
                            }
                        }
                    }
                }
            }
        }
        
        enumerateChildNodes(withName: "ammo") { [weak self] ammo, _ in
            guard let self = self else { return }

            if self.player.intersects(ammo), self.ammo < 3 {
                self.ammo += 1
                self.ammoOnScreen -= 1
                self.run(self.playPickupSoundAction)
                ammo.name = "animatedAmmo"
                ammo.run(SKAction.sequence([
                    .group([
                        .scale(to: 1.5, duration: 0.1),
                        .moveBy(x: 0, y: 200, duration: 0.1)
                    ]),
                    .group([
                        .rotate(byAngle: CGFloat(360).convertDegreesToRadians(), duration: 0.1),
                        .scale(to: 0.0, duration: 0.1),
                        .moveBy(x: 0, y: -200, duration: 0.1)
                    ]),
                    .removeFromParent()
                ]))
            }
        }
    }
    
    func spawnAmmo() {
        guard ammoOnScreen < maxAmmoOnScreen else { return }
        ammoOnScreen += 1
        
        let ammoBox = SKSpriteNode(imageNamed: "AmmoBox")
        ammoBox.name = "ammo"
        ammoBox.position.x = CGFloat(Int.random(in: -600...600))
        ammoBox.position.y = CGFloat(Int.random(in: -300...100))
        ammoBox.setScale(0.8)
        addChild(ammoBox)
        
        let rotateAndScaleAction = SKAction.group([
            .rotate(toAngle: CGFloat(30 * sign(ammoBox.position.x)).convertDegreesToRadians(), duration: 0.1),
            .scale(to: 1.2, duration: 0.1)
        ])
        rotateAndScaleAction.timingMode = .easeInEaseOut
        
        let rotateAndScaleActionReversed = SKAction.group([
            .rotate(toAngle: 0, duration: 0.2),
            .scale(to: 0.8, duration: 0.2)
        ])
        rotateAndScaleActionReversed.timingMode = .easeInEaseOut
        
        ammoBox.run(SKAction.repeatForever(SKAction.sequence([
            rotateAndScaleAction,
            rotateAndScaleActionReversed,
            .wait(forDuration: 0.5)
        ])))
    }
    
    func makeEggExplosion(at position: CGPoint) {
        if let explosion = SKEmitterNode(fileNamed: "EggExplosion") {
            explosion.position = position
            explosion.targetNode = self
            explosion.run(SKAction.sequence([.wait(forDuration: explosion.particleLifetime), .removeFromParent()]))
            addChild(explosion)
        }
    }
    
    func getPoints(_ points: Int, at position: CGPoint, close: Bool = false) {
        applyImpact(with: 1.0)

        let newPoints = points + 100 * comboMeter
        
        comboMeter += 1
        comboBar.removeAllActions()
        comboBar.size.width = 600
        comboBar.run(SKAction.resize(toWidth: 0, duration: 3.0)) {
            self.comboMeter = 0
        }
        
        let pointLabel = SKLabelNode(fontNamed: "Marker Felt Wide")
        pointLabel.fontSize = 100
        
        if close {
            pointLabel.text = "CLOSE ONE! \(newPoints)"
            pointLabel.fontSize = 80
            pointLabel.fontColor = .orange
        } else {
            pointLabel.text = "\(newPoints)"
        }
        
        pointLabel.run(SKAction.sequence([
            .move(by: CGVector(dx: -30, dy: 40), duration: 0.45),
            .wait(forDuration: 0.3),
            .scale(to: 0.0, duration: 0.2),
            .removeFromParent()
        ]))
        pointLabel.zPosition = 5
        pointLabel.position = position
        pointLabel.zRotation = CGFloat.random(in: -0.5...0.5)
        
        pointLabel.run(SKAction.sequence([
            .scaleY(to: 0.1, duration: 0.15),
            .scaleY(to: 1.0, duration: 0.15)
        ]))
        addChild(pointLabel)
        
        self.points += newPoints
        
        sceneCamera.run(SKAction.shake(duration: 0.1, amplitudeX: 100, amplitudeY: 100))
        
        self.run(playCrackingSoundAction)
    }
    
    func showMessage(of type: String) {
        let messageLabel = SKLabelNode(fontNamed: "Marker Felt Wide")
        messageLabel.fontSize = 100
        messageLabel.zPosition = 6
        messageLabel.yScale = 0.0
        messageLabel.position.y = 100
        messageLabel.run(SKAction.sequence([
            .scaleY(to: 1.0, duration: 0.1),
            .wait(forDuration: 1.0),
            .scaleY(to: 0.0, duration: 0.1),
            .removeFromParent()
        ]))
        messageLabel.fontColor = .systemYellow
        addChild(messageLabel)
        
        let messageCopy = messageLabel.copy() as! SKLabelNode
        messageCopy.alpha = 1.0
        messageCopy.fontColor = .brown
        messageCopy.zPosition = -1
        messageCopy.position.x = 5
        messageCopy.position.y = -5
        messageLabel.addChild(messageCopy)
        
//        let blur = SKSpriteNode(color: .black, size: vignette.size)
//        blur.zPosition = 5
//        blur.alpha = 0.3
//        blur.run(SKAction.sequence([
//            .wait(forDuration: 1.0),
//            .fadeOut(withDuration: 0.2),
//            .removeFromParent()
//        ]))
//        addChild(blur)
                
        var counter = 5

        if type == "frogBall" {
            messageLabel.text = "BOUNCING FIREBALLS FOR 3 SECONDS"
            
            counter = 3
            bouncingLabel.removeAllActions()
            bouncingLabel.text = "BOUNCING: \(counter)"
            bouncingLabel.alpha = 0.5
            bouncingLabel.run(SKAction.repeat(SKAction.sequence([
                .wait(forDuration: 1.0),
                .run { [weak self] in
                    counter -= 1
                    self?.bouncingLabel.text = "BOUNCING: \(counter)"
                }
            ]), count: counter + 1)) { [weak self] in
                self?.bouncingLabel.alpha = 0.0
            }
        } else if type == "energizeBall" {
            messageLabel.text = "INFINITE AMMO FOR 5 SECONDS"
            
            counter = 5
            energizeLabel.removeAllActions()
            energizeLabel.text = "INFINITE AMMO: \(counter)"
            energizeLabel.alpha = 0.5
            energizeLabel.run(SKAction.repeat(SKAction.sequence([
                .wait(forDuration: 1.0),
                .run { [weak self] in
                    counter -= 1
                    self?.energizeLabel.text = "INFINITE AMMO: \(counter)"
                }
            ]), count: counter + 1)) { [weak self] in
                self?.energizeLabel.alpha = 0.0
            }
        } else if type == "shieldBall" {
            messageLabel.text = "INVICIBILITY FOR 5 SECONDS"
            
            counter = 5
            shieldLabel.removeAllActions()
            shieldLabel.text = "SHIELD: \(counter)"
            shieldLabel.alpha = 0.5
            shieldLabel.run(SKAction.repeat(SKAction.sequence([
                .wait(forDuration: 1.0),
                .run { [weak self] in
                    counter -= 1
                    self?.shieldLabel.text = "SHIELD: \(counter)"
                }
            ]), count: counter + 1)) { [weak self] in
                self?.shieldLabel.alpha = 0.0
            }
        }
        
        messageCopy.text = messageLabel.text
    }
        
    func showLosingScreen() {
        guard isMovementEnabled else { return }
        
        self.removeAllActions()
        
        isMovementEnabled = false
        
        enumerateChildNodes(withName: "ammo") { ammo, _ in
            ammo.removeFromParent()
        }
        
        enumerateChildNodes(withName: "egg") { egg, _ in
            egg.removeFromParent()
        }
        
        sceneCamera.run(SKAction.shake(duration: 0.1, amplitudeX: 100, amplitudeY: 100))

        joyStick.snapBack()
        resetPlayer()
        
        ammoCounter.removeFromParent()
        pointsLabel.removeFromParent()
        comboLabel.removeFromParent()
        comboBar.removeFromParent()
        bouncingLabel.removeFromParent()
        shieldLabel.removeFromParent()
        energizeLabel.removeFromParent()

        player.physicsBody = nil
        player.removeAllActions()
        player.yScale = 1.0
        player.xScale = 1.0
        player.run(SKAction.repeatForever(SKAction.sequence([
            .rotate(toAngle: CGFloat(20).convertDegreesToRadians(), duration: 0.5),
            .rotate(toAngle: CGFloat(-20).convertDegreesToRadians(), duration: 0.5),
        ])))
        chickenEyes.run(SKAction.setTexture(SKTexture(imageNamed: "SwirlyEyes"), resize: true))
                
        sceneCamera.run(SKAction.group([
            .move(to: CGPoint(x: player.position.x, y: player.position.y + 100), duration: 1.0),
            .scale(to: 0.7, duration: 1.0)
        ]))
        
        let gameOverLabel = SKLabelNode(fontNamed: "Marker Felt Wide")
        gameOverLabel.text = "GAME OVER"
        gameOverLabel.fontSize = 80
        gameOverLabel.position.x = player.position.x
        gameOverLabel.position.y = player.position.y + 250
        gameOverLabel.setScale(0.0)
        addChild(gameOverLabel)
        
        let scoreLabel = SKLabelNode(fontNamed: "Marker Felt Wide")
        scoreLabel.text = "SCORE: \(points)"
        scoreLabel.fontSize = 60
        scoreLabel.position.x = player.position.x
        scoreLabel.position.y = player.position.y + 160
        scoreLabel.setScale(0.0)
        addChild(scoreLabel)
        
        let scaleAndRotateAction = SKAction.sequence([
            .wait(forDuration: 1.0),
            .group([
                .scale(to: 1.2, duration: 0.1),
                .rotate(toAngle: CGFloat(20).convertDegreesToRadians(), duration: 0.1),
            ]),
            .group([
                .scale(to: 1.0, duration: 0.1),
                .rotate(toAngle: 0, duration: 0.1),
            ])
        ])
        
        gameOverLabel.run(scaleAndRotateAction)
        scoreLabel.run(SKAction.sequence([
            .wait(forDuration: 0.5),
            scaleAndRotateAction
        ]))
        
        retryButton.run(SKAction.sequence([
            .wait(forDuration: 1.0),
            scaleAndRotateAction
        ]))
        retryButton.position.y = player.position.y
        retryButton.position.x = player.position.x - 300
        retryButton.setScale(0.0)
        addChild(retryButton)
        
        homeButton.run(SKAction.sequence([
            .wait(forDuration: 1.5),
            scaleAndRotateAction
        ]))
        homeButton.position.y = player.position.y
        homeButton.position.x = player.position.x + 300
        homeButton.setScale(0.0)
        addChild(homeButton)
        
        let transformNode = SKTransformNode()
        transformNode.position = CGPoint(x: player.position.x, y: player.position.y + 60)
        transformNode.zPosition = 5
        addChild(transformNode)
                
        let duration = 1.0
        let tilt = SKAction.customAction(withDuration: duration) { (node, elapsed) in
            let percent = elapsed / CGFloat(duration)
            transformNode.yRotation = percent * CGFloat(360).convertDegreesToRadians()
        }
        transformNode.run(SKAction.repeatForever(tilt))
        
        for i in 1...3 {
            let offset = (i - 1) * 100
            
            let star = SKSpriteNode(imageNamed: "Star")
            star.position.x = -100 + CGFloat(offset)
            transformNode.addChild(star)
            
            if star.position.x != 0 {
                star.zPosition = -10
            }
        }
        
        let highScore = UserDefaults.standard.integer(forKey: "highScore")
        
        if points > highScore {
            UserDefaults.standard.set(points, forKey: "highScore")
        }
    }
    
    func retry() {
        guard let scene = GameScene(fileNamed: "GameScene") else { return }
        scene.scaleMode = .aspectFill

        let transition = SKTransition.doorsOpenHorizontal(withDuration: 0.5)
        view?.presentScene(scene, transition: transition)
    }
    
    func goHome() {
        guard let scene = HomeScene(fileNamed: "HomeScene") else { return }
        scene.scaleMode = .aspectFill
        
        let transition = SKTransition.doorsOpenHorizontal(withDuration: 0.5)
        view?.presentScene(scene, transition: transition)
    }

    override func update(_ currentTime: TimeInterval) {
        guard let playerBody = player.physicsBody else { return }
        
        if joyStick.alpha != 1.0 {
            if moveAmtX < 0 {
                player.run(SKAction.scaleX(to: 1.0, duration: 0.1))
            } else if moveAmtX > 0 {
                player.run(SKAction.scaleX(to: -1.0, duration: 0.1))
            }
                        
            if player.position.y <= -250, joyStick.alpha != 1.0 {
                player.run(SKAction.rotate(toAngle: 0, duration: 0.1, shortestUnitArc: true))
            }
        }
                
        if playerBody.velocity.dx > 0 {
            if playerBody.velocity.dx < maxSwipeDistanceX {
                player.physicsBody?.applyImpulse(CGVector(dx: moveAmtX, dy: 0))
            }
        } else {
            if playerBody.velocity.dx > -maxSwipeDistanceX {
                player.physicsBody?.applyImpulse(CGVector(dx: moveAmtX, dy: 0))
            }
        }
        
        if playerBody.velocity.dy > 0 {
            if playerBody.velocity.dy < maxSwipeDistanceY {
                player.physicsBody?.applyImpulse(CGVector(dx: 0, dy: moveAmtY))
            }
        } else {
            if playerBody.velocity.dy > -maxSwipeDistanceY {
                player.physicsBody?.applyImpulse(CGVector(dx: 0, dy: moveAmtY))
            }
        }
    }
}

