//
//  CBLIneValueView.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 16/04/25.
//

import Foundation
import UIKit

class CBLineValueView: UIView {
    
    private weak var titleLabel: UILabel?
    private weak var valueLabel: UILabel?
    
    let kCBLineValueViewWidth: CGFloat = 55.0
    let kCBLineValueViewHeight: CGFloat = 28.0
    
    func initWithFrame(aRect: CGRect) -> CBLineValueView {
        let viewFrame = CGRect(x: 0.0, y: 0.0, width: kCBLineValueViewWidth, height: kCBLineValueViewHeight)
        self.frame = viewFrame
        var label = UILabel(frame: CGRect(x: 0.0, y: 0.0, width: kCBLineValueViewWidth, height: 14.0))
        addSubview(label)
        titleLabel = label
        titleLabel?.translatesAutoresizingMaskIntoConstraints = false
        titleLabel?.textColor = UIColor.lightGray
        titleLabel?.font = UIFont(name: "Helvetica-Bold", size: 10)
        titleLabel?.textAlignment = .center
        titleLabel?.backgroundColor = UIColor.clear
        label = UILabel(frame: CGRect(x: 0.0, y: 14.0, width: kCBLineValueViewWidth, height: 14.0))
        addSubview(label)
        valueLabel?.translatesAutoresizingMaskIntoConstraints = false
        valueLabel = label
        valueLabel?.textColor = UIColor.darkGray
        valueLabel?.font = UIFont(name: "Helvetica-Bold", size: 12)
        valueLabel?.textAlignment = .center
        valueLabel?.backgroundColor = UIColor.clear
        let views = [
            "titleLabel" : titleLabel,
            "valueLabel" : valueLabel
        ]
        
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(0)-[titleLabel]-(0)-|", options: [], metrics: nil, views: views as [String : Any]))
        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(0)-[valueLabel]-(0)-|", options: [], metrics: nil, views: views as [String : Any]))
//        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(0)-[titleLabel]", options: [], metrics: nil, views: views as [String : Any]))
//        self.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(0)-[valueLabel]", options: [], metrics: nil, views: views as [String : Any]))
        
        return self
    }

    
    func setValue(value: String?, forTitle title: String?, andType type: CBLineValueTypes) {
        
        valueLabel?.text = value
        titleLabel?.text = title
        
        let vacTitleColor = UIColor(named: "lineValueVacationColor")?.withAlphaComponent(0.7)
        let vacValueColor = UIColor(named: "lineValueVacationColor")
        
        if ((type.rawValue > 25 && type.rawValue < 39) || type.rawValue == 42 || type.rawValue == 68 || type.rawValue == 50 || type.rawValue == 52 || type.rawValue == 53 || (type.rawValue >= 58 && type.rawValue <= 63)) {
            
            if (type.rawValue == 42) { // vDiff - Vacation Difference line value
                let FloatValue = (value! as String).floatValue
                if FloatValue > 0.0 {
                    titleLabel?.textColor = vacTitleColor
                    valueLabel?.textColor = CBColor.greenColor()
                } else if FloatValue < 0.0 {
                    titleLabel?.textColor = vacTitleColor
                    valueLabel?.textColor = UIColor.red
                } else {
                    titleLabel?.textColor = vacTitleColor
                    valueLabel?.textColor = vacValueColor
                }
            } else {
                titleLabel?.textColor = vacTitleColor
                valueLabel?.textColor = vacValueColor
            }
            
        } else {
            
            if #available(iOS 13.0, *) {
                titleLabel?.textColor = UIColor.systemGray
                valueLabel?.textColor = UIColor.label
            } else {
                titleLabel?.textColor = UIColor.lightGray
                valueLabel?.textColor = UIColor.darkGray
            }
        }
    }
    

    
    func intrinsicContentSize()-> CGSize {
        return CGSize(width: kCBLineValueViewWidth, height: kCBLineValueViewHeight)
    }
    
}

extension String {
    var floatValue: Float {
        return (self as NSString).floatValue
    }
}

extension Int {
    var asNSNumber: NSNumber {
        return NSNumber(value: self as Int)
    }

}
