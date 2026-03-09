//
//  DocumentCell.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 20/03/25.
//

import UIKit

class DocumentCell: UICollectionViewCell {
    
    @IBOutlet weak var monthRoundLabel: UILabel!
    @IBOutlet weak var lastBidDate: UILabel!
    @IBOutlet weak var base: UILabel!
    @IBOutlet weak var baseIconView: UIImageView!
    @IBOutlet weak var position: UILabel!
    @IBOutlet weak var userIconView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var positionImageIcon: UIImageView!
    @IBOutlet weak var baseIconImage: UIImageView!
    @IBOutlet weak var imageStackViewTopConstraint: NSLayoutConstraint!
    //MARK: - Wiggle Animation
    private let kWiggleAnimationKey = "wiggle"
    // Function to start a wiggling animation on a view.
    
    func startWiggleAnimation() {
        let kWiggleAnimationAngle: CGFloat = 0.01
        // Define the starting and ending transformation for the wiggle animation.
        
        let startTransform = CATransform3DMakeRotation(-kWiggleAnimationAngle, 0, 0, 1.0)
        let endTransform = CATransform3DMakeRotation(kWiggleAnimationAngle, 0, 0, 1.0)
        let animation = CAKeyframeAnimation(keyPath: "transform")
        animation.values = [NSValue(caTransform3D: startTransform), NSValue(caTransform3D: endTransform)]
        animation.repeatCount = 100
        animation.duration = 0.125
        animation.autoreverses = true
        layer.transform = startTransform
        layer.add(animation, forKey: kWiggleAnimationKey)
    }
    // Function to stop the wiggling animation on a view.
    
    func stopWiggleAnimation() {
        layer.removeAnimation(forKey: kWiggleAnimationKey)
        layer.transform = CATransform3DMakeRotation(0.0, 0, 0, 1.0)
    }
    // Function to make a view shake.
    
    func shake() {
        let shakeAnimation = CABasicAnimation(keyPath: "transform.rotation")
        shakeAnimation.duration = 0.05
        shakeAnimation.repeatCount = 2
        shakeAnimation.autoreverses = true
        let startAngle: Float = (-2) * 3.14159/180
        let stopAngle = -startAngle
        shakeAnimation.fromValue = NSNumber(value: startAngle as Float)
        shakeAnimation.toValue = NSNumber(value: 3 * stopAngle as Float)
        shakeAnimation.autoreverses = true
        shakeAnimation.duration = 0.15
        shakeAnimation.repeatCount = 10000
        shakeAnimation.timeOffset = 290 * drand48()
        
        let layer: CALayer = self.layer
        layer.add(shakeAnimation, forKey:"shaking")
    }
    // Function to stop the shaking animation on a view.
    
    func stopShaking() {
        let layer: CALayer = self.layer
        layer.removeAnimation(forKey: "shaking")
    }
    
    func startLoading() {
            activityIndicator.isHidden = false
            activityIndicator.startAnimating()
        }

        func stopLoading() {
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
        }
}
