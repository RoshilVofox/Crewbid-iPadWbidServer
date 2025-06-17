//
//  CBUtils.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 11/05/25.
//

import Foundation
import ZipArchive
import CoreData

class CBUtils{

    func initialize(){
        // assigning  all the default values needed for the application
        let defaultLineValues = [CBLineValueTypes.cbLineValueTypePay.rawValue, CBLineValueTypes.cbLineValueTypeBlockTime.rawValue, CBLineValueTypes.cbLineValueTypeAircraftChanges.rawValue,CBLineValueTypes.cbLineValueTypePayPerBlock.rawValue, CBLineValueTypes.cbLineValueTypePayPerDay.rawValue]
        let standardDefaults = [kCBDefaultLineValuesKey : defaultLineValues]
        UserDefaults.standard.register(defaults: standardDefaults)
        
        let defaultRound2LineValues = [CBLineValueTypes.cbLineValueTypePay.rawValue, CBLineValueTypes.cbLineValueTypeBlockDaysOff.rawValue, CBLineValueTypes.cbLineValueTypeWeekends.rawValue, CBLineValueTypes.cbLineValueTypeWorkDays.rawValue, CBLineValueTypes.cbLineValueTypePayPerDay.rawValue]
        let standardRound2Defaults = [ kCBRound2DefaultLineValuesKey : defaultRound2LineValues ]
        UserDefaults.standard.register(defaults: standardRound2Defaults)
        
        // Set up the swaptimizer default line values and add them to the register defaults
        let swaptimizerLineValues = [CBLineValueTypes.cbLineValueTypeVTotalPay.rawValue, CBLineValueTypes.cbLineValueTypeVVacayPay.rawValue, CBLineValueTypes.cbLineValueTypeVBlockTime.rawValue, CBLineValueTypes.cbLineValueTypeVDaysOff.rawValue, CBLineValueTypes.cbLineValueTypeVPayPerDay.rawValue]
        let swaptimizerDefaults = [kCBSwaptimizerLineValuesKey : swaptimizerLineValues]
        UserDefaults.standard.register(defaults: swaptimizerDefaults)
        
        // Set up the Fa Vacation default line values and add them to the register defaults
        let faVacationLineValues = [CBLineValueTypes.cbLineValueTypeVTotalPay.rawValue, CBLineValueTypes.cbLineValueTypeVVacayPay.rawValue, CBLineValueTypes.cbLineValueTypeVBlockTime.rawValue, CBLineValueTypes.cbLineValueTypeVDaysOff.rawValue, CBLineValueTypes.cbLineValueTypeVPayPerDay.rawValue]
        let faVacationDefaults = [kCBFaVacationLineValuesKey : faVacationLineValues]
        UserDefaults.standard.register(defaults: faVacationDefaults)
        
        
        let eastCoastCities = ["PWM", "MHT", "BOS", "PVD", "BDL", "ROC", "ISP", "LGA", "BUF", "EWR", "PHL", "PIT", "BWI", "IAD", "DCA", "ORF", "RIC", "RDU", "CLT", "GSP", "CHS", "ATL", "JAX", "ECP", "MCO", "TPA", "PBI", "FLL", "RSW", "PNS", "BHM", "BNA", "MEM", "SDF", "CLE", "CAK", "CMH", "DAY", "DTW", "IND", "ALB", "CVG"]
        var eccs = [String:Any]()
        var arrEastCoast = NSArray()
        var arrEastCoastSelected = NSArray()
        if let aList = UserDefaults.standard.object(forKey: kCBEastCoastCitiesList) as? [Any] {
            arrEastCoast = NSArray(array: aList)
        }
        if !((arrEastCoast.count) > 0) {
            eccs = [kCBEastCoastCitiesList : eastCoastCities]
            UserDefaults.standard.register(defaults: eccs)
        }
        // Set the default selected cities. By default all are selected
        // But first remove the bid period base
        if let aList = UserDefaults.standard.object(forKey: kCBSelectedEastCoastCities) as? [Any] {
            arrEastCoastSelected = NSArray(array: aList)
        }
        if !(arrEastCoastSelected.count > 0) {
            eccs = [kCBSelectedEastCoastCities : eastCoastCities]
            UserDefaults.standard.register(defaults: eccs)
        }
        let westCoastCities = ["LGB", "SEA", "GEG", "PDX", "BOI", "RNO", "SMF", "OAK", "SFO", "SJC", "BUR", "LAX", "ONT", "SNA", "SAN", "LAS", "PHX", "TUS", "SLC", "DEN", "ABQ", "ELP"]

        var arrWestCoast = NSArray()
        var arrWestCoastSelected = NSArray()
        var wccs = [String:Any]()
        
        if let aList = UserDefaults.standard.object(forKey: kCBWestCoastCitiesList) as? [Any] {
            arrWestCoast = NSArray(array: aList)
        }
        if !(arrWestCoast.count > 0) {
            wccs = [kCBWestCoastCitiesList : westCoastCities]
            UserDefaults.standard.register(defaults: wccs)
        }
        // Set the default selected cities. By default all are selected
        if let aList = UserDefaults.standard.object(forKey: kCBSelectedWestCoastCities) as? [Any] {
            arrWestCoastSelected = NSArray(array: aList)
        }
        if !(arrWestCoastSelected.count > 0) {
            wccs = [kCBSelectedWestCoastCities : westCoastCities]
            UserDefaults.standard.register(defaults: wccs)
        }
        
        let ncCities = ["SJU"]// San Juan, Puerto Rico
        var arrNonConUS = NSArray()
        var arrNonConUSSelected = NSArray()
        var nccs = [String:Any]()
        if let aList = UserDefaults.standard.object(forKey: kCBNonConusCitiesList) as? [Any] {
            arrNonConUS = NSArray(array: aList)
        }
        if !(arrNonConUS.count > 0) {
            nccs = [kCBNonConusCitiesList : ncCities]
            UserDefaults.standard.register(defaults: nccs)
        }
        // Set the default selected cities. By default all are selected
        if let aList = UserDefaults.standard.object(forKey: kCBSelectedNonConusCities) as? [Any] {
            arrNonConUSSelected = NSArray(array: aList)
        }
        if !(arrNonConUSSelected.count > 0) {
            nccs = [kCBSelectedNonConusCities : ncCities]
            UserDefaults.standard.register(defaults: nccs)
        }
        // Initialize international cities
        let intlCities = ["LIR", "AUA", "CUN",  "MBJ", "MEX", "NAS", "SJO", "PUJ", "PVR", "SJD", "SJU", "TZA", "BZE", "CZM", "GCM", "HAV", "PLS", "SNU", "VRA"]
        var arrAllInternationalCities = NSArray()
        var acsInternational = [String:Any]()
        if let aList = UserDefaults.standard.object(forKey: kCBAllCitiesList) as? [Any] {
            arrAllInternationalCities = NSArray(array: aList)
        }
        if !(arrAllInternationalCities.count > 0) {
            acsInternational = [kCBInternationalCitiesList : intlCities]
            UserDefaults.standard.register(defaults: acsInternational)
        }
        // Initialize all cities
        let allCities = ["LGB", "NAS", "SJO", "PVR", "TZA", "AUA", "CUN", "MBJ", "MEX", "PUJ", "SJD", "SJU", "PWM", "MHT", "BOS", "PVD", "BDL", "ROC", "ISP", "LGA", "BUF", "EWR", "PHL", "PIT", "BWI", "IAD", "DCA", "ORF", "RIC", "RDU", "CLT", "GSP", "CHS", "ATL", "JAX", "ECP", "MCO", "TPA", "PBI", "FLL", "RSW", "EYW", "PNS", "BHM", "BNA", "MEM", "SDF", "CLE", "CAK", "CMH", "DAY", "DTW", "IND", "FNT", "GRR", "MSY", "JAN", "STL", "MDW", "MKE", "MSP", "DSM", "OMA", "MCI", "BKG", "ICT", "LIT", "TUL", "OKC", "AMA", "LBB", "DAL", "AUS", "HOU", "MAF", "SAT", "CRP", "HRL", "SEA", "GEG", "PDX", "BOI", "RNO", "SMF", "OAK", "SFO", "SJC", "BUR", "LAX", "ONT", "SNA", "SAN", "LAS", "PHX", "TUS", "SLC", "DEN", "ABQ", "ELP", "ALB", "CVG", "BDA"]
        
        var arrAllCities = NSArray()
        var arrAllCitiesSelected = NSArray()
        var acs = [String:Any]()
        if let aList = UserDefaults.standard.object(forKey: kCBAllCitiesList) as? [Any] {
            arrAllCities = NSArray(array: aList)
        }
        if !(arrAllCities.count > 0) {
            acs = [kCBAllCitiesList : allCities]
            UserDefaults.standard.register(defaults: acs)
        }
        
        if let aList = UserDefaults.standard.object(forKey: kCBSelectedAllCities) as? [Any] {
            arrAllCitiesSelected = NSArray(array: aList)
        }
        
        if !(arrAllCitiesSelected.count > 0) {
            acs = [kCBSelectedAllCities : allCities]
            UserDefaults.standard.register(defaults: acs)
        }
        //timeZones
        let timeZones = ["PWM" : "US/Eastern", "MHT" : "US/Eastern", "BOS" : "US/Eastern", "PVD" : "US/Eastern", "BDL" : "US/Eastern", "ROC" : "US/Eastern", "ISP" : "US/Eastern", "LGA" : "US/Eastern", "ALB" : "US/Eastern", "BUF" : "US/Eastern", "EWR" : "US/Eastern", "PHL" : "US/Eastern", "PIT" : "US/Eastern", "BWI" : "US/Eastern", "IAD" : "US/Eastern", "DCA" : "US/Eastern", "ORF" : "US/Eastern", "RIC" : "US/Eastern", "RDU" : "US/Eastern", "CLT" : "US/Eastern", "GSP" : "US/Eastern", "CHS" : "US/Eastern", "ATL" : "US/Eastern", "JAX" : "US/Eastern", "MCO" : "US/Eastern", "TPA" : "US/Eastern", "PBI" : "US/Eastern", "FLL" : "US/Eastern", "RSW" : "US/Eastern", "EYW" : "US/Eastern", "SDF" : "US/Eastern", "CLE" : "US/Eastern", "CAK" : "US/Eastern", "CMH" : "US/Eastern", "DAY" : "US/Eastern", "DTW" : "US/Eastern", "IND" : "US/Eastern", "FNT" : "US/Eastern", "GRR" : "US/Eastern", "CVG" : "US/Eastern",
            // CST CITIES
            "ECP" : "US/Central", "BHM" : "US/Central", "BNA" : "US/Central", "MEM" : "US/Central", "PNS" : "US/Central", "MSY" : "US/Central", "JAN" : "US/Central", "STL" : "US/Central", "MDW" : "US/Central", "MKE" : "US/Central", "MSP" : "US/Central", "DSM" : "US/Central", "OMA" : "US/Central", "MCI" : "US/Central", "BKG" : "US/Central", "IAH" : "US/Central", "ICT" : "US/Central", "LIT" : "US/Central", "TUL" : "US/Central", "OKC" : "US/Central", "AMA" : "US/Central", "LBB" : "US/Central", "DAL" : "US/Central", "AUS" : "US/Central", "HOU" : "US/Central", "MAF" : "US/Central", "SAT" : "US/Central", "CRP" : "US/Central", "HRL" : "US/Central",
            // MST CITIES
            "BOI" : "US/Mountain","SLC" : "US/Mountain","DEN" : "US/Mountain","ABQ" : "US/Mountain","ELP" : "US/Mountain",
            // PST CITIES
            "SMF" : "US/Pacific","OAK" : "US/Pacific","SFO" : "US/Pacific","SJC" : "US/Pacific","BUR" : "US/Pacific","LAX" : "US/Pacific","ONT" : "US/Pacific","SNA" : "US/Pacific","SAN" : "US/Pacific","SEA" : "US/Pacific","GEG" : "US/Pacific","PDX" : "US/Pacific","LAS" : "US/Pacific","RNO" : "US/Pacific","LGB" : "US/Pacific","BLI" : "US/Pacific",
            // ARIZONA CITIES
            "PHX" : "America/Phoenix","TUS" : "America/Phoenix","SJU" : "America/Puerto_Rico","AUA" : "America/Aruba","CUN" : "America/Cancun","MBJ" : "America/Jamaica","MEX" : "America/Mexico_City","PUJ" : "America/Santo_Domingo","SJD" : "America/Mazatlan","NAS" : "America/Nassau","PVR" : "America/Mexico_City","SJO" : "America/Costa_Rica","TZA" : "America/Belize","BDA" : "Atlantic/Bermuda","BZE" : "America/Belize","GCM" : "America/Cayman","HAV" : "America/Havana","LIR" : "America/Costa_Rica","PLS" : "America/Grand_Turk","SNU" : "America/Havana","VRA" : "America/Havana","OGG" : "US/Hawaii","HNL" : "US/Hawaii","LIH" : "US/Hawaii","KOA" : "US/Hawaii","ITO" : "US/Hawaii","HDN" : "US/Mountain","MIA" : "US/Eastern","PSP" : "US/Pacific","MTJ" : "US/Mountain","ORD" : "US/Central","SRQ" : "US/Eastern","BZN" : "US/Mountain","COS" : "US/Mountain","CZM" : "America/Cancun","EUG" : "US/Pacific","FAT" : "US/Pacific","MYR" : "US/Eastern","SAV" : "US/Eastern","SBA" : "US/Pacific","SYR" : "US/Eastern","VPS" : "US/Central",]
        
        let dct = UserDefaults.standard.object(forKey: kCBTimeZoneCitiesList)
        if (dct == nil) {
            UserDefaults.standard.register(defaults: [kCBTimeZoneCitiesList:timeZones])
        }
        
        UserDefaults.standard.set(timeZones, forKey: kCBTimeZoneCitiesList)
        
        let intlCitiesDict = ["AUA" : "YES","CUN" : "YES","MBJ" : "YES","MEX" : "YES","PUJ" : "YES","SJD" : "YES","SJU" : "YES","NAS" : "YES","PVR" : "YES","SJO" : "YES","TZA" : "YES","LIR" : "YES","BZE" : "YES"]
        let intCitiesDefaultDict = [kCBInternationalCitiesDict : intlCitiesDict]
        UserDefaults.standard.register(defaults: intCitiesDefaultDict)
        
        
        
        let hawaiiCities = ["HNL","ITO","LIH","KOA","OGG"]
     
        
        
        
        
        let CPRound1:[String : Any] = ["AbscenceTypeEnd" : 75,"AbscenceTypeSt" : 74,"AbsenceDatesEnd" : 87,"AbsenceDatesSt" : 77,"BidTypeEnd" : 24,"BidTypeSt" : 24,"ChkPltEnd" : 71,"ChkPltSt" : 71,"EbgEnd" : 15,"EbgSt" : 15,"EmpIdEnd" : 35,"EmpIdSt" : 30,"Id" : 71,"LcEnd" : 28,"LcSt" : 28,"NameEnd" : 69,"NameSt" : 37,"Position" : "CP","Round" : 1,"SeqNumEnd" : 4,"SeqNumSt" : 1]
        let CPRound2:[String : Any] = ["AbscenceTypeEnd" : 67,"AbscenceTypeSt" : 66,"AbsenceDatesEnd" : 79,"AbsenceDatesSt" : 69,"BidTypeEnd" : 14,"BidTypeSt" : 14,"ChkPltEnd" : 63,"ChkPltSt" : 63,"EbgEnd" : 22,"EbgSt" : 22,"EmpIdEnd" : 29,"EmpIdSt" : 24,"Id" : 71,"LcEnd" : 19,"LcSt" : 19,"NameEnd" : 61,"NameSt" : 31,"Position" : "CP","Round" : 2,"SeqNumEnd" : 4,"SeqNumSt" : 1]
                                              
        let FORound1:[String : Any] = ["AbscenceTypeEnd" : 75,"AbscenceTypeSt" : 74,"AbsenceDatesEnd" : 87,"AbsenceDatesSt" : 77,"BidTypeEnd" : 24,"BidTypeSt" : 24,"ChkPltEnd" : 71,"ChkPltSt" : 71,"EbgEnd" : 15,"EbgSt" : 15,"EmpIdEnd" : 35,"EmpIdSt" : 30,"Id" : 71,"LcEnd" : 28,"LcSt" : 28,"NameEnd" : 69,"NameSt" : 37,"Position" : "FO","Round" : 1,"SeqNumEnd" : 4,"SeqNumSt" : 1]
        let FORound2:[String : Any] = [  "AbscenceTypeEnd" : 67,"AbscenceTypeSt" : 66,"AbsenceDatesEnd" : 79,"AbsenceDatesSt" : 69,"BidTypeEnd" : 14,"BidTypeSt" : 14,"ChkPltEnd" : 63,"ChkPltSt" : 63,"EbgEnd" : 22,"EbgSt" : 22,"EmpIdEnd" : 29,"EmpIdSt" : 24,"Id" : 71,"LcEnd" : 19,"LcSt" : 19,"NameEnd" : 61,"NameSt" : 31,"Position" : "FO","Round" : 2,"SeqNumEnd" : 4,"SeqNumSt" : 1]
        
        let arrayDetails = [CPRound1,CPRound2,FORound1,FORound2]
        
    }
    
    
    static func downloadCrewBidUpdateFile(appDel: AppDelegate, completion: @escaping (Bool) -> Void) {
        // 1. Construct the URL
        guard let url = URL(string: EndPoint.shared.crewBidUpdate) else {
            completion(false)
            return
        }

        do {
            // 2. Download Data
            let urlData = try Data(contentsOf: url)

            // 3. Convert data to string using ASCII encoding
            if let myString = String(data: urlData, encoding: .ascii) {
                print(myString)
            }

            // 4. Get documents directory
            let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentsDir.appendingPathComponent("CrewBidUpdate.txt")

            // 5. Write to file
            try urlData.write(to: fileURL)

            // 6. Read back the file using Windows Hebrew encoding
            let windowsHebrewEncoding = String.Encoding(rawValue: 0x0505)
            let crewBidUpdateText = try String(contentsOf: fileURL, encoding: windowsHebrewEncoding)

            // 7. Parse the update text
            parseCrewBidUpdateFile(text: crewBidUpdateText)

            // 8. Completion
            completion(true)
        } catch {
            print("Download or parsing failed:", error)
            completion(false)
        }
    }
    
