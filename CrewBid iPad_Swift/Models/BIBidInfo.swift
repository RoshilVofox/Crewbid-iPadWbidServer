//
//  BIBidInfo.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 11/05/25.
//

import Foundation
import CoreData

let kCBCrewBidDocumentExtension = "crewbiddoc"

protocol BIBidInfoDataSource {
    var userid: String { get set }
    var password: String { get set }
    var year: Int { get set }
    var month: Int { get set }
    var base: String { get set }
    var position: BICrewPositionType { get set }
    var round: Int { get set }
    var employeeNumber: String { get set }
    var swaptimizerID: String { get set }
    var managedObjectContext: NSManagedObjectContext { get }
}
class GlobalBidInfo: BIBidInfoDataSource {
    static let shared = GlobalBidInfo()
    var userid: String = ""
    var password: String = ""
    var year: Int = 0
    var month: Int = 0
    var base: String = ""
    var position: BICrewPositionType = .Captain
    var round: Int = 0
    var employeeNumber: String = ""
    var swaptimizerID: String = ""
    var managedObjectContext: NSManagedObjectContext
    var allDomicileDownloadDictionary: [String: Any] = [:]
    var isCurrentlyDownloadingAllBid = 0
    var alertCount = 0
    var credentialEmployeeNumber: String = ""
    private init() {
        self.managedObjectContext = CoreDataManager.shared.persistentContainer.newBackgroundContext()
        self.managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}



class BIBidInfo:NSObject{
    
    static let shared = BIBidInfo()
    
    var dataSource = GlobalBidInfo.shared
    
    func bidDataFilename() -> String {
            return "\(dataFilenameBase()).737"
        }
    func textDataFilename() -> String {
           let bidRoundChar: Character = isFirstRoundBid() ? "A" : "B"
           return "\(textFilenameBase())\(bidRoundChar).ZIP"
       }
    
    func bidDataFiles() -> [String]? {
        var bidDataFiles:[String] = []
        if AppState.shared.isHistoricBid || AppState.shared.isMockData {
            bidDataFiles.append(textDataFilename())
        }else{
            bidDataFiles.append(textDataFilename())
            bidDataFiles.append(bidDataFilename())
        }
        
        if isSecondRoundBid() && !isFABid(){
            var firstRoundTextDataFilename = textDataFilename()
                    if firstRoundTextDataFilename.count > 5 {
                        let index = firstRoundTextDataFilename.index(firstRoundTextDataFilename.startIndex, offsetBy: 5)
                        firstRoundTextDataFilename.replaceSubrange(index...index, with: "A")
                        bidDataFiles.append(firstRoundTextDataFilename)
                    } else {
                        print("Warning: textDataFilename is too short to modify for first round")
                    }
                }
        return bidDataFiles
    }
    
    func bidDocumentFileURL() -> URL {
        let documentsDirectoryURL = self.documentsDirectory()
        let documentFilename = bidDocumentFilename()
        let documentFileURL = documentsDirectoryURL.appendingPathComponent(documentFilename)
        return documentFileURL
    }
    
    func documentsDirectory() -> URL {
        let fileManager = FileManager.default
        let directories = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        return directories.last!
    }
    
    func bidDocumentFilename() -> String {
        let app = AppState.shared
        var month = dataSource.month
        var year = dataSource.year
        if app.isMockData || app.isHistoricBid {
            month = app.mockDataMonth!
            year = app.mockDataYear!
        }
        if let isQATest = UserDefaults.standard.string(forKey: "isQATest"), isQATest == "1" {
            if let testMonthStr = UserDefaults.standard.string(forKey: "QATestMonth"),
               let testYearStr = UserDefaults.standard.string(forKey: "QATestYear"),
               let testMonth = Int(testMonthStr),
               let testYear = Int(testYearStr) {
                month = testMonth
                year = testYear
            }
        }
        var components = DateComponents()
        components.year = year
        components.month = month
        let calendar = Calendar.current
        let bidMonthDate = calendar.date(from: components) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        let formattedMonth = formatter.string(from: bidMonthDate)
        let position = dataSource.position.longName
        let base = dataSource.base
        let round = "Round \(dataSource.round)"
        let filename = "\(formattedMonth) \(base) \(position) \(round).crewbiddoc"
        return filename
    }
    
