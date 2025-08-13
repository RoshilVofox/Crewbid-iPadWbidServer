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
    let InternationalCityMinutes = 75
    let CityMinutes = 60
    var isNetworkNotAvailable = false
    var isSeniorityVacParsingFailed = false
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
    var pilotLines:[Int:Any] = [:]
    var seniorityPositionDetails:[String:Any] = [:]
    var arrOverNightCities:[String] = []
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

    func checkForSeniorityVacationAndReadBidInfo(completion: @escaping (Bool) -> Void){
        self.isNetworkNotAvailable = false
        self.isSeniorityVacParsingFailed = false
        
        let app = UIApplication.shared.delegate as! AppDelegate
        if app.connectedToInternet(){
            if app.objNetworkType == .free{
                self.isSeniorityVacParsingFailed = true
                let success = self.readBidData()
                if success{
                    NotificationCenter.default.post(name: Notification.Name("ParsingBid"), object: nil)
//                    CBVacationDownloader.shared.executeAutoDownload()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
//                        NotificationCenter.default.post(name: Notification.Name("ParsingVacation"), object: nil)
                        NotificationCenter.default.post(name: Notification.Name("CloseProgressView"), object: nil)
                        completion(true)
                    }
                }else{
                    completion(false)
                }
            }else{
                let url = URL(string: EndPoint.shared.GetAllSeniorityListFormatFromDB)
                let urlRequest = URLRequest(url: url!)
                
                let dataTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
                    
                    
                    if let error = error{
                        print("Error in retrieving data: \(error.localizedDescription)")
                        completion(false)
                        return
                        //handle error
                    }
                    if let data = data{
                        let httpResponse = response as! HTTPURLResponse
                        let range = response?.mimeType?.range(of: "application/json")
                        
                        if httpResponse.statusCode == 200 && range != nil{
                            do{
                                let responseArray = try JSONSerialization.jsonObject(with: data) as! [Any]
                                UserDefaults.standard.set(responseArray, forKey: KCBDefaultSeniorityListTableDBValues)
                                
                                for i in 0..<responseArray.count{
                                    let dict = responseArray[i] as! [String:Any]
                                    let position = self.dataSource.position.shortName
                                    
                                    if dict["Position"] as! String == position && dict["Round"] as! Int == self.dataSource.round{
                                        self.seniorityPositionDetails = dict
                                        break
                                    }
                                }
                                let success = self.readBidData()
                                if success { NotificationCenter.default.post(name:Notification.Name("ParsingBid"), object: nil)
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        NotificationCenter.default.post(name: Notification.Name("ParsingVacation"), object: nil)
                                        NotificationCenter.default.post(name: Notification.Name("CloseProgressView"), object: nil)
                                        completion(true)
                                    }
                                }else{
                                    completion(false)
                                }
                                
                            }catch{
                                print("JSON parsing error: \(error.localizedDescription)")
                                self.isNetworkNotAvailable = true
                                completion(false)
                            }
                        }else{
                            self.isNetworkNotAvailable = true
                            completion(false)
                        }
                    }else{
                        self.isNetworkNotAvailable = true
                        completion(false)
                    }
                }
                dataTask.resume()
            }
        }else{
            self.isNetworkNotAvailable = true
            let success = self.readBidData()
            if success{
                NotificationCenter.default.post(name: Notification.Name("ParsingBid"), object: nil)
//                CBVacationDownloader.shared.executeAutoDownload()
//                NotificationCenter.default.post(name: Notification.Name("ParsingVacation"), object: nil)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    NotificationCenter.default.post(name: Notification.Name("CloseProgressView"), object: nil)
                    completion(true)
                }
            }else{
                completion(false)
            }
        }
        
    }

    
    private func readBidData() ->Bool{
        if !self.isFABid() && self.isSecondRoundBid(){
            self.checkPaperBidUserVacation()
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
                }
                if success{
                  success = self.addDefaultFilterRules(context:dataSource.managedObjectContext)
                }
                if success{
                    if AppState.shared.isHistoricBid{
                        success = true
                    }else{
                        print("Reading text files")
                        success = self.readTextFiles()
                    }
                }
                if success && self.isFirstRoundBid(){
                    self.vacationScan()
                }
                if success && self.isSecondRoundBid(){
                    self.vacationScan()
                }
            }
        }
        else{
            success = self.readTrips()
            if success{
                print("Done Reading Trips")
                success = self.readLines()
                if success{
                    print("Done Reading Lines")
                }
            }
                if success && self.isSecondRoundBid(){
                    success = self.addSecondRoundTripsForBidPeriod()
                }
                if success{
                        if AppState.shared.isHistoricBid{
                            success = true
                        }else{
                            success = self.readTripLegsPay()
                        }
                    if let lines = self.bidPeriod?.lines?.allObjects as? [BILine] {
                        for line in lines {
                            self.updateEndDateForRedEyeTrips(line: line)
                            if line.number == 305 {
                                print("")
                            }
                            self.initRigRelatedProperties(for: line, isReprocessing: false)
                        }
                    }
                }
                if success{
                    success = self.addDefaultFilterRules(context: dataSource.managedObjectContext)
                }
                
                if success{
                        if AppState.shared.isHistoricBid{
                            success = true
                        }else{
                            success =  self.readTextFiles()
                        }
                }
                if success{
                    if !self.seniorityPositionDetails.isEmpty{
                        self.parseSeniorityWithNewFormat(dictDetails: self.seniorityPositionDetails)
                    }else{
                        let seniorityDefaultTableValues = UserDefaults.standard.array(forKey: KCBDefaultSeniorityListTableDBValues)!
                        for i in 0..<seniorityDefaultTableValues.count{
                            let dict = seniorityDefaultTableValues[i] as! [String: Any]
                            let position = self.dataSource.position.shortName
                            if dict["Position"] as! String == position && dict["Round"] as! Int == self.dataSource.round{
                                self.seniorityPositionDetails = dict
                                break
                            }
                        }
                        if self.isNetworkNotAvailable{
                            self.parseSeniorityWithNewFormat(dictDetails: self.seniorityPositionDetails)
                        }
                        if self.isSeniorityVacParsingFailed{
                            self.parseSeniorityWithNewFormat(dictDetails: self.seniorityPositionDetails)
                        }
                    }
                }
            }
        if success{
            self.calculateWorkBlockDetails()
            let isQATest = UserDefaults.standard.string(forKey: "isQATest")
            self.bidPeriod?.isQAdata = isQATest
            let moc = self.dataSource.managedObjectContext
            if moc.hasChanges {
                do{
                    try moc.save()
                }catch{
                    print("Error saving context in parseBidData: \(error.localizedDescription)")
                    success = false
                }
            }
        }
        
        return success
    }
    
    private func vacationScan(){
        UserDefaults.standard.set("", forKey: "Errors")
        let pilotEidToSeniorityStandard = 31
        let faEidToSeniority = 70
        let pilotEidToNewHireCharacter = 29
        let pilotEidToSeniorityNewHire = 33
        var pilotEidToSeniority = 0
        let numCharsLineStandard = 80
        let numCharsLineNewHire = 42
        var numCharsLine = 0
        var text = ""
//        let coverLetter = (self.bidPeriod?.textFile(withName: "Seniority List"))! as BITextFile
        if let coverLetter = self.bidPeriod?.textFile(withName: "Seniority List") as? BITextFile {
            text = coverLetter.text!
        } else {
            print("")
        }
        var emp = 0
        if !AppState.shared.isSenioritySecretOn{
            emp = Int(self.defaultEmployeeNumber!)!
        }else{
            emp = Int(self.dataSource.userid)!
        }
        let secretSwitch = UserDefaults.standard.string(forKey: "SecretVDuserName") ?? ""
        if secretSwitch.count > 1{
            emp = Int("\(UserDefaults.standard.value(forKey: "SecretVDuserName")!)")!
        }
        let empString = String(emp)
        let regex = try! NSRegularExpression(pattern: "^0*", options: [])
        let range = NSRange(location: 0, length: empString.utf16.count)
        let str = regex.stringByReplacingMatches(in: empString, options: [], range: range, withTemplate: "")
        let employee = Int(str)
        let employeeNumber = NSNumber(value: employee!)
//        let text = coverLetter.text!
        var numberToScan = ""
        var stringToScan = ""
        var vacayString = ""
        
        var scanner = Scanner(string: text)
        let numCharSet = CharacterSet(charactersIn: "0123456789")
        let dateRangeCharSet = CharacterSet(charactersIn: "/-;")
        let newLineCharSet = CharacterSet(charactersIn: "\r\n")
        let letterCharSet = CharacterSet.letters
        
        // Set the hide vacation user default to NO each time you DL a new bid pack
        UserDefaults.standard.set(false, forKey: kCBHideVacationKey)
        
        if self.isFirstRoundBid(){
            if !self.isFABid(){
                // Add leading zeros to the employee number and pad with a space on each side
                numberToScan = String(format: "%06d", employeeNumber.intValue)
                stringToScan = " \(numberToScan) "
                vacayString = "VA"
            }else{
                numberToScan = String(format: "%zd", employeeNumber.intValue)
                stringToScan = "(\(numberToScan))"
                vacayString = "VAC"
            }
            _ = scanner.scanUpToString(stringToScan)
            
            if scanner.isAtEnd{
                UserDefaults.standard.set("You are not in the Domicile", forKey: "Errors")
            }else{
                let eidLoc = scanner.currentIndex.utf16Offset(in: text)
                var senNumber = ""
                if !self.isFABid(){
                    // Check if we've got a new hire
                    let location = text.index(text.startIndex, offsetBy: scanner.currentIndex.utf16Offset(in: text) - pilotEidToNewHireCharacter)
                    let newHireCharacter = String(text[location])

                    if newHireCharacter.rangeOfCharacter(from: numCharSet) == nil {
                        // It's NOT a number → New hire case
                        pilotEidToSeniority = pilotEidToSeniorityNewHire
                        numCharsLine = numCharsLineNewHire
                    } else {
                        // It's a digit → Standard case
                        pilotEidToSeniority = pilotEidToSeniorityStandard
                        numCharsLine = numCharsLineStandard
                    }
                    // Back up 31 or 33 characters to grab the seniority number
                    scanner.currentIndex = String.Index(utf16Offset: eidLoc - pilotEidToSeniority, in: text)
                    senNumber = scanner.scanCharacters(from: numCharSet)!
                    if senNumber != ""{
                        self.bidPeriod?.seniorityNumber = Int(senNumber) as? NSNumber
                    }else{
                        UserDefaults.standard.set("Seniority List Error", forKey: "Errors")
                    }
                }
                else{
                    // Back up to the next line to find the new line character
                    var offset = eidLoc - faEidToSeniority
                    if offset < 35 {
                        offset = eidLoc - 40
                    }
                    scanner.currentIndex = String.Index(utf16Offset: offset, in: text)

                    _ = scanner.scanUpToCharacters(from: newLineCharSet)
                    if scanner.isAtEnd {
                        return
                    }
                    var currentOffset = scanner.currentIndex.utf16Offset(in: text)
                    var searchRange = NSRange(location: currentOffset, length: 10)
                    var swiftRange = Range(searchRange, in: text)
                    var seniorityRange = text.range(of: "\\d{1}", options: .regularExpression, range: swiftRange)
                    if seniorityRange == nil {
                    // Back up a line and grab the seniority number there
                    let backOffset = scanner.currentIndex.utf16Offset(in: text) - 40
                        scanner.currentIndex = String.Index(utf16Offset: backOffset, in: text)
                    _ = scanner.scanUpToCharacters(from: newLineCharSet)
                    if scanner.isAtEnd {
                        return
                    }
                    currentOffset = scanner.currentIndex.utf16Offset(in: text)
                    searchRange = NSRange(location: currentOffset, length: 10)
                    swiftRange = Range(searchRange, in: text)
                    seniorityRange = text.range(of: "\\d{1}", options: .regularExpression, range: swiftRange)
                    if seniorityRange != nil {
                        let utf16Offset = seniorityRange!.lowerBound.utf16Offset(in: text)
                        scanner.currentIndex = String.Index(utf16Offset: utf16Offset, in: text)
                        senNumber = scanner.scanCharacters(from: numCharSet)!
                        self.bidPeriod?.seniorityNumber = Int(senNumber) as? NSNumber
                    }
                    }else{
                        let utf16Offset = seniorityRange!.lowerBound.utf16Offset(in: text)
                        scanner.currentIndex = String.Index(utf16Offset: utf16Offset, in: text)
                        if let scanned = scanner.scanCharacters(from: numCharSet), let seniorityNum = Int(scanned) {
                              self.bidPeriod?.seniorityNumber = NSNumber(value: seniorityNum)
                        } else {
                            DispatchQueue.main.async {
                                let alert = AlertService.showAlert(title: "Seniority List Error", message: "The Seniority List is improperly formatted, as a result, the vacation corrections for the month are currently not available. Please notify Support in the Contact us view.", actions: nil)
                                let topVC = AlertService.currentTopViewController()
                                topVC?.present(alert, animated: true)
                                        
                            }
                            return
                        }
                    }
                }
                if dataSource.managedObjectContext.hasChanges {
                    do{
                        try dataSource.managedObjectContext.save()
                    }catch{
                        print("Error in saving context in vacationScan: \(error.localizedDescription)")
                    }
                }
                // Scan backwards to see if there is any vacay
                // Create a scan expression to search for the vacation string plus a decimal digit
                // wildcard (i.e. VA1 or VAC1) in order to avoid people's names that contain VA or VAC
                let myRegex = "\(vacayString)\\d{1}"
                
                var vacayScanLength = 0
                var vacayScanStart = 0
                if self.isFABid(){
                    vacayScanLength = 50
                    vacayScanStart = eidLoc - vacayScanLength
                }else{
                    vacayScanLength = 15
                    vacayScanStart = eidLoc - vacayScanLength
                }
                
                var vacayRangeToSearch = NSRange(location: vacayScanStart, length: vacayScanLength)
                var swiftRange = Range(vacayRangeToSearch, in: text)
                var rangeOfFirstVacay = text.range(of: myRegex, options: .regularExpression, range: swiftRange)
                
                if rangeOfFirstVacay == nil {
                    // If it's a pilot bid, check to see if the vacay is on the next line
                    if !self.isFABid() {
                        let seniorityLocNextLine = eidLoc - pilotEidToSeniority + numCharsLine
                        // Jump ahead a line to check for a seniority number on the next line
                        let stringIndex = String.Index(utf16Offset: seniorityLocNextLine, in: text)
                        scanner.currentIndex = stringIndex
                        var newSeniority = scanner.scanCharacters(from: numCharSet)
                        if scanner.isAtEnd {
                            return
                        }
                        if newSeniority != nil{
                            // No vacation
                            self.bidPeriod?.containsVacay = false
                            return
                        }
                        // If no seniority number, see if the line contains vacay (lines can contain SP, LM, and MD)
                        vacayScanStart += numCharsLine
                        vacayRangeToSearch.location = vacayScanStart
                        swiftRange = Range(vacayRangeToSearch, in: text)
                        rangeOfFirstVacay = text.range(of: myRegex, options: .regularExpression, range: swiftRange)
                        
                        while newSeniority == nil && rangeOfFirstVacay == nil {
                            let stringIndex = String.Index(utf16Offset: numCharsLine, in: text)
                            scanner.currentIndex = stringIndex
                            newSeniority = scanner.scanCharacters(from: numCharSet)
                            if scanner.isAtEnd {
                                return
                            }
                            if newSeniority != nil{
                                self.bidPeriod?.containsVacay = false
                                return
                            }
                            vacayScanStart += numCharsLine
                            vacayRangeToSearch.location = vacayScanStart
                            // make sure that we don't go beyond the file length
                            if vacayScanStart + vacayScanLength < text.length {
                                swiftRange = Range(vacayRangeToSearch, in: text)
                                rangeOfFirstVacay = text.range(of: myRegex, options: .regularExpression, range: swiftRange)
                            }else{
                                // Something was wrong with the formatting, so clear the seniority number and return
                                self.bidPeriod?.seniorityNumber = nil
                                return
                            }
                            if rangeOfFirstVacay != nil {
                                break
                            }
                        }
                    }else{
                        // No vacation for that EID
                        self.bidPeriod?.containsVacay = false
                        return
                    }
                }
                while rangeOfFirstVacay != nil {
                    // Set the scanner at the end of the vacay string
                    let offset = rangeOfFirstVacay!.upperBound.utf16Offset(in: text) - 1
                    scanner.currentIndex = String.Index(utf16Offset: offset, in: text)
                    
                    var startMonth:String!
                    var startDay:String!
                    var endMonth:String!
                    var endDay:String!
                    
                    // Scan the start month
                    var oldLoc = scanner.currentIndex.utf16Offset(in: text)
                    startMonth = scanner.scanCharacters(from: numCharSet)
                    if scanner.isAtEnd || scanner.currentIndex.utf16Offset(in: text) == oldLoc {
                        return
                    }
                    oldLoc = scanner.currentIndex.utf16Offset(in: text)
                    // Scan the "/"
                    _ = scanner.scanCharacters(from: dateRangeCharSet)
                    if scanner.isAtEnd || scanner.currentIndex.utf16Offset(in: text) == oldLoc {
                        return
                    }
                    oldLoc = scanner.currentIndex.utf16Offset(in: text)
                    // Scan the start day
                    startDay = scanner.scanCharacters(from: numCharSet)
                    if scanner.isAtEnd || scanner.currentIndex.utf16Offset(in: text) == oldLoc {
                        return
                    }
                    oldLoc = scanner.currentIndex.utf16Offset(in: text)
                    // Scan the "- or /"
                    _ = scanner.scanCharacters(from: dateRangeCharSet)
                    if scanner.isAtEnd || scanner.currentIndex.utf16Offset(in: text) == oldLoc {
                        return
                    }
                    oldLoc = scanner.currentIndex.utf16Offset(in: text)
                    // Scan the end month
                    endMonth = scanner.scanCharacters(from: numCharSet)
                    if scanner.isAtEnd || scanner.currentIndex.utf16Offset(in: text) == oldLoc {
                        return
                    }
                    oldLoc = scanner.currentIndex.utf16Offset(in: text)
                    // Scan the "/"
                    _ = scanner.scanCharacters(from: dateRangeCharSet)
                    if scanner.isAtEnd || scanner.currentIndex.utf16Offset(in: text) == oldLoc {
                        return
                    }
                    oldLoc = scanner.currentIndex.utf16Offset(in: text)
                    // Scan the end day
                    endDay = scanner.scanCharacters(from: numCharSet)
                    if scanner.isAtEnd || scanner.currentIndex.utf16Offset(in: text) == oldLoc {
                        return
                    }
                    // Create the dates
                    let cal = self.calendarData.bidPeriodCalendar()
                    var comps = DateComponents()
                    comps.day = Int(startDay)
                    comps.month = Int(startMonth)
                    comps.hour = 12
                    comps.year = self.bidPeriod?.month?.intValue == 1 && startMonth == "12" ? (self.bidPeriod?.year!.intValue)! - 1 : self.bidPeriod?.year?.intValue
                    
                    let startDate = cal!.date(from: comps)!
                    
                    comps.day = Int(endDay)
                    comps.month = Int(endMonth)
                    comps.year = self.bidPeriod?.month?.intValue == 12 && endMonth == "1" ? (self.bidPeriod?.year!.intValue)! + 1 : self.bidPeriod?.year?.intValue
                    
                    let endDate = cal!.date(from: comps)!
                    
                    let vacay = BIVacation(context: self.dataSource.managedObjectContext)
                    vacay.bidPeriod = self.bidPeriod
                    vacay.startDate = startDate
                    vacay.endDate = endDate
                    
                    let length = self.calendarData.daysBetweenDate(fromDateTime: startDate, toDateTime: endDate) + 1
                    vacay.length = length as NSNumber
                    self.bidPeriod?.containsVacay = true
                    self.bidPeriod?.seniorityVacayAvailable = true
                    
                    if self.dataSource.managedObjectContext.hasChanges {
                        do{
                            try self.dataSource.managedObjectContext.save()
                        }catch{
                            print("Error saving in vacationScan: \(error.localizedDescription)")
                        }
                    }
                    
                    // Check for multiple vacations
                    
                    if self.isFABid(){
                        // Scan the semi-colon, if it exists
                        _ = scanner.scanCharacters(from: dateRangeCharSet)
                        let currentOffset = scanner.currentIndex.utf16Offset(in: text)
                        vacayRangeToSearch = NSRange(location: currentOffset, length: 10)
                    }else{
                        // Jump ahead a line to check for vacay on the next line
                        let updatedLocation = rangeOfFirstVacay!.lowerBound.utf16Offset(in: text) + 80
                        vacayRangeToSearch = NSRange(location: updatedLocation, length: 20)
                    }
                    swiftRange = Range(vacayRangeToSearch, in: text)
                    rangeOfFirstVacay = text.range(of: myRegex, options: .regularExpression, range: swiftRange)
                    
                    if rangeOfFirstVacay == nil {
                        // No multiple vacations
                        break
                    }
                    if !self.isFABid(){
                        // If it's a pilot bid, check to make sure there is no seniority number to the left of the vacay
                        // Find the crew member's seniority number
                        let vacationToSeniorityOffset = 17
                        let newIndex = text.index(rangeOfFirstVacay!.lowerBound, offsetBy: -vacationToSeniorityOffset, limitedBy: text.startIndex)
                        scanner.currentIndex = newIndex!
                        if let newSeniority = scanner.scanCharacters(from: numCharSet), !newSeniority.isEmpty{
                            // This is someone else's vacay
                            break
                        }
                    }
                }
            }
        }else{// Is Second Round Bid
            // Add leading zeros to the employee number and then pad with a space on each side
            numberToScan = String(format: "%d", employeeNumber.intValue)
            
            if self.isFABid(){
                stringToScan = "[\(numberToScan)]"
            }else{
                stringToScan = "\(numberToScan)"
            }
            vacayString = "VA"
            
            _ = scanner.scanUpToString(stringToScan)
            
            if scanner.isAtEnd {
                return
            }else{
                var vacationLine:String? = nil
                
                var endOfLineLoc = text.utf16.distance(from: text.utf16.startIndex, to: scanner.currentIndex)
                
                if vacationLine != nil && vacationLine != "" {
                    let eidLoc = text.utf16.distance(from: text.utf16.startIndex, to: scanner.currentIndex)
                    var senNumber:String? = nil
                    var offset = eidLoc - faEidToSeniority
                    if offset < 35 {
                        offset = eidLoc - 40
                    }
                    let safeIndex = text.utf16.index(text.utf16.startIndex, offsetBy: offset, limitedBy: text.utf16.endIndex)
                    scanner.currentIndex = safeIndex!
                    
                    _ = scanner.scanUpToCharacters(from: newLineCharSet)
                    if scanner.isAtEnd{
                        return
                    }
                    var currentOffset = scanner.currentIndex.utf16Offset(in: text)
                    var searchRange = NSRange(location: currentOffset, length: 10)
                    var swiftRange = Range(searchRange, in: text)
                    var seniorityRange = text.range(of: "\\d{1}", options: .regularExpression, range: swiftRange)
                    if seniorityRange == nil {
                        // Back up a line and grab the seniority number there
                        currentOffset = scanner.currentIndex.utf16Offset(in: text)
                        let newOffset = max(currentOffset - 40, 0)
                        scanner.currentIndex = text.index(text.startIndex, offsetBy: newOffset)
                        _ = scanner.scanUpToCharacters(from: newLineCharSet)
                        if scanner.isAtEnd {
                            return
                        }
                         searchRange = NSRange(location: currentOffset, length: 10)
                         swiftRange = Range(searchRange, in: text)
                         seniorityRange = text.range(of: "\\d{1}", options: .regularExpression, range: swiftRange)
                        if seniorityRange != nil {
                            scanner.currentIndex = seniorityRange!.lowerBound
                            senNumber = scanner.scanCharacters(from: numCharSet)!
                            vacationLine = scanner.scanUpToCharacters(from: newLineCharSet)
                            if senNumber != nil {
                                self.bidPeriod?.seniorityNumber = Int(senNumber!) as? NSNumber
                            }
                        }
                    }else{
                        scanner.currentIndex = seniorityRange!.lowerBound
                        senNumber = scanner.scanCharacters(from: numCharSet)!
                        vacationLine = scanner.scanUpToCharacters(from: newLineCharSet)
                        if senNumber != nil {
                            self.bidPeriod?.seniorityNumber = Int(senNumber!) as? NSNumber
                        }else{
                            DispatchQueue.main.async {
                                let alert = AlertService.showAlert(title: "Seniority List Error", message: "The Seniority List is improperly formatted, as a result, the vacation corrections for the month are currently not available. Please notify Support in the Contact us view.", actions: nil)
                                let topVC = AlertService.currentTopViewController()
                                topVC?.present(alert, animated: true)
                                        
                            }
                            return
                        }
                    }
                }
                
                let myRegex = "\(vacayString) \\d{1}"
                var rangeOfFirstVacay = vacationLine?.range(of: myRegex, options: .regularExpression)
                
                if rangeOfFirstVacay == nil {
                    // No vacation for that EID
                    self.bidPeriod?.containsVacay = false
                    return
                }
                
                while rangeOfFirstVacay != nil {
                    // Set the scanner at the end of the vacay string;
                    let offset = text.utf16.distance(from: text.utf16.startIndex, to: rangeOfFirstVacay!.upperBound) - 1
                    scanner.currentIndex = text.utf16.index(text.utf16.startIndex, offsetBy: offset)
                    
                    var startMonth = ""
                    var startDay = ""
                    var endMonth = ""
                    var endDay = ""
                    
                    var oldLoc = text.utf16.distance(from: text.utf16.startIndex, to: scanner.currentIndex)
                    vacationLine = String(vacationLine!.dropFirst(oldLoc))
                    scanner = Scanner(string: vacationLine!)
                    
                    // Scan the start day
                    startDay = scanner.scanCharacters(from: numCharSet)!
                    if scanner.isAtEnd || scanner.currentIndex.utf16Offset(in: text) == oldLoc {
                        return
                    }
                    oldLoc = scanner.currentIndex.utf16Offset(in: text)
                    
                    // Scan the start month
                    startMonth = scanner.scanCharacters(from: letterCharSet)!
                    if scanner.isAtEnd || scanner.currentIndex.utf16Offset(in: text) == oldLoc {
                        return
                    }
                    oldLoc = scanner.currentIndex.utf16Offset(in: text)
                    
                    // Scan the "-"
                    _ = scanner.scanCharacters(from: dateRangeCharSet)
                    if scanner.isAtEnd || scanner.currentIndex.utf16Offset(in: text) == oldLoc {
                        return
                    }
                    oldLoc = scanner.currentIndex.utf16Offset(in: text)
                    
                    // Scan the end day
                    endDay = scanner.scanCharacters(from: numCharSet)!
                    if scanner.isAtEnd || scanner.currentIndex.utf16Offset(in: text) == oldLoc {
                        return
                    }
                    oldLoc = scanner.currentIndex.utf16Offset(in: text)
                   
                    // Scan the end month
                    endMonth = scanner.scanCharacters(from: letterCharSet)!
                    if scanner.isAtEnd || scanner.currentIndex.utf16Offset(in: text) == oldLoc {
                        return
                    }
                    oldLoc = scanner.currentIndex.utf16Offset(in: text)
                    
                    //Create the dates
                    let df = DateFormatter()
                    df.dateFormat = "HHddMMyyyy"
                    df.timeZone = TimeZone(identifier: "US/Central")
                    
                    var year = self.bidPeriod?.month?.intValue == 1 && startMonth == "Dec" ? (self.bidPeriod?.year!.intValue)! - 1 : self.bidPeriod?.year?.intValue
                    
                    let startDateString = "\(startDay)\(startMonth)\(year!)"
                    year = self.bidPeriod?.month?.intValue == 12 && endMonth == "Jan" ? (self.bidPeriod?.year!.intValue)! + 1 : self.bidPeriod?.year?.intValue
                    
                    let endDateString = "\(endDay)\(endMonth)\(year!)"
                    
                    let startDate = df.date(from: "12\(startDateString)")
                    let endDate = df.date(from: "12\(endDateString)")
                    
                    let vacay = BIVacation(context: dataSource.managedObjectContext)
                    vacay.bidPeriod = self.bidPeriod
                    vacay.startDate = startDate
                    vacay.endDate = endDate
                    
                    let length = self.calendarData.daysBetweenDate(fromDateTime: startDate!, toDateTime: endDate!) + 1
                    vacay.length = length as NSNumber
                    self.bidPeriod?.containsVacay = true
                    self.bidPeriod?.seniorityVacayAvailable = true
                    
                    if dataSource.managedObjectContext.hasChanges {
                        do{
                            try dataSource.managedObjectContext.save()
                        }catch{
                            print("Error saving context in vacationScan: \(error.localizedDescription)")
                        }
                    }
                    
                    // Check for multiple vacations
                    vacationLine = String(vacationLine![scanner.currentIndex...])
                    rangeOfFirstVacay = vacationLine?.range(of: myRegex, options: .regularExpression)
                    
                    // If no more vacations were found on this line, check the next line
                    if rangeOfFirstVacay == nil {
                        // Reset the scanner text and set the location just before the end of line character
                        // and then scan past it to get to the new line
                        scanner = Scanner(string: text)
                        scanner.currentIndex = String.Index(utf16Offset: endOfLineLoc, in: text)
                        _ = scanner.scanCharacters(from: newLineCharSet)
                        
                        // Scan the full next line
                        vacationLine = scanner.scanUpToCharacters(from: newLineCharSet)
                        endOfLineLoc = text.utf16.distance(from: text.utf16.startIndex, to: scanner.currentIndex)
                        
                        // Look for a 4 digit decimal number as an indicator that the next line is a new employee
                        
                        let newEidRegex = "\\d{4}"
                        let newEidRange = vacationLine?.range(of: newEidRegex, options: .regularExpression)
                        
                        if newEidRange != nil {
                            // The new line is a new employee, break out of the while loop
                            break
                        }else{
                            // Back to the grind of the while loop, scan for vacations.
                            rangeOfFirstVacay = vacationLine?.range(of: myRegex, options: .regularExpression)
                        }
                    }
                }
            }
        }
    }
    
    private func parseSeniorityWithNewFormat(dictDetails:[String:Any]){
        let empNumEndPos = dictDetails["EmpIdEnd"] as! Int
        let vacEndPos = dictDetails["AbsenceDatesEnd"] as! Int
        let vacTypeStartPos = dictDetails["AbscenceTypeSt"] as! Int
        let EBGTypeStartPos = dictDetails["EbgSt"] as! Int
        var text = ""
        if let coverLetter = self.bidPeriod?.textFile(withName: "Seniority List") {
            text = coverLetter.text!
        } else {
            print("")
        }
        var emp = 0
        if !AppState.shared.isSenioritySecretOn{
            emp = Int(self.defaultEmployeeNumber!)!
        }else{
            emp = Int(self.dataSource.userid)!
        }
        
        let secretSwitch = String(format: "%@", UserDefaults.standard.string(forKey: "SecretVDuserName") ?? "")
        if secretSwitch.count > 1{
            emp = Int("\(UserDefaults.standard.value(forKey: "SecretVDuserName")!)")!
        }
        let empString = String(emp)
        let regex = try! NSRegularExpression(pattern: "^0*")
        let range = regex.rangeOfFirstMatch(in: empString, options: [], range: NSRange(location: 0, length: empString.utf16.count))
        let str = (empString as NSString).replacingCharacters(in: range, with: "")
        let employee = Int(str)!
        let employeeNumber = NSNumber(value: employee)
//        let text = coverLetter.text
        var stringToScan = ""
        var scanner = Scanner(string: text)
        let numCharSet = CharacterSet(charactersIn: "0123456789")
        let dateRangeCharSet = CharacterSet(charactersIn: "/-;")
        let letterCharSet = CharacterSet.letters
        
        // Set the hide vacation user default to NO each time you DL a new bid pack
        
        UserDefaults.standard.set(false, forKey: kCBHideVacationKey)
        if !self.isFABid(){
            stringToScan = String(format: " %ld ", employeeNumber.intValue)
        }
        // Scan all characters before employee number plus a space
        _ = scanner.scanUpToString(stringToScan)
        if scanner.isAtEnd{
            return
        }else{
            var senNumber:String? = nil
            if !self.isFABid(){
                var oldLoc = scanner.currentIndex
                _ = scanner.scanCharacters(from: numCharSet)
                if scanner.isAtEnd || scanner.currentIndex == oldLoc{
                    return
                }
                oldLoc = scanner.currentIndex
                let EBGPosition = (empNumEndPos - EBGTypeStartPos) + 1
                var currentOffset = text.distance(from: text.startIndex, to: scanner.currentIndex)
                let ebgOffset = currentOffset - EBGPosition

                if ebgOffset >= 0 && ebgOffset < text.utf16.count {
                    let ebgIndex = text.index(text.startIndex, offsetBy: ebgOffset)
                    let EBGCharacter = String(text[ebgIndex])

                    if EBGCharacter == "Y" {
                        bidPeriod?.containsEBG = true
                    }
                }
                if self.bidPeriod?.round?.intValue == 1 {
                    let paperBidCount = self.calculatePaperBidCountAboveCurrentUser(from: text)
                    self.bidPeriod?.paperBidCount = paperBidCount as NSNumber
                }
                
                let lenFileInfo = text.utf16.count
                var lineRange = NSRange(location: 0, length: 0)
                
                while lineRange.location < lenFileInfo{
                    lineRange = (text as NSString).lineRange(for: lineRange)
                    lineRange.location = lineRange.location + lineRange.length
                    lineRange.length = 0
                }
                
                let offset = oldLoc.utf16Offset(in: text) - empNumEndPos
                scanner.currentIndex = (text.utf16.index(text.startIndex, offsetBy: offset, limitedBy: text.utf16.endIndex)?.samePosition(in: text))!
                let seqLocation = scanner.currentIndex.utf16Offset(in: text) - 1
                senNumber = scanner.scanCharacters(from: numCharSet)!
                if senNumber != nil{
                    self.bidPeriod?.seniorityNumber = Int(senNumber!) as? NSNumber
                }else {
                    return
                }
                let vacEndPosition = seqLocation + (vacEndPos + 2)
                
                //VacationType start position
                let vacTypeStartPosition = seqLocation + vacTypeStartPos
                let vacScanLength = vacEndPosition - vacTypeStartPosition
                var vacScanStart = 0
                let vacTypeRangeToSearch = NSRange(location: vacTypeStartPosition, length: 2)
                let vacationType = (text as NSString).substring(with: vacTypeRangeToSearch)
                if self.dataSource.managedObjectContext.hasChanges {
                    do{
                        try self.dataSource.managedObjectContext.save()
                    }catch{
                        print("Error saving context in parseSeniorityWithNewFormat(): \(error.localizedDescription)")
                    }
                }
                var myRegex = String(format: "%@", vacationType)
                scanner = Scanner(string: text)
                _ = scanner.scanUpToString(stringToScan)
                oldLoc = scanner.currentIndex
                _ = scanner.scanCharacters(from: numCharSet)
                if scanner.isAtEnd || scanner.currentIndex == oldLoc {
                    return
                }
                oldLoc = scanner.currentIndex
                
                let employeeNoEndToVacationTypeStart = vacTypeStartPosition - (oldLoc.utf16Offset(in: text) + 1)
                vacScanStart = oldLoc.utf16Offset(in: text) + employeeNoEndToVacationTypeStart
                var vacRangeToSearch = NSRange(location: vacScanStart, length: vacScanLength)
                var arrayVacations:[String] = []
                scanner.currentIndex = (text.utf16.index(text.startIndex, offsetBy: vacScanStart, limitedBy: text.utf16.endIndex)?.samePosition(in: text))!
                let newSeniority = scanner.scanCharacters(from: numCharSet) ?? ""
                if scanner.isAtEnd{
                    // No vacation for that EID
                    self.bidPeriod?.containsVacay = false
                    return
                }
                if newSeniority != "" {
                    // No vacation for that EID
                    self.bidPeriod?.containsVacay = false
                    return
                }
                _ = scanner.scanUpToString("-")
                currentOffset = scanner.currentIndex.utf16Offset(in: text)
                let adjustedOffset = max(0, currentOffset - 9) // Prevent negative value
                vacRangeToSearch.location = adjustedOffset
                vacRangeToSearch.length = vacScanLength
                if vacRangeToSearch.location + vacRangeToSearch.length > text.length {
                    self.bidPeriod?.containsVacay = false
                    return
                }
                var vacation = (text as NSString).substring(with: vacRangeToSearch) as NSString
                scanner.currentIndex = text.utf16.index(text.utf16.startIndex, offsetBy: vacRangeToSearch.location).samePosition(in: text)!
                if vacation.contains(" VA"){
                    myRegex = "VA "
                    arrayVacations.append(vacation as String)
                }else if vacation.contains("CFV"){
                    myRegex = "CFV "
                    arrayVacations.append(vacation as String)
                }else if vacation.contains(" FV"){
                    myRegex = "FV "
                    arrayVacations.append(vacation as String)
                }
                
                if vacRangeToSearch.location + vacRangeToSearch.length <= text.utf16.count {
                    let regex = try! NSRegularExpression(pattern: myRegex)
                    let searchRange = NSRange(location: vacRangeToSearch.location, length: vacRangeToSearch.length)
                    let rangeOfFirstVacaysds = regex.rangeOfFirstMatch(in: text, options: [], range: searchRange)
                    if rangeOfFirstVacaysds.location == NSNotFound{
                        if self.isFABid(){
                            self.bidPeriod?.containsVacay = false
                            return
                        }
                    }
                }
                
                while newSeniority.isEmpty{
                    // If it's a pilot bid, check to see if the vacay is on the next line
                    let seniorityLocNextLine = text.index(scanner.currentIndex, offsetBy: vacScanLength)
                    scanner.currentIndex = seniorityLocNextLine
                    let newSeniority = scanner.scanCharacters(from: numCharSet)
                    if scanner.isAtEnd{
                        break
                    }
                    if newSeniority != nil{
                        // No vacation
                        break
                    }
                    
                    _ = scanner.scanUpToString("-")
                    currentOffset = scanner.currentIndex.utf16Offset(in: text)
                    let adjustedOffset = max(0, currentOffset - 9) // Prevent negative value
                    vacRangeToSearch.location = adjustedOffset
                    vacRangeToSearch.length = vacScanLength
                    if vacRangeToSearch.location + vacRangeToSearch.length > text.utf16.count{
                        break
                    }
                    
                    vacation = (text as NSString).substring(with: vacRangeToSearch) as NSString
                    scanner.currentIndex = text.utf16.index(text.utf16.startIndex, offsetBy: vacRangeToSearch.location).samePosition(in: text)!
                    if vacation.contains(" VA") && vacation.contains("-"){
                        myRegex = "VA "
                        arrayVacations.append(vacation as String)
                    }else if vacation.contains("CFV") && vacation.contains("-"){
                        myRegex = "CFV "
                        arrayVacations.append(vacation as String)
                    }else if vacation.contains(" FV") && vacation.contains("-"){
                        myRegex = "FV "
                        arrayVacations.append(vacation as String)
                    }
                }
                
                var vaCount = 0
                if myRegex == "VA " || myRegex == "FV " || myRegex == "CFV "{
                    for i in 0..<arrayVacations.count{
                        let vacayRangeToSearch1 = NSRange(location: 0, length: arrayVacations[i].length)
                        let subScanner = Scanner(string: arrayVacations[i])
                        if myRegex == "CFV "{
                            myRegex = (arrayVacations[i] as NSString).substring(with: NSRange(location: 0, length: 4))
                        }else{
                            myRegex = (arrayVacations[i] as NSString).substring(with: NSRange(location: 0, length: 3))
                        }
                        let rangeOfFirstVacay = (arrayVacations[i] as NSString).range(of: myRegex, range: vacayRangeToSearch1)
                        if rangeOfFirstVacay.location != NSNotFound {
                            vaCount += 1
                            if let rangeStart = Range(rangeOfFirstVacay, in: text) {
                                let newLocation = text.utf16.index(rangeStart.lowerBound, offsetBy: 3).samePosition(in: text)!
                                subScanner.currentIndex = newLocation
                            }
                            var startMonth:String?
                            var startDay:String?
                            var endMonth:String?
                            var endDay:String?
                            
                            var oldLoc = subScanner.currentIndex
                            startDay = subScanner.scanCharacters(from: numCharSet)
                            if subScanner.isAtEnd || subScanner.currentIndex == oldLoc {
                                return
                            }
                            oldLoc = subScanner.currentIndex
                            
                            let months = subScanner.scanCharacters(from: letterCharSet)
                            
                            startMonth = String(format: "%d", self.calendarData.monthNumber(from: months!)!)
                            
                            // Scan the "/"
                            _ = subScanner.scanCharacters(from: dateRangeCharSet)
                            if subScanner.isAtEnd || subScanner.currentIndex == oldLoc {
                                return
                            }
                            
                            oldLoc = subScanner.currentIndex
                            
                            endDay = subScanner.scanCharacters(from: numCharSet)
                            if subScanner.isAtEnd || subScanner.currentIndex == oldLoc {
                                return
                            }
                            
                        
                            let endMonths = subScanner.scanCharacters(from: letterCharSet)
                            
                            oldLoc = subScanner.currentIndex
                            
                            endMonth = String(format: "%d", self.calendarData.monthNumber(from: endMonths!)!)
                            
                            // Create the dates
                            let cal = self.calendarData.bidPeriodCalendar()
                            var comps = DateComponents()
                            comps.day = Int(startDay!)
                            comps.month = Int(startMonth!)
                            comps.hour = 12
                            comps.year = self.bidPeriod?.month?.intValue == 1 && Int(startMonth!) == 12 ? self.bidPeriod!.year!.intValue - 1 : self.bidPeriod?.year?.intValue
                            
                            let startDate = cal!.date(from: comps)!
                            
                            comps.day = Int(endDay!)
                            comps.month = Int(endMonth!)
                            comps.year = self.bidPeriod?.month?.intValue == 12 && Int(endMonth!) == 1 ? self.bidPeriod!.year!.intValue + 1 : self.bidPeriod?.year?.intValue
                            
                            let endDate = cal!.date(from: comps)!
                            
                            // Save Vacation in Vacations Entity
                            let vacay = BIVacation(context: self.dataSource.managedObjectContext)
                            vacay.bidPeriod = self.bidPeriod
                            vacay.startDate = startDate
                            vacay.endDate = endDate
                            vacay.vacationType = myRegex.trimmingCharacters(in: .whitespacesAndNewlines)
                            
                            // Save Vacation in VacationArrayFromServer Entity
                            
                            let vacayFS = VacationArrayFromServer(context: self.dataSource.managedObjectContext)
                            vacayFS.bidPeriod = self.bidPeriod
                            vacayFS.startDate = startDate
                            vacayFS.endDate = endDate
                            vacayFS.vacationType = myRegex.trimmingCharacters(in: .whitespacesAndNewlines)
                            
                            let length = self.calendarData.daysBetweenDate(fromDateTime: startDate, toDateTime: endDate) + 1
                            vacay.length = length as NSNumber
                            self.bidPeriod?.containsVacay = true
                            self.bidPeriod?.seniorityVacayAvailable = true
                            
                            if self.dataSource.managedObjectContext.hasChanges{
                                do{
                                    try self.dataSource.managedObjectContext.save()
                                }catch{
                                    print("Error saving context in parseSeniorityWithNewFormat: \(error.localizedDescription)")
                                }
                            }
                        }
                    }
                }else{
                    arrayVacations.removeAll()
                }
                
                if arrayVacations.isEmpty {
                    self.bidPeriod?.containsVacay = false
                    return
                }
                
                if vaCount == 0 {
                    self.bidPeriod?.containsVacay = false
                    return
                }else{
                    self.bidPeriod?.containsVacay = true
                    self.bidPeriod?.seniorityVacayAvailable = true
                }
                
                if self.dataSource.managedObjectContext.hasChanges{
                    do{
                        try self.dataSource.managedObjectContext.save()
                    }catch{
                        print("Error saving context in parseSeniorityWithNewFormat: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    private func calculatePaperBidCountAboveCurrentUser(from text: String) -> Int {
        let bidTypeStartPosition = 24 // 'P' position in each line
        var pCount = 0
        var seniorityEmployeeScanStarted = false

        // Try to find the current user's employee number
        let empNumber = self.dataSource.employeeNumber
        let rangeToUser = text.range(of: empNumber)!

        // Scan only the text before the employee number
        let scanString = String(text[..<rangeToUser.lowerBound])
        let lines = scanString.components(separatedBy: .newlines)
        
        for line in lines {
            if seniorityEmployeeScanStarted {
                if line.count >= bidTypeStartPosition {
                    let index = line.index(line.startIndex, offsetBy: bidTypeStartPosition - 1)
                    let bidTypeChar = line[index]
                    if bidTypeChar == "P" {
                        pCount += 1
                    }
                }
            }

            if line.hasPrefix("SQ") {
                seniorityEmployeeScanStarted = true
            }
        }

        // Check current user line (the line containing the emp number)
        let remainingLines = text.components(separatedBy: .newlines)
        if let currentLine = remainingLines.first(where: { $0.contains(empNumber) }),
           currentLine.count >= bidTypeStartPosition {
            let index = currentLine.index(currentLine.startIndex, offsetBy: bidTypeStartPosition - 1)
            let bidTypeChar = currentLine[index]
            if bidTypeChar == "P" {
                pCount -= 1
            }
        }

        return pCount
    }
    
    func calculateWorkBlockDetailsWithVacation(){
        if self.bidPeriod!.isVacationRemoved!.boolValue{
            self.calculateWorkBlockDetails()
            return
        }
        var tripStartDate:Date!
        var tripStartDateTakeOff:Date!
        var tripEndDate:Date!
        var tripEndDateOnly:Date!
        var previousTripEndDate:Date!
        var previousTripEndDateOnly:Date!
        var startDateTime:Date!
        var startDateTakeOffTime:Date!
        
        //Iterate Lines
        for case let line as BILine in self.bidPeriod!.lines!{
            self.removeExistingWorkBlock(line)
            //Initialize Trip Index
            var tripIndex = 0
            var back2backTripBlock = 0
            previousTripEndDate = nil
            let tripsData = line.trips!.allObjects
            let sortDescriptor = NSSortDescriptor(key: "startDate", ascending: true)
            let trips1 = (tripsData as NSArray).sortedArray(using: [sortDescriptor]) as! [BITrip]
            let biTrips = (tripsData as NSArray).sortedArray(using: [sortDescriptor])
            
            //Iterate trips in line
            var previousTrip :[String:Any]?
            var biPreviousTrip:BITrip?
            var arrFetchedTrip:[[String:Any]] = []
            
            // Need to regrnerate trip
            let trips = self.regenerateTrip(trips1)
            
            var oneDayWorkBlockCount = 0
            var twoDayWorkBlockCount = 0
            var threeDayWorkBlockCount = 0
            var fourDayWorkBlockCount = 0
            var briefMins = 60
            var debriefMins = 30
            
            for tripCount in 0..<trips.count{
                let biTrip = biTrips[tripCount] as! BITrip
                let trip = trips[tripCount]
                tripStartDate = self.getStartDateIncludeVacation(from: trip)
                tripStartDateTakeOff = self.getStartDateIncludeVacationWithTakeOff(from: trip)
                tripEndDate = self.getEndDateOfTripIncludeVacation(from: trip)
                tripEndDateOnly = self.getOnlyEndDateOfTripIncludeVacation(from: trip, biTrip: biTrip)
                if tripCount != 0 {
                    previousTrip = trips[tripCount-1]
                    biPreviousTrip = biTrips[tripCount-1] as? BITrip
                    previousTripEndDate = self.getEndDateOfTripIncludeVacation(from: previousTrip!)
                    previousTripEndDateOnly = self.getOnlyEndDateOfTripIncludeVacation(from: previousTrip!, biTrip: biPreviousTrip!)
                }
                if tripIndex <= 0 {
                    startDateTime = self.getStartDateIncludeVacation(from: trip)
                    startDateTakeOffTime = self.getStartDateIncludeVacationWithTakeOff(from: trip)
                }
                if let brief = trip["briefMinutes"] as? NSNumber {
                    briefMins = brief.intValue
                }
                if let debrief = trip["debriefMinutes"] as? NSNumber {
                    debriefMins = debrief.intValue
                }
                if back2backTripBlock == 0 && tripCount != 0 {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "MM/dd/yyyy HH:mm:ss"
                    dateFormatter.timeZone = TimeZone(identifier: "GMT")
                    startDateTime = self.getStartDateIncludeVacation(from: previousTrip!)
                    startDateTakeOffTime = self.getStartDateIncludeVacationWithTakeOff(from: previousTrip!)
                    if let brief = previousTrip!["briefMinutes"] as? NSNumber {
                        briefMins = brief.intValue
                    }
                }
                
                //Check its continues trip
                if previousTripEndDate == nil {
                    back2backTripBlock += 1
                    tripIndex += 1
                    arrFetchedTrip.append(trip)
                    if tripCount == trips.count-1 {
                        //Set WorkBlock Details
                        let workBlock1 = WorkBlockList(context: self.dataSource.managedObjectContext)
                        workBlock1.backToBackCount = back2backTripBlock as NSNumber
                        workBlock1.startDateTime = startDateTime
                        workBlock1.startDateTakeOffTime = startDateTakeOffTime
                        workBlock1.startDay = self.getDay(from: startDateTime)
                        workBlock1.endDateTime = tripEndDate
                        workBlock1.endDateOnly = tripEndDateOnly
                        workBlock1.briefMinutes = briefMins as NSNumber
                        workBlock1.deBriefMinutes = debriefMins as NSNumber
                        workBlock1.endDay = self.getDay(from: tripEndDateOnly)
                        workBlock1.line = line
                        
                        var workBlockDays:[BIDay] = []
                        
                        for trip1 in trips {
                            let trip1StartDate = self.getStartDateIncludeVacation(from: trip1)
                            let trip1EndDate = self.getEndDateOfTripIncludeVacation(from: trip1)
                            
                            if let days = trip1["BIDay"] as? [BIDay] {
                                    workBlockDays.append(contentsOf: days)
                                }
                            if startDateTime == trip1StartDate {
                                workBlockDays.removeAll()
                                if let days = trip1["BIDay"] as? [BIDay] {
                                        workBlockDays.append(contentsOf: days)
                                    }
                            }
                            if tripEndDate == trip1EndDate {
                                break
                            }
                        }
                        for day in workBlockDays {
                            let dayObj = BIDay(context: self.dataSource.managedObjectContext)
                            dayObj.date = day.date
                            dayObj.info = day.info
                            dayObj.workBlock = workBlock1
                        }
                        
                        let checkDomicile = self.calculateNMidCountWithVacation(from: arrFetchedTrip, workBlock: workBlock1)
                        workBlock1.nightINDomicile = checkDomicile as? NSNumber
                        back2backTripBlock = 0
                        tripIndex = 0
                        
                        let daysCOunt = self.calendarData.daysBetweenDateForWorkBlock(from: workBlock1.startDateTime!, to: workBlock1.endDateOnly!) + 1
                        switch daysCOunt {
                        case 1:oneDayWorkBlockCount += 1
                            break
                        case 2:twoDayWorkBlockCount += 1
                            break
                        case 3:threeDayWorkBlockCount += 1
                            break
                        case 4:fourDayWorkBlockCount += 1
                            break
                        default:break
                        }
                        
                        let triped = arrFetchedTrip.last!
                        arrFetchedTrip = []
                        arrFetchedTrip.append(triped)
                    }
                }else if self.checkIsContinuousTrip(currentTripStartDate: tripStartDate, previousTripEndDate: previousTripEndDate) {
                    back2backTripBlock += 1
                    tripIndex += 1
                    arrFetchedTrip.append(trip)
                    if tripCount == trips.count-1 {
                        //Set WorkBlock Details
                        let workBlock2 = WorkBlockList(context: self.dataSource.managedObjectContext)
                        workBlock2.startDateTime = startDateTime
                        workBlock2.startDateTakeOffTime = startDateTakeOffTime
                        workBlock2.startDay = self.getDay(from: startDateTime!)
                        workBlock2.endDateTime = tripEndDate
                        workBlock2.endDateOnly = tripEndDateOnly
                        workBlock2.briefMinutes = briefMins as NSNumber
                        workBlock2.deBriefMinutes = debriefMins as NSNumber
                        workBlock2.endDay = self.getDay(from: tripEndDateOnly)
                        workBlock2.line = line
                        
                        var workBlockDays:[BIDay] = []
                        for  trip1 in trips {
                            let trip1StartDate = self.getStartDateIncludeVacation(from: trip1)
                            let trip1EndDate = self.getEndDateOfTripIncludeVacation(from: trip1)
                            if let days = trip1["BIDay"] as? [BIDay] {
                                    workBlockDays.append(contentsOf: days)
                                }
                            if startDateTime == trip1StartDate {
                                workBlockDays.removeAll()
                                if let days = trip1["BIDay"] as? [BIDay] {
                                        workBlockDays.append(contentsOf: days)
                                    }
                            }
                            if tripEndDate == trip1EndDate{
                                break
                            }
                        }
                        
                        for  day in workBlockDays {
                            let dayObj = BIDay(context: self.dataSource.managedObjectContext)
                            dayObj.date = day.date
                            dayObj.info = day.info
                            dayObj.workBlock = workBlock2
                        }
                        
                        let checkDomicile = self.calculateNMidCountWithVacation(from: arrFetchedTrip, workBlock: workBlock2)
                        workBlock2.nightINDomicile = checkDomicile as? NSNumber
                        back2backTripBlock = 0
                        tripIndex = 0
                        
                        let daysCount = self.calendarData.daysBetweenDateForWorkBlock(from: workBlock2.startDateTime!, to: workBlock2.endDateOnly!) + 1
                        switch daysCount{
                        case 1:oneDayWorkBlockCount += 1
                            break
                        case 2:twoDayWorkBlockCount += 1
                            break
                        case 3:threeDayWorkBlockCount += 1
                            break
                        case 4:fourDayWorkBlockCount += 1
                            break
                        default:break
                        }
                        let triped = arrFetchedTrip.last!
                        arrFetchedTrip = []
                        arrFetchedTrip.append(triped)
                    }
                }else{
                    //Set WorkBlock Details
                    let workBlock3 = WorkBlockList(context: self.dataSource.managedObjectContext)
                    workBlock3.backToBackCount = back2backTripBlock as NSNumber
                    workBlock3.startDateTime = startDateTime
                    workBlock3.startDateTakeOffTime = startDateTakeOffTime
                    workBlock3.briefMinutes = briefMins as NSNumber
                    workBlock3.deBriefMinutes = debriefMins as NSNumber
                    workBlock3.startDay = self.getDay(from: startDateTime)
                    if tripIndex >= 0 {
                        workBlock3.endDateTime = previousTripEndDate
                        workBlock3.endDateOnly = previousTripEndDateOnly
                        workBlock3.endDay = self.getDay(from: previousTripEndDateOnly)
                    }else{
                        workBlock3.endDateTime = tripEndDate
                        workBlock3.endDay = self.getDay(from: tripEndDateOnly)
                    }
                    workBlock3.line = line
                    
                    var workBlockDays:[BIDay] = []
                    
                    for trip1 in trips {
                        let trip1EndDate = self.getEndDateOfTripIncludeVacation(from: trip1)
                        if let days = trip1["BIDay"] as? [BIDay] {
                                workBlockDays.append(contentsOf: days)
                            }
                        if previousTripEndDate == trip1EndDate{
                            break
                        }
                    }
                    for day in workBlockDays {
                        let dayObj = BIDay(context: self.dataSource.managedObjectContext)
                        dayObj.date = day.date
                        dayObj.info = day.info
                        dayObj.workBlock = workBlock3
                    }
                    
                    let checkDomicile = self.calculateNMidCountWithVacation(from: arrFetchedTrip, workBlock: workBlock3)
                    workBlock3.nightINDomicile = checkDomicile as? NSNumber
                    
                    let daysCount = self.calendarData.daysBetweenDateForWorkBlock(from: workBlock3.startDateTime!, to: workBlock3.endDateOnly!) + 1
                    switch daysCount{
                    case 1:oneDayWorkBlockCount += 1
                        break
                    case 2:twoDayWorkBlockCount += 1
                        break
                    case 3:threeDayWorkBlockCount += 1
                        break
                    case 4:fourDayWorkBlockCount += 1
                        break
                    default:break
                    }
                    back2backTripBlock = 0
                    tripIndex = 0
                    
                    arrFetchedTrip = []
                    arrFetchedTrip.append(trip)
                    
                    if tripCount == trips.count-1 && tripIndex >= 0 {
                        //Set WorkBlock Details
                        let workBlock4 = WorkBlockList(context: self.dataSource.managedObjectContext)
                        workBlock4.backToBackCount = back2backTripBlock as NSNumber
                        workBlock4.startDateTime = tripStartDate
                        workBlock4.startDateTakeOffTime = tripStartDateTakeOff
                        workBlock4.startDay = self.getDay(from: tripStartDate)
                        workBlock4.endDateTime = tripEndDate
                        workBlock4.endDateOnly = tripEndDateOnly
                        workBlock4.endDay = self.getDay(from: tripEndDateOnly)
                        workBlock4.line = line
                        workBlock4.briefMinutes = briefMins as NSNumber
                        workBlock4.deBriefMinutes = debriefMins as NSNumber
                        
                        for trip1 in trips {
                            let trip1StartDate = self.getStartDateIncludeVacation(from: trip1)
                            let trip1EndDate = self.getEndDateOfTripIncludeVacation(from: trip1)
                            if let days = trip1["BIDay"] as? [BIDay] {
                                    workBlockDays.append(contentsOf: days)
                                }
                            if tripStartDate == trip1StartDate {
                                workBlockDays.removeAll()
                                if let days = trip1["BIDay"] as? [BIDay] {
                                        workBlockDays.append(contentsOf: days)
                                    }
                            }
                            if tripEndDate == trip1EndDate {
                                break
                            }
                        }
                        
                        for day in workBlockDays {
                            let dayObj = BIDay(context: self.dataSource.managedObjectContext)
                            dayObj.date = day.date
                            dayObj.info = day.info
                            dayObj.workBlock = workBlock4
                        }
                        
                        let checkDomicile = self.calculateNMidCountWithVacation(from: arrFetchedTrip, workBlock: workBlock4)
                        workBlock4.nightINDomicile = checkDomicile as? NSNumber
                        let daysCount = self.calendarData.daysBetweenDateForWorkBlock(from: workBlock4.startDateTime!, to: workBlock4.endDateOnly!) + 1
                        switch daysCount{
                        case 1:oneDayWorkBlockCount += 1
                            break
                        case 2:twoDayWorkBlockCount += 1
                            break
                        case 3:threeDayWorkBlockCount += 1
                            break
                        case 4:fourDayWorkBlockCount += 1
                            break
                        default:break
                        }
                    }
                    tripIndex = 0
                }
            }
            line.workBlock1 = oneDayWorkBlockCount as NSNumber
            line.workBlock2 = twoDayWorkBlockCount as NSNumber
            line.workBlock3 = threeDayWorkBlockCount as NSNumber
            line.workBlock4 = fourDayWorkBlockCount as NSNumber
            line.workBlockCount = line.workBlocks!.count as NSNumber
            self.calculateNewProperties(line: line)
        }
        let context = self.dataSource.managedObjectContext
        if context.hasChanges{
            do{
                try context.save()
            }catch{
                print("Error in saving context: \(error.localizedDescription)")
            }
        }
        self.calculateNightInMiddle()
    }
    
    private func calculateNMidCountWithVacation(from trips:[[String:Any]], workBlock:WorkBlockList) -> Int? {
        var oneWeek = DateComponents()
        oneWeek.day = 1
        var nightInMiddle = 0
        for trip in trips {
            let tripInfoOrderedDays = trip["BITripInfo"] as! [Any]
            let tripStartDate = trip["StartDate"] as! Date
            var loopDate = tripStartDate
            let tripEndDate = self.getEndDateOfTripIncludeVacation(from: trip)
            
            //SingleDay trip
            if loopDate.compare(tripEndDate!) == .orderedSame && workBlock.endDateTime?.compare(tripEndDate!) != .orderedSame{
                for case let dayInfo as BIDayInfo in tripInfoOrderedDays{
                    let dayOrderedLegs = dayInfo.orderedLegs
                    let legInfo = dayOrderedLegs.last as! BILegInfo
                    if legInfo.arriveCity == self.bidPeriod?.base {
                        nightInMiddle += 1
                    }
                }
            }else{
                //multiple day trip
                if  workBlock.endDateTime?.compare(tripEndDate!) == .orderedSame {
                    
                }else{
                    for case let dayInfo as BIDayInfo in tripInfoOrderedDays {
                        let dayOrderedLegs = dayInfo.orderedLegs
                        let legInfo = dayOrderedLegs.last as! BILegInfo
                        if workBlock.endDateTime?.compare(loopDate) != .orderedSame {
                            if legInfo.arriveCity == self.bidPeriod?.base {
                                nightInMiddle += 1
                            }
                        }
                        loopDate = Calendar.current.date(byAdding: oneWeek, to: loopDate)!
                    }
                }
            }
        }
        return nightInMiddle
    }
    
    
    private func getStartDateIncludeVacation(from trip: [String: Any]) -> Date? {
        var startDate:Date!
        let tripInfoOrderedDays = trip["BITripInfo"] as! [Any]
        let tripStartDate = trip["StartDate"] as! Date
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale.current
        calendar.timeZone = TimeZone(identifier: "GMT")!
        var dateComps = calendar.dateComponents([.day,.month,.year], from: tripStartDate)
        
        let dayInfo = tripInfoOrderedDays.first as? BIDayInfo
        var isInternationalCity = false
        let arrInternationalCities = (UserDefaults.standard.array(forKey: kCBInternationalCitiesList) as? [String])
        
        if dayInfo != nil{
            let dayOrderedLegs = dayInfo?.orderedLegs
            let legInfo = dayOrderedLegs?.first as? BILegInfo
            if legInfo != nil {
                dateComps.minute = legInfo!.departMinutes?.intValue
                startDate = calendar.date(from: dateComps)
                if let arriveCity = legInfo!.arriveCity {
                    isInternationalCity = arrInternationalCities!.contains(arriveCity)
                }
            }
        }
        var updateTime:Date!
        if isInternationalCity{
            updateTime = startDate.addingTimeInterval(TimeInterval(-InternationalCityMinutes * 60))
        }else{
            updateTime = startDate.addingTimeInterval(TimeInterval(-CityMinutes * 60))
        }
        return updateTime
    }
    
    private func getStartDateIncludeVacationWithTakeOff(from trip: [String: Any]) -> Date? {
        var updateTime:Date!
        let tripInfoOrderedDays = trip["BITripInfo"] as! [Any]
        let tripStartDate = trip["StartDate"] as! Date
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale.current
        calendar.timeZone = TimeZone(identifier: "GMT")!
        var dateComps = calendar.dateComponents([.day,.month,.year], from: tripStartDate)
        
        let dayInfo = tripInfoOrderedDays.first as? BIDayInfo
        if dayInfo != nil {
            let dayOrderedLegs = dayInfo?.orderedLegs
            let legInfo = dayOrderedLegs?.first as? BILegInfo
            if legInfo != nil {
                let briefMin = trip["briefMinutes"] as! Int
                dateComps.minute = (legInfo?.departMinutes!.intValue)! - briefMin
                updateTime = calendar.date(from: dateComps)!
            }
        }
        return updateTime
    }
    
    private func getEndDateOfTripIncludeVacation(from trip: [String: Any]) -> Date? {
        var endDate:Date!
        let tripInfoOrderedDays = trip["BITripInfo"] as! [Any]
        let tripStartDate = trip["StartDate"] as! Date
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale.current
        calendar.timeZone = TimeZone(identifier: "GMT")!
        var dateComps = calendar.dateComponents([.day,.month,.year], from: tripStartDate)
        let dayInfo = tripInfoOrderedDays.last as? BIDayInfo
        if dayInfo != nil {
            let dayOrderedLegs = dayInfo?.orderedLegs
            let legInfo = dayOrderedLegs?.last as? BILegInfo
            if legInfo != nil {
                dateComps.minute = legInfo?.arriveMinutes?.intValue
                endDate = calendar.date(from: dateComps)!
            }
        }
        let tripNumber = trip["TripNumber"]
        let tripNUmberString = tripNumber as! String
        if tripNUmberString.length > 1{
            let secondChar = tripNUmberString[tripNUmberString.index(tripNUmberString.startIndex, offsetBy: 1)]
            if secondChar >= "W"{
                var dateCompsReserve = calendar.dateComponents([.day,.month,.year], from: endDate)
                let returnTime = trip["returnTime"] as! Int
                let time = String(format: "%04d", returnTime % 2400)
                let strHr = (time as NSString).substring(with: NSRange(location: 0, length: 2))
                let strMin = (time as NSString).substring(with: NSRange(location: 2, length: time.length - strHr.length))
                dateCompsReserve.hour = Int(strHr)
                dateCompsReserve.minute = Int(strMin)
                endDate = calendar.date(from: dateCompsReserve)!
                let hour = dateCompsReserve.hour!
                if hour >= 0 && hour <= 4 {
                    var dateComponents = DateComponents()
                    dateComponents.day = 1
                    endDate = Calendar.current.date(byAdding: dateComponents, to: endDate)!
                }
            }
        }
        return endDate
    }
    
    private func getOnlyEndDateOfTripIncludeVacation(from trip: [String: Any], biTrip: BITrip) -> Date? {
        var endDate:Date!
        let tripOrderedDays = trip["BIDay"] as! [Any]
        let tripStartDate = trip["StartDate"] as! Date
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale.current
        calendar.timeZone = TimeZone(identifier: "GMT")!
        let now = tripStartDate
        var daysToAdd = tripOrderedDays.count
        if biTrip.isRedEyeTrip {
            if biTrip.info?.calendarDaysCount != NSNumber(value: biTrip.info!.orderedDays().count) {
                if CBUtils.findMissingDate(forRedEyeTrip: biTrip) != nil {
                    daysToAdd += 1
                }
            }
        }
        let newDate = now.addingTimeInterval(TimeInterval(60*60*24*(daysToAdd-1)))
        let dateComps = calendar.dateComponents([.day,.month,.year], from: newDate)
        endDate = calendar.date(from: dateComps)
        return endDate
    }
    
    func calculateWorkBlockDetails(){
        var tripStartDate:Date!
        var tripStartDateTakeOff:Date!
        var tripEndDate:Date!
        var tripEndDateOnly:Date!
        var previousTripEndDate:Date!
        var previousTripEndDateOnly:Date!
        var startDateTime:Date!
        var startDateTakeOffTime:Date!
        
        //Iterate Lines
        let bidLinesFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Line")
        bidLinesFetch.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "type != 4"),
            NSPredicate(format: "bidPeriod == %@", self.bidPeriod!)
        ])
        bidLinesFetch.sortDescriptors = [NSSortDescriptor(key: "bidOrder", ascending: true)]
        do{
            let results = try self.bidPeriod!.managedObjectContext!.fetch(bidLinesFetch)
            
            var arrLineOvernightCity:[String] = []
            for case let line as BILine in results {
                   self.removeExistingWorkBlock(line)
                    //Initialize Trip Index
                    var tripIndex = 0
                    var back2backTripBlock = 0
                    previousTripEndDate = nil
                    
                    let tripsData = line.orderedTrips
                    let sortDescriptor = NSSortDescriptor(key: "startDate", ascending: true)
                    let trips = (tripsData as NSArray).sortedArray(using: [sortDescriptor])
                    
                    //Iterate trips in line
                    arrLineOvernightCity = []
                    var prevTrip: BITrip?
                    
                    var arrFetchedTrip:[BITrip] = []
                    var oneDayWorkBlockCount = 0
                    var twoDayWorkBlockCount = 0
                    var threeDayWorkBlockCount = 0
                    var fourDayWorkBlockCount = 0
                    var briefMins = 60
                    var debriefMins = 30
                    
                    // Need to regererate trip
                    for tripCount in 0..<trips.count {
                            let trip = trips[tripCount] as! BITrip
                            //to get the overnight cities list
                            self.getTripArriveCity(from: trip)
                            arrLineOvernightCity.append(contentsOf: self.getTripArriveCity(trip: trip))
                            tripStartDate = self.getStartDate(for: trip)
                            tripStartDateTakeOff = self.getStartDateWithTakeOff(for: trip)
                            tripEndDate = self.getEndDateOfTrip(for: trip)
                            //using EndDate to account for irregular datetimes in company time keeping method.
                            tripEndDateOnly = self.getOnlyEndDateOfTrip(for: trip)!
                            briefMins = trip.info?.briefMinutes as! Int
                            debriefMins = trip.info?.debriefMinutes as! Int
                            
                            if tripCount != 0 {
                                prevTrip = trips[tripCount - 1] as? BITrip
                                previousTripEndDate = self.getEndDateOfTrip(for: prevTrip!)
                                previousTripEndDateOnly = self.getOnlyEndDateOfTrip(for: prevTrip!)
                            }
                            if tripIndex <= 0 {
                                startDateTime = self.getStartDate(for: trip)
                                startDateTakeOffTime = self.getStartDateWithTakeOff(for: trip)
                            }
                            if back2backTripBlock == 0 && tripCount != 0 {
                                let dateFormatter = DateFormatter()
                                dateFormatter.dateFormat = "MM/dd/yyyy HH:mm:ss"
                                dateFormatter.timeZone = TimeZone(identifier: "GMT")
                                startDateTime = self.getStartDate(for: prevTrip!)
                                startDateTakeOffTime = self.getStartDateWithTakeOff(for: prevTrip!)
                            }
                            var isContinousTrip = false
                            if prevTrip != nil {
                                isContinousTrip = self.doesTripsContinues(lastTripEndDate: prevTrip!.endDate!, currentTripStartDate: trip.startDate!)
                            }
                            if isContinousTrip {
                                briefMins = prevTrip!.info!.briefMinutes as! Int
                            }
                       
                            //Check if its continous trip
                            if previousTripEndDate == nil {
                                back2backTripBlock += 1
                                tripIndex += 1
                                arrFetchedTrip.append(trip)
                                if tripCount == trips.count-1 {
                                    //Set WorkBlock Details
                                    let workBlock1 = WorkBlockList(context: self.dataSource.managedObjectContext)
                                    workBlock1.backToBackCount = back2backTripBlock as NSNumber
                                    workBlock1.startDateTime = startDateTime
                                    workBlock1.startDateTakeOffTime = startDateTakeOffTime
                                    workBlock1.startDay = self.getDay(from: startDateTime)
                                    workBlock1.endDateTime = tripEndDate
                                    workBlock1.endDateOnly = tripEndDateOnly
                                    workBlock1.endDay = self.getDay(from: tripEndDateOnly)
                                    workBlock1.line = line
                                    workBlock1.briefMinutes = briefMins as NSNumber
                                    workBlock1.deBriefMinutes = debriefMins as NSNumber
                                    let checkDomicile = self.calculateNMidCount(trips: arrFetchedTrip, workBlock: workBlock1)
                                    workBlock1.nightINDomicile = checkDomicile as NSNumber
                                    
                                    let workBlockDays = (prevTrip!.days!.allObjects) + (trip.days!.allObjects)
                                    for case let day as BIDay in workBlockDays {
                                        let dayObj = BIDay(context: self.dataSource.managedObjectContext)
                                        dayObj.date = day.date
                                        dayObj.info = day.info
                                        dayObj.workBlock = workBlock1
                                    }
                                    let daysCount = self.calendarData.daysBetweenDateForWorkBlock(from: workBlock1.startDateTime!, to: workBlock1.endDateOnly!) + 1
                                    switch daysCount{
                                    case 1:oneDayWorkBlockCount += 1
                                        break
                                    case 2:twoDayWorkBlockCount += 1
                                        break
                                    case 3:threeDayWorkBlockCount += 1
                                        break
                                    case 4:fourDayWorkBlockCount += 1
                                        break
                                    default:break
                                    }
                                    back2backTripBlock = 0
                                    tripIndex = 0
                                    
                                    if let triped = arrFetchedTrip.last {
                                        arrFetchedTrip.append(triped)
                                    }
                                }
                            }
                            else if  self.checkIsContinuousTrip(currentTripStartDate: tripStartDate, previousTripEndDate: previousTripEndDate){
                                back2backTripBlock += 1
                                tripIndex += 1
                                arrFetchedTrip.append(trip)
                                
                                if tripCount == trips.count - 1 {
                                    let workBlock2 = WorkBlockList(context: self.dataSource.managedObjectContext)
                                    workBlock2.backToBackCount = back2backTripBlock as NSNumber
                                    workBlock2.startDateTime = startDateTime
                                    workBlock2.startDateTakeOffTime = startDateTakeOffTime
                                    workBlock2.startDay = self.getDay(from: startDateTime)
                                    workBlock2.endDateTime = tripEndDate
                                    workBlock2.endDateOnly = tripEndDateOnly
                                    workBlock2.endDay = self.getDay(from: tripEndDateOnly)
                                    workBlock2.line = line
                                    
                                    var workBlockDays:[Any] = []
                                    
                                    for case let trip1 as BITrip in trips{
                                        let trip1StartDate = self.getStartDate(for: trip1)
                                        let trip1EndDate = self.getEndDateOfTrip(for: trip1)
                                        workBlockDays.append(contentsOf: trip1.days!.allObjects)
                                        if startDateTime == trip1StartDate {
                                            workBlockDays.removeAll()
                                            workBlockDays.append(contentsOf: trip1.days!.allObjects)
                                        }
                                        if tripEndDate == trip1EndDate {
                                            break
                                        }
                                    }
                                    
                                    for case let day as BIDay in workBlockDays{
                                        let dayObj = BIDay(context: self.dataSource.managedObjectContext)
                                        dayObj.date = day.date
                                        dayObj.info = day.info
                                        dayObj.workBlock = workBlock2
                                    }
                                    
                                    let daysCount = self.calendarData.daysBetweenDateForWorkBlock(from: workBlock2.startDateTime!, to: workBlock2.endDateOnly!) + 1
                                    
                                    switch daysCount{
                                    case 1:oneDayWorkBlockCount += 1
                                        break
                                    case 2:twoDayWorkBlockCount += 1
                                        break
                                    case 3:threeDayWorkBlockCount += 1
                                        break
                                    case 4:fourDayWorkBlockCount += 1
                                        break
                                    default:break
                                    }
                                    
                                    let checkDomicile = self.calculateNightInMiddleCount(trips: arrFetchedTrip, workBlock: workBlock2)
                                    workBlock2.nightINDomicile = checkDomicile as NSNumber
                                    back2backTripBlock = 0
                                    tripIndex = 0
                                    
                                    if let triped = arrFetchedTrip.last {
                                        arrFetchedTrip.append(triped)
                                    }
                                }
                            }else{
                                //Set WorkBlock Details
                                let workBlock3 = WorkBlockList(context: self.dataSource.managedObjectContext)

                                workBlock3.backToBackCount = back2backTripBlock as NSNumber
                                workBlock3.startDateTime = startDateTime
                                workBlock3.startDateTakeOffTime = startDateTakeOffTime
                                workBlock3.startDay = self.getDay(from: startDateTime)
                                workBlock3.briefMinutes = briefMins as NSNumber
                                workBlock3.deBriefMinutes = debriefMins as NSNumber
                                
                                var workBlockDays:[Any] = []
                                if tripIndex >= 0 {
                                    workBlock3.endDateTime = previousTripEndDate
                                    workBlock3.endDateOnly = previousTripEndDateOnly
                                    workBlock3.endDay = self.getDay(from: previousTripEndDateOnly)
                                    
                                    for case let trip1 as BITrip in trips{
                                        let trip1StartDate = self.getStartDate(for: trip1)
                                        let trip1EndDate = self.getEndDateOfTrip(for: trip1)
                                        workBlockDays.append(contentsOf: trip1.days!.allObjects)
                                        
                                        if startDateTime == trip1StartDate {
                                            workBlockDays.removeAll()
                                            workBlockDays.append(contentsOf: trip1.days!.allObjects)
                                        }
                                        
                                        if previousTripEndDate == trip1EndDate {
                                            break
                                        }
                                    }
                                }else{
                                    workBlock3.endDateTime = tripEndDate
                                    workBlock3.endDay = self.getDay(from: tripEndDateOnly)
                                    let trip1 = trips[tripCount-1] as! BITrip
                                    workBlockDays = trip1.days!.allObjects
                                }
                                workBlock3.line = line
                                
                                for case let day as BIDay in workBlockDays {
                                    
                                    let dayObj = BIDay(context: self.dataSource.managedObjectContext)
                                    
                                    dayObj.date = day.date
                                    dayObj.info = day.info
                                    dayObj.workBlock = workBlock3
                                }
                                
                                let daysCount = self.calendarData.daysBetweenDateForWorkBlock(from: workBlock3.startDateTime!, to: workBlock3.endDateOnly!) + 1
                                
                                switch daysCount{
                                case 1:oneDayWorkBlockCount += 1
                                    break
                                case 2:twoDayWorkBlockCount += 1
                                    break
                                case 3:threeDayWorkBlockCount += 1
                                    break
                                case 4:fourDayWorkBlockCount += 1
                                    break
                                default:break
                                }
                                let checkDomicile = self.calculateNightInMiddleCount(trips: arrFetchedTrip, workBlock: workBlock3)
                                workBlock3.nightINDomicile = checkDomicile as NSNumber
                                back2backTripBlock = 0
                                tripIndex = 0
                                
                                arrFetchedTrip = []
                                arrFetchedTrip.append(trip)
                                
                                if tripCount == trips.count - 1 && tripIndex >= 0 {
                                    //Set WorkBlock Details
                                    let workBlock4 = WorkBlockList(context: self.dataSource.managedObjectContext)
                                    
                                    workBlock4.backToBackCount = back2backTripBlock as NSNumber
                                    workBlock4.startDateTime = tripStartDate
                                    workBlock4.startDateTakeOffTime = tripStartDateTakeOff
                                    workBlock4.startDay = self.getDay(from: tripStartDate)
                                    workBlock4.endDateTime = tripEndDate
                                    workBlock4.endDateOnly = tripEndDateOnly
                                    workBlock4.endDay = self.getDay(from: tripEndDateOnly)
                                    workBlock4.line = line
                                    workBlock4.briefMinutes = briefMins as NSNumber
                                    workBlock4.deBriefMinutes = debriefMins as NSNumber
                                    
                                    let workBlockDays = trip.days!.allObjects
                                    for case let day as BIDay in workBlockDays{
                                        let dayObj = BIDay(context: self.dataSource.managedObjectContext)
                                        dayObj.date = day.date
                                        dayObj.info = day.info
                                        dayObj.workBlock = workBlock4
                                    }
                                    
                                    let daysCount = self.calendarData.daysBetweenDateForWorkBlock(from: workBlock4.startDateTime!, to: workBlock4.endDateOnly!) + 1
                                    
                                    switch daysCount{
                                    case 1:oneDayWorkBlockCount += 1
                                        break
                                    case 2:twoDayWorkBlockCount += 1
                                        break
                                    case 3:threeDayWorkBlockCount += 1
                                        break
                                    case 4:fourDayWorkBlockCount += 1
                                        break
                                    default:break
                                    }
                                    let checkDomicile = self.calculateNightInMiddleCount(trips: arrFetchedTrip, workBlock: workBlock4)
                                    workBlock4.nightINDomicile = checkDomicile as NSNumber
                                    
                                }
                                tripIndex = 0
                            }
                    }
                    
                    line.workBlock1 = oneDayWorkBlockCount as NSNumber
                    line.workBlock2 = twoDayWorkBlockCount as NSNumber
                    line.workBlock3 = threeDayWorkBlockCount as NSNumber
                    line.workBlock4 = fourDayWorkBlockCount as NSNumber
                    line.workBlockCount = line.workBlocks!.count as NSNumber
                    self.calculateNewProperties(line: line)
            }
            
            self.bidPeriod?.overNightCities = arrOverNightCities as NSArray
            self.bidPeriod?.isOverNightBulkApplied = "NO"
            self.bidPeriod?.isVacationRemoved = false
            AppState.shared.currentBidPeriod = self.bidPeriod
            
            if self.dataSource.managedObjectContext.hasChanges {
                do{
                    try self.dataSource.managedObjectContext.save()
                }catch{
                    print("Error in saving bid lines: \(error.localizedDescription)")
                }
            }
            self.calculateNightInMiddle()
        }catch{
            print("Error in fetching bid lines: \(error.localizedDescription)")
        }
    }
    
    private func regenerateTrip(_ trips: [BITrip]) -> [[String: Any]] {
        var arrRegenerateTrip: [[String: Any]] = []

        for trip in trips {
            if let data = checkAndReframeTrip(trip) {
                arrRegenerateTrip.append(data)
            }
        }

        return arrRegenerateTrip
    }
    
    private func checkAndReframeTrip(_ trip: BITrip) -> [String: Any]? {
        var dicTrip: [String: Any] = [:]
        var arrOrderedDaysDay: [Any] = []
        var arrOrderedDaysTripInfoDay: [Any] = []

        for i in 0..<trip.orderedDays.count {
            let dayInfo = trip.orderedDays[i]
            let displayType = dayInfo.displayType?.intValue
            if  displayType != BIDayDisplayType.fullPay.rawValue,
               displayType != BIDayDisplayType.noPay.rawValue,
               displayType != BIDayDisplayType.partialPay.rawValue {

                arrOrderedDaysDay.append(dayInfo)

                if let tripInfoDays = trip.info?.orderedDays(),
                   i < tripInfoDays.count{
                    arrOrderedDaysTripInfoDay.append(tripInfoDays[i])
                }
            }
        }

        if !arrOrderedDaysDay.isEmpty {
            dicTrip["BIDay"] = arrOrderedDaysDay
            dicTrip["StartDate"] = trip.startDate
            dicTrip["BITripInfo"] = arrOrderedDaysTripInfoDay
            dicTrip["briefMinutes"] = trip.info?.briefMinutes
            dicTrip["debriefMinutes"] = trip.info?.debriefMinutes
            dicTrip["TripNumber"] = trip.info?.number
            dicTrip["returnTime"] = trip.info?.returnTime
            return dicTrip
        }

        return nil
    }
    
    
    private func calculateNightInMiddle() {
        for case let line as BILine in self.bidPeriod!.lines! {
                line.nightsInMid = 0
                var inMiddle = 0

                for case let workBlock as WorkBlockList in line.workBlocks ?? [] {
                    inMiddle += workBlock.nightINDomicile!.intValue
                }
                line.nightsInMid = NSNumber(value: inMiddle)
        }

        do {
            try self.bidPeriod?.managedObjectContext?.save()
        } catch {
            print("Failed to save context: \(error.localizedDescription)")
        }
    }
    
    private func calculateNightInMiddleCount(trips: [BITrip], workBlock: WorkBlockList) -> Int {
        var nightInMiddle = 0
        let calendar = Calendar.current
        var oneDay = DateComponents()
        oneDay.day = 1

        for trip in trips {
            var loopDate = trip.startDate!
            let tripEndDate = getEndDateOfTrip(for: trip)

            // Single-day trip
            if loopDate == tripEndDate && workBlock.endDateTime != tripEndDate {
                for case let dayInfo in trip.info!.orderedDays() {
                    let legs = dayInfo.orderedLegs
                    let lastLeg = legs.last
                    if lastLeg!.arriveCity == self.bidPeriod?.base{
                        nightInMiddle += 1
                    }
                }
            } else {
                // Multi-day trip
                if workBlock.endDateTime == tripEndDate {
                    // Do nothing
                } else {
                    for case let dayInfo in trip.info!.orderedDays() {
                        let legs = dayInfo.orderedLegs
                           let lastLeg = legs.last
                            if workBlock.endDateTime != loopDate,
                               lastLeg!.arriveCity == self.bidPeriod?.base {
                                nightInMiddle += 1
                            }
                        
                        loopDate = calendar.date(byAdding: oneDay, to: loopDate) ?? loopDate
                    }
                }
            }
        }

        return nightInMiddle
    }
    
    private func checkIsContinuousTrip(currentTripStartDate: Date, previousTripEndDate: Date) -> Bool {
        let daysBetweenTrip = self.numberOfDaysBetween(startDate: previousTripEndDate, endDate: currentTripStartDate)
        var flag = true
        if daysBetweenTrip >= 1 {
            flag = false
        }
        return flag
    }
    
    private func numberOfDaysBetween(startDate: Date, endDate: Date) -> Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(abbreviation: "GMT")!
        let startDay = calendar.component(.day, from: startDate)
        let endDay = calendar.component(.day, from: endDate)
        let difference = endDay - startDay - 1
        return difference
    }
    
    private func calculateNMidCount(trips: [BITrip], workBlock: WorkBlockList) -> Int {
        var nightInMiddle = 0
        let calendar = Calendar.current
        let oneDay = DateComponents(day: 1)

        for trip in trips {
            var loopDate = trip.startDate!
            let tripEndDate = getEndDateOfTrip(for: trip)

            // Single-day trip
            if loopDate == tripEndDate && workBlock.endDateTime != tripEndDate {
                for case let dayInfo in trip.info!.orderedDays() {
                    let dayOrderedLegs = dayInfo.orderedLegs
                    if let legInfo = dayOrderedLegs.last as? BILegInfo,
                       legInfo.arriveCity == self.bidPeriod!.base {
                        nightInMiddle += 1
                    }
                }
            } else {
                // Multi-day trip
                if workBlock.endDateTime != tripEndDate {
                    for case let dayInfo in trip.info!.orderedDays() {
                        if workBlock.endDateTime != loopDate {
                            let dayOrderedLegs = dayInfo.orderedLegs
                            if let legInfo = dayOrderedLegs.last as? BILegInfo,
                               legInfo.arriveCity == self.bidPeriod!.base {
                                nightInMiddle += 1
                            }
                        }
                        loopDate = calendar.date(byAdding: oneDay, to: loopDate)!
                    }
                }
            }
        }

        return nightInMiddle
    }
    
    
    private func doesTripsContinues(lastTripEndDate: Date, currentTripStartDate: Date) -> Bool {
        let calendar = Calendar.current

        // Strip the time components to compare only dates
        guard let startOfDay1 = calendar.startOfDay(for: lastTripEndDate) as Date?,
              let startOfDay2 = calendar.startOfDay(for: currentTripStartDate) as Date? else {
            return false
        }

        // Get difference in days
        let dayDifference = calendar.dateComponents([.day], from: startOfDay1, to: startOfDay2).day

        // Get year and month components
        let components1 = calendar.dateComponents([.year, .month], from: lastTripEndDate)
        let components2 = calendar.dateComponents([.year, .month], from: currentTripStartDate)

        // Check if year and month match
        if components1.year == components2.year && components1.month == components2.month {
            return abs(dayDifference!) == 1
        }

        return false
    }
    
    
    private func getOnlyEndDateOfTrip(for trip: BITrip) -> Date? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale.current
        calendar.timeZone = TimeZone(identifier: "GMT")!

        guard let startDate = trip.startDate else {
            return nil
        }

        var daysToAdd = trip.days!.count

        // Handle red-eye trips
        if trip.isRedEyeTrip == true,
           let calendarDaysCount = trip.info?.calendarDaysCount,
           let orderedDaysCount = trip.info?.orderedDays().count,
           calendarDaysCount != NSNumber(value: orderedDaysCount),
           CBUtils.findMissingDate(forRedEyeTrip: trip) != nil {
            daysToAdd += 1
        }

        let totalDaysToAdd = max(daysToAdd - 1, 0)
        guard let intermediateDate = Calendar.current.date(byAdding: .day, value: totalDaysToAdd, to: startDate) else {
            return nil
        }

        // Remove time components to return a pure date
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: intermediateDate)
        return calendar.date(from: dateComponents)
    }
    
    private func getEndDateOfTrip(for trip: BITrip) -> Date? {
        // Special case: FA 2nd round reserve line uses endDate directly
        if isFABid() == true,
           bidPeriod?.isSecondRoundBid() == true,
           trip.isReserve == true {
            return trip.endDate
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale.current
        calendar.timeZone = TimeZone(identifier: "GMT")!

        var endDate: Date?
        var dateComps = calendar.dateComponents([.year, .month, .day], from: trip.startDate!)

        if let dayInfo = trip.info?.orderedDays().last,
           let legInfo = (dayInfo.orderedLegs).last {

            dateComps.minute = legInfo.arriveMinutes!.intValue
            endDate = calendar.date(from: dateComps)

            // Adjust for early morning arrivals
            if let endDateUnwrapped = endDate {
                let endDateComps = calendar.dateComponents([.year, .month, .day], from: endDateUnwrapped)
                let hourComponents = calendar.dateComponents([.hour], from: endDateUnwrapped)

                if endDateComps.day == dateComps.day, (hourComponents.hour!) <= 4 {
                    dateComps.day! += 1
                    endDate = calendar.date(from: dateComps)
                }
            }
        }

        // Reserve trip ending late at night / early morning
        if let number = trip.info?.number,
           number.count > 1 {
            let secondChar = number[number.index(number.startIndex, offsetBy: 1)]
            if secondChar >= "W"{
                if let endDateUnwrapped = endDate {
                    var reserveComps = calendar.dateComponents([.year, .month, .day], from: endDateUnwrapped)
                    let returnTime = trip.info?.returnTime!.intValue
                    let timeString = String(format: "%04d", returnTime! % 2400)

                    if let hour = Int(timeString.prefix(2)),
                       let minute = Int(timeString.suffix(2)) {
                        reserveComps.hour = hour
                        reserveComps.minute = minute
                        endDate = calendar.date(from: reserveComps)

                        if hour >= 0 && hour <= 4 {
                            endDate = calendar.date(byAdding: .day, value: 1, to: endDate!)
                        }
                    }
                }
            }
        }

        return endDate
    }
    
    private func getStartDateWithTakeOff(for trip: BITrip) -> Date? {
        var updateTime: Date?
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale.current
        calendar.timeZone = TimeZone(identifier: "GMT")!

        var dateComps = calendar.dateComponents([.year, .month, .day], from: trip.startDate!)

        if let dayInfo = trip.info?.orderedDays().first,
           let legInfo = (dayInfo.orderedLegs).first {
            
            let departMinutes = legInfo.departMinutes!.intValue
            let briefMinutes = trip.info?.briefMinutes!.intValue
            dateComps.minute = departMinutes - briefMinutes!
            updateTime = calendar.date(from: dateComps)
        }

        if let number = trip.info?.number,
           number.count > 1 {
            let secondChar = number[number.index(number.startIndex, offsetBy: 1)]
            if secondChar >= "W"{
                
                var reserveComps = calendar.dateComponents([.year, .month, .day], from: trip.startDate!)
                let departTime = trip.info?.departTime!.intValue
                let timeString = String(format: "%04d", departTime! % 2400)
                
                if let hour = Int(timeString.prefix(2)), let minute = Int(timeString.suffix(2)) {
                    reserveComps.hour = hour
                    reserveComps.minute = minute
                    updateTime = calendar.date(from: reserveComps)
                }
            }
        }
        return updateTime
    }
    
    private func getStartDate(for trip: BITrip) -> Date? {
        var startDate: Date?
        var updateTime: Date?
        
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale.current
        calendar.timeZone = TimeZone(identifier: "GMT")!
        var dateComps = calendar.dateComponents([.year, .month, .day], from: trip.startDate!)
        
        let dayInfo = trip.info?.orderedDays().first as? BIDayInfo
        var isInternationalCity = false
        
        let arrInternationalCities = UserDefaults.standard.array(forKey: kCBInternationalCitiesList) as! [String]

        let dayOrderedLegs = dayInfo!.orderedLegs
        let legInfo = dayOrderedLegs.first

        dateComps.minute = legInfo!.departMinutes!.intValue
        startDate = calendar.date(from: dateComps)
        isInternationalCity = arrInternationalCities.contains(legInfo!.arriveCity ?? "")
        

        if let startDate = startDate {
            if isInternationalCity {
                updateTime = startDate.addingTimeInterval(TimeInterval(-InternationalCityMinutes * 60))
            } else {
                updateTime = startDate.addingTimeInterval(TimeInterval(-CityMinutes * 60))
            }
        }

        // Check for reserve trips
        if let number = trip.info?.number, number.count > 1 {
            let secondChar = number[number.index(number.startIndex, offsetBy: 1)]
            if secondChar >= "W"{
                var reserveComps = calendar.dateComponents([.year, .month, .day], from: trip.startDate!)
                let departTime = trip.info?.departTime!.intValue
                let time = String(format: "%04d", departTime! % 2400)
                
                if let hour = Int(time.prefix(2)), let minute = Int(time.suffix(2)) {
                    reserveComps.hour = hour
                    reserveComps.minute = minute
                    updateTime = calendar.date(from: reserveComps)
                }
            }
        }

        return updateTime
    }
    
    private func getTripArriveCity(trip: BITrip) -> [String] {
        var arrOvernightCity: [String] = []
        for dayInfo in trip.info!.orderedDays() {
            if let dayInfo = dayInfo as? BIDayInfo,
               let legInfo = (dayInfo.orderedLegs).last,
               let city = legInfo.arriveCity,
               city != self.bidPeriod?.base {
                arrOvernightCity.append(city)
            }
        }
        return arrOvernightCity
    }
    
    func getTripArriveCity(from trip: BITrip) {
        var city = ""
        if let orderedDays = trip.info?.orderedDays(), let lastDay = orderedDays.last as? BIDayInfo, let domicileCity = lastDay.city {
            for case let dayInfo as BIDayInfo in orderedDays{
                let dayOrderedLegs = dayInfo.orderedLegs
                let legInfo = dayOrderedLegs.last as! BILegInfo
                city = legInfo.arriveCity!
                if city != domicileCity && !arrOverNightCities.contains(city){
                    arrOverNightCities.append(city)
                }
            }
        }
    }
    
    private func removeExistingWorkBlock(_ line: BILine){
        line.workBlocks = NSMutableSet()
    }
    
    private func checkPaperBidUserVacation(){
        var dictDetails: [String: Any] = [:]
        let rawEmpNum = self.dataSource.employeeNumber
        let cleanedEmpNum = rawEmpNum.replacingOccurrences(of: "x", with: "").trimmingCharacters(in: CharacterSet.symbols)
        let empNum = Int(cleanedEmpNum)

        dictDetails["EmpNum"] = empNum
        dictDetails["Base"] = self.dataSource.base
        dictDetails["Position"] = self.dataSource.position.shortName
        dictDetails["Month"] = self.dataSource.month
        dictDetails["Year"] = self.dataSource.year
        dictDetails["Round"] = 2
        
        let objDataBuilder = ODataBuilder()
            objDataBuilder.getFirstRoundPaperBidVactionsAndUsers(details: dictDetails, completion: { result in
            if result.count > 0 {
                let dict = result[0] as? [String:Any]
                let arr = dict?["Absences"] as? [Any]
                if dict!["DomicileSeniority"] != nil {
                    if dict!["DomicileSeniority"] as! Int != 0 {
                        self.bidPeriod?.isFirstRoundPaperBidder = true
                    }
                }
                if arr != nil {
                    if arr!.count > 0 {
                        self.bidPeriod?.paperBidVacArray = arr as? NSArray
                        self.bidPeriod?.seniorityVacayAvailable = true
                    }
                }
            }
        }, errorHandler: {error in
            print("Error: \(error.localizedDescription)")
        })
    }
    

    
    func addDefaultFilterRules(context: NSManagedObjectContext) -> Bool{
        var success = true
        // Filter rule to allow hard lines only (no reserve or blank lines).
        // For now, allow all line types.
        var set: Set<Int> = []
        var rule = BIFilterRule(context: context)
        rule.bidPeriod = bidPeriod
        rule.category = BIFilterRuleCategory.BITypeFilterRuleCategory.rawValue as NSNumber
        rule.type = BITypeFilterRuleType.BITypeCompoundType.rawValue as NSNumber
        
        if self.isFABid(){
            if self.isFirstRoundBid(){
                if self.bidPeriod!.isEtopsLinesContainsInBid == true{
                    set = [BILineType.HardConUS.rawValue, BILineType.HardNonConUS.rawValue, BILineType.NonEtopsConUS.rawValue, BILineType.NonEtopsNonConUS.rawValue, BILineType.EtopsFAFirstRound.rawValue]
                }else{
                    set = [BILineType.HardConUS.rawValue, BILineType.HardNonConUS.rawValue]
                }
            }else{
                //FA 2nd round
                if self.bidPeriod!.isEtopsLinesContainsInBid == true{
                    set = [BILineType.HardConUS.rawValue, BILineType.HardNonConUS.rawValue, BILineType.ReserveLine.rawValue, BILineType.NonEtopsReserve.rawValue, BILineType.NonReserveEtops.rawValue, BILineType.NonEtopsConUS.rawValue, BILineType.NonEtopsNonConUS.rawValue]
                }else{
                    set = [BILineType.HardConUS.rawValue, BILineType.HardNonConUS.rawValue, BILineType.ReserveLine.rawValue]
                }
            }
        }else{ // is Pilot Bid
            if self.isFirstRoundBid(){
                if self.bidPeriod!.isEtopsLinesContainsInBid == true{
                    set = [BILineType.HardConUS.rawValue, BILineType.HardNonConUS.rawValue, BILineType.ReserveLine.rawValue, BILineType.NonEtopsConUS.rawValue, BILineType.NonEtopsNonConUS.rawValue, BILineType.NonEtopsReserve.rawValue, BILineType.BlankLine.rawValue, BILineType.MixedLine.rawValue, BILineType.NonReserveEtops.rawValue, BILineType.EtopsReserve.rawValue]
                }else{
                    set = [BILineType.HardConUS.rawValue, BILineType.HardNonConUS.rawValue, BILineType.ReserveLine.rawValue, BILineType.BlankLine.rawValue, BILineType.MixedLine.rawValue]
                }
            }else{//Pilot 2nd round
                if self.isFirstRoundBid(){
                    set = [BILineType.HardLine.rawValue, BILineType.MixedLine.rawValue, BILineType.ReserveLine.rawValue, BILineType.NonEtopsHard.rawValue, BILineType.NonEtopsMixed.rawValue, BILineType.NonEtopsReserve.rawValue, BILineType.NonReserveEtops.rawValue]
                }else{
                    set = [BILineType.HardLine.rawValue, BILineType.MixedLine.rawValue, BILineType.ReserveLine.rawValue]
                }
            }
            
        }
        rule.variables = ["SET": set]
        
        // Set Etops Filter rule
        rule = BIFilterRule(context: context)
        rule.bidPeriod = bidPeriod
        rule.category = BIFilterRuleCategory.BIEtopsFilterRuleCategory.rawValue as NSNumber
        let etopsOn = true
        
        rule.variables = ["ETOPS_ON": etopsOn]
        
        // Set Etops Reserve Filter rule
        rule = BIFilterRule(context: context)
        rule.bidPeriod = bidPeriod
        rule.category = BIFilterRuleCategory.BIEtopsResFilterRuleCategory.rawValue as NSNumber
        let etopsResOn = true
        
        rule.variables = ["ETOPSRES_ON": etopsResOn]
        
        // Filter rule to allow both AM and PM lines.
        rule = BIFilterRule(context: context)
        rule.bidPeriod = bidPeriod
        rule.category = BIFilterRuleCategory.BIAmPmFilterRuleCategory.rawValue as NSNumber
        rule.type = BIAmPmFilterRuleType.BIAmPmCompoundType.rawValue as NSNumber
        
        set = [BILineAMPM.AMLine.rawValue, BILineAMPM.PMLine.rawValue, BILineAMPM.MixedAMPMLine.rawValue, BILineAMPM.BlankAMPMLine.rawValue, BILineAMPM.RedEyeAMPMLine.rawValue]
        rule.variables = ["SET": set]
        
        // Filter rule for Flight Attendant Round 2 bidding Reserve line Types
        if self.isFABid() && self.isSecondRoundBid(){
            rule = BIFilterRule(context: context)
            rule.bidPeriod = bidPeriod
            rule.category = BIFilterRuleCategory.BIFaReserveFilterRuleCategory.rawValue as NSNumber
            set = [BIFaReserveLineType.SnrAMres.rawValue, BIFaReserveLineType.SnrPMres.rawValue, BIFaReserveLineType.JnrAMres.rawValue, BIFaReserveLineType.JnrPMres.rawValue, BIFaReserveLineType.JnrLateRes.rawValue, BIFaReserveLineType.NoType.rawValue]
            
            rule.variables = ["SET": set]
        }
        
        // Filter rule to allow Flight Attendant Positions A,B,C,D lines.
        if self.isFABid(){
            rule = BIFilterRule(context: context)
            rule.bidPeriod = bidPeriod
            rule.category = BIFilterRuleCategory.BIPositionFilterRuleCategory.rawValue as NSNumber
            rule.type = BIPositionFilterRuleType.BIPositionCompoundType.rawValue as NSNumber
            set = [BIFaPosition.FaPositionA.rawValue, BIFaPosition.FaPositionB.rawValue, BIFaPosition.FaPositionC.rawValue, BIFaPosition.FaPositionD.rawValue, BIFaPosition.FaPositionMultiple.rawValue, BIFaPosition.FaPositionNA.rawValue]
            rule.variables = ["SET": set]
        }
        // Filter rule to allow weekdays only (Mon-Fri, but no Sat or Sun).
        // For now, allow all days of week.
        rule = BIFilterRule(context: context)
        rule.bidPeriod = bidPeriod
        rule.category = BIFilterRuleCategory.BIDaysOfWeekFilterRuleCategory.rawValue as NSNumber
        rule.type = BIWeekdaysFilterRuleType.BIWeekdaysCompoundType.rawValue as NSNumber
        let weekdayBits = 0
        rule.variables = ["WEEKDAY_BITS": weekdayBits]
        
        // Filter rule to allow turns, two-day trips, three-day trips, but no
        // four-day trips.
        // For now, allow all trip lengths.
        rule = BIFilterRule(context: context)
        rule.bidPeriod = bidPeriod
        rule.category = BIFilterRuleCategory.BITripLengthFilterRuleCategory.rawValue as NSNumber
        rule.type = BITripLengthFilterRuleType.BITripLengthCompoundType.rawValue as NSNumber
        let turnsOn = true
        let twodaysOn = true
        let threedaysOn = true
        let fourdaysOn = true
        rule.variables = ["TURNS_ON": turnsOn, "TWO_DAYS_ON": twodaysOn, "THREE_DAYS_ON": threedaysOn, "FOUR_DAYS_ON": fourdaysOn]
        
        // Set bid period filtered and bid line numbers.
        let sortDescriptor = NSSortDescriptor(key: "number", ascending: true)
        let sortedLines = NSArray(array: self.bidPeriod!.lines!.allObjects).sortedArray(using: [sortDescriptor]) as NSArray
        self.bidPeriod?.filteredLineNumbers = sortedLines.value(forKey: "number") as? NSArray
        self.bidPeriod?.bidLineNumbers = []
        
        if context.hasChanges {
            do{
                try context.save()
            }catch{
                print("Error saving context in addDefaultFilterRules(): \(error.localizedDescription)")
                success = false
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
        
        self.defaultEmployeeNumber = self.dataSource.employeeNumber
        let isHistoric = AppState.shared.isHistoricBid
        self.bidPeriod = BIBidPeriod(context: dataSource.managedObjectContext)
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
         
        self.intlCities = UserDefaults.standard.object(forKey: kCBInternationalCitiesDict) as! [String : Any]
        
        self.bidPeriod?.isAllLinesTrashed = false
    }
    
    //MARK: Read Trips file
    private func readTrips() -> Bool{
        var success = true
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
                                print("Error saving context in readTrips(): \(error.localizedDescription)")
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
                    success = false
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
            success = false
        }
        
        return success
    }
    
    //MARK: Read Lines file
    private func readLines() -> Bool{
        var success = true
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
                                line?.type = BILineType.HardConUS.rawValue as NSNumber
                            }else{
                                line?.type = BILineType.HardLine.rawValue as NSNumber
                            }
                            break
                        case "R":
                            line?.type = BILineType.ReserveLine.rawValue as NSNumber
                            break
                        case " ":
                            line?.type = BILineType.BlankLine.rawValue as NSNumber
                            break
                        case "M":
                            line?.type = BILineType.MixedLine.rawValue as NSNumber
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
                                if line?.type?.intValue == BILineType.ReserveLine.rawValue{
                                    line?.isETOPSRES = true
                                    line?.isETOPS = false
                                }else{
                                    line?.isETOPSRES = false
                                }
                                // If line type is mixedlinetype(contains both normal and reserve trips) then we need to consider the lines as Etops Reserve line
                                if line?.type?.intValue == BILineType.MixedLine.rawValue{
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
                            if line?.isETOPS?.intValue == 1 && line?.type?.intValue != BILineType.ReserveLine.rawValue {
                                line?.type = NSNumber(value: BILineType.NonReserveEtops.rawValue)
                            }
                            
                            // Non-ETOPS Reserve
                            if line?.type?.intValue == BILineType.ReserveLine.rawValue && line?.isETOPS?.intValue == 0, line?.isETOPSRES?.intValue == 0 {
                                line?.type = NSNumber(value: BILineType.NonEtopsReserve.rawValue)
                            }
                            
                            // ETOPS Reserve
                            if line?.type?.intValue == BILineType.ReserveLine.rawValue && line?.isETOPS?.intValue == 1 {
                                line?.type = NSNumber(value: BILineType.EtopsReserve.rawValue)
                            }
                            
                            // Non-ETOPS Hard CONUS
                            if line?.type?.intValue == BILineType.HardConUS.rawValue && line?.isETOPS?.intValue == 0 {
                                line?.type = NSNumber(value: BILineType.NonEtopsConUS.rawValue)
                            }
                            
                            // Non-ETOPS Hard (2nd round)
                            if self.bidPeriod?.isSecondRoundBid() == true && line?.type?.intValue == BILineType.HardLine.rawValue && line?.isETOPS?.intValue == 0 {
                                line?.type = NSNumber(value: BILineType.NonEtopsHard.rawValue)
                            }
                            
                            // Non-ETOPS Mixed (2nd round)
                            if self.bidPeriod?.isSecondRoundBid() == true && line?.type?.intValue == BILineType.MixedLine.rawValue && line?.isETOPS?.intValue == 0 {
                                line?.type = NSNumber(value: BILineType.NonEtopsMixed.rawValue)
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
            // Init last line read.
            if self.bidPeriod!.isFirstRoundBid(){
                self.initDerivedPropertiesForLine(line: line!, isReprocessing: false)
            }
            self.pilotLines = pLines
            if success && moc.hasChanges{
                do{
                    try moc.save()
                }catch{
                    print("Error saving to context: \(error)")
                    //handle error
                    success =  false
                }
            }
        }catch{
            print("Error reading file: \(error)")
            success = false
        }
        self.saveToDictionary()
        return success
    
    }
    
    //MARK: Read Trips file FA - done
    private func readTripsFA() -> Bool{
        var success = true
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
                                print("Error saving context: \(error.localizedDescription)")
                                if let nserror = error as NSError? {
                                    print("Core Data Error: \(nserror), \(nserror.userInfo)")
                                }
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
                        tripInfo?.returnTime = CBUtils.convertMinsToHHMM((leg?.arriveMinutes!.intValue)!) as NSNumber
                        let herbValueStr = UserDefaults.standard.string(forKey: KCBCustomizedHerbValue)
                        let herbValue: Int

                        if let herbValueStr = herbValueStr, !herbValueStr.isEmpty {
                            herbValue = Int(herbValueStr)!
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
                    if fileString.substring(with: NSRange(location: 74, length: 1)) == "O"{
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
                    let equipmentStr = fileString.substring(with: NSRange(location: 9, length: 3))
                    let equipment = equipmentStr.first!
                    leg?.equipment = String(equipment)
                    
                    //Aircraft change
                    let isAircraftChange = fileString.character(at: 66) == UnicodeScalar("1").value
                    leg?.isAircraftChange = isAircraftChange as NSNumber
                    
                    //Leg pay
                    let legPay = fileString.substring(with: NSRange(location: 67, length: 4))
                    leg?.pay = legPay.floatValue/100 as NSNumber
                    
                    if legIndex == 0 && dayIndex == 0{
                        tripInfo?.departTime = CBUtils.convertMinsToHHMM((leg?.departMinutes!.intValue)!) as NSNumber
                    }
                
                    //Etops
                    let etopschar = fileString.substring(with: NSRange(location: 73, length: 1))
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
            tripInfo?.returnTime = CBUtils.convertMinsToHHMM((leg?.arriveMinutes!.intValue)!) as NSNumber
            
            let herbValueStr = UserDefaults.standard.string(forKey: KCBCustomizedHerbValue)
            let herbValue: Int
            if let herbValueStr = herbValueStr, !herbValueStr.isEmpty {
                herbValue = Int(herbValueStr)!
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
                    
                    //Create Line
                    line = BILine(context: moc)
                    let moc = line!.managedObjectContext!
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
                    line?.type = NSNumber(value: BILineType.HardConUS.rawValue)
                    
                    //Read trips
                    if !self.readTripsForLine(line: line!, record: lineFile, isReserve: false){
                        //handle error
                        success = false
                        return false
                    }
                }else if lineFile.hasPrefix("A"){
                    line?.type = BILineType.ReserveLine.name() as NSNumber
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
            linesFetch.predicate = NSPredicate(format: "bidPeriod == %@", self.bidPeriod!)
            linesFetch.sortDescriptors = [NSSortDescriptor(key: "number", ascending: true)]
            let objResults = try moc.fetch(linesFetch)
            
            for case let line as BILine in objResults{
                for case let trip as BITrip in line.orderedTrips{
                    let tripOrderedDays = (trip.info?.orderedDays())!
                    for case let dayInfo as BIDayInfo in tripOrderedDays{
                        let dayOrderedLegs = dayInfo.orderedLegs
                        for case let legInfo as BILegInfo in dayOrderedLegs{
                            let arriveCity = (legInfo.arriveCity)!
                            let isIntlCity = self.intlCities[arriveCity]
                            if isIntlCity != nil{
                                line.type = BILineType.HardNonConUS.rawValue as NSNumber
                            }
                            if legInfo.isEtopsFlight?.boolValue == true{
                                line.isETOPS = true
                            }
                            else{
                                if line.isETOPS == nil{
                                    line.isETOPS = false
                                }
                            }
                        }
                    }
                }
                if self.bidPeriod?.isEtopsLinesContainsInBid?.intValue == 1{
                    if (self.bidPeriod?.isSecondRoundBid())! && (line.isETOPS?.intValue == 1) && !(line.type!.intValue == BILineType.ReserveLine.rawValue){
                        line.type = BILineType.NonReserveEtops.rawValue as NSNumber
                    }
                    if (self.bidPeriod?.isSecondRoundBid())! && (line.type!.intValue == BILineType.ReserveLine.rawValue) && (line.isETOPS?.intValue == 0){
                        line.type = BILineType.NonEtopsReserve.rawValue as NSNumber
                    }
                    if (line.type!.intValue == BILineType.HardConUS.rawValue) && (line.isETOPS?.intValue == 0){
                        line.type = BILineType.NonEtopsConUS.rawValue as NSNumber
                    }
                    if (line.type!.intValue == BILineType.HardNonConUS.rawValue) && (line.isETOPS?.intValue == 0){
                        line.type = BILineType.NonEtopsNonConUS.rawValue as NSNumber
                    }
                    if (self.bidPeriod?.isFirstRoundBid())! && (line.isETOPS?.intValue == 1){
                        line.type = BILineType.EtopsFAFirstRound.rawValue as NSNumber
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
            self.saveToDictionary()
        }catch{
            print("Error reading line file: \(error.localizedDescription)")
            success = false
        }
        return success
    }

    private func saveToDictionary(){
        let context = dataSource.managedObjectContext
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
            line.vTpLPay = NSNumber(value: (line.lineRig!.floatValue) + (line.vVacationPay!.floatValue))
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
        let moc = self.bidPeriod!.managedObjectContext!
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
        let commutesRequired = 0
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
        let minimumOvernightMinsPlaceholder = 1000000
        var minimumOvernightMinutes = minimumOvernightMinsPlaceholder
        var maximumOvernightMinutes = 0
        let redeyesCount = 0
        var faPay: Float = 0
        let base = self.bidPeriod!.base
        var tripStartDates: [Date] = []
        var tripEndDates: [Date] = []
        let df = DateFormatter()
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
        let departFormatter = DateFormatter()
        departFormatter.dateFormat = "HHmm"
        let arriveFormatter = DateFormatter()
        arriveFormatter.dateFormat = "HHmm"
        workBP = 0
        workBPInVac = 0
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
            tripNumLegs = 0
            
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
            let tripOrderedDays = trip.info!.orderedDays()
            var dayCount = 0
            
            let monthBitIndex = self.calendarData.indexForDate(date:trip.startDate!)
            
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
                    dateCompsReport.minute = ((dayOrderedLegs.first as? BILegInfo)?.departMinutes!.intValue)! - (trip.info!.briefMinutes!.intValue)
                }else{
                    dateCompsReport.minute = ((dayOrderedLegs.first as? BILegInfo)?.departMinutes!.intValue)! - (trip.info!.debriefMinutes!.intValue)
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
                dateCompsReport.minute = ((dayOrderedLegs.last as? BILegInfo)?.arriveMinutes!.intValue)! + (trip.info!.debriefMinutes!.intValue)
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
                    
                    if !(line.type?.intValue == BILineType.ReserveLine.rawValue) && arriveCity == base{
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
                            line.type = BILineType.HardNonConUS.rawValue as NSNumber
                            if line.isETOPS?.intValue == 0 && ((self.bidPeriod?.isEtopsLinesContainsInBid) != nil){
                                line.type = BILineType.NonEtopsNonConUS.rawValue as NSNumber
                            }
                        }
                        if self.bidPeriod!.isSecondRoundBid(){
                            if self.bidPeriod!.isFABid(){
                                line.type = BILineType.HardNonConUS.rawValue as NSNumber
                                if line.isETOPS?.intValue == 0 && ((self.bidPeriod?.isEtopsLinesContainsInBid) != nil){
                                    line.type = BILineType.NonEtopsNonConUS.rawValue as NSNumber
                                }
                            }
                        }
                        if self.bidPeriod?.isEtopsLinesContainsInBid?.intValue == 1 && !self.bidPeriod!.isFABid(){
                            if line.type?.intValue == BILineType.HardNonConUS.rawValue && line.isETOPS?.intValue == 0 &&
                                ((self.bidPeriod?.isEtopsLinesContainsInBid) != nil) {
                                line.type = BILineType.NonEtopsNonConUS.rawValue as NSNumber
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
                        dateComps.minute = ((dayOrderedLegs.first)?.departMinutes!.intValue)! - (trip.info!.briefMinutes!.intValue)
                    }
                    else{
                        dateComps.minute = ((dayOrderedLegs.first)?.departMinutes!.intValue)! - (trip.info!.debriefMinutes!.intValue)
                        }
                    departDate = appCal!.date(from: dateComps)
                    dateComps.minute = ((dayOrderedLegs.last)?.arriveMinutes!.intValue)! + (trip.info!.debriefMinutes!.intValue)
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
                    if trip.info?.calendarDaysCount != NSNumber(value: trip.info!.orderedDays().count){
                        let missingDateIndex =  CBUtils.findMissingIndex(inRedEyeTrip: trip)
                        let missingDate = CBUtils.findMissingDate(forRedEyeTrip: trip)
                        let calendar = Calendar.current
                        let date1 = calendar.startOfDay(for: (day?.date)!)
                        let date2 = calendar.startOfDay(for: missingDate!)
                        
                        let result = date1.compare(date2)
                        
                        if result == .orderedSame && missingDateIndex == dayCount && missingDateIndex != trip.info?.orderedDays().count{
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
                        for case let legInfo in (day?.info?.orderedLegs)!{
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
                    dayInfo.firstLeg = dayInfo.orderedLegs.first
                }
                if dayCount == (trip.info?.orderedDays().count)! - 1{
                    tripEndMonthBits |= one << (monthBitIndex + dayCount)
                }
                // Max legs in a day
                if dayNumLegs > maxLegsInADay{
                    maxLegsInADay = dayNumLegs
                }
                dayCount += 1
                
                // Minimum and maximum overnight times
                
                let legInfo = dayInfo.orderedLegs.last
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
            if line.type?.intValue == BILineType.BlankLine.rawValue{
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
        line.minimumOvernightHours = Float(minimumOvernightMinutes) / 60.0 as NSNumber
        line.maximumOvernightHours = Float(maximumOvernightMinutes) / 60.0 as NSNumber
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
        if line.number == 305 {
            print("")
        }
        self.initRigRelatedProperties(for: line, isReprocessing: isReprocessing)
        self.calculateNewProperties(line: line)
        self.updateEndDateForRedEyeTrips(line: line)
    }
    
    private func initRigRelatedProperties(for line:BILine, isReprocessing:Bool){
        let isFABid = self.isFABid()
        let appCal = self.calendarData.bidPeriodCalendar()
        line.holidayPay = 0
        
        //Day Related Rigs
        var rigDHR:Float = 0 // Duty Hour Ratio
        var rigDPM:Float = 0 // Duty Period Minimum
        
        //Trip Related Rigs
        var rigADG:Float = 0 // Average Daily Guarantee
        var rigTHR:Float = 0 // Trip Hour Ratio
        
        var vcCarryOutPay:Float = 0
        
        for case let trip as BITrip in line.trips!{
            if trip.vacationOverlapType?.intValue != 0{
                if self.includeDroppedTrips!{
                    trip.dropForFiltersSorts = false
                }else{
                    trip.dropForFiltersSorts = true
                    continue
                }
            }
           
            var dateComps = DateComponents()
            dateComps.year = trip.line?.bidPeriod?.year?.intValue
            dateComps.month = trip.line?.bidPeriod?.month?.intValue
            dateComps.day = trip.startDay?.intValue
            
            var departDate:Date!
            var arriveDate:Date!
            var dayDutyMinutes = 0
            let tripOrderedDays = trip.info!.orderedDays()
            var dayCount = 0
            var tripActualPay:Float = 0
            
            for dayInfo in tripOrderedDays{
                let dayOrderedLegs = dayInfo.orderedLegs
                
                let day = trip.orderedDays[dayCount] as BIDay
                if !(AppState.shared.isHistoricBid){
                    if (day.info?.dayPay == 0) && !isFABid{
                        return
                    }
                }
                if dayOrderedLegs.count > 0{
                    if tripOrderedDays[0] == dayInfo{
                        dateComps.minute = dayOrderedLegs[0].departMinutes!.intValue - trip.info!.briefMinutes!.intValue
                    }else{
                        dateComps.minute = dayOrderedLegs[0].departMinutes!.intValue - trip.info!.debriefMinutes!.intValue
                    }
                    departDate = appCal!.date(from: dateComps)!
                    
                    dateComps.minute = dayOrderedLegs.last!.arriveMinutes!.intValue + trip.info!.debriefMinutes!.intValue
                    arriveDate = appCal!.date(from: dateComps)!
                    dayDutyMinutes = appCal!.dateComponents([.minute], from: departDate, to: arriveDate).minute!
                }
                //Day Rig Calculation
                let dutyHourMinPayRatio:Float = 0.74 // Duty Hour Rig
                var dayMinimum:NSNumber = isFABid ? 4 : 5  // Duty Period Minimum
                let dayActualPay = Float(day.info!.dayPay)
                var dayMinimumBasedOnDutyHour = (Float(dayDutyMinutes) / 60 * dutyHourMinPayRatio) as NSNumber
                if dayMinimum.floatValue >= dayMinimumBasedOnDutyHour.floatValue{
                    dayMinimumBasedOnDutyHour = 0
                }else{
                    dayMinimum = 0
                }
                let dayMaxValue = fmaxf(dayMinimum.floatValue, fmaxf(dayActualPay, dayMinimumBasedOnDutyHour.floatValue))
                day.info?.dayPayWithRig = dayMaxValue as NSNumber
                
                if dayMaxValue > dayActualPay{
                    if dayMinimum != 0{
                        rigDPM = rigDPM + (dayMaxValue - dayActualPay)
                    }else{
                        rigDHR = rigDHR + (dayMaxValue - dayActualPay)
                    }
                }
                tripActualPay = tripActualPay + dayMaxValue
                dayCount += 1
                
                if trip.isReserve{
                    day.info?.dayPayWithRig = isFABid ? 6.5 : 6
                    tripActualPay = isFABid ? 6.5 : 6
                }
            }
            //Trip Rig Calculation
            let tripHourRatio:Float = 3 //TAFB
            let tripMinimumDefaultPay:Float = (trip.isReserve && !isFABid) ? 6 : 6.5 // 6.5 for FA reserve
            
            var tripMinimum = NSNumber(value: Float(trip.orderedDays.count) * tripMinimumDefaultPay)
            var tripMinimumBasedOnTAFBHour:NSNumber = 0
            if line.number!.intValue > 305{
                print("")
            }
//            print(line.number!.intValue)
            if trip.isReserve{
                tripMinimumBasedOnTAFBHour = 0
            }else{
                tripMinimumBasedOnTAFBHour = NSNumber(value:( (trip.info?.tafbMinutes!.floatValue)! / 60) / tripHourRatio)
            }
            if tripMinimum.floatValue >= tripMinimumBasedOnTAFBHour.floatValue{
                tripMinimumBasedOnTAFBHour = 0
            }else{
                tripMinimum = 0
            }
            
            if trip.isRedEyeTrip{
                let domicileDayCount = trip.info!.calendarDaysCount!
                
                if domicileDayCount.intValue == 1{
                    tripMinimum = 6.5
                }else{
                    tripMinimum = domicileDayCount.floatValue * 6.5 as NSNumber
                }
            }
            
            let tripMaxValue = fmaxf(tripMinimum.floatValue, fmaxf(tripActualPay, tripMinimumBasedOnTAFBHour.floatValue))
            
            if tripMaxValue > tripActualPay{
                if tripMinimum != 0{
                    rigADG = rigADG + (tripMaxValue - tripActualPay)
                }else{
                    rigTHR = rigTHR + (tripMaxValue - tripActualPay)
                }
            }
            
            self.tripRigDistributionCalculation(for: trip)
            
            var isHolidayPayForRedEyeAdded = false
            var missingDateIndex = -1
            var missingRedEyeDate:Date!
            
            if trip.isRedEyeTrip {
                missingDateIndex = CBUtils.findMissingIndex(inRedEyeTrip: trip)
                missingRedEyeDate = CBUtils.findMissingDate(forRedEyeTrip: trip)
            }
            var dayCountSecondLoop = 0
            let dutyDates = self.datesOnlyArrayFromTrip(trip: trip)
            
            for dayInfo in tripOrderedDays{
                let day = trip.orderedDays[dayCountSecondLoop] as BIDay
                if !self.calendarData.dateIsInBidMonth(date: day.date!) && !self.calendarData.dateIsBeforeFirstDateOfBidMonth(date: day.date!){
                    vcCarryOutPay += day.info!.dayPayWithRig!.floatValue
                }
                let dayMaxValue = day.info?.dayPayWithRig?.floatValue
                if trip.isRedEyeTrip{
                    if self.isFABid(){
                        var dayDate = day.date!
                        if tripOrderedDays.count == dutyDates.count{
                            dayDate = dutyDates[dayCountSecondLoop]
                        }else{
                            if missingRedEyeDate != nil && missingDateIndex == dayCountSecondLoop{
                                dayDate = missingRedEyeDate
                            }
                        }
                        if missingRedEyeDate != nil && !isHolidayPayForRedEyeAdded{
                            let holidayPay = self.holidayCalculation(for: dayDate, day: day, line: line, dayInfo: dayInfo, maxPay: dayMaxValue!)
                            line.holidayPay = (line.holidayPay as! Float + holidayPay) as NSNumber
                            if holidayPay != 0{
                                isHolidayPayForRedEyeAdded = true
                            }
                        }
                    }else{
                        if missingRedEyeDate != nil && !isHolidayPayForRedEyeAdded{
                            if self.isDatePilotHolidayDate(date: missingRedEyeDate, displayType: day.redEyeDayDisplayDayType!, line: line){
                                line.holidayPay = NSNumber(value: (line.holidayPay!.doubleValue) + 6.5)
                                isHolidayPayForRedEyeAdded = true
                            }
                        }
                    }
                }else{
                    let holidayPay = self.holidayCalculation(for: day.date!, day: day, line: line, dayInfo: dayInfo, maxPay: dayMaxValue!)
                    line.holidayPay = (line.holidayPay as! Float + holidayPay) as NSNumber
                }
               dayCountSecondLoop += 1
            }
        }
        
        
        line.rigADG = rigADG as NSNumber // Average Daily Guarantee
        line.rigDPM = rigDPM as NSNumber // Duty Period Minimum
        line.rigDHR = rigDHR as NSNumber // Duty Hour Ratio
        line.rigTHR = rigTHR as NSNumber // Trip Hour Ratio
        
        if isReprocessing{
            if (self.bidPeriod?.vacations?.allObjects.count)! > 0{
                line.pay = line.vTotalPay?.floatValue as? NSNumber
            }else{
                line.pay = NSNumber(value: (line.actualPay!.floatValue) + (line.holidayPay!.floatValue))
            }
        }else{
            line.pay = NSNumber(value: (line.actualPay!.floatValue) + (line.holidayPay!.floatValue) + (line.lineRig!.floatValue))
        }
        
        if line.orderedTrips.count == 0{
            switch self.bidPeriod?.month?.intValue{
            case 2:line.pay = self.isFABid() ? 85 : 84
                break
            case 4,6,9,11:line.pay = 87
                break
            default:line.pay = 89
                break
            }
        }
        
        
        line.carryOutPay = vcCarryOutPay as NSNumber
        line.payPlusCo = vcCarryOutPay + line.pay!.floatValue as NSNumber
        line.coPlusHoli = NSNumber(value: (line.coHoli!.floatValue) + (line.carryOutPay!.floatValue))
        
        if line.pay!.floatValue > 0 && line.blockMinutes!.floatValue > 0 {
            line.payPerBlockHour = NSNumber(value: ((line.pay!.floatValue) * 60) / (line.blockMinutes!.floatValue))
        }
        if line.pay!.floatValue > 0 && line.numLegs!.intValue > 0 {
            line.payPerTrip = NSNumber(value: (line.pay!.floatValue) / (line.numTrips!.floatValue))
        }
        if line.pay!.floatValue > 0 && line.numLegs!.intValue > 0 {
            line.payPerLeg = NSNumber(value: (line.pay!.floatValue) / (line.numLegs!.floatValue))
        }else{
            line.payPerLeg = 0
        }
        
        if line.pay!.floatValue > 0 && line.workDays!.intValue > 0 {
            line.payPerDay = NSNumber(value: (line.pay!.floatValue) / Float((line.workDays!.intValue - line.overlapDaysCount!.intValue)))
            if line.workDays!.intValue - line.overlapDaysCount!.intValue == 0{
                line.payPerDay = 0
            }
        }
        
        if line.pay!.floatValue > 0 && line.tafbMinutes!.intValue > 0 {
            line.payPerTAFB = NSNumber(value: ((line.pay!.floatValue) * 60) / (line.tafbMinutes!.floatValue))
        }else{
            line.payPerTAFB = 0
        }
        
        if line.pay!.floatValue > 0 && line.dutyMinutes!.intValue > 0 {
            line.payPerDutyTime = NSNumber(value: ((line.pay!.floatValue * 60) / (line.dutyMinutes!.floatValue)))
        }else{
            line.payPerDutyTime = 0
        }

        if (line.dutyHours!.intValue > 0) && (line.workDays!.intValue > 0) {
            line.dutyHoursPerDay = NSNumber(value: (line.dutyHours!.floatValue) / (line.workDays!.floatValue))
        }
        
    }
    
    private func calculateNewProperties(line:BILine){
        var gtTotal = 0
        var gtMax = 0
        var groundCount = 0
        var redEyeCount = 0
        for case let trip as BITrip in line.trips! {
            if trip.dropForFiltersSorts == 0{
                let tripOrderedDays = trip.info!.orderedDays()
                for dayInfo in tripOrderedDays{
                    let dayOrderedLegs = dayInfo.orderedLegs
                    //Calculation will only happen if there are more than one dayOrderedLegs, because if there's only one leg, it's the last leg(Over night).
                    if dayOrderedLegs.count > 1{
                        // If there is more than one leg ordered for the day, we should remove the last leg, which is the overnight one.
                        let subArrayWithoutLastLeg = Array(dayOrderedLegs.dropLast())
                        for case let legInfo in subArrayWithoutLastLeg{
                            if legInfo.isRedEyeFlight?.boolValue == true{
                                redEyeCount += 1
                            }
                            var groundMinutes = 0
                            if legInfo.nextLeg != nil {
                                // Calculate the total ground time.
                                groundMinutes = legInfo.groundMinutes.intValue
                                groundCount += 1
                                gtTotal += groundMinutes
                            }
                            //Check if groundMinutes is greater than the current greatest minute stored in gtMax.If gtMax.integerValue < groundMinutes then that groundMinutes will store to gtMax.
                            if gtMax < groundMinutes{
                                gtMax = groundMinutes
                            }
                        }
                    }
                }
            }
        }
        line.gTmax = gtMax as NSNumber
        if groundCount != 0{
            let doubleValue = Double(gtTotal)/Double(groundCount)
            let roundedValue = round(doubleValue)
            let roundedNum = NSNumber(value: roundedValue)
            line.gTavg = roundedNum
        }else{
            line.gTavg = 0
        }
        
        // Calculate Overnight Average (ovAvg)
        
        var ovMinutes = 0
        var ovCount = 0
        
        for case let trip as BITrip in line.trips! {
            if !trip.isReserve && trip.dropForFiltersSorts == 0 {
                let tripOrderedDays = trip.orderedDays
                
                var missingRedEyeDate:Date!
                if trip.isRedEyeTrip{
                    missingRedEyeDate = CBUtils.findMissingDate(forRedEyeTrip: trip)!
                }
                var redEyeDatehandledForOvernight = false
                
                for day in tripOrderedDays {
                    let releaseTime = (day.info?.releaseTime!.intValue)! % 2400
                    var nextDayReportTime = ((day.info?.nextDay?.reportTime?.intValue ?? 0)) % 2400
                    
                    if trip.isRedEyeTrip{
                        let isDaysCountSame = trip.info!.calendarDaysCount != NSNumber(value: trip.info!.orderedDays().count)
                        if isDaysCountSame && missingRedEyeDate != nil && !redEyeDatehandledForOvernight{
                            nextDayReportTime += 2400
                            redEyeDatehandledForOvernight = true
                        }
                    }
                    
                    if nextDayReportTime != 0 {
                        let minutes = CBUtils.getGroundTimeBetween(reportTime: nextDayReportTime, releaseTime: releaseTime)
                        let hours = CBUtils.convertMinsToHHMM(minutes)
                        let convertedMin = CBUtils.convertTimeToMinutes(hours)!
                        ovMinutes += convertedMin
                        ovCount += 1
                        
                    }
                }
            }
        }
        if ovCount != 0 {
            let calculatedMinutes = ovMinutes / ovCount
            line.ovAvg = calculatedMinutes as NSNumber
        }else{
            line.ovAvg = 0
        }
        
        // One Or two days off between Workblocks
        var oneOrTwoDaysCount = 0
        
        if line.workBlocks!.count > 1 {
            let workBlocksArray = (line.workBlocks?.allObjects as? [WorkBlockList])?.sorted {
                $0.startDateTime!.compare($1.startDateTime!) == .orderedAscending
            }
            
            for i in 0..<workBlocksArray!.count - 1{
                let currentWorkBlock = workBlocksArray![i]
                let nextWorkBlock = workBlocksArray![i+1]
                
                let dateFormatter  = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                dateFormatter.timeZone = TimeZone(identifier: "GMT")
                
                let fromDateStr = dateFormatter.string(from: currentWorkBlock.endDateOnly!)
                let toDateStr = dateFormatter.string(from: nextWorkBlock.startDateTime!)
                
                let startDate = dateFormatter.date(from: fromDateStr)
                let endDate = dateFormatter.date(from: toDateStr)
                
                if startDate?.compare(endDate!) == .orderedAscending {
                    let daysCount = BICalendarData().daysBetweenDate(fromDateTime: startDate!, toDateTime: endDate!) - 1
                    if daysCount == 1 || daysCount == 2{
                        oneOrTwoDaysCount += 1
                    }
                }
            }
        }else{
            oneOrTwoDaysCount = 0
        }
        line.redeyes = line.redEyeCount
        line.redEyeTrips = line.redEyeCount
        if line.redEyeCount.intValue != 0 {
            line.amPM = BILineAMPM.RedEyeAMPMLine.rawValue as NSNumber
        }
        line.oneOrTwoDaysCount = oneOrTwoDaysCount as NSNumber
        line.payPlusCo = NSNumber(value: (line.carryOutPay!.floatValue) + (line.pay!.floatValue))
    }
    
    private func updateEndDateForRedEyeTrips(line:BILine){
        for case let trip as BITrip in line.trips! {
            if trip.isRedEyeTrip{
                if trip.info?.calendarDaysCount == trip.info!.orderedDays().count as NSNumber{
                    if CBUtils.findMissingDate(forRedEyeTrip: trip) != nil {
                        trip.endDate = self.calendarData.dateForDayOfMonth(dayOfMonth: trip.startDay!.intValue + ((trip.info?.orderedDays().count)!-1)+1)
                    }
                }
            }
        }
    }

    
    private func addSecondRoundTripsForBidPeriod() -> Bool {
        var success = true
        // Open lines text file
        // Lines text
        let directoryURL = BIBidInfo.shared.downloadDirectory()
        let textFileURL = directoryURL.appendingPathComponent(BIBidInfo.shared.linesTextFilename())
        let fileInfo = try! String(contentsOf: textFileURL, encoding: .utf8)
        if fileInfo.isEmpty && !AppState.shared.isMockData{
            //handle error
            success = false
        }
        // A dictionary to hold the second round trips that are created.
        var round2Trips: [String: Any] = [:]
        let bpLines = self.pilotLines
        
        for (_,value) in bpLines{
            let line = value as? BILine
            var r2TripsToRead: [Any] = []
            for case let trip as BITrip in line!.trips! {
                if self.trips[trip.number!] == nil {
                    line?.containsPartialTrip = false
                    r2TripsToRead.append(String(trip.number!.prefix(4)))
                    let dupTrips = r2TripsToRead.filter { ($0 as? String)?.hasPrefix(String(trip.number!.prefix(4))) == true }
                    
                    let r2Trip = self.readTripFromJson(trip: trip, tripSequence: dupTrips.count, line: line!, showPPAlert: self.showAlertForPP)
                    
                    if r2Trip != nil {
                        trip.info = r2Trip
                        round2Trips[trip.number!] = r2Trip
                    }
                    else{
                        //handle error
                        success = false
                    }
                }
            }
            self.initDerivedPropertiesForLine(line: line!, isReprocessing: false)
        }
        return success
    }
    
    private func readTripLegsPay() -> Bool{
        var success = true
        let fileURL = BIBidInfo.shared.downloadDirectory().appendingPathComponent(BIBidInfo.shared.tripsTextFilename())
        let tripsText = try! String(contentsOf: fileURL, encoding: .utf8)
        
        if tripsText.isEmpty{
            //handle error
            return false
        }

        let scanner = Scanner(string: tripsText)
        var arrCityCharSet = CharacterSet.uppercaseLetters
        arrCityCharSet.insert(charactersIn: "*")
        var blkCharSet = CharacterSet.decimalDigits
        blkCharSet.insert(charactersIn: ":")
        
        let tripKeys = Array(self.trips.keys).sorted { "\($0)" < "\($1)" }
        var legPay:Double = 0
        var count = 0
        
        for tripNum in tripKeys{
            
            //scan trip number
            _ = scanner.scanString(tripNum)
            
            let trip = self.trips[tripNum]! as? BITripInfo
            
            for day in trip!.orderedDays(){
                for case let leg in day.orderedLegs{
                    // check to see if trip is FA Reserve
                    if self.bidPeriod!.isFABid() && leg.departCity == leg.arriveCity{
                        continue
                    }
            
                    // scan past leg arrive city
                    _ = scanner.scanUpToString(leg.arriveCity!)
                    _ = scanner.scanCharacters(from: arrCityCharSet)
                    // if leg is reserve, depart and arrive cities are the same, so
                    // must scan past second occurrence of leg arrive city
                    
                    if leg.departCity == leg.arriveCity{
                        _ = scanner.scanUpToString(leg.arriveCity!)
                        _ = scanner.scanCharacters(from: arrCityCharSet)
                    }
                    // scan past leg arrive time
                    _ = scanner.scanInt()
                    // scan past leg block
                    _ = scanner.scanUpToCharacters(from: blkCharSet)
                    _ = scanner.scanCharacters(from: blkCharSet)
                    
                    // scan leg pay
                    if let scannedPay = scanner.scanDouble(){
                        legPay = scannedPay
                    }
                    leg.pay = legPay as NSNumber
                }// End legs loop
            }// End day loop
            count += 1
        }
        if dataSource.managedObjectContext.hasChanges {
            do{
                try dataSource.managedObjectContext.save()
            }catch{
                //Handle error
                success = false
            }
        }
        return success
    }
    
   
    
    private func holidayCalculation(for date:Date, day:BIDay, line:BILine, dayInfo:BIDayInfo, maxPay:Float) -> Float{
        var isHoliday = false
        if !self.isFABid(){
            var holidayPay:Float = 0
            if self.isDatePilotHolidayDate(date: day.date!, displayType: day.displayType!, line: line){
                holidayPay = 6.5
            }
            return holidayPay
        }else{
            if self.isDateFAHolidayDate(day: day, date: date, line: line){
                isHoliday = true
            }
        }
        var holidayPay:Float = 0
        let tripDayInfo = day.info
        if isHoliday{
            holidayPay = tripDayInfo == nil ? 0 : maxPay
        }
        return holidayPay
    }
    
    
    private func isDatePilotHolidayDate(date: Date, displayType: NSNumber, line: BILine) -> Bool {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        
        let specialDates: [[Int]] = [
            // Easter
            [2024, 3, 31], [2025, 4, 20], [2026, 4, 5], [2027, 3, 28], [2028, 4, 16], [2029, 4, 1], [2030, 4, 21],
            // New Year
            [2024, 1, 1], [2025, 1, 1], [2026, 1, 1], [2027, 1, 1], [2028, 1, 1], [2029, 1, 1], [2030, 1, 1],
            // Memorial Day (effective from 2027)
            [2027, 5, 31], [2028, 5, 29], [2029, 5, 28], [2030, 5, 27],
            // Independence Day
            [2024, 7, 4], [2025, 7, 4], [2026, 7, 4], [2027, 7, 4], [2028, 7, 4], [2029, 7, 4], [2030, 7, 4],
            // Labor Day (effective from 2026)
            [2026, 9, 7], [2027, 9, 6], [2028, 9, 4], [2029, 9, 3], [2030, 9, 2],
            // Thanksgiving
            [2024, 11, 28], [2025, 11, 27], [2026, 11, 26], [2027, 11, 25], [2028, 11, 23], [2029, 11, 22], [2030, 11, 28],
            // Christmas Eve
            [2024, 12, 24], [2025, 12, 24], [2026, 12, 24], [2027, 12, 24], [2028, 12, 24], [2029, 12, 24], [2030, 12, 24],
            // Christmas
            [2024, 12, 25], [2025, 12, 25], [2026, 12, 25], [2027, 12, 25], [2028, 12, 25], [2029, 12, 25], [2030, 12, 25],
            // New Year’s Eve
            [2024, 12, 31], [2025, 12, 31], [2026, 12, 31], [2027, 12, 31], [2028, 12, 31], [2029, 12, 31], [2030, 12, 31]
        ]
        
        for specialDate in specialDates {
            let (year, month, day) = (specialDate[0], specialDate[1], specialDate[2])
            
            if components.year == year && components.month == month && components.day == day {
                if month != self.bidPeriod!.month?.intValue && displayType.intValue == BIDayDisplayType.normal.rawValue {
                    line.coHoli = 6.5
                    return false
                }
                return true
            }
        }
        
        return false
    }
    
    private func isDateFAHolidayDate(day: BIDay, date: Date, line: BILine) -> Bool {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)

        let specialDates: [[Int]] = [
            // Memorial Day
            [2024, 5, 27], [2025, 5, 26], [2026, 5, 25], [2027, 5, 31], [2028, 5, 29], [2029, 5, 28], [2030, 5, 27],
            // 4th of July
            [2024, 7, 4], [2025, 7, 4], [2026, 7, 4], [2027, 7, 4], [2028, 7, 4], [2029, 7, 4], [2030, 7, 4],
            // Labor Day
            [2024, 9, 2], [2025, 9, 1], [2026, 9, 7], [2027, 9, 6], [2028, 9, 4], [2029, 9, 3], [2030, 9, 2],
            // Thanksgiving
            [2024, 11, 28], [2025, 11, 27], [2026, 11, 26], [2027, 11, 25], [2028, 11, 23], [2029, 11, 22], [2030, 11, 28],
            // Christmas Day
            [2024, 12, 25], [2025, 12, 25], [2026, 12, 25], [2027, 12, 25], [2028, 12, 25], [2029, 12, 25], [2030, 12, 25],
            // New Year’s Eve
            [2024, 12, 31], [2025, 12, 31], [2026, 12, 31], [2027, 12, 31], [2028, 12, 31], [2029, 12, 31], [2030, 12, 31]
        ]

        for specialDate in specialDates {
            let year = specialDate[0], month = specialDate[1], dayInt = specialDate[2]

            if components.year == year, components.month == month, components.day == dayInt {
                if month != self.bidPeriod!.month?.intValue, day.displayType?.intValue == BIDayDisplayType.normal.rawValue {
                    if let dayInfo = day.info {
                        var holidayPay = dayInfo.dayPay
                        if holidayPay < 4 {
                            holidayPay = 4
                        }
                        line.coHoli = NSNumber(value: holidayPay)
                    }
                    return false
                }
                return true
            }
        }
        return false
    }
    

    
    private func tripRigDistributionCalculation(for trip:BITrip){
        let isFABid = self.isFABid()
        let tripMinimumDefaultPay:Float = (trip.isReserve && !isFABid) ? 6 : 6.5 // This is for For CP only; For FA we need to show 6.5 for FA reserve
        var tripMinimumPay = NSNumber(value:Float(trip.info!.orderedDays().count) * tripMinimumDefaultPay).floatValue
        
        if trip.isRedEyeTrip {
            let domicileDayCount = trip.info!.calendarDaysCount!
            
            if domicileDayCount.intValue == 1{
                tripMinimumPay = 6.5
            }else{
                tripMinimumPay = domicileDayCount.floatValue * 6.5
            }
        }
        
        let tripActualPayWithDayRigs = trip.info!.getDayPaySumForTrips()
        let tripHourRatio:Float = 3    //TAFB
        var tripMinimumBasedOnTAFBHour:NSNumber = 0
        if trip.isReserve{
            tripMinimumBasedOnTAFBHour = 0
        }else{
            tripMinimumBasedOnTAFBHour = NSNumber(value: (trip.info!.tafbMinutes!.floatValue) / 60 / tripHourRatio)
        }
        
        if tripMinimumPay >= tripMinimumBasedOnTAFBHour.floatValue {
            tripMinimumBasedOnTAFBHour = 0
        }else {
            tripMinimumPay = 0
        }
        
        let tripMaxValue = fmaxf(tripMinimumPay, fmaxf(tripActualPayWithDayRigs, tripMinimumBasedOnTAFBHour.floatValue))
        var payToDistributeAdditionally = tripMaxValue - tripActualPayWithDayRigs
        
        if trip.info?.orderedDays().count == 1{
            let day = trip.info?.orderedDays()[0]
            day!.dayPayWithRig = tripMaxValue as NSNumber
        }else if trip.info?.orderedDays().count == 2{
            let day1 = trip.info?.orderedDays()[0]
            let day2 = trip.info?.orderedDays()[1]
            
            var pays:[NSNumber] = [day1!.dayPayWithRig!, day2!.dayPayWithRig!]
            let distributedPay = self.distributeRig(&pays, rig: &payToDistributeAdditionally)
            
            day1!.dayPayWithRig = distributedPay[0]
            day2!.dayPayWithRig = distributedPay[1]
        }else if trip.info?.orderedDays().count == 3{
            let day1 = trip.info?.orderedDays()[0]
            let day2 = trip.info?.orderedDays()[1]
            let day3 = trip.info?.orderedDays()[2]
            
            var pays:[NSNumber] = [day1!.dayPayWithRig!, day2!.dayPayWithRig!, day3!.dayPayWithRig!]
            let distributedPay = self.distributeRig(&pays, rig: &payToDistributeAdditionally)
            
            day1!.dayPayWithRig = distributedPay[0]
            day2!.dayPayWithRig = distributedPay[1]
            day3!.dayPayWithRig = distributedPay[2]
            
        }else if trip.info?.orderedDays().count == 4{
            let day1 = trip.info?.orderedDays()[0]
            let day2 = trip.info?.orderedDays()[1]
            let day3 = trip.info?.orderedDays()[2]
            let day4 = trip.info?.orderedDays()[3]
            
            var pays:[NSNumber] = [day1!.dayPayWithRig!, day2!.dayPayWithRig!, day3!.dayPayWithRig!, day4!.dayPayWithRig!]
            let distributedPay = self.distributeRig(&pays, rig: &payToDistributeAdditionally)
            
            day1!.dayPayWithRig = distributedPay[0]
            day2!.dayPayWithRig = distributedPay[1]
            day3!.dayPayWithRig = distributedPay[2]
            day4!.dayPayWithRig = distributedPay[3]
        }
        trip.info?.faPay = trip.info!.getDayPaySumForTrips() as NSNumber
    }
    
    private func distributeRig(_ pays: inout [NSNumber], rig: inout Float) -> [NSNumber] {
        let dayCount = pays.count
        while rig > 0{
            // Find the minimum payment and the indices of all days with this minimum payment.
            var minPay:Float = .greatestFiniteMagnitude
            var minIndices:[Int] = []
            
            for i in 0..<dayCount {
                let pay = pays[i].floatValue
                if pay < minPay {
                    minPay = pay
                    minIndices.removeAll()
                    minIndices.append(i)
                }else if pay == minPay{
                    minIndices.append(i)
                }
            }
            
            // Calculate the increment needed to equalize the minimum days.
            var nextMinPay:Float = .greatestFiniteMagnitude
            for i in 0..<dayCount {
                let pay = pays[i].floatValue
                if pay > minPay && pay < nextMinPay {
                    nextMinPay = pay
                }
            }
            
            var increment:Float = (nextMinPay == .greatestFiniteMagnitude) ? rig/Float(minIndices.count) : (nextMinPay - minPay)
            let requiredRig = increment * Float(minIndices.count)
            if rig >= requiredRig{
                for index in minIndices {
                    let idx = index.asNSNumber.intValue
                    pays[idx] = minPay + increment as NSNumber
                }
                rig -= requiredRig
            }else{
                increment = rig / Float(minIndices.count)
                for index in minIndices{
                    let idx = index.asNSNumber.intValue
                    pays[idx] = pays[idx].floatValue + increment as NSNumber
                }
                rig = 0
            }
        }
        return pays
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
                    else if (resultStart == .orderedSame || resultEnd == .orderedSame) {
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
                    
                    if trip.info?.calendarDaysCount?.intValue != trip.info?.orderedDays().count {
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
                workBP = workBP - 0
            } else {
                workBP = workBP - workBPInVac
            }
     
            line.workDaysBP = NSNumber(value: workBP)
        }
     
    private func datesOnlyArrayFromTrip(trip: BITrip) -> [Date] {
            var calendar = Calendar(identifier: .gregorian)
            calendar.locale = Locale(identifier: "en_US")
            calendar.timeZone = TimeZone(identifier: "US/Central")!
            guard let startDate = trip.startDate else { return [] }
            var dateComponents = calendar.dateComponents([.year, .month, .day], from: startDate)
            let df = DateFormatter()
            df.dateFormat = "dd-MM-yyyy"
            df.timeZone = TimeZone(identifier: "US/Central")!
            var tripDates: [String] = []
            for dayInfo in (trip.info?.orderedDays() as? [BIDayInfo]) ?? [] {
                let legs = dayInfo.orderedLegs
                    for legInfo in legs {
                        dateComponents.minute = legInfo.departMinutes?.intValue
                        let legStartDate = calendar.date(from: dateComponents)!
                        let dateString = df.string(from: legStartDate)
                        tripDates.append(dateString)
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
        var tripPosRange = NSRange(location: 0, length: 0)
        let tripResvStartRange = NSRange(location: 24, length: 4)
        let tripResvEndRange = NSRange(location: 35, length: 4)
        let resRept1 = NSRange(location: 24, length: 2)
        let resRls1 = NSRange(location: 35, length: 2)
        let resRept2 = NSRange(location: 26, length: 2)
        let resRls2 = NSRange(location: 37, length: 2)
        calendarData = calendarData.initWithBidPeriod(bidPeriod: self.bidPeriod!)!
        if isReserve{
            tripNumRange = NSRange(location: 12, length: 4)
            tripDateRange = NSRange(location: 17, length: 7)
            tripStartDayRange = NSRange(location: 17, length: 2)
            
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
            dateFormatter.dateFormat = "HHddMMMyy"
            let tripDate = dateFormatter.date(from: "12\(dateString)")
            let tripStartDay = record.substring(with: tripStartDayRange)
            trip?.startDay = Int(tripStartDay) as? NSNumber
            trip?.isReserveFa = true
            if (tripDate != nil){
                trip?.startDate = self.calendarData.dateForDate(date:tripDate!)
            }
            
            trip?.tripStartDay = self.getDay(from: (trip?.startDate)!)
            trip?.endDate = self.calendarData.dateForDayOfMonth(dayOfMonth:(trip?.startDay?.intValue)!+((trip?.info?.orderedDays().count)! - 1))
            
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
                    dateFormatter.dateFormat = "HHddMMMyy"
                    dateFormatter.timeZone = TimeZone(identifier: "US/Central")!
                    let tripDate = dateFormatter.date(from: "12\(dateStr)")
                    if (tripDate != nil){
                        trip.startDate = tripDate
                    }
                    trip.tripStartDay = self.getDay(from: trip.startDate ?? Date())
                    trip.endDate = self.calendarData.dateForDayOfMonth(dayOfMonth:(trip.startDay?.intValue)!+(trip.info?.orderedDays().count)! - 1)
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
            herbValue = Int(herbValueStr)!
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
        for _ in 0..<maxTripsPerRecord{
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
                                success = false
                                break
                            }
                        }
                        trip.line = line
                        trip.startDate = self.calendarData.dateForDayOfMonth(dayOfMonth:trip.startDay!.intValue)
                        trip.tripStartDay = self.getDay(from: trip.startDate!)
                        trip.endDate = self.calendarData.dateForDayOfMonth(dayOfMonth:(trip.startDay!.intValue+(trip.info?.orderedDays().count)!-1))
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
        
        if dict?["JsonTripData"] is NSNull{
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
            let tripNumWithSpecialChar = missingTripDict["TripNum"] as! String
            var startDay = "\(trip.startDay!)"
            if startDay.length == 1{
                startDay = "0\(trip.startDay!)"
            }
            let tripNumWithDay = "\(trip.number!)\(startDay)"
            
            if tripNumWithSpecialChar == tripNumWithDay{
                tripInfo = BITripInfo(context: moc)
                let dutyPeriodArray = missingTripDict["DutyPeriods"] as! [Any]
                let depTime = missingTripDict["DepTime"] as? String
                let arrTime = missingTripDict["RetTime"] as? String
                let debriefMinutes = missingTripDict["DebriefTime"] as? Int
                let briefMinutes = missingTripDict["BriefTime"] as? Int
                let tripInfoPayJSON = missingTripDict["Tfp"] as? Float
                let tripTAFBJSON = missingTripDict["Tafb"] as? Float
                tripInfo?.number = trip.number?.substring(to: 4)
                tripInfo?.departTime = Int(depTime!) as? NSNumber
                tripInfo?.returnTime = Int(arrTime!) as? NSNumber
                tripInfo?.partialTrip = false
                tripInfo?.jsonPay = tripInfoPayJSON as? NSNumber
                tripInfo?.tafbJson = tripTAFBJSON as? NSNumber
                tripInfo?.debriefMinutes = debriefMinutes as? NSNumber
                tripInfo?.briefMinutes = briefMinutes as? NSNumber
                
//                var prevCity = self.bidPeriod?.base
                prevDay = nil
                for i in 0..<dutyPeriodArray.count{
                    let city = (dutyPeriodArray[i] as? [String: Any])?["ArrStaLastLeg"] as? String
                    //create new day
                    dayInfo = BIDayInfo(context: moc)
                    dayInfo?.trip = tripInfo
                    dayInfo?.city = city
                    dayInfo?.reportTime = (dutyPeriodArray[i] as? [String: Any])?["ShowTime"] as? NSNumber
                    let pay: CGFloat = CGFloat(((dutyPeriodArray[i] as? [String: Any])?["Tfp"] as? NSNumber)!.floatValue)
                    dayInfo?.pay = pay as NSNumber
                    let departTimeFirstLeg = (dutyPeriodArray[i] as? [String: Any])?["DepTimeFirstLeg"] as? NSNumber
                    dayInfo?.departTimeFirstLeg = departTimeFirstLeg
                    var tfpRig:Float = 0
                    if i == dutyPeriodArray.count - 1{
                        // last duty period
                        let adjRig = Float((missingTripDict["RigAdg"] as? Double)!)
                        let tafbRig = Float((missingTripDict["RigTafb"] as? Double)!)
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
                        let flightNum = (flightArray![k] as [String:Any])["FltNum"] as? Int
                        let isDeadHead = (flightArray![k] as [String:Any])["DeadHead"] as? Int
                        legInfo = BILegInfo(context: moc)
                        legInfo?.departCity = (flightArray![k] as [String:Any])["DepSta"] as? String
                        legInfo?.arriveCity = (flightArray![k] as [String:Any])["ArrSta"] as? String
                        legInfo?.flight = "\(flightNum!)"
                        legInfo?.isDeadhead = isDeadHead as? NSNumber
                        legInfo?.day = dayInfo
                        legInfo?.departMinutes = departMin as? NSNumber
                        legInfo?.arriveMinutes = arriveMin as? NSNumber
                        legInfo?.equipment = equipment
//                        prevCity = city
                        
                        let legPay = (flightArray![k] as [String:Any])["Tfp"] as? Double
                        legInfo?.pay = Float(legPay!) as NSNumber
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
                        return nil
                    }
                    // Failed to read TFP value.
                    if scanner.scanFloat() == nil{
                        //handle error
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
                        return nil
                    }
                    // Skip to next line of text, which will have start/end times
                    // and pay for trip.
                    lineRange.location = lineRange.location + lineRange.length
                    lineRange.length = 0
                    lineRange = (fileInfo as NSString).lineRange(for: lineRange)
                    if  lineRange.location >= fileInfoLength{
                        //handle error
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
                            return nil
                        }
                        var prevScanLoc = scanner.currentIndex.utf16Offset(in: scanner.string)
                        var depTime: Int = 0
                        if !scanner.scanInt(&depTime) || (scanner.currentIndex.utf16Offset(in: scanner.string) - prevScanLoc) != 4{
                            //handle error
                            return nil
                        }
                        prevScanLoc = scanner.currentIndex.utf16Offset(in: scanner.string)
                        var arrTime = 0
                        guard scanner.scanUpToCharacters(from: .decimalDigits) != nil,
                              let scannedInt = scanner.scanInt(),
                              scanner.currentIndex.utf16Offset(in: scanner.string) - prevScanLoc == 5 else {
                            //handle error
                            return nil
                        }
                        arrTime = scannedInt
                        
                        var pay:Float = 0
                        guard scanner.scanUpToCharacters(from: .decimalDigits) != nil, let scannedFloat = scanner.scanFloat() else {
                           //handle error
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
                        
                    let herbValueStr = UserDefaults.standard.string(forKey: KCBCustomizedHerbValue)
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
                    if let lastDay = tripInfo!.orderedDays().last,
                           let lastLeg = lastDay.orderedLegs.last {
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
        let directoryURL = BIBidInfo.shared.downloadDirectory()
        
        //Cover Letter
        var textFileURL = directoryURL.appendingPathComponent(BIBidInfo.shared.coverLetterFileName())
        var text = ""
        do{
            let data = try Data(NSData(contentsOf: textFileURL))
            if self.isFABid(){
                if let asciitext = String(data: data, encoding: .ascii){
                    text = asciitext
                }else if let cp1252text = String(data: data, encoding: .windowsCP1252){
                    text = cp1252text
                }
            }else{
                if let utf8text = String(data: data, encoding: .utf8){
                    text = utf8text
                }else if let cp1252text = String(data: data, encoding: .windowsCP1252){
                    text = cp1252text
                }
            }
        }catch{
            print("Error reading text file: \(error.localizedDescription)")
        }
        if !text.isEmpty{
            self.bidPeriod?.addTextFile(withText: text, name: BICoverLetterTextFileName)
        }else{
            if AppState.shared.isMockData{
                return true
            }
            return false
        }
        
        //Seniority List
        textFileURL = directoryURL.appendingPathComponent(BIBidInfo.shared.seniorityListFileName())
        text = try! String(contentsOf: textFileURL, encoding: .utf8)
        if text.isEmpty{
            text = try! String(contentsOf: textFileURL, encoding: .windowsCP1252)
        }
        if !text.isEmpty{
            self.bidPeriod?.addTextFile(withText: text, name: BISeniorityListTextFileName)
        }else{
            //handle error
            print("Unable to read Seniority")
            return false
        }
        
        //Lines text
        textFileURL = directoryURL.appendingPathComponent(BIBidInfo.shared.linesTextFilename())
        text = try! String(contentsOf: textFileURL, encoding: .utf8)
        if !text.isEmpty{
            self.bidPeriod?.addTextFile(withText: text, name: BILinesTextFileName)
        }else{
            //handle error
            return false
        }
        
        //Trips Text
        textFileURL = directoryURL.appendingPathComponent(BIBidInfo.shared.tripsTextFilename())
        text = try! String(contentsOf: textFileURL, encoding: .utf8)
        if !text.isEmpty{
            self.bidPeriod?.addTextFile(withText: text, name: BITripsTextFileName)
        }else{
            //handle error
            return false
        }
        
        //FA Memo text
        if self.isFABid(){
            textFileURL = directoryURL.appendingPathComponent(BIBidInfo.shared.faMemoTextFilename())
            text = try! String(contentsOf: textFileURL, encoding: .ascii)
            if !text.isEmpty{
                self.bidPeriod?.addTextFile(withText: text, name: BIFaMemoTextFileName)
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
    
    private func getEquipmentType(type: String) -> String {
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
    
    private func getDay(from date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        dateFormatter.dateFormat = "EEEE"
        return dateFormatter.string(from: date)
    }
}
