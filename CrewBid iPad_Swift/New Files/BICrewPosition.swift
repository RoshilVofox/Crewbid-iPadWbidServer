//
//  BICrewPosition.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 11/05/25.
//

import Foundation

class BICrewPosition{
    let type:BICrewPositionType
    
    init(type: BICrewPositionType) {
        self.type = type
    }
    var longName:String{
        switch type{
        case .Captain:return "Captain"
        case .FirstOfficer:return "First Officer"
        case .FlightAttendant:return "Flight Attendant"
        }
    }
    var shortName:String{
        switch type{
        case .Captain:return "CP"
        case .FirstOfficer:return "FO"
        case .FlightAttendant:return "FA"
        }
    }
    var character:Character{
        switch type{
        case .Captain:return "C"
        case .FirstOfficer:return "F"
        case .FlightAttendant:return "A"
        }
    }
    
    static let allCrewPositions: [BICrewPosition] = {
         return BICrewPositionType.allCases.map { BICrewPosition(type: $0) }
     }()
    
    static func crewPositionforType(_ type: BICrewPositionType) -> BICrewPosition? {
        let all = BICrewPosition.allCrewPositions
        return all.indices.contains(type.rawValue) ? all[type.rawValue] : nil
    }
    
    static func crewPositionforLongName(_ longName: String) -> BICrewPosition? {
        switch longName {
        case "Captain":
            return BICrewPosition.allCrewPositions[BICrewPositionType.Captain.rawValue]
        case "First Officer":
            return BICrewPosition.allCrewPositions[BICrewPositionType.FirstOfficer.rawValue]
        case "Flight Attendant":
            return BICrewPosition.allCrewPositions[BICrewPositionType.FlightAttendant.rawValue]
        default:
            return nil
        }
    }
    
    static func longNameforCrewPositionType(_ type: BICrewPositionType) -> String {
        switch type {
        case .Captain:
            return "Captain"
        case .FirstOfficer:
            return "First Officer"
        case .FlightAttendant:
            return "Flight Attendant"
        }
    }
    
    
    func isEqual(to otherCrewPosition: BICrewPosition) -> Bool {
          return self.type == otherCrewPosition.type
      }
    
    //MARK: Coding Protocol
    
    private static let kCBCrewPositionTypeKey = "Type"
    func encode(with coder: NSCoder) {
        if coder.allowsKeyedCoding {
            coder.encode(type.rawValue, forKey: BICrewPosition.kCBCrewPositionTypeKey)
        }
    }
    
    required init?(coder: NSCoder) {
        if coder.allowsKeyedCoding {
            self.type = BICrewPositionType(rawValue: coder.decodeInteger(forKey: BICrewPosition.kCBCrewPositionTypeKey)) ?? .Captain
        } else {
            return nil
        }
    }
    
    //MARK: Debugging
    var description: String {
        return "type: \(type.rawValue) character: \(character) short name: \(shortName) long name: \(longName)"
    }
}
