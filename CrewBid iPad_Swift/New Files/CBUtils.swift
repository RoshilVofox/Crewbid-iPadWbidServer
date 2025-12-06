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
    
    
    static func downloadCrewBidUpdateFile(completion: @escaping (Bool) -> Void) {
        // 1. Construct the URL
        guard let url = URL(string: EndPoint.shared.crewBidUpdate) else {
            completion(false)
            return
        }

            let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let destinationFileUrl = documentsUrl.appendingPathComponent("CrewBidUpdate.txt")
        let urlRequest = URLRequest(url: url)
        URLSession.shared.downloadTask(with: urlRequest) { data, response, error in
            if let tempURL = data , error == nil{
                //Success
                do {
                    if(FileManager.default.fileExists(atPath:destinationFileUrl.path)) {
                        try! FileManager.default.removeItem(at: destinationFileUrl)
                    }
                    try FileManager.default.copyItem(at: tempURL, to: destinationFileUrl)
                } catch (let writeError) {
                    print("Error creating a file \(destinationFileUrl) : \(writeError)")
                    DispatchQueue.main.sync {
                        completion(false)
                    }
                }
                let encoding = CFStringConvertEncodingToNSStringEncoding(UInt32(CFStringEncodings.windowsHebrew.rawValue))
                let crewBidUpdateText = try! String(contentsOf: destinationFileUrl, encoding: String.Encoding(rawValue: encoding))
                let IsParsingCompleted:Bool =  self.parseCrewBidUpdateFile(crewBidUpdateText)
                if IsParsingCompleted{
                    completion(true)
                }else{
                    completion(false)
                }
            }else{
                print("Error took place while downloading a file. Error description: %@", error!.localizedDescription)
                completion(false)
            }
        }.resume()
    }
    
//    static func parseCrewBidUpdateFile(text: String) -> Bool {
//        
//        var success:Bool = true
//        //Parse CrewBid Update file
//        if text.contains("File or directory not found") || text.contains("internal server error") {
//            return true
//        }
//        
//        let scanner = Scanner(string: text)
//        let dataSource = GlobalBidInfo.shared
//        autoreleasepool {
//            let fetchRequest: NSFetchRequest<CrewBidUpdateData> = CrewBidUpdateData.fetchRequest()
//
//            let context = dataSource.managedObjectContext
//            var crewBidDataVersion: CrewBidUpdateData
//
//            do {
//                let fetchedObjects = try context.fetch(fetchRequest)
//                
//                if let existingData = fetchedObjects.first {
//                    crewBidDataVersion = existingData
//                } else {
//                    crewBidDataVersion = CrewBidUpdateData(context: context)
//                }
//
//            } catch {
//                print("Failed to fetch CrewBidUpdateData: \(error)")
//                crewBidDataVersion = CrewBidUpdateData(context: context)
//            }
//            
////            let success = self.fetchCityList(crewBidDataVersion, file: text)
////            if !success {
////                return
////            }
//            
//        }
//        
//    }
    
//    static func parseCrewBidUpdateFile(_ fileContent: String) -> Bool {
//        //
//        var success:Bool = true
//        //Parse CrewBid Update file
//        if fileContent.contains("File or directory not found") || fileContent.contains("internal server error") {
//            return true
//        }
//        // 1. Initialize NSScanner with string
//        let scanner = Scanner(string: fileContent)
//        // Auto release pool for releasing local variable after usage
//        autoreleasepool {
//            //2. Load Core data version list
//            var crewBidDataVersion = CrewBidUpdateData(context: GlobalBidInfo.shared.managedObjectContext)
//            
//            let managedContext = GlobalBidInfo.shared.managedObjectContext
//            let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
//            
//            //Create object for entity description
//            let entity = NSEntityDescription.entity(forEntityName: "CrewBidUpdateData", in: (managedContext))
//            // Set entity to fetch request
//            fetchRequest.entity = entity
//            // Execute fetch request
//            let fetchedObjects = try? managedContext.fetch(fetchRequest)
//            if fetchedObjects != nil && (fetchedObjects?.count)! > 0 {
//                crewBidDataVersion = (fetchedObjects?[0] as? CrewBidUpdateData)!
//            } else {
//                crewBidDataVersion = CrewBidUpdateData(entity: entity!, insertInto: managedContext)
//            }
//            
//            success = self.fetchCityList(crewBidDataVersion, fileContent: fileContent)
//            
//            
//            if crewBidDataVersion.cities != nil {
//                self.fetchLatestNews(crewBidDataVersion, scanner: scanner, fileContent: fileContent)
//            }
//            
//        }
//        return success
//    }
    
    static func parseCrewBidUpdateFile(_ fileContent: String) -> Bool {
        var success = true
        
        // Early exit if file has errors
        if fileContent.contains("File or directory not found") || fileContent.contains("internal server error") {
            return true
        }
        
//        let scanner = Scanner(string: fileContent)
        
        autoreleasepool {
            let managedContext = GlobalBidInfo.shared.managedObjectContext
            var crewBidDataVersion: CrewBidUpdateData?
            
            // Fetch existing CrewBidUpdateData
            let fetchRequest: NSFetchRequest<CrewBidUpdateData> = CrewBidUpdateData.fetchRequest()
            
            if let results = try? managedContext.fetch(fetchRequest),
               let first = results.first {
                crewBidDataVersion = first
            } else {
                // Create a new CrewBidUpdateData if none exists
                crewBidDataVersion = CrewBidUpdateData(context: managedContext)
            }
            
            if let crewBidDataVersion = crewBidDataVersion {
                success = self.fetchCityList(crewBidDataVersion, fileContent: fileContent)
                
//                if crewBidDataVersion.cities != nil {
//                    self.fetchLatestNews(crewBidDataVersion, scanner: scanner, fileContent: fileContent)
//                }
            }
        }
        
        return success
    }
    
//    static func fetchLatestNews(_ crewBidVersionController: CrewBidUpdateData, scanner: Scanner, fileContent:String) {
//        //1. Scan to the latest news position
//        _ = scanner.scanUpToString("LatestNews")
//        //2. define number character set
//        let numCharSet = CharacterSet(charactersIn: "0123456789")
//        //3. Scan up to number and capture the number set
//        scanner.currentIndex = fileContent.index(scanner.currentIndex, offsetBy: 11)
//        let versionNumber = scanner.scanCharacters(from: numCharSet)
//        //4. Check if local version is  null to avoid the crash
//        if crewBidVersionController.latestNews == nil {
//            crewBidVersionController.latestNews = ""
//        }
//        //5. Check any version change is occured
//        if (crewBidVersionController.latestNews != versionNumber as String?) {
//            //6. Download the latest news from VPS directory
//            self.checkForNewsWithCompletionHandler(isDownloaded: { (responce: Bool) -> Void in
//                if responce {
//                    //7. Update the latest news version number to local core data
//                    let versionStr = versionNumber! as String
//                    crewBidVersionController.latestNews = versionStr
//                    DispatchQueue.main.async {
//                        if GlobalBidInfo.shared.managedObjectContext.hasChanges {
//                            do {
//                                try GlobalBidInfo.shared.managedObjectContext.save()
//                            } catch {
//                                print(error)
//                            }
//                        }
//                    }
//                }
//            })
//        }
//    }
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

    
    static func fetchLatestNews(){
        let fileManager = FileManager.default
        let destinationPath = self.getLatestNewsFilePath()
        guard let destinationURL = URL(string: destinationPath) else {
            print("Invalid destination URL")
            return
        }
        let reachability: Reachability = try! Reachability()
            
        if !reachability.isReachable {
            NotificationCenter.default.post(name: Notification.Name("NetWorkError"), object: nil)
            return
        }
        
        let stringURL = EndPoint.shared.latestNews
        
        APIService.shared.fetchDownload(urlString: stringURL, httpMethod: .GET) { result in
            switch result {
            case .success(let tempURL):
                do {
                    let fileManager = FileManager.default
                    
                    // Remove existing file if it exists
                    if fileManager.fileExists(atPath: destinationURL.path) {
                        try fileManager.removeItem(at: destinationURL)
                    }
                    
                    // Move downloaded temp file to final location
                    try fileManager.moveItem(at: tempURL, to: destinationURL)
                    
                } catch {
                    print("Error saving latest news: \(error.localizedDescription)")
                }

            case .failure(let error):
                print("Download failed with error: \(error.localizedDescription)")
            }
        }
    }
    
