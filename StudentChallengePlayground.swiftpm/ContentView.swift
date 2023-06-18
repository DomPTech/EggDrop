import SwiftUI
import SpriteKit
import UIKit

let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)

func applyImpact(with strength: CGFloat) {
    feedbackGenerator.impactOccurred(intensity: strength)
}

struct ContentView: View {
    @State var shouldPresentSheet = true

    var scene: SKScene {
        guard let scene = HomeScene(fileNamed: "HomeScene.sks") else { fatalError("Missing Home Scene.")}
        scene.scaleMode = .aspectFill
        return scene
    }

    var body: some View {
        ZStack {
            SpriteView(scene: scene)
                .sheet(isPresented: $shouldPresentSheet) {
                    VStack {
                        SheetView()
                            .padding()
                        Button {
                            shouldPresentSheet.toggle()
                            feedbackGenerator.prepare()
                            applyImpact(with: 0.8)
                        } label: {
                            Text("Okay")
                                .font(Font.custom("Marker Felt", size: 20))
                                .padding()
                                .background(Color.orange)
                                .cornerRadius(10, antialiased: true)
                                .foregroundColor(.white)
                        }
                        .padding()
                    }
                }
        }
    }
}

struct SheetView: View {
    var body: some View {
        ScrollView {
            VStack {
                Text("WELCOME TO EGG DROP")
                    .fontWeight(.bold)
                    .padding()
                    .font(Font.custom("Marker Felt", size: 50))
                Text(
    """
    • Dodge and destroy the eggs to survive!
    • Swipe on the left side of the screen to move in any direction.
    • Click on the right side of the screen to make a joystick, move the joystick to slow down time and aim your shots, and release the joystick to fire.
    • Destroy eggs to gain points and increase your combo meter.
    • The combo meter increases the amount of points you get from each egg, but it expires if you don't destroy another egg within 3 seconds.
    • Destroy special-looking eggs to gain different power-ups. 
    • Pickup fire boxes to restore your shots.
    """
                )
                .padding()
                .font(Font.custom("Marker Felt", size: 25))
                .background(Color.brown)
                .cornerRadius(10.0, antialiased: true)
                .foregroundColor(.white)
            }
        }
        .modify {
            if #available(macCatalyst 16, *), #available(iOS 16.0, *) {
                $0.scrollIndicators(.visible)
            } else {
                $0 // watchOS 6 fallback
            }
        }
    }
}

extension View {
    func modify<T: View>(@ViewBuilder _ modifier: (Self) -> T) -> some View {
        return modifier(self)
    }
}
