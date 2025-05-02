//
//  KUIPopOverUsable.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 25/03/25.
//

import Foundation
import UIKit

public protocol KUIPopOverUsable {
    
    var contentSize: CGSize { get }
    var contentView: UIView { get }
    var popOverBackgroundColor: UIColor? { get }
    var arrowDirection: UIPopoverArrowDirection { get }
    
}

extension KUIPopOverUsable {
    
    
    public var popOverBackgroundColor: UIColor? {
        return nil
    }
    
    public var arrowDirection: UIPopoverArrowDirection {
        return .any
    }
    
}

public extension UIPopoverArrowDirection {
    static var none: UIPopoverArrowDirection {
        return UIPopoverArrowDirection(rawValue: 0)
    }
}
