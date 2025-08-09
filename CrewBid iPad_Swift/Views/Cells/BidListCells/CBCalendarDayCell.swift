//
//  CBCalendarDayCell.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 01/08/25.
//

import UIKit

class CBCalendarDayCell: UICollectionViewCell {
    
    var type = CBCalendarTripDayType.cbCalendarTripDayNone
    weak var color: UIColor?
    override func draw(_ rect: CGRect) {
         var path: UIBezierPath? = nil
         if CBCalendarTripDayType.cbCalendarTripDayNone.rawValue == type.rawValue {
            path = UIBezierPath(rect: rect)
            UIColor.secondarySystemBackground.set()
            path?.fill()
            return
         }
         var pathRect: CGRect
         var rectCorners: UIRectCorner
         var cornerRadii: CGSize
         switch type {
         case CBCalendarTripDayType.cbCalendarTripDayStart:
             // Rounded on left.
             pathRect = CGRect(x: 0.0, y: 0.0, width: rect.size.width - 0.0, height: rect.size.height)
             rectCorners = [.topLeft, .bottomLeft]
             cornerRadii = CGSize(width: rect.size.height / 2.0, height: rect.size.height / 2.0)
             path = UIBezierPath(roundedRect: pathRect, byRoundingCorners: rectCorners, cornerRadii: cornerRadii)
         case CBCalendarTripDayType.cbCalendarTripDayMiddle:
             // Square corners.
             path = UIBezierPath(rect: rect)
         case CBCalendarTripDayType.cbCalendarTripDayEnd:
             // Rounded on right.
             pathRect = CGRect(x: 0.0, y: 0.0, width: rect.size.width - 0.0, height: rect.size.height)
             rectCorners = [.topRight, .bottomRight]
             cornerRadii = CGSize(width: rect.size.height / 2.0, height: rect.size.height / 2.0)
             path = UIBezierPath(roundedRect: pathRect, byRoundingCorners: rectCorners, cornerRadii: cornerRadii)
         case CBCalendarTripDayType.cbCalendarTripDaySingle:
             // Rounded on both.
             pathRect = CGRect(x: 0.0, y: 0.0, width: rect.size.width - 0.0, height: rect.size.height)
             path = UIBezierPath(roundedRect: pathRect, cornerRadius: rect.size.height / 2.0)
         default:
             break
         }
         color?.set()
         path?.fill()
     }
}
