//
//  BIBidInfoReader.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 20/05/25.
//

import Foundation
import CoreData


class BIBidInfoReader{
    let tripFileName = "TRIPS"
    let lineFileName = "PS"
    let dataSource = GlobalBidInfo.shared
    let moc = CoreDataManager.shared.persistentContainer.newBackgroundContext()
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
    let calendarData = BICalendarData()
    var thanksgivingDay: UInt = 0
    var includeDroppedTrips:Bool?
    var intlCities:[String:Any] = [:]
//    var moc:NSManagedObjectContext?
    
    func readBidData(){
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
                if success{ print("Done Reading Lines FA")}
            }
            
            //needs code here
            
        }else{
            success = self.readTrips()
            if success{
                print("Done Reading Trips")
                
                success = self.readLines()
                if success{
                    print("Done Reading Lines")
                }
                
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: Notification.Name("CloseProgressView"), object: nil)
                }
            }
            
            //needs code here
        }
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
        DispatchQueue.main.sync {
            let app = UIApplication.shared.delegate as! AppDelegate
            isHistoric = app.isHistoricBid as NSNumber
        }
        self.bidPeriod = BIBidPeriod(context: self.moc)
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
//        self.intlCities = UserDefaults.standard.object(forKey: kCBInternationalCitiesDict) as! [String : Any]
        //need to create the cities list
        
        self.bidPeriod?.isAllLinesTrashed = false
        
    }
    
    //MARK: Read Trips file - done
    private func readTrips() -> Bool{
        var success = true
        
        let moc = self.moc
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
                    if !self.readDaysInfoTripsInfoRecord2(tripInfo: tripInfo!, record2: info, context: moc){
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
                            if !self.readLegsInfoForTripInfo(tripInfo: tripInfo!, record5: record5, record6: record6, context: moc){
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
    
    //MARK: Read Lines file - done
    private func readLines() -> Bool{
        var success = true
        let moc = self.moc
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
    
    //MARK: Read Trips file FA
    private func readTripsFA() -> Bool{
        var success = true
        let moc = self.moc
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
                //neeeds code
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
                    //PAY
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
                    //MARK: needs code
                    
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
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name("CloseProgressView"), object: nil)
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
        let moc = self.moc
        let linesDataFileURL = BIBidInfo().downloadDirectory().appendingPathComponent(self.lineFileName)
        if !FileManager.default.fileExists(atPath: linesDataFileURL.path){
            return false}
        do{
            let linesData = try NSString(contentsOf: linesDataFileURL, encoding: String.Encoding.utf8.rawValue)

            var numberRange = NSRange(location: 4, length: 3)
            let storedValue = UserDefaults.standard.string(forKey: "PSFileFormatChange")
            if storedValue != nil {
                DispatchQueue.main.async {
                    let app = UIApplication.shared.delegate as! AppDelegate
                    if !app.isHistoricBid{
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
                        dateComponents1.month = app.mockDataMonth
                        dateComponents1.year = app.mockDataYear
                        
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
            var prevLine:BILine? = nil
            
            while moreLinesToRead{
                
                //Start new line
                if lineFile.hasPrefix("C"){
                    counter += 1
                    if let lineNum = line?.number{
                        print("Line num: \(lineNum)")
                    }else{
                        print("Line num is nil")
                    }
                    //MARK:  need to check
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
                        prevLine = line
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
        }catch{
            print("Error reading line file: \(error.localizedDescription)")
        }
        return success
    }

    
    private func initDerivedPropertiesForLine(line:BILine, isReprocessing:Bool){
        self.thanksgivingDay = CBUtils.thanksgivingDay(for: self.bidPeriod?.year?.intValue ?? 2025)
        if isReprocessing{
            line.vTpLPay = NSNumber(value: (line.lineRig?.floatValue ?? 0) + (line.vVacationPay?.floatValue ?? 0))
            if self.includeDroppedTrips!{
                line.pay = line.actualPay
                line.tripTfp = line.actualPay
                line.blockMinutes = line.actualBlockMinutes
                line.vTpLPay = line.lineRig
            }else if line.vTpLPay as! Int > 0{
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
        let moc = self.moc
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
        }
    }
    
    private func readTripsForLine(line:BILine, record:NSString, isReserve:Bool) -> Bool{
        var success = true
        let moc = self.moc
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
                        //PM reseeve
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
                trip?.startDate = self.calendarData.date(for: tripDate!)
            }
            trip?.tripStartDay = self.calendarData.getDay(from: (trip?.startDate)!)
            trip?.endDate = self.calendarData.dateforDayOfMonth((trip?.startDay?.intValue)!+((trip?.info?.orderedDays.count)! - 1))
            
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
                    let tripDate = dateFormatter.date(from: "12\(dateStr)")
                    if (tripDate != nil){
                        trip.startDate = self.calendarData.date(for: tripDate!)
                    }
                    trip.tripStartDay = self.calendarData.getDay(from: trip.startDate ?? Date())
                    trip.endDate = self.calendarData.dateforDayOfMonth((trip.startDay?.intValue)!+((trip.info?.orderedDays.count)! - 1))
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
    private func readDaysInfoTripsInfoRecord2(tripInfo:BITripInfo, record2:String, context:NSManagedObjectContext) -> Bool{
        var prevDay:BIDayInfo?
        var overNightsInBase = 0
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
                let dayInfo = BIDayInfo(context: context)
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
    private func readLegsInfoForTripInfo(tripInfo:BITripInfo, record5:String, record6:String, context:NSManagedObjectContext) -> Bool{
        var day = tripInfo.firstDay
        var prevLeg : BILegInfo?
        //Get max possible number of legs in record5 and 6
        let maxRecord5Legs = record5.length/legRecord5Interval
        let maxRecord6Legs = record6.length/legRecord6Interval
        let maxLegs = min(maxRecord5Legs, maxRecord6Legs)
        
        //Read the legs
        for legIndex in 0..<maxLegs{
            let leg = BILegInfo(context: context)
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
        return true
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
}
