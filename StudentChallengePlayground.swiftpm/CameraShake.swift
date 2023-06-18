//
//  CameraShake.swift
//  StudentChallenge2023
//
//  Created by Dominick Pelaia on 4/10/23.
//

import Foundation
import SpriteKit

extension SKAction {
    class func shake(duration: CGFloat, amplitudeX: Int = 12, amplitudeY: Int = 3) -> SKAction {
        let numOfShakes = duration / 0.015
        let dy = CGFloat(CGFloat(arc4random_uniform(UInt32(amplitudeY))) - CGFloat(amplitudeY / 2))
        let forward = SKAction.moveBy(x: 0, y: CGFloat(dy), duration: 0.015)
        let reverse = forward.reversed()
        let rotate = SKAction.rotate(byAngle: 0.05, duration: 0.015)
        let reversedRotate = rotate.reversed()
        let group1 = SKAction.group([forward, rotate])
        let group2 = SKAction.group([reverse, reversedRotate])
        return SKAction.repeat(SKAction.sequence([group1, group2]), count: Int(numOfShakes))
    }
}
