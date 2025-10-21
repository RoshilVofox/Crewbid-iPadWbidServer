//
//  AwardActionsTableController.swift
//  CrewBid iPad_Swift
//
//  Created by Developer on 18/04/25.
//

import UIKit
import MessageUI
import Messages
import EventKit

let kCBPdfSize: CGRect = CGRect(x: 20, y: 20, width: 816, height: 1056)

class AwardActionsTableController: BaseViewController, KUIPopOverUsable, UIPrintInteractionControllerDelegate, MFMailComposeViewControllerDelegate {
    
    var contentSize: CGSize = CGSize(width: 350, height: 300)
    
 
    @IBOutlet weak var tableView: UITableView!
    var bidPeriod: BIBidPeriod?
    public var titleText = String()
    public var attributedTxt:NSAttributedString?
    public var text = String()
    public var bidReceipttext = String()
    var dataTypeSelected : TextFileType = .seniorityList
    var awardActionArray = ["Email Bid Awards","Print Bid Awards","Show Awarded Line","Add Awarded Line to Calendar"]
    var FileActionArray = ["Email Cover Letter","Print Cover Letter"]
    var seniorityArray = ["Email Seniority List","Print Seniority List"]
    var lineTextArray = ["Email Lines Text","Print Lines Text","Show Line","Add Line to Calendar"]
    var tripTextArray = ["Email Trips Text","Print Trips Text","Show Trip"]
    var reciptTextArray = ["Email Bid Receipt","Print Bid Receipt"]
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        bidPeriod = CBGlobalMethods.shared.selectedBidPeriod
        
        
    }
    
    
    
    func setPropertiesWithReceiptText(_ receiptText: String) -> NSAttributedString {
        let attrBlank = [NSAttributedString.Key.backgroundColor: UIColor.blue, NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.strokeWidth: NSNumber(value: -3.0), NSAttributedString.Key.font : UIFont(name: "Courier", size: 12)!]
        let attrReserve = [NSAttributedString.Key.backgroundColor: UIColor.red, NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.strokeWidth: NSNumber(value: -3.0), NSAttributedString.Key.font : UIFont(name: "Courier", size: 12)!]
        let attrClear = [NSAttributedString.Key.backgroundColor: UIColor.clear, NSAttributedString.Key.font : UIFont(name: "Courier", size: 12)!]
        let condensedText : NSMutableAttributedString = NSMutableAttributedString()
        var optionalEmployeeNumbers = [Any]() /* capacity: 3 */
        var readFirstLine: Bool = true
        var readBidLineNumbers: Bool = false
        var readOptionalEmployeeNumbers: Bool = false
        var readFinalLine: Bool = false
        var isValidReceipt: Bool = false
        var count = 0
        receiptText.enumerateLines {
            (line: String, stop: inout Bool) in
            if readFirstLine {
                let temp = NSAttributedString(string: "\(line)\n", attributes: attrClear)
                condensedText.append(temp)
                readFirstLine = false
                readBidLineNumbers = true
            }
            else if readBidLineNumbers {
                if (line == "*E") {
                    let temp = NSAttributedString(string: "\n", attributes: attrClear)
                    condensedText.append(temp)
                    
                    let temp1 = NSAttributedString(string: "\(line)\n", attributes: attrClear)
                    condensedText.append(temp1)
                    
                    readBidLineNumbers = false
                    readOptionalEmployeeNumbers = true
                }  else {
                    count = count + 1
                    let a = line.addBidreciptSacesForPilot()
                    var temp = NSAttributedString(string: a, attributes: attrClear)
                    if self.fetchLineType(lineNumber: Int(line) ?? 0) == .reserve {
                        temp = NSAttributedString(string: a, attributes: attrReserve)
                    }else  if self.fetchLineType(lineNumber: Int(line) ?? 0) == .blank {
                        temp = NSAttributedString(string: a, attributes: attrBlank)
                    }
                    condensedText.append(temp)
                    if count % 20 == 0 {
                        condensedText.append(NSAttributedString(string: "\n", attributes: attrClear))
                    }
                }
            }
            
                // Read optional employee numbers (avoidance and buddy bids). Optional
                // employee numbers end with *E.
            else if readOptionalEmployeeNumbers {
                if (line == "*E") {
                    let temp = NSAttributedString(string: "\(line)\n", attributes: attrClear)
                    condensedText.append(temp)
                    
                    readOptionalEmployeeNumbers = false
                    readFinalLine = true
                } else {
                    optionalEmployeeNumbers.append(line)
                    
                    let temp = NSAttributedString(string: "\(line)\n", attributes: attrClear)
                    condensedText.append(temp)
                }
            }
            
                // Read final line for submitted by, submitted for, and time stamp.
                // Format:  SUBMITTED BY: [e52758]     52758    02/06/13 07:49:12
            
            else if readFinalLine {
                let brackets = CharacterSet(charactersIn:"[]")
                let digits = CharacterSet.decimalDigits
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MM/dd/yy HH:mm:ss"
                var submittedBy: String? = ""
                var submittedFor: String? = ""
                var timeStamp: String? = nil
                let scanner = Scanner(string: line)
                    // Scan past SUBMITTED BY:.
                _ = scanner.scanUpToString("SUBMITTED BY:")
                _ = scanner.scanString("SUBMITTED BY:")
                    // Scan submitted by user id.
//                let skipCharacters = scanner.charactersToBeSkipped
                scanner.charactersToBeSkipped = CharacterSet(charactersIn: "")
                _ = scanner.scanUpToCharacters(from: brackets)
                _ = scanner.scanCharacters(from: brackets)
                
                submittedBy = scanner.scanUpToCharacters(from: brackets)
                    // Scan submitted for employee number.
                _ = scanner.scanUpToCharacters(from: digits)
                submittedFor = scanner.scanCharacters(from: digits)
                    // Scan time stamp.
                _ = scanner.scanUpToCharacters(from: digits)
//                timeStamp = (line as NSString).substring(from: scanner.scanLocation)
                let startIndex = scanner.currentIndex
                timeStamp = String(line[startIndex...])
                if (submittedFor == submittedFor) {
                    isValidReceipt = true
                }
                
                print(timeStamp ?? "", isValidReceipt)
                
                let temp = NSAttributedString(string: "\(line)\n", attributes: attrClear)
                condensedText.append(temp)
            }
        }
        
        return condensedText
    }
    
    func fetchLineType(lineNumber: Int) -> LineTypeForRecipt {
        
        let lineTypeSort = NSSortDescriptor(key: "type", ascending: true)
        let lineNumberSort = NSSortDescriptor(key: "number", ascending: true)
        
        let lineSorts = [lineTypeSort, lineNumberSort]
        let predicate = NSPredicate(format: "number == %@", NSNumber(value: lineNumber))
        
        
        let lines = (CBGlobalMethods.shared.selectedBidPeriod!.lines!.allObjects as NSArray).sortedArray(using: lineSorts)
        let results = (lines as NSArray).filtered(using: predicate) as! [BILine]
        
        if results.count > 0 {
            let line = results[0]
            if line.orderedTrips.count == 0 {
                return LineTypeForRecipt.blank
            }
            if line.isETOPSRES?.intValue != 0 {
                return LineTypeForRecipt.reserve
            }
            if line.type?.intValue == BILineType.ReserveLine.rawValue {
                return LineTypeForRecipt.reserve
            }
        }else {
            return LineTypeForRecipt.normal
        }
        
        return LineTypeForRecipt.normal
    }
    
    
    func showPrintController() {
        let printController = UIPrintInteractionController.shared
        printController.delegate = self
        
        let printInfo = UIPrintInfo.printInfo()
        printInfo.outputType = .grayscale
        printInfo.duplex = .none
        printInfo.jobName = self.titleText
        printController.printInfo = printInfo
        printInfo.orientation = .landscape
        var printFormatter: UISimpleTextPrintFormatter!
        if attributedTxt != nil{
            printFormatter = UISimpleTextPrintFormatter(attributedText: attributedTxt!)
        } else {
            printFormatter = UISimpleTextPrintFormatter(text: self.text)
            let font = UIFont(name: "Courier", size: 12)
            let attributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.foregroundColor: UIColor.black, NSAttributedString.Key.font: font ?? UIFont.systemFont(ofSize: 12.0)]
            let attributedText = NSAttributedString(string: text, attributes: attributes)
            printFormatter.attributedText = attributedText
        }
        printFormatter.startPage = 0
        printController.printFormatter = printFormatter
        printController.present(animated: true, completionHandler: nil)
    }
    
    func createPDF(from attributedString: NSAttributedString) -> Data? {
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: kCBPdfSize)
        let pdfData = pdfRenderer.pdfData { (context) in
            context.beginPage()
            attributedString.draw(in: kCBPdfSize)
        }
        return pdfData
    }
    
    func emailTextFile(){
        let file = self.titleText
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            
            if titleText == "Bid Receipt" {
                if let attStr = self.attributedTxt, let data = createPDF(from: attStr) {
                    mail.addAttachmentData(data, mimeType: "application/pdf", fileName: "Bid Receipt.pdf")
                }else if let bidReceipt = text.data(using: .utf8) {
                    mail.addAttachmentData(bidReceipt as Data, mimeType: "text/plain" , fileName: file)
                }
                mail.setMessageBody("Bid receipt :", isHTML: false)
            } else {
                if let data = text.data(using: .utf8) {
                    mail.addAttachmentData(data as Data, mimeType: "text/plain" , fileName: file)
                }
            }
            mail.setSubject(self.titleText)
            present(mail, animated: true)
        } else {
            dismissFn()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                CBGlobalMethods.shared.ShowAlert(TitleString: "CrewBid", MessageString: "Please confirm that you have logged into the Mail App in your device.")
            }
        }
    }
}


