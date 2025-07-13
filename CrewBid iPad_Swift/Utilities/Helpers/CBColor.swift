//
//  CBColor.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 25/03/25.
//

import Foundation
import UIKit

let kColorDivisor: CGFloat = 255.0
// Application blue (purple) color.

class CBColor: UIColor, @unchecked Sendable {
    // Static variable to store cell background color
    
    static let faPosAColor = UIColor(red: 51 / kColorDivisor, green: 104.98 / kColorDivisor, blue: 231.999 / kColorDivisor, alpha: 1.0)
    static let faPosBColor =  UIColor(red:0.0 / kColorDivisor, green:153.0 / kColorDivisor, blue:36.975 / kColorDivisor, alpha:1.000)
    static let faPosCColor = UIColor(red:237.99 / kColorDivisor, green:177.99 / kColorDivisor, blue:16.83 / kColorDivisor, alpha:1.000)
    static let faPosDColor = UIColor(red:213.0 / kColorDivisor, green:14.994 / kColorDivisor, blue:37.0/kColorDivisor, alpha:1.000)
    
    static let cbPurpleColor = UIColor(named: "PurpleColor") //UIColor(red: 76.0 / kColorDivisor, green: 23.0 / kColorDivisor, blue: 203.0 / kColorDivisor, alpha: 1.0)
    static let cbPurpleColorLoader = UIColor(red: 76.0 / kColorDivisor, green: 23.0 / kColorDivisor, blue: 203.0 / kColorDivisor, alpha: 0.5)
    static let cbPurpleColorDarkMode = UIColor(red: 76.0 / kColorDivisor, green: 23.0 / kColorDivisor, blue: 203.0 / kColorDivisor, alpha: 1.0)

    static let cellBackgroundColorVar: UIColor? = UIColor(red: 247.0 / kColorDivisor, green: 247.0 / kColorDivisor, blue: 247.0 / kColorDivisor, alpha: 1.0)
    static let tripHighlightColor = UIColor(red: 255.0 / kColorDivisor, green: 255.0 / kColorDivisor, blue: 0.0 / kColorDivisor, alpha: 1.0)
    static let tableViewBackgroundColor = UIColor(red: 75.99 / kColorDivisor, green: 83.89 / kColorDivisor, blue: 91 / kColorDivisor, alpha: 1.0)
    static let buttonDarkTextColor = UIColor(red: 43 / kColorDivisor, green: 47.94 / kColorDivisor, blue: 55 / kColorDivisor, alpha: 1.0)
    static let tableViewCellBackgroundColor = UIColor(white: 0.97, alpha: 1.0)
    static let tripButtonredColor = UIColor(red: 185.0 / kColorDivisor, green: 54.0 / kColorDivisor, blue: 16.0 / kColorDivisor, alpha: 1.0)
    static let cbBrownColor = UIColor(red: 122.0 / kColorDivisor, green: 92.0 / kColorDivisor, blue: 49.0 / kColorDivisor, alpha: 1.0)
    static let oldbrownColor = UIColor(red: 153.0 / kColorDivisor, green: 102.0 / kColorDivisor, blue: 51.0 / kColorDivisor, alpha: 1.0)
    static let lightBlackColor = UIColor(red: 27 / kColorDivisor, green: 28 / kColorDivisor, blue: 28 / kColorDivisor, alpha: 1.0)
    static let cbRed = UIColor(red: 255.0 / kColorDivisor, green: 59.0 / kColorDivisor, blue: 10.0 / kColorDivisor, alpha: 1.0)
    static let cbOrangeColor = UIColor(red: 220.0 / kColorDivisor, green: 100.0 / kColorDivisor, blue: 5.0 / kColorDivisor, alpha: 1.0)
    static let cbGray = UIColor(red: 124.0 / kColorDivisor, green: 138.0 / kColorDivisor, blue: 150.0 / kColorDivisor, alpha: 1.0)
    static let cbGreenColor = UIColor(red: 0.0, green: 0.6484375, blue: 0.484375, alpha: 1.0)
    static let buttonLightTextColor = UIColor(red: 0.404, green: 0.455, blue: 0.494, alpha: 1.000)
    static let lightGreenColor = UIColor(red: 113.0 / kColorDivisor, green: 203.0 / kColorDivisor, blue: 181.0 / kColorDivisor, alpha: 1.0)
    static let lightTripButtonRedColor = UIColor(red: 201.0 / kColorDivisor, green: 118.0 / kColorDivisor, blue: 97.0 / kColorDivisor, alpha: 1.0)
    
}


