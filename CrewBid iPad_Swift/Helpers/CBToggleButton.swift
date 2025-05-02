//
//  CGToggleButton.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 21/03/25.
//

import Foundation
import UIKit

// Protocol to notify when the state of the button changes

protocol GRButtonDelegate {
    func didChangeState(state: Bool)
}
// Custom toggle button class

class CBToggleButton: UIButton {
    
    var customSelected = false
    
    func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        if isEnabled {
            customSelected = !customSelected
            isHighlighted = customSelected
            sendActions(for: .touchUpInside)
        }
    }
    
}
// Custom round button class

class GRRoundButton: UIButton {
    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = self.frame.height / 2
        self.layer.masksToBounds = true
    }
}
// Custom checkbox button class

class GRCheckButton: GRRoundButton {
    private var returnSelect: Bool!
    private var returnHighlight: Bool!
    private var selectionView = UIView()
    var selectionColor: UIColor = .red
    var highlightColor: UIColor = .red
    var Delegate: GRButtonDelegate?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.borderColor = UIColor.lightGray.cgColor
        self.layer.borderWidth = 2
        selectionView.frame = CGRect(x: 4, y: 4, width: self.frame.width - 8, height: self.frame.height - 8)
        selectionView.layer.cornerRadius = selectionView.frame.height / 2
        selectionView.layer.masksToBounds = true
        self.addSubview(selectionView)
//        self.titleLabel?.text = ""
        if seleciontState {
            selectionView.backgroundColor = selectionColor
        } else {
            selectionView.backgroundColor = .clear
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.highlight = true
    }
    
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        self.highlight = false
        self.seleciontState = !self.seleciontState
        if let delegate = self.Delegate {
            delegate.didChangeState(state: self.seleciontState)
        }
    }
    
//    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
//        super.touchesCancelled(touches, with: event)
//        self.highlight = false
//        self.seleciontState = !self.seleciontState
//    }
    
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        self.highlight = false
    }
    
    
    var highlight: Bool {
        get {
            return returnHighlight
        }
        set(newVlaue) {
            returnHighlight = newVlaue
            if newVlaue {
                self.backgroundColor = highlightColor
            } else {
                self.backgroundColor = .clear
            }
        }
    }
    
    var seleciontState: Bool {
        get {
            return returnSelect ?? false
        }
        set(newValue) {
            returnSelect = newValue
            if newValue {
                DispatchQueue.main.async {
                    self.selectionView.backgroundColor = self.selectionColor
                }
            } else {
                DispatchQueue.main.async {
                    self.selectionView.backgroundColor = .clear
                }
            }
        }
    }
}

// Custom checkbox button class

class CheckBox: UIButton {
    // Images
    let checkedImage = UIImage(named: "RadioButton-On")! as UIImage
    let uncheckedImage = UIImage(named: "radioButton-Off")! as UIImage
    
    // Bool property
    var isChecked: Bool = false {
        didSet {
            if isChecked == true {
                self.setImage(checkedImage, for: UIControl.State.normal)
            } else {
                self.setImage(uncheckedImage, for: UIControl.State.normal)
            }
        }
    }
        
    override func awakeFromNib() {
        self.addTarget(self, action:#selector(buttonClicked(sender:)), for: UIControl.Event.touchUpInside)
        self.isChecked = false
    }
        
    @objc func buttonClicked(sender: UIButton) {
        if sender == self {
            isChecked = !isChecked
        }
    }
}
