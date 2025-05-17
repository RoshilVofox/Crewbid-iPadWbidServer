//
//  CBUtils.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 11/05/25.
//

import Foundation
import ZipArchive

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
    class func isRunningOnSimulator() -> Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    class func downloadFlightData(completionHandler: @escaping (Bool) -> Void) {
            guard let url = URL(string: "http://www.wbidmax.com/downloads/swa/FlightDataJson.zip") else {
                print("Invalid URL.")
                completionHandler(false)
                return
            }
            guard let urlData = try? Data(contentsOf: url) else {
                print("Failed to download data.")
                completionHandler(false)
                return
            }
            let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let zipFilePath = documentsDir.appendingPathComponent("FlightDataJson.zip")

            do {
                try urlData.write(to: zipFilePath, options: .atomic)
                let defaults = UserDefaults.standard
                defaults.set(1, forKey: "IsLatestFlightDataDownloaded")
                defaults.set(false, forKey: "IsNeedtoEnableVacationDifference")
                parseFlightDataFile(at: zipFilePath.path)
                completionHandler(true)
            } catch {
                print("Error writing file: \(error)")
                completionHandler(false)
            }
        }
    
    class func parseFlightDataFile(at filePath: String) {
        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let flightDataJsonPath = documentPath.appendingPathComponent("FlightDataJson")
                if FileManager.default.fileExists(atPath: flightDataJsonPath.path) {
                    do {
                        try FileManager.default.removeItem(at: flightDataJsonPath)
                    } catch {
                        print("Error deleting old FlightDataJson folder: \(error)")
                    }
                }
                SSZipArchive.unzipFile(atPath: filePath, toDestination: documentPath.path)
                if FileManager.default.fileExists(atPath: filePath) {
                    do {
                        try FileManager.default.removeItem(atPath: filePath)
                    } catch {
                        print("Error deleting zip file: \(error)")
                    }
                }
            }
}
