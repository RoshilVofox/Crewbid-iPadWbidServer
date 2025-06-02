//
//  CBUtils.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 11/05/25.
//

import Foundation
import ZipArchive

class CBUtils{
    
    static let timeZonesArray = ["PWM" : "US/Eastern",
                     "MHT" : "US/Eastern",
                     "BOS" : "US/Eastern",
                     "PVD" : "US/Eastern",
                     "BDL" : "US/Eastern",
                     "ROC" : "US/Eastern",
                     "ISP" : "US/Eastern",
                     "LGA" : "US/Eastern",
                     "ALB" : "US/Eastern",
                     "BUF" : "US/Eastern",
                     "EWR" : "US/Eastern",
                     "PHL" : "US/Eastern",
                     "PIT" : "US/Eastern",
                     "BWI" : "US/Eastern",
                     "IAD" : "US/Eastern",
                     "DCA" : "US/Eastern",
                     "ORF" : "US/Eastern",
                     "RIC" : "US/Eastern",
                     "RDU" : "US/Eastern",
                     "CLT" : "US/Eastern",
                     "GSP" : "US/Eastern",
                     "CHS" : "US/Eastern",
                     "ATL" : "US/Eastern",
                     "JAX" : "US/Eastern",
                     "MCO" : "US/Eastern",
                     "TPA" : "US/Eastern",
                     "PBI" : "US/Eastern",
                     "FLL" : "US/Eastern",
                     "RSW" : "US/Eastern",
                     "EYW" : "US/Eastern",
                     "SDF" : "US/Eastern",
                     "CLE" : "US/Eastern",
                     "CAK" : "US/Eastern",
                     "CMH" : "US/Eastern",
                     "DAY" : "US/Eastern",
                     "DTW" : "US/Eastern",
                     "IND" : "US/Eastern",
                     "FNT" : "US/Eastern",
                     "GRR" : "US/Eastern",
                     "CVG" : "US/Eastern",
                     // CST CITIES
                     "ECP" : "US/Central",
                     "BHM" : "US/Central",
                     "BNA" : "US/Central",
                     "MEM" : "US/Central",
                     "PNS" : "US/Central",
                     "MSY" : "US/Central",
                     "JAN" : "US/Central",
                     "STL" : "US/Central",
                     "MDW" : "US/Central",
                     "MKE" : "US/Central",
                     "MSP" : "US/Central",
                     "DSM" : "US/Central",
                     "OMA" : "US/Central",
                     "MCI" : "US/Central",
                     "BKG" : "US/Central",
                     "IAH" : "US/Central",
                     "ICT" : "US/Central",
                     "LIT" : "US/Central",
                     "TUL" : "US/Central",
                     "OKC" : "US/Central",
                     "AMA" : "US/Central",
                     "LBB" : "US/Central",
                     "DAL" : "US/Central",
                     "AUS" : "US/Central",
                     "HOU" : "US/Central",
                     "MAF" : "US/Central",
                     "SAT" : "US/Central",
                     "CRP" : "US/Central",
                     "HRL" : "US/Central",
                     // MST CITIES
                     "BOI" : "US/Mountain",
                     "SLC" : "US/Mountain",
                     "DEN" : "US/Mountain",
                     "ABQ" : "US/Mountain",
                     "ELP" : "US/Mountain",
                     // PST CITIES
                     "SMF" : "US/Pacific",
                     "OAK" : "US/Pacific",
                     "SFO" : "US/Pacific",
                     "SJC" : "US/Pacific",
                     "BUR" : "US/Pacific",
                     "LAX" : "US/Pacific",
                     "ONT" : "US/Pacific",
                     "SNA" : "US/Pacific",
                     "SAN" : "US/Pacific",
                     "SEA" : "US/Pacific",
                     "GEG" : "US/Pacific",
                     "PDX" : "US/Pacific",
                     "LAS" : "US/Pacific",
                     "RNO" : "US/Pacific",
                     "LGB" : "US/Pacific",
                     "BLI" : "US/Pacific",
                     // ARIZONA CITIES
                     "PHX" : "America/Phoenix",
                     "TUS" : "America/Phoenix",
                     "SJU" : "America/Puerto_Rico",
                     "AUA" : "America/Aruba",
                     "CUN" : "America/Cancun",
                     "MBJ" : "America/Jamaica",
                     "MEX" : "America/Mexico_City",
                     "PUJ" : "America/Santo_Domingo",
                     "SJD" : "America/Mazatlan",
                     "NAS" : "America/Nassau",
                     "PVR" : "America/Mexico_City",
                     "SJO" : "America/Costa_Rica",
                     "TZA" : "America/Belize",
                     "BDA" : "Atlantic/Bermuda",
                     "BZE" : "America/Belize",
                     "GCM" : "America/Cayman",
                     "HAV" : "America/Havana",
                     "LIR" : "America/Costa_Rica",
                     "PLS" : "America/Grand_Turk",
                     "SNU" : "America/Havana",
                     "VRA" : "America/Havana",
                     "OGG" : "US/Hawaii",
                     "HNL" : "US/Hawaii",
                     "LIH" : "US/Hawaii",
                     "KOA" : "US/Hawaii",
                     "ITO" : "US/Hawaii",
                     "HDN" : "US/Mountain",
                     "MIA" : "US/Eastern",
                     "PSP" : "US/Pacific",
                     "MTJ" : "US/Mountain",
                     "ORD" : "US/Central",
                     "SRQ" : "US/Eastern",
                     "BZN" : "US/Mountain",
                     "COS" : "US/Mountain",
                     "CZM" : "America/Cancun",
                     "EUG" : "US/Pacific",
                     "FAT" : "US/Pacific",
                     "MYR" : "US/Eastern",
                     "SAV" : "US/Eastern",
                     "SBA" : "US/Pacific",
                     "SYR" : "US/Eastern",
                     "VPS" : "US/Central"]
    
