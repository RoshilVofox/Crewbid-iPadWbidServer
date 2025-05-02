//
//  CBBidListSortOptions.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 26/03/25.
//

import UIKit

//protocol CBSortOptionDelegate {
//    func didTappedAwardSort(isOn: Bool)
//    func didTappedSubmitSort(isOn: Bool)
//}

class CBBidListSortOptions: UIViewController {

    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var popBackView: UIView!
    @IBOutlet weak var popBackTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var popViewTrailing: NSLayoutConstraint!
    @IBOutlet weak var awardSortButton: CBCheckButton!
    @IBOutlet weak var submitSortButton: CBCheckButton!
    
    var yAxis: CGFloat!
    var xAxis: CGFloat!

//    var Delegate: CBSortOptionDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
   setupUI()
    }
    func setupUI() {
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        //A-Sort UI
        // Apply a rounded mask to the popBackView.
        let maskLayer = CAShapeLayer()
        maskLayer.path = UIBezierPath(roundedRect: self.popBackView.bounds, byRoundingCorners: [.topLeft, .bottomLeft, .bottomRight], cornerRadii: CGSize(width: 15, height: 10)).cgPath
        self.popBackView.layer.mask = maskLayer
        // Adjust constraints for positioning.
        popBackTopConstraint.constant = yAxis / 2
        popViewTrailing.constant = yAxis + 35.0
        // Add a tap gesture recognizer to the background view to dismiss the view controller.
        backView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissVC)))
    }
    @objc private func dismissVC() {
        self.removeFromParent()
        self.view.isHidden = true
    }
}
