//
//  CBUtils.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 11/05/25.
//

import Foundation


class CBUtils{
    
    
    class func getYearforBid(month : Int, year : Int) -> Int {
        var yearToReturn : Int = 0
        // Avoid sending a 13 when bid month is December
        if (month == 12) {
            yearToReturn = year + 1
        } else {
            yearToReturn = year
        }
        return yearToReturn
    }
    class func AppVersion() -> String{
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    }
}