    func linesTextFilename() -> String {
        // 'L' for first round, 'N' for second round
        let bidRoundChar: Character = isSecondRoundBid() ? "N" : "L"
        return "\(textFilenameBase())\(bidRoundChar).TXT"
    }

    func dataFilenameBase() -> String {
        let position = dataSource.position.character
        let base = dataSource.base
        let round = isFirstRoundBid() ? "D" : "B"
        let isQATest = UserDefaults.standard.string(forKey: "isQATest")
        if isQATest == "1" {
            let qaMonth = UserDefaults.standard.string(forKey: "QATestMonth") ?? "0"
            dataSource.month = Int(qaMonth)!
        }
        let monthValue = dataSource.month
        // Convert to uppercase hex string
        let monthHex = String(format: "%lX", monthValue)
        return "\(position)\(round)\(base)\(monthHex)"
    }

    private func isFirstRoundBid() -> Bool {
        return dataSource.round == 1
    }
    
    private func isSecondRoundBid() -> Bool {
        return dataSource.round == 2
    }
    private func isFABid() -> Bool {
        let isFABid = BICrewPositionType.FlightAttendant.rawValue == self.dataSource.position.rawValue
        return isFABid
    }
    
    func bidAwardTextFilename() -> String {
        /* M for first round, W for second round */
        let bidPeriod = CBGlobalMethods.shared.selectedBidPeriod
        var bidRoundChar = "M"
        if isSecondRoundBid(){
            bidRoundChar = "W"
        }
        let positionArray = ["CP","FO","FA"]
        let positionName = positionArray[(bidPeriod?.positionType!.intValue)!]
        var baseName = UserDefaults.standard.string(forKey: "baseKey")  ?? ""
        if let bd = CBGlobalMethods.shared.selectedBidPeriod {
            baseName = bd.base ?? ""
        }
        let bidAwardDataFileName: String = "\(baseName)\(positionName)\(bidRoundChar).TXT"
        return bidAwardDataFileName
    }
    
    func textFilenameBase() -> String {
        let base = dataSource.base
        let position = dataSource.position.shortName
        return "\(base)\(position)"
    }

    static func temporaryDirectory() -> URL {
        return URL(fileURLWithPath: NSTemporaryDirectory())
    }

    func downloadDirectory() -> URL {
        return Self.temporaryDirectory().appendingPathComponent(dataFilenameBase())
    }

    func tripsTextFilename() -> String {
        // Default trip text character is 'P'
        var tripTextChar: Character = "P"
        if isSecondRoundBid() && isFABid() {
            tripTextChar = "T"
        }
        let filename = "\(textFilenameBase())\(tripTextChar).TXT"
        return filename
    }
    func coverLetterFileName() -> String {
        let bidRoundStr: String
        if isFirstRoundBid() {
            bidRoundStr = "C"
        } else {
            bidRoundStr = isFABid() ? "CR" : "R"
        }
        return "\(textFilenameBase())\(bidRoundStr).TXT"
    }
    
    func seniorityListFileName() -> String {
        let bidRoundStr: String
        if isFirstRoundBid() {
            bidRoundStr = "S"
        } else {
            bidRoundStr = isFABid() ? "SR" : "R"
        }
        return "\(textFilenameBase())\(bidRoundStr).TXT"
    }
    
    
    func tripsTextFilename() -> String? {
        if isSecondRoundBid() && !isFABid() {
            return nil
        }
        let tripTextChar: Character = (isSecondRoundBid() && isFABid()) ? "T" : "P"
        return "\(textFilenameBase())\(tripTextChar).TXT"
    }
    
    func faMemoTextFilename() -> String {
        let faMemoSuffix = (isSecondRoundBid() && isFABid()) ? "OR" : "O"
        return "\(textFilenameBase())\(faMemoSuffix).TXT"
    }
}
