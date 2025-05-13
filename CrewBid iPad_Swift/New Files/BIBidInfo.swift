//
//  BIBidInfo.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 11/05/25.
//

import Foundation

typealias BIFinishedBlock = () -> Void
typealias BIProgressBlock = (Float) -> Void
typealias BIErrorBlock = (Error) -> Void
class BIBidInfoDataSource {
    var year = Int()
    var month  = Int()
    var base = String()
    var position : BICrewPositionType = .Captain
    var round = Int()
    var employeeNumber = String()
    var swaptimizerID = String()
}

class BIBidInfo:NSObject{
    private var app:AppDelegate!
    weak var dataSource: BIBidInfoDataSource!
    //MARK: Directories
    static func tempDirectory() -> URL {
        return FileManager.default.temporaryDirectory
    }
    
    func downloadDirectory() -> URL {
        return BIBidInfo.tempDirectory().appendingPathComponent("Downloads")
    }
    
    class func documentsDirectory() -> URL {
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
        let filename = ""
        return filename
    }
    
    func dataFilenameBase() -> String {
        let filename = ""
        return filename
    }
    
    func textFilenameBase() -> String {
        let base = dataSource.base
        let shortName = dataSource.position
        return "\(String(describing: base))\(String(describing: shortName))"
    }
    
    func bidDocumentFilename() -> String {
        // Month and year formatting
        let monthYearFormatter = DateFormatter()
        monthYearFormatter.dateFormat = "MMM yyyy"
        var components = DateComponents()
        let app = UIApplication.shared.delegate as! AppDelegate
        components.year = dataSource.year
        components.month = dataSource.month
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
        let position = CBGlobalMethods.longNameOf(type: dataSource.position)
        let base = dataSource.base
        let round = "Round \(dataSource.round)"
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
    

}
