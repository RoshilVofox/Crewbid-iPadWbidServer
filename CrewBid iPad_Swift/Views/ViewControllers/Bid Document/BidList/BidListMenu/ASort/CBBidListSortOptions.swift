//
//  CBBidListSortOptions.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 26/03/25.
//

import UIKit

protocol CBSortOptionDelegate {
    func didTappedAwardSort(isOn: Bool)
    func didTappedSubmitSort(isOn: Bool)
}

class CBBidListSortOptions: UIViewController {
    
    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var popBackView: UIView!
    @IBOutlet weak var popBackTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var popViewTrailing: NSLayoutConstraint!
    @IBOutlet weak var awardSortButton: CBCheckButton!
    @IBOutlet weak var submitSortButton: CBCheckButton!
    
    var yAxis: CGFloat!
    var xAxis: CGFloat!
    var isAwardSortSelected: Bool = false
    var isSubmitOredrSortSelected: Bool = false
    var Delegate: CBSortOptionDelegate?
    let highlightedColor = UIColor(red: 244/255, green: 162/255, blue: 62/255, alpha: 1.0)
    let lightGrayColor = UIColor(rgb: 0xEBEBF0)
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        if isAwardSortSelected {
            awardSortButton.isChecked = true
            awardSortButton.backgroundColor = highlightedColor
            awardSortButton.setTitleColor(.black, for: .normal)
        } else {
            awardSortButton.isChecked = false
            awardSortButton.backgroundColor = lightGrayColor
        }
        if isSubmitOredrSortSelected {
            submitSortButton.isChecked = true
            submitSortButton.backgroundColor = highlightedColor
            submitSortButton.setTitleColor(.black, for: .normal)
        } else {
            submitSortButton.isChecked = false
            submitSortButton.backgroundColor = lightGrayColor
        }
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
    
    @IBAction func awardSortBtnAction(_ sender: Any) {
        self.removeFromParent()
        self.view.isHidden = true
        awardSortButton.isChecked = !awardSortButton.isChecked
        submitSortButton.isChecked = false
        // Notify the delegate about the sorting action.

        if self.isAwardSortSelected {
            self.Delegate?.didTappedAwardSort(isOn: false)
        } else {
            if self.isSubmitOredrSortSelected {
                self.isSubmitOredrSortSelected = false
            }
            self.Delegate?.didTappedAwardSort(isOn: true)
        }
    }
    
    @IBAction func submitSortBtnAction(_ sender: Any) {
        self.removeFromParent()
        self.view.isHidden = true
        submitSortButton.isChecked = !submitSortButton.isChecked
        awardSortButton.isChecked = false
        // Notify the delegate about the sorting action.

        if self.isSubmitOredrSortSelected {
            self.Delegate?.didTappedSubmitSort(isOn: false)
        } else {
            if self.isAwardSortSelected {
                self.isAwardSortSelected = false
            }
            self.Delegate?.didTappedSubmitSort(isOn: true)
        }
    }
    
}
