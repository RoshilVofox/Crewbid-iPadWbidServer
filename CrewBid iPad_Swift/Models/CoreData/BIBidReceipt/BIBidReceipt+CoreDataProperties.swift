//
//  BIBidReceipt+CoreDataProperties.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 19/03/25.
//
//

import Foundation
import CoreData


extension BIBidReceipt {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BIBidReceipt> {
        return NSFetchRequest<BIBidReceipt>(entityName: "BidReceipt")
    }

    @NSManaged public var bidLineNumbers: [Any]
    @NSManaged public var condensedText: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var optionalEmployeeNumbers: [Any]
    @NSManaged public var submittedBy: String?
    @NSManaged public var submittedByUserId: String?
    @NSManaged public var submittedDateString: String?
    @NSManaged public var submittedFor: String?
    @NSManaged public var submittedForUserId: String?
    @NSManaged public var submittedLineNumbersString: String?
    @NSManaged public var text: String?
    @NSManaged public var timeStamp: Date?
    @NSManaged public var bidPeriod: BIBidPeriod?

}

extension BIBidReceipt : Identifiable {

    func setPropertiesWithReceiptText(receiptText: String){
        self.text = receiptText
        
        // String for holding condensed version of bid receipt. Temp numbers line
        // is a temporary string to hold bid line number strings, which will be
        // truncated at 80 characters. Each line number in the string will be 5
        // characters long.
        
        let condensedText = NSMutableString(capacity: receiptText.count)
        var tempNumbersLine = NSMutableString(capacity: 81)
        
        var bidLineNumbers = [Any]()
        var optionalEmployeeNumbers = [Any]()
        
        var readFirstLine: Bool = true
        var readBidLineNumbers: Bool = false
        var readOptionalEmployeeNumbers: Bool = false
        var readFinalLine: Bool = false
        var isValidReceipt: Bool = false
        
        receiptText.enumerateLines { (line, stop) in
            // First line of bid receipt text is employee number for which the bid
            // was submitted.
            if readFirstLine{
                self.submittedFor = line
                condensedText.appendFormat("\(line)\n" as NSString)
                readFirstLine = false
                readBidLineNumbers = true
            }
            else if readBidLineNumbers{
                if line == "*E"{
                    condensedText.appendFormat("\(tempNumbersLine)\n" as NSString)
                    condensedText.appendFormat("\(line)\n" as NSString)
                    readBidLineNumbers = false
                    readOptionalEmployeeNumbers = true
                }else{
                    bidLineNumbers.append(line)
                    // Temp numbers line can hold additional line numbers.
                    if tempNumbersLine.length < 76 {
                        let formatted = String(format: "%6s", line.cString(using: .utf8)!)
                        tempNumbersLine.append(formatted)
                    }
                    // Temp numbers line has the maximum line numbers. Add to
                    // condensed text (with line feed at end) and remove all .
                    else{
                        condensedText.appendFormat("\(tempNumbersLine)\n" as NSString)
                        tempNumbersLine = String(format: "%5s", line) as! NSMutableString
                    }
                }
            }
            // Read optional employee numbers (avoidance and buddy bids). Optional
            // employee numbers end with *E.
            else if readOptionalEmployeeNumbers{
                if line == "*E"{
                    condensedText.appendFormat("\(line)\n" as NSString)
                    readOptionalEmployeeNumbers = false
                    readFinalLine = true
                }else{
                    optionalEmployeeNumbers.append(line)
                    condensedText.appendFormat("\(line)\n" as NSString)
                }
            }
            // Read final line for submitted by, submitted for, and time stamp.
            // Format:  SUBMITTED BY: [e52758]     52758    02/06/13 07:49:12
            else if readFinalLine{
                let brackets = CharacterSet(charactersIn: "[]")
                let digits = CharacterSet.decimalDigits
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MM/dd/yy HH:mm:ss"
                var submittedBy: String? = nil
                var submittedFor: String? = nil
                var timeStamp: String? = nil
                let scanner = Scanner(string: line)
                // Scan past SUBMITTED BY:.
                _ = scanner.scanUpToString("SUBMITTED BY:")
                _ = scanner.scanString("SUBMITTED BY:")
                // Scan submitted by user id.
                scanner.charactersToBeSkipped = CharacterSet(charactersIn: "")
                _ = scanner.scanUpToCharacters(from: brackets)
                _ = scanner.scanCharacters(from: brackets)
                submittedBy = scanner.scanUpToCharacters(from: brackets)
                // Scan submitted for employee number.
                _ = scanner.scanUpToCharacters(from: digits)
                submittedFor = scanner.scanCharacters(from: digits)
                // Scan time stamp.
                _ = scanner.scanUpToCharacters(from: digits)
                timeStamp = String(line[scanner.currentIndex...])
                // Set properties after sanity check of submitted for.
                if submittedFor == self.submittedFor{
                    isValidReceipt = true
                }
                self.submittedBy = submittedBy
                self.submittedByUserId = self.extractNumber(from: submittedBy!)
                self.submittedForUserId = submittedFor
                self.timeStamp = dateFormatter.date(from: timeStamp!)
                self.submittedDateString = timeStamp
                self.bidLineNumbers = bidLineNumbers
                self.submittedLineNumbersString = (bidLineNumbers as! [String]).joined(separator: ",")
                self.optionalEmployeeNumbers = optionalEmployeeNumbers
                // Add to condensed text.
                condensedText.appendFormat("\(line)\n" as NSString)
            }
        }
        self.condensedText = condensedText as String
        self.createdAt = Date()
        if !isValidReceipt{
            DispatchQueue.main.async {
                AlertService.showAlertForTopVC(title: "Bid Receipt Error!", message: "The Bid Receipt format was not correct. This may mean that your bid was not properly received by SWA. You can double-check in SWA Life to be sure your bid was received (instructions are in the FAQ file in the Help Menu).\n\nThere is either an issue with SWA's bid server or you are probably connected to airport or hotel wifi but have not fully connected to the internet.  If the second case, open Safari and follow the wifi network's instructions to fully connect.")
            }
        }
    }
    