   static let allCitiesDict = ["LGB","NAS","SJO","PVR","TZA","AUA","CUN","MBJ","MEX","PUJ","SJD","SJU","PWM","MHT","BOS","PVD","BDL","ROC","ISP","LGA","BUF","EWR","PHL","PIT","BWI","IAD","DCA","ORF","RIC","RDU","CLT","GSP","CHS","ATL","JAX","ECP","MCO","TPA","PBI","FLL","RSW","EYW","PNS","BHM","BNA","MEM","SDF","CLE","CAK","CMH","DAY","DTW","IND","FNT","GRR","MSY","JAN","STL","MDW","MKE","MSP","DSM","OMA","MCI","BKG","ICT","LIT","TUL","OKC","AMA","LBB","DAL","AUS","HOU","MAF","SAT","CRP","HRL","SEA","GEG","PDX","BOI","RNO","SMF","OAK","SFO","SJC","BUR","LAX","ONT","SNA","SAN","LAS","PHX","TUS","SLC","DEN","ABQ","ELP","ALB","CVG","BDA"]
    
    static let intlCitiesDict = ["AUA" : "YES",
                             "CUN" : "YES",
                             "MBJ" : "YES",
                             "MEX" : "YES",
                             "PUJ" : "YES",
                             "SJD" : "YES",
                             "SJU" : "YES",
                             "NAS" : "YES",
                             "PVR" : "YES",
                             "SJO" : "YES",
                             "TZA" : "YES",
                             "LIR" : "YES",
                             "BZE" : "YES"]
    
    static let hawaiiCities = ["HNL","ITO","LIH","KOA","OGG"]
    
    static let ncCities = ["SJU"]
    
    static let CPRound1:[String : Any] = ["AbscenceTypeEnd" : 75,
                           "AbscenceTypeSt" : 74,
                           "AbsenceDatesEnd" : 87,
                           "AbsenceDatesSt" : 77,
                           "BidTypeEnd" : 24,
                           "BidTypeSt" : 24,
                           "ChkPltEnd" : 71,
                           "ChkPltSt" : 71,
                           "EbgEnd" : 15,
                           "EbgSt" : 15,
                           "EmpIdEnd" : 35,
                           "EmpIdSt" : 30,
                           "Id" : 71,
                           "LcEnd" : 28,
                           "LcSt" : 28,
                           "NameEnd" : 69,
                           "NameSt" : 37,
                           "Position" : "CP",
                           "Round" : 1,
                           "SeqNumEnd" : 4,
                           "SeqNumSt" : 1]
    static let CPRound2:[String : Any] = ["AbscenceTypeEnd" : 67,
                                          "AbscenceTypeSt" : 66,
                                          "AbsenceDatesEnd" : 79,
                                          "AbsenceDatesSt" : 69,
                                          "BidTypeEnd" : 14,
                                          "BidTypeSt" : 14,
                                          "ChkPltEnd" : 63,
                                          "ChkPltSt" : 63,
                                          "EbgEnd" : 22,
                                          "EbgSt" : 22,
                                          "EmpIdEnd" : 29,
                                          "EmpIdSt" : 24,
                                          "Id" : 71,
                                          "LcEnd" : 19,
                                          "LcSt" : 19,
                                          "NameEnd" : 61,
                                          "NameSt" : 31,
                                          "Position" : "CP",
                                          "Round" : 2,
                                          "SeqNumEnd" : 4,
                                          "SeqNumSt" : 1]
                                          
