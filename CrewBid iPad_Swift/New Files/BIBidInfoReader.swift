//
//  BIBidInfoReader.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 20/05/25.
//

import Foundation
import CoreData

protocol BIBidInfoReaderDataSource: BIBidInfoDataSource {
    func managedObjectContext() -> NSManagedObjectContext
}

protocol BIBidInfoReaderDelegate: AnyObject {
    func bidInfoReader(_ bidInfoReader: BIBidInfoReader, didUpdateReadProgress progress: Float)
    func bidInfoReader(_ bidInfoReader: BIBidInfoReader, didUpdateProcessProgress progress: Float)
    func bidInfoReaderDidFinish(_ bidInfoReader: BIBidInfoReader)
    func bidInfoReader(_ bidInfoReader: BIBidInfoReader, didFailWithError error: Error)
}



class BIBidInfoReader{
    static let shared = BIBidInfoReader()
    
    let tripFileName = "TRIPS"
    let lineFileName = "PS"
    let dataSource = GlobalBidInfo.shared
    var trips:[String:Any] = [:]
    var dhStartCities:[String] = []
    var dhEndCities:[String] = []
    let tripNumberRegex = "[A-Z]{2}[1-9A-Z]{2}"
    let cityRegex = "[A-Z]{3}"
    let tripNumberRange = NSRange(location: 0, length: 4)
    let tripCalendarDaysCountRange = NSRange(location: 18, length: 1)
    let tripDepartTimeRange = NSRange(location: 22, length: 4)
    let tripReturnTimeRange = NSRange(location: 29, length: 4)
    let tripAmPmRange = NSRange(location: 36, length: 1)
    let tripDutyPeriodsCountRange = NSRange(location: 42, length: 1)
    let nonDigitCharacters = CharacterSet.decimalDigits.inverted
    let tripMaxDaysCount = 10
    let dayInterval = 7
    let dayCityRangeLocation = 5
    let dayCityRangeLength = 3
    let dayPayIntegerRangeLocation = 8
    let dayPayIntegerRangeLength = 2
    let dayPayDecimalRangeLocation = 10
    let dayPayDecimalRangeLength = 2
    let legRecord5Interval = 12
    let legTypeCharIndex = 0
    let legDepartMinutesRangeLocation = 1
    let legDepartMinutesRangeLength = 5
    let legDutyBreakCharIndex = 6
    let legArriveMinuteRangeLocation = 7
    let legArriveMinuteRangeLength = 5
    var legRecord6Interval = 15
    let legFlightRangeLocation = 0
    let legFlightRangeLength = 6
    let legDepartCityRangeLocation = 6
    let legDepartCityRangeLength = 3
    let legArriveCityRangeLocation = 9
    let legArriveCityRangeLength = 3
    let legAircraftChangeCharIndex = 12
    let legEquipmentCharIndex = 12
    let legEquipmentCharIndexForReserveLine = 13
    let legEquipmentRangeLength = 3
    let whitespace = CharacterSet.whitespaces
    var cityPredicate:NSPredicate?
    var tripNumberPredicate:NSPredicate?
    var tripsCount:Float = 0
    var linesCount:Float = 0
    var bidPeriod:BIBidPeriod?
    var calendarData = BICalendarData()
    var thanksgivingDay: UInt = 0
    var includeDroppedTrips:Bool?
    var intlCities:[String:Any] = [:]
    var dateComponents: DateComponents?
    var defaultEmployeeNumber: String?
    weak var delegate: BIBidInfoReaderDelegate?
    var showAlertForPP = false
    var isFA = false
    var missingTrips:[String]?
    var calendar:Calendar?
    var firstDateOfMonth:Date?
    var daysInMonth:Int?
    var weeksInMonth:Int?
    var workBPInVac: Int = 0
    var workBP: Int = 0
    init() {
            guard
                dataSource.year != 0,
                dataSource.month != 0,
                !dataSource.base.isEmpty,
                dataSource.position.rawValue != 3 ,
                dataSource.round != 0,
                !dataSource.employeeNumber.isEmpty
            else {
                print("Invalid GlobalBidInfo data")
                return
            }
        }


    
    func readBidData() ->Bool{
        if !self.isFABid() && self.isSecondRoundBid(){
            // check paper bid user vacation
        }
        self.initializeReadingVariables()
        var success:Bool = false
        
        if self.isFABid(){
            if self.isSecondRoundBid(){
                tripsCount = round(tripsCount/1.9145)
                linesCount = round(linesCount/8.6995)
            }else{
                tripsCount = round(tripsCount/1.9145)
                linesCount = round(linesCount/3.15)
            }
            success = self.readTripsFA()
            if success{
                print("Done Reading Trips FA")
                success = self.readLinesFA()
                if success{
                    print("Done Reading Lines FA")
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: Notification.Name("ParsingBid"), object: nil)
                    }
                }
                if success{
                    if AppState.shared.isHistoricBid{
                        success = true
                    }else{
//                        success = self.readTextFiles()
                    }
                }
                if success && self.isFirstRoundBid(){
                    //vacation scan
                }
                if success && self.isSecondRoundBid(){
                    //vacation scan
                }
                
            }
            
        }
        else{
            success = self.readTrips()
            if success{
                print("Done Reading Trips")
                
                success = self.readLines()
            }
                if success && self.isSecondRoundBid(){
//                    success = self.addSecondRoundTripsForBidPeriod()
                }
                if success{
                        if AppState.shared.isHistoricBid{
                            success = true
                        }else{
//                            success = self.readTripLegsPay()
                        }
                    
                    if let lines = self.bidPeriod?.lines?.allObjects as? [BILine] {
                        for line in lines {
//                            self.updateEndDateForRedEyeTrips(line)
//                            self.initRigRelatedPropertiesForLine(line, isReprocessing:false)
                        }
                    }
                }
                if success{
//                    self.addDefaultFilterRules(self.moc)
                }
                
                if success{
                        if AppState.shared.isHistoricBid{
                            success = true
                        }else{
//                            success =  self.readTextFiles()
                        }
                }
                if success{
                    // needs code- seniority
                }
                if success{
                    //calculate workblock details
                }
                if success{
                    print("Done Reading Lines")
                }
        }
        return success
    }
    
    //MARK: initialize Reading Variables
    private func initializeReadingVariables(){
        tripNumberPredicate = NSPredicate(format: "SELF MATCHES %@", tripNumberRegex)
        cityPredicate = NSPredicate(format: "SELF MATCHES %@", cityRegex)
        
        let tripsDataFileURL = BIBidInfo().downloadDirectory().appendingPathComponent(self.tripFileName)
        let linesFileURL = BIBidInfo().downloadDirectory().appendingPathComponent(self.lineFileName)
        if !FileManager.default.fileExists(atPath: tripsDataFileURL.path) || !FileManager.default.fileExists(atPath: linesFileURL.path){
            return}
        do {
            let tripsData = try NSString(contentsOf: tripsDataFileURL, encoding: String.Encoding.utf8.rawValue)
            tripsData.enumerateLines { (trip, stop) in
                if trip.first == "*"{
                    stop.pointee = true
                }else if trip.count > 4 && trip[trip.index(trip.startIndex, offsetBy: 4)] == "1"{
                    self.tripsCount += 1
                }
            }
            
            let linesData = try NSString(contentsOf: linesFileURL, encoding: String.Encoding.utf8.rawValue)
            linesData.enumerateLines { (line, stop) in
                if line.first == "*"{
                    stop.pointee = true
                }else{
                    self.linesCount += 1
                }
            }
        }catch{
            print("Error reading files: \(error.localizedDescription)")
        }
        
        
        var isHistoric: NSNumber = 0
        isHistoric = AppState.shared.isHistoricBid as NSNumber
        self.bidPeriod = BIBidPeriod(context: dataSource.managedObjectContext)
//        self.bidPeriod = BIBidPeriod(context: self.moc)
        self.bidPeriod?.isHistoric = isHistoric as NSNumber
        self.bidPeriod?.year = self.dataSource.year as NSNumber
        self.bidPeriod?.base = self.dataSource.base
        self.bidPeriod?.month = self.dataSource.month as NSNumber
        self.bidPeriod?.positionType = self.dataSource.position.rawValue as NSNumber
        self.bidPeriod?.round = self.dataSource.round as NSNumber
        self.bidPeriod?.appVersion = CBUtils.AppVersion()
        
        let secretEnabled = UserDefaults.standard.string(forKey: "isHistoricSecretVDSwitchEnabled")
        if secretEnabled == "YES"{
            self.bidPeriod?.crewIdentifier = Int(UserDefaults.standard.string(forKey: "SecretVDuserName")!) as? NSNumber
        }else{
            self.bidPeriod?.crewIdentifier = Int(self.dataSource.employeeNumber) as? NSNumber
        }
        self.thanksgivingDay = CBUtils.thanksgivingDay(for: (self.bidPeriod?.year!.intValue)!)
        self.includeDroppedTrips = UserDefaults.standard.bool(forKey: kCBIncludeDroppedTripsInProcessingKey)
        self.bidPeriod?.swaptimizerIdentifier = Int(self.dataSource.employeeNumber) as? NSNumber
         
//        self.intlCities = UserDefaults.standard.object(forKey: kCBInternationalCitiesDict) as! [String : Any]
        //need to create the cities list
        
        self.bidPeriod?.isAllLinesTrashed = false
    }
    
    //MARK: Read Trips file
    private func readTrips() -> Bool{
        var success = true
        
//        let moc = self.moc
        let moc = dataSource.managedObjectContext
        moc.undoManager = nil
        let tripsDataFileURL = BIBidInfo().downloadDirectory().appendingPathComponent(self.tripFileName)
        if !FileManager.default.fileExists(atPath: tripsDataFileURL.path){
            return false}
        do{
            let tripsData = try NSString(contentsOf: tripsDataFileURL, encoding: String.Encoding.utf8.rawValue)
            
            var counter = 0
            let recordLength = 80
            let recordTypeCharIndex = 4
            var tripInfo:BITripInfo?
            var briefMinutes = 0
            var debriefMinutes = 0
            var record6Count = 0
            var digits = ""
            var addString = ""
            var appendString = ""
            var record5 = ""
            var record6 = ""
            let briefHoursRange = NSRange(location: 69, length: 2)
            let briefMinutesRange = NSRange(location: 71, length: 2)
            let debriefHoursRange = NSRange(location: 73, length: 2)
            let debriefMinutesRange = NSRange(location: 75, length: 2)
            let legInfoRange = NSRange(location: 5, length: 72)
            let record6CountRange = NSRange(location: 79, length: 1)

            var trips:[String:BITripInfo] = [:]
            tripsData.enumerateLines { (info, stop) in
                if info.first == "*"{
                    stop.pointee = true
                    return
                }
                if recordLength != info.length{
                    //handle error
                    stop.pointee = true
                    success = false
                    return
                }
                switch info.character(at: recordTypeCharIndex){
                    //Record 1
                    // Trip number, AM or PM, length (number of calendar days), number
                    // of duty periods.
                case "1": counter += 1
                    if counter%10 == 0{
                       if moc.hasChanges{
                            do{
                                try moc.save()
                            }catch{
                                //handle error
                                print("Error saving context in readTrips(): \(error)")
                                success = false
                                stop.pointee = true
                                return
                            }
                        }
                    }
                    tripInfo = BITripInfo(context: moc)
                    //set trip info properties for record 1
                    if !self.setPropertiesForTripInfoRecord1(tripInfo: tripInfo!, record1: info){
                        //handle error
                        success = false
                        stop.pointee = true
                        return
                    }
                    trips[(tripInfo?.number)!] = tripInfo
                    record5 = ""
                    record6 = ""
                    break
                    
                    //Record 2
                    // Day overnight cities and pay.
                case "2":
                    if !self.readDaysInfoTripsInfoRecord2(tripInfo: tripInfo!, record2: info){
                        //handle error
                        success = false
                        stop.pointee = true
                        return
                    }
                    break
                    
                    //Record 3
                    //Trip brief and debrief minutes
                case "3":
                    if let char = tripInfo?.number!.dropFirst().first, char >= "W" {
                        tripInfo?.briefMinutes = 0
                        tripInfo?.debriefMinutes = 0
                    }else{
                        //brief minutes
                        var range = Range(briefHoursRange, in: info)!
                        digits = String(info[range])
                        if !self.isDigitString(digits, trimWhitespace: false){
                            //handle error
                            success = false
                            stop.pointee = true
                            return
                        }
                        briefMinutes = (digits as NSString).integerValue * 60
                        range = Range(briefMinutesRange, in: info)!
                        digits = String(info[range])
                        if !self.isDigitString(digits, trimWhitespace: false){
                            //handle error
                            success = false
                            stop.pointee = true
                            return
                        }
                        briefMinutes += (digits as NSString).integerValue
                        tripInfo?.briefMinutes = briefMinutes as NSNumber
                        
                        //debrief minutes
                        range = Range(debriefHoursRange, in: info)!
                        digits = String(info[range])
                        if !self.isDigitString(digits, trimWhitespace: false){
                            //handle error
                            success = false
                            stop.pointee = true
                            return
                        }
                        debriefMinutes = (digits as NSString).integerValue * 60
                        range = Range(debriefMinutesRange, in: info)!
                        digits = String(info[range])
                        if !self.isDigitString(digits, trimWhitespace: false){
                            success = false
                            stop.pointee = true
                            return
                        }
                        debriefMinutes += (digits as NSString).integerValue
                        tripInfo?.debriefMinutes = debriefMinutes as NSNumber
                        
                    }
                    if let char = tripInfo?.number!.dropFirst().first, char >= "W" {
                        if (self.bidPeriod?.positionType?.intValue == BICrewPositionType.Captain.rawValue)||(self.bidPeriod?.positionType?.intValue == BICrewPositionType.FirstOfficer.rawValue) {
                            var range = Range(briefHoursRange, in: info)!
                            digits = String(info[range])
                            range = Range(briefMinutesRange, in: info)!
                            addString = String(info[range])
                            appendString = digits.appending(addString)
                            tripInfo?.departTime = Int(appendString) as? NSNumber
                            
                            //Latest Arrival
                            var tripReturnTime = tripInfo?.returnTime?.intValue
                            if tripReturnTime! < 400{
                                tripReturnTime! += 2400
                                tripInfo?.returnTime = tripReturnTime as? NSNumber
                            }
                            
                        }
                        
                    }
                    break
                    
                    //Record 5
                    // Legs international, deadhead, depart and arrive minutes
                    // (since midnight of the first day of trip), duty break, and,
                    // number of type 6 records.
                case "5":
                    //Append Legs data to record 5
                    var range = Range(legInfoRange, in: info)!
                        record5 += String(info[range])
                        if legInfoRange.length == record5.length{
                            range = Range(record6CountRange, in: info)!
                            digits = String(info[range])
                            if !self.isDigitString(digits, trimWhitespace: false){
                                //handle error
                                success = false
                                stop.pointee = true
                                return
                            }
                            record6Count = (digits as NSString).integerValue
                        }
                    
                    break
                    //Record 6
                    // Legs flight number, depart and arrive city, equipment, and
                    // aircraft change.
                case "6":
                    // Append legs data to record 6
                    let range = Range(legInfoRange, in: info)!
                        record6 += String(info[range])
                        // If this is the last record6, read legs info
                        if record6.length/legInfoRange.length == record6Count{
                            if !self.readLegsInfoForTripInfo(tripInfo: tripInfo!, record5: record5, record6: record6){
                                //handle error
                                success = false
                                stop.pointee = true
                                return
                            }
                        }
                    
                    break
                default:
                    //handle error
                    success = false
                    stop.pointee = true
                    return
                }
            }
            
            if moc.hasChanges{
                do{
                    try moc.save()
                }catch{
                    print("Error saving file: \(error)")
                }
            }else{
                //handle error
                success = false
            }
            if success{
                self.trips = trips
            }
        }catch{
            print("Error reading file: \(error)")
        }
        
        return success
    }
    
    //MARK: Read Lines file
    private func readLines() -> Bool{
        var success = true
//        let moc = self.moc
        let moc = dataSource.managedObjectContext
        let linesDataFileURL = BIBidInfo().downloadDirectory().appendingPathComponent(self.lineFileName)
        if !FileManager.default.fileExists(atPath: linesDataFileURL.path){
            return false}
        do{
            let linesData = try NSString(contentsOf: linesDataFileURL, encoding: String.Encoding.utf8.rawValue)
            
            var counter = 0
            let numberRange = NSRange(location: 0, length: 6)
            let typeCharIndex = 6
            let typetopsCharIndex = 80
            let continuedLineCharIndex = 70
            var isContinuedLine = false
            let payIntegerRange = NSRange(location: 71, length: 3)
            let payFractionRange = NSRange(location: 74, length: 2)
            var pay:Float = 0
            let blockHoursRange = NSRange(location: 76, length: 2)
            let blockMinutesRange = NSRange(location: 78, length: 2)
            var blockMinutes = 0
            var line:BILine? = nil
            var digits:String = ""
            var pLines:[Int:BILine] = [:]
            self.bidPeriod?.bidByEmpID = self.dataSource.employeeNumber
            
            linesData.enumerateLines { (info, stop) in
                if info.length > 80{
                    let c = info[info.index(info.startIndex, offsetBy: typetopsCharIndex)]
                    let EtopsStr = String(c)
                    if EtopsStr == "E"{
                        self.bidPeriod?.isEtopsLinesContainsInBid = true
                        stop.pointee = true
                    }
                }
            }
            
            linesData.enumerateLines { (info, stop) in
                    //end of data
                    if info.character(at: 0) == "*"{
                        return
                    }
                    counter += 1
                    if counter%10 == 0{
                        if moc.hasChanges{
                            do{
                                try moc.save()
                            }catch{
                                //handle error
                                print("Error saving context in readLines(): \(error)")
                            }
                        }
                    }
                    
                    if isContinuedLine{
                        //add trips to current line
                        if !self.readTripsForLine(line: line!, record: info){
                            //handle error
                            success = false
                            stop.pointee = true
                            return
                        }
                    }else{
                        //finalize previously read line
                        if let currentline = line, self.bidPeriod?.isFirstRoundBid() == true{
                            self.initDerivedPropertiesForLine(line: currentline, isReprocessing:false)
                        }
                        
                        digits = (info as NSString).substring(with: numberRange)
                        if !self.isDigitString(digits, trimWhitespace: true){
                            //handle error
                            success = false
                            stop.pointee = true
                            return
                        }
                        
                        //Create Line
                        line = BILine(context: moc)
                        
                        //Number
                        line?.number = (digits as NSString).integerValue as NSNumber
                        if self.bidPeriod?.firstLineNumber?.intValue == 0{
                            self.bidPeriod?.firstLineNumber = line?.number
                        }
                        // Add the lines to the pilot lines dictionary for using in reading round 2 bidding trips
                        pLines[line?.number as! Int] = line
                        
                        //Type - Hard, Reserve or Blank
                        switch info.character(at: typeCharIndex){
                        case "H":
                            if self.bidPeriod?.isFirstRoundBid() == true{
                                line?.type = BILineType.LineTypeHardConus.rawValue as NSNumber
                            }else{
                                line?.type = BILineType.HardLineType.rawValue as NSNumber
                            }
                            break
                        case "R":
                            line?.type = BILineType.ReserveLineType.rawValue as NSNumber
                            break
                        case " ":
                            line?.type = BILineType.BlankLineType.rawValue as NSNumber
                            break
                        case "M":
                            line?.type = BILineType.MixedLineType.rawValue as NSNumber
                            break
                        default:
                            //handle error
                            success = false
                            stop.pointee = true
                            return
                        }
                        
                        //Type - ETOPS
                        if info.length > 80{
                            let c = info[info.index(info.startIndex, offsetBy: typetopsCharIndex)]
                            let EtopsStr = String(c)
                            if EtopsStr == "E"{
                                line?.isETOPS = true
                                if line?.type?.intValue == BILineType.ReserveLineType.rawValue{
                                    line?.isETOPSRES = true
                                    line?.isETOPS = false
                                }else{
                                    line?.isETOPSRES = false
                                }
                                // If line type is mixedlinetype(contains both normal and reserve trips) then we need to consider the lines as Etops Reserve line
                                if line?.type?.intValue == BILineType.MixedLineType.rawValue{
                                    line?.isETOPSRES = true
                                    line?.isETOPS = false
                                }
                            }else{
                                line?.isETOPS = false
                                line?.isETOPSRES = false
                            }
                        }else{
                            line?.isETOPS = false
                            line?.isETOPSRES = false
                        }
                        
                        if self.bidPeriod?.isEtopsLinesContainsInBid?.intValue == 1 {
                            
                            // Non-reserve ETOPS
                            if line?.isETOPS?.intValue == 1, line?.type?.intValue != BILineType.ReserveLineType.rawValue {
                                line?.type = NSNumber(value: BILineType.LineTypeNonReserveEtops.rawValue)
                            }
                            
                            // Non-ETOPS Reserve
                            if line?.type?.intValue == BILineType.ReserveLineType.rawValue, line?.isETOPS?.intValue == 0, line?.isETOPSRES?.intValue == 0 {
                                line?.type = NSNumber(value: BILineType.LineTypeNonEtopsReserve.rawValue)
                            }
                            
                            // ETOPS Reserve
                            if line?.type?.intValue == BILineType.ReserveLineType.rawValue, line?.isETOPS?.intValue == 1 {
                                line?.type = NSNumber(value: BILineType.LineTypeEtopsReserve.rawValue)
                            }
                            
                            // Non-ETOPS Hard CONUS
                            if line?.type?.intValue == BILineType.LineTypeHardConus.rawValue, line?.isETOPS?.intValue == 0 {
                                line?.type = NSNumber(value: BILineType.LineTypeNonEtopsConUs.rawValue)
                            }
                            
                            // Non-ETOPS Hard (2nd round)
                            if self.bidPeriod?.isSecondRoundBid() == true, line?.type?.intValue == BILineType.HardLineType.rawValue, line?.isETOPS?.intValue == 0 {
                                line?.type = NSNumber(value: BILineType.LineTypeNonEtopsHard.rawValue)
                            }
                            
                            // Non-ETOPS Mixed (2nd round)
                            if self.bidPeriod?.isSecondRoundBid() == true, line?.type?.intValue == BILineType.MixedLineType.rawValue, line?.isETOPS?.intValue == 0 {
                                line?.type = NSNumber(value: BILineType.LineTypeNonEtopsMixed.rawValue)
                            }
                        }
                        
                        //Pay
                        digits = (info as NSString).substring(with: payIntegerRange)
                        if !self.isDigitString(digits, trimWhitespace: false){
                            //handle error
                            success = false
                            stop.pointee = true
                            return
                        }
                        pay = digits.floatValue
                        digits = (info as NSString).substring(with: payFractionRange)
                        if !self.isDigitString(digits, trimWhitespace: false){
                            //handle error
                            success = false
                            stop.pointee = true
                            return
                        }
                        pay += digits.floatValue / 60
                        line?.pay = pay as NSNumber
                        
                        // actualPay is used for assingning linepay after vacation turnoff.
                        line?.actualPay = pay as NSNumber
                        line?.tripTfp = line?.actualPay
                        line?.vTpLPay = line?.lineRig
                        
                        //Block minutes
                        digits = (info as NSString).substring(with: blockHoursRange)
    
                        if !self.isDigitString(digits, trimWhitespace: true){
                            //handle error
                            success = false
                            stop.pointee = true
                            return
                        }
                        blockMinutes = (digits as NSString).integerValue * 60
                        digits = (info as NSString).substring(with: blockMinutesRange)
                        if !self.isDigitString(digits, trimWhitespace: true){
                            //handle error
                            success = false
                            stop.pointee = true
                            return
                        }
                        blockMinutes += (digits as NSString).integerValue
                        line?.blockMinutes = blockMinutes as NSNumber
                        
                        // actual blockMinutes is used for assingning linepay after vacation turnoff.
                        line?.actualBlockMinutes = blockMinutes as NSNumber
                        
                        //Read Trips
                        if !self.readTripsForLine(line: line!, record: info){
                            //handle error
                            success = false
                            stop.pointee = true
                            return
                        }
                        
                        //Set bid period
                        line?.bidPeriod = self.bidPeriod
                    }
                    isContinuedLine = info.character(at: continuedLineCharIndex) == "C"
                
            }
        }catch{
            print("Error reading file: \(error)")
        }
        return success
    
    }
    
    //MARK: Read Trips file FA - done
    private func readTripsFA() -> Bool{
        var success = true
//        let moc = self.moc
        let moc = dataSource.managedObjectContext
        moc.undoManager = nil
        let tripsDataFileURL = BIBidInfo().downloadDirectory().appendingPathComponent(self.tripFileName)
        if !FileManager.default.fileExists(atPath: tripsDataFileURL.path){
            return false}
        do {
            let tripsData = try NSString(contentsOf: tripsDataFileURL, encoding: String.Encoding.utf8.rawValue)

            
            var counter = 0
            var tripInfo:BITripInfo?
            var lineRange = NSRange(location: 0, length: 0)
            var start: UInt = 0
            var lineEnd: UInt = 0
            var contentsEnd: UInt = 0
            
            let EMPTY_STRING: NSString = ""
            let TRIP_START: NSString = "T1"
            let LEG_START: NSString = "L"
            let DAY_END: NSString = "D"
            
            var dayIndex = 0
            var legIndex = 0
            
            let TRIP_NUMBER_RANGE = NSRange(location: 2, length: 4)
            let TRIP_PAY_RANGE = NSRange(location: 45, length: 5)
            var faTrips:[String:Any] = [:]
            var tripNumber: NSString? = nil

                // Get first line info
            tripsData.getLineStart(&start, end: &lineEnd, contentsEnd: &contentsEnd, for: lineRange)
            lineRange.location = Int(start)
            lineRange.length = Int(contentsEnd - start)
            
            let fileString = NSMutableString(string: tripsData.substring(with: lineRange))
            var day:BIDayInfo?
            var prevDay:BIDayInfo?
            var leg:BILegInfo?
            var prevLeg:BILegInfo?
            var continueProcessing: Bool = true
            
            if moc.persistentStoreCoordinator?.persistentStores.count == 0{
                //handle error
                success = false
                continueProcessing = false
                return false
            }
            while fileString != EMPTY_STRING && continueProcessing {
                if fileString.hasPrefix(TRIP_START as String) {
                    counter += 1
                    if counter % 10 == 0 {
                        if moc.hasChanges {
                            do {
                                try moc.save()
                            } catch {
                                print("Error saving context: \(error)")
                                success = false
                                continueProcessing = false
                                return false
                            }
                        }
                    }
                    
                    if tripInfo != nil{
                        prevDay = nil
                        prevLeg = nil
                        tripInfo?.calendarDaysCount = dayIndex as NSNumber
                        tripInfo?.dutyPeriodsCount = dayIndex as NSNumber
                        tripInfo?.returnTime = CBUtils.convertMinsToHHMM(leg?.arriveMinutes?.intValue ?? 0) as NSNumber
                        let herbValueStr = UserDefaults.standard.string(forKey: KCBCustomizedHerbValue)
                        let herbValue: Int

                        if let herbValueStr = herbValueStr, !herbValueStr.isEmpty {
                            herbValue = Int(herbValueStr) ?? 0
                        } else {
                            herbValue = 1200
                        }
                        if (tripInfo?.departTime!.intValue)! < herbValue{
                            tripInfo?.amPM = BIAMPMTripType.AMTrip.rawValue as NSNumber
                        }else{
                            tripInfo?.amPM = BIAMPMTripType.PMTrip.rawValue as NSNumber
                        }
                        self.bidPeriod?.currentAmPmHerb = herbValue as NSNumber
                        faTrips[(tripInfo?.number)!] = tripInfo!
                        tripInfo = nil
                    }
                    tripInfo = BITripInfo(context: moc)
                    tripNumber = fileString.substring(with: TRIP_NUMBER_RANGE) as NSString
                    if !self.matchesTripNumberFormat(tripNumber: tripNumber! as String){
                        return false
                    }
                    tripInfo?.number = tripNumber as? String
                    
                    //Pay
                    let digits = fileString.substring(with: TRIP_PAY_RANGE)
                    let tripPay:Float = digits.floatValue/60
                    tripInfo?.faPay = tripPay as NSNumber
                    prevDay = nil
                    dayIndex = 0
                    legIndex = 0
                    tripInfo?.briefMinutes = 60
                    tripInfo?.debriefMinutes = 30
                }else if fileString.hasPrefix(LEG_START as String){
                   leg = BILegInfo(context: moc)
                    
                    //Check if leg is red eye
                    if fileString.substring(with: NSRange(location: 74, length: 1)) == "0"{
                        leg?.isRedEyeFlight = true
                    }else{
                        leg?.isRedEyeFlight = false
                    }
                    var flight = fileString.substring(with: NSRange(location: 4, length: 4))
                    flight = flight.trimmingCharacters(in: .whitespaces)
                    while flight.first == "0"{
                        flight.removeFirst()
                    }
                    leg?.flight = flight
                    
                    // Depart minutes.
                    var digits = fileString.substring(with: NSRange(location: 23, length: 4))
                    if !self.isDigitString(digits, trimWhitespace: true){
                        return false
                    }
                    let departMinutes = (digits as NSString).integerValue - 1440
                    leg?.departMinutes = departMinutes as NSNumber
                    
                    //Deadhead
                    let isDeadHead = fileString.character(at: 60) == UnicodeScalar("1").value
                    leg?.isDeadhead = isDeadHead as NSNumber
                    
                    //Depart city
                    let departCity = fileString.substring(with: NSRange(location: 13, length: 3))
                    if !(self.cityPredicate?.evaluate(with: departCity))!{
                        return false
                    }
                    leg?.departCity = departCity
                    
                    //Arrive city
                    let arriveCity = fileString.substring(with: NSRange(location: 32, length: 3))
                    if !(self.cityPredicate?.evaluate(with: arriveCity))!{
                        return false
                    }
                    leg?.arriveCity = arriveCity
                    
                    //Hawaii cities
                    if let hawaiiCities = UserDefaults.standard.array(forKey: kCBHawaiiCitiesList) as? [String],hawaiiCities.contains(arriveCity) {
                        tripInfo?.isETOPS = true
                    }
                    
                    //Arrive minutes
                    digits = fileString.substring(with: NSRange(location: 42, length: 4))
                    if !self.isDigitString(digits, trimWhitespace: true){
                        return false
                    }
                    let arriveMinutes = (digits as NSString).integerValue - 1440
                    leg?.arriveMinutes = arriveMinutes as NSNumber
                    
                    //Equipment
                    let equipment = fileString.substring(with: NSRange(location: 9, length: 3))
                    leg?.equipment = equipment
                    
                    //Aircraft change
                    let isAircraftChange = fileString.character(at: 57) == UnicodeScalar("1").value
                    leg?.isAircraftChange = isAircraftChange as NSNumber
                    
                    //Leg pay
                    let legPay = fileString.substring(with: NSRange(location: 67, length: 4))
                    leg?.pay = legPay.floatValue/100 as NSNumber
                    
                    if legIndex == 0 && dayIndex == 0{
                        tripInfo?.departTime = CBUtils.convertMinsToHHMM(leg?.departMinutes?.intValue ?? 0) as NSNumber
                    }
                    
                    //Etops
                    let etopschar = fileString.character(at: 73)
                    let etopsString = String(etopschar)
                    if etopsString == "H"{
                        leg?.isEtopsFlight = true
                        self.bidPeriod?.isEtopsLinesContainsInBid = true
                    }
                    
                    //Day first leg
                    if legIndex == 0{
                        day = BIDayInfo(context: moc)
                        day?.trip = tripInfo
                        day?.previousDay = prevDay
                        tripInfo?.firstDay = day
                        day?.firstLeg = leg
                        dayIndex += 1
                    }
                    
                    //Day
                    leg?.day = day
                    //Previous leg
                    leg?.previousLeg = prevLeg
                    prevLeg = leg
                    legIndex += 1
                    
                }else if fileString.hasPrefix(DAY_END as String){
                    //Duty break. Also calculate the max legs in a day
                    leg?.isDutyBreak = true
                    day?.city = leg?.arriveCity
                    day?.previousDay = prevDay
                    prevDay = day
                    legIndex = 0
                }
                
                //Get next line of the file
                lineRange.location = Int(lineEnd)
                lineRange.length = 0
                tripsData.getLineStart(&start, end: &lineEnd, contentsEnd: &contentsEnd, for: lineRange)
                lineRange.location = Int(start)
                lineRange.length = Int(contentsEnd - start)
                fileString.setString(tripsData.substring(with: lineRange))
            }
            
            //Add the last trip
            //Trip length
            tripInfo?.calendarDaysCount = dayIndex as NSNumber
            
            //Duty periods
            tripInfo?.dutyPeriodsCount = dayIndex as NSNumber
            
            //Set trip departure and arrival times
            tripInfo?.returnTime = CBUtils.convertMinsToHHMM(leg?.arriveMinutes?.intValue ?? 0) as NSNumber
            
            let herbValueStr = UserDefaults.standard.string(forKey: KCBCustomizedHerbValue)
            let herbValue: Int
            if let herbValueStr = herbValueStr, !herbValueStr.isEmpty {
                herbValue = Int(herbValueStr) ?? 0
            } else {
                herbValue = 1200
            }
            if (tripInfo?.departTime!.intValue)! < herbValue {
                tripInfo?.amPM = BIAMPMTripType.AMTrip.rawValue as NSNumber
            }else{
                tripInfo?.amPM = BIAMPMTripType.PMTrip.rawValue as NSNumber
            }
            self.bidPeriod?.currentAmPmHerb = herbValue as NSNumber
            faTrips[(tripInfo?.number)!] = tripInfo
            tripInfo = nil
            
            if success{
                self.trips = faTrips
            }
        } catch {
            print("Failed to read file: \(error)")
            success = false
        }
        return success
    }
    
    //MARK: Read Lines file FA
    private func readLinesFA() -> Bool{
        
        var success = true
//        let moc = self.moc
        let moc = dataSource.managedObjectContext
        let linesDataFileURL = BIBidInfo().downloadDirectory().appendingPathComponent(self.lineFileName)
        if !FileManager.default.fileExists(atPath: linesDataFileURL.path){
            return false}
        do{
            let linesData = try NSString(contentsOf: linesDataFileURL, encoding: String.Encoding.utf8.rawValue)

            var numberRange = NSRange(location: 4, length: 3)
            let storedValue = UserDefaults.standard.string(forKey: "PSFileFormatChange")
            if storedValue != nil {
                    if !AppState.shared.isHistoricBid{
                        if Int(storedValue!) == 0{
                            print("Old format")
                            numberRange = NSRange(location: 4, length: 3)
                        }else{
                            print("New format")
                            numberRange = NSRange(location: 3, length: 4)
                        }
                    }
                    else{
                        var dateComponents1 = DateComponents()
                        dateComponents1.day = 1
                        dateComponents1.month = AppState.shared.mockDataMonth
                        dateComponents1.year = AppState.shared.mockDataYear
                        
                        var dateComponents2 = DateComponents()
                        dateComponents2.day = 1
                        dateComponents2.month = Int(storedValue!)
                        dateComponents2.year = 2024
                        
                        let calendar = Calendar(identifier: .gregorian)
                        let date1 = calendar.date(from: dateComponents1)!
                        let date2 = calendar.date(from: dateComponents2)!
                        
                        let result =  date1.compare(date2)
                        if result == .orderedAscending{
                            print("Date 1 is earlier than Date 2 - Old Format")
                            numberRange = NSRange(location: 4, length: 3)
                        }else{
                            print("Date 1 is later than Date 2 - New Format")
                            numberRange = NSRange(location: 3, length: 4)
                        }
                    }
                
            }else{
                print("No value found in UserDefaults for the specified key")
            }
            
            var digits = ""
            let payRange = NSRange(location: 12, length: 5)
            var pay:Float = 0
            let blockHoursRange = NSRange(location: 17, length: 3)
            let blockMinutesRange = NSRange(location: 20, length: 2)
            var blockMinutes = 0
            
            var lineRange = NSRange(location: 0, length: 0)
            var lineStart: UInt = 0
            var lineEnd: UInt = 0
            var contentsEnd: UInt = 0
            
            let fileLength = linesData.length
            linesData.getLineStart(&lineStart, end: &lineEnd, contentsEnd: &contentsEnd, for: lineRange)
            lineRange.location = Int(lineStart)
            lineRange.length = Int(contentsEnd - lineStart)
            var lineFile:NSString = linesData.substring(with: lineRange) as NSString
       
            
            var counter = 0
            var line:BILine?
            var moreLinesToRead = true
            
            while moreLinesToRead{
                
                //Start new line
                if lineFile.hasPrefix("C"){
                    counter += 1
                    if counter%10 == 0{
                        if moc.hasChanges{
                            do{
                                try moc.save()
                            }catch{
                                print("Error saving context: \(error.localizedDescription)")
                                //handle error
                                success = false
                                return false
                            }
                        }
                    }
                    if (line != nil){
                        self.initDerivedPropertiesForLine(line: line!, isReprocessing: false)
                    }
                    
                    digits = lineFile.substring(with: numberRange) as String
                    if !self.isDigitString(digits, trimWhitespace: true){
                        //handle error
                        success = false
                        return false
                    }
                    
                    line = BILine(context: moc)
                    let bidPeriod = try moc.existingObject(with: self.bidPeriod!.objectID) as? BIBidPeriod
                    
                    line?.bidPeriod = bidPeriod
                    bidPeriod?.bidByEmpID = self.dataSource.employeeNumber
                    
                    //Number
                   
                    line?.number = (digits as NSString).integerValue as NSNumber
                
                    if self.bidPeriod?.firstLineNumber?.intValue == 0 {
                        self.bidPeriod?.firstLineNumber = line?.number
                    }
                    
                    //Pay
                    digits = lineFile.substring(with: payRange)
                    if !self.isDigitString(digits, trimWhitespace: false){
                        //handle error
                        success = false
                        return false
                    }
                    pay = digits.floatValue / 100
                    line?.pay = pay as NSNumber
                    line?.actualPay = pay as NSNumber
                    line?.tripTfp = line?.actualPay
                    
                    //Block minutes
                    digits = lineFile.substring(with: blockHoursRange)
                    if !self.isDigitString(digits, trimWhitespace: true){
                        //handle error
                        success = false
                        return false
                    }
                    blockMinutes = (digits as NSString).integerValue * 60
                    digits = lineFile.substring(with: blockMinutesRange)
                    if !self.isDigitString(digits, trimWhitespace: true){
                        //handle error
                        success = false
                        return false
                    }
                    blockMinutes += (digits as NSString).integerValue
                    line?.blockMinutes = blockMinutes as NSNumber
                    line?.actualBlockMinutes = blockMinutes as NSNumber
                    
                }
                
                else if lineFile.hasPrefix("T"){
                    line?.type = BILineType.LineTypeHardConus.name() as NSNumber
                    
                    //Read trips
                    if !self.readTripsForLine(line: line!, record: lineFile, isReserve: false){
                        //handle error
                        success = false
                        return false
                    }
                }else if lineFile.hasPrefix("A"){
                    line?.type = BILineType.ReserveLineType.name() as NSNumber
                    //Read trips
                    if !self.readTripsForLine(line: line!, record: lineFile, isReserve: true){
                        //handle error
                        success = false
                        return false
                    }
                }//if end
                linesData.getLineStart(&lineStart, end: &lineEnd, contentsEnd: &contentsEnd, for: lineRange)
                lineRange.location = Int(lineStart)
                lineRange.length = Int(contentsEnd - lineStart)
                
                if lineRange.location < fileLength{
                    lineFile = (linesData as NSString).substring(with: lineRange) as NSString
                    lineRange.location = Int(lineEnd)
                    lineRange.length = 0
                }
                else{
                    moreLinesToRead = false
                }
                if lineFile.range(of: "").location != NSNotFound{
                    moreLinesToRead = false
                }
                
            }// while end
            let linesFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Line")
            linesFetch.sortDescriptors = [NSSortDescriptor(key: "number", ascending: true)]
            let objResults = try moc.fetch(linesFetch)
            
            for case let line as BILine in objResults{
                for case let trip as BITrip in line.orderedTrips{
                    let tripOrderedDays = (trip.info?.orderedDays)!
                    for case let dayInfo as BIDayInfo in tripOrderedDays{
                        let dayOrderedLegs = dayInfo.orderedLegs
                        for case let legInfo as BILegInfo in dayOrderedLegs{
                            let arriveCity = (legInfo.arriveCity)!
                            let isIntlCity = self.intlCities[arriveCity]
                            if isIntlCity != nil{
                                line.type = BILineType.LineTypeHardNonConus.rawValue as NSNumber
                            }
                            if legInfo.isEtopsFlight?.boolValue == true{
                                line.isETOPS = true
                            }
                            else{
                                if line.isETOPS == false{
                                    line.isETOPS = false
                                }
                            }
                        }
                    }
                }
                if self.bidPeriod?.isEtopsLinesContainsInBid?.intValue == 1{
                    if (self.bidPeriod?.isSecondRoundBid())! && line.isETOPS?.intValue == 1 && !(line.type?.intValue == BILineType.ReserveLineType.rawValue){
                        line.type = BILineType.LineTypeNonReserveEtops.rawValue as NSNumber
                    }
                    if (self.bidPeriod?.isSecondRoundBid())! && line.type?.intValue == BILineType.ReserveLineType.rawValue && line.isETOPS?.intValue == 0{
                        line.type = BILineType.LineTypeNonEtopsReserve.rawValue as NSNumber
                    }
                    if line.type?.intValue == BILineType.LineTypeHardConus.rawValue && line.isETOPS?.intValue == 0{
                        line.type = BILineType.LineTypeNonEtopsConUs.rawValue as NSNumber
                    }
                    if line.type?.intValue == BILineType.LineTypeHardNonConus.rawValue && line.isETOPS?.intValue == 0{
                        line.type = BILineType.LineTypeNonEtopsNonConUs.rawValue as NSNumber
                    }
                    if (self.bidPeriod?.isFirstRoundBid())! && line.isETOPS?.intValue == 1{
                        line.type = BILineType.LineTypeEtopsFAFirstRound.rawValue as NSNumber
                    }
                }

            }
            
            self.initDerivedPropertiesForLine(line: line!, isReprocessing: false)
            if success && moc.hasChanges {
                do{
                    try moc.save()
                }catch{
                    //handle error
                    print("Error saving line: \(error.localizedDescription)")
                    success = false
                }
            }
            self.saveToDictionary(context: moc)
        }catch{
            print("Error reading line file: \(error.localizedDescription)")
            success = false
        }
        return success
    }

    private func saveToDictionary(context:NSManagedObjectContext){
        
        var linesDictionary:[NSNumber: [String: Any]] = [:]
        for case let line as BILine in (self.bidPeriod?.lines)!{
            var dataDictionary:[String:Any] = [:]
            let entityName = line.entity.name ?? ""
            if let entityDescription = NSEntityDescription.entity(forEntityName: entityName, in: context){
                let attributes = entityDescription.attributesByName
                for key in attributes.keys{
                    if let value = line.value(forKey: key){
                        dataDictionary[key] = value
                    }
                }
                linesDictionary[line.number!] = dataDictionary
            }
        }
        let userdata: Data?
        do {
            userdata = try NSKeyedArchiver.archivedData(withRootObject: linesDictionary, requiringSecureCoding: false)
        } catch {
            print("Archiving failed: \(error)")
            userdata = nil
        }
        self.bidPeriod?.baseLine = userdata as? NSData
        if context.hasChanges{
            do{
                try context.save()
            }catch{
                print("Error saving context: \(error)")
            }
        }
    }
    
    func initDerivedPropertiesForLine(line:BILine, isReprocessing:Bool){
        calendarData = calendarData.initWithBidPeriod(bidPeriod: self.bidPeriod!)!
        self.thanksgivingDay = CBUtils.thanksgivingDay(for: self.bidPeriod?.year?.intValue ?? 2025)
        if isReprocessing{
            line.vTpLPay = NSNumber(value: (line.lineRig?.floatValue ?? 0) + (line.vVacationPay?.floatValue ?? 0))
            if self.includeDroppedTrips!{
                line.pay = line.actualPay
                line.tripTfp = line.actualPay
                line.blockMinutes = line.actualBlockMinutes
                line.vTpLPay = line.lineRig
            }else if line.vTpLPay!.intValue > 0{
                if (self.bidPeriod?.vacations!.count)! > 0{
                    line.pay = line.vTotalPay
                    line.tripTfp = line.vFlyPay
                }
            }
        }
        
        line.holidayPay = 0
        line.vHolidayPay = 0
        line.coHoli = 0
        line.isFA31thLineVacationCalculated = false
        line.isFA25thLineVacationCalculated = false
        let moc = dataSource.managedObjectContext
        let amExpression = NSExpression(format: "SUBQUERY(trips, $TRIP, $TRIP.info.amPM == 1).@count")
        let amTripsCount = amExpression.expressionValue(with: line, context: nil) as? NSNumber
        let pmExpression = NSExpression(format: "SUBQUERY(trips, $TRIP, $TRIP.info.amPM == 2).@count")
        let pmTripsCount = pmExpression.expressionValue(with: line, context: nil) as? NSNumber
        
        //AM/PM
        if line.trips?.count == 0{
            line.amPM = BILineAMPM.BlankAMPMLine.rawValue as NSNumber
        }else{
            if line.trips?.count == amTripsCount?.intValue{
                line.amPM = BILineAMPM.AMLine.rawValue as NSNumber
            }else if line.trips?.count == pmTripsCount?.intValue{
                line.amPM = BILineAMPM.PMLine.rawValue as NSNumber
            }else{
                line.amPM = BILineAMPM.MixedAMPMLine.rawValue as NSNumber
            }
        }
        // Add rig values to the line pay value
        if !(self.bidPeriod?.isFABid())!{
            var minRig = 0.0
            switch self.bidPeriod?.month?.intValue{
            case 2: minRig = 84.0
                break
            case 4,6,9,11: minRig = 87.0
                break
            default: minRig = 89.0
                break
            }
            let ETC = CBExceedingTripCalculation()
            let minRigVal = ETC.calculateExceedingTripRig(line: line, calendarData: self.calendarData, minRig: Float(minRig))
            if line.pay!.doubleValue < minRig{
                if !isReprocessing{
                    line.lineRig = NSNumber(value: minRigVal - line.pay!.floatValue)
                    line.pay = minRigVal as NSNumber
                    line.vTpLPay = NSNumber(value: (line.lineRig!.floatValue) + (line.vVacationPay!.floatValue))
                    
                }else{
                    if self.includeDroppedTrips!{
                        line.lineRig = NSNumber(value: minRigVal - line.actualPay!.floatValue)
                        line.pay = minRigVal as NSNumber
                        line.vTpLPay = NSNumber(value: line.lineRig!.floatValue + line.vVacationPay!.floatValue)
                    }
                }
            }
        }else{
            let minRigVal:Float = 0
            self.calculateFARigValue(minRigVal: minRigVal, line: line, reprocessing: isReprocessing)
            if line.faReserveLineType!.intValue > 0{
                self.calculateFAReserveRigValue(minRigVal: minRigVal, line: line, reprocessing: isReprocessing)
            }
        }
        
        //Week day and month bits
        if self.dateComponents == nil{
            self.dateComponents = DateComponents()
            self.dateComponents?.year = self.bidPeriod?.year?.intValue
            self.dateComponents?.month = self.bidPeriod?.month?.intValue
            self.dateComponents?.hour = 12
        }
        var weekdayBits: UInt = 0
        var monthBits: UInt64 = 0
        var tripStartMonthBits: UInt64 = 0
        var tripEndMonthBits: UInt64 = 0
        var weekdays = [Int](repeating: 0, count: 7)
        for i in 0..<7{
            weekdays[i] = 0
        }
        let numDaysInBidMonth = CBUtils.numberOfDays(inMonth: (self.dateComponents?.month)!, forYear: (self.dateComponents?.year)!)
        var numAircraftChanges = 0
        var numLegs = 0
        var numReserveDays = 0
        var tripNumLegs = 0
        var maxLegsInADay = 0
        var numWorkDays = 0
        var lineTafbMinutes = 0
        var commutesRequired = 0
        var passesThruBase = 0
        var midTripPTBs = 0
        var overnightsInBase = 0
        var aircraftType8MaxCount = 0
        var aircraftType7MaxCount = 0
        var aircraftType800Count = 0
        var aircraftType700Count = 0
        var etopsTripsCount = 0
        var earliestDepartureTime = 2400
        var latestArrivalTime = 0
        var dutyMinutes = 0
        var dayNumLegs = 0
        var vacationBlockMinutes = 0
        var lineBlockMinutes = 0
        var deadheadsCount = 0
        var deadheadsAtStartCount = 0
        var deadheadsAtEndCount = 0
        var overlapDaysCount = 0
        let minimumOvernightMinsPlaceholder = 1_000_000
        var minimumOvernightMinutes = minimumOvernightMinsPlaceholder
        var maximumOvernightMinutes = 0
        var redeyesCount = 0
        var faPay: Float = 0
        let base = self.bidPeriod!.base
        var tripStartDates: [Date] = []
        var tripEndDates: [Date] = []
        var df = DateFormatter()
        let appCal = self.calendarData.bidPeriodCalendar()
        var dayComponent = DateComponents()
        var faPosition = BIFaPosition.FaPositionNA
        var isFirstTrip = true
        var faPosIsMultiple = false
        var containsNonConUSLeg = false
        var nonConUSLegs = 0
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US")
        calendar.timeZone = TimeZone(identifier: "US/Central")!
        var departDateReport:Date?
        var report = ""
        var release = ""
        var departFormatter = DateFormatter()
        departFormatter.dateFormat = "HHmm"
        var arriveFormatter = DateFormatter()
        arriveFormatter.dateFormat = "HHmm"
        
        for case let trip as BITrip in line.trips!{
            // Figure out the FA position of the line (A,B,C,D,M,NA)
            if bidPeriod!.isFABid() {
                if !faPosIsMultiple {
                    if let tripPosRaw = trip.position?.intValue {
                        let tripPos = BIFaPosition(rawValue: tripPosRaw)
                        
                        if let tripPos = tripPos {
                            if isFirstTrip {
                                faPosition = tripPos
                                isFirstTrip = false
                            }

                            if faPosition != tripPos {
                                faPosition = .FaPositionMultiple
                                faPosIsMultiple = true
                            } else {
                                faPosition = tripPos
                            }
                        }
                    }
                }
            }
            var tripNumLegs = 0
            
            // Don't include the trip in any of the line calculations if it is dropped.
            // AND if the user doesn't want to include them in the calculation
            if isReprocessing && trip.vacationOverlapType?.intValue != 0{
                if self.includeDroppedTrips!{
                    trip.dropForFiltersSorts = false
                }else{
                    trip.dropForFiltersSorts = true
                    continue
                }
            }
            let startDay = trip.startDay?.intValue
            let tripLength = trip.info?.calendarDaysCount?.intValue
            
            tripStartDates.append(trip.startDate!)
            
            dayComponent.day = tripLength! - 1 // Weekday calculation below relies on this.
            tripEndDates.append(appCal!.date(byAdding: dayComponent, to: trip.startDate!)!)
            df.dateFormat = "ddMMMyy"
            var dateComps = DateComponents()
            dateComps.year = trip.line?.bidPeriod?.year?.intValue
            dateComps.month = trip.line?.bidPeriod?.month?.intValue
            dateComps.day = trip.startDay?.intValue
            
            // Calculate the trip startWeekday and trip endWeekday for the commuting filter
            let endWeekDay = tripEndDates.last
            let startWeekdayComps = appCal!.component(.weekday, from: trip.startDate!)
            trip.startWeekday = startWeekdayComps as NSNumber
            
            let endWeekDayComps = appCal!.component(.weekday, from: endWeekDay!)
            trip.endWeekday = endWeekDayComps as NSNumber
            df.dateFormat = "ddMMM"
            let tf = DateFormatter()
            tf.dateFormat = "HHmm"
            
            var departDate: Date?
            var arriveDate: Date?
            var blockMinutes = 0
            var groundMinutes = 0
            var dayBlockMinutes = 0
            var dayDutyMinutes = 0
            var tripBlockMinutes = 0
            var tripDutyMinutes = 0
            var containsMidTripPTB = false
            let tripOrderedDays = trip.info!.orderedDays
            var dayCount = 0
            var monthBitIndex = self.calendarData.indexForDate(date:trip.startDate!)
            
            var dateCompsReport = calendar.dateComponents([.year, .month, .day], from: trip.startDate!)
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .decimal
            for case let dayInfo as BIDayInfo in tripOrderedDays{
                if trip.isReserve {
                    numReserveDays += 1
                }
                let dayOrderedLegs = dayInfo.orderedLegs
                
                //block time, duty time and pay
                if tripOrderedDays.first as? BIDayInfo === dayInfo {
                    dateCompsReport.minute = (dayOrderedLegs.first as? BILegInfo)?.departMinutes?.intValue ?? 0 - (trip.info!.briefMinutes?.intValue ?? 0)
                }else{
                    dateCompsReport.minute = (dayOrderedLegs.first as? BILegInfo)?.departMinutes?.intValue ?? 0 - (trip.info!.debriefMinutes?.intValue ?? 0)
                }
                departFormatter.timeZone = TimeZone(identifier: "US/Central")
                departDateReport = calendar.date(from: dateCompsReport)!
                report = String(format: "%@", departFormatter.string(from: departDateReport!))
                if (trip.info?.number?.character(at: 1))! >= "W"{
                    if !(self.bidPeriod?.isFABid())!{
                        report = String(format: "%04d", (trip.info?.departTime!.intValue)!)
                    }
                }
                if report.length > 0{
                    dayInfo.reportTime = numberFormatter.number(from: report)
                }
                arriveFormatter.timeZone = TimeZone(identifier: "US/Central")
                dateCompsReport.minute = (dayOrderedLegs.last as? BILegInfo)?.arriveMinutes?.intValue ?? 0 + (trip.info!.debriefMinutes?.intValue ?? 0)
                arriveDate = calendar.date(from: dateCompsReport)!
                release = String(format: "%@", arriveFormatter.string(from: arriveDate!))
                if (trip.info?.number?.character(at: 1))! >= "W"{
                    if !(self.bidPeriod?.isFABid())!{
                        release = String(format: "%04d", (trip.info?.returnTime!.intValue)!)
                    }
                }
                if release.length > 0{
                    dayInfo.releaseTime = numberFormatter.number(from: release)
                }
                var day:BIDay? = nil
                if !isReprocessing{
                    day = BIDay(context: moc)
                    day?.info = dayInfo
                    day?.line = line
                    day?.trip = trip
                }else{
                    if trip.orderedDays.count > dayCount{
                        day = trip.orderedDays[dayCount]
                    }else{
                        day = BIDay(context: moc)
                    }
                }
                dayBlockMinutes = 0
                dayNumLegs = 0
                
                for case let legInfo as BILegInfo in dayOrderedLegs{
                    var leg:BILeg? = nil
                    if !isReprocessing{
                        leg = BILeg(context: moc)
                        leg?.info = legInfo
                        leg?.day = day
                        leg?.trip = trip
                        leg?.line = line
                        let hawaiiCities = UserDefaults.standard.array(forKey: kCBHawaiiCitiesList) as? [String] ?? []
                        if hawaiiCities.contains((leg?.info?.departCity)!){
                            trip.info?.isETOPS = true
                        }
                    }
                    // More derived values
                    // Line number of legs
                    if !trip.isReserve{
                        numLegs += 1
                    }
                    // Deadhead
                    if legInfo.isDeadhead!.boolValue{
                        deadheadsCount += 1
                    }
                    // Day num legs
                    dayNumLegs += 1
                    // Passes through base
                    let arriveCity = legInfo.arriveCity
                    
                    if !(line.type?.intValue == BILineType.ReserveLineType.rawValue) && arriveCity == base{
                        passesThruBase += 1
                        if dayCount > 0 && dayCount < (tripOrderedDays.count - 1){
                            midTripPTBs += 1
                            containsMidTripPTB = true
                        }
                    }
                    // NonConus Leg
                    // International cities currently includes NonConus Cities as well.
                    // Check to see if the base exists in the InternationalCitiesDict
                    // If the base exists, then it's an itnernational city
                    let isIntlCity = self.intlCities[arriveCity!]
                    if isIntlCity != nil{
                        containsNonConUSLeg = true
                        nonConUSLegs += 1
                        if self.bidPeriod!.isFirstRoundBid(){
                            line.type = BILineType.LineTypeHardNonConus.rawValue as NSNumber
                            if line.isETOPS?.intValue == 0 && ((self.bidPeriod?.isEtopsLinesContainsInBid) != nil){
                                line.type = BILineType.LineTypeNonEtopsNonConUs.rawValue as NSNumber
                            }
                        }
                        if self.bidPeriod!.isSecondRoundBid(){
                            if self.bidPeriod!.isFABid(){
                                line.type = BILineType.LineTypeHardNonConus.rawValue as NSNumber
                                if line.isETOPS?.intValue == 0 && ((self.bidPeriod?.isEtopsLinesContainsInBid) != nil){
                                    line.type = BILineType.LineTypeNonEtopsNonConUs.rawValue as NSNumber
                                }
                            }
                        }
                        if self.bidPeriod?.isEtopsLinesContainsInBid?.intValue == 1 && !self.bidPeriod!.isFABid(){
                            if line.type?.intValue == BILineType.LineTypeHardNonConus.rawValue && line.isETOPS?.intValue == 0 &&
                                ((self.bidPeriod?.isEtopsLinesContainsInBid) != nil) {
                                line.type = BILineType.LineTypeNonEtopsNonConUs.rawValue as NSNumber
                                }
                            }
                        }
                        // Duty time calculation
                        // Leg is reserve if depart and arrive cities are the same.
                    let isReserveLeg = legInfo.departCity == legInfo.arriveCity
                    let isDeadHeadLeg = legInfo.isDeadhead!.boolValue
                    // Reserve legs have block of 1 hour from bid info data, but should
                    // have 0 block when displayed. Deadhead legs have 0 block as
                    // parsed from bid info, but set to 0 here and also to set block
                    // time string.
                    if isReserveLeg || isDeadHeadLeg {
                        blockMinutes = 0
                    }
                    // Otherwise block the value for the leg.
                    else{
                        blockMinutes = legInfo.blockMinutes.intValue
                    }
                    dateComps.minute = legInfo.departMinutes?.intValue
                    departDate = appCal!.date(from: dateComps)
                    dateComps.minute = legInfo.arriveMinutes?.intValue
                    arriveDate = appCal!.date(from: dateComps)
                    // Ground time.
                    groundMinutes = legInfo.groundMinutes.intValue
                    dayBlockMinutes += blockMinutes
                    
                    // Aircraft changes
                    if legInfo.isAircraftChange!.boolValue {
                        numAircraftChanges += 1
                    }
                    if legInfo.equipment == "7"{
                        aircraftType700Count += 1
                    }
                    if legInfo.equipment == "8"{
                        aircraftType800Count += 1
                    }
                    if legInfo.equipment == "6"{
                        aircraftType8MaxCount += 1
                    }
                    if legInfo.equipment == "2" {
                        aircraftType7MaxCount += 1
                    }
                }// END leg loop
                
                if !dayOrderedLegs.isEmpty {
                    if tripOrderedDays.first as? BIDayInfo === dayInfo {
                        dateComps.minute = (dayOrderedLegs.first as? BILegInfo)?.departMinutes?.intValue ?? 0 - (trip.info!.briefMinutes?.intValue ?? 0)
                    }
                    else{
                        dateComps.minute = (dayOrderedLegs.first as? BILegInfo)?.departMinutes?.intValue ?? 0 - (trip.info!.debriefMinutes?.intValue ?? 0)
                        }
                    departDate = appCal!.date(from: dateComps)
                    dateComps.minute = (dayOrderedLegs.last as? BILegInfo)?.arriveMinutes?.intValue ?? 0 + (trip.info!.debriefMinutes?.intValue ?? 0)
                    arriveDate = appCal!.date(from: dateComps)
                    
                    if tripOrderedDays.last as? BIDayInfo !== dayInfo {
                        groundMinutes -= 2 * (trip.info?.debriefMinutes!.intValue)!
                    }
                    
                    dayDutyMinutes = appCal!.dateComponents([.minute], from: departDate!, to: arriveDate!).minute!
                    if trip.isReserve && self.bidPeriod!.isFABid() && self.bidPeriod!.isSecondRoundBid(){
                        dayDutyMinutes = 60
                    }
                    tripBlockMinutes += dayBlockMinutes
                    tripDutyMinutes += dayDutyMinutes
                    day?.info?.dutyMinutes = dayDutyMinutes as NSNumber
                    day?.info?.blockMinutes = dayBlockMinutes as NSNumber
                }
                dayComponent.day = dayCount
                let date = appCal!.date(byAdding: dayComponent, to: trip.startDate!)
                day?.date = date
                
                var weekday = appCal!.component(.weekday, from: date!)
                weekday -= 1
                weekdayBits |= 1 << weekday
                weekdays[weekday] += 1
                
                if trip.isRedEyeTrip {
                    if trip.info?.calendarDaysCount != NSNumber(value: trip.info!.orderedDays.count){
                        let missingDateIndex =  CBUtils.findMissingIndex(inRedEyeTrip: trip)
                        let missingDate = CBUtils.findMissingDate(forRedEyeTrip: trip)
                        let calendar = Calendar.current
                        let date1 = calendar.startOfDay(for: (day?.date)!)
                        let date2 = calendar.startOfDay(for: missingDate!)
                        
                        let result = date1.compare(date2)
                        
                        if result == .orderedSame && missingDateIndex == dayCount && missingDateIndex != trip.info?.orderedDays.count{
                            dayComponent.day = dayCount + 1
                            let date = appCal!.date(byAdding: dayComponent, to: trip.startDate!)
                            day?.date = date
                            
                            var weekdayRedEye = appCal!.component(.weekday, from: date!)
                            weekdayRedEye -= 1
                            weekdayBits |= 1 << weekdayRedEye
                            weekdays[weekdayRedEye] += 1
                        }else{
                            var weekdayRedEye = appCal!.component(.weekday, from: missingDate!)
                            weekdayRedEye -= 1
                            weekdayBits |= 1 << weekdayRedEye
                            weekdays[weekdayRedEye] += 1
                        }
                    }else{
                        for case let legInfo as BILegInfo in (day?.info?.orderedLegs)!{
                            if legInfo.isRedEyeFlight == true{
                                let missingDateIndex = CBUtils.findMissingIndex(inRedEyeTrip: trip)
                                if missingDateIndex != -1 {
                                    dayComponent.day = dayCount + 1
                                }
                                let date = appCal!.date(byAdding: dayComponent, to: trip.startDate!)
                                day!.date = date
                                
                                var weekdayRedEye = appCal!.component(.weekday, from: date!)
                                weekdayRedEye -= 1
                                weekdayBits |= 1 << weekdayRedEye
                                weekdays[weekdayRedEye] += 1
                                break
                            }
                        }
                    }
                }
                
                // Month bits
                let one:UInt64 = 1
                monthBits |= one << (monthBitIndex + dayCount)
                
                if dayCount == 0{
                    tripStartMonthBits |= one << (monthBitIndex + dayCount)
                    trip.info?.firstDay = dayInfo
                    dayInfo.firstLeg = dayInfo.orderedLegs.first as? BILegInfo
                }
                if dayCount == (trip.info?.orderedDays.count)! - 1{
                    tripEndMonthBits |= one << (monthBitIndex + dayCount)
                }
                // Max legs in a day
                if dayNumLegs > maxLegsInADay{
                    maxLegsInADay = dayNumLegs
                }
                dayCount += 1
                
                // Minimum and maximum overnight times
                
                let legInfo = dayInfo.orderedLegs.last as? BILegInfo
                var groundMins = legInfo!.groundMinutes.intValue
                if groundMins > 0 {
                    groundMins -= (2 * (trip.info?.debriefMinutes!.intValue)!)
                    if groundMins < minimumOvernightMinutes{
                        minimumOvernightMinutes = groundMins
                    }
                    if groundMins > maximumOvernightMinutes{
                        maximumOvernightMinutes = groundMins
                    }
                }
                tripNumLegs += dayNumLegs
            }// END Day loop
            
            if passesThruBase != 0{
                passesThruBase -= 1 // Subtract 1 for last leg ending in the base
            }
            numWorkDays += tripLength!
            lineTafbMinutes += (trip.info?.tafbMinutes!.intValue)!
            
            overnightsInBase += trip.info!.overnightsInBase!.intValue
            // Earliest Departure
            let tripDepartTime = trip.info!.departTime!.intValue
            if tripDepartTime < earliestDepartureTime{
                earliestDepartureTime = tripDepartTime
            }
            // Latest Arrival
            var tripReturnTime = trip.info!.returnTime!.intValue
            if tripReturnTime < 400 {
                tripReturnTime += 2400 // Account for trips landing before 2am the next day
            }
            if tripReturnTime > latestArrivalTime{
                latestArrivalTime = tripReturnTime
            }
            // Check for deadheads at start and end
            
            var dayInfo = tripOrderedDays.first as? BIDayInfo
            var legInfo = dayInfo?.orderedLegs.first as? BILegInfo
            legInfo?.firstLegOfTrip = true
            
            if legInfo!.isDeadhead!.boolValue{
                deadheadsAtStartCount += 1
                if !dhStartCities.contains((legInfo?.arriveCity)!){
                    let startCity = BIDeadheadAtStartCity(context: moc)
                    startCity.city = legInfo?.arriveCity
                    startCity.bidPeriod = self.bidPeriod
                    dhStartCities.append((legInfo?.arriveCity)!)
                }
            }
            dayInfo = tripOrderedDays.last as? BIDayInfo
            legInfo = dayInfo?.orderedLegs.last as? BILegInfo
            legInfo?.lastLegOfTrip = true
            
            if legInfo!.isDeadhead!.boolValue{
                deadheadsAtEndCount += 1
                if !dhEndCities.contains((legInfo?.departCity)!){
                    let endCity = BIDeadheadAtEndCity(context: moc)
                    endCity.city = legInfo?.departCity
                    endCity.bidPeriod = self.bidPeriod
                    dhEndCities.append((legInfo?.departCity)!)
                }
            }
            // MidTripPTB
            trip.info?.containsMidTripPTB = containsMidTripPTB as NSNumber
            
            //Fullycommutable or not set default value
            trip.info?.isFullyCommutable = false
            
            // Overlap
            // Check for overlap into the next month
            if(startDay! + tripLength! - 1) > numDaysInBidMonth{
                overlapDaysCount += (startDay! + tripLength! - 1 - numDaysInBidMonth)
            }
            
            //FAPay
            if self.isFABid(){
                faPay += (trip.info?.faPay!.floatValue)!
            }
            
            trip.info?.numLegs = tripNumLegs as NSNumber
            
            trip.info?.blockMinutes = tripBlockMinutes as NSNumber
            trip.info?.dutyMinutes = tripDutyMinutes as NSNumber
            
            lineBlockMinutes += tripBlockMinutes
            dutyMinutes += tripDutyMinutes
            
            if trip.vacationOverlapType?.intValue == 0{
                vacationBlockMinutes += tripBlockMinutes
            }
            if trip.info!.isETOPS!.boolValue{
                etopsTripsCount += 1
            }
        }// END trip loop
        
        if self.bidPeriod?.month?.intValue == 12{
            let vacationEnabled = self.bidPeriod?.userVacationWbidOrCrewBid
            if vacationEnabled == "" || vacationEnabled == nil{
                line.pay = line.pay!.floatValue + line.holidayPay!.floatValue as NSNumber
            }
        }
        // Check to make sure the minimum overnight mins was overwritten
        // If it wasn't that means the line is all turns, so overwrite to 0
        if minimumOvernightMinutes == minimumOvernightMinsPlaceholder{
            minimumOvernightMinutes = 0
        }
        // Calculate the blockOfDaysOff and add OIBs due to back to back trips
        var blockOfDaysOff = 0
        let undroppedTrips = line.trips?.filtered(using: NSPredicate(format: "vacationOverlapType == 0"))
        
        // Make sure it's not a blank line or a line with no trips
        if let trips = line.trips as? Set<BITrip>, !trips.isEmpty,
           let undropped = undroppedTrips, !undropped.isEmpty {
            tripStartDates = tripStartDates.sorted()
            tripEndDates = tripEndDates.sorted()
            var daysDiff = 0
            if let firstDate = tripStartDates.first{
                blockOfDaysOff = self.calendarData.noOfDaysBetweenDates(startDate: self.calendarData.firstDateOfMonth, endDate: firstDate)
            }
            for j in 0..<tripStartDates.count - 1 {
                autoreleasepool {
                    let startOff = tripEndDates[j]
                    let endOff = tripStartDates[j + 1]
                    
                    let daysDiff = (calendarData.daysBetweenDate(fromDateTime: startOff, toDateTime: endOff)) - 1
                    
                    if daysDiff == 0 {
                        overnightsInBase += 1
                    }
                    
                    if daysDiff > blockOfDaysOff {
                        blockOfDaysOff = daysDiff
                    }
                }
            }
            let lastDate = tripEndDates.last!
            let lastDayOfBidMonth = self.calendarData.dateForDayOfMonth(dayOfMonth:numDaysInBidMonth)
            daysDiff = (self.calendarData.daysBetweenDate(fromDateTime:lastDate, toDateTime:lastDayOfBidMonth!))
            if daysDiff > blockOfDaysOff{
                blockOfDaysOff = daysDiff
            }
        }
            line.blockOfDaysOff = blockOfDaysOff as NSNumber
            line.maxLegsInADay = maxLegsInADay as NSNumber
            line.numAircraftChanges = numAircraftChanges as NSNumber
            line.numLegs = numLegs as NSNumber
            line.workDays = numWorkDays as NSNumber
            line.reserveDays = numReserveDays as NSNumber
            if undroppedTrips!.isEmpty{
                line.blockOfDaysOff = NSNumber(value: self.calendarData.daysInMonth)
            }
            
            if self.bidPeriod!.isFABid(){
                if self.bidPeriod?.month?.intValue == 2{
                    //Get last tripDate
                    let lastDate = tripEndDates.last!
                    //Get last day of month
                    let lastDayOfBidMonth = self.calendarData.dateForDayOfMonth(dayOfMonth:numDaysInBidMonth)
                    //Number of days between last trip date and last day of month
                    let lastDay = self.calendarData.daysBetweenDate(fromDateTime:lastDate, toDateTime: lastDayOfBidMonth!)
                    
                    let firstDate = tripStartDates.first!
                    //Number of days between first trip date and first day of month
                    let firstDay = self.calendarData.daysBetweenDate(fromDateTime:self.calendarData.firstDateOfMonth!, toDateTime: firstDate)
                    
                    //calculating number of trip beyound month
                    var numberOfTripBeyondMonth = 0
                    if lastDay >= 0 {
                        numberOfTripBeyondMonth = -lastDay
                    }
                    if firstDay > 0 {
                        numberOfTripBeyondMonth += 1
                    }
                    
                    // number of working days in month excluding trip that beyound month
                    let tempWorkDays = numWorkDays - numberOfTripBeyondMonth
                    
                    //Check Jan 31 and 1March is day off
                    var FAFirstandLastCount = 0
                    if lastDay >= 0 {
                        FAFirstandLastCount = 1
                    }
                    if firstDay >= 0 {
                        FAFirstandLastCount += 1
                    }
                    //Total days off
                    let totalDaysOff = numDaysInBidMonth - tempWorkDays + FAFirstandLastCount
                    line.daysOff = totalDaysOff as NSNumber
                }
                else if self.bidPeriod?.month?.intValue == 3{
                    line.daysOff = numDaysInBidMonth - (numWorkDays - overlapDaysCount) as NSNumber
                    line.daysOff = (line.daysOff!.intValue - 1) as NSNumber
                }
                else{
                    line.daysOff = numDaysInBidMonth - (numWorkDays - overlapDaysCount) as NSNumber
                }
                
            }
            else{
                line.daysOff = numDaysInBidMonth - (numWorkDays - overlapDaysCount) as NSNumber
            }
            
            // For blank lines linerig is zero
            if line.type?.intValue == BILineType.BlankLineType.rawValue{
                line.lineRig = 0
                line.vTpLPay = line.lineRig!.floatValue + line.vVacationPay!.floatValue as NSNumber
            }
            if isReprocessing{
                if !self.includeDroppedTrips!{
                    //Change the blockminiutes while applying vacation.
                    let blockMin = Int(roundf(line.vBlockTime!.floatValue * 60))
                    line.blockMinutes = blockMin as NSNumber
                    line.blockHours = line.blockMinutes!.floatValue / 60 as NSNumber
                }
                else{
                    // set actual blockminutes while removing the vacation.
                    line.blockMinutes = line.actualBlockMinutes
                    line.blockHours = line.blockMinutes!.floatValue / 60 as NSNumber
                }
            }
            
            // calculating workDays BP
            self.getWorkDaysBPInBidPeriodFromTrip(line: line, isReprocessing: isReprocessing)
            line.tafbMinutes = lineTafbMinutes as NSNumber
            line.commutesRequired = commutesRequired as NSNumber
            line.etopsTripsCount = etopsTripsCount as NSNumber
            line.passesThruBase = passesThruBase as NSNumber
            line.overnightsInBase = overnightsInBase as NSNumber
            line.aircraftType700Count = aircraftType700Count as NSNumber
            line.aircraftType800Count = aircraftType800Count as NSNumber
            line.aircraftType7MaxCount = aircraftType7MaxCount as NSNumber
            line.aircraftType8MaxCount = aircraftType8MaxCount as NSNumber
            line.earliestDepartureTime = earliestDepartureTime as NSNumber
            line.latestArrivalTime = latestArrivalTime as NSNumber
            line.dutyMinutes = dutyMinutes as NSNumber
            line.blockHours = line.blockMinutes!.floatValue / 60 as NSNumber
            line.dutyHours = line.dutyMinutes!.floatValue / 60 as NSNumber
            line.tafbHours = line.tafbMinutes!.floatValue / 60 as NSNumber
            line.deadheadsCount = deadheadsCount as NSNumber
            line.deadheadsAtStartCount = deadheadsAtStartCount as NSNumber
            line.deadheadsAtEndCount = deadheadsAtEndCount as NSNumber
            line.deadheadsAtEitherCount = deadheadsAtStartCount + deadheadsAtEndCount as NSNumber
            line.overlapDaysCount = overlapDaysCount as NSNumber
            line.faPosition = faPosition.rawValue as NSNumber
            line.minimumOvernightHours = Float(minimumOvernightMinutes / 60) as NSNumber
            line.maximumOvernightHours = Float(maximumOvernightMinutes / 60) as NSNumber
            line.containsNonConusLeg = containsNonConUSLeg as NSNumber
            line.nonConusLegsCount = nonConUSLegs as NSNumber
            line.monthBits = monthBits as NSNumber
            line.tripStartMonthBits = tripStartMonthBits as NSNumber
            line.tripEndMonthBits = tripEndMonthBits as NSNumber
            line.redeyes = redeyesCount as NSNumber
            line.redEyeTrips = redeyesCount as NSNumber
            
            line.weekdayBits = weekdayBits as NSNumber
            line.sundaysCount = weekdays[0] as NSNumber
            line.mondaysCount = weekdays[1] as NSNumber
            line.tuesdaysCount = weekdays[2] as NSNumber
            line.wednesdaysCount = weekdays[3] as NSNumber
            line.thursdaysCount = weekdays[4] as NSNumber
            line.fridaysCount = weekdays[5] as NSNumber
            line.saturdaysCount = weekdays[6] as NSNumber
            line.weekendsCount = weekdays[0] + weekdays[6] as NSNumber
            
            line.rptLessThanentered = false
            line.rlsGreaterThanEntered = false
            
            line.flagOrder = 8
            
            if isFA{
                var FAPosition:String
                switch line.faPosition?.intValue {
                case 1:FAPosition = "A"
                case 2:FAPosition = "B"
                case 3:FAPosition = "C"
                case 4:FAPosition = "D"
                default:FAPosition = ""
                }
                line.faNumber = String(format: "%@%@", line.number!,FAPosition)
            }
            
            // ***** Trip Lengths *****
            let expressionFormat = "SUBQUERY(trips, $TRIP, $TRIP.info.calendarDaysCount == %@ && $TRIP.dropForFiltersSorts == NO).@count"
            
            for tripLength in 1...4{
                let tripLengthCountExpression = NSExpression(format: expressionFormat, argumentArray: [tripLength])
                switch tripLength{
                case 1: line.turnsCount = tripLengthCountExpression.expressionValue(with: line, context: nil) as? NSNumber
                    break
                case 2: line.twoDayTripsCount = tripLengthCountExpression.expressionValue(with: line, context: nil) as? NSNumber
                    break
                case 3: line.threeDayTripsCount = tripLengthCountExpression.expressionValue(with: line, context: nil) as? NSNumber
                    break
                case 4: line.fourDayTripsCount = tripLengthCountExpression.expressionValue(with: line, context: nil) as? NSNumber
                    break
                default: break
                }
            }
            
            let fmt = NumberFormatter()
            fmt.positiveFormat = "0.##"

            let f = NumberFormatter()
            f.numberStyle = .decimal
            
            line.numTrips = (line.turnsCount!.intValue + line.twoDayTripsCount!.intValue + line.threeDayTripsCount!.intValue + line.fourDayTripsCount!.intValue) as NSNumber
        self.initRigRelatedProperties(forLine: line, isReprocessing: isReprocessing)
        self.calculateNewProperties(forLine: line)
        self.updateEndDateForRedEyeTrips(forLine: line)
    }
    
    private func initRigRelatedProperties(forLine:BILine, isReprocessing:Bool){
        
    }
    
    private func calculateNewProperties(forLine:BILine){
        
    }
    
    private func updateEndDateForRedEyeTrips(forLine:BILine){
        
    }
    
    private func getWorkDaysBPInBidPeriodFromTrip(line: BILine, isReprocessing: Bool) {
            for trip in line.trips as? Set<BITrip> ?? [] {
                let bpStartDate = self.startOfMonth()
                let bpEndDate = self.endOfMonth()
                
                for i in 0..<trip.orderedDays.count {
                    let daysArray = trip.days?.allObjects
                    let day = daysArray![i] as? BIDay
                    var dayDate = day?.date
                    
                    if (trip.isRedEyeTrip == true && (trip.info?.calendarDaysCount as? Int == trip.orderedDays.count)) {
                        let dutyDates = self.datesOnlyArrayFromTrip(trip: trip)
                        if (dutyDates.count == trip.orderedDays.count) {
                            dayDate = dutyDates[i]
                        }
                    }
                    var calendar = Calendar(identifier: .gregorian)
                    calendar.locale = Locale.current
                    calendar.timeZone = TimeZone(identifier: "GMT")!
                    var dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: dayDate!)
                    
                    dateComponents.hour = 0
                    dateComponents.minute = 0
                    dateComponents.second = 0
                    
                    let tripDayDate = calendar.date(from: dateComponents)
                    let resultStart = tripDayDate!.compare(bpStartDate!)
                    let resultEnd = tripDayDate!.compare(bpEndDate!)
                    
                    if (self.bidPeriod?.isFABid() == true) {
                        if let swaptimizerStatus = self.bidPeriod?.swaptimizerStatus?.intValue,
                           let faVacationStatus = self.bidPeriod?.faVacationStatus?.intValue,
                           let overlapType = trip.vacationOverlapType?.intValue,
                           let displayType = day?.displayType?.intValue,
                           (swaptimizerStatus == CBSwaptimizerStatus.enabled.rawValue ||
                            faVacationStatus == BIFaVacationStatus.enabled.rawValue),
                           overlapType > 0,
                           displayType != BIDayDisplayType.normal.rawValue {
                            if (resultStart == .orderedDescending && resultEnd == .orderedAscending) {
                                workBPInVac += 1
                            }
                            else if (resultStart == .orderedSame && resultEnd == .orderedSame) {
                                workBPInVac += 1
                            }
                        }
                    }
                    else {
                        if let swaptimizerStatus = self.bidPeriod?.swaptimizerStatus?.intValue,
                           let overlapType = trip.vacationOverlapType?.intValue,
                           let displayType = day?.displayType?.intValue,
                           (swaptimizerStatus == CBSwaptimizerStatus.enabled.rawValue),
                           overlapType > 0,
                           displayType != BIDayDisplayType.normal.rawValue {
                            if (resultStart == .orderedDescending && resultEnd == .orderedAscending) {
                                workBPInVac += 1
                            }
                            else if (resultStart == .orderedSame && resultEnd == .orderedSame) {
                                workBPInVac += 1
                            }
                        }
                    }
                    if (resultStart == .orderedDescending && resultEnd == .orderedAscending) {
                        workBP += 1
                    }
                    else if (resultStart == .orderedSame && resultEnd == .orderedSame) {
                        workBP += 1
                    }
                }
            }
            
            // Handling Work days for RedEye Trips
            var redEyeDays = 0
            var redEyeDaysInVac = 0
            
            for trip in line.trips as? Set<BITrip> ?? [] {
                if (trip.isRedEyeTrip == true) {
                    let bpStartDate = self.startOfMonth()
                    let bpEndDate = self.endOfMonth()
                    
                    if trip.info?.calendarDaysCount?.intValue != trip.info?.orderedDays.count {
                        let missingDateIndex = CBUtils.findMissingIndex(inRedEyeTrip:trip)
                        let missingRedEyeDate = CBUtils.findMissingDate(forRedEyeTrip: trip)
                        
                        if (missingDateIndex != -1) {
                            var calendar = Calendar(identifier: .gregorian)
                            calendar.locale = Locale.current
                            calendar.timeZone = TimeZone(identifier: "GMT")!
                            var dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: missingRedEyeDate!)
                            // making times 0 for enabling comapare. becase BPStratDate nad BPEndDate are 0 in time.
                            dateComponents.hour = 0
                            dateComponents.minute = 0
                            dateComponents.second = 0
                            
                            let tripDayDate = calendar.date(from: dateComponents)
                            let resultStart = tripDayDate!.compare(bpStartDate!)
                            let resultEnd = tripDayDate!.compare(bpEndDate!)
                            
                            if (self.bidPeriod?.isFABid() == true) {
                                if let swaptimizerStatus = self.bidPeriod?.swaptimizerStatus?.intValue,
                                   let faVacationStatus = self.bidPeriod?.faVacationStatus?.intValue,
                                   let overlapType = trip.vacationOverlapType?.intValue,
                                   (swaptimizerStatus == CBSwaptimizerStatus.enabled.rawValue ||
                                    faVacationStatus == BIFaVacationStatus.enabled.rawValue),
                                   overlapType > 0 {
                                    if (resultStart == .orderedDescending && resultEnd == .orderedAscending) {
                                        redEyeDaysInVac += 1
                                    }
                                    else if (resultStart == .orderedSame && resultEnd == .orderedSame) {
                                        redEyeDaysInVac += 1
                                    }
                                }
                            }
                            else {
                                if let swaptimizerStatus = self.bidPeriod?.swaptimizerStatus?.intValue,
                                   let overlapType = trip.vacationOverlapType?.intValue,
                                   (swaptimizerStatus == CBSwaptimizerStatus.enabled.rawValue),
                                   overlapType > 0 {
                                    if (resultStart == .orderedDescending && resultEnd == .orderedAscending) {
                                        redEyeDaysInVac += 1
                                    }
                                    else if (resultStart == .orderedSame && resultEnd == .orderedSame) {
                                        redEyeDaysInVac += 1
                                    }
                                }
                            }
                            if (resultStart == .orderedDescending && resultEnd == .orderedAscending) {
                                redEyeDays += 1
                            }
                            else if (resultStart == .orderedSame && resultEnd == .orderedSame) {
                                redEyeDays += 1
                            }
                        }
                    }
                    
                }
            }
            workBP = workBP + redEyeDays
            workBPInVac = workBPInVac + redEyeDaysInVac
            
            let isOn = UserDefaults.standard.bool(forKey: kCBIncludeDroppedTripsInProcessingKey)
     
            if isOn {
                workBP = workBP - 0 // This has no effect
            } else {
                workBP = workBP - workBPInVac
            }
     
            line.workDaysBP = NSNumber(value: workBP)
        }
     
    func datesOnlyArrayFromTrip(trip: BITrip) -> [Date] {
            var calendar = Calendar(identifier: .gregorian)
            calendar.locale = Locale(identifier: "en_US")
            calendar.timeZone = TimeZone(identifier: "US/Central")!
            guard let startDate = trip.startDate else { return [] }
            var dateComponents = calendar.dateComponents([.year, .month, .day], from: startDate)
            let df = DateFormatter()
            df.dateFormat = "dd-MM-yyyy"
            df.timeZone = TimeZone(identifier: "US/Central")!
            var tripDates: [String] = []
            for dayInfo in (trip.info?.orderedDays as? [BIDayInfo]) ?? [] {
                if let legs = dayInfo.orderedLegs as? [BILegInfo] {
                    for legInfo in legs {
                        dateComponents.minute = legInfo.departMinutes?.intValue
                        let legStartDate = calendar.date(from: dateComponents)!
                        let dateString = df.string(from: legStartDate)
                        tripDates.append(dateString)
                    }
                }
            }
            let uniqueDatesSet = NSOrderedSet(array: tripDates)
            let uniqueDatesArray = uniqueDatesSet.array as! [String]
            var datesArray: [Date] = []
     
            for dateStr in uniqueDatesArray {
                if let date = df.date(from: dateStr) {
                    datesArray.append(date)
                }
            }
            return datesArray
        }
     
    
    
    private func readTripsForLine(line:BILine, record:NSString, isReserve:Bool) -> Bool{
        var success = true
//        let moc = self.moc
        let moc = dataSource.managedObjectContext
        var tripInfo:BITripInfo?
        var trip:BITrip?
        let tripInterval = 19
        var tripNumRange = NSRange(location: 0, length: 0)
        var tripDateRange = NSRange(location: 0, length: 0)
        var tripStartDayRange = NSRange(location: 0, length: 0)
        var tripMonthDateRange = NSRange(location: 0, length: 0)
        var tripYearRange = NSRange(location: 0, length: 0)
        var tripPosRange = NSRange(location: 0, length: 0)
        let tripResvStartRange = NSRange(location: 24, length: 4)
        let tripResvEndRange = NSRange(location: 35, length: 4)
        let resRept1 = NSRange(location: 24, length: 2)
        let resRls1 = NSRange(location: 35, length: 2)
        let resRept2 = NSRange(location: 26, length: 2)
        let resRls2 = NSRange(location: 37, length: 2)
        
        if isReserve{
            tripNumRange = NSRange(location: 12, length: 4)
            tripDateRange = NSRange(location: 17, length: 7)
            tripStartDayRange = NSRange(location: 17, length: 2)
            tripMonthDateRange = NSRange(location: 19, length: 3)
            tripYearRange = NSRange(location: 22, length: 2)
            
            let tripNumber = record.substring(with: tripNumRange)
            trip = BITrip(context: moc)
            trip?.line = line
            trip?.info = self.trips[tripNumber] as? BITripInfo
            if trip?.info == nil {
                tripInfo = BITripInfo(context: moc)
                tripInfo?.number = tripNumber
                trip?.info = tripInfo
                self.trips[tripNumber] = tripInfo
                let reserveStartTime = record.substring(with: tripResvStartRange)
                trip?.info?.departTime = Int(reserveStartTime) as? NSNumber
                let reserveEndTime = record.substring(with: tripResvEndRange)
                trip?.info?.returnTime = Int(reserveEndTime) as? NSNumber
                trip?.info?.calendarDaysCount = 1
                trip?.info?.faPay = 6.5
                if Int(reserveStartTime)! < 800{
                    tripInfo?.amPM = BIAMPMTripType.AMTrip.rawValue as NSNumber
                }else{
                    tripInfo?.amPM = BIAMPMTripType.PMTrip.rawValue as NSNumber
                }
                let day = BIDayInfo(context: moc)
                day.trip = tripInfo
                tripInfo?.firstDay = day
                
                //Create a leg
                let legInfo = BILegInfo(context: moc)
                legInfo.departMinutes = 720
                legInfo.arriveMinutes = 720
                let rpt = (Int(record.substring(with: resRept1))! * 60) + (Int(record.substring(with: resRept2))!)
                let rls = (Int(record.substring(with: resRls1))! * 60) + (Int(record.substring(with: resRls2))!)
                legInfo.departMinutes = rpt as NSNumber
                legInfo.arriveMinutes = rls as NSNumber
                legInfo.flight = trip?.info?.number
                legInfo.departCity = self.bidPeriod?.base
                legInfo.arriveCity = self.bidPeriod?.base
                legInfo.day = trip?.info?.firstDay
                legInfo.pay = 6.5
                legInfo.equipment = "3"
            }
            
            // Re-set the amPm bit since the FA PM Reserves start between 9am and 12pm
            if (trip?.info?.departTime!.intValue)! < 800{
                trip?.info?.amPM = BIAMPMTripType.AMTrip.rawValue as NSNumber
            }else{
                trip?.info?.amPM = BIAMPMTripType.PMTrip.rawValue as NSNumber
            }
            if line.faReserveLineType?.intValue == BIFaReserveLineType.NoType.rawValue{
                let range = NSRange(location: 1, length: 3)
                let tripNumRange = Range(range, in: tripNumber)!
                    let tripNumberSuffix = tripNumber[tripNumRange]
                    if tripNumberSuffix == "SAR"{
                        //AM reserve
                        line.faReserveLineType = BIFaReserveLineType.SnrAMres.rawValue as NSNumber
                    }else if tripNumberSuffix == "SPR"{
                        //PM reserve
                        line.faReserveLineType = BIFaReserveLineType.SnrPMres.rawValue as NSNumber
                    }else if tripNumberSuffix == "JAR"{
                        //Ready reserve
                        line.faReserveLineType = BIFaReserveLineType.JnrAMres.rawValue as NSNumber
                    }else if tripNumberSuffix == "JPR"{
                        //Ready reserve
                        line.faReserveLineType = BIFaReserveLineType.JnrPMres.rawValue as NSNumber
                    }else if tripNumberSuffix == "JLR"{
                        //Ready reserve
                        line.faReserveLineType = BIFaReserveLineType.JnrLateRes.rawValue as NSNumber
                    }else{
                        line.faReserveLineType = BIFaReserveLineType.NoType.rawValue as NSNumber
                    }
                
            }
            let dateString = record.substring(with: tripDateRange)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "hhddMMMyy"
            let tripDate = dateFormatter.date(from: "12\(dateString)")
            let tripStartDay = record.substring(with: tripStartDayRange)
            trip?.startDay = Int(tripStartDay) as? NSNumber
            trip?.isReserveFa = true
            if (tripDate != nil){
                trip?.startDate = self.calendarData.dateForDate(date:tripDate!)
            }
            
            trip?.tripStartDay = self.getDay(from: (trip?.startDate)!)
            trip?.endDate = self.calendarData.dateForDayOfMonth(dayOfMonth:(trip?.startDay?.intValue)!+((trip?.info?.orderedDays.count)! - 1))
            
            if self.isSecondRoundBid(){
                let timeZoneStr = CBUtils.rawTimeZoneString(forAirportCode: (self.bidPeriod?.base)!)
                let departHHMM = BITrip.staticTimeForReserveType(trip: trip!, line: line, key: "depart", timeZone: timeZoneStr!)
                
                if departHHMM != nil{
                    
                    //parse hours and minutes from the "HHmm" format
                    let hourString = departHHMM?.substring(to: 2)
                    let minuteString = departHHMM?.substring(from: 2)
                    let hour = Int(hourString!)
                    let minute = Int(minuteString!)
                    
                    // Create calendar and components from original date
                    var calendar = Calendar(identifier: .gregorian)
                    calendar.timeZone = TimeZone(identifier: "GMT")!
                    
                    var dateComponents = calendar.dateComponents([.day,.month,.year], from: (trip?.startDate)!)
                    dateComponents.hour = hour
                    dateComponents.minute = minute
                    
                    if let updatedDate = calendar.date(from: dateComponents) {
                        trip?.startDate = updatedDate
                    }
                }
                let arriveHHMM = BITrip.staticTimeForReserveType(trip: trip!, line: line, key: "arrive", timeZone: timeZoneStr!)
                
                if arriveHHMM != nil{
                    
                    let hourString = arriveHHMM?.substring(to: 2)
                    let minuteString = arriveHHMM?.substring(from: 2)
                    let hour = Int(hourString!)
                    let minute = Int(minuteString!)
                    
                    // Create calendar and components from original date
                    var calendar = Calendar(identifier: .gregorian)
                    calendar.timeZone = TimeZone(identifier: "GMT")!
                    
                    var dateComponents = calendar.dateComponents([.day,.month,.year], from: (trip?.endDate)!)
                    dateComponents.hour = hour
                    dateComponents.minute = minute
                    
                    if let updatedDate = calendar.date(from: dateComponents) {
                        trip?.endDate = updatedDate
                    }
                    
                    if trip?.endDate?.compare((trip?.startDate)!) == .orderedAscending{
                        var calendar = Calendar(identifier: .gregorian)
                        calendar.locale = .current
                        calendar.timeZone = TimeZone(identifier: "GMT")!
                        let oneDay = DateComponents(day: 1)
                        trip?.endDate = calendar.date(byAdding: oneDay, to: trip?.endDate ?? Date())!
                    }
                }
            }
        }
        else{
            tripNumRange = NSRange(location: 12, length: 4)
            tripDateRange = NSRange(location: 16, length: 7)
            tripPosRange = NSRange(location: 30, length: 1)
            tripStartDayRange = NSRange(location: 16, length: 2)
            tripMonthDateRange = NSRange(location: 18, length: 3)
            tripYearRange = NSRange(location: 21, length: 2)
            
            while tripNumRange.location < 69{
                
                let tripNumber = record.substring(with: tripNumRange)
                if !tripNumber.hasPrefix(" "){
                    let trip = BITrip(context: moc)
                    trip.info = self.trips[tripNumber] as? BITripInfo
                    trip.line = line
                    let digits = record.substring(with: tripStartDayRange)
                    if !self.isDigitString(digits, trimWhitespace: true){
                        success = false
                        break
                    }
                    trip.startDay = (digits as NSString).integerValue as NSNumber
                    let position = record.substring(with: tripPosRange)
                    trip.positionString = position
                    if position == "A"{
                        trip.position = BIFaPosition.FaPositionA.rawValue as NSNumber
                    }else if position == "B"{
                        trip.position = BIFaPosition.FaPositionB.rawValue as NSNumber
                    }else if position == "C"{
                        trip.position = BIFaPosition.FaPositionC.rawValue as NSNumber
                    }else if position == "D"{
                        trip.position = BIFaPosition.FaPositionD.rawValue as NSNumber
                    }else{
                        trip.position = BIFaPosition.FaPositionNA.rawValue as NSNumber
                    }
                    let dateStr = record.substring(with: tripDateRange)
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "hhddMMMyy"
                    dateFormatter.timeZone = TimeZone(identifier: "US/Central")!
                    let tripDate = dateFormatter.date(from: "12\(dateStr)")
                    if (tripDate != nil){
                        trip.startDate = tripDate
                    }
                    trip.tripStartDay = self.getDay(from: trip.startDate ?? Date())
                    trip.endDate = self.calendarData.dateForDayOfMonth(dayOfMonth:(trip.startDay?.intValue)!+(trip.info?.orderedDays.count)! - 1)
                }
                tripNumRange.location += tripInterval
                tripDateRange.location += tripInterval
                tripPosRange.location += tripInterval
                tripStartDayRange.location += tripInterval
            }//end of while loop
        }
        return success
    }
    
    //MARK: trip info properties with record 1
    private func setPropertiesForTripInfoRecord1(tripInfo:BITripInfo, record1:String) -> Bool{
        
        //Number
        let numberRange = Range(tripNumberRange, in: record1)!
            let number = String(record1[numberRange])
            if !self.matchesTripNumberFormat(tripNumber: number){
                return false
            }
            tripInfo.number = number
        
        
        //length - calendar days count
        let daysCountRange = Range(tripCalendarDaysCountRange, in: record1)!
            let count = String(record1[daysCountRange])
            if !self.isDigitString(count, trimWhitespace: false){
                return false
            }
            tripInfo.calendarDaysCount = (count as NSString).integerValue as NSNumber
        
        
        //Depart time
        let departTimeRange = Range(tripDepartTimeRange, in: record1)!
            let departTime = String(record1[departTimeRange])
            if !self.isDigitString(departTime, trimWhitespace: false){
                return false
            }
            tripInfo.departTime = (departTime as NSString).integerValue as NSNumber
        
        
        //Return time
        let returnTimeRange = Range(tripReturnTimeRange, in: record1)!
            let returnTime = String(record1[returnTimeRange])
            if !self.isDigitString(returnTime, trimWhitespace: false){
                return false
            }
            tripInfo.returnTime = (returnTime as NSString).integerValue as NSNumber
        
        
        //AM/PM am = 1, pm = 2
        let ampmRange = Range(tripAmPmRange, in: record1)!
            let ampm = Int(record1[ampmRange])
            if ampm != 1 && ampm != 2{
                return false
            }
            tripInfo.amPM = ampm as? NSNumber
        
        
        let herbValueStr = UserDefaults.standard.string(forKey: KCBCustomizedHerbValue)
        let herbValue: Int
        if let herbValueStr = herbValueStr, !herbValueStr.isEmpty {
            herbValue = Int(herbValueStr) ?? 0
        } else {
            herbValue = 1200
        }
        if (tripInfo.departTime!.intValue) < herbValue {
            tripInfo.amPM = BIAMPMTripType.AMTrip.rawValue as NSNumber
        }else{
            tripInfo.amPM = BIAMPMTripType.PMTrip.rawValue as NSNumber
        }
        self.bidPeriod?.currentAmPmHerb = herbValue as NSNumber
        
        //Duty period count
         let tripdutyPeriodCountRange = Range(tripDutyPeriodsCountRange, in: record1)!
            let dutyPeriodCount = String(record1[tripdutyPeriodCountRange])
            if !self.isDigitString(dutyPeriodCount, trimWhitespace: false){
                return false
            }
            tripInfo.dutyPeriodsCount = (dutyPeriodCount as NSString).integerValue as NSNumber
        return true
    }
    
    //MARK: trip info properties with record 2
    private func readDaysInfoTripsInfoRecord2(tripInfo:BITripInfo, record2:String) -> Bool{
        var prevDay:BIDayInfo?
        var overNightsInBase = 0
//        let moc = self.moc
        let moc = dataSource.managedObjectContext
        let base = UserDefaults.standard.string(forKey: kCBCrewBaseDefaultKey)
        for dayIndex in 0..<tripMaxDaysCount {
            let cityRangeStart = dayCityRangeLocation + dayIndex * dayInterval
            
            //Stop when reaching end of the day
            if record2.character(at: cityRangeStart) == " "{
                break
            }
            
            //City
            var range = NSRange(location: cityRangeStart, length: dayCityRangeLength)
            let cityRange = Range(range, in: record2)
            let city = String(record2[cityRange!])
            if !(cityPredicate?.evaluate(with: city))!{
                return false
            }
            if city == base{
                overNightsInBase += 1
            }
            
            //Pay
            range = NSRange(location: dayPayIntegerRangeLocation + dayIndex * dayInterval, length: dayPayIntegerRangeLength)
            var digits:String
            let dayPayIntRange = Range(range, in: record2)
            digits = String(record2[dayPayIntRange!])
            
                //Reserve trips have leading space for pay
                if let c = tripInfo.number?.dropFirst().first, c <= "W" {
                    digits = digits.trimmingCharacters(in: .whitespaces)
                }
                if !self.isDigitString(digits, trimWhitespace: true){
                    return false
                }
                var pay = (digits as NSString).floatValue
                
                range = NSRange(location: dayPayDecimalRangeLocation + dayIndex * dayInterval, length: dayPayDecimalRangeLength)
                let dayPayDecRange = Range(range, in: record2)
                digits = String(record2[dayPayDecRange!])
               
                
                if !self.isDigitString(digits, trimWhitespace: false){
                    return false
                }
                pay += (digits as NSString).floatValue / 60
                
                //Create day
                let dayInfo = BIDayInfo(context: moc)
                dayInfo.city = city
                dayInfo.pay = pay as NSNumber
                dayInfo.trip = tripInfo
                
                //First Day
                if dayIndex == 0{
                    tripInfo.firstDay = dayInfo
                }
                //Previous day/next day
                dayInfo.previousDay = prevDay
                prevDay = dayInfo
            
        }
        tripInfo.overnightsInBase = overNightsInBase - 1 as NSNumber
        return true
    }
    
    //MARK: leg info properties with record5 and record6
    private func readLegsInfoForTripInfo(tripInfo:BITripInfo, record5:String, record6:String) -> Bool{
//        let moc = self.moc
        let moc = dataSource.managedObjectContext
        var day = tripInfo.firstDay
        var prevLeg : BILegInfo?
        //Get max possible number of legs in record5 and 6
        let maxRecord5Legs = record5.length/legRecord5Interval
        let maxRecord6Legs = record6.length/legRecord6Interval
        let maxLegs = min(maxRecord5Legs, maxRecord6Legs)
        
        //Read the legs
        for legIndex in 0..<maxLegs{
            let leg = BILegInfo(context: moc)
            var isDutyBreak:Bool = false
            var range = NSRange(location: legDepartMinutesRangeLocation + legRecord5Interval * legIndex, length: legDepartMinutesRangeLength)
            let departRange = Range(range, in: record5)!
            var digits = String(record5[departRange])
                if !self.isDigitString(digits, trimWhitespace: true){
                    return false
                }
                let departMinutes = (digits as NSString).integerValue
                if departMinutes == 0{
                    break
                }
                leg.departMinutes = departMinutes as NSNumber
                
                //Deadhead
                var index = record5.index(record5.startIndex, offsetBy: legTypeCharIndex + legRecord5Interval * legIndex)
                let isDeadhead = record5[index] == "2"
                leg.isDeadhead = isDeadhead as NSNumber
                
                //Duty break
                index = record5.index(record5.startIndex, offsetBy: legDutyBreakCharIndex + legRecord5Interval * legIndex)
                isDutyBreak = record5[index] == "9"
                leg.isDutyBreak = isDutyBreak as NSNumber
                if isDutyBreak{
                    day = day?.nextDay
                }
            
                //Arrive minutes
            range = NSRange(location: legArriveMinuteRangeLocation + legRecord5Interval * legIndex, length: legArriveMinuteRangeLength)
            let arriveRange = Range(range, in: record5)!
                 digits = String(record5[arriveRange])
                if !self.isDigitString(digits, trimWhitespace: true){
                    return false
                }
                let arriveMinutes = (digits as NSString).integerValue
                leg.arriveMinutes = arriveMinutes as NSNumber
            
              
            // Flight. Trim whitespace. Remove DH in first two characters. Remove
            // leading zeros.
            range = NSRange(location: legFlightRangeLocation + legRecord6Interval * legIndex, length: legFlightRangeLength)
            let flightRange = Range(range, in: record6)!
                var flight = String(record6[flightRange])
                if !self.isDigitString(flight, trimWhitespace: true){
                    if !flight.hasPrefix("DH"){
                        legRecord6Interval = 18
                    }
                    if tripInfo.isPilotReserve{
                        legRecord6Interval = 15
                    }
                    flight = String(record6[Range(NSRange(location: legFlightRangeLocation + legRecord6Interval * legIndex, length: legFlightRangeLength), in: record6)!])
                }
                flight = flight.trimmingCharacters(in: .whitespaces)
                if flight.hasPrefix("DH") {
                    flight = String(flight.dropFirst(2))
                }
                leg.flight = flight
            
            
            //Red eye
            range = NSRange(location: 17 + legRecord6Interval * legIndex, length: 1)
            let redEyeRange = Range(range, in: record6)!
                if String(record6[redEyeRange]) == "O"{
                    leg.isRedEyeFlight = true
                }else{
                    leg.isRedEyeFlight = false
                }
            
                
           //Depart city
            range = NSRange(location: legDepartCityRangeLocation + legRecord6Interval * legIndex, length: legDepartCityRangeLength)
            let departCityRange = Range(range, in: record6)!
                let departCity = String(record6[departCityRange])
                if !(cityPredicate?.evaluate(with: departCity))!{
                    return false
                }
                leg.departCity = departCity
        
            //Arrive city
                range = NSRange(location: legArriveCityRangeLocation + legRecord6Interval * legIndex, length: legArriveCityRangeLength)
                let arriveCityRange = Range(range, in: record6)!
                    let arriveCity = String(record6[arriveCityRange])
                    if !(cityPredicate?.evaluate(with: arriveCity))!{
                        return false
                    }
                    leg.arriveCity = arriveCity
                
                
                //Aircraft change
                index = record6.index(record6.startIndex, offsetBy: legAircraftChangeCharIndex + legRecord6Interval * legIndex)
                let isAircraftChange = record6[index] == "*"
                leg.isAircraftChange = isAircraftChange as NSNumber
                
                //Equipment
                
                if tripInfo.isPilotReserve{
                    leg.equipment = nil
                }else{
                    range = NSRange(location: legEquipmentCharIndex + legRecord6Interval * legIndex, length: legEquipmentRangeLength)
                    let equipmentRange = Range(range, in: record6)!
                        let equipmentCharacters = String(record6[equipmentRange])
                        leg.equipment = self.getEquipmentType(type: equipmentCharacters)
                    
                }
                
                //Previous leg
                leg.previousLeg = prevLeg
                prevLeg = leg
                
                //Day
                leg.day = day
                
                //Day first leg
                if legIndex == 0 || isDutyBreak{
                    day?.firstLeg = leg
                }
                
            
        }
        return true
    }
    
    //MARK: read trips for line
    private func readTripsForLine(line:BILine, record:String) -> Bool{
        var success = true
        let moc = self.dataSource.managedObjectContext
        var startDayRange = NSRange(location: 14, length: 2)
        let tripInterval = 6
        var tripNumberRange = NSRange(location: 10, length: 4)
        let maxTripsPerRecord = 10
        var tripSequence = 1
        calendarData = calendarData.initWithBidPeriod(bidPeriod: self.bidPeriod!)!
        for t in 0..<maxTripsPerRecord{
            let digits = (record as NSString).substring(with: startDayRange)
            if !self.isDigitString(digits, trimWhitespace: true){
                success = false
                break
            }
            else{
                let startDay = (digits as NSString).intValue
                if startDay == 0{
                    break
                }
                else{
                    let tripNumber = (record as NSString).substring(with: tripNumberRange)
                    if self.matchesTripNumberFormat(tripNumber: tripNumber){
                        let trip = BITrip(context: moc)
                        trip.number = tripNumber
                        if let info = trips[tripNumber] as? BITripInfo {
                            trip.info = info
                        }
                        trip.startDay = startDay as NSNumber
                        if trip.info == nil{
                            trip.info = self.readTripFromJson(trip: trip, tripSequence: tripSequence, line: line, showPPAlert: self.showAlertForPP)
                            tripSequence += 1
                        }
                        if trip.info == nil{
                            if self.isSecondRoundBid() && !self.isFABid(){
                                missingTrips?.append(tripNumber)
                            }else{
                                //handle error
                                let errorReason = "We cannot display the bid data right now.  The bid data is just not complete.  We are in the process of build a complete trip file, and you should be able to try again in 4 hours."
                                success = false
                                break
                            }
                        }
                        trip.line = line
                        trip.startDate = self.calendarData.dateForDayOfMonth(dayOfMonth:trip.startDay!.intValue)
                        trip.tripStartDay = self.getDay(from: trip.startDate!)
                        trip.endDate = self.calendarData.dateForDayOfMonth(dayOfMonth:(trip.startDay!.intValue+(trip.info?.orderedDays.count)!-1))
                    }else{
                        success = false
                        break
                    }
                }
            }
            startDayRange.location += tripInterval
            tripNumberRange.location += tripInterval
        }
        return success
    }
    
    private func readTripFromJson(trip: BITrip,tripSequence: Int,line: BILine,showPPAlert: Bool) -> BITripInfo? {
        let moc = self.dataSource.managedObjectContext
        var dayInfo:BIDayInfo?
        var prevDay:BIDayInfo?
        var legInfo:BILegInfo?
        var tripInfo:BITripInfo?
        var prevLeg:BILegInfo?
        let dict = AppState.shared.missingTripInfo
        
        if dict!["JsonTripData"] is NSNull{
            if self.showAlertForPP == true{
                NotificationCenter.default.post(name: Notification.Name("ShowAlert"), object: nil)
                self.bidPeriod?.containsMissingTripLines = true
                self.showAlertForPP = false
            }
            let directoryURL = BIBidInfo.shared.downloadDirectory()
            let textFileURL = directoryURL.appendingPathComponent(BIBidInfo.shared.linesTextFilename())
            let fileInfo = try! String(contentsOf: textFileURL, encoding: .utf8)
            line.containsPartialTrip = true
            tripInfo = self.readTripForLineNumber(line.number!.intValue, forTrip: trip, trip.startDay!.intValue, tripSequence, fileInfo)
            return tripInfo
        }
        
        let missingTripsArray = dict!["JsonTripData"] as! [Any]
        for i in 0..<missingTripsArray.count{
            let missingTripDict = missingTripsArray[i] as! [String:Any]
            let tripNumWithSpecialChar = missingTripDict["TripNumb"] as! String
            var startDay = "\(trip.startDay!)"
            if startDay.length == 1{
                startDay = "0\(trip.startDay!)"
            }
            let tripNumWithDay = "\(trip.number!)\(startDay)"
            
            if tripNumWithSpecialChar == tripNumWithDay{
                tripInfo = BITripInfo(context: moc)
                let dutyPeriodArray = missingTripDict["DutyPeriods"] as! [Any]
                let depTime = missingTripDict["DepTime"] as! Int
                let arrTime = missingTripDict["RetTime"] as! Int
                let debriefMinutes = missingTripDict["DebriefTime"] as! Int
                let briefMinutes = missingTripDict["BriefTime"] as! Int
                let tripInfoPayJSON = missingTripDict["Tfp"] as! Float
                let tripTAFBJSON = missingTripDict["Tafb"] as! Float
                tripInfo?.number = trip.number?.substring(to: 4)
                tripInfo?.departTime = depTime as NSNumber
                tripInfo?.returnTime = arrTime as NSNumber
                tripInfo?.partialTrip = false
                tripInfo?.jsonPay = tripInfoPayJSON as NSNumber
                tripInfo?.tafbJson = tripTAFBJSON as NSNumber
                tripInfo?.debriefMinutes = debriefMinutes as NSNumber
                tripInfo?.briefMinutes = briefMinutes as NSNumber
                
                var prevCity = self.bidPeriod?.base
                prevDay = nil
                for i in 0..<dutyPeriodArray.count{
                    let city = (dutyPeriodArray[i] as? [String: Any])?["ArrStaLastLeg"] as? String
                    //create new day
                    dayInfo = BIDayInfo(context: moc)
                    dayInfo?.trip = tripInfo
                    dayInfo?.city = city
                    dayInfo?.reportTime = (dutyPeriodArray[i] as? [String: Any])?["ShowTime"] as? NSNumber
                    let pay: CGFloat = CGFloat(((dutyPeriodArray[i] as? [String: Any])?["Tfp"] as? NSNumber)?.floatValue ?? 0.0)
                    dayInfo?.pay = pay as NSNumber
                    let departTimeFirstLeg = (dutyPeriodArray[i] as? [String: Any])?["DepTimeFirstLeg"] as? NSNumber
                    dayInfo?.departTimeFirstLeg = departTimeFirstLeg
                    var tfpRig:Float = 0
                    if i == dutyPeriodArray.count - 1{
                        // last duty period
                        let adjRig:Float = missingTripDict["RidAdg"] as! Float
                        let tafbRig:Float = missingTripDict["RigTafb"] as! Float
                        if adjRig <= tafbRig{
                            tfpRig = tafbRig
                        }else if adjRig > tafbRig{
                            tfpRig = adjRig
                        }
                        dayInfo?.pay = dayInfo!.pay!.floatValue + tfpRig as NSNumber
                    }
                    let flightArray = (dutyPeriodArray[i] as? [String: Any])?["Flights"] as? [[String: Any]]
                    for k in 0..<flightArray!.count{
                        var equipment = (flightArray![k] as [String:Any])["Equip"] as? String
                        if equipment != ""{
                            equipment = equipment?.substring(to: 1)
                        }
                        let departMin = (flightArray![k] as [String:Any])["DepTime"] as? Int
                        let arriveMin = (flightArray![k] as [String:Any])["ArrTime"] as? Int
                        let flightNum = (flightArray![k] as [String:Any])["FltNum"] as? String
                        let isDeadHead = (flightArray![k] as [String:Any])["DeadHead"] as? Int
                        legInfo = BILegInfo(context: moc)
                        legInfo?.departCity = (flightArray![k] as [String:Any])["DepSta"] as? String
                        legInfo?.arriveCity = (flightArray![k] as [String:Any])["ArrSta"] as? String
                        legInfo?.flight = flightNum
                        legInfo?.isDeadhead = isDeadHead as? NSNumber
                        legInfo?.day = dayInfo
                        legInfo?.departMinutes = departMin as? NSNumber
                        legInfo?.arriveMinutes = arriveMin as? NSNumber
                        legInfo?.equipment = equipment
                        prevCity = city
                        let legPay = (flightArray![k] as [String:Any])["Tfp"] as? Float
                        legInfo?.pay = legPay as? NSNumber
                        let redEyeValue = (flightArray![k] as [String:Any])["RedEye"] as? Int
                        if redEyeValue == 1{
                            legInfo?.isRedEyeFlight = true
                        }else{
                            legInfo?.isRedEyeFlight = false
                        }
                        if k == 0{
                            dayInfo?.firstLeg = legInfo
                        }
                        legInfo?.previousLeg = prevLeg
                        prevLeg = legInfo
                    }
                    dayInfo?.previousDay = prevDay
                    prevDay = dayInfo
                    if i == 0{
                        tripInfo?.firstDay = dayInfo
                    }
                }
                tripInfo?.calendarDaysCount = dutyPeriodArray.count as NSNumber
                tripInfo?.dutyPeriodsCount = dutyPeriodArray.count as NSNumber
                
                let herbValueStr = UserDefaults.standard.string(forKey: KCBCustomizedHerbValue)
                let herbValue = (herbValueStr?.isEmpty ?? true) ? 1200 : Int(herbValueStr!) ?? 1200
                
                if tripInfo!.departTime!.intValue < herbValue{
                    tripInfo?.amPM = BIAMPMTripType.AMTrip.rawValue as NSNumber
                }else{
                    tripInfo?.amPM = BIAMPMTripType.PMTrip.rawValue as NSNumber
                }
                self.bidPeriod?.currentAmPmHerb = herbValue as NSNumber
            }
        }
        if tripInfo == nil{
            if showAlertForPP == true{
                NotificationCenter.default.post(name: Notification.Name("showAlert"), object: nil)
                bidPeriod?.containsMissingTripLines = true
                showAlertForPP = false
            }
            let directoryURL = BIBidInfo.shared.downloadDirectory()
            let textFileURL = directoryURL.appendingPathComponent(BIBidInfo.shared.linesTextFilename())
            let fileInfo = try! String(contentsOf: textFileURL, encoding: .utf8)
            
            line.containsPartialTrip = true
            tripInfo = self.readTripForLineNumber(line.number!.intValue, forTrip: trip, trip.startDay!.intValue, tripSequence, fileInfo)
        }
        return tripInfo
    }
    
    private func readTripForLineNumber(_ lineNumber:Int, forTrip trip:BITrip, _ tripDate:Int, _ tripSequence:Int, _ fileInfo:String) -> BITripInfo?{
        let moc = dataSource.managedObjectContext
        var tripInfo:BITripInfo? = nil
        let regex = "^Line.*"
        let regexPredicate = NSPredicate(format: "SELF MATCHES %@", regex)
        let fileInfoLength = fileInfo.length
        var lineRange = NSRange(location: 0, length: 0)
        var lineInfo:String = ""
        var prevDay:BIDayInfo? = nil
        var dayInfo:BIDayInfo? = nil
        var legInfo:BILegInfo? = nil
        var herbValue = 0
        var dayIndex = 0
        // Scanner results, used to determine if errors occurred in reading the
        // line info.
        // Read lines from the file, seeking the line that begins the info for the
        // line that contains the trip we're trying to create.
        while lineRange.location < fileInfoLength{
            lineRange = (fileInfo as NSString).lineRange(for: lineRange)
            lineInfo = (fileInfo as NSString).substring(with: lineRange)
            if regexPredicate.evaluate(with: lineInfo){
                var scanner = Scanner(string: lineInfo)
                // Scan past the string 'Line'. This shouldn't fail, since the
                // predicate test should have found a line of text that begins with
                // the string 'Line'.
                if scanner.scanString("Line") == nil{
                    //handle error
                    let errorReason = String(format: "Failed to read line number for line: %ld trip: %@ sequence: %lu.", lineNumber, trip.number!.substring(to: 4), tripSequence)
                    return nil
                }
                // Scan line number, which should immediately follow string 'Line'
                // at the start of the line info.
                guard let lineNum = scanner.scanInt() else{
                    return nil
                }
                // Find the start of the info for the line that contains the trip
                // that is to be created.
                if lineNum == lineNumber{
                    // Determine the location of the start of the days of the month
                    // in this line, which will be used to set the start of the
                    // scan for the trip number, as there is no trip number info
                    // prior to that point in the line info.
                    
                    // Failed to read text 'TFP', which should immediately follow
                    // line number in the line info.
                    if scanner.scanString("TFP") == nil{
                        //handle error
                        let errorReason = String(format: "Failed to read TFP text for line: %ld trip: %@ sequence: %lu.", lineNumber, trip.number!.substring(to: 4), tripSequence)
                        return nil
                    }
                    // Failed to read TFP value.
                    if scanner.scanFloat() == nil{
                        //handle error
                        let errorReason = String(format: "Failed to find days of month start for line: %ld trip: %@ sequence: %lu.", lineNumber, trip.number!.substring(to: 4), tripSequence)
                        return nil
                    }
                    // This is the point at which all scanning of lines info should
                    // start; there is no useful trip information in the lines
                    // file info before this point in each line of info.
                    let datesStart = scanner.string.distance(from: scanner.string.startIndex, to: scanner.currentIndex) - 1
                    // Skip past this line and the next line.
                    lineRange.location = lineRange.location + lineRange.length
                    lineRange.length = 0
                    if lineRange.location >= fileInfoLength{
                        //handle error
                        let errorReason = String(format: "Failed to find trip info for line: %ld trip: %@ sequence: %lu.", lineNumber, trip.number!.substring(to: 4), tripSequence)
                        return nil
                    }
                    lineInfo = (fileInfo as NSString).substring(with: lineRange)
                    // We should now be at the text that contains the partial trip
                    // number. Determine where it is located in the text, so we can
                    // use that location in the next line to read the overnight
                    // cities. This is really just a sanity check, since we should
                    // be able to determine where the overnight cities start from
                    // where the dates start and the start day of the trip.
                    let scanStart = datesStart + 3 * (tripDate - 1)
                    scanner = Scanner(string: lineInfo)
                    scanner.currentIndex = scanner.string.index(scanner.string.startIndex, offsetBy: scanStart)
                    let partTripNum = (trip.number! as NSString).substring(with: NSRange(location: 1, length: 3))
                    // Failed to find partial trip number at scan start location
                    // in line info. Partial trip number has format 'P01'. Since
                    // the scanner should already be at the start of the partial
                    // trip number, this scan should fail.
                    if scanner.scanUpToString(partTripNum) == nil{
                        //handle error
                        let errorReason = String(format: "Failed to find trip for line: %ld trip: %@ sequence: %lu.", lineNumber, trip.number!.substring(to: 4), tripSequence)
                        return nil
                    }
                    let tripStartLoc = scanner.currentIndex.utf16Offset(in: scanner.string)
                    var charsToNextTrip = 1000
                    if tripStartLoc + 3 < lineInfo.length{
                        scanner.currentIndex = scanner.string.index(scanner.currentIndex, offsetBy: 3)
                        scanner.charactersToBeSkipped = nil
                        _ = scanner.scanUpToCharacters(from: CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"))
                        charsToNextTrip = scanner.currentIndex.utf16Offset(in: scanner.string) - tripStartLoc
                    }
                    // Skip to next line of text, which should have overnight
                    // cities.
                    lineRange.location = lineRange.location + lineRange.length
                    lineRange.length = 0
                    if lineRange.location >= fileInfoLength{
                        //handle error
                        let errorReason = String(format: "Failed to find trip info for line: %ld trip: %@ sequence: %lu.", lineNumber, trip.number!.substring(to: 4), tripSequence)
                        return nil
                    }
                    lineRange = (fileInfo as NSString).lineRange(for: lineRange)
                    lineInfo = (fileInfo as NSString).substring(with: lineRange)
                    scanner.currentIndex = scanner.string.index(scanner.string.startIndex, offsetBy: tripStartLoc)
                    // Scan the overnight cities for the trip. The number of
                    // characters scanned should be evenly divisible by 3.
                    let citiesRangeEnd = scanner.string[scanner.currentIndex...].firstIndex(where: { !CharacterSet.alphanumerics.contains($0.unicodeScalars.first!) }) ?? scanner.string.endIndex
                    let citiesString = scanner.string[scanner.currentIndex..<citiesRangeEnd]
                    scanner.currentIndex = citiesRangeEnd
                    let cities = String(citiesString)
                    if cities.length%3 != 0{
                        //handle error
                        let errorReason = String(format: "Failed to find overnight cities for line: %ld trip: %@ sequence: %lu.", lineNumber, trip.number!.substring(to: 4), tripSequence)
                        return nil
                    }
                    // Skip to next line of text, which will have start/end times
                    // and pay for trip.
                    lineRange.location = lineRange.location + lineRange.length
                    lineRange.length = 0
                    lineRange = (fileInfo as NSString).lineRange(for: lineRange)
                    if  lineRange.location >= fileInfoLength{
                        //handle error
                        let errorReason = String(format: "Failed to find trip info for line: %ld trip: %@ sequence: %lu.", lineNumber, trip.number!.substring(to: 4), tripSequence)
                        return nil
                    }
                    lineInfo = (fileInfo as NSString).substring(with: lineRange)
                    // Determine if following line has more trip info blocks. If
                    // so, append to lineInfo string. If the following line starts
                    // with a '-' char, then there is no more trip info available.
                    let nextCharLoc = lineRange.location + lineRange.length
                    if nextCharLoc < fileInfoLength && fileInfo.character(at: nextCharLoc) != "-"{
                        lineRange.location = lineRange.location + lineRange.length
                        lineRange.length = 0
                        lineRange = (fileInfo as NSString).lineRange(for: lineRange)
                        if lineRange.location >= fileInfoLength{
                            //handle error
                            let errorReason = String(format: "Failed to find trip info for line: %ld trip: %@ sequence: %lu.", lineNumber, trip.number!.substring(to: 4), tripSequence)
                            return nil
                        }
                        lineInfo += (fileInfo as NSString).substring(with: lineRange)
                    }
                    
                    // If the trip info (P03=0620/1605(14.50)) contains 3 lines,
                    // we need to append the next next line to line range.
                    let nextCharLoc1 = lineRange.location + lineRange.length
                    if nextCharLoc1 < fileInfoLength && fileInfo.character(at: nextCharLoc1) != "-"{
                        lineRange.location = lineRange.location + lineRange.length
                        lineRange.length = 0
                        lineRange = (fileInfo as NSString).lineRange(for: lineRange)
                    }
                        lineInfo += (fileInfo as NSString).substring(with: lineRange)
                        
                        // Read trip info (format: P03=0620/1605(14.50)).
                        // Start scanning at dates start location since
                        // there is no trip data before that point. If there is more
                        // than one trip with the same number in the line, skip to the
                        // trip info that corresponds to that trip (trip sequence).
                        scanner = Scanner(string: lineInfo)
                        scanner.currentIndex = scanner.string.index(scanner.string.startIndex, offsetBy: datesStart)
                        for _ in 0..<tripSequence {
                            // scan up to partTripNum
                            if let range = scanner.string[scanner.currentIndex...].range(of: partTripNum) {
                                // advance scanner to start of partTripNum
                                scanner.currentIndex = range.lowerBound
                            } else {
                                break  // partTripNum not found, exit loop early
                            }

                            // scan the partTripNum string itself
                            scanner.currentIndex = scanner.string.index(scanner.currentIndex, offsetBy: partTripNum.count)

                            // scan up to the next decimal digit
                            if let nextDigitIndex = scanner.string[scanner.currentIndex...].firstIndex(where: { $0.isWholeNumber }) {
                                scanner.currentIndex = nextDigitIndex
                            } else {
                                // no decimal digit found, move scanner to end
                                scanner.currentIndex = scanner.string.endIndex
                            }
                        }
                        // If scanner is at end, then failed to find partial trip
                        // number in trip start/end and pay info.
                        if scanner.isAtEnd{
                            //handle error
                            let errorReason = String(format: "Failed to find trip start/end and pay info for line: %ld trip: %@ sequence: %lu.", lineNumber, trip.number!.substring(to: 4), tripSequence)
                            return nil
                        }
                        var prevScanLoc = scanner.currentIndex.utf16Offset(in: scanner.string)
                        var depTime: Int = 0
                        if !scanner.scanInt(&depTime) || (scanner.currentIndex.utf16Offset(in: scanner.string) - prevScanLoc) != 4{
                            //handle error
                            let errorReason = String(format: "Failed to find read start time for line: %ld trip: %@ sequence: %lu.", lineNumber, trip.number!.substring(to: 4), tripSequence)
                            return nil
                        }
                        prevScanLoc = scanner.currentIndex.utf16Offset(in: scanner.string)
                        var arrTime = 0
                        guard scanner.scanUpToCharacters(from: .decimalDigits) != nil,
                              let scannedInt = scanner.scanInt(),
                              scanner.currentIndex.utf16Offset(in: scanner.string) - prevScanLoc == 5 else {
                            let errorReason = String(format: "Failed to read end time for line: %ld trip: %@ sequence: %lu.",lineNumber,trip.number!.substring(to: 4),tripSequence)
                            return nil
                        }
                        arrTime = scannedInt
                        
                        var pay:Float = 0
                        guard scanner.scanUpToCharacters(from: .decimalDigits) != nil, let scannedFloat = scanner.scanFloat() else {
                            let errorReason = String(format: "Failed to read end time for line: %ld trip: %@ sequence: %lu.",lineNumber,trip.number!.substring(to: 4),tripSequence)
                             return nil
                        }
                        pay = scannedFloat
                        // Create a new trip and set available properties. At this
                        // point should be fairly certain that available properties
                        // have been read properly.
                        tripInfo = BITripInfo(context: moc)
                        // Trip number is the first four characters of the trip key.
                        tripInfo?.number = trip.number?.substring(to: 4)
                        tripInfo?.departTime = depTime as NSNumber
                        tripInfo?.returnTime = arrTime as NSNumber
                        tripInfo?.partialTrip = true
                        
                        var herbValueStr = UserDefaults.standard.string(forKey: KCBCustomizedHerbValue)
                        let herbValue: Int
                        if let herbStr = herbValueStr, !herbStr.isEmpty {
                            herbValue = Int(herbStr) ?? 1200
                        } else {
                            herbValue = 1200
                        }
                        if tripInfo!.departTime!.intValue < herbValue{
                            tripInfo?.amPM = BIAMPMTripType.AMTrip.rawValue as NSNumber
                        }else{
                            tripInfo?.amPM = BIAMPMTripType.PMTrip.rawValue as NSNumber
                        }
                        // Create days for each city.
                        let daysCount = cities.length / 3
                        dayIndex = 0
                        var actualDayCount = 0
                        var prevCity = self.bidPeriod?.base
                        prevDay = nil
                        var departMinutes = 0
                        for dayIndex in 0..<daysCount {
                            // Check to see if there was a back to back trip, because if there was then the
                            // lineReader will have read in the cities from the second trip as well, so break
                            // at the start of the next trip
                            if (dayIndex * 3 + 1) > charsToNextTrip {
                                break
                            }
                            let cityRange = NSRange(location: dayIndex * 3, length: 3)
                            let city = (cities as NSString).substring(with: cityRange)
                            
                            // Create a new day
                            dayInfo = BIDayInfo(context: moc)
                            dayInfo?.trip = tripInfo
                            dayInfo?.city = city
                            dayInfo?.pay = pay / Float(daysCount) as NSNumber
                            
                            // Create a single leg for each day.
                            legInfo = BILegInfo(context: moc)
                            legInfo?.departCity = prevCity
                            legInfo?.arriveCity = city
                            legInfo?.flight = "NA"
                            legInfo?.day = dayInfo
                            legInfo?.departMinutes = departMinutes as NSNumber
                            departMinutes += 1440
                            legInfo?.arriveMinutes = departMinutes as NSNumber
                            prevCity = city
                            dayInfo?.firstLeg = legInfo
                            
                            if dayIndex == 0{
                                tripInfo?.firstDay = dayInfo
                                let time = (tripInfo!.departTime!.intValue / 100) * 60 + tripInfo!.departTime!.intValue % 100
                                legInfo?.departMinutes = time as NSNumber
                            }
                            // Stop when we get to city that is equal to base, to
                            // avoid reading past the trip's city (such as when the
                            // is followed by a turn).
                            dayInfo?.previousDay = prevDay
                            prevDay = dayInfo
                            actualDayCount += 1
                        }
                        tripInfo?.calendarDaysCount = actualDayCount as NSNumber
                        tripInfo?.dutyPeriodsCount = actualDayCount as NSNumber
                        // Set departure and arrival times for first and last legs of
                        // trip. (This is the only information we have available for
                        // days and legs.) Departure and return times are minutes from
                        // midnight of first day of trip, so need to convert.
                        
                        let time = (tripInfo!.returnTime!.intValue / 100) * 60 + tripInfo!.returnTime!.intValue % 100 + (daysCount - 1) * 60 * 24
                        if let lastDay = tripInfo!.orderedDays.last as? BIDayInfo,
                           let lastLeg = lastDay.orderedLegs.last as? BILegInfo {
                            lastLeg.arriveMinutes = NSNumber(value: time)
                        }
                    }
                // Go to next line in file info.
                lineRange.location = lineRange.location + lineRange.length
                lineRange.location = 0
            }
        }
        return tripInfo
    }
    
    private func calculateFARigValue(minRigVal:Float, line: BILine, reprocessing:Bool){
        if line.pay!.floatValue < minRigVal{
            if !reprocessing{
                line.lineRig = NSNumber(value: minRigVal - line.pay!.floatValue)
                line.pay = minRigVal as NSNumber
                line.vTpLPay = NSNumber(value: line.lineRig!.floatValue + line.vVacationPay!.floatValue)
            }else{
                if self.includeDroppedTrips!{
                    line.lineRig = NSNumber(value: minRigVal - line.pay!.floatValue)
                    line.pay = minRigVal as NSNumber
                    line.vTpLPay = NSNumber(value: line.lineRig!.floatValue + line.vVacationPay!.floatValue)
                }
            }
        }
    }
    
    private func calculateFAReserveRigValue(minRigVal:Float, line: BILine, reprocessing:Bool){
        var lineRigValue:Float = 0
        if let rig = line.lineRig, rig.floatValue != 0 {
            lineRigValue = (rig.floatValue)
        }
        let payValue = line.pay!.floatValue - lineRigValue
        if line.pay!.floatValue != minRigVal{
            line.pay = payValue as NSNumber
        }
        if line.pay!.floatValue < minRigVal{
            if !reprocessing{
                line.lineRig = NSNumber(value: minRigVal - line.pay!.floatValue)
                line.pay = minRigVal as NSNumber
                line.vTpLPay = NSNumber(value: line.lineRig!.floatValue + line.vVacationPay!.floatValue)
            }else{
                if self.includeDroppedTrips!{
                    line.lineRig = NSNumber(value: minRigVal - line.pay!.floatValue)
                    line.pay = minRigVal as NSNumber
                    line.vTpLPay = NSNumber(value: line.lineRig!.floatValue + line.vVacationPay!.floatValue)
                }
            }
        }
    }
    
    private func readTextFiles() -> Bool{
        let directoryURL = BIBidInfo().downloadDirectory()
        
        //Cover Letter
        var textFileURL = directoryURL.appendingPathComponent(self.coverLetterFileName())
        var text = ""
        if self.isFABid(){
            text = try! String(contentsOf: textFileURL, encoding: .ascii)
        }else{
            text = try! String(contentsOf: textFileURL, encoding: .utf8)
            if text.isEmpty{
                text = try! String(contentsOf: textFileURL, encoding: .windowsCP1252)
            }
        }
        if !text.isEmpty{
            self.bidPeriod?.addTextFile(withText: text, name: "Cover Letter")
        }else{
            if AppState.shared.isMockData{
                return true
            }
            return false
        }
        
        //Seniority List
        textFileURL = directoryURL.appendingPathComponent(self.seniorityListFileName())
        text = try! String(contentsOf: textFileURL, encoding: .utf8)
        if text.isEmpty{
            text = try! String(contentsOf: textFileURL, encoding: .windowsCP1252)
        }
        if !text.isEmpty{
            self.bidPeriod?.addTextFile(withText: text, name: "Seniority List")
        }else{
            //handle error
            return false
        }
        
        //Lines text
        textFileURL = directoryURL.appendingPathComponent(self.linesTextFilename())
        text = try! String(contentsOf: textFileURL, encoding: .utf8)
        if !text.isEmpty{
            self.bidPeriod?.addTextFile(withText: text, name: "Lines Text")
        }else{
            //handle error
            return false
        }
        
        //Trips Text
        textFileURL = directoryURL.appendingPathComponent(self.tripsTextFilename()!)
        text = try! String(contentsOf: textFileURL, encoding: .utf8)
        if !text.isEmpty{
            self.bidPeriod?.addTextFile(withText: text, name: "Trips Text")
        }else{
            //handle error
            return false
        }
        
        //FA Memo text
        if self.isFABid(){
            textFileURL = directoryURL.appendingPathComponent(self.faMemoTextFilename())
            text = try! String(contentsOf: textFileURL, encoding: .ascii)
            if !text.isEmpty{
                self.bidPeriod?.addTextFile(withText: text, name: "FA Memo")
            }
        }
        
        //Save context
        let moc = dataSource.managedObjectContext
        if moc.hasChanges {
            do{
                try moc.save()
            }catch{
                print("Error saving context: \(error)")
                return false
            }
        }
        return true
    }
    
    private func startOfMonth() -> Date? {
            var calendar = Calendar(identifier: .gregorian)
            calendar.locale = Locale.current
            calendar.timeZone = TimeZone(identifier: "GMT")!
     
            let isFA = self.bidPeriod?.isFABid() ?? false
            let monthValue = self.bidPeriod?.month?.intValue
            let yearValue = self.bidPeriod?.year?.intValue
     
            var day = 1
            var month = monthValue ?? 1
            let year = yearValue ?? 2000
     
            if isFA && monthValue == 2 {
                day = 31
                month = 1
            } else if isFA && monthValue == 3 {
                day = 2
            }
     
            var components = DateComponents()
            components.day = day
            components.month = month
            components.year = year
            components.hour = 0
            components.minute = 0
            components.second = 0
     
            return calendar.date(from: components)
        }
     
     
    private func endOfMonth() -> Date? {
            var calendar = Calendar(identifier: .gregorian)
            calendar.locale = Locale.current
            calendar.timeZone = TimeZone(identifier: "GMT")!
     
            let isFA = self.bidPeriod?.isFABid() ?? false
            let monthValue = self.bidPeriod?.month?.intValue ?? 1
            let yearValue = self.bidPeriod?.year?.intValue ?? 2000
     
            // Start of the current month
            var startComponents = DateComponents()
            startComponents.day = 1
            startComponents.month = monthValue
            startComponents.year = yearValue
            startComponents.hour = 0
            startComponents.minute = 0
            startComponents.second = 0
     
            guard let startOfMonth = calendar.date(from: startComponents) else {
                return nil
            }
     
            // Move to the first day of next month, then subtract one day
            var adjustComponents = DateComponents()
            adjustComponents.month = 1
            adjustComponents.day = -1
     
            guard var lastDayOfMonth = calendar.date(byAdding: adjustComponents, to: startOfMonth) else {
                return nil
            }
     
            // Special FA rules
            if isFA && monthValue == 2 {
                // February → March 1
                lastDayOfMonth = lastDayOfMonth.addingTimeInterval(1 * 24 * 60 * 60)
            } else if isFA && monthValue == 1 {
                // January → Jan 30
                lastDayOfMonth = lastDayOfMonth.addingTimeInterval(-1 * 24 * 60 * 60)
            }
     
            return lastDayOfMonth
        }
    
    private func coverLetterFileName() -> String {
        let bidRoundStr: String
        if isFirstRoundBid() {
            bidRoundStr = "C"
        } else {
            bidRoundStr = isFABid() ? "CR" : "R"
        }
        return "\(textFileNameBase())\(bidRoundStr).TXT"
    }
    
    private func seniorityListFileName() -> String {
        let bidRoundStr: String
        if isFirstRoundBid() {
            bidRoundStr = "S"
        } else {
            bidRoundStr = isFABid() ? "SR" : "R"
        }
        return "\(textFileNameBase())\(bidRoundStr).TXT"
    }
    
    private func linesTextFilename() -> String {
        // 'N' for second round, 'L' for first round
        let bidRoundChar: Character = isSecondRoundBid() ? "N" : "L"
        return "\(textFileNameBase())\(bidRoundChar).TXT"
    }
    
    private func textFileNameBase() ->String{
        return "\(self.dataSource.base)\(self.dataSource.position.shortName)"
    }
    
    private func tripsTextFilename() -> String? {
        if isSecondRoundBid() && !isFABid() {
            return nil
        }
        let tripTextChar: Character = (isSecondRoundBid() && isFABid()) ? "T" : "P"
        return "\(textFileNameBase())\(tripTextChar).TXT"
    }
    
    private func faMemoTextFilename() -> String {
        let faMemoSuffix = (isSecondRoundBid() && isFABid()) ? "OR" : "O"
        return "\(textFileNameBase())\(faMemoSuffix).TXT"
    }
    
    private func isFABid() -> Bool {
        let isFABid = BICrewPositionType.FlightAttendant.rawValue == self.dataSource.position.rawValue
        return isFABid
    }
    private func isFirstRoundBid() -> Bool {
        let isFirstRoundBid = dataSource.round == 1
        return isFirstRoundBid
    }
    
    private func isSecondRoundBid() -> Bool {
        let isSecondRoundBid = dataSource.round == 2
        return isSecondRoundBid
    }
    
    func getEquipmentType(type: String) -> String {
        let type700 = ["73W", "73R", "7S7", "7R7"]
        let type800 = ["73H", "7S8", "738", "7R8"]
        let type8Max = ["7M8", "7U8", "7T8", "7V8"]

        if type700.contains(type) {
            return "7" // Equipment 700
        } else if type800.contains(type) {
            return "8" // Equipment 800
        } else if type8Max.contains(type) {
            return "6" // Equipment 8Max
        } else {
            return ""  // Default case
        }
    }
    
    private func matchesTripNumberFormat(tripNumber:String) ->Bool{
        return tripNumber.range(of: tripNumberRegex, options: .regularExpression) != nil
    }
    
    private func isDigitString(_ string: String, trimWhitespace: Bool) -> Bool {
        let trimmed = trimWhitespace ? string.trimmingCharacters(in: .whitespaces) : string
        return trimmed.rangeOfCharacter(from: nonDigitCharacters) == nil
    }
    
    func getDay(from date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        dateFormatter.dateFormat = "EEEE"
        return dateFormatter.string(from: date)
    }
}
