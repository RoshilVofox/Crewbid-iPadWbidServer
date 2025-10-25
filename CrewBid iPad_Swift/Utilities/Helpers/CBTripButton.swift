//
//  CBTripButton.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 25/03/25.
//

import Foundation
import UIKit

class CBTripButton : UIButton {
    
    weak var otherButton: CBTripButton?
    weak var trip: BITrip?
    
    var customSelected = false
    
    func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        if self.isEnabled {
            customSelected = !customSelected
            isHighlighted = customSelected
            sendActions(for: .touchUpInside)
        }
    }
    
    func setHighlighted(_ highlighted: Bool) {
        super.isHighlighted = highlighted
        if (self.otherButton?.isHighlighted != highlighted) {
            self.otherButton?.isHighlighted = highlighted
        }
    }
}

class CBBorderToggleButton: UIButton {
    let ReloadCount = 0
    weak var textColor: UIColor?

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        layer.cornerRadius = 6.0
        layer.borderWidth = 3.0

        if titleLabel?.responds(to: #selector(setter: UIBarButtonItem.tintColor)) ?? false {
            titleLabel?.tintColor = .clear
        }
        titleLabel?.textColor = .black
    }

    func setTitleColor(_ color: UIColor?) {
        titleLabel?.textColor = color
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        if titleLabel?.responds(to: #selector(setter: UIBarButtonItem.tintColor)) ?? false {
            titleLabel?.tintColor = .clear
        }
        layer.cornerRadius = 6.0
        layer.borderWidth = 3.0
        titleLabel?.textColor = .clear
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        titleLabel?.backgroundColor = .clear
        titleLabel?.shadowColor = .clear
        backgroundColor = UIColor.black
        if isSelected {
            if #available(iOS 13.0, *) {
                titleLabel?.textColor = .label
            } else {
                titleLabel?.textColor = UIColor(named: "preset_label")
            }
            if let currentFont = titleLabel?.font {
                titleLabel?.font = UIFont.boldSystemFont(ofSize: currentFont.pointSize)
            }
        } else {
            if #available(iOS 13.0, *) {
                titleLabel?.textColor = .label
            } else {
                titleLabel?.textColor = CBColor.buttonLightTextColor
            }
            if let currentFont = titleLabel?.font {
                titleLabel?.font = UIFont.systemFont(ofSize: currentFont.pointSize)
            }
        }
        layer.borderColor = (self.isSelected ? UIColor(red: 76.0 / kColorDivisor, green: 23.0 / kColorDivisor, blue: 203.0 / kColorDivisor, alpha: 1.0).cgColor : CBColor.buttonLightTextColor.cgColor)
        let textColor = self.isSelected ? .black : CBColor.buttonLightTextColor
        setTitleColor(textColor, for: .normal)
        setTitleColor(textColor, for: .selected)

        titleLabel?.textColor = self.isSelected ? UIColor(named: "preset_label") : CBColor.buttonLightTextColor

        backgroundColor = UIColor(named: "contentBgColor")
        alpha = self.isSelected ? 1.0 : 0.5
    }
    
    func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        isSelected = !isSelected
        isHighlighted = isSelected
    }
    func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        isHighlighted = isSelected
    }

    func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        isHighlighted = isSelected
    }

    func setSelected(_ selected: Bool) {
        super.select(selected)
        layer.borderColor = (selected ? UIColor(red: 76.0 / kColorDivisor, green: 23.0 / kColorDivisor, blue: 203.0 / kColorDivisor, alpha: 1.0).cgColor : CBColor.buttonLightTextColor.cgColor)
        let textColor = selected ? .black : CBColor.buttonLightTextColor
        setTitleColor(textColor, for: .normal)
        setTitleColor(textColor, for: .selected)
        titleLabel?.textColor = selected ? .black  : CBColor.buttonLightTextColor
        backgroundColor = UIColor.white
        alpha = selected ? 1.0 : 0.3
    }

}