    static let FORound1:[String : Any] = ["AbscenceTypeEnd" : 75,
                                          "AbscenceTypeSt" : 74,
                                          "AbsenceDatesEnd" : 87,
                                          "AbsenceDatesSt" : 77,
                                          "BidTypeEnd" : 24,
                                          "BidTypeSt" : 24,
                                          "ChkPltEnd" : 71,
                                          "ChkPltSt" : 71,
                                          "EbgEnd" : 15,
                                          "EbgSt" : 15,
                                          "EmpIdEnd" : 35,
                                          "EmpIdSt" : 30,
                                          "Id" : 71,
                                          "LcEnd" : 28,
                                          "LcSt" : 28,
                                          "NameEnd" : 69,
                                          "NameSt" : 37,
                                          "Position" : "FO",
                                          "Round" : 1,
                                          "SeqNumEnd" : 4,
                                          "SeqNumSt" : 1]
    static let FORound2:[String : Any] = [  "AbscenceTypeEnd" : 67,
                                            "AbscenceTypeSt" : 66,
                                            "AbsenceDatesEnd" : 79,
                                            "AbsenceDatesSt" : 69,
                                            "BidTypeEnd" : 14,
                                            "BidTypeSt" : 14,
                                            "ChkPltEnd" : 63,
                                            "ChkPltSt" : 63,
                                            "EbgEnd" : 22,
                                            "EbgSt" : 22,
                                            "EmpIdEnd" : 29,
                                            "EmpIdSt" : 24,
                                            "Id" : 71,
                                            "LcEnd" : 19,
                                            "LcSt" : 19,
                                            "NameEnd" : 61,
                                            "NameSt" : 31,
                                            "Position" : "FO",
                                            "Round" : 2,
                                            "SeqNumEnd" : 4,
                                            "SeqNumSt" : 1]
    static let arrayDetails = [CPRound1,CPRound2,FORound1,FORound2]
    
    static func loadUserDefaults(){
        let defaults = UserDefaults.standard
        if defaults.object(forKey: kCBTimeZoneCitiesList) == nil{
            defaults.set(CBUtils.timeZonesArray, forKey: kCBTimeZoneCitiesList)
        }
        if defaults.object(forKey: kCBAllCitiesList) == nil{
            defaults.set(CBUtils.allCitiesDict, forKey: kCBAllCitiesList)
        }
        if defaults.object(forKey: kCBInternationalCitiesDict) == nil{
            defaults.set(CBUtils.intlCitiesDict, forKey: kCBInternationalCitiesDict)
        }
        if defaults.object(forKey: KCBDefaultSeniorityListTableDBValues) == nil{
            defaults.set(CBUtils.arrayDetails, forKey: KCBDefaultSeniorityListTableDBValues)
        }
        if defaults.object(forKey: kCBHawaiiCitiesList) == nil{
            defaults.set(CBUtils.hawaiiCities, forKey: kCBHawaiiCitiesList)
        }
    }
 
    

    
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
    
    static func numberOfDays(in month: Int, for year: Int) -> Int {
        var components = DateComponents()
        components.year = year
        components.month = month

        let calendar = Calendar.current

        if let date = calendar.date(from: components),
           let range = calendar.range(of: .day, in: .month, for: date) {
            return range.count
        }

        return 0
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
    static func shortMonthName(month: Int, uc: Bool) -> String {
        switch month {
        case 1, 13: return uc ? "JAN" : "Jan"
        case 2:     return uc ? "FEB" : "Feb"
        case 3:     return uc ? "MAR" : "Mar"
        case 4:     return uc ? "APR" : "Apr"
        case 5:     return uc ? "MAY" : "May"
        case 6:     return uc ? "JUN" : "Jun"
        case 7:     return uc ? "JUL" : "Jul"
        case 8:     return uc ? "AUG" : "Aug"
        case 9:     return uc ? "SEP" : "Sep"
        case 10:    return uc ? "OCT" : "Oct"
        case 11:    return uc ? "NOV" : "Nov"
        case 12, 0: return uc ? "DEC" : "Dec"
        default:    return ""
        }
    }
    static func shortName(for type: BICrewPositionType) -> String {
        switch type {
        case .Captain:
            return "CP"
        case .FirstOfficer:
            return "FO"
        case .FlightAttendant:
            return "FA"
        }
    }
    
    static func convertMinsToHHMM(_ totalMinutes: Int) -> Int {
        var hours = totalMinutes / 60
        let mins = totalMinutes % 60
        // Simulate 24-hour overflow handling
        if hours < 3 {
            hours += 24  // Add 24 hours if less than 3 AM
        }
        let result = hours * 100 + mins
        return result
    }
    
    static func thanksgivingDay(for year: Int) -> UInt {
        switch year {
        case 2014: return 27
        case 2015: return 26
        case 2016: return 24
        case 2017: return 23
        case 2018: return 22
        case 2019: return 28
        case 2020: return 26
        case 2021: return 25
        case 2022: return 24
        case 2023: return 23
        case 2024: return 28
        default:   return 0
        }
    }

    static func rawTimeZoneString(forAirportCode base: String) -> String? {
            guard let timeZones = UserDefaults.standard.dictionary(forKey: kCBTimeZoneCitiesList) as? [String: String] else {
                return nil
            }
            return timeZones[base]
        }
}
