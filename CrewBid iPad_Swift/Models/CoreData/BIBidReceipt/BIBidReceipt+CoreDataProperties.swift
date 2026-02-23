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
    
    //old format
    func setProperties(withReceiptText receiptText: String){
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
    
    //new format
    func setProperties(withReceiptTextForVerticalAlignment receiptText:String, bidPeriod:BIBidPeriod){
        self.bidPeriod = bidPeriod
        self.text = receiptText
        
        var condensedText = ""
        
        var bidLineNumbers:[String] = []
        var optionalEmployeeNumbers:[String] = []
        
        var readFirstLine = true
        var readBidLineNUmbers = false
        var readOptionalEmployeeNumbers = false
        var readFinalLine = false
        var isValidReceipt = false
        
        
        receiptText.enumerateLines { line, stop in
            
            // ----- FIRST LINE -----
            
            if readFirstLine{
                self.submittedFor = line
                condensedText += "\(line)\n"
                readFirstLine = false
                readBidLineNUmbers = true
            }
            
            // ----- BID LINE NUMBERS -----
            
            else if readBidLineNUmbers{
                if line == "*E"{
                    condensedText += "\(line)\n"
                    readBidLineNUmbers = false
                    readOptionalEmployeeNumbers = true
                }else{
                    bidLineNumbers.append(line)
                }
            }
            
            // ----- OPTIONAL EMPLOYEE NUMBERS -----
            
            else if readOptionalEmployeeNumbers{
                if line == "*E"{
                    condensedText += "\(line)\n"
                    readOptionalEmployeeNumbers = false
                    readFinalLine = true
                }else{
                    optionalEmployeeNumbers.append(line)
                    condensedText += "\(line)\n"
                }
            }
            
            // ----- FINAL LINE (submitted by, for, timestamp) -----
            
            else if readFinalLine{
                
                let brackets = CharacterSet(charactersIn: "[]")
                let digits = CharacterSet.decimalDigits
                
                let formatter = DateFormatter()
                formatter.dateFormat = "MM/dd/yy HH:mm:ss"
                
                let scanner = Scanner(string: line)
                
                _ = scanner.scanUpToString("SUBMITTED BY:")
                _ = scanner.scanString("SUBMITTED BY:")
                
                scanner.charactersToBeSkipped = CharacterSet(charactersIn: "")
                
                _ = scanner.scanUpToCharacters(from: brackets)
                _ = scanner.scanCharacters(from: brackets)
                let submittedBy = scanner.scanUpToCharacters(from: brackets) ?? ""
                
                _ = scanner.scanUpToCharacters(from: digits)
                let submittedFor = scanner.scanCharacters(from: digits) ?? ""
                
                _ = scanner.scanUpToCharacters(from: digits)
                
                let timeStamp = String(line[scanner.currentIndex...])
                
                if submittedFor == self.submittedFor {
                    isValidReceipt = true
                }
                
                self.submittedBy = submittedBy
                self.submittedByUserId = self.extractNumber(from: submittedBy)
                self.submittedForUserId = submittedFor
                self.timeStamp = formatter.date(from: timeStamp)
                self.submittedDateString = timeStamp
                
                self.optionalEmployeeNumbers = optionalEmployeeNumbers
                condensedText += "\(line)\n"
            }
        }
        
        // Assign base properties
        self.bidLineNumbers = bidLineNumbers
        self.submittedLineNumbersString = bidLineNumbers.joined(separator: ",")
        self.createdAt = Date()
        
        // ============ APPLY 5-COLUMN FORMATTER ============
        
        if bidLineNumbers.count > 0{
            let vertical = self.formatLineNumbers(numbers: bidLineNumbers, maxColumns: 5)
            condensedText += "\n\n"
            condensedText += vertical
        }
        
        self.condensedText = condensedText
        
        if !isValidReceipt{
            AlertService.showAlertForTopVC(title: "Bid Receipt Error!", message: "The Bid receipt format was not correct...")
        }
    }
    
    //MARK: For PILOT - 5 Column Vertical Formatter
    func formatLineNumbers(numbers:[String], maxColumns:Int) -> String{
        
        let totalCount = numbers.count
        if totalCount == 0 { return ""}
        
        // Serial width
        let maxSerialString = "\(totalCount)."
        let maxSerialWidth = maxSerialString.length
        
        // Line number width
        var maxLineWidth = 0
        for line in numbers{
            if line.length > maxLineWidth{
                maxLineWidth = line.length
            }
        }
        
        // Row rules
        var maxRowsPage1 = self.bidPeriod!.isFABid() ? 32 : 45
        if self.optionalEmployeeNumbers.count == 1{
            maxRowsPage1 = maxRowsPage1 - 1
        }
        if self.optionalEmployeeNumbers.count == 2{
            maxRowsPage1 = maxRowsPage1 - 2
        }
        if self.optionalEmployeeNumbers.count == 3{
            maxRowsPage1 = maxRowsPage1 - 3
        }
        
        let maxRowsOther = self.bidPeriod!.isFABid() ? 37 : 51
        
        var output = ""
        var index = 0
        var pageNumber = 1
        var prevPageOffset = 0
        
        while index < totalCount{
            let currentMaxRows = (pageNumber == 1) ? maxRowsPage1 : maxRowsOther
            
            var columns: [[String]] = Array(repeating: [], count: maxColumns)
            
            // Fill columns top-to-bottom
            for col in 0..<maxColumns{
                for _ in 0..<currentMaxRows where index < totalCount{
                    columns[col].append(numbers[index])
                    index += 1
                }
            }
            
            // Render rows
            for row in 0..<currentMaxRows{
                for col in 0..<maxColumns{
                    let colArray = columns[col]
                    let value = (row < colArray.count) ? colArray[row] : ""
                    
                    let globalIndex = row + (col * currentMaxRows) + prevPageOffset + 1
                    
                    if globalIndex <= numbers.count{
                        
                        // --- SERIAL NUMBER (RIGHT-ALIGNED) ---
                        let serial = "\(globalIndex)."
                        let serialRightAligned = self.rightAlign(text: serial, width: maxSerialWidth)
                        
                        // LINE NUMBER (left-aligned)
                        let valueLeftAligned = value.padding(toLength: maxLineWidth, withPad: " ", startingAt: 0)
                        
                        // FINAL MIX — NO SPACE between serial + line number
                        output += "\(serialRightAligned)\(valueLeftAligned)   "
                    }
                }
                output += "\n"
            }
            
            if index < totalCount - 1 {
                output += "\n"
            }
            
            prevPageOffset += currentMaxRows * maxColumns
            pageNumber += 1
        }
        
        return output
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

            
            for choice in bidChoices{
                if let line = choice["choice"] as? String, !line.isEmpty{
                    bidLineNumbers.append(line)
                }
            }
            
            
            self.bidLineNumbers = bidLineNumbers
            self.submittedLineNumbersString = bidLineNumbers.joined(separator: ",")

            // BID INFO
            condensedText += "BID INFO: \(position ?? "")  -  \(bidInfo ?? "")\n"
            condensedText += "Receipt File Dated: \(self.convertLocalFormat()) (Local)\n"
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
                condensedText += "           : \(utcDateStr)  [UTC]"
            }
            
            if condensedText.contains("JOB SHARE") || condensedText.contains("BUDDY ID:"){
                condensedText += "\n\n"
            }else{
                condensedText += "\n\n\n"
            }
            
            let alignedLineNo = self.formatForA4Columns(items: bidChoices, maxColumns: 5, font: UIFont(name: "Courier", size: 15)!)
            condensedText += "\(alignedLineNo) "
            
            
            
            /*
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
             */
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
    
    func convertLocalFormat() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "EEEE, MMM dd, yyyy"
        return formatter.string(from: Date())
    }
    
    //MARK: Main Formatter
    
    func formatForA4Columns(items: [[String:Any]], maxColumns:Int, font:UIFont) -> String{
        let totalCount = items.count
        guard totalCount > 0 else { return "" }
        
        let maxSerialWidth = "\(totalCount).".count
        
        let maxRows = 36
        let maxRowsPage1 = 30
        
        var maxLen = 0
        
        for dict in items{
            let choice = (dict["choice"] as? String) ?? ""
            if choice.count > maxLen { maxLen = choice.count }
        }
        
        var finalOutput = ""
        var index = 0
        
        var pageNumber = 1
        var prevPageOffset = 0
        
        while index < items.count{
            
            let currentMaxRows = (pageNumber == 1) ? maxRowsPage1 : maxRows
            
            var columns: [[String]] = Array(repeating: [], count: maxColumns)
            
            for col in 0..<maxColumns{
                for _ in 0..<currentMaxRows where index < items.count {
                    let dict = items[index]
                    let lineNo = dict["choice"] as? String ?? ""
                    
                    columns[col].append(lineNo)
                    index += 1
                }
            }
            
            for row in 0..<currentMaxRows {
                for col in 0..<maxColumns {
                    let colArr = columns[col]
                    let value = (row < colArr.count) ? colArr[row] : ""
                    
                    let globalIndex = row + (col * currentMaxRows) + prevPageOffset + 1
                    
                    if globalIndex <= totalCount {
                        
                        
                        // --- SERIAL NUMBER (RIGHT-ALIGNED) ---
                        let serial = "\(globalIndex)."
                        let serialAligned = self.rightAlign(text: serial, width: maxSerialWidth)
                        
                        // --- VALUE (LEFT-ALIGNED) ---
                        let valueAligned = value.padding(toLength: maxLen, withPad: " ", startingAt: 0)
                        
                        
                        let combined = "\(serialAligned) \(valueAligned)"
                        
                        finalOutput.append(combined)
                        finalOutput.append("  ")
                    }
                }
                finalOutput.append("\n")
            }
            
            if index < (items.count - 1) {
                finalOutput.append("\n\n")
            }
            
            prevPageOffset += currentMaxRows * maxColumns
            pageNumber += 1
        }
        return finalOutput
    }
    
    func rightAlign(text:String, width:Int) -> String{
        let spaceCount = (width > text.length) ? (width - text.length) : 0
        let spaces = String(repeating: " ", count: spaceCount)
        return spaces.appending(text)
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
    
    func addBidreciptSpacesForPilot() -> String{
        let a = String(format: "%5s", (self as NSString).utf8String!)
        return a
    }
}
