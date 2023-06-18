//
//  Joystick.swift
//  StudentChallenge2023
//
//  Created by Dominick Pelaia on 4/10/23.
//

import Foundation
import UIKit
import SpriteKit

public enum Direction: String, Codable {
    case up
    case upRight
    case upLeft
    case right
    case left
    case down
    case downRight
    case downLeft
}

/// Receives directional updates from the Joystick.
public protocol JoystickDelegate: AnyObject {
    func joystick(_ joystick: Joystick, didChangeDirection direction: Direction?, distance: CGFloat)
}

/// Converts the user's touches to a Direction.
public class Joystick: SKNode {
        
    public weak var delegate: JoystickDelegate?
    private var currentDirection: Direction? = .none {
        didSet {
            updateViewForNewDirection()
        }
    }
    
    let bound: CGFloat = 110
        
    public let controller = SKSpriteNode()
    var controllerBoundBorder = SKShapeNode()
    
    var distanceFromOrigin = 0.0
    
    private var offset = 10.0
    
    public var activeTouch: UITouch?
    
    public override init() {
        super.init()
        
        controller.zPosition = 1
        controller.setScale(0.8)
        self.addChild(controller)
        
        let controllerConstraints = SKConstraint.distance(SKRange(upperLimit: bound), to: controllerBoundBorder)
        controller.constraints = [controllerConstraints]
        
        controllerBoundBorder = SKShapeNode(circleOfRadius: bound)
        controllerBoundBorder.fillColor = .clear
        controllerBoundBorder.strokeColor = .white
        controllerBoundBorder.lineWidth = 8.0
        self.addChild(controllerBoundBorder)
        
        updateViewForNewDirection()
        resetJoyStick()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func touched(_ touches: Set<UITouch>) {
        // Get location from the touch.
        // RawLocation is to the topLeft of the actual JoystickView.
        guard let rawLocation = touches.first?.location(in: self) else { return }

        controller.position = rawLocation
        
        let deltaX = abs(controller.position.x)
        let deltaY = abs(controller.position.y)
        
        distanceFromOrigin = hypot(deltaX, deltaY) - 20.0
        
        // Find out the Direction
        let touchDirection = checkForDirection(rawLocation)
        
        // Notify delegate if the direction has changed.
        if currentDirection != touchDirection {
            self.currentDirection = touchDirection
            delegate?.joystick(self, didChangeDirection: touchDirection, distance: distanceFromOrigin)
        }
    }
    
    private func updateViewForNewDirection() {
        let textureAtlas = SKTextureAtlas(named: "JoystickTextures")
        let imageName = "\(currentDirection?.rawValue ?? "idle")"
        controller.run(SKAction.setTexture(textureAtlas.textureNamed(imageName), resize: true))
    }
    
    /// Converts a location on the Joystick into a Direction or returns nil if it's in the middle.
    private func checkForDirection(_ location: CGPoint) -> Direction? {
        var direction: Direction? = .none
        
        // Creates a deadzone in the center of the joystick.
        let diameter = controllerBoundBorder.frame.size.width
        let deadZone = diameter * 0.2
        if abs(location.x) + abs(location.y) > deadZone {
            
            // Divides the 8 directions into even slices
            let sliceSize = diameter * 0.125
            
            // Right third of the Joystick
            if location.x >= sliceSize {
                if location.y >= sliceSize {
                    direction = .upRight
                } else if location.y <= -sliceSize {
                    direction = .downRight
                } else {
                    direction = .right
                }
                
                // Left third of the Joystick
            } else if location.x <= -sliceSize {
                if location.y >= sliceSize {
                    direction = .upLeft
                } else if location.y <= -sliceSize {
                    direction = .downLeft
                } else {
                    direction = .left
                }
                
                // Middle third of the Joystick
            } else if location.y >= 0 {
                direction = .up
            } else {
                direction = .down
            }
        }
        return direction
    }
    
    public func snapBack() {
        controller.position = CGPoint.zero
        self.alpha = 0.0
    }
    
    public func resetJoyStick() {
        currentDirection = .none
        delegate?.joystick(self, didChangeDirection: .none, distance: distanceFromOrigin)
        snapBack()
        activeTouch = nil
    }
    
    public func handleTouchesMoved(_ touches: Set<UITouch>) -> Bool {
        guard let activeTouch = self.activeTouch else { return false }
        guard touches.contains(activeTouch) else { return false }
        touched(touches)
        return true
    }
    
    public func handleTouchesEnded(_ touches: Set<UITouch>) -> Bool {
        guard let activeTouch = self.activeTouch else { return false }
        guard touches.contains(activeTouch) else { return false }
        resetJoyStick()
        return true
    }
}