    static func parseCrewBidUpdateFile(text: String) {
        
        let scanner = Scanner(string: text)
        let dataSource = GlobalBidInfo.shared
        autoreleasepool {
            let fetchRequest: NSFetchRequest<CrewBidUpdateData> = CrewBidUpdateData.fetchRequest()

            let context = dataSource.managedObjectContext
            var crewBidDataVersion: CrewBidUpdateData

            do {
                let fetchedObjects = try context.fetch(fetchRequest)
                
                if let existingData = fetchedObjects.first {
                    crewBidDataVersion = existingData
                } else {
                    crewBidDataVersion = CrewBidUpdateData(context: context)
                }

            } catch {
                print("Failed to fetch CrewBidUpdateData: \(error)")
                crewBidDataVersion = CrewBidUpdateData(context: context)
            }
            
//            let success = self.fetchCityList(crewBidDataVersion, file: text)
//            if !success {
//                return
//            }
            
        }
        
    }
    
    
    static func getCityWithTimeZone(from cityName: String, timeZone: String) -> [String: String] {
        return [cityName: timeZone]
    }
    
    static func removeWhiteSpace(from string: String) -> String {
        return string.trimmingCharacters(in: .whitespacesAndNewlines)
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
    
    class func numberOfDays(inMonth month: Int, forYear year: Int) -> Int {
        let dateComponents = DateComponents(year: year, month: month)
        let calendar = Calendar.current
        let date = calendar.date(from: dateComponents)!
        
        let range = calendar.range(of: .day, in: .month, for: date)!
        let numDays = range.count
        
        return numDays
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
    
    class func findMissingIndex(inRedEyeTrip trip: BITrip) -> Int {
        let result = findMissingDateAndIndex(forRedEyeTrip: trip)
        return (result["missingIndex"] as? NSNumber)?.intValue ?? 0
    }
    
    class func findMissingDate(forRedEyeTrip trip: BITrip) -> Date? {
        let result = findMissingDateAndIndex(forRedEyeTrip: trip)
        return result["missingDate"] as? Date
    }
    
    class func findMissingDateAndIndex(forRedEyeTrip trip: BITrip?) -> [String: Any] {
        var missingDayIndex = -1
        var missingDate: Date? = nil
        var isMissingDateIsLastDay = false

        if let trip = trip, trip.isRedEyeTrip {
            let calendar = Calendar(identifier: .gregorian)
            var calendarWithTimeZone = calendar
            calendarWithTimeZone.locale = Locale(identifier: "en_US")
            calendarWithTimeZone.timeZone = TimeZone(identifier: "US/Central")!

            var dateComps = calendarWithTimeZone.dateComponents([.year, .month, .day], from: trip.startDate!)

            let df = DateFormatter()
            df.dateFormat = "dd-MMM-yyyy"
            df.timeZone = TimeZone(identifier: "US/Central")

            var tripDates: [String] = []

            if let orderedDays = trip.info?.orderedDays as? [BIDayInfo] {
                for dayInfo in orderedDays {
                    for legInfo in dayInfo.orderedLegs as? [BILegInfo] ?? [] {
                        dateComps.minute = legInfo.departMinutes?.intValue ?? 0
                        if let legStartDate = calendarWithTimeZone.date(from: dateComps) {
                            tripDates.append(df.string(from: legStartDate))
                        }
                    }
                }
            }

            let uniqueDatesArray = Array(NSOrderedSet(array: tripDates)) as! [String]

            var shouldBreak = false

            for i in 0..<uniqueDatesArray.count - 1 where !shouldBreak {
                guard let currentDate = df.date(from: uniqueDatesArray[i]),
                      let nextDate = df.date(from: uniqueDatesArray[i + 1]) else {
                    continue
                }

                let startOfCurrentDate = calendarWithTimeZone.startOfDay(for: currentDate)
                let startOfNextDate = calendarWithTimeZone.startOfDay(for: nextDate)

                let daysBetween = calendarWithTimeZone.dateComponents([.day], from: startOfCurrentDate, to: startOfNextDate).day ?? 0

                if daysBetween > 1 {
                    for j in 1..<daysBetween {
                        missingDate = calendarWithTimeZone.date(byAdding: .day, value: j, to: startOfCurrentDate)
                        if let calendarDaysCount = trip.info?.calendarDaysCount?.intValue,
                           uniqueDatesArray.count != calendarDaysCount {
                            missingDayIndex = i + 1
                        } else {
                            missingDayIndex = -1
                        }
                        missingDayIndex = i + 1
                        shouldBreak = true
                        break
                    }
                } else {
                    if i == uniqueDatesArray.count - 1 || i == uniqueDatesArray.count - 2 {
                        if daysBetween == 1 {
                            missingDate = calendarWithTimeZone.date(byAdding: .day, value: 1, to: startOfNextDate)
                            if trip.line?.bidPeriod?.isFABid() == true {
                                missingDayIndex = i + 1
                            } else {
                                missingDayIndex = 1
                            }
                            isMissingDateIsLastDay = true
                            shouldBreak = true
                            break
                        }
                    }
                }
            }
        }

        return [
            "missingDate": missingDate as Any? ?? NSNull(),
            "missingIndex": missingDayIndex,
            "isMissingDateIsLastDay": isMissingDateIsLastDay
        ]
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
    class func getFALISTWB4JSONFromServer(){
            guard let url = URL(string: EndPoint.shared.faListWB4Json) else {
                print("Invalid URL")
                return
            }
            var request = URLRequest(url: url)
     
            let config = URLSessionConfiguration.default
    //        config.timeoutIntervalForRequest = 30
    //        config.timeoutIntervalForResource = 30
     
            let session = URLSession(configuration: config)
            let task = session.dataTask(with: request) { data, response, error in
                
                if let error = error{
                //handle error
                }
                
                if let data = data {
                    do {
                        if let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                            print("JSON Response: \(responseDict)")
                            
                            self.writeJSONDictToFile(jsonDict: responseDict)
                        }
                    } catch {
                        print("JSON Parsing Error: \(error.localizedDescription)")
                    }
                }
     
            }
     
            task.resume()
        }
        
    static func writeJSONDictToFile(jsonDict: [String: Any]) {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: jsonDict, options: .prettyPrinted)
                
                // Convert JSON data to string (optional, only needed if you want to see it as a string)
                let jsonString = String(data: jsonData, encoding: .utf8)
                
                // Get path to the Documents directory
                let fileManager = FileManager.default
                let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
                let fileName = "falistwb4.json"
                let fileURL = BIBidInfo.shared.downloadDirectory().appendingPathComponent(fileName)
                
                // Write data to file (atomically = true writes to a temp file first, then replaces)
                try jsonString?.data(using: .utf8)?.write(to: fileURL, options: .atomic)
                
                print("JSON successfully written buddy bid list to: \(fileURL.path)")
                
            } catch {
                print("Failed to write JSON to file: \(error.localizedDescription)")
            }
        }
    
