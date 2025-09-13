//
//  CBGlobal.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 11/09/25.
//

import Foundation
import UIKit

class CBGlobal {
    
    // MARK: - Singleton
    static let sharedObject = CBGlobal()
    private init() {}
    
    // MARK: - Top View Controller
    func currentTopViewController() -> UIViewController? {
        guard var topVC = UIApplication.shared.delegate?.window??.rootViewController else { return nil }
        while let presented = topVC.presentedViewController {
            topVC = presented
        }
        return topVC
    }
    
    // MARK: - Show Activity Indicator
    func showActivityIndicator(text: String = "", backgroundColor: UIColor = UIColor.black.withAlphaComponent(0.7)) {
        guard let topView = currentTopViewController()?.view else { return }
        
        let newView = UIView(frame: CGRect(x: topView.center.x - 140, y: topView.center.y - 50, width: 280, height: 100))
        newView.backgroundColor = backgroundColor
        newView.tag = 98
        newView.layer.cornerRadius = 8
        newView.layer.masksToBounds = true
        topView.addSubview(newView)
        
        if !text.isEmpty {
            let label = UILabel(frame: CGRect(x: 5, y: 60, width: 270, height: 30))
            label.text = text
            label.font = .boldSystemFont(ofSize: 20)
            label.textAlignment = .center
            label.textColor = .white
            newView.addSubview(label)
        }
        
        let activityIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.large)
        activityIndicator.alpha = 1.0
        activityIndicator.tag = 99
        activityIndicator.hidesWhenStopped = true
        activityIndicator.center = CGPoint(
            x: newView.bounds.width / 2,
            y: text.isEmpty ? newView.bounds.height / 2 : (newView.bounds.height / 2) - 15
        )
        newView.addSubview(activityIndicator)
        activityIndicator.startAnimating()
    }
    
    // MARK: - Hide Activity Indicator
    func hideActivityIndicator() {
        guard let topView = currentTopViewController()?.view,
              let newView = topView.viewWithTag(98) else { return }
        
        if let activityIndicator = newView.viewWithTag(99) as? UIActivityIndicatorView {
            activityIndicator.stopAnimating()
        }
        newView.removeFromSuperview()
    }
}