extension AwardActionsTableController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if dataTypeSelected == .awardText {
            return awardActionArray.count
        } else if dataTypeSelected == .tripText {
            return tripTextArray.count
        } else if dataTypeSelected == .lineText {
            return lineTextArray.count
        } else if dataTypeSelected == .coverLetter{
            return FileActionArray.count
        }else if dataTypeSelected == .bidReceipt{
            return reciptTextArray.count
        }else{
            return seniorityArray.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        if dataTypeSelected == .awardText {
            cell.textLabel?.text = awardActionArray[indexPath.row]
        } else if dataTypeSelected == .tripText {
            cell.textLabel?.text = tripTextArray[indexPath.row]
        } else if dataTypeSelected == .lineText {
            cell.textLabel?.text = lineTextArray[indexPath.row]
        } else if dataTypeSelected == .coverLetter{
            cell.textLabel?.text = FileActionArray[indexPath.row]
        }else if dataTypeSelected == .bidReceipt{
            cell.textLabel?.text = reciptTextArray[indexPath.row]
        }
        else{
            cell.textLabel?.text = seniorityArray[indexPath.row]
        }
        cell.textLabel?.font = .boldSystemFont(ofSize: 17)
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if dataTypeSelected == .awardText {
            switch indexPath.row {
                case 0: //Email bid awards
                    self.dismiss(animated: true) { [weak self] in
                        guard let self = self else { return }
                        self.emailTextFile()
                    }
                    break
                case 1: //Print bid awards
                    self.dismiss(animated: true) { [weak self] in
                        guard let self = self else { return }
                        self.showPrintController()
                    }
                    break
                case 2: //Show awarded line
                    dismissFn()
                    if let presentingVC = self.presentingViewController {
                        self.dismiss(animated: true) {
                            let storyboard = UIStoryboard(name: "BidInfo", bundle: nil)
                            let vc = storyboard.instantiateViewController(withIdentifier: "CBDefaultEmployeeVC") as! CBDefaultEmployeeVC
                            vc.preferredContentSize = CGSize(width: 600, height: 500)
                            vc.bidPeriod = self.bidPeriod
                            vc.type = .showAwardedLine
                            let navController = UINavigationController(rootViewController: vc)
                            navController.setNavigationBarHidden(true, animated: false)
                            presentingVC.present(navController, animated: true)
                        }
                    }
                    break
               case 3: //Add awarded line to calendar
                    dismissFn()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        NotificationCenter.default.post(name: NSNotification.Name(KCBOpenAwardEmpValidationVCForAddToCal), object: self)
                    }
                default:
                    break
            }
        } else if dataTypeSelected == .tripText {
            switch indexPath.row {
                case 0: //Email bid awards
                    self.dismiss(animated: true) { [weak self] in
                        guard let self = self else { return }
                        self.emailTextFile()
                    }
                    break
                case 1: //Print bid awards
                    self.dismiss(animated: true) { [weak self] in
                        guard let self = self else { return }
                        self.showPrintController()
                    }
                    break
                case 2: //Show trip
                    dismissFn()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    NotificationCenter.default.post(name: NSNotification.Name("openTripFetchInTextView"), object: self)
                    }
                    break
                default:
                    break
            }
        } else if dataTypeSelected == .lineText {
            let selectedOption = ["option":lineTextArray[indexPath.row]] as? [String:String]
            switch indexPath.row {
                case 0: //Email bid awards
                    self.dismiss(animated: true) { [weak self] in
                        guard let self = self else { return }
                        self.emailTextFile()
                    }
                    break
                case 1: //Print bid awards
                    self.dismiss(animated: true) { [weak self] in
                        guard let self = self else { return }
                        self.showPrintController()
                    }
                    break
                case 2: //Show line
                    dismissFn()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        NotificationCenter.default.post(name: NSNotification.Name("openLineFetchInTextView"), object: self,userInfo: selectedOption)
                    }
                    break
                case 3: //Show line
                dismissFn()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    NotificationCenter.default.post(name: NSNotification.Name("openLineFetchInTextView"), object: self,userInfo: selectedOption)
                }
                break
                default:
                    break
            }
        }
        else {
            switch indexPath.row {
                case 0: //Email bid awards
                    self.dismiss(animated: true) { [weak self] in
                        guard let self = self else { return }
                        self.emailTextFile()
                    }
                    break
                case 1: //Print bid awards
                    self.dismiss(animated: true) { [weak self] in
                        guard let self = self else { return }
                        self.showPrintController()
                    }
                    break
                default:
                    break
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 45
    }
}


