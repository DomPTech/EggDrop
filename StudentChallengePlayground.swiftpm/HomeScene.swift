//
//  HomeScene.swift
//  StudentChallengePlayground
//
//  Created by Dominick Pelaia on 4/13/23.
//

import Foundation
import SpriteKit

class HomeScene: SKScene {
    private let playClickSoundAction = SKAction.playSoundFileNamed("ClickSound.m4a", waitForCompletion: false)

    override func didMove(to view: SKView) {
        guard let playButton = self.childNode(withName: "PlayButton") else { return }
        
        playButton.run(SKAction.repeatForever(SKAction.sequence([
            .fadeOut(withDuration: 0.8),
            .fadeIn(withDuration: 0.8),
            .wait(forDuration: 0.4)
        ])))
        
        let highScore = UserDefaults.standard.integer(forKey: "highScore")
        
        let highScoreLabel = SKLabelNode(fontNamed: "Marker Felt Wide")
        highScoreLabel.text = "HIGH SCORE: \(highScore)"
        highScoreLabel.position.y = -270
        highScoreLabel.fontSize = 80
        addChild(highScoreLabel)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.run(playClickSoundAction)
        applyImpact(with: 0.8)
        
        let transition = SKTransition.doorsOpenHorizontal(withDuration: 1.0)
        
        guard let scene = GameScene(fileNamed: "GameScene") else { return }
        scene.scaleMode = .aspectFill
        
        view?.presentScene(scene, transition: transition)
    }
}
