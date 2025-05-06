//
//  Extensions.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 21/04/25.
//

import Foundation
import UIKit


extension UIApplication {
    
//    static func topVC() -> UIViewController {
//        var topController: UIViewController? = UIApplication.shared.keyWindow?.rootViewController
//        while ((topController?.presentedViewController) != nil) {
//            topController = topController?.presentedViewController
//        }
//        return topController!
//    }
    static func topVC() -> UIViewController {
//        guard let windowScene = UIApplication.shared.connectedScenes
//                .filter({ $0.activationState == .foregroundActive })
//                .first as? UIWindowScene,
//              let root = windowScene.windows
//                .first(where: { $0.isKeyWindow })?.rootViewController else {
//            fatalError("No rootViewController found")
//        }
//        var topController: UIViewController? = root
        var topController: UIViewController? = UIApplication.shared.keyWindow?.rootViewController
        while let presented = topController?.presentedViewController {
            topController = presented
        }

        return topController!
    }
    /*
     class func topViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
         if let nav = base as? UINavigationController {
             return topViewController(base: nav.visibleViewController)
         }
         if let tab = base as? UITabBarController {
             if let selected = tab.selectedViewController {
                 return topViewController(base: selected)
             }
         }
         if let presented = base?.presentedViewController {
             return topViewController(base: presented)
         }
         return base
     }
     */
    

    class func topViewController(base: UIViewController? =
//    {
//        if let scene = UIApplication.shared.connectedScenes
//            .filter({ $0.activationState == .foregroundActive })
//            .first as? UIWindowScene {
//
//            return scene.windows
//                .first(where: { $0.isKeyWindow })?.rootViewController
//        }
//        return nil
//    }()) -> UIViewController? {
    UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            if let selected = tab.selectedViewController {
                return topViewController(base: selected)
            }
        }
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }
}
@objc
public protocol AnchorView: AnyObject {

    var plainView: UIView { get }

}

extension UIView: AnchorView {

    public var plainView: UIView {
        return self
    }

}

extension UIBarButtonItem: AnchorView {
    
    public var plainView: UIView {
        return value(forKey: "view") as! UIView
    }
    
}
 


extension String {
    
    var length: Int {
        return self.count
    }
    
    subscript (i: Int) -> String {
        return self[i ..< i + 1]
    }
    
    func substring(from: Int) -> String {
        return self[min(from, length) ..< length]
    }
    
    func substring(to: Int) -> String {
        return self[0 ..< max(0, to)]
    }
    
    subscript (r: Range<Int>) -> String {
        let range = Range(uncheckedBounds: (lower: max(0, min(length, r.lowerBound)), upper: min(length, max(0, r.upperBound))))
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        let Finalrange = Range.init(uncheckedBounds: (lower: start, upper: end))
        return String(self[Finalrange])
    }
    
    func CharAtIndex(pos: Int) -> Character {
        return self[String.Index(utf16Offset: pos, in: self)]
    }
    
}

extension String {
    
    func substring(with r: Range<Int>) -> String {
        let startIndex = self.index(self.startIndex, offsetBy: r.lowerBound)
        let endIndex = self.index(startIndex, offsetBy: r.upperBound)
        var string = String(self[startIndex..<endIndex])
        if string == "" {
            string = "0"
        }
        return string
    }
    
    func character(at index: Int) -> Character {
        let charAtIndex = self.CharAtIndex(pos: index)
        return charAtIndex
    }
}

extension StringProtocol {
    subscript(offset: Int) -> Character {
        self[index(startIndex, offsetBy: offset)]
    }
}




public extension Int {
    /// returns number of digits in Int number
    var digitCount: Int {
        get {
            return numberOfDigits(in: self)
        }
    }
    /// returns number of useful digits in Int number
    var usefulDigitCount: Int {
        get {
            var count = 0
            for digitOrder in 0..<self.digitCount {
                /// get each order digit from self
                let digit = self % (Int(truncating: pow(10, digitOrder + 1) as NSDecimalNumber))
                / Int(truncating: pow(10, digitOrder) as NSDecimalNumber)
                if isUseful(digit) { count += 1 }
            }
            return count
        }
    }
    // private recursive method for counting digits
    private func numberOfDigits(in number: Int) -> Int {
        if number < 10 && number >= 0 || number > -10 && number < 0 {
            return 1
        } else {
            return 1 + numberOfDigits(in: number/10)
        }
    }
    // returns true if digit is useful in respect to self
    private func isUseful(_ digit: Int) -> Bool {
        return (digit != 0) && (self % digit == 0)
    }
}
