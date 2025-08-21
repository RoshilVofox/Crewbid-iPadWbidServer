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
    
    
    func extractNumber(from text: String) -> String {
        let digits = text.unicodeScalars.filter { CharacterSet.decimalDigits.contains($0) }
        return String(String.UnicodeScalarView(digits))
    }
    
}
