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
private let kBlueColorRedComponent: CGFloat = 76.0
private let kBlueColorGreenComponent: CGFloat = 23.0
private let kBlueColorBlueComponent: CGFloat = 203.0

class CBColor {
    // Static variable to store cell background color

    static var cellBackgroundColorVar: UIColor? = nil
    // Returns the cell background color, lazily initialized

        class func cellBackgroundColor() -> UIColor? {

            if nil == cellBackgroundColorVar {
                cellBackgroundColorVar = UIColor(red: 247.0 / kColorDivisor, green: 247.0 / kColorDivisor, blue: 247.0 / kColorDivisor, alpha: 1.0)
            }
            return cellBackgroundColorVar
        }
    // Returns a specific trip highlight color

    class func tripHighlightColor() -> UIColor {
        var tripHighlightColorVar: UIColor = UIColor()
        tripHighlightColorVar = UIColor(red: 255.0 / kColorDivisor, green: 255.0 / kColorDivisor, blue: 0.0 / kColorDivisor, alpha: 1.0)
        return tripHighlightColorVar
    }
    // Returns the table view background color

    class func tableViewBackgroundColor() -> UIColor {
        return UIColor(red: 0.298, green: 0.329, blue: 0.357, alpha: 1.0)
    }
    // Returns the dark text color for buttons

    class func buttonDarkTextColor() -> UIColor {
        return UIColor(red: 0.169, green: 0.188, blue: 0.216, alpha: 1.0)
    }
    // Returns a specific color for FA (Flight Attendant) position A

    class func faPosAColor() -> UIColor {
        return UIColor(red: 0.2, green: 0.4117, blue: 0.9098, alpha: 1.0)
    }
    
    // Returns a specific color for FA (Flight Attendant) position B

    class func faPosBColor() -> UIColor {
        return UIColor(red:0.0, green:0.6, blue:0.145, alpha:1.000)
    }
    // Returns a specific color for FA (Flight Attendant) position C

    class func faPosCColor() -> UIColor {
        return UIColor(red:0.9333, green:0.698, blue:0.066, alpha:1.000)
     }
    // Returns a specific color for FA (Flight Attendant) position D

    class func faPosDColor() -> UIColor {
        return UIColor(red:0.8353, green:0.0588, blue:0.1451, alpha:1.000)
    }
    // Returns the background color for table view cells

    class func tableViewCellBackgroundColor() -> UIColor {
        return UIColor(white: 0.97, alpha: 1.0)
    }
    // Returns a specific color for trip buttons

    class func tripButtonredColor() -> UIColor {
        return UIColor(red: 185.0 / kColorDivisor, green: 54.0 / kColorDivisor, blue: 16.0 / kColorDivisor, alpha: 1.0)
    }
    
    class func brownColor() -> UIColor {
        return UIColor(red: 122.0 / kColorDivisor, green: 92.0 / kColorDivisor, blue: 49.0 / kColorDivisor, alpha: 1.0)
    }
    class func oldbrownColor() -> UIColor {
        return UIColor(red: 153.0 / kColorDivisor, green: 102.0 / kColorDivisor, blue: 51.0 / kColorDivisor, alpha: 1.0)
    }

    class func purpleColor() ->  UIColor {
        return UIColor(red: 76.0 / kColorDivisor, green: 23.0 / kColorDivisor, blue: 203.0 / kColorDivisor, alpha: 1.0)
    }

    class func lightBlackColor() -> UIColor {
        return UIColor(red: 27 / kColorDivisor, green: 28 / kColorDivisor, blue: 28 / kColorDivisor, alpha: 1.0)
    }


    class func red() -> UIColor {
        return UIColor(red: 255.0 / kColorDivisor, green: 59.0 / kColorDivisor, blue: 10.0 / kColorDivisor, alpha: 1.0)
    }
    
    class func orangeColor() -> UIColor {
        return UIColor(red: 220.0 / kColorDivisor, green: 100.0 / kColorDivisor, blue: 5.0 / kColorDivisor, alpha: 1.0)
    }
    
    class func gray() -> UIColor {
        return UIColor(red: 124.0 / kColorDivisor, green: 138.0 / kColorDivisor, blue: 150.0 / kColorDivisor, alpha: 1.0)
    }

    class func greenColor() -> UIColor {
        return UIColor(red: 0.0, green: 0.6484375, blue: 0.484375, alpha: 1.0)
    }
    
    class func buttonLightTextColor() -> UIColor? {
        return UIColor(red: 0.404, green: 0.455, blue: 0.494, alpha: 1.000)
    }
    class func lightGreenColor() -> UIColor {
        return UIColor(red: 113.0 / 255.0, green: 203.0 / 255.0, blue: 181.0 / 255.0, alpha: 1.0)
    }
    class func lightTripButtonRedColor() -> UIColor {
        return UIColor(red: 201.0 / 255.0, green: 118.0 / 255.0, blue: 97.0 / 255.0, alpha: 1.0)
    }

    
//    static var purpleColorBlueColor: UIColor? = nil
//
//    class var purple() -> UIColor {
//        if nil == purpleColorBlueColor {
//            purpleColorBlueColor = UIColor(red: kBlueColorRedComponent / kColorDivisor, green: kBlueColorGreenComponent / kColorDivisor, blue: kBlueColorBlueComponent / kColorDivisor, alpha: 1.0)
//        }
//        return purpleColorBlueColor ?? UIColor.clear
//    }
}