    func setProperties(withReceiptJson json: [String: Any]) {
        var condensedText = ""
        var bidLineNumbers: [String] = []
        var isValidReceipt = false

        // Extract values safely
        let employeeId = json["employeeId"] as? String
        let submittedBy = json["submittedBy"] as? String
        let confirmationNumber = json["confirmationNumber"] as? String
        let bidChoices = json["bidChoices"] as? [[String: Any]]
        let bidInfo = json["packetId"]
        let position = json["department"]
        let jobShare1 = json["jobShareId1"] as? String
        let jobShare2 = json["jobShareId2"] as? String
        let buddy1 = json["buddyId1"] as? String
        let buddy2 = json["buddyId2"] as? String
        let receivedAt = json["receivedAt"] as? String

        var buddyText = ""

        // MARK: Buddy / Job Share Handling
        if jobShare1 != nil, jobShare1 as Any is NSNull == false,
           jobShare2 != nil, jobShare2 as Any is NSNull == false {

            if employeeId == jobShare1 {
                buddyText = "JOB SHARE: \(jobShare2 ?? "")"
            } else {
                buddyText = "JOB SHARE: \(jobShare1 ?? "")"
            }
        } else {

            if let b1 = buddy1, !b1.isEmpty, buddy1 as Any is NSNull == false {
                buddyText = "BUDDY ID:   \(b1)"

                if let b2 = buddy2, !b2.isEmpty, buddy2 as Any is NSNull == false {
                    buddyText += ", \(b2)"
                }
            } else {
                buddyText = ""
            }
        }

        // MARK: Main Validation
        if let employeeId, let submittedBy, let confirmationNumber, let bidChoices {

            self.submittedBy = submittedBy
            self.submittedByUserId = extractNumber(from: submittedBy)

            self.submittedFor = employeeId
            self.submittedForUserId = extractNumber(from: employeeId)

            self.timeStamp = Date()

            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd HH:mm:ss"
            self.submittedDateString = df.string(from: self.timeStamp ?? Date())

            self.bidLineNumbers = bidLineNumbers
            self.submittedLineNumbersString = bidLineNumbers.joined(separator: ",")

            // BID INFO
            condensedText += "BID INFO: \(position ?? "")  -  \(bidInfo ?? "")\n"
            condensedText += "SUBMITTED BY: [\(submittedBy)]   \(employeeId)\n"

            if !buddyText.isEmpty {
                condensedText += "\(buddyText)\n"
            }

            condensedText += "Confirmation Number: \(confirmationNumber)\n"

            if let receivedAt {
                let utcDateStr = convertDateToUTC(receivedAt)
                let herbDateStr = convertDateToHerb(receivedAt)
                self.submittedDateString = herbDateStr

                condensedText += "Received At: \(herbDateStr)  [HERB]\n"
                condensedText += "           : \(utcDateStr)  [UTC]\n\n"
            }

            // MARK: Bid Choices
            let maxLength = bidChoices
                .compactMap { $0["choice"] as? String }
                .map { $0.count }
                .max() ?? 1

            for choice in bidChoices {
                if let line = choice["choice"] as? String {
                    bidLineNumbers.append(line)

                    let padded = line.padding(
                        toLength: maxLength,
                        withPad: " ",
                        startingAt: 0
                    )
                    condensedText += "\(padded) "
                }
            }

            isValidReceipt = true
        }

        // Final properties
        self.bidLineNumbers = bidLineNumbers
        self.submittedLineNumbersString = bidLineNumbers.joined(separator: ",")
        self.condensedText = condensedText
        self.createdAt = Date()

        // MARK: Error Alert
        if !isValidReceipt {
            DispatchQueue.main.async {
                AlertService.showAlertForTopVC(title: "Bid Receipt Error!", message: "The Bid Receipt format was not correct. This may mean that your bid was not properly received by SWA. You can double-check in SWA Life to be sure your bid was received (instructions are in the FAQ file in the Help Menu).\n\nThere is either an issue with SWA's bid server or you are probably connected to airport or hotel wifi but have not fully connected to the internet.  If the second case, open Safari and follow the wifi network's instructions to fully connect.")
            }
        }
    }
    
    
    func convertDateToUTC(_ dateStr: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        // Parse ISO8601 date string
        guard let date = isoFormatter.date(from: dateStr) else {
            return dateStr // fallback, same as Objective-C
        }

        // Format as UTC yyyy-MM-dd HH:mm:ss
        let outputFormatter = DateFormatter()
        outputFormatter.timeZone = TimeZone(abbreviation: "UTC")
        outputFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        return outputFormatter.string(from: date)
    }
    
    func convertDateToHerb(_ dateStr: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        // Parse ISO8601 input
        guard let date = isoFormatter.date(from: dateStr) else {
            return dateStr // fallback identical to Objective-C
        }

        // Convert to HERB → US/Central time
        let outputFormatter = DateFormatter()
        outputFormatter.timeZone = TimeZone(identifier: "US/Central")
        outputFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        return outputFormatter.string(from: date)
    }
    
    func extractNumber(from text: String) -> String {
        let digits = text.unicodeScalars.filter { CharacterSet.decimalDigits.contains($0) }
        return String(String.UnicodeScalarView(digits))
    }
    
}

extension String {
    func addBidreciptSaces() -> String{
        if self.count == 0 {
            return "       \(self)" //12
        }else if self.count == 1 {
            return "      \(self)"  //11
        }else if self.count == 2 {
            return "     \(self)"    //10
        }else if self.count == 3 {
            return "    \(self)"      //9
        }else if self.count == 4 {
            return "   \(self)"       //8
        }else if self.count == 5 {
            return "  \(self)"        //7
        }
        return ""
    }
    
    func addBidreciptSacesForPilot() -> String{
        let a = String(format: "%5s", (self as NSString).utf8String!)
        return a
    }
}
