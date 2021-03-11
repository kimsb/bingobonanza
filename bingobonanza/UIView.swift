//
//  UIView.swift
//  bingobonanza
//
//  Created by Kim Stephen Bovim on 21/01/2020.
//  Copyright © 2020 Kim Stephen Bovim. All rights reserved.
//

import UIKit

extension UIView {
    
    func fadeOutAnimation(duration: TimeInterval = 0.5, delay: TimeInterval = 0.0, completion: @escaping (Bool) -> Void = {(finished: Bool) -> Void in}) {
        UIView.animate(withDuration: duration, delay: delay, options: UIView.AnimationOptions.curveEaseIn, animations: {
            self.alpha = 0.0
            self.transform = CGAffineTransform(scaleX: 7, y: 7)
        }, completion: completion)
    }
    
}
