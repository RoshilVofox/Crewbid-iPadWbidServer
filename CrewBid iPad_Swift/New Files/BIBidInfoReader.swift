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
    
    var trips:[String:Any] = [:]
    var dhStartCities:[String] = []
    var dhEndCities:[String] = []
    let tripNumberRegex = "[A-Z]{2}[1-9A-Z]{2}"
    let cityRegex = "[A-Z]{3}"
    var cityPredicate:NSPredicate?
    var tripNumberPredicate:NSPredicate?
    var tripsCount:Float = 0
    var linesCount:Float = 0
    var bidPeriod:BIBidPeriod?
    let calendarData = BICalendarData()
    let app = UIApplication.shared.delegate as! AppDelegate
    var thanksgivingDay: UInt = 0
    var includeDroppedTrips:Bool?
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
//                success = self.readLinesFA()
//                if success{ print("Done Reading Lines FA")}
            }
            
            //needs code here
            
        }else{
            success = self.readTrips()
            if success{
//                print("Done Reading Trips")
//                success = self.readLines()
//                if success{print("Done Reading Lines")}
            }
            
            //needs code here
        }
    }
    
    
    private func initializeReadingVariables(){
        tripNumberPredicate = NSPredicate(format: "SELF MATCHES %@", tripNumberRegex)
        cityPredicate = NSPredicate(format: "SELF MATCHES %@", cityRegex)
    }
    
    //Read Trips file
    private func readTrips() -> Bool{
        return true
    }
    
    //Read Lines file
    private func readLines() -> Bool{
        return true
    }
    
    //Read Trips file FA
    private func readTripsFA() -> Bool{
        var success = true
        let moc = CoreDataManager().persistentContainer.newBackgroundContext()
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
                    let departMinutes = Int(digits)! - 1440
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
                    let arriveMinutes = Int(digits)! - 1440
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
    
    //Read Lines file FA
    private func readLinesFA() -> Bool{
        var success = true
        let moc = CoreDataManager.shared.persistentContainer.newBackgroundContext()
        let linesDataFileURL = BIBidInfo().downloadDirectory().appendingPathComponent(self.lineFileName)
        if !FileManager.default.fileExists(atPath: linesDataFileURL.path){
            return false}
        do{
            let linesData = try NSString(contentsOf: linesDataFileURL, encoding: String.Encoding.utf8.rawValue)
            
     

            
            var numberRange = NSRange(location: 4, length: 3)
            let storedValue = UserDefaults.standard.string(forKey: "PSFileFormatChange")
            if storedValue != nil {
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
//            var prevLine:BILine? = nil
            
            while moreLinesToRead{
                
                //Start new line
                if lineFile.hasPrefix("C"){
                    counter += 1
                    if counter%10 == 0{
                        if moc.hasChanges{
                            do{
                                try moc.save()
                            }catch{
                                print("Error saving context: \(error)")
                                //handle error
                                success = false
                                return false
                            }
                        }
                    }
                    if (line != nil){
                        self.initDerivedPropertiesForLine(line: line!, isReprocessing: false)
//                        prevLine = line
                    }
                    
                    digits = lineFile.substring(with: numberRange) as String
                    if !self.isDigitString(digits, trimWhitespace: true){
                        //handle error
                        success = false
                        return false
                    }
                    
                    line = BILine(context: moc)
                    let bidPeriod = try moc.existingObject(with: self.bidPeriod!.objectID) as! BIBidPeriod              // crashes due to nil value need to check
                    line?.bidPeriod = bidPeriod
                    bidPeriod.bidByEmpID = self.dataSource.employeeNumber
                    line?.number = Int(digits)! as NSNumber
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
                    blockMinutes = Int(digits)! * 60
                    digits = lineFile.substring(with: blockMinutesRange)
                    if !self.isDigitString(digits, trimWhitespace: true){
                        //handle error
                        success = false
                        return false
                    }
                    blockMinutes += Int(digits)!
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
                    if !self.readTripsForLine(line: line!, record: lineFile, isReserve: false){
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
        return true
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
        let moc = CoreDataManager.shared.persistentContainer.newBackgroundContext()
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
        let moc = CoreDataManager.shared.persistentContainer.newBackgroundContext()
        var tripInfo:BITripInfo?
        var trip:BITrip?
        let tripInterval = 19
        var tripNumRange = NSRange(location: 0, length: 0)
        var tripDateRange = NSRange(location: 0, length: 0)
        var tripStartDayRange = NSRange(location: 0, length: 0)
//        var tripMonthDateRange = NSRange(location: 0, length: 0)
//        var tripYearRange = NSRange(location: 0, length: 0)
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
//            tripMonthDateRange = NSRange(location: 19, length: 3)
//            tripYearRange = NSRange(location: 22, length: 2)
            
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
                let startIndex = tripNumber.index(tripNumber.startIndex, offsetBy: 1)
                let endIndex = tripNumber.index(startIndex, offsetBy: 3)
                let tripNumberSuffix = String(tripNumber[startIndex..<endIndex])
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
                let departHHMM = BITrip.staticTime(for: trip!, line: line, key: "depart", timeZone: timeZoneStr!)
                
                if departHHMM != nil{
                    
                    //parse hours and minutes from the "HHmm" format
                    let hourString = departHHMM?.substring(to: 2)
                    let minuteString = departHHMM?.substring(to: 2)
                    let hour = Int(hourString!)
                    let minute = Int(minuteString!)
                    
                    // Create calendar and components from original date
                    var calendar = Calendar(identifier: .gregorian)
                    calendar.locale = .current
                    calendar.timeZone = TimeZone(identifier: "GMT")!
                    
                    var dateComponents = calendar.dateComponents([.day,.month,.year], from: trip?.startDate ?? Date())
                    dateComponents.hour = hour
                    dateComponents.minute = minute
                    
                    trip?.startDate = calendar.date(from: dateComponents)
                }
                let arriveHHMM = BITrip.staticTime(for: trip!, line: line, key: "arrive", timeZone: timeZoneStr!)
                
                if arriveHHMM != nil{
                    
                    let hourString = arriveHHMM?.substring(to: 2)
                    let minuteString = arriveHHMM?.substring(to: 2)
                    let hour = Int(hourString!)
                    let minute = Int(minuteString!)
                    
                    // Create calendar and components from original date
                    var calendar = Calendar(identifier: .gregorian)
                    calendar.locale = .current
                    calendar.timeZone = TimeZone(identifier: "GMT")!
                    
                    var dateComponents = calendar.dateComponents([.day,.month,.year], from: trip?.endDate ?? Date())
                    dateComponents.hour = hour
                    dateComponents.minute = minute
                    
                    trip?.endDate = calendar.date(from: dateComponents)
                    
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
//            tripMonthDateRange = NSRange(location: 18, length: 3)
//            tripYearRange = NSRange(location: 21, length: 2)
            
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
                    trip.startDay = Int(digits) as? NSNumber
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
    private func matchesTripNumberFormat(tripNumber:String) ->Bool{
        return tripNumber.range(of: tripNumberRegex, options: .regularExpression) != nil
    }
    private func isDigitString(_ string: String, trimWhitespace: Bool) -> Bool {
        let trimmed = trimWhitespace ? string.trimmingCharacters(in: .whitespacesAndNewlines) : string
        return !trimmed.isEmpty && trimmed.allSatisfy { $0.isNumber }
    }
}
