//
//  CGFloatExtensions.swift
//  StudentChallengePlayground
//
//  Created by Dominick Pelaia on 4/12/23.
//

import Foundation
import CoreGraphics

public extension CGFloat {
    mutating func clamp(_ lower: CGFloat, _ upper: CGFloat) {
        self = Self.minimum(upper, Self.maximum(self, lower))
    }
    
    func convertDegreesToRadians() -> CGFloat {
        return CGFloat.pi * self / 180.0
    }
    
    func convertRadiansToDegrees() -> CGFloat {
        return self * 180.0 / CGFloat.pi
    }
}


@propertyWrapper
struct Clamp {
    let lower: CGFloat
    let upper: CGFloat
    var value: CGFloat
    var wrappedValue: CGFloat {
        get { value }
        set { value = CGFloat.minimum(upper, CGFloat.maximum(newValue, lower)) }
    }
    
    init(wrappedValue: CGFloat, lower: CGFloat, upper: CGFloat) {
        self.lower = lower
        self.upper = upper
        self.value = wrappedValue
        self.wrappedValue = wrappedValue
    }
}
