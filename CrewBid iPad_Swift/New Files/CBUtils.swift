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
        let defaultLineValues = [CBLineValueTypes.Pay.rawValue, CBLineValueTypes.BlockTime.rawValue, CBLineValueTypes.AircraftChanges.rawValue,CBLineValueTypes.PayPerBlock.rawValue, CBLineValueTypes.PayPerDay.rawValue]
        let standardDefaults = [kCBDefaultLineValuesKey : defaultLineValues]
        UserDefaults.standard.register(defaults: standardDefaults)
        
        let defaultRound2LineValues = [CBLineValueTypes.Pay.rawValue, CBLineValueTypes.BlockDaysOff.rawValue, CBLineValueTypes.Weekends.rawValue, CBLineValueTypes.WorkDays.rawValue, CBLineValueTypes.PayPerDay.rawValue]
        let standardRound2Defaults = [ kCBRound2DefaultLineValuesKey : defaultRound2LineValues ]
        UserDefaults.standard.register(defaults: standardRound2Defaults)
        
        // Set up the swaptimizer default line values and add them to the register defaults
        let swaptimizerLineValues = [CBLineValueTypes.VTotalPay.rawValue, CBLineValueTypes.VVacayPay.rawValue, CBLineValueTypes.VBlockTime.rawValue, CBLineValueTypes.VDaysOff.rawValue, CBLineValueTypes.VPayPerDay.rawValue]
        let swaptimizerDefaults = [kCBSwaptimizerLineValuesKey : swaptimizerLineValues]
        UserDefaults.standard.register(defaults: swaptimizerDefaults)
        
        // Set up the Fa Vacation default line values and add them to the register defaults
        let faVacationLineValues = [CBLineValueTypes.VTotalPay.rawValue, CBLineValueTypes.VVacayPay.rawValue, CBLineValueTypes.VBlockTime.rawValue, CBLineValueTypes.VDaysOff.rawValue, CBLineValueTypes.VPayPerDay.rawValue]
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
        
        
        
        let arrHawaiiCities = ["HNL","ITO","LIH","KOA","OGG"]
        let hwaaii: [AnyHashable: Any] = [ kCBHawaiiCitiesList : arrHawaiiCities ]
        UserDefaults.standard.register(defaults: hwaaii as? [String : Any] ?? [String : Any]())
        
        
        
        let CPRound1:[String : Any] = ["AbscenceTypeEnd" : 75,"AbscenceTypeSt" : 74,"AbsenceDatesEnd" : 87,"AbsenceDatesSt" : 77,"BidTypeEnd" : 24,"BidTypeSt" : 24,"ChkPltEnd" : 71,"ChkPltSt" : 71,"EbgEnd" : 15,"EbgSt" : 15,"EmpIdEnd" : 35,"EmpIdSt" : 30,"Id" : 71,"LcEnd" : 28,"LcSt" : 28,"NameEnd" : 69,"NameSt" : 37,"Position" : "CP","Round" : 1,"SeqNumEnd" : 4,"SeqNumSt" : 1]
        let CPRound2:[String : Any] = ["AbscenceTypeEnd" : 67,"AbscenceTypeSt" : 66,"AbsenceDatesEnd" : 79,"AbsenceDatesSt" : 69,"BidTypeEnd" : 14,"BidTypeSt" : 14,"ChkPltEnd" : 63,"ChkPltSt" : 63,"EbgEnd" : 22,"EbgSt" : 22,"EmpIdEnd" : 29,"EmpIdSt" : 24,"Id" : 71,"LcEnd" : 19,"LcSt" : 19,"NameEnd" : 61,"NameSt" : 31,"Position" : "CP","Round" : 2,"SeqNumEnd" : 4,"SeqNumSt" : 1]
                                              
        let FORound1:[String : Any] = ["AbscenceTypeEnd" : 75,"AbscenceTypeSt" : 74,"AbsenceDatesEnd" : 87,"AbsenceDatesSt" : 77,"BidTypeEnd" : 24,"BidTypeSt" : 24,"ChkPltEnd" : 71,"ChkPltSt" : 71,"EbgEnd" : 15,"EbgSt" : 15,"EmpIdEnd" : 35,"EmpIdSt" : 30,"Id" : 71,"LcEnd" : 28,"LcSt" : 28,"NameEnd" : 69,"NameSt" : 37,"Position" : "FO","Round" : 1,"SeqNumEnd" : 4,"SeqNumSt" : 1]
        let FORound2:[String : Any] = [  "AbscenceTypeEnd" : 67,"AbscenceTypeSt" : 66,"AbsenceDatesEnd" : 79,"AbsenceDatesSt" : 69,"BidTypeEnd" : 14,"BidTypeSt" : 14,"ChkPltEnd" : 63,"ChkPltSt" : 63,"EbgEnd" : 22,"EbgSt" : 22,"EmpIdEnd" : 29,"EmpIdSt" : 24,"Id" : 71,"LcEnd" : 19,"LcSt" : 19,"NameEnd" : 61,"NameSt" : 31,"Position" : "FO","Round" : 2,"SeqNumEnd" : 4,"SeqNumSt" : 1]
        
        let arrayDetails = [CPRound1,CPRound2,FORound1,FORound2]
        
    }
    
    
    static func downloadCrewBidUpdateFile(appDel: AppDelegate/*, completion: @escaping (Bool) -> Void*/) {
        // 1. Construct the URL
        guard let url = URL(string: EndPoint.shared.crewBidUpdate) else {
//            completion(false)
            return
        }

            let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentsDir.appendingPathComponent("CrewBidUpdate.txt")
        let urlRequest = URLRequest(url: url)
        URLSession.shared.dataTask(with: urlRequest) { data, _, error in
            do {
                if let data = data{
//                    if let myString = String(data: data, encoding: .ascii) {
//                        print(myString)
//                    }
                    try data.write(to: fileURL)
                    
                    let windowsHebrewEncoding = String.Encoding(rawValue: 0x0505)
                    let crewBidUpdateText = try String(contentsOf: fileURL, encoding: windowsHebrewEncoding)
                    
                    parseCrewBidUpdateFile(text: crewBidUpdateText)
                }
            } catch {
                print("Download or parsing failed:", error)

            }
        }.resume()
        
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
    /*
    static func parrseCrewBidUpdateFile(_ fileContent: String) -> Bool {
        //
        var success:Bool = true
        //Parse CrewBid Update file
        if fileContent.contains("File or directory not found") || fileContent.contains("internal server error") {
            return true
        }
        // 1. Initialize NSScanner with string
        let scanner = Scanner(string: fileContent)
        // Auto release pool for releasing local variable after usage
        autoreleasepool {
            //2. Load Core data version list
            var crewBidDataVersion = CrewBidUpdateData()
            
            let managedContext = GlobalBidInfo.shared.managedObjectContext
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
            
            //Create object for entity description
            let entity = NSEntityDescription.entity(forEntityName: "CrewBidUpdateData", in: (managedContext))
            // Set entity to fetch request
            fetchRequest.entity = entity
            // Execute fetch request
            let fetchedObjects = try? managedContext.fetch(fetchRequest)
            if fetchedObjects != nil && (fetchedObjects?.count)! > 0 {
                crewBidDataVersion = (fetchedObjects?[0] as? CrewBidUpdateData)!
            } else {
                crewBidDataVersion = CrewBidUpdateData(entity: entity!, insertInto: managedContext)
            }
            
            success = self.fetchCityList(crewBidDataVersion, fileContent: fileContent)
            
            
            if crewBidDataVersion.cities != nil {
                self.fetchLatestNews(crewBidDataVersion, scanner: scanner, fileContent: fileContent)
            }
            
        }
        return success
    }
    static func fetchLatestNews(_ crewBidVersionController: CrewBidUpdateData, scanner: Scanner, fileContent:String) {
        //1. Scan to the latest news position
        _ = scanner.scanUpToString("LatestNews")
        //2. define number character set
        let numCharSet = CharacterSet(charactersIn: "0123456789")
        //3. Scan up to number and capture the number set
        scanner.currentIndex = fileContent.index(scanner.currentIndex, offsetBy: 11)
        let versionNumber = scanner.scanCharacters(from: numCharSet)
        //4. Check if local version is  null to avoid the crash
        if crewBidVersionController.latestNews == nil {
            crewBidVersionController.latestNews = ""
        }
        //5. Check any version change is occured
        if (crewBidVersionController.latestNews != versionNumber as String?) {
            //6. Download the latest news from VPS directory
            self.checkForNewsWithCompletionHandler(isDownloaded: { (responce: Bool) -> Void in
                if responce {
                    //7. Update the latest news version number to local core data
                    let versionStr = versionNumber! as String
                    crewBidVersionController.latestNews = versionStr
                    DispatchQueue.main.async {
                        if GlobalBidInfo.shared.managedObjectContext.hasChanges {
                            do {
                                try GlobalBidInfo.shared.managedObjectContext.save()
                            } catch {
                                print(error)
                            }
                        }
                    }
                }
            })
        }
    }
    static func fetchCityList(_ crewBidVersionController: CrewBidUpdateData, fileContent: String)-> Bool {
        
        var isCompleted:Bool = false
        // 1 Scan ititial position of CityList
        let scanner = Scanner(string: fileContent)
        //2. define number character set
        let numCharSet = CharacterSet(charactersIn: "0123456789")
        //3. Scan up to number and capture the number set
        _ = scanner.scanUpToString("Cities")
        if scanner.isAtEnd {
            return true
        }
        scanner.currentIndex = fileContent.index(scanner.currentIndex, offsetBy: 7)
        let versionNumber = scanner.scanCharacters(from: numCharSet)
        //4. Check if local version is  null to avoid the crash
        if crewBidVersionController.cities == nil {
            crewBidVersionController.cities = ""
        }
        //5. Check any version change is occured
        if !(crewBidVersionController.cities == versionNumber as String?) || (UserDefaults.standard.object(forKey: kCBInternationalCitiesList) != nil) {
            _ = scanner.scanUpToString("[Cities]")
            scanner.currentIndex = fileContent.index(scanner.currentIndex, offsetBy: 8)
            //6 Scan up to cites end position and store it in the list
            
            let citiesList = scanner.scanUpToString("[CitiesEnd]")
            //7 make City array
            let arrCities1: [String] = (citiesList! as String).components(separatedBy: "\n")
            var arrCities = [String]()
            for str in arrCities1 {
                if str.length > 0 && str != "" && str != "\r" {
                    arrCities.append(str)
                }
            }
            
            //8 Intialize Parse cities list
            let arrInternatinalCities = NSMutableArray()
            let arrWestCoastCities = NSMutableArray()
            let arrEastCoastCities = NSMutableArray()
            let arrAllCities = NSMutableArray()
            let arrEstCities = NSMutableArray()
            let arrCstCities = NSMutableArray()
            let arrMstCities = NSMutableArray()
            let arrPstCities = NSMutableArray()
            let arrNonUsCities = NSMutableArray()
            let arrHawaiiCities = NSMutableArray()
            let dictCitiesTimeZone = NSMutableDictionary()
            
            //9 iterate City list
            for cityListCount in 0..<arrCities.count {
                let cityDetailsString = arrCities[cityListCount]
                let tempCityDetails = cityDetailsString.components(separatedBy: "@").first!
                // 10 Saparate city and its type
                let arrTempCityDetails = tempCityDetails.components(separatedBy: "-")
                
                if cityDetailsString.contains("@") {
                    let searchFromRange = (cityDetailsString as NSString).range(of: "@")
                    let searchToRange = (cityDetailsString as NSString).range(of: "#")
                    let cityTimeZone = (cityDetailsString as NSString).substring(with: NSRange(location: (searchFromRange.location + searchFromRange.length), length: (searchToRange.location - searchFromRange.location - searchFromRange.length)))
                    dictCitiesTimeZone.addEntries(from: CBUtils.getCityWithTimeZone(from: CBUtils.removeWhiteSpace(from: arrTempCityDetails[0]), timeZone: CBUtils.removeWhiteSpace(from: cityTimeZone)))
                }
                
                // 11 Add city to all cities list
                arrAllCities.add(CBUtils.removeWhiteSpace(from: arrTempCityDetails[0]))
                //  arrAllCities.append(self.removeWhiteSpace(arrTempCityDetails[0]))
                //12 Check and Add cities to list
                //W=WestCoast , E=Eastcaost, I=International,P=PstCities ,M= MstCities ,C= CstCities ,S=EstCities
                if arrTempCityDetails.count > 1 && "\(arrTempCityDetails[1])".contains("I"){
                    arrInternatinalCities.add(CBUtils.removeWhiteSpace(from: arrTempCityDetails[0]))
                    //arrInternatinalCities.append(self.removeWhiteSpace(arrTempCityDetails[0]))
                }
                
                if arrTempCityDetails.count > 1 && "\(arrTempCityDetails[1])".contains("W") {
                    arrWestCoastCities.add(CBUtils.removeWhiteSpace(from: arrTempCityDetails[0]))
                }
                
                if arrTempCityDetails.count > 1 && "\(arrTempCityDetails[1])".contains("E") {
                    arrEastCoastCities.add(CBUtils.removeWhiteSpace(from: arrTempCityDetails[0]))
                }
                
                if arrTempCityDetails.count > 1 && "\(arrTempCityDetails[1])".contains("P") {
                    arrPstCities.add(CBUtils.removeWhiteSpace(from: arrTempCityDetails[0]))
                }
                
                if arrTempCityDetails.count > 1 && arrTempCityDetails[1].contains("M") {
                    arrMstCities.add(CBUtils.removeWhiteSpace(from: arrTempCityDetails[0]))
                }
                
                if arrTempCityDetails.count > 1 && "\(arrTempCityDetails[1])".contains("C") {
                    arrCstCities.add(CBUtils.removeWhiteSpace(from: arrTempCityDetails[0]))
                }
                
                if arrTempCityDetails.count > 1 && "\(arrTempCityDetails[1])".contains("S") {
                    arrEstCities.add(CBUtils.removeWhiteSpace(from: arrTempCityDetails[0]))
                }
                
                if arrTempCityDetails.count > 1 && "\(arrTempCityDetails[1])".contains("N") {
                    arrNonUsCities.add(CBUtils.removeWhiteSpace(from: arrTempCityDetails[0]))
                }
                if arrTempCityDetails.count > 1 && "\(arrTempCityDetails[1])".contains("H") {
                    arrHawaiiCities.add(CBUtils.removeWhiteSpace(from: arrTempCityDetails[0]))
                }
            }
            
            //13 . Save the city details in User defaults
            //13.1 Save all cities
            UserDefaults.standard.set(arrAllCities, forKey: kCBAllCitiesList)
            
            if dictCitiesTimeZone.count > 0 {
                let tzDict: [AnyHashable: Any] = [kCBTimeZoneCitiesList: dictCitiesTimeZone]
                UserDefaults.standard.set(dictCitiesTimeZone, forKey: kCBTimeZoneCitiesList)
            }
            
            var alls: [AnyHashable: Any] = [kCBAllCitiesList: arrAllCities]
            UserDefaults.standard.set(arrAllCities, forKey: kCBAllCitiesList)
            UserDefaults.standard.register(defaults: alls as? [String : Any] ?? [String : Any]())
            
            // Set the default selected cities. By default all are selected
            alls = [ kCBSelectedAllCities : arrAllCities ]
            UserDefaults.standard.set(arrAllCities, forKey: kCBSelectedAllCities)
            UserDefaults.standard.register(defaults: alls as? [String : Any] ?? [String : Any]())
            
            //13.2 Save EastCoast cities
            var eccs: [AnyHashable: Any] = [ kCBEastCoastCitiesList : arrEastCoastCities ]
            UserDefaults.standard.set(arrEastCoastCities, forKey: kCBEastCoastCitiesList)
            UserDefaults.standard.register(defaults: eccs as? [String : Any] ?? [String : Any]())
            
            // Set the default selected cities. By default all are selected
            eccs = [ kCBSelectedEastCoastCities : arrEastCoastCities ];
            UserDefaults.standard.set(arrEastCoastCities, forKey: kCBSelectedEastCoastCities)
            UserDefaults.standard.register(defaults: eccs as? [String : Any] ?? [String : Any]())
            
            // 13.3 Save west coast cities
            var wccs: [AnyHashable: Any] = [ kCBWestCoastCitiesList : arrWestCoastCities ]
            UserDefaults.standard.set(arrWestCoastCities, forKey: kCBWestCoastCitiesList)
            UserDefaults.standard.register(defaults: wccs as? [String : Any] ?? [String : Any]())
            
            // Set the default selected cities. By default all are selected
            wccs = [ kCBSelectedWestCoastCities : arrWestCoastCities ]
            UserDefaults.standard.register(defaults: wccs as? [String : Any] ?? [String : Any]())
            UserDefaults.standard.set(arrWestCoastCities, forKey: kCBSelectedWestCoastCities)
            
            //13.4 Save International cities
            var ics: [AnyHashable: Any] = [ kCBInternationalCitiesList : arrInternatinalCities ]
            UserDefaults.standard.set(arrInternatinalCities, forKey: kCBInternationalCitiesList)
            UserDefaults.standard.register(defaults: ics as? [String : Any] ?? [String : Any]())
            
            
            var hwaaii: [AnyHashable: Any] = [ kCBHawaiiCitiesList : arrHawaiiCities ]
            UserDefaults.standard.set(arrHawaiiCities, forKey: kCBHawaiiCitiesList)
            UserDefaults.standard.register(defaults: hwaaii as? [String : Any] ?? [String : Any]())
            
            // Set the default selected cities. By default all are selected
            hwaaii = [ kCBSelectedHawaiiCities : arrHawaiiCities ]
            UserDefaults.standard.register(defaults: hwaaii as? [String : Any] ?? [String : Any]())
            UserDefaults.standard.set(arrHawaiiCities, forKey: kCBSelectedHawaiiCities)
            
            
            // Set the default selected cities. By default all are selected
            ics = [ kCBSelectedInternationalCities : arrInternatinalCities ]
            UserDefaults.standard.set(arrInternatinalCities, forKey: kCBSelectedInternationalCities)
            UserDefaults.standard.register(defaults: ics as? [String : Any] ?? [String : Any]())
            
            let dicinitCity =  NSMutableDictionary ()
            for string in arrInternatinalCities {
                dicinitCity.setObject("YES", forKey: string as! NSCopying)
            }
            UserDefaults.standard.set(dicinitCity, forKey: kCBInternationalCitiesDict)
            //14. Update the latest news version number to local core data
            crewBidVersionController.cities = versionNumber as String?
            //15. Save NonUsCity
            print("\(arrInternatinalCities)")
            print("\(arrNonUsCities)")
            let arrcombined = NSMutableArray()
            //Combining nonconus array and international array
            for i in arrNonUsCities {
                if arrInternatinalCities.contains(i){
                    arrInternatinalCities.remove(i)
                    arrcombined.addObjects(from: arrNonUsCities as! [Any])
                    arrcombined.addObjects(from: arrInternatinalCities as! [Any])
                    
                    //arrcombined = arrNonUsCities + arrInternatinalCities
                } else {
                    // do something else
                }
            }
            var nccs: [AnyHashable: Any] = [ kCBNonConusCitiesList : arrcombined ]
            UserDefaults.standard.set(arrcombined, forKey: kCBNonConusCitiesList)
            UserDefaults.standard.register(defaults: nccs as? [String : Any] ?? [String : Any]())
            // Set the default selected cities. By default all are selected
            UserDefaults.standard.set(arrcombined, forKey: kCBSelectedNonConusCities)
            nccs = [ kCBSelectedNonConusCities : arrcombined ]
            UserDefaults.standard.register(defaults: nccs as? [String : Any] ?? [String : Any]())
            isCompleted = true
        }
        return isCompleted
    }
    static func checkForNewsWithCompletionHandler(isDownloaded: @escaping (Bool) -> Void) {
        // 1. Check network status
        let reachability: Reachability = try! Reachability()
        
        if !reachability.isReachable {
            NotificationCenter.default.post(name: Notification.Name("NetWorkError"), object: nil)
            isDownloaded(false)
            return
        }
        // 2. Contruct URL for fetching News
        // let error: Error?
        let stringURL: String = "http://www.wbidmax.com/downloads/CrewBid/LatestNews.pdf"
        guard let url = URL(string: stringURL) else {
            print("Invalid URL")
            isDownloaded(false)
            return
        }
        
        // 3. Fetch Latest news asynchronously using URLSession
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching news: \(error)")
                isDownloaded(false)
                return
            }
            
            guard let urlData = data else {
                print("No data received")
                isDownloaded(false)
                return
            }
            
            // 4. Load save directory
            let pdfFilePath: String = self.getLatestNewsFilePath()
            guard let urlPath = URL(string: pdfFilePath) else {
                print("Invalid file path")
                isDownloaded(false)
                return
            }
            
            // 5. Write data to directory
            do {
                try urlData.write(to: urlPath, options: .atomic)
                let filePath = urlPath.path
                let fileManager = FileManager.default
                
                // 6. Checking if saving is successful
                if fileManager.fileExists(atPath: filePath) {
                    print("FILE AVAILABLE")
                    isDownloaded(true)
                } else {
                    print("FILE NOT AVAILABLE")
                    isDownloaded(false)
                }
            } catch {
                print("Error saving file: \(error)")
                isDownloaded(false)
            }
        }

        // Start the async task
        task.resume()
    }
    static func getLatestNewsFilePath() -> String {
        let paths: [Any] = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDir: String = paths[0] as? String ?? ""
        return URL(fileURLWithPath: documentsDir).appendingPathComponent("LatestNews.pdf").absoluteString
    }
    */
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
    
    class func isDateMissingInPreviousDay(_ trip:BITrip) -> Bool{
        let result = self.findMissingDateAndIndex(forRedEyeTrip: trip)
        return (result["isMissingDateIsLastDay"] as? Bool)!
    }
    
    class func redEyeIconButton(fontSize: CGFloat) -> UIButton {
        let redEyeIconButton = UIButton(type: .custom)
        redEyeIconButton.isUserInteractionEnabled = false

        if #available(iOS 13.0, *) {
            let config = UIImage.SymbolConfiguration(pointSize: fontSize, weight: .regular, scale: .default)
            if let icon = UIImage(systemName: "eye.fill")?.applyingSymbolConfiguration(config) {
                redEyeIconButton.setImage(icon, for: .normal)
                redEyeIconButton.tintColor = .white
            }
        } else {
            redEyeIconButton.setImage(UIImage(named: "redeye"), for: .normal)
        }

        return redEyeIconButton
    }
    
    class func isClawBack(line: BILine, day: BIDay, bidPeriod: BIBidPeriod) -> Bool {
        guard let clawBack = line.clawBack?.floatValue, clawBack > 0 else {
            return false
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US")
        calendar.timeZone = TimeZone(identifier: "US/Central")!

        let dateComponents = calendar.dateComponents([.year, .month, .day], from: day.date!)
        guard let currentDateMonth = dateComponents.month,
              let bidMonth = bidPeriod.month?.intValue,
              currentDateMonth != bidMonth else {
            return false
        }

        guard let vacations = bidPeriod.vacations as? Set<BIVacation> else {
            return false
        }

        for vacay in vacations {
            let cal = Calendar.current

            guard let dayDate = day.date,
                  let vacStart = vacay.startDate,
                  let vacEnd = vacay.endDate else { continue }

            let dayDateOnly = cal.startOfDay(for: dayDate)
            let startDateOnly = cal.startOfDay(for: vacStart)
            let endDateOnly = cal.startOfDay(for: vacEnd)

            let isInRange = (dayDateOnly >= startDateOnly && dayDateOnly <= endDateOnly)

            if isInRange {
                return true
            }
        }

        return false
    }
    
    static func weekDay(from date: Date) -> Int {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        // Sunday = 1, Monday = 2, ..., Saturday = 7
        return weekday
    }
    
    class func popcount_few_ones(_ x: UInt64) -> Int {
          var x = x
          var count: Int
          count = 0
          while (x != 0) {
              x &= x - 1
              count += 1
          }
          return count
      }
    
    class func timeZone(forAirportCode base: String) -> TimeZone {
        // If Herb Time is the setting, return Central timezone
        if UserDefaults.standard.integer(forKey: kCBTimeZoneSetting) == CBTimeZoneSetting.herbTime.rawValue {
            return TimeZone(identifier: "US/Central")!
        } else {
            return CBUtils.rawTimeZone(forAirportCode: base)
        }
    }
    
    class func rawTimeZone(forAirportCode base: String) -> TimeZone {
        let timeZones = UserDefaults.standard.object(forKey: kCBTimeZoneCitiesList) as? [AnyHashable : Any]
        var tz = TimeZone(identifier: "US/Central")!
        let tzString = timeZones?[base] as? String
        if let tzString = tzString {
            tz = TimeZone(identifier: tzString)!
        }
        return tz
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

            if let orderedDays = trip.info?.orderedDays() {
                for dayInfo in orderedDays {
                    for legInfo in dayInfo.orderedLegs {
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
    
    class func compareDatesToDecideRedEye(Date1: Date, Date2: Date) -> Bool {
        // Create a calendar with a fixed time zone (UTC)
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "UTC")!
        
        // Extract year, month, and day components
        let currentComponents = calendar.dateComponents([.year, .month, .day], from: Date1)
        let providedComponents = calendar.dateComponents([.year, .month, .day], from: Date2)
        
        // Ensure components are not nil
        guard let currentYear = currentComponents.year,
              let currentMonth = currentComponents.month,
              let currentDay = currentComponents.day,
              let providedYear = providedComponents.year,
              let providedMonth = providedComponents.month,
              let providedDay = providedComponents.day else {
            return false
        }
        
        // Check for same year
        if currentYear == providedYear {
            if currentMonth == providedMonth {
                // Same month, check day difference
                return (providedDay - currentDay) == 2
            } else if (providedMonth - currentMonth) == 1 {
                // Adjacent months, calculate day difference
                let daysInCurrentMonth = calendar.range(of: .day, in: .month, for: Date1)!.count
                return (daysInCurrentMonth - currentDay + providedDay) == 2
            }
        } else if (providedYear - currentYear) == 1 && currentMonth == 12 && providedMonth == 1 {
            // Transition from December to January
            let daysInCurrentMonth = calendar.range(of: .day, in: .month, for: Date1)!.count
            return (daysInCurrentMonth - currentDay + providedDay) == 2
        }
        
        // Return false for all other cases
        return false
    }
    
    static func changeMinutesToShowHours(_ time: NSNumber) -> NSNumber {
        let totalMinutes = time.intValue

        // Calculate hours and minutes
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        // Create formatted string like "0130" for 1 hour 30 minutes
        let formattedResult = String(format: "%02d%02d", hours, minutes)

        // Convert to NSNumber
        if let outputNumber = Int(formattedResult) {
            return NSNumber(value: outputNumber)
        }

        return 0
    }
    
    class func downloadFlightData(/*completionHandler: @escaping (Bool) -> Void*/) {
        guard let url = URL(string: EndPoint.shared.flightdataJSON) else {
                print("Invalid URL.")
//                completionHandler(false)
                return
            }
        let urlRequest = URLRequest(url: url)
//        let urlData = try! Data(contentsOf: url)
            
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let zipFilePath = documentsDir.appendingPathComponent("FlightDataJson.zip")
        URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            if let data = data {
                do {
                    
                    try data.write(to: zipFilePath, options: .atomic)
                    let defaults = UserDefaults.standard
                    defaults.set(1, forKey: "IsLatestFlightDataDownloaded")
                    defaults.set(false, forKey: "IsNeedtoEnableVacationDifference")
                    unzipFlightDataFile(at: zipFilePath.path)
    //                completionHandler(true)
                } catch {
                    print("Error writing file: \(error)")
    //                completionHandler(false)
                }
            }
        }.resume()
            
        }
    class func getFALISTWB4JSONFromServer(completion: (() -> Void)? = nil) {
        guard let url = URL(string: EndPoint.shared.faListWB4Json) else {
            print("Invalid URL")
            completion?()
            return
        }

        let request = URLRequest(url: url)
        let session = URLSession(configuration: .default)

        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error in getting FA list from server: \(error.localizedDescription)")
                completion?()
                return
            }

            if let data = data {
                do {
                    if let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        self.writeJSONDictToFile(jsonDict: responseDict)
                    }
                } catch {
                    print("JSON Parsing Error: \(error.localizedDescription)")
                }
            }

            // Notify caller when done
            completion?()
        }

        task.resume()
    }
        
    static func writeJSONDictToFile(jsonDict: [String: Any]) {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: jsonDict, options: .prettyPrinted)
                let jsonString = String(data: jsonData, encoding: .utf8)
                let filename = "falistwb4.json"
                let filePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).map(\.path)[0]
                let fileURL = URL(fileURLWithPath: filePath).appendingPathComponent(filename)
                try jsonString?.data(using: .utf8)?.write(to: fileURL, options: .atomic)
                print("JSON successfully written buddy bid list to: \(fileURL.path)")
            } catch {
                print("Failed to write JSON to file: \(error.localizedDescription)")
            }
        }
    
    class func readJSONStringFromFile() -> [String:Any]? {
        let filename = "falistwb4.json"
        let filePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).map(\.path)[0]
        let fileAtPath = URL(fileURLWithPath: filePath).appendingPathComponent(filename).path
        var JSONString:String? = nil
        if let data = NSData(contentsOfFile: fileAtPath){
            JSONString = String(data: data as Data, encoding: .utf8)
        }
        let objData = JSONString?.data(using: .utf8)
        var JSONDict:[String:Any]? = nil
        do{
            if let objData = objData{
                JSONDict = try JSONSerialization.jsonObject(with: objData, options: .mutableContainers) as? [String:Any]
            }
        }catch{
            print("Error parsing FAList JSON: \(error.localizedDescription)")
        }
        return JSONDict
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
                let jsonString = String(data: jsonData, encoding: .utf8)
                print("Request: \(jsonString!)")
                request.httpBody = jsonData
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
    
    
    class func unzipFlightDataFile(at filePath: String) {
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
    
    class func parseFlightData() -> [Any]{
        var app:AppDelegate?
        DispatchQueue.main.async {
            app = UIApplication.shared.delegate as? AppDelegate
        }
        
        var arr:[Any] = []
        let searchPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documnentPath = searchPaths[0] as String
        let filePath = documnentPath + "/FlightDataJson/FlightDataJson.JSON"
        if FileManager.default.fileExists(atPath: filePath) {
            do{
                let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
                arr = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as! [Any]
            }catch{
                print("Error reading flight data : \(error.localizedDescription)")
            }
        }else{
            if app!.objNetworkType != .free{
                CBUtils.downloadFlightData()
            }else{
                let alert = AlertService.showAlert(title: "Sorry", message: "You cannot get needed access via SouthwestWifi or 2Wire. Try again later when you are safely on the ground and have another internet access.", actions: nil)
                let topVC = app!.getTopViewController()
                topVC?.present(alert, animated: true)
            }
        }
        return arr
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
    

    
    class func checkOvernightPredicate() -> [NSPredicate] {
            var overnightPredicate: [NSPredicate] = []
            
            let context = GlobalBidInfo.shared.managedObjectContext
            
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "OvernightBulk")
            
            do {
                let fetchedObjects = try context.fetch(fetchRequest)
                
                guard let firstObject = fetchedObjects.first,
                      let cityStatusAny = firstObject.value(forKey: "citystatus"),
                      !(cityStatusAny is NSNull),
                      let dictAllValues = cityStatusAny as? [String: Any] else {
                    return overnightPredicate
                }
                
                let yesArray = dictAllValues.filter { $0.value as? String == "2" }.map { $0.key }
                let noArray = dictAllValues.filter { $0.value as? String == "1" }.map { $0.key }
                
                if yesArray.isEmpty && noArray.isEmpty {
                    return overnightPredicate
                }
                
                var filterVars: [String: Any] = [:]
                
                if !noArray.isEmpty {
                    let formatString = "isOvernightFiltered == 0"
                    let format = NSPredicate(format: formatString)
                    overnightPredicate.append(format)
                }
                
                if !yesArray.isEmpty {
                    filterVars["SET"] = Set(yesArray)
                    let formatString = "SUBQUERY(days, $DAY, ($DAY.info.city IN $SET) && $DAY.trip.dropForFiltersSorts == 0).@count > 0"
                    let format = NSPredicate(format: formatString).withSubstitutionVariables(filterVars)
                    overnightPredicate.append(format)
                }
            } catch {
                print("Overnight fetch failed: \(error.localizedDescription)")
            }
            
            return overnightPredicate
        }
    
    static func GenerateOvernightCities() -> [String] {
        var arrCities: [String] = []
        let moc = GlobalBidInfo.shared.managedObjectContext
        let fetchRequest: NSFetchRequest<BILine> = BILine.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "type != 4")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "bidOrder", ascending: true)]
        do {
            let fetResults = try moc.fetch(fetchRequest)
            for line in fetResults {
                for case let day as BIDay in line.days ?? [] {
                    if let city = day.info?.city,
                       city != CBGlobalMethods.shared.selectedBidPeriod?.base,
                       arrCities.contains(city) {
                        let city = day.info?.city
                        arrCities.append(city!)
                    }
                }
            }
        }
        catch {
            print ("error fetching bid lines \(error.localizedDescription)")
        }
        return arrCities
    }
    
    static func commutabilitySecondCellValue() -> [String] {
        return ["NoMiddle", "OKMiddle"]
    }
    
    static func CommutabilityThirdCell() -> [String] {
        return ["Front", "Back", "Overall"]
    }
    
    static func CommutabilityFourthCell() -> [String] {
        return [">=", "<="]
    }
 
    class func generateUniqueIdentifier() -> String {
        return UUID().uuidString
    }
}

class JWTDecoder{
    static func decode(jwtToken jwt: String) -> [String: Any]? {
            // Split the JWT into parts
            let segments = jwt.components(separatedBy: ".")
            guard segments.count >= 2 else {
                print("Invalid JWT token")
                return nil
            }
            
            let payloadBase64 = segments[1]
            
            // Convert from Base64URL to Base64
            var base64 = payloadBase64
                .replacingOccurrences(of: "-", with: "+")
                .replacingOccurrences(of: "_", with: "/")
            
            // Pad with '=' if needed
            while base64.count % 4 != 0 {
                base64.append("=")
            }
            
            // Decode Base64 → Data
            guard let data = Data(base64Encoded: base64) else {
                print("Failed to decode Base64 string")
                return nil
            }
            
            // Parse JSON into dictionary
            do {
                let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                return jsonObject as? [String: Any]
            } catch {
                print("Failed to parse JSON: \(error.localizedDescription)")
                return nil
            }
        }
}
