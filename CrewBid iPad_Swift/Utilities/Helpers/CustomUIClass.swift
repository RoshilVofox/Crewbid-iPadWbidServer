//
//  CustomUIClass.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 21/03/25.
//

import Foundation
import UIKit
open class customUITextField: UITextField {

    func setup() {
        self.layer.backgroundColor = UIColor.clear.cgColor
        self.layer.borderColor = UIColor.gray.cgColor
        self.layer.borderWidth = 1
        self.layer.cornerRadius = 5
        self.layer.masksToBounds = false
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
}
@IBDesignable
final class customButton: UIButton {
    func setup() {
        self.clipsToBounds = true
        self.layer.cornerRadius = 5
        self.layer.borderWidth = 1
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
}
@IBDesignable
final class dataDownloadingButton: UIButton {
    func setup() {
        self.clipsToBounds = true
        self.layer.cornerRadius = 5
        self.layer.borderColor = UIColor.lightGray.cgColor
        self.layer.borderWidth = 1
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
}
extension UIColor {
    static let purpleColor = UIColor(red:76.0 / 255.0, green:23.0 / 255.0, blue:203.0 / 255.0, alpha: 1.0)
    
    
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
}

class CBCheckButton: UIButton {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let lightGrayColor = UIColor(rgb: 0xEBEBF0)
        self.backgroundColor = lightGrayColor
        self.setTitleColor(.black, for: .normal)
    }
    
    private var _isChecked = false
    var isChecked: Bool {
        set {
            _isChecked = newValue
            if _isChecked {
                let greenColor = UIColor(red: 49.0 / 255.0, green: 126.0 / 255.0, blue: 62.0 / 255.0, alpha: 1.0)
                self.backgroundColor = greenColor
                self.setTitleColor(.white, for: .normal)
            } else {
                let lightGrayColor = UIColor(rgb: 0xEBEBF0)
                self.backgroundColor = lightGrayColor
                self.setTitleColor(.black, for: .normal)
            }
        }
        get {
            return _isChecked
        }
    }
    
}