//    static func checkForNewsWithCompletionHandler(isDownloaded: @escaping (Bool) -> Void) {
//        let reachability: Reachability = try! Reachability()
//        
//        if !reachability.isReachable {
//            NotificationCenter.default.post(name: Notification.Name("NetWorkError"), object: nil)
//            isDownloaded(false)
//            return
//        }
//        let stringURL: String = "http://www.wbidmax.com/downloads/CrewBid/LatestNews.pdf"
//        guard let url = URL(string: stringURL) else {
//            print("Invalid URL")
//            isDownloaded(false)
//            return
//        }
//        
//        let task = URLSession.shared.dataTask(with: url) { data, response, error in
//            if let error = error {
//                print("Error fetching news: \(error)")
//                isDownloaded(false)
//                return
//            }
//            
//            guard let urlData = data else {
//                print("No data received")
//                isDownloaded(false)
//                return
//            }
//            
//            let pdfFilePath: String = self.getLatestNewsFilePath()
//            guard let urlPath = URL(string: pdfFilePath) else {
//                print("Invalid file path")
//                isDownloaded(false)
//                return
//            }
//            
//            do {
//                try urlData.write(to: urlPath, options: .atomic)
//                let filePath = urlPath.path
//                let fileManager = FileManager.default
//                
//                if fileManager.fileExists(atPath: filePath) {
//                    print("FILE AVAILABLE")
//                    isDownloaded(true)
//                } else {
//                    print("FILE NOT AVAILABLE")
//                    isDownloaded(false)
//                }
//            } catch {
//                print("Error saving file: \(error)")
//                isDownloaded(false)
//            }
//        }
//        task.resume()
//    }
    
    static func getLatestNewsFilePath() -> String {
        let paths: [Any] = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDir: String = paths[0] as? String ?? ""
        return URL(fileURLWithPath: documentsDir).appendingPathComponent("LatestNews.pdf").absoluteString
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
    
    class func downloadFlightData
    (completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: EndPoint.shared.flightdataJSON) else {
                print("Invalid URL.")
                completion(false)
                return
            }
        let urlRequest = URLRequest(url: url)
            
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationFileUrl = documentsUrl.appendingPathComponent("FlightDataJson.zip")
        URLSession.shared.downloadTask(with: urlRequest) { (data, response, error) in
            if let tempUrl = data {
                do {
                    try FileManager.default.copyItem(at: tempUrl, to: destinationFileUrl)
                } catch (let writeError) {
                    print("Error creating a file \(destinationFileUrl) : \(writeError)")
                    completion(false)
                }
                let isParsingDone = self.parseFlightDataFile(at: destinationFileUrl)
                UserDefaults.standard.setValue(true, forKey: "IsLatestFlightDataDownloaded")
                UserDefaults.standard.setValue(false, forKey: "IsNeedtoEnableVacationDifference")
                if isParsingDone{
                    completion(true)
                }else{
                    completion(false)
                }
            }else{
                print("Error while downloading a file. Error description:", error!.localizedDescription)
                completion(false)
            }
        }.resume()
    }
    class func getFALISTWB4JSONFromServer(completion: (() -> Void)? = nil) {
//        guard let url = URL(string: EndPoint.shared.faListWB4Json) else {
//            print("Invalid URL")
//            completion?()
//            return
//        }
//
//        let request = URLRequest(url: url)
//        let session = URLSession(configuration: .default)
//
//        let task = session.dataTask(with: request) { data, response, error in
//            if let error = error {
//                print("Error in getting FA list from server: \(error.localizedDescription)")
//                completion?()
//                return
//            }
//
//            if let data = data {
//                do {
//                    if let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
//                        self.writeJSONDictToFile(jsonDict: responseDict)
//                    }
//                } catch {
//                    print("JSON Parsing Error: \(error.localizedDescription)")
//                }
//            }
//
//            // Notify caller when done
//            completion?()
//        }
//
//        task.resume()
        APIService.shared.fetch(
            urlString: EndPoint.shared.faListWB4Json,
            parse: { data in
                // Try parsing JSON into a dictionary
                guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    throw Errors.decodingError
                }
                return dict
            },
            completion: { result in
                switch result {
                case .success(let responseDict):
                    self.writeJSONDictToFile(jsonDict: responseDict)
                case .failure(let error):
                    print("Error in getting FA list from server: \(error)")
                }
                completion?()
            }
        )
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
    
    static func writeJSONDictToFile(_ jsonDict: [String: Any], fileName: String) -> String? {
            do {
                // Convert dictionary to JSON data
                let jsonData = try JSONSerialization.data(withJSONObject: jsonDict, options: .prettyPrinted)
                
                // Get the document directory path
                guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                    return "Failed to locate documents directory."
                }
                
                let fileURL = documentsPath.appendingPathComponent(fileName)
                
                // Remove existing file if it exists
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    do {
                        try FileManager.default.removeItem(at: fileURL)
                    } catch {
                        return "Failed to remove existing file: \(error.localizedDescription)"
                    }
                }
                
                // Write JSON data to file
                try jsonData.write(to: fileURL, options: .atomic)
                
                return nil // Success
            } catch {
                return "JSON Serialization or File Write Error: \(error.localizedDescription)"
            }
        }
    
    
    static func readJSONString(fromFile fileName: String) -> [String: Any]? {
        let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let filePath = (documentDirectory as NSString).appendingPathComponent(fileName)
        
        guard let jsonData = try? Data(contentsOf: URL(fileURLWithPath: filePath)) else {
            print("Failed to read file at: \(filePath)")
            return nil
        }

        do {
            let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers)
            return jsonObject as? [String: Any]
        } catch {
            print("JSON parse error:", error)
            return nil
        }
    }
    
    static func readJSONStringFromFileForArray(_ fileName: String) -> [Any]? {
        let fileManager = FileManager.default
        
        // Path to /Documents
        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        // Read file data
        guard let data = try? Data(contentsOf: fileURL) else {
            print("File not found: \(fileURL.path)")
            return nil
        }
        
        // Parse JSON
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
            return json as? [Any]
        } catch {
            print("JSON parse error:", error)
            return nil
        }
    }
    
    @discardableResult
    static func deleteFile(withName fileName: String) -> Bool {
        let fileManager = FileManager.default
        
        // Documents directory
        guard let documentsPath = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first else {
            return false
        }
        
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        // Check if the file exists
        if fileManager.fileExists(atPath: fileURL.path) {
            do {
                try fileManager.removeItem(at: fileURL)
                return true
            } catch {
                print("File deletion error:", error.localizedDescription)
                return false
            }
        } else {
            print("File not found:", fileURL.path)
            return false
        }
    }
    
    
    static func nsNumber(from value: Any?) -> NSNumber {
        // nil or NSNull → return 0
        guard let value = value, !(value is NSNull) else {
            return 0
        }

        // NSNumber → return directly
        if let number = value as? NSNumber {
            return number
        }

        // String → convert to Double
        if let string = value as? String {
            return NSNumber(value: Double(string) ?? 0)
        }

        // BOOL → convert
        if let boolValue = value as? Bool {
            return NSNumber(value: boolValue)
        }

        return NSNumber(value: (value as AnyObject).boolValue)
    }
    
    static func getTripPositionNumber(_ position: String) -> NSNumber {
        switch position {
        case "A":
            return NSNumber(value: BIFaPosition.FaPositionA.rawValue)
        case "B":
            return NSNumber(value: BIFaPosition.FaPositionB.rawValue)
        case "C":
            return NSNumber(value: BIFaPosition.FaPositionC.rawValue)
        case "D":
            return NSNumber(value: BIFaPosition.FaPositionD.rawValue)
        default:
            return NSNumber(value: BIFaPosition.FaPositionNA.rawValue)
        }
    }
    
    class func convertToHerb(fromUTC utcDate: Date) -> Date? {
        guard let centralTimeZone = TimeZone(identifier: "US/Central") else { return nil }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = centralTimeZone

        let components = calendar.dateComponents(in: centralTimeZone, from: utcDate)
        return calendar.date(from: DateComponents(
            year: components.year,
            month: components.month,
            day: components.day,
            hour: components.hour,
            minute: components.minute,
            second: components.second
        ))
    }
    
    class func getMinutes(from date: Date) -> Int {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "US/Central")!  // DST-aware

        let components = calendar.dateComponents([.hour, .minute], from: date)

        let hour = components.hour ?? 0
        let minute = components.minute ?? 0

        return (hour * 60) + minute
    }
    
    
    static func getTripPosition(_ position: BIFaPosition) -> String {
        switch position {
        case .FaPositionA:        return "A"
        case .FaPositionB:        return "B"
        case .FaPositionC:        return "C"
        case .FaPositionD:        return "D"
        case .FaPositionMultiple: return "M"
        case .FaPositionNA:       return "NA"
        }
    }
    
    static func getDay(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "GMT")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
    
    static func getDateOnly(from date: Date) -> NSNumber {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "GMT")
        formatter.dateFormat = "dd"

        let dayString = formatter.string(from: date)
        let dayInt = Int(dayString) ?? 0
        return NSNumber(value: dayInt)
    }
    
    static func getEquipmentType(_ typeChar: String?) -> String {
        guard let typeChar = typeChar else { return "" }

        let types700 = ["73W", "73R", "7S7", "7R7", "700"]
        let types800 = ["73H", "7S8", "738", "7R8", "800"]
        let types8Max = ["7M8", "7U8", "7T8", "7V8"]

        if types700.contains(typeChar) {
            return "7"   // Equipment 700
        } else if types800.contains(typeChar) {
            return "8"   // Equipment 800
        } else if types8Max.contains(typeChar) {
            return "6"   // Equipment 8Max
        } else {
            return ""
        }
    }
    
    
    static func convertMinsToHHMMFor24Hrs(_ totalMinutes: Int) -> Int {
        let hours = totalMinutes / 60      // Total hours
        let mins = totalMinutes % 60       // Remaining minutes
        let result = hours * 100 + mins    // Convert to HHMM format
        return result
    }
    
    
    static func date(bySettingHHMM hhmm: String, to baseDate: Date?) -> Date? {
        guard let baseDate = baseDate, hhmm.count == 4 else { return nil }
        
        let hour = Int(hhmm.prefix(2)) ?? 0
        let minute = Int(hhmm.suffix(2)) ?? 0
        
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale.current
        calendar.timeZone = TimeZone(identifier: "UTC")!
        
        // Extract Y/M/D components from base date
        var comps = calendar.dateComponents([.year, .month, .day], from: baseDate)
        comps.hour = hour
        comps.minute = minute
        
        return calendar.date(from: comps)
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
                
                if let error = error as NSError?, error.code == NSURLErrorTimedOut {
                    let offlineEvent = CBOfflineEvents()
                    offlineEvent.sendOfflineDataForTimeOut(url: url.absoluteString, month: nil)
                }
                
                guard let data = data else {
                    completion(false)
                    return
                }

                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    
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
    
    
    class func parseFlightDataFile(at filePath: URL) -> Bool {
        var success = false
        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let flightDataJsonPath = documentPath.appendingPathComponent("FlightDataJson")
        if FileManager.default.fileExists(atPath: flightDataJsonPath.path) {
            do {
                try FileManager.default.removeItem(at: flightDataJsonPath)
            } catch {
                print("Error deleting old FlightDataJson folder: \(error)")
            }
        }
        success = SSZipArchive.unzipFile(atPath: filePath.path, toDestination: documentPath.path)
        if FileManager.default.fileExists(atPath: filePath.path) {
            do {
                try FileManager.default.removeItem(atPath: filePath.path)
            } catch {
                print("Error deleting zip file: \(error)")
            }
        }
        return success
    }
    
//    class func parseFlightData() -> [Any]{
//        var app:AppDelegate?
//        DispatchQueue.main.async {
//            app = UIApplication.shared.delegate as? AppDelegate
//        }
//        
//        var arr:[Any] = []
//        let searchPaths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
//        let documnentPath = searchPaths[0] as String
//        let filePath = documnentPath + "/FlightDataJson/FlightDataJson.JSON"
//        if FileManager.default.fileExists(atPath: filePath) {
//            do{
//                let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
//                arr = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as! [Any]
//            }catch{
//                print("Error reading flight data : \(error.localizedDescription)")
//            }
//        }else{
//            if app!.objNetworkType != .free{
//                CBUtils.downloadFlightData(){ result in
//                    print(result)
//                }
//            }else{
//                let alert = AlertService.showAlert(title: "Sorry", message: "You cannot get needed access via SouthwestWifi or 2Wire. Try again later when you are safely on the ground and have another internet access.", actions: nil)
//                let topVC = app!.getTopViewController()
//                topVC?.present(alert, animated: true)
//            }
//        }
//        return arr
//    }
    
    
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
    

    
//    class func checkOvernightPredicate() -> [NSPredicate] {
//            var overnightPredicate: [NSPredicate] = []
//            
//            let context = GlobalBidInfo.shared.managedObjectContext
//            
//            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "OvernightBulk")
//            
//            do {
//                let fetchedObjects = try context.fetch(fetchRequest)
//                
//                guard let firstObject = fetchedObjects.first,
//                      let cityStatusAny = firstObject.value(forKey: "citystatus"),
//                      !(cityStatusAny is NSNull),
//                      let dictAllValues = cityStatusAny as? [String: Any] else {
//                    return overnightPredicate
//                }
//                
//                let yesArray = dictAllValues.filter { $0.value as? String == "2" }.map { $0.key }
//                let noArray = dictAllValues.filter { $0.value as? String == "1" }.map { $0.key }
//                
//                if yesArray.isEmpty && noArray.isEmpty {
//                    return overnightPredicate
//                }
//                
//                var filterVars: [String: Any] = [:]
//                
//                if !noArray.isEmpty {
//                    let formatString = "isOvernightFiltered == 0"
//                    let format = NSPredicate(format: formatString)
//                    overnightPredicate.append(format)
//                }
//                
//                if !yesArray.isEmpty {
//                    filterVars["SET"] = Set(yesArray)
//                    let formatString = "SUBQUERY(days, $DAY, ($DAY.info.city IN $SET) && $DAY.trip.dropForFiltersSorts == 0).@count > 0"
//                    let format = NSPredicate(format: formatString).withSubstitutionVariables(filterVars)
//                    overnightPredicate.append(format)
//                }
//            } catch {
//                print("Overnight fetch failed: \(error.localizedDescription)")
//            }
//            
//            return overnightPredicate
//        }
    
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
    
    class func getFlightData() -> NSMutableArray {
        var array = NSMutableArray()
        let searchPaths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).map(\.path)
        let documentPath = searchPaths[0]
        let filePath = URL(fileURLWithPath: documentPath).appendingPathComponent("FlightDataJson/FlightDataJson.JSON").path
        if FileManager.default.fileExists(atPath: filePath) {
            let myDictData = NSData(contentsOfFile: filePath)! as Data?
            do {
                array = try JSONSerialization.jsonObject(with: myDictData!, options: .mutableContainers) as! NSMutableArray
            }
            catch let error1 {
                print(error1.localizedDescription)
            }
        }
        return array
        
    }
    
    class func noOfDaysBetweenDates(startDate: Date?,endDate: Date?) -> Int {
        let calendarData = BICalendarData()
        let newStartDate = calendarData.dateForDate(date: startDate)
        let newEndtDate = calendarData.dateForDate(date: endDate)
        
        let calendar = Calendar.current
        var dateComponent: DateComponents? = nil
        if let startDate = newStartDate, let endDate = newEndtDate {
            dateComponent = calendar.dateComponents([.day], from: startDate, to: endDate)
        }
        let totalDays = Int(dateComponent?.day ?? 0)
        return totalDays + 1
        
    }
    
    class func isLocalUserInformationAvailable() -> Bool {
        let app = UIApplication.shared.delegate as! AppDelegate
        return app.isUserInformationAvailable()
    }
    
    
    static func setPushNotifications() {
           DispatchQueue.main.async {
               let center = UNUserNotificationCenter.current()
               center.removeAllPendingNotificationRequests()
               
               guard let app = UIApplication.shared.delegate as? AppDelegate else { return }
               
               let positionName = (app.ObjUserAccount?.position == 3) ? "Flight Attendant" : "Pilot"
               
               var round1LinesPostedDay = 0
               var round1LinesDueDay = 0
               var round2LinesPostedDay = 0
               var round2LinesDueDay = 0
               
               var round1LinesPostedDayMessage = ""
               var round1LinesDueDayMessage = ""
               var round2LinesPostedDayMessage = ""
               var round2LinesDueDayMessage = ""
               
               let defaults = UserDefaults.standard
               
               if positionName == "Flight Attendant" {
                   if (defaults.string(forKey: "FAround1LinesPostedDayActive") as NSString?)?.boolValue ?? false {
                       round1LinesPostedDay = Int(defaults.string(forKey: "FAround1LinesPostedDay") ?? "0") ?? 0
                       round1LinesPostedDayMessage = defaults.string(forKey: "FAround1LinesPostedDayMessage") ?? ""
                   }
                   if (defaults.string(forKey: "FAround1LinesDueDayActive") as NSString?)?.boolValue ?? false {
                       round1LinesDueDay = Int(defaults.string(forKey: "FAround1LinesDueDay") ?? "0") ?? 0
                       round1LinesDueDayMessage = defaults.string(forKey: "FAround1LinesDueDayMessage") ?? ""
                   }
                   if (defaults.string(forKey: "FAround2LinesPostedDayActive") as NSString?)?.boolValue ?? false {
                       round2LinesPostedDay = Int(defaults.string(forKey: "FAround2LinesPostedDay") ?? "0") ?? 0
                       round2LinesPostedDayMessage = defaults.string(forKey: "FAround2LinesPostedDayMessage") ?? ""
                   }
                   if (defaults.string(forKey: "FAround2LinesDueDayActive") as NSString?)?.boolValue ?? false {
                       round2LinesDueDay = Int(defaults.string(forKey: "FAround2LinesDueDay") ?? "0") ?? 0
                       round2LinesDueDayMessage = defaults.string(forKey: "FAround2LinesDueDayMessage") ?? ""
                   }
               } else {
                   if (defaults.string(forKey: "NonFAround1LinesPostedDayActive") as NSString?)?.boolValue ?? false {
                       round1LinesPostedDay = Int(defaults.string(forKey: "NonFAround1LinesPostedDay") ?? "0") ?? 0
                       round1LinesPostedDayMessage = defaults.string(forKey: "NonFAround1LinesPostedDayMessage") ?? ""
                   }
                   if (defaults.string(forKey: "NonFAround1LinesDueDayActive") as NSString?)?.boolValue ?? false {
                       round1LinesDueDay = Int(defaults.string(forKey: "NonFAround1LinesDueDay") ?? "0") ?? 0
                       round1LinesDueDayMessage = defaults.string(forKey: "NonFAround1LinesDueDayMessage") ?? ""
                   }
                   if (defaults.string(forKey: "NonFAround2LinesPostedDayActive") as NSString?)?.boolValue ?? false {
                       round2LinesPostedDay = Int(defaults.string(forKey: "NonFAround2LinesPostedDay") ?? "0") ?? 0
                       round2LinesPostedDayMessage = defaults.string(forKey: "NonFAround2LinesPostedDayMessage") ?? ""
                   }
                   if (defaults.string(forKey: "NonFAround2LinesDueDayActive") as NSString?)?.boolValue ?? false {
                       round2LinesDueDay = Int(defaults.string(forKey: "NonFAround2LinesDueDay") ?? "0") ?? 0
                       round2LinesDueDayMessage = defaults.string(forKey: "NonFAround2LinesDueDayMessage") ?? ""
                   }
               }
               
               let calendar = Calendar(identifier: .gregorian)
               let varCalendar = Calendar(identifier: .gregorian)
               let now = Date()
               let someDate = calendar.date(byAdding: .month, value: 4, to: now)!
               
               let today = Date()
               var currentDate = now
               var i = 0
               
               while currentDate.compare(someDate) == .orderedAscending {
                   let comps = varCalendar.dateComponents([.year, .month], from: currentDate)
                   
                   func scheduleNotification(day: Int, hour: Int, message: String, key: String) {
                       var dc = DateComponents()
                       dc.year = comps.year
                       dc.month = comps.month
                       dc.day = day
                       dc.hour = hour
                       dc.minute = 0
                       dc.second = 0
                       
                       if let compareDate = varCalendar.date(from: dc),
                          today.compare(compareDate) == .orderedAscending {
                           
                           let content = UNMutableNotificationContent()
                           content.title = "CrewBid!"
                           content.body = message
                           content.sound = .default
                           
                           let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: false)
                           let request = UNNotificationRequest(identifier: "\(key)\(i)", content: content, trigger: trigger)
                           center.add(request, withCompletionHandler: nil)
                       }
                   }
                   
                   // Round 1 posted
                   scheduleNotification(day: round1LinesPostedDay, hour: 12, message: round1LinesPostedDayMessage, key: "BidNotificationKey0")
                   // Round 2 posted
                   scheduleNotification(day: round2LinesPostedDay, hour: 12, message: round2LinesPostedDayMessage, key: "BidNotificationKey1")
                   // Round 1 due
                   scheduleNotification(day: round1LinesDueDay, hour: 20, message: round1LinesDueDayMessage, key: "BidNotificationKey2")
                   // Round 2 due
                   scheduleNotification(day: round2LinesDueDay, hour: 20, message: round2LinesDueDayMessage, key: "BidNotificationKey3")
                   
                   i += 1
                   currentDate = varCalendar.date(byAdding: .month, value: 1, to: currentDate)!
               }
               
               center.getPendingNotificationRequests { requests in
                   // You can log requests here if needed
               }
           }
       }
    
    static func overnightBulkRedApply(noArray: NSArray) {
        let lineFechRequest: NSFetchRequest<BILine> = BILine.fetchRequest()
        lineFechRequest.predicate = NSPredicate(format: "type != 4")
        lineFechRequest.sortDescriptors = [NSSortDescriptor(key: "bidOrder", ascending: true)]
        let results = try? CBGlobalMethods.shared.selectedBidPeriod!.managedObjectContext!.fetch(lineFechRequest)
        for line in results! {
            var isContainCity = false
            for case let day as BIDay in line.days! {
                if noArray.contains(day.info?.city) {
                    isContainCity = true
                }
            }
            if isContainCity {
                line.isOvernightFiltered = 1
            }
            else {
                line.isOvernightFiltered = 0
            }
        }
        try? CBGlobalMethods.shared.selectedBidPeriod!.managedObjectContext!.save()
    }
    
    static func overnightBulkGreenApply(yesArray: NSArray) {
        if yesArray.count == 0 {
            return
        }
        let lineFechRequest: NSFetchRequest<BILine> = BILine.fetchRequest()
        lineFechRequest.predicate = NSPredicate(format: "type != 4")
        lineFechRequest.sortDescriptors = [NSSortDescriptor(key: "bidOrder", ascending: true)]
        let results = try? CBGlobalMethods.shared.selectedBidPeriod!.managedObjectContext!.fetch(lineFechRequest)
        for line in results! {
            var isContainCity = false
            for case let day as BIDay in line.days! {
                if yesArray.contains(day.info?.city) {
                    isContainCity = true
                }
            }
            if !isContainCity {
                line.isOvernightFiltered = 1
            }
        }
        try? CBGlobalMethods.shared.selectedBidPeriod!.managedObjectContext!.save()
    }
    
    static func highlightTripsOverNightBulk() {
        let tripsFetch: NSFetchRequest<BITrip> = BITrip.fetchRequest()
        let subPrepicates = NSMutableArray()
        if CBGlobalMethods.shared.selectedBidPeriod?.isOverNightBulkApplied == "YES" {
            subPrepicates.addObjects(from: CBUtils.checkOvernightPredicate())
        }
        tripsFetch.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: subPrepicates as! [NSPredicate])
        guard tripsFetch.predicate != nil else {return}
        tripsFetch.sortDescriptors = [NSSortDescriptor(key: "info.number", ascending: true)]
        do {
            let results = try CBGlobalMethods.shared.selectedBidPeriod!.managedObjectContext?.fetch(tripsFetch)
            for trip in results! {
                trip.highlightCount = trip.highlightCount!.intValue + 1 as NSNumber
            }
        }
        catch {
            print("error fetching \(error.localizedDescription)")
        }

    }
    
    static func checkOvernightPredicate() -> [NSPredicate] {
        var overnightPredicate = [NSPredicate]()
        let fetchRequest: NSFetchRequest<OvernightBulk> = OvernightBulk.fetchRequest()
        let results: [OvernightBulk]? = try? CBGlobalMethods.shared.selectedBidPeriod!.managedObjectContext!.fetch(fetchRequest)
        var dictAllValues = [String: Any]()
        let array = NSMutableArray()
        if let results = results, results.count > 0 {
            let filterFetch: NSFetchRequest<BIFilterRule> = BIFilterRule.fetchRequest()
            let predicate1 = NSPredicate(format: "bidPeriod == %@", CBGlobalMethods.shared.selectedBidPeriod!)
            let predicate2 = NSPredicate(format: "category == 34")
            filterFetch.predicate = NSCompoundPredicate(type: .and, subpredicates: [predicate1, predicate2])
            let filterResult = try? CBGlobalMethods.shared.selectedBidPeriod!.managedObjectContext!.fetch(filterFetch)
            if filterResult?.count ?? 0 > 0 {
                let vb = filterResult?[0].variables
                dictAllValues = vb as? [String: Any] ?? [:]
            }
            let noArray = dictAllValues.keys.filter { dictAllValues[$0] as? String == "1" }
            let yesArray = dictAllValues.keys.filter { dictAllValues[$0] as? String == "2" }
            if (yesArray.count == 0 && noArray.count == 0) {
                return overnightPredicate
            }
            else {
                var filterVars: [String: Any] = [:]

                let set = Set(yesArray)
                filterVars["SET"] = set

                let avoidSet = Set(noArray)
                filterVars["AVOIDSET"] = avoidSet

                var formatString = "SUBQUERY(legs, $LEG,"
                var format: NSPredicate

                if noArray.count > 0 {
                    formatString = "isOvernightFiltered == 0"
                    format = NSPredicate(format: formatString)
                    overnightPredicate.append(format)
                }

                if yesArray.count > 0 {
                    formatString = "SUBQUERY(days, $DAY, ($DAY.info.city IN $SET) && $DAY.trip.dropForFiltersSorts == 0).@count > 0"
                    format = NSPredicate(format: formatString)
                    overnightPredicate.append(format.withSubstitutionVariables(filterVars))
                }
                if array.count > 0 {
                    if dictAllValues.count > 0 {
                        let noArray = (dictAllValues.filter { $0.value as? String == "1" }.map { $0.key } as? NSArray)!
                        let yesArray = (dictAllValues.filter { $0.value as? String == "2" }.map { $0.key } as? NSArray)!
                        
                        self.overnightBulkRedApply(noArray: noArray)
                        self.overnightBulkGreenApply(yesArray: yesArray)
                        CBOvernightBulkRuleCell().reloadContent()
                    }
                }
            }

        }
        else {
            return overnightPredicate
        }
        return overnightPredicate
    }
    
    
    static func isSwaTypeOfFileDownload() -> Bool{
        if ((AppState.shared.mockDataYear == 2025 && AppState.shared.mockDataMonth == 12) || AppState.shared.mockDataYear! > 2026){
            return true
        }
        return false
    }
    
    static func generateTextForAwardData(_ lineAward: [String: Any]?,
                                         mrtAward: [String: Any]?,
                                         jobShareAward: [String: Any]?,
                                         reserveData: [String: Any]?,
                                         bidPeriod: BIBidPeriod?) -> String {
        var text = String()

        guard let bidPeriod = bidPeriod else {
            return text
        }

        if bidPeriod.isSecondRoundBid() {
            let secondRoundAwardText = secondRoundAwardStr(lineAward, bidPeriod: bidPeriod)
            text.append(secondRoundAwardText)
        } else {
            let lineAwardText = lineAwardString(lineAward, jsAward: jobShareAward, bidPeriod: bidPeriod)
            let mrtAwardText = mrtAwardString(mrtAward, bidPeriod: bidPeriod)
            let jsAwardText = jobshareAwardString(jobShareAward, bidPeriod: bidPeriod)
            let reserveText = reserveAwardString(reserveData, bidPeriod: bidPeriod)
            let lineAwardNameSortText = lineAwardStringnameSort(lineAward, bidPeriod: bidPeriod)

            text.append(mrtAwardText)
            text.append(jsAwardText)
            text.append(lineAwardText)
            text.append(reserveText)
            text.append(lineAwardNameSortText)
        }

        return text
    }
    
    static func secondRoundAwardStr(_ lineAward: [String: Any]?, bidPeriod: BIBidPeriod) -> String {
            var text = ""

            // Header title (uses existing ShortMonthName equivalent)
            let monthName = CBUtils.shortMonthName(month: bidPeriod.month?.intValue ?? 0, uc: true)
            let year = bidPeriod.year ?? 0
            let base = bidPeriod.base ?? ""
            text += "**Subject to Protest**\n\(monthName) \(year)\nReserve Award List\n\(base) Base\n\n"

            let col0Width = 3   // Left Padding
            let col1Width = 7   // Line Num
            let col2Width = 8   // Base Seq
            let col3Width = 38  // Name
            let col4Width = 10  // Emp ID
            let col5Width = 21  // Regulatory

            var vrString = ""
            var sprString = ""
            var sarString = ""
            var jprString = ""
            var jarString = ""
            var jlrString = ""

            // Helper: padding generator
            func pad(_ s: String, to length: Int) -> String {
                if s.count >= length { return s }
                return s + String(repeating: " ", count: length - s.count)
            }
            func leftPad(_ s: String, to length: Int) -> String {
                if s.count >= length { return s }
                return String(repeating: " ", count: length - s.count) + s
            }

            // Build header rows (same pattern used for each block)
            func headerRow(_ title: String) -> String {
                let p0 = String(repeating: " ", count: col0Width)
                let c1 = pad(title, to: col1Width)
                let c2 = pad("Sen#", to: col2Width)
                let c3 = pad("Name", to: col3Width)
                let c4 = pad("Emp#", to: col4Width)
                let c5 = pad("Regulatory (Y/N)", to: col5Width)
                var row = "\(p0)\(c1)\(c2)\(c3)\(c4)\(c5)\n"
                row += "   ----------------------------------------------------------------------------------\n"
                return row
            }

            vrString += headerRow("VR")
            sprString += headerRow("SPR")
            sarString += headerRow("SAR")
            jprString += headerRow("JPR")
            jarString += headerRow("JAR")
            jlrString += headerRow("JLR")


            guard let lineAward = lineAward,
                  let embedded = lineAward["_embedded"] as? [String: Any],
                  let awardArray = embedded["IFLineBaseAuctionAwards"] as? [[String: Any]],
                  awardArray.count > 0 else {
                text += "** NONE **\n"
                return text
            }


            let sortedAwardArray = awardArray.sorted { a, b in
                let aLine = String(describing: a["line"] ?? "")
                let bLine = String(describing: b["line"] ?? "")
                
                if let ai = Int(aLine), let bi = Int(bLine) {
                    return ai < bi
                } else {
                    return aLine.localizedStandardCompare(bLine) == .orderedAscending
                }
            }

            var prevLineNum = ""
            let maxLineNumberLength = (sortedAwardArray.last?["line"] as? String)?.count ?? 0

            for awardDict in sortedAwardArray {
                let line = (awardDict["line"] as? String) ?? ""
                var lineNumStr: String

                if line == prevLineNum {
                    let indentLen = maxLineNumberLength + 3
                    lineNumStr = String(repeating: " ", count: indentLen)
                } else {
                    let padded = leftPad(line, to: max(0, maxLineNumberLength))
                    lineNumStr = padded
                    prevLineNum = line
                }

                let seniorityNum = String(describing: awardDict["baseSeniority"] ?? "")
                let nameStr = String(describing: awardDict["legalName"] ?? "")
                let empNum = "[\(String(describing: awardDict["employeeId"] ?? ""))]"

                let regulatoryBool = (awardDict["regulatory"] as? Bool) ?? ( (awardDict["regulatory"] as? NSNumber)?.boolValue ?? false )
                let regulatory = regulatoryBool ? "       Y" : "       N"


                let leftPadding = String(repeating: " ", count: col0Width)
                let lineWithPos = pad(lineNumStr, to: col1Width)
                let seq = pad(seniorityNum, to: col2Width)
                let name = pad(nameStr.uppercased(), to: col3Width)
                let empID = pad(empNum, to: col4Width)
                let reg = pad(regulatory, to: col5Width)

                let rowString = "\(leftPadding)\(lineWithPos)\(seq)\(name)\(empID)\(reg)\n"


                if let reserveType = awardDict["reserveType"] as? String {
                    switch reserveType {
                    case "VR": vrString += rowString
                    case "SPR": sprString += rowString
                    case "SAR": sarString += rowString
                    case "JPR": jprString += rowString
                    case "JAR": jarString += rowString
                    case "JLR": jlrString += rowString
                    default: break
                    }
                }
            }

            text += "\(vrString)\n\n\(sarString)\n\n\(jarString)\n\n\(sprString)\n\n\(jprString)\n\n\(jlrString)\n\n"

            return text
        }
    
    static func lineAwardString(_ lineAward: [String: Any]?, jsAward: [String: Any]?, bidPeriod: BIBidPeriod) -> String {
        var text = ""

        // Header title
        let monthName = CBUtils.shortMonthName(month: bidPeriod.month?.intValue ?? 0, uc: true)
        let year = bidPeriod.year ?? 0
        let base = bidPeriod.base ?? ""
        text += "**Subject to Protest**\n\(monthName) \(year)\nAward List - \(base)\n\n"

        // Fixed column widths
        let col0Width = 3   // Left Padding
        let col1Width = 10  // Line Num
        let col2Width = 8   // Base Seq
        let col3Width = 35  // Name
        let col4Width = 10  // Emp ID
        let col5Width = 3   // NH
        let col6Width = 21  // Regulatory

        // Helper padding functions
        func padRight(_ s: String, to length: Int) -> String {
            if s.count >= length { return s }
            return s + String(repeating: " ", count: length - s.count)
        }
        func padLeft(_ s: String, to length: Int) -> String {
            if s.count >= length { return s }
            return String(repeating: " ", count: length - s.count) + s
        }

        // Header row
        let p0 = String(repeating: " ", count: col0Width)
        let header = "\(p0)\(padRight("Line-Pos", to: col1Width))\(padRight("Sen#", to: col2Width))\(padRight("Name", to: col3Width))\(padRight("Emp#", to: col4Width))\(padRight("NH", to: col5Width))\(padRight("Regulatory (Y/N)", to: col6Width))\n"
        text += header
        text += "   ----------------------------------------------------------------------------------\n"

        // Prepare jobshare array (if any)
        var jsAwardArray: [[String: Any]]? = nil
        if let embedded = jsAward?["_embedded"] as? [String: Any],
           let arr = embedded["IFLineBaseAuctionJobShareAwards"] as? [[String: Any]] {
            jsAwardArray = arr
        }

        // If no lineAward embedded data -> ** NONE **
        guard let lineAward = lineAward,
              let embedded = lineAward["_embedded"] as? [String: Any],
              let awardArray = embedded["IFLineBaseAuctionAwards"] as? [[String: Any]],
              awardArray.count > 0 else {
            text += "** NONE **\n\n"
            return text
        }

        // Sort awards by line+position numerically if possible
        let sortedAwardArray = awardArray.sorted { a, b -> Bool in
            let aLine = String(describing: a["line"] ?? "")
            let aPos = String(describing: a["position"] ?? "")
            let bLine = String(describing: b["line"] ?? "")
            let bPos = String(describing: b["position"] ?? "")

            let aKey = aLine + aPos
            let bKey = bLine + bPos

            // attempt numeric compare by extracting ints where possible
            if let ai = Int(aKey), let bi = Int(bKey) { return ai < bi }
            return aKey.localizedStandardCompare(bKey) == .orderedAscending
        }

        var prevLineNum = ""
        let maxLineNumberLength = (sortedAwardArray.last?["line"] as? String)?.count ?? 0

        for awardDict in sortedAwardArray {
            let line = (awardDict["line"] as? String) ?? ""
            let position = (awardDict["position"] as? String) ?? ""

            var lineNum = ""

            if line == prevLineNum {
                // indent to align multi-row, width = maxLineNumberLength + 3
                let indent = String(repeating: " ", count: maxLineNumberLength + 3)
                lineNum = "\(indent)\(position)"
            } else {
                // padded left so the line numbers align
                let paddedLine = padLeft(line, to: max(0, maxLineNumberLength))
                lineNum = "\(paddedLine) - \(position)"

                if prevLineNum != "" {
                    text += "   ----------------------------------------------------------------------------------\n"
                }
                prevLineNum = line
            }

            // Check Jobshare: find matching jsAward with same baseSeniority
            var jsSeq = ""
            let seniorityNum = String(describing: awardDict["baseSeniority"] ?? "")
            if let jsArr = jsAwardArray {
                for js in jsArr {
                    let jsSen = String(describing: js["baseSeniority"] ?? "")
                    if jsSen == seniorityNum {
                        let pos = js["jobSharePosition"].map { String(describing: $0) } ?? ""
                        jsSeq = "JS\(pos)"
                        break
                    }
                }
            }

            var nameStr = String(describing: awardDict["legalName"] ?? "")
            if !jsSeq.isEmpty {
                nameStr = "\(nameStr)...\(jsSeq)"
            }

            let empNum = "[\(String(describing: awardDict["employeeId"] ?? ""))]"

            let regulatoryBool = (awardDict["regulatory"] as? Bool) ?? ((awardDict["regulatory"] as? NSNumber)?.boolValue ?? false)
            let regulatory = regulatoryBool ? "       Y" : "       N"

            // Build columns with padding
            let leftPadding = String(repeating: " ", count: col0Width)
            let lineWithPos = padRight(lineNum, to: col1Width)
            let seq = padRight(seniorityNum, to: col2Width)
            let name = padRight(nameStr, to: col3Width)
            let empID = padRight(empNum, to: col4Width)
            let nh = padRight("", to: col5Width)
            let reg = padRight(regulatory, to: col6Width)

            let rowString = "\(leftPadding)\(lineWithPos)\(seq)\(name)\(empID)\(nh)\(reg)\n"
            text += rowString
        }

        text += "\n\n"

        return text
    }
    
    static func mrtAwardString(_ mrtAward: [String: Any]?, bidPeriod: BIBidPeriod) -> String {
        var text = ""

        // Header title
        let monthName = CBUtils.shortMonthName(month: bidPeriod.month?.intValue ?? 0, uc: true)
        let year = bidPeriod.year ?? 0
        let base = bidPeriod.base ?? ""
        text += "**Subject to Protest**\n\(monthName) \(year)\nMRT Employees Awards - \(base)\n\n"

        // Fixed column widths
        let col0Width = 3   // Left Padding
        let col1Width = 8   // Base Seq (Sen)
        let col2Width = 10  // Emp ID
        let col3Width = 34  // Name
        let col4Width = 15  // Contingency

        // helper padding functions
        func padRight(_ s: String, to length: Int) -> String {
            if s.count >= length { return s }
            return s + String(repeating: " ", count: length - s.count)
        }
        func padLeft(_ s: String, to length: Int) -> String {
            if s.count >= length { return s }
            return String(repeating: " ", count: length - s.count) + s
        }

        // Header row
        let p0 = String(repeating: " ", count: col0Width)
        let header = "\(p0)\(padRight("Sen", to: col1Width))\(padRight("EmpID", to: col2Width))\(padRight("Name", to: col3Width))\(padRight("Cont. Bid", to: col4Width))\n"
        text += header
        text += "\n"

        guard let mrtAward = mrtAward,
              let embedded = mrtAward["_embedded"] as? [String: Any],
              let awardArray = embedded["IFLineBaseAuctionMrtAwards"] as? [[String: Any]],
              awardArray.count > 0
        else {
            text += "** NONE **\n\n\n"
            return text
        }

        let sortedAwardArray = awardArray.sorted { a, b -> Bool in
            let aLine = String(describing: a["line"] ?? "")
            let aPos = String(describing: a["position"] ?? "")
            let bLine = String(describing: b["line"] ?? "")
            let bPos = String(describing: b["position"] ?? "")
            let aKey = aLine + aPos
            let bKey = bLine + bPos
            if let ai = Int(aKey), let bi = Int(bKey) { return ai < bi }
            return aKey.localizedStandardCompare(bKey) == .orderedAscending
        }

        for awardDict in sortedAwardArray {
            let seniorityNum = String(describing: awardDict["baseSeniority"] ?? "")
            let nameStr = String(describing: awardDict["legalName"] ?? "")
            let empNum = String(describing: awardDict["employeeId"] ?? "")

            let contingencyBool = (awardDict["contingency"] as? Bool) ?? ((awardDict["contingency"] as? NSNumber)?.boolValue ?? false)
            let contingency = contingencyBool ? "     Y" : "     N"

            let leftPadding = String(repeating: " ", count: col0Width)
            let seq = padRight(seniorityNum, to: col1Width)
            let empID = padRight(empNum, to: col2Width)
            let name = padRight(nameStr, to: col3Width)
            let cont = padRight(contingency, to: col4Width)

            let rowString = "\(leftPadding)\(seq)\(empID)\(name)\(cont)\n"
            text += rowString
        }

        text += "\n\n"

        return text
    }
    
    static func jobshareAwardString(_ jobshareAward: [String: Any]?, bidPeriod: BIBidPeriod) -> String {
        var text = ""

        // Header title
        let monthName = CBUtils.shortMonthName(month: bidPeriod.month?.intValue ?? 0, uc: true)
        let year = bidPeriod.year ?? 0
        let base = bidPeriod.base ?? ""
        text += "**Subject to Protest**\n\(monthName) \(year)\nJob Share Employees Awards - \(base)\n\n"

        // Fixed column widths
        let col0Width = 3   // Left Padding
        let col1Width = 8   // Base Seq (Sen)
        let col2Width = 10  // Emp ID
        let col3Width = 34  // Name
        let col4Width = 6   // Jobshare Position
        let col5Width = 5   // Line Num
        let col6Width = 6   // Position
        let col7Width = 12  // Contingency

        // Padding helpers
        func padRight(_ s: String, to length: Int) -> String {
            if s.count >= length { return s }
            return s + String(repeating: " ", count: length - s.count)
        }
        func padLeft(_ s: String, to length: Int) -> String {
            if s.count >= length { return s }
            return String(repeating: " ", count: length - s.count) + s
        }

        // Header row
        let p0 = String(repeating: " ", count: col0Width)
        let header = "\(p0)\(padRight("Sen", to: col1Width))\(padRight("EmpID", to: col2Width))\(padRight("Name", to: col3Width))\(padRight("JPos", to: col4Width))\(padRight("L", to: col5Width))\(padRight("Pos", to: col6Width))\(padRight("Cont. Bid", to: col7Width))\n"
        text += header
        text += "\n"

        // Parse embedded jobshare array
        guard let jobshareAward = jobshareAward,
              let embedded = jobshareAward["_embedded"] as? [String: Any],
              let awardArray = embedded["IFLineBaseAuctionJobShareAwards"] as? [[String: Any]],
              awardArray.count > 0
        else {
            text += "** NONE **\n\n\n"
            return text
        }

        let sortedAwardArray = awardArray.sorted { a, b -> Bool in
            let aLine = String(describing: a["line"] ?? "")
            let aPos = String(describing: a["position"] ?? "")
            let bLine = String(describing: b["line"] ?? "")
            let bPos = String(describing: b["position"] ?? "")
            let aKey = aLine + aPos
            let bKey = bLine + bPos
            if let ai = Int(aKey), let bi = Int(bKey) { return ai < bi }
            return aKey.localizedStandardCompare(bKey) == .orderedAscending
        }

        for awardDict in sortedAwardArray {
            let line = String(describing: awardDict["line"] ?? "")
            let pos = String(describing: awardDict["position"] ?? "")
            let seniorityNum = String(describing: awardDict["baseSeniority"] ?? "")
            let nameStr = String(describing: awardDict["legalName"] ?? "")
            let empNum = String(describing: awardDict["employeeId"] ?? "")
            let contingencyBool = (awardDict["contingency"] as? Bool) ?? ((awardDict["contingency"] as? NSNumber)?.boolValue ?? false)
            let contingency = contingencyBool ? "    Y" : "    N"
            let jobSharePosition = String(describing: awardDict["jobSharePosition"] ?? "")
            let jPos = "JS\(jobSharePosition)"

            let leftPadding = String(repeating: " ", count: col0Width)
            let seq = padRight(seniorityNum, to: col1Width)
            let empID = padRight(empNum, to: col2Width)
            let name = padRight(nameStr, to: col3Width)
            let jobSharePos = padRight(jPos, to: col4Width)
            let lineNum = padRight(line, to: col5Width)
            let posStr = padRight(pos, to: col6Width)
            let cont = padRight(contingency, to: col7Width)

            let rowString = "\(leftPadding)\(seq)\(empID)\(name)\(jobSharePos)\(lineNum)\(posStr)\(cont)\n"
            text += rowString
        }

        text += "\n\n"
        return text
    }
    
    static func reserveAwardString(_ reserveData: [String: Any]?, bidPeriod: BIBidPeriod) -> String {
        var text = ""

        // Header title
        let monthName = CBUtils.shortMonthName(month: bidPeriod.month?.intValue ?? 0, uc: true)
        let year = bidPeriod.year ?? 0
        let base = bidPeriod.base ?? ""
        text += "**Subject to Protest**\n\(monthName) \(year)\nReserve List - \(base)\n\n"

        // Fixed column widths
        let col0Width = 3   // Left Padding
        let col1Width = 6   // Base Seq
        let col2Width = 38  // Name (filled with '-')
        let col3Width = 12  // Emp ID

        func padRight(_ s: String, to length: Int, fill: Character = " ") -> String {
            if s.count >= length { return s }
            return s + String(repeating: fill, count: length - s.count)
        }
        func padLeft(_ s: String, to length: Int) -> String {
            if s.count >= length { return s }
            return String(repeating: " ", count: length - s.count) + s
        }

        let p0 = String(repeating: " ", count: col0Width)
        let header = "\(p0)\(padRight("Sen#", to: col1Width))\(padRight("  ", to: 3))\(padRight("Name", to: col2Width))\(padRight("Emp ID", to: col3Width))\n"
        text += header
        text += "   -----------------------------------------------------\n"

        guard let reserve = reserveData,
              let embedded = reserve["_embedded"] as? [String: Any],
              let awardArray = embedded["IFLineBaseAuctionReserveAwards"] as? [[String: Any]],
              awardArray.count > 0
        else {
            text += "** NONE **\n\n"
            return text
        }

        let sortedAwardArray = awardArray.sorted { a, b -> Bool in

            let aKey = String(describing: a["baseSeniority"] ?? a["Seniority"] ?? "")
            let bKey = String(describing: b["baseSeniority"] ?? b["Seniority"] ?? "")
            if let ai = Int(aKey), let bi = Int(bKey) { return ai < bi }
            return aKey.localizedStandardCompare(bKey) == .orderedAscending
        }

        for awardDict in sortedAwardArray {
            let seniorityNum = String(describing: awardDict["baseSeniority"] ?? "")
            let nameStr = String(describing: awardDict["legalName"] ?? "")
            let empNum = String(describing: awardDict["employeeId"] ?? "")

            let leftPadding = String(repeating: " ", count: col0Width)
            let seq = padRight(seniorityNum, to: col1Width)
            let hyphen = padRight("-", to: 3)
            let name = padRight(nameStr, to: col2Width, fill: "-")
            let empID = padRight(empNum, to: col3Width)

            let rowString = "\(leftPadding)\(seq)\(hyphen)\(name)\(empID)\n"
            text += rowString
        }

        text += "\n"

        return text
    }
    
    static func lineAwardStringnameSort(_ lineAward: [String: Any]?, bidPeriod: BIBidPeriod) -> String {
        var text = ""

        // Header title
        let monthName = CBUtils.shortMonthName(month: bidPeriod.month?.intValue ?? 0, uc: true)
        let year = bidPeriod.year ?? 0
        let base = bidPeriod.base ?? ""
        text += "**Subject to Protest**\n\(monthName) \(year)\nAward List - \(base)\n\n"

        // Fixed column widths
        let col0Width = 3   // Left Padding
        let col1Width = 6   // Base Seq
        let col2Width = 38  // Name
        let col3Width = 12  // Emp ID
        let col4Width = 13  // Line Num

        // Padding helpers
        func padRight(_ s: String, to length: Int, fill: Character = " ") -> String {
            if s.count >= length { return s }
            return s + String(repeating: fill, count: length - s.count)
        }
        func padLeft(_ s: String, to length: Int) -> String {
            if s.count >= length { return s }
            return String(repeating: " ", count: length - s.count) + s
        }

        let p0 = String(repeating: " ", count: col0Width)
        let header = "\(p0)\(padRight("Sen#", to: col1Width))\(padRight("  ", to: 3))\(padRight("Name", to: col2Width))\(padRight("Emp #", to: col3Width))\(padRight("Line-Pos", to: col4Width))\n"
        text += header
        text += "   --------------------------------------------------------------------\n"

        guard let lineAward = lineAward,
              let embedded = lineAward["_embedded"] as? [String: Any],
              let awardArray = embedded["IFLineBaseAuctionAwards"] as? [[String: Any]],
              awardArray.count > 0
        else {
            text += "** NONE **\n\n\n"
            return text
        }

        let sortedAwardArray = awardArray.sorted { a, b -> Bool in
            let aName = String(describing: a["legalName"] ?? "")
            let bName = String(describing: b["legalName"] ?? "")
            return aName.localizedStandardCompare(bName) == .orderedAscending
        }

        for awardDict in sortedAwardArray {
            let lineNum = "\(String(describing: awardDict["line"] ?? ""))-\(String(describing: awardDict["position"] ?? ""))"
            let seniorityNum = String(describing: awardDict["baseSeniority"] ?? "")
            let nameStr = String(describing: awardDict["legalName"] ?? "")
            let empNum = "[\(String(describing: awardDict["employeeId"] ?? ""))]"

            let leftPadding = String(repeating: " ", count: col0Width)
            let seq = padRight(seniorityNum, to: col1Width)
            let hyphen = padRight("-", to: 3)
            let name = padRight(nameStr, to: col2Width)
            let empID = padRight(empNum, to: col3Width)
            let lineWithPos = padRight(lineNum, to: col4Width)

            let rowString = "\(leftPadding)\(seq)\(hyphen)\(name)\(empID)\(lineWithPos)\n"
            text += rowString
        }

        text += "\n\n"
        return text
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
