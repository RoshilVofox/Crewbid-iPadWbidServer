//
//  BIBidInfo.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 11/05/25.
//

import Foundation

typealias BIFinishedBlock = () -> Void
typealias BIProgressBlock = (Float) -> Void


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
    private init() {}
}



class BIBidInfo:NSObject{
    
    static let shared = BIBidInfo()
    
    var dataSource = GlobalBidInfo.shared
    func bidDataFilename() -> String {
            return "\(dataFilenameBase()).737"
        }
    
    func linesTextFilename() -> String {
        // 'L' for first round, 'N' for second round
        let bidRoundChar: Character = isSecondRoundBid() ? "N" : "L"
        return "\(textFilenameBase())\(bidRoundChar).TXT"
    }

    private func dataFilenameBase() -> String {
        let position = dataSource.position.character
        let base = dataSource.base
        let round = isFirstRoundBid() ? "D" : "B"
        let month = dataSource.month
        return "\(position)\(round)\(base)\(month)"
    }

    private func isFirstRoundBid() -> Bool {
        return dataSource.round == 1
    }
    
    private func isSecondRoundBid() -> Bool {
        return dataSource.round == 2
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


}
