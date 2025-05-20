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
    let lineFileNamee = "PS"
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
    func readBidData(){
        if !self.isFABid() && self.isSecondRoundBid(){
            // check paper bid user vacation
        }
        self.initializeReadingVariables()
//        var success:Bool = false
        if self.isFABid(){
            tripsCount = round(tripsCount/1.9145)
            linesCount = round(linesCount/8.6995)
        }else{
            tripsCount = round(tripsCount/1.9145)
            linesCount = round(linesCount/3.15)
        }
        if self.readTripsFA(){
            print("Done Reading Trips")
        }
    }
    private func initializeReadingVariables(){
        tripNumberPredicate = NSPredicate(format: "SELF MATCHES %@", tripNumberRegex)
        cityPredicate = NSPredicate(format: "SELF MATCHES %@", cityRegex)
    }
    
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
                        trips[(tripInfo?.number)!] = tripInfo!
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
                    var tripPay:Float = digits.floatValue/60
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
                    //needs code
                    
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
                    
                    //needs more code
                }
                lineRange.location = Int(lineEnd)
                lineRange.length = 0
                tripsData.getLineStart(&start, end: &lineEnd, contentsEnd: &contentsEnd, for: lineRange)
                lineRange.location = Int(start)
                lineRange.length = Int(contentsEnd - start)
                fileString.setString(tripsData.substring(with: lineRange))
            }
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name("CloseProgressView"), object: nil)
            }
        } catch {
            print("Failed to read file: \(error)")
        }
        return true
    }
    private func readTrips(){
        
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