    class func getGroundTimeBetween(reportTime: Int, releaseTime: Int) -> Int {
        var reportTime = reportTime
        var shouldAdd2400 = false

        // Normalize times if they exceed 2400
        if reportTime >= 2400 {
            reportTime -= 2400
            shouldAdd2400 = true
        }

        // Convert HHMM to minutes
        let releaseMins = (releaseTime / 100) * 60 + (releaseTime % 100)
        let reportMins = (reportTime / 100) * 60 + (reportTime % 100)

        // Calculate the difference
        var differenceInMinutes = reportMins - releaseMins

        // Handle wrap-around to the next day
        if differenceInMinutes < 0 {
            differenceInMinutes += 1440
        }

        if shouldAdd2400 {
            differenceInMinutes += 1440
        }

        return differenceInMinutes
    }
    
    static func getMissingTripJSON(year: Int,month: Int,round: Int,base: String,position: String,completion: @escaping (Bool) -> Void) {
         let app = AppState.shared
        app.missingTripInfo = nil
            
            let dict: [String: Any] = ["Year": year,"Month": month,"Round": round,"Domicile": base,"Position": position]
            
            guard let url = URL(string: EndPoint.shared.getScrappedMissedTrips) else {
                completion(false)
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

            do {
                let jsonData = try JSONSerialization.data(withJSONObject: dict)
                let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
                print("Request: \(jsonString)")
                request.httpBody = jsonString.data(using: .utf8)
            } catch {
                print("JSON serialization error: \(error)")
                completion(false)
                return
            }

            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 30
            config.timeoutIntervalForResource = 30

            let session = URLSession(configuration: config)
            let task = session.dataTask(with: request) { data, response, error in
                
                guard let data = data else {
                    completion(false)
                    return
                }

                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    print("Response JSON: \(String(describing: json))")
                    
                    if app.jsonSecretIsOn {
                        app.missingTripInfo = json
                    }
                    completion(true)
                } catch {
                    print("JSON parsing error: \(error)")
                    completion(false)
                }
            }

            task.resume()
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
            return "CA"
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
    
    class func convertTimeToMinutes(_ time: Int?) -> Int? {
        guard let time = time else {
            return nil
        }
        
        let hours = time / 100
        let minutes = time % 100
        let totalMinutes = hours * 60 + minutes

        return totalMinutes
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
    
    static func getMissingTripJSONFromYear(year:String, month:String, round:String, base:String, position:String, finishedHandler: @escaping (Bool) -> Void){
        let appState = AppState.shared
        appState.missingTripInfo = nil
        let dict:[String:Any] = ["Year":year,"Month":month,"Round":round,"Domicile":base,"Position":position]
        let urlString = URL(string: EndPoint.shared.getScrappedMissedTrips)
        var urlRequest = URLRequest(url: urlString!)
        let jsonData = try! JSONSerialization.data(withJSONObject: dict)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        urlRequest.httpBody = jsonString.data(using: .utf8)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let dataTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                print("Error: \(error)")
                finishedHandler(false)
                return
            }
            if let data = data{
                let jsonDict = try! JSONSerialization.jsonObject(with: data, options: []) as! [String:Any]
                if appState.jsonSecretIsOn{
                    appState.missingTripInfo = jsonDict
                }
                finishedHandler(true)
            }else{
                finishedHandler(false)
            }
            
        }
        dataTask.resume()
    }
    
    
    
//    static func findMissingDateAndIndex(forRedEyeTrip trip: BITrip) -> [String: Any] {
//        var missingDayIndex = -1
//        var missingDate: Date? = nil
//        var isMissingDateIsLastDay = false
//        
//        if (trip != nil && trip.isRedEyeTrip) {
//            var calendar = Calendar(identifier: .gregorian)
//            calendar.locale = Locale(identifier: "en_US")
//            calendar.timeZone = TimeZone(identifier: "US/Central")!
//            var dateComps = calendar.dateComponents([.year, .month, .day], from: trip.startDate!)
//            let df = DateFormatter()
//            df.dateFormat = "dd-MM-yyyy"
//            df.timeZone = TimeZone(identifier: "US/Central")
//            
//            var tripDates: [String] = []
//            tripDates.reserveCapacity(4)
//            for dayInfo in trip.info?.orderedDays as! [BIDayInfo] {
//                for lengInfo in dayInfo.orderedLegs as! [BILegInfo] {
//                    dateComps.minute = lengInfo.departMinutes?.intValue
//                    let legStartDate = calendar.date(from: dateComps)!
//                    tripDates.append(df.string(from: legStartDate))
//                }
//            }
//            let uniqueDatesSet = NSOrderedSet(array: tripDates)
//            let uniqueDatesArray = uniqueDatesSet.array as? [String] ?? []
//            
//            var shouldBreak = false // Flag to break the outer loop
//            for i in 0..<uniqueDatesArray.count - 1 where shouldBreak == false {
//                let currentDate = df.date(from: uniqueDatesArray[i])
//                let nextDate = df.date(from: uniqueDatesArray[i + 1])
//                let startOfCurrentDate = calendar.startOfDay(for: currentDate!)
//                let startOfNextDate: Date = calendar.startOfDay(for: nextDate!)
//                
//                let daysBetween = calendar.dateComponents([.day], from: startOfCurrentDate, to: startOfNextDate).day ?? 0
//                if (daysBetween > 1) {
//                    for j in 1..<daysBetween {
//                        let missingDate = calendar.date(byAdding: .day, value: j, to: startOfCurrentDate)!
//                        if (uniqueDatesArray.count != trip.info?.calendarDaysCount?.intValue) {
//                            missingDayIndex = i + 1
//                        }
//                        else {
//                            missingDayIndex = -1
//                        }
//                        missingDayIndex = i + 1
//                        shouldBreak = true
//                        break // Exit loop after finding the first missing date
//                    }
//                }
//                else {
//                    // This is the case where the date is missing at the end of the DutyPeriod isntead of missing in between.
//                        // So we have added one date manually to the startDate and set the missingIndex as 1;
//                    if (i == uniqueDatesArray.count - 1 || i == uniqueDatesArray.count - 2) {
//                        if (daysBetween == 1) {
//                            missingDate = calendar.date(byAdding: .day, value: 1, to: startOfNextDate)
//                            let isFa = trip.line?.bidPeriod?.isFABid()
//                            if (isFa!) {
//
//                            }
//                        }
//                    }
//                }
//            }
//        }
//    }

}
