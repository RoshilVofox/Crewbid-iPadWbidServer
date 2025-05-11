//
//  BIBidInfo.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 11/05/25.
//

import Foundation

protocol BIBidInfoDataSource: AnyObject {
    func year() -> NSNumber
    func month() -> NSNumber?
    func base() -> String?
    func position() -> BICrewPosition?
    func round() -> NSNumber?
    func employeeNumber() -> String
    func swaptimizerId() -> String
}
class BIBidInfo{
    private var app:AppDelegate!
    weak var dataSource: BIBidInfoDataSource!
    
    //MARK: Directories
    static func tempDirectory() -> URL {
        return FileManager.default.temporaryDirectory
    }
    
    func downloadDirectory() -> URL {
        return BIBidInfo.tempDirectory().appendingPathComponent("Downloads")
    }
    
    static func documentsDirectory() -> URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
     return directory.last!
    }
    
    //MARK: URLs & Filenames
    func bidDocumentFileURL() -> URL {
        let documentsDirectoryURL = BIBidInfo.documentsDirectory()
        let documentFilename = bidDocumentFilename()
        let documentFileURL = documentsDirectoryURL.appendingPathComponent(documentFilename)
        return documentFileURL
    }
    
    func mockDataFilenameBase() -> String {
        // C for captain, F for first officer, A for flight attendant.
        let positionChar = dataSource.position()?.character.unicodeScalars.first!.value
        // D for first round bid, B for second round bid.
        let roundChar = isFirstRoundBid() ? "D".unicodeScalars.first!.value : "B".unicodeScalars.first!.value
        // Log month value
        print("Month---DataFile --\(dataSource?.month()?.intValue ?? 0)")
        // Get app delegate
        let app = UIApplication.shared.delegate as! AppDelegate
        // Format the filename using hex for the month
        let filename = String(format: "%c%c%@%lX",positionChar!,roundChar,dataSource.base()!,app.mockDataMonth!)
        return filename
    }
    
    func dataFilenameBase() -> String {
        // C for captain, F for first officer, A for flight attendant.
        let positionChar = dataSource.position()?.character.unicodeScalars.first!.value
        // D for first round bid, B for second round bid.
        let roundChar = (isFirstRoundBid() ? "D" : "B").unicodeScalars.first!.value
        // Log the month
        print("Month---DataFile --\(dataSource.month()?.intValue ?? 0)")
        let app = UIApplication.shared.delegate as! AppDelegate
        let filename: String
        if app.isMockData || app.isHistoricBid {
            filename = String(format: "%c%c%@%lX",positionChar!,roundChar,dataSource.base()!,app.mockDataMonth!)
        } else {
            filename = String(format: "%c%c%@%lX",positionChar!,roundChar,dataSource.base()!,dataSource.month()?.intValue ?? 0)
        }
        return filename
    }
    
    func textFilenameBase() -> String {
        let base = dataSource.base()
        let shortName = dataSource.position()?.shortName
        return "\(String(describing: base))\(String(describing: shortName))"
    }
    
    func bidDocumentFilename() -> String {
        // Month and year formatting
        let monthYearFormatter = DateFormatter()
        monthYearFormatter.dateFormat = "MMM yyyy"
        var components = DateComponents()
        let app = UIApplication.shared.delegate as! AppDelegate
        components.year = dataSource.year().intValue
        components.month = dataSource.month()?.intValue ?? 0
        if app.isMockData || app.isHistoricBid {
            components.year = app.mockDataYear
            components.month = app.mockDataMonth
        }
        if UserDefaults.standard.string(forKey: "isQATest") == "YES" {
            let qaTestMonth = UserDefaults.standard.string(forKey: "QATestMonth")
            let qaTestYear = UserDefaults.standard.string(forKey: "QATestYear")
            if let monthStr = qaTestMonth, let yearStr = qaTestYear,
               let monthInt = Int(monthStr), let yearInt = Int(yearStr) {
                components.month = monthInt
                components.year = yearInt
            }
        }
        let calendar = Calendar.current
        let bidMonth = calendar.date(from: components)
        let month = monthYearFormatter.string(from: bidMonth!)
        // Position, base, and round
        let position = dataSource.position()?.longName
        let base = dataSource.base()
        let round = "Round \(dataSource.round()!.intValue)"
        let filename = "\(month) \(String(describing: base)) \(String(describing: position)) \(round).crewbiddoc"
        return filename
    }
    
    func removeDownloadDirectory() {
        let fileManager = FileManager.default
        let downloadURL = downloadDirectory()
        if fileManager.fileExists(atPath: downloadURL.path) {
            do {
                try fileManager.removeItem(at: downloadURL)
            } catch {
                print("\(type(of: self)) failed to delete downloaded files at path: \(downloadURL.path) *** Reason: \(error.localizedDescription)")
            }
        }
    }
    
    
    func isFirstRoundBid() -> Bool {
        return dataSource?.round()?.intValue == 1
    }
    
    func isSecondRoundBid() -> Bool {
        return dataSource?.round()?.intValue == 2
    }
    
    func isFlightAttendantBid() -> Bool {
        return dataSource?.position()?.type == .FlightAttendant
    }
}
