//
//  CBBidDocumentController.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 18/03/25.
//

import UIKit
import CoreData

class CBBidDocumentController: BaseViewController, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var btnHome: UIButton!
    @IBOutlet weak var btnSettings: UIButton!
    @IBOutlet weak var btnEOM: UIButton!
    @IBOutlet weak var btnWbidMax: UIButton!
    @IBOutlet weak var lblHome: UILabel!
    @IBOutlet weak var btnSwaptimizer: UIButton!
    @IBOutlet weak var btnHelp: UIButton!
    @IBOutlet weak var btnShare: UIButton!
    @IBOutlet weak var btnLocalHerbView: UIView!
    @IBOutlet weak var herbLabel: UILabel!
    @IBOutlet weak var localLabel: UILabel!
    @IBOutlet weak var btnLocalHerb: UIButton!
    @IBOutlet weak var btnSync: UIButton!
    @IBOutlet weak var toastView: CBToast!
    @IBOutlet weak var toastLabel: UILabel!
    
    @IBOutlet weak var leftShadowView: UIView!
    @IBOutlet weak var rightShadowView: UIView!
    @IBOutlet weak var leftContainerView: UIView!
    @IBOutlet weak var rightContainerView: UIView!
    @IBOutlet weak var bidView: UIView!
    
    @IBOutlet weak var bidCont: UIView!
    var bidPeriod: BIBidPeriod?
    var bidVC: CBBidListVC!
//    var bidLinesController:CBBidListVC!
    var rightNavController:UINavigationController!
    var bidsTableNavController:UINavigationController!
    var dataSource = GlobalBidInfo.shared
    var bdPrd = 1
    var calendarData:BICalendarData = BICalendarData()
    var managedObjectContext: NSManagedObjectContext {
        return CoreDataManager.shared.persistentContainer.viewContext
    }
    var positionFlag1 = 0
    var tempPositionLine : [BILine] = []
    var filtersTableController = CBFilterRulesTableVC()
//    var scratchpadTableController = CBScratchPadVC()
    var sortsTableController = CBLineSortsTVC()
    var swaptimizerVacationImage = "WBidmax-logo"
    var context = CBGlobalMethods.shared.selectedBidPeriod?.managedObjectContext
    var isVacationsRemoved: Bool = false
    var manageVacationsEnabled = false
    var round: NSNumber = 0
    var year: NSNumber = 0000
    var month: NSNumber = 0
    var poistion: BICrewPositionType?
    var employeeNumber = ""
    var seniorityShowed = false
    var eomSelectedIndex = ""
    var commutingSortCell = CBCommutingSortCell()
    var isOldBidPackage: Bool = false
    var totalNumberString: String?
    var didDisplayMonthToMonthAlert = true
    var alertShouldDisplay: Bool = true
    override func viewDidLoad() {
        super.viewDidLoad()
        updateLocalHerbSwitchUI()
        self.bidPeriod = CBGlobalMethods.shared.selectedBidPeriod!
        self.context = CBGlobalMethods.shared.selectedBidPeriod!.managedObjectContext!
//        self.linesManager = BILinesManager.init(managedObjectContext: self.managedObjectContext)
        self.calendarData = calendarData.initWithBidPeriod(bidPeriod: self.bidPeriod!)!
        isVacationsRemoved = false
        btnSwaptimizer.tag = 21
        if self.bidPeriod!.isFABid() {
            btnWbidMax.setTitle("VAC", for: .normal)
            btnSwaptimizer.isHidden = true
        }
        else {
            btnWbidMax.setTitle("WBidMax", for: .normal)
            btnSwaptimizer.isHidden = false
        }
        if bidPeriod?.isHistoric?.boolValue == true {
            btnSwaptimizer.isHidden = true
            btnEOM.isHidden = true
            btnWbidMax.isHidden = true
        }
        alertShouldDisplay = true
//        self.bidLinesController = self.storyboard?.instantiateViewController(withIdentifier: "CBBidListVC") as? CBBidListVC
//        self.bidLinesController.managedObjectContext = self.managedObjectContext
//        self.bidLinesController.bidPeriod = self.bidPeriod!
        setupUI()
        NotificationCenter.default.addObserver(self, selector: #selector(self.setupLayoutView), name: NSNotification.Name("SortBidListAction"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.setupLayoutViewForSwitch), name: NSNotification.Name("SyncSwitchStateAction"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showCommutablilityFilterView), name: Notification.Name("ShowCommutabilityFilterView"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ShowCommutablilitySortView), name: Notification.Name("ShowCommutabilitySortView"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(tapWBidMaxBtn), name: Notification.Name("TapWBidMaxBtn"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateLocalHerbSwitchUI), name: NSNotification.Name("updateLocalHerbSwitchUI"), object: nil)
        
        firstTimeBidOpen()
        NotificationCenter.default.addObserver(self, selector: #selector(didDismissLatestNews), name: NSNotification.Name("DidDismissLatestNews"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(openCoverLetter(notification:)), name: NSNotification.Name(KCBOpenCoverletter), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(openSeniority), name: NSNotification.Name(KCBOpenSeniority), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(openLineText), name: NSNotification.Name(KCBOpenLineText), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(openTripText), name: NSNotification.Name(KCBOpenTripText), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(openFAMemo), name: NSNotification.Name(KCBOpenFAMemo), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(openAwardData), name: NSNotification.Name(KCBOpenAwardData), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(openretrieveAwardDownloadPage), name: NSNotification.Name(KCBOpenretrieveAwardDownloadPage), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.checkLinesAvailableInBidList), name: NSNotification.Name(rawValue: "checkLinesAvailableInBidList"), object: nil)
    }
    
    @objc func openCoverLetter(notification: Notification) {
        self.bidPeriod?.coverLetterDisplayed = true
        let storyboard : UIStoryboard = UIStoryboard(name: "BidActions", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBTextViewController") as! CBTextViewController
        vc.bidPeriod = bidPeriod
        vc.dataTypeSelected = TextFileType.coverLetter
        if let userInfo = notification.userInfo as? NSDictionary {
            vc.isFromFirstTimeOpenBid = userInfo["isFromFirstTimeOpenBid"] as! Bool
        }
           vc.modalPresentationStyle = .fullScreen
           vc.modalTransitionStyle = .crossDissolve
           self.present(vc, animated: true, completion: nil)
    }
        //openSeniority view controller push action
    @objc func openSeniority() {
        let storyboard : UIStoryboard = UIStoryboard(name: "BidActions", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBTextViewController") as!   CBTextViewController
        vc.bidPeriod = bidPeriod
        vc.dataTypeSelected = TextFileType.seniorityList
        vc.modalPresentationStyle = .fullScreen
        vc.modalTransitionStyle = .crossDissolve
        self.present(vc, animated: true, completion: nil)
    }
        //LineText view controller push action
    @objc func openLineText() {
        let storyboard : UIStoryboard = UIStoryboard(name: "BidActions", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBTextViewController") as!   CBTextViewController
        vc.bidPeriod = bidPeriod
        vc.dataTypeSelected = TextFileType.lineText
        vc.modalPresentationStyle = .fullScreen
        vc.modalTransitionStyle = .crossDissolve
        self.present(vc, animated: true, completion: nil)
    }
        //TripText view controller push action
    @objc func openTripText() {
        let storyboard : UIStoryboard = UIStoryboard(name: "BidActions", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBTextViewController") as!   CBTextViewController
        vc.bidPeriod = bidPeriod
        vc.dataTypeSelected = TextFileType.tripText
        vc.modalPresentationStyle = .fullScreen
        vc.modalTransitionStyle = .crossDissolve
        self.present(vc, animated: true, completion: nil)
    }
        //LineText view controller push action
    @objc func openFAMemo(){
        let storyboard : UIStoryboard = UIStoryboard(name: "BidActions", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBTextViewController") as!   CBTextViewController
        vc.bidPeriod = bidPeriod
        vc.dataTypeSelected = TextFileType.faMemo
        vc.modalPresentationStyle = .fullScreen
        vc.modalTransitionStyle = .crossDissolve
        self.present(vc, animated: true, completion: nil)
    }
        //openAwardData view controller push action
    @objc func openAwardData() {
        let storyboard : UIStoryboard = UIStoryboard(name: "BidActions", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBTextViewController") as!   CBTextViewController
        vc.bidPeriod = self.bidPeriod
        vc.dataTypeSelected = TextFileType.awardText
        self.navigationController?.pushViewController(vc, animated: true)
    }
    @objc func openretrieveAwardDownloadPage() {
        let storyboard : UIStoryboard = UIStoryboard(name: "BidInfo", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBCredentialsPageVC") as! CBCredentialsPageVC
        vc.type = .retrieveAwards
        vc.bidPeriod = self.bidPeriod
        vc.preferredContentSize = CGSize(width: 600, height: 500)
        vc.isModalInPresentation = true
        self.present(vc, animated: true, completion: nil)
    }
    
    
    //MARK: -Bid Submission methods
    @objc func checkLinesAvailableInBidList() {
        var linesCount: Int = 0
        linesCount = bidPeriod!.getBidListLines().count
        if 0 == linesCount {
            // Display a warning if there are no lines in the Bid List
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                AlertService.showAlertForTopVC(title: "Warning!", message: "There are no lines in the Bid List. Please add lines to bid list for bid submission")
            })

        }
        else if !self.bidPeriod!.isFABid() && !self.bidPeriod!.isSecondRoundBid() && isBlankLinesMissing() {
            print("Blank lines are missing in between")
        }
        else if !self.bidPeriod!.isFABid() && !self.bidPeriod!.isSecondRoundBid() && !arrayIsInAsendingOrder() {
            // Display an alert if blank lines are not in ascending order
            AlertService.showAlertForTopVC(title: "CrewBid Alert!", message: "Your Blank Lines are not in order of lowest to highest, or you have skipped some Blank Lines. Click Ok to go back and fix this issue. ")
        } else {
             // Proceed with entering the employee number for bid submission
            enterSubmitEmpIdAlert()
        }
    }
    
    func enterSubmitEmpIdAlert(){
        let storyboard = UIStoryboard(name: "BidInfo", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBDefaultEmployeeVC") as! CBDefaultEmployeeVC
        vc.preferredContentSize = CGSize(width: 600, height: 500)
        vc.type = .submitEmployeeNumber
        vc.bidPeriod = self.bidPeriod!
        vc.isEmpIDVerified = false
        let navController = UINavigationController(rootViewController: vc)
        navController.setNavigationBarHidden(true, animated: false)
        self.present(navController, animated: true)
    }
    
    func isBlankLinesMissing() -> Bool {
        let alllines = (self.bidPeriod!.lines!.allObjects as NSArray).sortedArray(using: [NSSortDescriptor(key: "number", ascending: true)])as! [BILine]
        
        var result = [BILine]()
        
        for line in alllines{
            if line.type == BILineType.BlankLine.rawValue.asNSNumber {
                result.append(line)
            }
        }
        
        
        let arrBlankLinesInWholeBid = result.map { $0.number }
        
        var blankLines = [Int]()
        let lines = (self.bidPeriod!.lines!.allObjects as NSArray).sortedArray(using: [NSSortDescriptor(key: "bidOrder", ascending: true)])
        let resultsBidLines = (lines as NSArray).filtered(using: NSPredicate(format: "bidOrder != 0")) as! [BILine]
        
        if !bidPeriod!.isFABid() {
            for line in resultsBidLines {
                if line.type as! Int == BILineType.BlankLine.rawValue {
                    blankLines.append(line.number as! Int)
                }
            }
        }
        
        
        var blankLinesValidate = [String]()
        if let firstValue = blankLines.first, let lastValue = blankLines.last {
            for a in arrBlankLinesInWholeBid {
                if let aInt = a as? Int, aInt >= firstValue, aInt <= lastValue {
                    blankLinesValidate.append("\(aInt)")
                }
            }
        }
        print("Array - \(blankLinesValidate)")
        blankLinesValidate.removeAll { blankLines.contains(Int($0) ?? 0) }
        print("Final - \(blankLinesValidate)")
        if !blankLinesValidate.isEmpty {
            //let missedLines = blankLinesValidate.joined(separator: ",")
            //let message = "You have skipped blank line\(blankLinesValidate.count > 1 || blankLinesValidate.count == 1 ? "s": "")(\(missedLines)). We suggest you fix your bid"
            let alert = UIAlertController(title: "CrewBid Alert!", message: "Your Blank Lines are not in order of lowest to highest, or you have skipped some Blank Lines. Click Ok to go back and fix this issue. ", preferredStyle: UIAlertController.Style.alert)
            let okAction = UIAlertAction(title: "Ok", style: .default) { _ in }
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
            return true
        }
        return false
    }
    
    // Function to check if an array is in ascending order

    func arrayIsInAsendingOrder() -> Bool {
        // Create array of bid line numbers.
        let lines = (self.bidPeriod!.lines!.allObjects as NSArray).sortedArray(using: [NSSortDescriptor(key: "bidOrder", ascending: true)])
        let results = (lines as NSArray).filtered(using: NSPredicate(format: "bidOrder != 0")) as! [BILine]
        
        let results2 = self.bidPeriod!.orderedLines()
        var firtBidLineNum : NSNumber?
        var firtLineNum : NSNumber?
        
        if !bidPeriod!.isFABid() {
            for case let line in results2 {
                if line.type?.intValue == BILineType.BlankLine.rawValue {
                    if firtLineNum == nil {
                        firtLineNum = line.number
                    }
                }
            }
        }
        
        let blankLines = NSMutableArray ()
        if !bidPeriod!.isFABid() {
            for case let line in results {
                print("LineType--\(String(describing: line.type)), blank line--\(Int(BILineType.BlankLine.rawValue))")
                if line.type?.intValue == BILineType.BlankLine.rawValue {
                    blankLines.add(line.number?.intValue as Any)
                    if firtBidLineNum == nil {
                        firtBidLineNum = line.number
                    }
                }
            }
        }
        
        if firtBidLineNum == nil {
            firtBidLineNum = 0
        }
        if firtLineNum == nil {
            firtLineNum = 0
        }
        
        if (!firtLineNum!.isEqual(to: firtBidLineNum!) && firtBidLineNum != 0){
            return false
        }
        
        if blankLines.count != 0 {
            for i in 1..<blankLines.count {
                let FirstNum = blankLines[i - 1] as! Int
                let SecNum = blankLines[i] as! Int
                if FirstNum > SecNum {
                    return false
                }
            }
        }
        return true
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshWorkBlock), name: NSNotification.Name("refreshWorkBlock"), object: nil)
    }
    
    @objc func refreshWorkBlock() {
        self.reprocessWorkBlock()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        seniorityShowed = false
        
        do{
            try self.managedObjectContext.save()
        }catch{
            print("Couldnt save moc because: \(error.localizedDescription)")
        }
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver("SortBidListAction")
        NotificationCenter.default.removeObserver("SyncSwitchStateAction")
        NotificationCenter.default.removeObserver("ShowCommutabilityFilterView")
    }
    
    func sanityBidCheckingForCoverLetterLineCount(){
        // Sanity check the # of lines in the bid package with the number of lines in the Cover Letter
        // But ONLY if we haven't sanity checked this bid package before
        var sanityCheckedBidPackage = UserDefaults.standard.value(forKey: kCBLastBidPackageSanityChecked) as? NSDictionary
        sanityCheckedBidPackage = nil
        
        // Check to see if we've sanity checked this bid package already
        if bidPeriod!.isFirstRoundBid() &&
            (bidPeriod?.month?.intValue != (sanityCheckedBidPackage?[kCBMonthWord] as? NSNumber)?.intValue ||
             bidPeriod?.year?.intValue  != (sanityCheckedBidPackage?[kCBYearWord] as? NSNumber)?.intValue) {
            
            if self.bidPeriod!.isFABid()/* && self.bidPeriod.isSwaAPI */{//MARK: for FA SWA
               //get line count form the pdf
                //and check line validation
//                self.checkLineCountValidation(lineCount: lineCount, sanityCheckedBidPackage: &sanityCheckedBidPackage)
            }else{
                
                let textFile = self.bidPeriod?.textFile(withName: BICoverLetterTextFileName)
                if textFile == nil && !AppState.shared.isHistoricBid {
                    // Looks like the text file never got loaded, perhaps there was a crash during processing, tell the user
                    // they need to redownload
                    AlertService.showAlertForTopVC(title: "Bid Package Error", message: "The bid package was not fully processed.  To try again: (1) delete the bid package, (2) close and reopen the app (by double-tapping the iPad's Home button and swiping CrewBid up), (3) downloading the bid package anew.")
                    
                }else{
                    // we've got a cover letter, parse through it.
                    var stringToScan:String? = nil
                    var coverLetterNumberOfLines:String? = nil
                    let numCharSet = CharacterSet(charactersIn: "0123456789")
                    let words = textFile?.text?.components(separatedBy: .whitespacesAndNewlines)
                    let noWhiteSpaceString = words?.joined(separator: "") ?? ""
                    let scanner = Scanner(string: noWhiteSpaceString)
                    if self.bidPeriod!.isFABid(){
                        stringToScan = "TOTALnumberofpositionsavailableforbid:"
                        _ = scanner.scanUpToString(stringToScan!)
                        if !scanner.isAtEnd {
                            // Scan up to the number of lines
                            _ = scanner.scanUpToCharacters(from: numCharSet)
                            if !scanner.isAtEnd {
                                coverLetterNumberOfLines = scanner.scanCharacters(from: numCharSet)
                            }
                        }
                    }else{
                        stringToScan = String(format: "%@%@", self.bidPeriod!.base!, self.bidPeriod!.positionType?.intValue == BICrewPositionType.Captain.rawValue ? "CA" : "FO")
                        // Scan up to the [BASE] [POSITION] string
                        var myRegex = "\(stringToScan!)\\d{4}"
                        if let range = noWhiteSpaceString.range(of: myRegex, options: .regularExpression) {
                            var nsRange = NSRange(range, in: noWhiteSpaceString)
                            nsRange.location += 5
                            nsRange.length -= 6
                            if let range = Range(nsRange, in: noWhiteSpaceString) {
                                coverLetterNumberOfLines = String(noWhiteSpaceString[range])
                            }
                        } else {
                            // fallback to 3-digit pattern
                            myRegex = "\(stringToScan!)\\d{3}"
                            if let range = noWhiteSpaceString.range(of: myRegex, options: .regularExpression) {
                                var nsRange = NSRange(range, in: noWhiteSpaceString)
                                nsRange.location += 5
                                nsRange.length -= 6
                                if let range = Range(nsRange, in: noWhiteSpaceString) {
                                    coverLetterNumberOfLines = String(noWhiteSpaceString[range])
                                }
                            }
                        }
                    }
                    self.checkLineCountValidation(lineCount: coverLetterNumberOfLines, sanityCheckedBidPackage: &sanityCheckedBidPackage)
                }
                
            }
        }
        
    }
    
//    func handleSeniorityAlert(){
//        if self.bidPeriod!.isSecondRoundBid() && !self.bidPeriod!.isFABid() {
//            if self.bidPeriod!.isFirstRoundPaperBidder?.boolValue == false || self.bidPeriod!.paperBidVacArray?.count == 0{
//                //check paper bid vacation
//            }
//        }
//    }
//    
//    func showSeniorityAlert(){
//        if self.bidPeriod?.seniorityNumber?.intValue != 0 {
//            if self.bidPeriod?.positionType?.intValue == 2 {
//                
//            }
//        }
//    }
    
    func checkLineCountValidation(lineCount: String?, sanityCheckedBidPackage: inout NSDictionary?){
        // Check this number of lines against the bid package number of lines
        // Alert the user if there is a mismatch
        if !self.bidPeriod!.isHistoric!.boolValue {
            if (lineCount?.count ?? 0 > 0) {
                if self.bidPeriod!.lines?.count != Int(lineCount!){
                    // Mismatch, alert the user
                    AlertService.showAlertForTopVC(title: "Bid Package Error", message: "The number of lines in the processed bid package does not match the number of lines in the Cover Letter.  Double check that this is indeed the case.  If so perform the following steps:\n\n  To try again: (1) delete the bid package, (2) close and reopen the app (by double-tapping the iPad's Home button and swiping CrewBid up), (3) downloading the bid package anew.", actions: [(title: "OK", style: .default, handler:{_ in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                            if self?.bidPeriod?.isHistoric?.boolValue != true {
                                self?.handleVacationData()
                            }
                        }
                        self.seniorityAlert()
                    })])
                    if !(self.bidPeriod!.bidPackageErrorDisplayed?.boolValue == true){
                        // mailbidpackageerror fx
                    }
                }
                sanityCheckedBidPackage = [kCBMonthWord: self.bidPeriod!.month!, kCBYearWord: self.bidPeriod!.year!]
                UserDefaults.standard.set(sanityCheckedBidPackage, forKey: kCBLastBidPackageSanityChecked)
            }
        }
    }
    
    
    
    func getSortDiscriptorsPosition() -> [NSSortDescriptor] {
        
        // Create an expression for sorting by line number
        let number = NSExpression(forKeyPath: "number")
        let numberExpDescription = NSExpressionDescription()
        numberExpDescription.name = "number"
        numberExpDescription.expression = number
        numberExpDescription.expressionResultType = .integer16AttributeType
        
        // Initialize an array to store sort descriptors

        var lineSortDiscriptors = [NSSortDescriptor]()
        

        
        // Initialize default position order
        var standardPosOrder = [0, 1, 2, 3]
        let userPosOrder = NSMutableArray() /* TODO: .reserveCapacity(maxPositionsPerLine) */
        
        // Iterate through user-defined line sorts

        for case let lineSort in self.bidPeriod!.getOrderedSortsForPosition(){
            // Ignore line sorts that do not have a key path since these will not
            // be valid sorts.
            
            if nil == lineSort.keyPath || 0 == (lineSort.keyPath?.length ?? 0) {
                continue
            } else {
                if lineSort.category == 3 {
                    // Insert the line number sort first
                    let sort = NSSortDescriptor(key: numberExpDescription.name, ascending: true)
                    lineSortDiscriptors.append(sort)
                    userPosOrder.add(lineSort.type!)
                }
                // Create a sort descriptor based on the user's selection

                let sort = NSSortDescriptor(key: lineSort.keyPath, ascending: (lineSort.ascending != 0))
                lineSortDiscriptors.append(sort)
            }
        }
        // Adjust the position order based on user-defined sorts

        for pos in userPosOrder {
            while let elementIndex = standardPosOrder.firstIndex(of: pos as! Int) { standardPosOrder.remove(at: elementIndex) }
        }
        userPosOrder.add(standardPosOrder)
        // If no user-defined sorts, use default sorting by line number

        if self.bidPeriod!.getOrderedSortsForPosition().count == 0 {
            lineSortDiscriptors.append(NSSortDescriptor(key: "bidOrder", ascending: true))
        } else {
            let sort = NSSortDescriptor(key: numberExpDescription.name, ascending: true)
            lineSortDiscriptors.append(sort)
            // Ensure that the lines are sorted by position if FA since the position logic depends on it
            if bidPeriod!.isFABid() {
                let positionSort = NSSortDescriptor(key: "faPosition", ascending: true)
                lineSortDiscriptors.append(positionSort)
            }
        }
        
       
        return lineSortDiscriptors
    }
    
    
    @objc func bidLines(_ notification: Notification) {
    }
    
    @objc func updateLocalHerbSwitchUI() {
        if UserDefaults.standard.integer(forKey: kCBTimeZoneSetting) == CBTimeZoneSetting.herbTime.rawValue {
            herbLabel.backgroundColor = .purple
            herbLabel.textColor = .white
            
            localLabel.backgroundColor = .white
            localLabel.textColor = .black
        } else {
            localLabel.backgroundColor = .purple
            localLabel.textColor = .white
            
            herbLabel.backgroundColor = .white
            herbLabel.textColor = .black
        }
    }
    
    
    func setupUI(){
        let positionArray = ["CP","FO","FA"]
        let index = dataSource.position.rawValue
        let version = "(\(CBUtils.AppVersion()))"
        let month = CBGlobalMethods.shortMonthNameOf(monthInt: dataSource.month)
        let position = positionArray[index]
        let year = dataSource.year
        let base = dataSource.base
        let round = dataSource.round
        var empID = bidPeriod!.crewIdentifier!.stringValue
        if empID == "21221"{
            empID = String(format: "x%@", empID)
        }else{
            empID = String(format: "e%@", empID)
        }
        lblHome.text = "\(version) \(month) \(year) \(base) \(position) Rnd \(round) - \(empID)"


        btnLocalHerbView.layer.borderWidth = 1
        btnLocalHerbView.layer.borderColor = UIColor.black.cgColor
        btnLocalHerbView.layer.cornerRadius = 16
    
        
        herbLabel.layer.borderColor = UIColor.white.cgColor
        herbLabel.layer.borderWidth = 0.4
        herbLabel.layer.cornerRadius = 15
        herbLabel.clipsToBounds = true
        
        localLabel.layer.borderColor = UIColor.white.cgColor
        localLabel.layer.borderWidth = 0.4
        localLabel.layer.cornerRadius = 15
        localLabel.clipsToBounds = true
        if AppData.shared.isSyncOn == false {
            btnSync.isHidden = true
        }
    }
    
    func firstTimeBidOpen() {
        // Get the current date and componentas
        let today = Date()
        let units: Set<Calendar.Component> = [.hour, .day, .month, .year]
        let dc = Calendar.current.dateComponents(units, from: today)
        var month: Int? = dc.month
        var year: Int? = dc.year
        
        // Increment month and year for the next bid period

        month = 12 == month ? 1 : (month ?? 0) + 1
        year = 12 == month ? (year ?? 0) + 1 : year
        
        // Check if the opened bid package is older
        
        if month != self.bidPeriod?.month?.intValue{
            isOldBidPackage = true
            AlertService.showAlertForTopVC(title: "Old Bid Package", message: "It looks like you've opened a previous month's bid package.  If you meant to, carry on, if not, download the NEW bid package by tapping the + button on the home screen.", actions: [(title: "OK", style: .default, handler: {_ in
                //check sanity
                self.sanityBidCheckingForCoverLetterLineCount()
                if self.bidPeriod?.isHistoric?.boolValue != true {
                    self.handleVacationData()
                }
            })])
        }else{
            self.sanityBidCheckingForCoverLetterLineCount()
            isOldBidPackage = false
            if ((self.bidPeriod?.latestNewsDisplayed?.boolValue) != nil){
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {[weak self] in
                    if self?.bidPeriod?.isHistoric?.boolValue != true {
                        self?.handleVacationData()
                    }
                }
            }
        }
        // Seniority List alert
        if self.bidPeriod?.seniorityNumber?.intValue != 0 {
            if self.bidPeriod?.positionType?.intValue == 2{
                let textFile = self.bidPeriod?.textFile(withName: BISeniorityListTextFileName)
                
                if self.bidPeriod?.isFABid() == true && self.bidPeriod?.isSecondRoundBid() == true{
                    let textField1 = String(format: "%@", (textFile?.text)!)
                    let listItems = textField1.components(separatedBy: "\n") as Array
                    let lastLine = listItems[listItems.count - 2] as String
                    let lastLine2 = listItems[listItems.count - 3] as String
                    let sArray = lastLine.components(separatedBy: "]") as Array
                    let sString = sArray[0] as String
                    let stringItems = sString.components(separatedBy: "-") as Array
                    let totalNumber = stringItems[0] as String
                    let scanner = Scanner(string: totalNumber)
                    let isNumeric = scanner.scanInt(nil) && scanner.isAtEnd
                    
                    if isNumeric == false{
                        let sArray2 = lastLine2.components(separatedBy: "]") as Array
                        let sString2 = sArray2[0] as String
                        let stringItems2 = sString2.components(separatedBy: "-") as Array
                        let totaNumber2 = stringItems2[0] as String
                        self.totalNumberString = self.extractNumber(from: totaNumber2)
                    }else{
                        self.totalNumberString = self.extractNumber(from: totalNumber)
                    }
                }
                if self.bidPeriod?.isFABid() == true && self.bidPeriod?.isFirstRoundBid() == true{
                    let textField1 = String(format: "%@", (textFile?.text)!)
                    let listItems = textField1.components(separatedBy: "\n") as Array
                    let lastLine = listItems[listItems.count - 2] as String
                    let lastLine2 = listItems[listItems.count - 3] as String
                    let sArray = lastLine.components(separatedBy: ")") as Array
                    let sString = sArray[0] as String
                    let newString = sString.trimmingCharacters(in: .whitespaces)
                    let stringItems = newString.components(separatedBy: " ") as Array
                    let totalNumber = stringItems[0]
                    let scanner = Scanner(string: totalNumber)
                    let isNumeric = scanner.scanInt(nil) && scanner.isAtEnd
                    
                    if isNumeric == false{
                        let sArray2 = lastLine2.components(separatedBy: ")") as Array
                        let sString2 = sArray2[0] as String
                        let stringItems2 = sString2.components(separatedBy: " ") as Array
                        let totaNumber2 = stringItems2[0] as String
                        self.totalNumberString = self.extractNumber(from: totaNumber2)
                    }else{
                        self.totalNumberString = self.extractNumber(from: totalNumber)
                    }
                }
                
                if self.totalNumberString == ""{
                    if !(self.bidPeriod?.coverLetterDisplayed?.boolValue ?? false){
                        if !seniorityShowed && self.bidPeriod?.isHistoric?.boolValue == false{
                            var alertText = ""
                            if self.bidPeriod!.paperBidCount!.intValue > 0 {
                                alertText = "We found you in the Seniority List.  You are number \(self.bidPeriod!.seniorityNumber!)."
                            }else{
                                alertText = "We found you in the Seniority List.  You are number \(self.bidPeriod!.seniorityNumber!)."
                            }
//                            self.showSeniorityAlert(text: alertText)
                            AlertService.showAlertForTopVC(title: "Seniority List", message: alertText, actions: [(title: "View Seniority List", style: .default, handler:{_ in
                                self.showSeniority()
                            }),(title: "OK", style: .default, handler:{_ in
                                self.showCoverLetter()
                            })])
                        }
                    }else{
                        //show toast text
                        self.showToastWith(text: "We found you in the Seniority List.  You are number \(self.bidPeriod!.seniorityNumber!).", duration: 5.5)
                    }
                }else{
                    if !(self.bidPeriod?.coverLetterDisplayed?.boolValue ?? false){
                        if !seniorityShowed && self.bidPeriod?.isHistoric?.boolValue == false{
                            var alertText = ""
                            if self.bidPeriod!.paperBidCount!.intValue > 0 {
                                let paperCountAvoidedSeniorityListPosition = NSNumber(
                                    value: self.bidPeriod!.seniorityNumber!.intValue - self.bidPeriod!.paperBidCount!.intValue)
                                alertText = String(format: "We found you in the Seniority List. You are number %@ out of %@\n\nThere are %@ paper bids above you, making you %@ on the bid list.", self.bidPeriod!.seniorityNumber!, self.totalNumberString!, self.bidPeriod!.paperBidCount!, paperCountAvoidedSeniorityListPosition)
                            }else{
                                alertText = String(format: "\nWe found you in the Seniority List.\nYou are number %@ out of %@", self.bidPeriod!.seniorityNumber!, self.totalNumberString!)
                            }
//                            self.showSeniorityAlert(text: alertText)
                            AlertService.showAlertForTopVC(title: "Seniority List", message: alertText, actions: [(title: "View Seniority List", style: .default, handler:{_ in
                                self.showSeniority()
                            }),(title: "OK", style: .default, handler:{_ in
                                self.showCoverLetter()
                            })])
                        }
                    }else{
                        self.showToastWith(text: String(format: "We found you in the Seniority List. You are number %@ out of %@", self.bidPeriod!.seniorityNumber!, self.totalNumberString!), duration: 6)
                    }
                }
            }else{
                var newDes = ""
                let textFile = bidPeriod!.textFile(withName: BISeniorityListTextFileName)
                if let range = textFile!.text!.range(of: "RECORD COUNT") {
                    let startIndex = textFile!.text!.index(range.lowerBound, offsetBy: 16, limitedBy: textFile!.text!.endIndex)
                if let startIndex = startIndex {
                    let endIndex = textFile!.text!.index(startIndex, offsetBy: 5, limitedBy: textFile!.text!.endIndex) ?? textFile!.text!.endIndex
                        newDes = String(textFile!.text![startIndex..<endIndex])
//                        print(newDes)
                    }
                }
                if !(self.bidPeriod?.coverLetterDisplayed?.boolValue ?? false){
                    if !seniorityShowed && self.bidPeriod?.isHistoric?.boolValue == false{
                        var alertText = ""
                        if self.bidPeriod!.paperBidCount!.intValue > 0 {
                            let paperCountAvoidedSeniorityListPosition = NSNumber(
                                value: self.bidPeriod!.seniorityNumber!.intValue - self.bidPeriod!.paperBidCount!.intValue)
                            alertText = String(format: "We found you in the Seniority List. You are number %@ out of %@\n\nThere are %@ paper bids above you, making you %@ on the bid list.", self.bidPeriod!.seniorityNumber!, self.bidPeriod!.paperBidCount!, paperCountAvoidedSeniorityListPosition)
                        }else{
                            alertText = String(format: "\nWe found you in the Seniority List.\nYou are number %@ out of %@", self.bidPeriod!.seniorityNumber!, newDes)
                        }
//                        self.showSeniorityAlert(text: alertText)
                        AlertService.showAlertForTopVC(title: "Seniority List", message: alertText, actions: [(title: "View Seniority List", style: .default, handler:{_ in
                            self.showSeniority()
                        }),(title: "OK", style: .default, handler:{_ in
                            self.showCoverLetter()
                        })])
                    }
                }else{
                    var alertText = ""
                    if self.bidPeriod!.paperBidCount!.intValue > 0 {
                        let paperCountAvoidedSeniorityListPosition = NSNumber(
                            value: self.bidPeriod!.seniorityNumber!.intValue - self.bidPeriod!.paperBidCount!.intValue)
                        alertText = String(format: "We found you in the Seniority List. You are number %@ out of %@\n\nThere are %@ paper bids above you, making you %@ on the bid list.", self.bidPeriod!.seniorityNumber!, newDes, self.bidPeriod!.paperBidCount!, paperCountAvoidedSeniorityListPosition)
                    }else{
                        alertText = String(format: "We found you in the Seniority List. You are number %@ out of %@", self.bidPeriod!.seniorityNumber!, newDes)
                    }
                    self.showToastWith(text: alertText, duration: 6)
                }
            }
        }else{
            if !(self.bidPeriod?.coverLetterDisplayed?.boolValue ?? false){
                if !seniorityShowed && self.bidPeriod?.isHistoric?.boolValue == false{
                    if self.bidPeriod?.isFABid() != true && self.bidPeriod?.isSecondRoundBid() == true && self.bidPeriod!.paperBidVacArray?.count ?? 0 > 0{
                        var message = "We did not find you in the Second round Seniority list, but we did find you in the First round as a \"Paper\" bidder. We also found that you have Vacation"
                        for case let dic as NSDictionary in self.bidPeriod!.paperBidVacArray!{
                            let endAbsenceDate = dic["EndAbsenceDate"] as! String
                            let startAbsenceDate = dic["StartAbsenceDate"] as! String
                            let start = self.getDateFromJSON(startAbsenceDate)!
                            let end = self.getDateFromJSON(endAbsenceDate)!
                            
                            let df = DateFormatter()
                            df.dateStyle = .long
                            df.timeStyle = .none
                            
                            var startStrLong = df.string(from: start)
                            var endStrLong = df.string(from: end)
                            if endStrLong.length > 6 && startStrLong.length > 6 {
                                startStrLong = startStrLong.substring(to: startStrLong.length - 5)
                                endStrLong = endStrLong.substring(to: endStrLong.length - 5)
                            }
                            message = String(format: "%@, %@ to %@", message, startStrLong, endStrLong)
                        }
//                        self.showSeniorityAlert(text: message)
                        AlertService.showAlertForTopVC(title: "Seniority List", message: message, actions: [(title: "View Seniority List", style: .default, handler:{_ in
                            self.showSeniority()
                        }),(title: "OK", style: .default, handler:{_ in
                            self.bidPeriod?.coverLetterDisplayed = true
                            self.showCoverLetter()
                        })])
                    }else{
                        var message = "We did not find you in the Seniority list.  Sometimes the format of the list will cause problems and we will incorrectly read the list.  We will display the Seniority list next.  If you do not see yourself in the list, we suggest you call Planning to find out why you are missing from the seniority list."
                        if self.bidPeriod?.isFABid() != true && self.bidPeriod?.isSecondRoundBid() == true && self.bidPeriod?.isFirstRoundPaperBidder?.boolValue == true {
                            message = "We did not find you in the Second round Seniority list, but we did find you in the First round as a \"Paper\" bidder."
                        }
//                        self.showSeniorityAlert(text: message)
                        AlertService.showAlertForTopVC(title: "Seniority List", message: message, actions: [(title: "View Seniority List", style: .default, handler:{_ in
                            self.showSeniority()
                        }),(title: "OK", style: .default, handler:{_ in
                            self.bidPeriod?.coverLetterDisplayed = true
                            self.showCoverLetter()
                        })])
                    }
                }else{
                    if self.bidPeriod?.isFABid() != true && self.bidPeriod?.isSecondRoundBid() == true && self.bidPeriod?.isFirstRoundPaperBidder?.boolValue == true {
                        self.showToastWith(text: "We did not find you in the Second round Seniority list, but we did find you in the First round as a \"Paper\" bidder.", duration: 4)
                    }else{
                        self.showToastWith(text: "We did not find you in the Seniority list.", duration: 4)
                    }
                }
            }else{
                if self.bidPeriod?.isFABid() != true && self.bidPeriod?.isSecondRoundBid() == true && self.bidPeriod?.isFirstRoundPaperBidder?.boolValue == true {
                    self.showToastWith(text: "We did not find you in the Second round Seniority list, but we did find you in the First round as a \"Paper\" bidder.", duration: 4)
                }else{
                    self.showToastWith(text: "We did not find you in the Seniority list.", duration: 4)
                }
            }
        }
        try! self.bidPeriod?.managedObjectContext?.save()
    }
    //MARK: need to check this alert fn
    func showSeniorityAlert(text: String){
        AlertService.showAlertForTopVC(title: "Seniority List", message: text, actions: [(title: "View Seniority List", style: .default, handler:{_ in
            self.showSeniority()
        }),(title: "OK", style: .default, handler:{_ in
            self.bidPeriod?.coverLetterDisplayed = true
            self.showCoverLetter()
        })])
    }
    
    func showToastWith(text: String, duration: TimeInterval){
        self.toastView.layer.cornerRadius = 20
        self.toastView.layer.masksToBounds = true
        self.toastView.alpha = 0
        self.toastLabel.text = text
        UIView.animate(withDuration: 0.5, delay: 1, options: .curveEaseOut, animations: {
            self.toastView.alpha = 0.8
            }) { _ in
                UIView.animate(withDuration: 0.5, delay: duration, options: .curveEaseOut, animations: {
                    self.toastView.alpha = 0
                }, completion: nil)
            }
    }
    
    func showCoverLetter(){
        self.bidPeriod?.coverLetterDisplayed = true
        if !(self.bidPeriod?.latestNewsDisplayed?.boolValue ?? false) {
            if self.bidPeriod!.isFABid()/* && self.bidPeriod.isSwaAPI*/{
                if !isOldBidPackage{
                    let details = ["isFromFirstTimeOpenBid":true]
                    NotificationCenter.default.post(name: NSNotification.Name(KCBOpenCoverletter), object: self,userInfo: details)
                }
            }else{
                let details = ["isFromFirstTimeOpenBid":true]
                NotificationCenter.default.post(name: NSNotification.Name(KCBOpenCoverletter), object: self,userInfo: details)
            }
        }
    }
    
    func showSeniority(){
        self.seniorityShowed = true
        //add FA asn Swa condition
        let vc = UIStoryboard(name: "BidActions", bundle: nil).instantiateViewController(withIdentifier: "CBTextViewController") as! CBTextViewController
        vc.bidPeriod = self.bidPeriod
        vc.dataTypeSelected = TextFileType.seniorityList
        vc.isFromFirstTimeOpenBid = true
//        self.navigationController?.pushViewController(vc, animated: true)
        vc.modalPresentationStyle = .fullScreen
        vc.modalTransitionStyle = .crossDissolve
        self.present(vc, animated: true, completion: nil)
    }
    
    @objc private func didDismissLatestNews() {
        if self.bidPeriod?.latestNewsDisplayed?.boolValue == true{
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {[weak self] in
                if self?.bidPeriod?.isHistoric?.boolValue != true {
                    self?.handleVacationData()
                }
            }
        }
        
    }
    
    func extractNumber(from text: String) -> String {
        let nonDigits = CharacterSet.decimalDigits.inverted
        let components = text.components(separatedBy: nonDigits)
        return components.joined()
    }
    
    func getDateFromJSON(_ string: String) -> Date? {
        // Lazy static regex, equivalent to dispatch_once
        struct Static {
            static let regex: NSRegularExpression = {
                let pattern = #"^\/date\((-?\d+)(?:([+-])(\d{2})(\d{2}))?\)\/$"#
                return try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            }()
        }
        
        let range = NSRange(location: 0, length: string.utf16.count)
        guard let match = Static.regex.firstMatch(in: string, options: [], range: range) else {
            return nil
        }
        
        // Milliseconds part
        if let millisRange = Range(match.range(at: 1), in: string) {
            var seconds = (Double(string[millisRange]) ?? 0.0) / 1000.0
            
            // Optional timezone sign/hours/minutes
            if match.range(at: 2).location != NSNotFound,
               let signRange = Range(match.range(at: 2), in: string),
               let hourRange = Range(match.range(at: 3), in: string),
               let minuteRange = Range(match.range(at: 4), in: string) {
                
                let sign = String(string[signRange]) // "+" or "-"
                let hours = Double(sign + string[hourRange]) ?? 0
                let minutes = Double(sign + string[minuteRange]) ?? 0
                seconds += (hours * 3600) + (minutes * 60)
            }
            
            return Date(timeIntervalSince1970: seconds)
        }
        
        return nil
    }
    
    
    @IBAction func btnHomeAction(_ sender: UIButton) {
        if let navigationController = self.navigationController {
            navigationController.popToRootViewController(animated: true)
        } else {
            self.dismiss(animated: true)
        }
    }
    
    @IBAction func localHerbAction(_ sender: Any) {
        if UserDefaults.standard.integer(forKey: kCBTimeZoneSetting) == CBTimeZoneSetting.herbTime.rawValue{
            UserDefaults.standard.set(CBTimeZoneSetting.localTime.rawValue, forKey: kCBTimeZoneSetting)
//            localLabel.backgroundColor = UIColor.purple
//            localLabel.textColor = UIColor.white
//            herbLabel.backgroundColor = UIColor.white
//            herbLabel.textColor = UIColor.black
        }else{
            UserDefaults.standard.set(CBTimeZoneSetting.herbTime.rawValue, forKey: kCBTimeZoneSetting)
//            localLabel.backgroundColor = UIColor.white
//            localLabel.textColor = UIColor.black
//            herbLabel.backgroundColor = UIColor.purple
//            herbLabel.textColor = UIColor.white
        }
        updateLocalHerbSwitchUI()
        NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
    }
    
    
    
    @IBAction func settingsAction(_ sender: Any) {
        let storyboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "EmbeddedSettingsVC") as! EmbeddedSettingsVC
        vc.bidPeriod = bidPeriod
        vc.bdPrd = bdPrd
        vc.preferredContentSize = CGSize(width: 300, height: 210)
        vc.modalPresentationStyle = .custom
        let frame = CGRect(x: 15, y: 35, width: 0, height: 0)
        vc.showPopover(sourceView: btnSettings, sourceRect: frame)
    }
    
    @IBAction func btnShareAction(_ sender: Any) {
        let storyboard : UIStoryboard = UIStoryboard(name: "BidActions", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "EmbeddedBidActionsVC") as! EmbeddedBidActionsVC
       
        vc.preferredContentSize = CGSize(width: 310, height: 610)
        vc.modalPresentationStyle = .custom
        let frame = CGRect(x: 15, y: 35, width: 0, height: 0)
        vc.showPopover(sourceView: btnShare, sourceRect: frame)
    }
    
    @IBAction func btnHelpAction(_ sender: Any) {
        let storyBoard = UIStoryboard(name: "HelpMenu", bundle: nil)
        if let helpMenuVC = storyBoard.instantiateViewController(withIdentifier: "CBHelpMenuController") as? CBHelpMenuController{
            helpMenuVC.modalTransitionStyle = .crossDissolve
            helpMenuVC.preferredContentSize = CGSize(width: 764, height: 630)
            present(helpMenuVC, animated: true)
        }
    }
    
    @objc func setupLayoutView(){
        if AppData.shared.isBidListSort == true{
            leftShadowView.isHidden = true
            rightShadowView.isHidden = false
            bidView.isHidden = false
            self.bidVC = self.storyboard?.instantiateViewController(identifier: "CBBidListVC") as? CBBidListVC
            self.bidVC?.view.frame = self.bidCont.frame
            if let bidController = self.bidVC {
                
                self.bidCont.addSubview(bidController.view)
                self.addChild(bidController)
                bidController.didMove(toParent: self)
          }
        }
        else {
            leftShadowView.isHidden = false
            rightShadowView.isHidden = false
            bidView.isHidden = true
        }
    }
    
    @objc func setupLayoutViewForSwitch() {
        if AppData.shared.isSyncOn {
            btnSync.isHidden = false
        }
        else {
            btnSync.isHidden = true
        }
    }
    
    @objc func ShowCommutablilitySortView() {
            let storyboard = UIStoryboard(name: "BidDocument", bundle: nil)
            let commuteInformation = storyboard.instantiateViewController(withIdentifier: "CommuteInformation") as! CBCommuteInfoViewController
            commuteInformation.bidPeriod = self.bidPeriod
            commuteInformation.commutabilityType = CommutabilityType.sort
            commuteInformation.preferredContentSize = CGSize(width: 320, height: 320)
            DispatchQueue.main.async {
                self.present(commuteInformation, animated: true) {
                }
            }
        }
    
    
    @objc func showCommutablilityFilterView() {
        let topVC = AlertService.currentTopViewController()
        let storyboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let commuteInformation = storyboard.instantiateViewController(withIdentifier: "CommuteInformation") as! CBCommuteInfoViewController
        commuteInformation.bidPeriod = self.bidPeriod
        commuteInformation.commutabilityType = CommutabilityType.filter
        commuteInformation.preferredContentSize = CGSize(width: 320, height: 320)
//        print("Presenting from topVC: \(topVC!)")
        DispatchQueue.main.async {
            topVC!.present(commuteInformation, animated: true) {
                print("commuteInformation presented successfully")
            }
        }
    }
    
    @IBAction func btnSyncAction(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Sync", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "syncFirstVC")
        vc.preferredContentSize = CGSize(width: 768, height: 900)
        present(vc, animated: true)
    }
    
    func showVacationWeekAlert(completionHandler: @escaping (Bool) -> Void) {
        if self.bidPeriod?.isFABid() == false {
            let weekTypes = self.getWeekTypeForVacationAlert()
            if weekTypes.count == 0 {
                completionHandler(true)
                return
            }
            let weekTypeDate = self.getWeekTypeDateForVacationAlert()
            var alertMessage: String = ""
            if weekTypes.count == 1 {
                if weekTypes.contains("A") {
                    alertMessage = "You have an `A` Week Vacation: \(weekTypeDate["aStartDate"] ?? "") - \(weekTypeDate["aEndDate"] ?? "")."
                    alertMessage += "\n\nA weeks generally are the lead-out month vacation.\n\nThere are opportunities with Month-To-Month Vacations, but there are ALSO limitations.\n\nWe suggest you read the following documents to improve your bidding knowledge."
                }
                if weekTypes.contains("E") {
                    alertMessage = "You have an `E` Week Vacation: \(weekTypeDate["eStartDate"] ?? "") - \(weekTypeDate["eEndDate"] ?? "")."
                    alertMessage += "\n\nE weeks generally are the lead-in month vacation.\n\nThere are opportunities with Month-To-Month Vacations, but there are ALSO limitations.\n\nWe suggest you read the following documents to improve your bidding knowledge."
                }
                if weekTypes.contains("F") {
                    alertMessage = "You have an `F` Week Vacation: \(weekTypeDate["fStartDate"] ?? "") - \(weekTypeDate["fEndDate"] ?? "")."
                    alertMessage += "\n\nF weeks generally are the lead-uut month vacation.\n\nThere are opportunities with Month-To-Month Vacations, but there are ALSO limitations.\n\nWe suggest you read the following documents to improve your bidding knowledge."
                }
            }
            else {
                if weekTypes.contains("A") {
                    alertMessage = "You have an `A` Week Vacation: \(weekTypeDate["aStartDate"] ?? "") - \(weekTypeDate["aEndDate"] ?? "")."
                    alertMessage += "\n\nA weeks generally are the lead-out month vacation.\n\nThere are opportunities with Month-To-Month Vacations, but there are ALSO limitations.\n\nWe suggest you read the following documents to improve your bidding knowledge."
                }
                if weekTypes.contains("E") {
                    alertMessage = "You have an `E` Week Vacation: \(weekTypeDate["eStartDate"] ?? "") - \(weekTypeDate["eEndDate"] ?? "")."
                    alertMessage += "\n\nE weeks generally are the lead-in month vacation.\n\nThere are opportunities with Month-To-Month Vacations, but there are ALSO limitations.\n\nWe suggest you read the following documents to improve your bidding knowledge."
                }
                if weekTypes.contains("F") {
                    alertMessage = "You have an `F` Week Vacation: \(weekTypeDate["fStartDate"] ?? "") - \(weekTypeDate["fEndDate"] ?? "")."
                    alertMessage += "\n\nF weeks generally are the lead-out month vacation.\n\nThere are opportunities with Month-To-Month Vacations, but there are ALSO limitations.\n\nWe suggest you read the following documents to improve your bidding knowledge."
                }
                if weekTypes.contains("A") && weekTypes.contains("E") {
                    var alertMessage = "You have an `A` & `E` Week Vacation: \(weekTypeDate["aStartDate"] ?? "") - \(weekTypeDate["aEndDate"] ?? "") and \(weekTypeDate["eStartDate"] ?? "") - \(weekTypeDate["eEndDate"] ?? "")."
                    alertMessage += "\n\nA weeks generally are the lead-out month and E weeks generally are the lead-in month vacation.\n\nThere are opportunities with Month-To-Month Vacations, but there are ALSO limitations.\n\nWe suggest you read the following documents to improve your bidding knowledge."
                }
            }
            if alertMessage == "" {
                completionHandler(true)
                return
            }
            let storyboard = UIStoryboard(name: "BidActions", bundle: nil)
            let monthToMonthAlert = storyboard.instantiateViewController(withIdentifier: "CBMonthToMonthAlertVC") as! CBMonthToMonthAlertVC
            monthToMonthAlert.text = alertMessage
            if didDisplayMonthToMonthAlert == false {
                let storyboard : UIStoryboard = UIStoryboard(name: "BidActions", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "CBMonthToMonthAlertVC") as! CBMonthToMonthAlertVC
                vc.text = alertMessage
//                vc.delegate = self
                vc.preferredContentSize = CGSize(width: 700, height: 600)
//                vc.providesPresentationContextTransitionStyle = true
//                vc.definesPresentationContext = true
//                vc.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
//                vc.view.backgroundColor = UIColor.clear
//                    vc.onDoneBlock = { result in
//                        dismissHandler(true)
//                    }
                self.present(vc, animated: true, completion: nil)
            }
            else {
                completionHandler(true)
            }
        }
        else {
            completionHandler(true)
        }
    }
    
    func getWeekTypeForVacationAlert() -> [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        let AweekArray: [String] = self.bidPeriod!.aWeekDays?.components(separatedBy: ",") ?? []
        let BweekArray: [String] = self.bidPeriod!.bWeekDays?.components(separatedBy: ",") ?? []
        let CweekArray: [String] = self.bidPeriod!.cWeekDays?.components(separatedBy: ",") ?? []
        let DweekArray: [String] = self.bidPeriod!.dWeekDays?.components(separatedBy: ",") ?? []
        let EweekArray: [String] = self.bidPeriod!.eWeekDays?.components(separatedBy: ",") ?? []
        let FweekArray: [String] = self.bidPeriod!.fWeekDays?.components(separatedBy: ",") ?? []
        
        var weekTypeArray: [String] = []
        for i in 0..<(self.bidPeriod?.vacations?.allObjects.count)! {
            let vacation = (self.bidPeriod!.vacations!.allObjects as? [BIVacation])![i]
            if !(vacation.vacationType == "VA") {
                continue
            }
            let vacationStartDate = formatter.string(from: vacation.startDate!)
            let vacationEndDate = formatter.string(from: vacation.endDate!)
            if (AweekArray.contains(vacationStartDate) && AweekArray.contains(vacationEndDate)) {
                weekTypeArray.append("A")
            }
            else if (BweekArray.contains(vacationStartDate) && BweekArray.contains(vacationEndDate)) {
                weekTypeArray.append("B")
            }
            else if (CweekArray.contains(vacationStartDate) && CweekArray.contains(vacationEndDate)) {
                weekTypeArray.append("C")
            }
            else if (DweekArray.contains(vacationStartDate) && DweekArray.contains(vacationEndDate)) {
                weekTypeArray.append("D")
            }
            else if (EweekArray.contains(vacationStartDate) && EweekArray.contains(vacationEndDate)) {
                weekTypeArray.append("E")
            }
            else if (FweekArray.contains(vacationStartDate) && FweekArray.contains(vacationEndDate)) {
                weekTypeArray.append("F")
            }
        }
        return weekTypeArray
    }
    
    func getWeekTypeDateForVacationAlert() -> [String: String] {
        let formatter = DateFormatter()
        let aWeekArray: [String] = self.bidPeriod!.aWeekDays?.components(separatedBy: ",") ?? []
        let bWeekArray: [String] = self.bidPeriod!.bWeekDays?.components(separatedBy: ",") ?? []
        let cWeekArray: [String] = self.bidPeriod!.cWeekDays?.components(separatedBy: ",") ?? []
        let dWeekArray: [String] = self.bidPeriod!.dWeekDays?.components(separatedBy: ",") ?? []
        let eWeekArray: [String] = self.bidPeriod!.eWeekDays?.components(separatedBy: ",") ?? []
        let fWeekArray: [String] = self.bidPeriod!.fWeekDays?.components(separatedBy: ",") ?? []
        
        var weekTypeDateDict: [String: String] = [:]
        for i in 0..<(self.bidPeriod?.vacations?.allObjects.count)! {
            formatter.dateFormat = "dd/MM/yyyy"
            let vacation = (self.bidPeriod!.vacations!.allObjects as? [BIVacation])![i]
            let vacationStartDate = formatter.string(from: vacation.startDate!)
            let vacationEndDate = formatter.string(from: vacation.endDate!)
            
            formatter.dateFormat = "dd MMM"
            let vacationStartDateDisp = formatter.string(from: vacation.startDate!)
            let vacationEndDateDisp = formatter.string(from: vacation.endDate!)
            if (aWeekArray.contains(vacationStartDate) && aWeekArray.contains(vacationEndDate)) {
                weekTypeDateDict["aStartDate"] = vacationStartDateDisp
                weekTypeDateDict["aEndDate"] = vacationEndDateDisp
            }
            else if (bWeekArray.contains(vacationStartDate) && bWeekArray.contains(vacationEndDate)) {
                weekTypeDateDict["bStartDate"] = vacationStartDateDisp
                weekTypeDateDict["bEndDate"] = vacationEndDateDisp
            }
            else if (cWeekArray.contains(vacationStartDate) && cWeekArray.contains(vacationEndDate)) {
                weekTypeDateDict["cStartDate"] = vacationStartDateDisp
                weekTypeDateDict["cEndDate"] = vacationEndDateDisp
            }
            else if (dWeekArray.contains(vacationStartDate) && dWeekArray.contains(vacationEndDate)) {
                weekTypeDateDict["dStartDate"] = vacationStartDateDisp
                weekTypeDateDict["dEndDate"] = vacationEndDateDisp
            }
            else if (eWeekArray.contains(vacationStartDate) && eWeekArray.contains(vacationEndDate)) {
                weekTypeDateDict["eStartDate"] = vacationStartDateDisp
                weekTypeDateDict["eEndDate"] = vacationEndDateDisp
            }
            else if (fWeekArray.contains(vacationStartDate) && fWeekArray.contains(vacationEndDate)) {
                weekTypeDateDict["fStartDate"] = vacationStartDateDisp
                weekTypeDateDict["fEndDate"] = vacationEndDateDisp
            }
        }
        return weekTypeDateDict
    }
    
    @objc func handleVacationData() {
        self.bidPeriod!.isVacationRemoved = NSNumber(value: false)
        self.bidPeriod?.secretSwitchOn = "YES"
//        vacation data
        let secretEnabled = UserDefaults.standard.value(forKey: "isSecretVDSwitchEnabled") ?? ""
        if secretEnabled as! String == "YES" {
            self.bidPeriod?.containsVacay = NSNumber(value: true)
        }
//        adding bar items
        if self.bidPeriod?.isFABid() == true {
            if !(self.bidPeriod!.latestNewsDisplayed?.boolValue == true) {
                if self.bidPeriod!.containsVacay?.boolValue == true {
                    self.bidPeriod?.onlyContainEOM = "NO"
                }
                else {
                    self.bidPeriod?.onlyContainEOM = "YES"
                }
            }
            if self.bidPeriod?.isFirstRoundBid() == true {
                btnWbidMax.isHidden = false
            }
            else {
                btnWbidMax.isHidden = true
                btnWbidMax.isSelected = false
            }
            self.enableOrDisableEOMButton()
            self.executeEOMForFA()
        }
        else {
            if self.bidPeriod!.latestNewsDisplayed?.boolValue ?? false {
                if (self.bidPeriod!.containsVacay?.boolValue == true || secretEnabled as! String == "YES") {
                    self.bidPeriod!.onlyContainEOM = "NO"
                }
                else {
                    self.bidPeriod!.onlyContainEOM = "YES"
                }
            }
            btnWbidMax.isHidden = false
            btnSwaptimizer.isHidden = false
            self.enableOrDisableEOMButton()
            
//            vacation data
            if (UserDefaults.standard.value(forKey: "isMaxSubScriptionOfEnteredUser") as? String ?? ""  == "YES") {
                let value: NSNumber = UserDefaults.standard.integer(forKey: "SecretVDuserName") as NSNumber
                self.bidPeriod!.historicSecretUser = value
                self.bidPeriod!.isMaxSubScriptionOfEnteredUser = NSNumber(value: true)
            }
            else {
                self.bidPeriod!.isMaxSubScriptionOfEnteredUser = NSNumber(value: false)
            }
            if (self.bidPeriod!.onlyContainEOM == "YES") {
                btnSwaptimizer.isEnabled = true
                btnWbidMax.isEnabled = true
                self.executeEOMModule()
            }
            else {
                if (secretEnabled as! String == "YES") {
                    self.bidPeriod!.selectedSegmentVacType = UserDefaults.standard.value(forKey: "VacationType") as? String
//                    self.bidPeriod?.vacationName = app.ObjUserAccount.VacationFilename
                    self.executeEOMModule()
                }
                else {
                    self.executeEOMModule()
                }
            }
        }
    }
    
    func enableOrDisableEOMButton() {
//        let funcName = #function
        if (self.bidPeriod?.vacationType == "CREWBIDF" || self.bidPeriod?.vacationType == "WBIDF" || self.bidPeriod?.vacationType == "FAVacationF" || self.bidPeriod?.vacationType == "FAVacationEomOnly") {
            self.bidPeriod?.currentDateTime = Date()
            self.bidPeriod?.isStateFileModifiedToSync = NSNumber(value: true)
            btnEOM.isEnabled = true
            btnEOM.alpha = 1
            btnEOM.isSelected = true
            self.bidPeriod?.isEomOn = NSNumber(value: true)
            btnEOM.backgroundColor = UIColor(red: 35.00/255.0, green: 177.0/255.0, blue: 76.0/255.0, alpha: 1.00)
            btnEOM.setTitleColor(.white, for: .selected)
        }
        else if (self.bidPeriod?.vacationType == "CREWBID" || self.bidPeriod?.vacationType == "WBID" || self.bidPeriod?.vacationType == "FAVacation") {
            self.bidPeriod?.currentDateTime = Date()
            self.bidPeriod?.isStateFileModifiedToSync = NSNumber(value: true)
            btnEOM.isEnabled = true
            btnEOM.alpha = 1
            btnEOM.isSelected = false
            self.bidPeriod?.isEomOn = NSNumber(value: false)
            btnEOM.backgroundColor = .white
            btnEOM.setTitleColor(.black, for: .normal)
        }
        else {
            btnEOM.isSelected = false
            self.bidPeriod?.isEomOn = NSNumber(value: false)
            btnEOM.backgroundColor = .white
            btnEOM.setTitleColor(.black, for: .normal)
        }
        if self.bidPeriod?.isFABid() == false {
            if ((self.bidPeriod?.isSwaptimizerOn?.boolValue == true) && (self.bidPeriod!.vacationType != nil) && (self.bidPeriod?.vacationType == "WBIDF")) {
                btnEOM.isSelected = false
                self.bidPeriod?.isEomOn = NSNumber(value: false)
                btnEOM.backgroundColor = .white
                btnEOM.setTitleColor(.black, for: .normal)
            }
        }
    }
    
    func executeEOMForFA() {
        if ( self.bidPeriod!.vacationType == "FAVacationF") {
            self.bidPeriod!.userVacationWbidOrCrewBid = "FAVacationF"
            alertShouldDisplay = false
            self.checkForSWAPtimizerFile()
        }
        else if ( self.bidPeriod!.vacationType == "FAVacation") {
            self.bidPeriod!.userVacationWbidOrCrewBid = "FAVacation"
            alertShouldDisplay = false
            self.checkForSWAPtimizerFile()
        }
        else if ( self.bidPeriod!.vacationType == "FAVacationEomOnly") {
            self.bidPeriod!.userVacationWbidOrCrewBid = "FAVacationEomOnly"
            alertShouldDisplay = false
            self.checkForSWAPtimizerFile()
        }
        else {
            if (!(self.bidPeriod!.eomIsNo != nil && self.bidPeriod!.eomIsNo == "YES")) {
                AlertService.showAlertForTopVC(title: "Vacation!", message: "Do you have Vacation Starting in the first 3 days of the next bid period \(self.eomMonth()) ?", actions: [(
                    title: "Yes",
                    style: .default,
                    handler: { _ in
                        self.bidPeriod?.eomIsNo = "NO"
                        do {
                            try self.context!.save()
                        }
                        catch {
                            print("error saving \(error.localizedDescription)")
                        }
                        self.eomVacationDateSelect(fromBtnAction: false)
                    }
                ),
                (
                    title: "No",
                    style: .cancel,
                    handler: { _ in
                        self.bidPeriod!.eomIsNo = "YES"
                        do {
                            try self.context!.save()
                        }
                        catch {
                            print("error saving \(error.localizedDescription)")
                        }
                        self.bidPeriod!.userVacationWbidOrCrewBid = "FAVacation"
                        self.checkForSWAPtimizerFile()
                    }
                )])
            }
        }
    }
    
    func checkForSWAPtimizerFile() {
//        MARK: needed to add fa vacation buttopn in storyboard before
        btnSwaptimizer.isEnabled = true
        btnWbidMax.isEnabled = true
        self.bidPeriod?.swaptimizerStatus = CBSwaptimizerStatus.checked.rawValue as NSNumber
        let vacationType = self.bidPeriod!.userVacationWbidOrCrewBid
        let vDL = CBVacationDownloader()
        vDL.bidPeriod = self.bidPeriod
        vDL.calendarData = self.calendarData
        if vacationType == "CREWBID" {
            if (self.bidPeriod!.cbFileIntent != nil) {
                self.crewbid(vDL: vDL)
            }
            else {
                switch (app.objNetworkType) {
                case .ground:
                    self.crewbid(vDL: vDL)
                    break
                case .paid:
                    self.crewbid(vDL: vDL)
                case .free:
                    self.disableVacationButton()
                    btnSwaptimizer.isEnabled = true
                    btnWbidMax.isEnabled = true
                    AlertService.showAlertForTopVC(title: "Network not available!!", message: "You are on the plane using the free company limited internet connection.\nYou cannot download vacation using the limited internet connection.Either pay for a full internet connection or wailt until you get on the ground and have a full internet connection")
                    break
                }
            }
        }
        else if vacationType == "CREWBIDF" {
            if self.bidPeriod!.cbFileIntent != nil {
                self.eomCrewBid(vDL: vDL)
            }
            else {
                switch (app.objNetworkType) {
                case .ground:
                    self.eomCrewBid(vDL: vDL)
                    break
                case .paid:
                    self.eomCrewBid(vDL: vDL)
                    break
                case .free:
                    self.disableVacationButton()
                    btnSwaptimizer.isEnabled = true
                    btnWbidMax.isEnabled = true
                    AlertService.showAlertForTopVC(title: "Network not available!!", message: "You are on the plane using the free company limited internet connection.\nYou cannot download vacation using the limited internet connection.Either pay for a full internet connection or wailt until you get on the ground and have a full internet connection")
                    break
                }
            }
        }
        
        else if vacationType == "WBID" {
            if self.bidPeriod!.wbFileIntent == nil {
                self.wbid(vDL: vDL)
            }
            else {
                switch (app.objNetworkType) {
                case .ground:
                    self.wbid(vDL: vDL)
                    break
                case .paid:
                    self.wbid(vDL: vDL)
                    break
                case .free:
                    self.disableVacationButton()
                    btnSwaptimizer.isEnabled = true
                    btnWbidMax.isEnabled = true
                    AlertService.showAlertForTopVC(title: "Network not available!!", message: "You are on the plane using the free company limited internet connection.\nYou cannot download vacation using the limited internet connection.Either pay for a full internet connection or wailt until you get on the ground and have a full internet connection")
                    break
                }
            }
        }
        
        else if vacationType == "WBIDF" {
            if self.bidPeriod!.wbVacationfileF == nil {
                self.eomWbid(vDL: vDL)
            }
            else {
                switch (app.objNetworkType) {
                case .ground:
                    self.eomWbid(vDL: vDL)
                    break
                case .paid:
                    self.eomWbid(vDL: vDL)
                    break
                case .free:
                    self.disableVacationButton()
                    btnSwaptimizer.isEnabled = true
                    btnWbidMax.isEnabled = true
                    AlertService.showAlertForTopVC(title: "Network not available!!", message: "You are on the plane using the free company limited internet connection.\nYou cannot download vacation using the limited internet connection.Either pay for a full internet connection or wailt until you get on the ground and have a full internet connection")
                    break
                }
            }
        }
        
        else if vacationType == "FAVacation" {
            if (self.bidPeriod!.faFileIntent != nil) {
                self.faVacation(vDL: vDL)
            }
            else {
                switch (app.objNetworkType) {
                case .ground:
                    self.faVacation(vDL: vDL)
                    break
                case .paid:
                    self.faVacation(vDL: vDL)
                    break
                case .free:
                    self.disableVacationButton()
                    btnSwaptimizer.isEnabled = true
                    AlertService.showAlertForTopVC(title: "Network not available!!", message: "You are on the plane using the free company limited internet connection.\nYou cannot download vacation using the limited internet connection.Either pay for a full internet connection or wailt until you get on the ground and have a full internet connection")
                    break
                }
            }
        }
        
        else if vacationType == "FAVacationF" {
            if (self.bidPeriod!.faFileIntentF == nil) {
                self.eomForFAVacation(vDL: vDL)
            }
            else {
                switch (app.objNetworkType) {
                case .ground:
                    self.eomForFAVacation(vDL: vDL)
                    break
                case .paid:
                    self.eomForFAVacation(vDL: vDL)
                    break
                case .free:
                    self.disableVacationButton()
                    btnSwaptimizer.isEnabled = true
                    self.btnWbidMax.isEnabled = true
                    AlertService.showAlertForTopVC(title: "Network not available!!", message: "You are on the plane using the free company limited internet connection.\nYou cannot download vacation using the limited internet connection.Either pay for a full internet connection or wailt until you get on the ground and have a full internet connection")
                    break
                }
            }
        }
        
        else if vacationType == "FAVacationEomOnly" {
            if self.bidPeriod!.faFileIntentEomOnly == nil {
                self.executeEOMOnlyFA(vDL: vDL)
            }
            else {
                switch (app.objNetworkType) {
                case .ground:
                    self.executeEOMOnlyFA(vDL: vDL)
                    break
                case .paid:
                    self.executeEOMOnlyFA(vDL: vDL)
                    break
                case .free:
                    self.disableVacationButton()
                    btnSwaptimizer.isEnabled = true
                    AlertService.showAlertForTopVC(title: "Network not available!!", message: "You are on the plane using the free company limited internet connection.\nYou cannot download vacation using the limited internet connection.Either pay for a full internet connection or wailt until you get on the ground and have a full internet connection")
                    break
                }
            }
        }
    }
    
    func crewbid(vDL: CBVacationDownloader) {
        let app = UIApplication.shared.delegate as! AppDelegate
        if (app.connectedToInternet() == false && (self.bidPeriod!.cbFileIntent == nil)) {
            self.disableVacationButton()
            AlertService.showAlertForTopVC(title: "No Internet Connection", message: "An internet connection is required to download the vacation file. Please connect to the internet and try again.")
            btnSwaptimizer.isEnabled = true
            btnWbidMax.isEnabled = true
            return
        }
        self.view.showActivityIndicator(message: "Contacting SWAPtimizer...")
        vDL.downloadSwaptimizerVacationFilesWithHud() { suscess in
            if (suscess) {
                self.view.hideActivityIndicator()
                self.btnSwaptimizer.isEnabled = true
                self.btnWbidMax.isEnabled = true
                if (self.bidPeriod?.containsVacay?.boolValue == true && self.bidPeriod?.swaptimizerStatus?.intValue == CBSwaptimizerStatus.enabled.rawValue) {
//                    self.filtersTableController.objFilterTableView.reloadData()
                    self.setVacationBackgroundColor()
                    self.selectSwaptimizerVacationButton()
//                    self.scratchpadTableController.scratchPadTableView.reloadData()
                    NotificationCenter.default.post(name: Notification.Name("refreshLines"), object: self)
                    self.btnSwaptimizer.isEnabled = true
                    self.btnWbidMax.isEnabled = true
                    self.reprocessWorkBlock()
                    NotificationCenter.default.post(name: NSNotification.Name("ReloadSortTable"), object: self)
                    NotificationCenter.default.post(name: NSNotification.Name("ReloadFilterTable"), object: self)
                    NotificationCenter.default.post(name: Notification.Name("refreshLines"), object: self)
                    NotificationCenter.default.post(name: Notification.Name("CBLineValuesToDisplayDidChangeNotification"), object: self)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self.tableViewReloadWithHud() // tableViewReload
                    }

                }
                else if (self.bidPeriod!.vacayAlertDisplayed?.boolValue == false && self.bidPeriod!.containsVacay?.boolValue == true) {
                    AlertService.showAlertForTopVC(title: "Vacation detected!", message: "Vacation weeks are overlaid in yellow.")
                    self.bidPeriod?.vacayAlertDisplayed = NSNumber(value: true)
                }
                else {
                    self.bidPeriod?.userVacationWbidOrCrewBid = ""
                    self.disableVacationButton()
//                    self.filtersTableController.objFilterTableView.reloadData()
//                    self.sortsTableController.tableView.reloadData()
                }
                self.btnSwaptimizer.isUserInteractionEnabled = true
                self.btnSwaptimizer.alpha = 1
            }
        }
    }
    
    func setVacationBackgroundColor() {
        let userDefaults = UserDefaults.standard
        let type = self.bidPeriod!.vacationType
        
        if type == "CREWBID" || type == "CREWBIDF" || type == "FAVacation" || type == "FAVacationF" {
            self.swaptimizerVacationColor()
        } else if type == "WBID" || type == "WBIDF" {
            userDefaults.set("TripButton-rounded-right-green_iOS7", forKey: kCBTripButtonRoundedRightYellowImageNameKey)
            userDefaults.set("TripButton-rounded-left-green_iOS7", forKey: kCBTripButtonRoundedLeftYellowImageNameKey)
            userDefaults.set("TripButton-rounded-both-green_iOS7", forKey: kCBTripButtonRoundedBothYellowImageNameKey)
        } else {
            self.swaptimizerVacationColor()
        }
    }
    
    func swaptimizerVacationColor() {
        let userDefaults = UserDefaults.standard
        userDefaults.set("TripButton-rounded-right-yellow_iOS7", forKey: kCBTripButtonRoundedRightYellowImageNameKey)
        userDefaults.set("TripButton-rounded-left-yellow_iOS7", forKey: kCBTripButtonRoundedLeftYellowImageNameKey)
        userDefaults.set("TripButton-rounded-both-yellow_iOS7", forKey: kCBTripButtonRoundedBothYellowImageNameKey)
    }

    func selectSwaptimizerVacationButton() {
//        let funcName = #function
        self.bidPeriod?.currentDateTime = Date()
        self.bidPeriod?.isStateFileModifiedToSync = NSNumber(value: true)
        swaptimizerVacationImage =  "SwaptAlert"
        if (self.bidPeriod!.vacationType == "CREWBID" || self.bidPeriod!.vacationType == "CREWBIDF") {
            btnSwaptimizer.isSelected = true
            self.bidPeriod?.isSwaptimizerOn = NSNumber(value: true)
            btnSwaptimizer.backgroundColor = UIColor(red: 17.0/255.0, green: 143.0/255.0, blue: 226.0/255.0, alpha: 1)
            btnSwaptimizer.setTitleColor(.white, for: .selected)
            btnWbidMax.isSelected = false
            self.bidPeriod?.isWbidMaxOn = NSNumber(value: false)
            btnWbidMax.backgroundColor = .white
            btnWbidMax.setTitleColor(.black, for: .normal)
//            to set EOM status
            self.bidPeriod!.isEomOn = NSNumber(value: false)
            btnEOM.isSelected = false
            btnEOM.backgroundColor = .white
            btnEOM.setTitleColor(.black, for: .normal)
        }
        else {
            btnSwaptimizer.isSelected = false
            self.bidPeriod!.isSwaptimizerOn = NSNumber(value: false)
            btnSwaptimizer.isSelected = false
            btnSwaptimizer.backgroundColor = .white
            btnSwaptimizer.setTitleColor(.black, for: .normal)
            btnWbidMax.isSelected = false
            self.bidPeriod?.isWbidMaxOn = NSNumber(value: false)
            btnWbidMax.backgroundColor = .white
            btnWbidMax.setTitleColor(.black, for: .normal)
        }
    }
    
    func disableVacationButton() {
        self.bidPeriod?.vacationType = self.bidPeriod!.userVacationWbidOrCrewBid
//        let funcName = #function
        self.bidPeriod?.currentDateTime = Date()
        self.bidPeriod!.isStateFileModifiedToSync = NSNumber(value: true)
        if (self.bidPeriod?.vacationType == "WBID" || self.bidPeriod?.vacationType == "WBIDF") {
            swaptimizerVacationImage = "WBidmax-logo"
            btnWbidMax.isSelected = true
            self.bidPeriod!.isWbidMaxOn = NSNumber(value: true)
            btnWbidMax.backgroundColor = UIColor(red: 17.0/255.0, green: 143.0/255.0, blue: 226.0/255.0, alpha: 1)
            btnWbidMax.setTitleColor(.white, for: .selected)
            btnSwaptimizer.isSelected = false
            btnSwaptimizer.backgroundColor = .white
            btnSwaptimizer.setTitleColor(.black, for: .normal)
        }
        else if (self.bidPeriod!.vacationType == "CREWBID" || self.bidPeriod!.vacationType == "CREWBIDF") {
            swaptimizerVacationImage = "SwaptAlert"
            btnSwaptimizer.isSelected = true
            self.bidPeriod!.isSwaptimizerOn = NSNumber(value: true)
            btnSwaptimizer.backgroundColor =  UIColor(red: 17.0/255.0, green: 143.0/255.0, blue: 226.0/255.0, alpha: 1)
            btnSwaptimizer.setTitleColor(.white, for: .selected)
            btnWbidMax.isSelected = false
            self.bidPeriod!.isWbidMaxOn = NSNumber(value: false)
            btnWbidMax.backgroundColor = .white
            btnWbidMax.setTitleColor(.black, for: .normal)
        }
        else if (self.bidPeriod!.vacationType == "FAVaction" || self.bidPeriod!.vacationType == "FAVacationF") {
            if (self.bidPeriod!.containsVacay?.boolValue == true) {
                btnWbidMax.isSelected = true
                self.bidPeriod!.isFAVacationOn = NSNumber(value: true)
                btnWbidMax.backgroundColor =  UIColor(red: 17.0/255.0, green: 143.0/255.0, blue: 226.0/255.0, alpha: 1)
                btnWbidMax.setTitleColor(.white, for: .selected)
            }
        }
        else {
            btnSwaptimizer.isSelected = false
            self.bidPeriod!.isSwaptimizerOn = NSNumber(value: false)
            btnSwaptimizer.backgroundColor = .white
            btnSwaptimizer.setTitleColor(.black, for: .normal)
            btnWbidMax.isSelected = false
            btnWbidMax.backgroundColor = .white
            btnWbidMax.setTitleColor(.black, for: .normal)
            self.bidPeriod!.isWbidMaxOn = NSNumber(value: false)
            
            if self.bidPeriod!.isFABid() == true {
                btnWbidMax.isSelected = false
                btnWbidMax.backgroundColor = .white
                btnWbidMax.setTitleColor(.black, for: .normal)
                self.bidPeriod!.isFAVacationOn = NSNumber(value: false)
            }
        }
        self.enableOrDisableEOMButton()
        if (!btnSwaptimizer.isSelected && btnWbidMax.isSelected) {
            self.bidPeriod?.vacationType = ""
            try? context!.save()
            print("type saved")
        }
        if ((self.bidPeriod!.cbFileIntent?.count ?? 0 > 1) || (self.bidPeriod!.wbFileIntent?.count ?? 0 > 1)) {
            self.bidPeriod?.isSwaptimizerOn = CBSwaptimizerStatus.enabled.rawValue as NSNumber
            self.bidPeriod?.userVacationWbidOrCrewBid = self.bidPeriod?.vacationType
            try? context!.save()
            print("type saved")
        }
        if (self.bidPeriod?.faFileIntent?.count ?? 0 > 1) {
            self.bidPeriod?.faVacationStatus = BIFaVacationStatus.enabled.rawValue as NSNumber
            try? context!.save()
            print("type saved")
        }
    }
    
    func reprocessWorkBlock() {
        self.view.showActivityIndicator(message: "Processing...")
        let isOn = UserDefaults.standard.bool(forKey: kCBIncludeDroppedTripsInProcessingKey)
        let bidReader = BIBidInfoReader()
        bidReader.bidPeriod = self.bidPeriod
        bidReader.calendarData = self.calendarData
        if isOn {
            bidReader.calculateWorkBlockDetails()
        }
        else {
            bidReader.calculateWorkBlockDetailsWithVacation()
        }
        
//        fetching filter
        let fetchRequest: NSFetchRequest<BIFilterRule> = BIFilterRule.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "category", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "category == 33")
        let filterRulesController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context!, sectionNameKeyPath: nil, cacheName: nil)
//        fetching sort
        let fetchRequestSort: NSFetchRequest<BILineSort> = BILineSort.fetchRequest()
        fetchRequestSort.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
        fetchRequestSort.predicate = NSPredicate(format: "category == 9")
        let sortsFetchController = NSFetchedResultsController(fetchRequest: fetchRequestSort, managedObjectContext: context!, sectionNameKeyPath: nil, cacheName: nil)
        do {
            try filterRulesController.performFetch()
            try sortsFetchController.performFetch()
            
            if (filterRulesController.fetchedObjects?.count ?? 0 > 0) {
//                MARK: needed to add RecalculateCommutabilityFilter
                self.view.hideActivityIndicator()
            }
            else if (sortsFetchController.fetchedObjects?.count ?? 0 > 0) {
//                MARK: needed to add RecalculateCommutabilitySort
                self.view.hideActivityIndicator()
            }
            else {
                DispatchQueue.main.async {
                    self.view.hideActivityIndicator()
                    if (UserDefaults.standard.bool(forKey: "isStateSync")) {
                        UserDefaults.standard.set(false, forKey: "isStateSync")
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
                    }
                }
            }
        }
        catch {
            print("failed to perform fetch \(error.localizedDescription)")
        }
    }
    
    func tableViewReloadWithHud() {
        let condition1 = !btnEOM.isHidden && !btnSwaptimizer.isSelected && !btnWbidMax.isSelected
        let condition2 = !btnEOM.isHidden
        let condition3 = !btnSwaptimizer.isSelected && !btnWbidMax.isSelected
        let condition4 = !self.manageVacationsEnabled
        DispatchQueue.main.async {
            if (condition1) {
                if (condition2) {
                    if (condition4) {
                        self.bidPeriod?.swaptimizerStatus = CBSwaptimizerStatus.statusError.rawValue as NSNumber
                        DispatchQueue.main.async {
                            self.reprocessAfterChangedIncludeDroppedTrips() { finished in
                                if (finished) {
                                    //Reset day displaytype to normal
                                    self.resetDisplayTypesOfAllDays()
                                    self.view.hideActivityIndicator()
                                    if (UserDefaults.standard.bool(forKey: KCBIsSyncEnabled)) {
                                        NotificationCenter.default.post(name: Notification.Name("RefreshBidListLineCountFilter"), object: self)
                                        NotificationCenter.default.post(name: Notification.Name(kCBPresetSyncReload), object: self)
                                    }
                                    if self.isVacationsRemoved {
                                        self.resetAllVacationDetails()
                                    }
                                    if (self.bidPeriod?.isReportReleaseFilterApplied?.boolValue == true) {
                                        NotificationCenter.default.post(name: Notification.Name("ReloadFilterTable"), object: self)
                                    }
                                }
                            }
                        }
                    }
                    return
                }
                // Observe line values to display change.
                DispatchQueue.main.async {
//                    self.scratchpadTableController.scratchPadTableView.reloadData()
                    NotificationCenter.default.post(name: Notification.Name("refreshLines"), object: self)
                }
                
                self.reprocessAfterChangedIncludeDroppedTrips() { finished in
                    if (finished) {
                        if (UserDefaults.standard.bool(forKey: KCBIsSyncEnabled)) {
                            NotificationCenter.default.post(name: Notification.Name("RefreshBidListLineCountFilter"), object: self)
                            NotificationCenter.default.post(name: Notification.Name(kCBPresetSyncReload), object: self)
                        }
                        if self.isVacationsRemoved {
                            self.resetAllVacationDetails()
                        }
                    }
                }
                DispatchQueue.main.async {
                    self.view.hideActivityIndicator()
                    if (self.seniorityShowed == false && self.bidPeriod?.isHistoric?.boolValue == false) {
                        self.perform(#selector(self.seniorityAlert), with: nil, afterDelay: 0.5)
                    }
                }
                return
            }
            
            if (condition3) {
                if (condition4) {
                    self.bidPeriod!.swaptimizerStatus = CBSwaptimizerStatus.statusError.rawValue as NSNumber
                    DispatchQueue.main.async {
                        self.view.hideActivityIndicator()
                        if (self.seniorityShowed == false && self.bidPeriod?.isHistoric?.boolValue == false) {
                            self.perform(#selector(self.seniorityAlert), with: nil, afterDelay: 0.5)
                        }
                    }
                }
                return
            }
            // Observe line values to display change.
            DispatchQueue.main.async {
//                self.scratchpadTableController.scratchPadTableView.reloadData()
                NotificationCenter.default.post(name: Notification.Name("refreshLines"), object: self)
            }
            self.reprocessAfterChangedIncludeDroppedTrips() { finished in
                if (finished) {
                    if (UserDefaults.standard.bool(forKey: KCBIsSyncEnabled)) {
                        NotificationCenter.default.post(name: Notification.Name("RefreshBidListLineCountFilter"), object: self)
                        NotificationCenter.default.post(name: Notification.Name(kCBPresetSyncReload), object: self)
                    }
                    if self.isVacationsRemoved {
                        self.resetAllVacationDetails()
                    }
                    let fetchRequest: NSFetchRequest<BILineSort> = BILineSort.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "category == 4")
                    do {
                        let arrayCommutingSort = try self.context!.fetch(fetchRequest)
                        if arrayCommutingSort.count > 0 {
                            let lineSort = arrayCommutingSort[0]
                            self.commutingSortCell = CBCommutingSortCell()
                            self.commutingSortCell.bidPeriod = self.bidPeriod
                            self.commutingSortCell.outsideFlag = "1"
                            lineSort.ascending = NSNumber(value: false)
                            self.commutingSortCell.lineSort = lineSort
                            self.commutingSortCell.calculateSortAfterVacationLoading()
    //                        MARK: needed to be addded regarding commmuting sort and CBCommutingSortCell
                        }
                    }
                    catch {
                        print("failed to fetch line sort \(error.localizedDescription)")
                    }
                    self.perform(#selector(self.showAlertforVacationLoading), with: nil, afterDelay: 0.5)
                }
            }
            
            DispatchQueue.main.async {
                self.view.hideActivityIndicator()
            }
        }
    }
    
    func reprocessAfterChangedIncludeDroppedTrips(completion: @escaping (Bool) -> Void) {
        self.view.showActivityIndicator(message: "Reprocessing lines...")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Three steps:
            // 1: reset the trip highlight count
            // 2: Change the dropForFiltersSorts value to the current user setting and reprocess the lines
            // 3: Rehighlight the trips based on the new dropForFiltersSorts setting
            // Reset trip highlight count
            BITrip.resetTripHighlightCount(in: self.context!)
            // Init the bidInfoReader for line reprocessing (if needed)
            self.round = self.bidPeriod!.round!
            self.year = self.bidPeriod!.year!
            self.month = self.bidPeriod!.month!
            self.poistion = BICrewPositionType(rawValue: self.bidPeriod!.positionType!.intValue)
            self.employeeNumber = self.bidPeriod!.swaptimizerIdentifier!.stringValue
            let bidInfoReader = BIBidInfoReader()
            bidInfoReader.bidPeriod = self.bidPeriod
            bidInfoReader.calendarData = self.calendarData
            bidInfoReader.includeDroppedTrips = UserDefaults.standard.bool(forKey: kCBIncludeDroppedTripsInProcessingKey)
            bidInfoReader.intlCities = UserDefaults.standard.object(forKey: kCBInternationalCitiesDict) as! [String : Any]
            // Grab all non-blank sorted lines
            let lines = self.bidPeriod?.lines?.allObjects as? [AnyObject] ?? []
            var sortedLines = (lines as NSArray).sortedArray(using: [
                NSSortDescriptor(key: "number", ascending: true)
            ])
            let notBlankPredicate = NSPredicate(format: "type != %d", BILineType.BlankLine.rawValue)
            sortedLines = (sortedLines as NSArray).filtered(using: notBlankPredicate)
            for line in sortedLines as! [BILine] {
                bidInfoReader.initDerivedPropertiesForLine(line: line, isReprocessing: true)
            }
            do {
                try self.context!.save()
                print("saved")
            }
            catch {
                print("unable to save: \(error.localizedDescription)")
            }
            DispatchQueue.main.async {
                self.view.hideActivityIndicator()
            }
            
//            filter fetch
            let filterFetch: NSFetchRequest<BIFilterRule> = BIFilterRule.fetchRequest()
            filterFetch.sortDescriptors = [NSSortDescriptor(key: "category", ascending: true), NSSortDescriptor(key: "type", ascending: true)]
            do {
                let filterRules = try self.context!.fetch(filterFetch)
                for rule in filterRules {
                    if (rule.ruleHighlightsTrips()) {
                        rule.highlightTrips()
                    }
//                    Report - Release
                    if (rule.category?.intValue == 37) {
                        self.bidPeriod?.isReportReleaseFilterApplied = NSNumber(value: true)
                        self.view.hideActivityIndicator()
                        if (self.seniorityShowed == false && self.bidPeriod?.isHistoric?.boolValue == false) {
                            self.perform(#selector(self.seniorityAlert), with: nil, afterDelay: 0.5)
                            
                        }
                    }
                }
            }
            catch {
                print("failed to fetch filter rule \(error.localizedDescription)")
            }
//            sort Fetch
            let sortFetch: NSFetchRequest<BILineSort> = BILineSort.fetchRequest()
            if (self.bidPeriod!.isBidListSortOn?.boolValue == true) {
                sortFetch.predicate =  NSPredicate(format: "isBidListSort == %@", NSNumber(value: true))
            }
            else {
                sortFetch.predicate =  NSPredicate(format: "isBidListSort == %@", NSNumber(value: false))
            }
            sortFetch.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
            do {
                let lineSorts = try self.context!.fetch(sortFetch)
                // Rehighlight for all the sorts
                for sort in lineSorts as[BILineSort] {
                    if (BILineSortCategory.BICitiesLineSortCategory.rawValue == sort.category!.intValue) {
                        // Redo the lineSort key paths (this isn't working for an unknown reason)
                        if (BICityLineSortType.BICitiesLineSortTypeEastCoast.rawValue == sort.type?.intValue || BICityLineSortType.BICitiesLineSortTypeWestCoast.rawValue == sort.type?.intValue || BICityLineSortType.BICitiesLineSortTypeNonConus.rawValue == sort.type?.intValue || BICityLineSortType.BICitiesLineSortTypeIntl.rawValue == sort.type?.intValue || BICityLineSortType.BICitiesLineSortTypeAll.rawValue == sort.type?.intValue || BICityLineSortType.BICitiesLineSortTypeHawaii.rawValue == sort.type?.intValue) {
                            sort.keyPath = sort.bidPeriod?.lineSortKeyForCityLineSort(cityLineSort: sort, city: "")
                        }
                        else if (sort.city != nil && sort.city != "") {
                            sort.lineSortKeyMap!.sortKey = nil
                            sort.lineSortKeyMap!.lineKey = nil
                            self.context!.delete(sort.lineSortKeyMap!)
                            sort.city = sort.city
                        }
                    }
                    else if (BILineSortCategory.BICommutingLineSortCategory.rawValue == sort.category?.intValue) {
//                        sort.keyPath = sort.bidPeriod.lineSortKeyForCommute 6422
//                        MARK: needed to be addded
                    }
                    else if (BILineSortCategory.BIDaysOffLineSortCategory.rawValue == sort.category?.intValue) {
                        sort.keyPath = sort.bidPeriod?.lineSortKeyForDaysOff(lineSort: sort)
                    }
                    else if (BILineSortCategory.BIDaysWorkLineSortCategory.rawValue == sort.category?.intValue) {
                        sort.keyPath = sort.bidPeriod?.lineSortKeyForDaysWork(lineSort: sort)
                    }
                    else if (BILineSortCategory.BIDaysTripStartSortCategory.rawValue == sort.category?.intValue) {
                        sort.keyPath = sort.bidPeriod?.lineSortKeyForTripStartDays(lineSort: sort)
                    }
                    if (sort.sortHighlightsTrips()) {
                        sort.highlightTrips()
                    }
                }
            }
            catch {
                print("failed to fetch sort rule \(error.localizedDescription)")
            }
            DispatchQueue.main.async {
                self.view.hideActivityIndicator()
                self.reprocessWorkBlock()
                let fetchRequest: NSFetchRequest<BILineSort> = BILineSort.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "category == 4")
                do {
                    let arrayCommutingSort = try self.context!.fetch(fetchRequest)
                    if arrayCommutingSort.count > 0 {
                        let lineSort = arrayCommutingSort[0]
                        self.commutingSortCell = CBCommutingSortCell()
                        self.commutingSortCell.bidPeriod = self.bidPeriod
                        self.commutingSortCell.outsideFlag = "1"
                        lineSort.ascending = NSNumber(value: false)
                        self.commutingSortCell.lineSort = lineSort
                        self.commutingSortCell.calculateSortAfterVacationLoading()
//                        MARK: needed to be addded regarding commmuting sort and CBCommutingSortCell
                        if (self.seniorityShowed == false && self.bidPeriod?.isHistoric?.boolValue == false) {
                            self.perform(#selector(self.seniorityAlert), with: nil, afterDelay: 0.5)
                        }
                    }
                }
                catch {
                    print("failed to fetch line sort \(error.localizedDescription)")
                }
                
            }
            completion(true)
        }
    }
    
    @objc func seniorityAlert() {
//    MARK: needed to add seniorityAlert
    }
    
    func resetDisplayTypesOfAllDays() {
        let fetchRequest: NSFetchRequest<BITrip> = BITrip.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "number", ascending: true)]
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context!, sectionNameKeyPath: nil, cacheName: nil)
        controller.delegate = self
        do {
            try controller.performFetch()
            for trip in controller.fetchedObjects ?? [] {
                trip.vacationOverlapType = 0
                trip.dropForFiltersSorts = NSNumber(value: false)
                for case let day as BIDay in trip.days!  {
                    day.displayType = BIDayDisplayType.normal.rawValue as NSNumber
                    day.redEyeDayDisplayDayType = BIDayDisplayType.fullPay.rawValue as NSNumber
                }
            }
        }
        catch {
            print("Fetching error in BITrip: \(error.localizedDescription)")
        }
        //bug fix in vacation removal - issue was rig was not properly calciulated when user removes vacation
        let bidinfoReader = BIBidInfoReader()
        bidinfoReader.bidPeriod = self.bidPeriod
        bidinfoReader.calendarData = self.calendarData
        bidinfoReader.includeDroppedTrips = UserDefaults.standard.bool(forKey: kCBIncludeDroppedTripsInProcessingKey)
        bidinfoReader.intlCities = UserDefaults.standard.object(forKey: kCBInternationalCitiesDict) as! [String : Any]
        for case let line as BILine in self.bidPeriod!.lines!.allObjects {
            bidinfoReader.initDerivedPropertiesForLine(line: line, isReprocessing: true)
        }
    }
    
    func resetAllVacationDetails() {
//        let funcName = #function
        isVacationsRemoved = false
        self.bidPeriod!.isSwaptimizerOn = NSNumber(value: false)
        self.bidPeriod!.isWbidMaxOn = NSNumber(value: false)
        self.bidPeriod!.isEomOn = NSNumber(value: false)
        self.bidPeriod!.vacationType = ""
        btnWbidMax.isSelected = false
        btnSwaptimizer.isSelected = false
        btnEOM.isSelected = false
        self.bidPeriod!.userVacationWbidOrCrewBid = ""
        btnSwaptimizer.backgroundColor = UIColor.white
        btnSwaptimizer.setTitleColor(.black, for: .normal)
        btnWbidMax.backgroundColor = UIColor.white
        btnWbidMax.setTitleColor(.black, for: .normal)
        btnEOM.backgroundColor = UIColor.white
        btnEOM.setTitleColor(.black, for: .normal)
        if (self.bidPeriod!.isFABid() == true) {
            btnWbidMax.isSelected = false
            self.bidPeriod!.isFAVacationOn = NSNumber(value: false)
            btnWbidMax.backgroundColor = UIColor.white
            btnWbidMax.setTitleColor(.black, for: .normal)
        }
    }
    
    @objc func showAlertforVacationLoading() {
        let vacationType = self.bidPeriod!.userVacationWbidOrCrewBid
        if (vacationType == "CREWBID" || vacationType == "CREWBIDF") {
            if ((self.bidPeriod?.crewIdentifier?.intValue != self.bidPeriod!.credentialEmployeenumber!.intValue) && alertShouldDisplay) {
                self.enableOrDisableEOMButton()
                DispatchQueue.main.async {
                    AlertService.showAlertForTopVC(title: "SWAPtimizer loaded, but...", message: "There is a mismatch between the user for whom the bid package was downloaded (\(self.bidPeriod!.crewIdentifier?.stringValue ?? "")) and the user for whom the SWAPtimizer file is valid (\(GlobalBidInfo.shared.userid)).", actions: [(
                        title: "OK",
                        style: .default,
                        handler: { _ in
                            if self.bidPeriod!.isReportReleaseFilterApplied?.boolValue == true {
                                NotificationCenter.default.post(name: NSNotification.Name("ReloadFilterTable"), object: self)
                            }
                        }
                        
                    )])
                }
            }
            else {
                DispatchQueue.main.async {
                    if self.alertShouldDisplay {
                        AlertService.showAlertForTopVC(title: "SWAPtimizer loaded!", message: "You now have access to over 20 Sorts and Filters based on SWAPtimizer's vacation prediction algorithms. SWAPtimizer-specific Sorts and Filters display the SWAPtimizer logo. SWAPtimizer line values are displayed in blue.", actions: [(
                            title: "OK",
                            style: .default,
                            handler: { _ in
                                if self.bidPeriod!.isReportReleaseFilterApplied?.boolValue == true {
                                    NotificationCenter.default.post(name: NSNotification.Name("ReloadFilterTable"), object: self)
                                }
                            }
                            
                        )])
                    }
                }
            }
            self.bidPeriod!.vacayAlertDisplayed = NSNumber(value: true)
        }
        else if (vacationType == "WBID" || vacationType == "WBIDF") {
            if ((self.bidPeriod?.crewIdentifier?.intValue != self.bidPeriod!.credentialEmployeenumber!.intValue) && alertShouldDisplay) {
                DispatchQueue.main.async {
                    AlertService.showAlertForTopVC(title: "WBidmax loaded, but...", message: "There is a mismatch between the user for whom the bid package was downloaded (\(self.bidPeriod!.crewIdentifier?.stringValue ?? "")) and the user for whom the SWAPtimizer file is valid (\(GlobalBidInfo.shared.userid)).", actions: [(
                        title: "OK",
                        style: .default,
                        handler: { _ in
                            if self.bidPeriod!.isReportReleaseFilterApplied?.boolValue == true {
                                NotificationCenter.default.post(name: NSNotification.Name("ReloadFilterTable"), object: self)
                                try? self.context!.save()
                            }
                        }
                        
                    )])
                }
            }
            else {
                DispatchQueue.main.async {
                    if self.alertShouldDisplay {
                        AlertService.showAlertForTopVC(title: "SWAPtimizer loaded!", message: "You now have access to over 20 Sorts and Filters based on SWAPtimizer's vacation prediction algorithms. SWAPtimizer-specific Sorts and Filters display the SWAPtimizer logo. SWAPtimizer line values are displayed in blue.", actions: [(
                            title: "OK",
                            style: .default,
                            handler: { _ in
                                if self.bidPeriod!.isReportReleaseFilterApplied?.boolValue == true {
                                    NotificationCenter.default.post(name: NSNotification.Name("ReloadFilterTable"), object: self)
                                    try? self.context!.save()
                                }
                            }
                            
                        )])
                    }
                }
            }
            self.bidPeriod!.vacayAlertDisplayed = NSNumber(value: true)
        }
        else if ((vacationType == "FAVacation" || vacationType == "FAVacationF")) && alertShouldDisplay {
            if (self.bidPeriod?.crewIdentifier?.intValue != self.bidPeriod!.credentialEmployeenumber!.intValue) {
                DispatchQueue.main.async {
                    AlertService.showAlertForTopVC(title: "Vacation loaded, but...", message: "There is a mismatch between the user for whom the bid package was downloaded (\(self.bidPeriod!.crewIdentifier?.stringValue ?? "")) and the user for whom the SWAPtimizer file is valid (\(GlobalBidInfo.shared.userid)).", actions: [(
                        title: "OK",
                        style: .default,
                        handler: { _ in
                            if self.bidPeriod!.isReportReleaseFilterApplied?.boolValue == true {
                                NotificationCenter.default.post(name: NSNotification.Name("ReloadFilterTable"), object: self)
                            }
                        }
                        
                    )])
                }
            }
            else {
                DispatchQueue.main.async {
                    if self.alertShouldDisplay {
                        AlertService.showAlertForTopVC(title: "SWAPtimizer loaded!", message: "You now have access to over 20 Sorts and Filters based on SWAPtimizer's vacation prediction algorithms. SWAPtimizer-specific Sorts and Filters display the SWAPtimizer logo. SWAPtimizer line values are displayed in blue.", actions: [(
                            title: "OK",
                            style: .default,
                            handler: { _ in
                                if self.bidPeriod!.isReportReleaseFilterApplied?.boolValue == true {
                                    NotificationCenter.default.post(name: NSNotification.Name("ReloadFilterTable"), object: self)
                                }
                            }
                            
                        )])
                    }
                }
            }
            self.bidPeriod!.vacayAlertDisplayed = NSNumber(value: true)
        }
    }
    
    func eomCrewBid(vDL: CBVacationDownloader) {
        self.executeEOMCrewBid(vDL: vDL)
    }
    
    func executeEOMCrewBid(vDL: CBVacationDownloader) {
        if ((!app.connectedToInternet() == true) && (self.bidPeriod!.cbFileIntentF == nil)) {
            self.disableVacationButton()
            AlertService.showAlertForTopVC(title: "No Internet Connection", message: "An internet connection is required to download the vacation file. Please connect to the internet and try again.")
            btnSwaptimizer.isEnabled = true
            btnWbidMax.isEnabled = true
            return
        }
        self.view.showActivityIndicator(color: UIColor.blue, message: "Getting EOM Vacation...")
        DispatchQueue.main.async {
            vDL.downloadSwaptimizerEOMVacationFilesWithHud() { finished in
                if finished {
                    self.view.hideActivityIndicator()
                    self.btnSwaptimizer.isEnabled = true
                    self.btnWbidMax.isEnabled = true
                    if (self.bidPeriod!.containsVacay?.boolValue == true && self.bidPeriod?.swaptimizerStatus?.intValue == CBSwaptimizerStatus.enabled.rawValue) {
//                        self.filtersTableController.objFilterTableView.reloadData()
                        self.setVacationBackgroundColor()
                        self.selectSwaptimizerVacationButton()
                        self.enableOrDisableEOMButton()
//                        self.scratchpadTableController.scratchPadTableView.reloadData()
                        NotificationCenter.default.post(name: Notification.Name("refreshLines"), object: self)
                        self.btnSwaptimizer.isEnabled = true
                        self.btnWbidMax.isEnabled = true
                        self.reprocessWorkBlock()
                        NotificationCenter.default.post(name: NSNotification.Name("ReloadSortTable"), object: self)
                        NotificationCenter.default.post(name: NSNotification.Name("ReloadFilterTable"), object: self)
                        NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
                        NotificationCenter.default.post(name: NSNotification.Name("CBLineValuesToDisplayDidChangeNotification"), object: self)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            self.tableViewReloadWithHud()
                        }
                    }
                    else if (!(self.bidPeriod!.vacayAlertDisplayed?.boolValue == true) && self.bidPeriod!.containsVacay?.boolValue == true) {
                        AlertService.showAlertForTopVC(title: "Vacation detected!", message: "Vacation weeks are overlaid in yellow.")
                        self.bidPeriod!.vacayAlertDisplayed = NSNumber(value: true)
                    }
                    else {
                        self.bidPeriod!.userVacationWbidOrCrewBid = self.bidPeriod?.vacationType
                        self.disableVacationButton()
//                        self.sortsTableController.tableView.reloadData()
//                        self.filtersTableController.objFilterTableView.reloadData()
                    }
                    self.btnSwaptimizer.isUserInteractionEnabled = true
                    self.btnSwaptimizer.alpha = 1
                }
            }
        }
    }
    
    func wbid(vDL: CBVacationDownloader) {
        if (app.connectedToInternet() == false && self.bidPeriod!.wbFileIntent == nil) {
            self.bidPeriod!.userVacationWbidOrCrewBid = ""
            self.disableVacationButton()
            AlertService.showAlertForTopVC(title: "No Internet Connection", message: "An internet connection is required to download the vacation file. Please connect to the internet and try again.")
            btnSwaptimizer.isEnabled = true
            btnWbidMax.isEnabled = true
            return
        }
//        if app.isUserInformationAvailable() == false {
//            self.bidPeriod!.userVacationWbidOrCrewBid = ""
//            self.disableVacationButton()
//            AlertService.showAlertForTopVC(title: "CrewBid", message: "User information not available,you have to create user account to access WBidMax vacation. Please create user account by clicking on new bid period (+) from home screen.")
//            btnSwaptimizer.isEnabled = true
//            btnWbidMax.isEnabled = true
//            return
//        }
        
        self.view.showActivityIndicator(message: "Processing WbidMax Vacation...")
        DispatchQueue.main.async {
            vDL.downloadWbidVacationFilesWithHud() { finished in
                if (finished) {
                    self.view.hideActivityIndicator()
                    self.btnSwaptimizer.isEnabled = true
                    self.btnWbidMax.isEnabled = true
                    if (self.bidPeriod!.containsVacay?.boolValue == true && self.bidPeriod!.swaptimizerStatus?.intValue == CBSwaptimizerStatus.enabled.rawValue) {
                        self.selectWBidVacationButton()
                        self.setVacationBackgroundColor()
                        self.enableOrDisableEOMButton()
                        self.reprocessWorkBlock()
                        NotificationCenter.default.post(name: NSNotification.Name("ReloadSortTable"), object: self)
                        NotificationCenter.default.post(name: NSNotification.Name("ReloadFilterTable"), object: self)
                        NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
                        NotificationCenter.default.post(name: NSNotification.Name("CBLineValuesToDisplayDidChangeNotification"), object: self)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            self.tableViewReloadWithHud()
                        }
                    }
                    else if (self.bidPeriod!.vacayAlertDisplayed?.boolValue == false && self.bidPeriod!.containsVacay?.boolValue == true) {
                        DispatchQueue.main.async {
                            AlertService.showAlertForTopVC(title: "Vacation detected!", message: "Vacation weeks are overlaid in green.")
                        }
                        self.bidPeriod?.vacayAlertDisplayed = NSNumber(value: true)
                    }
                    else {
                        if self.bidPeriod!.containsVacay?.boolValue == false {
                            self.disableVacationButton()
                        }
                        self.view.hideActivityIndicator()
                        self.btnSwaptimizer.isEnabled = true
                        self.btnWbidMax.isEnabled = true
                    }
                    self.btnWbidMax.isUserInteractionEnabled = true
                    self.btnWbidMax.alpha = 1.0
                }
//                self.sortsTableController.tableView.reloadData()
//                self.filtersTableController.objFilterTableView.reloadData()
                else {
                    NotificationCenter.default.post(name: Notification.Name("refreshLines"), object: self)
                    self.bidPeriod!.userVacationWbidOrCrewBid = ""
//                    self.disableVacationButton()
                    self.view.hideActivityIndicator()
                    self.btnSwaptimizer.isEnabled = true
                    self.btnWbidMax.isEnabled = true
                }
            }
        }
    }
    
    func selectWBidVacationButton() {
//        let funcName = #function
        self.bidPeriod!.currentDateTime = Date()
        self.bidPeriod!.isStateFileModifiedToSync = NSNumber(value: true)
        if self.bidPeriod!.isFABid() == false {
            swaptimizerVacationImage = "WBidmax-logo"
        }
        if (self.bidPeriod!.vacationType == "WBID" || self.bidPeriod!.vacationType == "WBIDF") {
            btnWbidMax.isSelected = true
            self.bidPeriod!.isWbidMaxOn = NSNumber(value: true)
            btnWbidMax.backgroundColor = UIColor(red: 17.0/255.0, green: 143.0/255.0, blue: 226.0/255.0, alpha: 1.0)
            btnWbidMax.setTitleColor(.white, for: .selected)
            btnSwaptimizer.isSelected = false
            self.bidPeriod!.isSwaptimizerOn = NSNumber(value: false)
            btnSwaptimizer.backgroundColor = .white
            btnSwaptimizer.setTitleColor(.black, for: .normal)
        }
        else if (self.bidPeriod!.vacationType == "FAVacation" || self.bidPeriod!.vacationType == "FAVacationF") {
            if self.bidPeriod!.containsVacay?.boolValue == true {
                btnWbidMax.isSelected = true
                self.bidPeriod!.isFAVacationOn = NSNumber(value: true)
                btnWbidMax.backgroundColor = UIColor(red: 17.0/255.0, green: 143.0/255.0, blue: 226.0/255.0, alpha: 1.0)
                btnWbidMax.setTitleColor(.white, for: .selected)
            }
        }
        else {
            btnSwaptimizer.isSelected = false
            self.bidPeriod!.isSwaptimizerOn = NSNumber(value: false)
            btnSwaptimizer.backgroundColor = .white
            btnSwaptimizer.setTitleColor(.black, for: .normal)
            btnWbidMax.isSelected = false
            self.bidPeriod!.isWbidMaxOn = NSNumber(value: false)
            btnWbidMax.backgroundColor = .white
            btnWbidMax.setTitleColor(.black, for: .normal)
        }
    }
    
    func eomWbid(vDL: CBVacationDownloader) {
        //        MARK: needed to add this in subscription condition 4433
//        if (nosubcription) {
//            self.disableVacationButton()
//            btnSwaptimizer.isEnabled = true
//            btnWbidMax.isEnabled = true
//            self.bidPeriod!.userVacationWbidOrCrewBid = ""
//            AlertService.showAlertForTopVC(title: "No MAX Subscription!", message: "The EOM feature is only available with a MAX subscription. The best place to get a MAX subscription is by going to www.crewbid.com and logging in. Then go to My Account and touch Subscribe Here", actions: [(
//                title: "OK",
//                style: .default,
//                handler: { _ in
//                    if self.btnSwaptimizer.isSelected {
//                        self.wbidMaxErrorMessageEOMSpecialcase()
//                    }
//                    else {
//                        self.wbidMaxErrorMessageEOM(isAuto: true)
//                    }
//                }
//            )])
//        }
        self.executeEOmWBid(vDL: vDL)
    }
    
    func wbidMaxErrorMessageEOMSpecialcase() {
        return
    }
    
    func wbidMaxErrorMessageEOM(isAuto: Bool) {
        return
    }
    
    func executeEOmWBid(vDL: CBVacationDownloader) {
//        if app.isUserInformationAvailable() == false {
//            self.disableVacationButton()
//            AlertService.showAlertForTopVC(title: "CrewBid", message: "An internet connection is required to download the vacation file. Please connect to the internet and try again.")
//            btnSwaptimizer.isEnabled = true
//            btnWbidMax.isEnabled = true
//            return
//        }
        self.view.showActivityIndicator(message: "Getting EOM Vacation...")
        DispatchQueue.main.async {
            vDL.downloadWbidEOMVacationFilesWithHud() { finished in
                if finished {
                    self.btnSwaptimizer.isEnabled = true
                    self.btnWbidMax.isEnabled = true
                    if (self.bidPeriod!.containsVacay?.boolValue == true && self.bidPeriod!.swaptimizerStatus?.intValue == CBSwaptimizerStatus.enabled.rawValue) {
                        self.selectWBidVacationButton()
                        self.setVacationBackgroundColor()
                        self.reprocessWorkBlock()
                        self.showEOMAlert()
                        NotificationCenter.default.post(name: NSNotification.Name("ReloadSortTable"), object: self)
                        NotificationCenter.default.post(name: NSNotification.Name("ReloadFilterTable"), object: self)
                        NotificationCenter.default.post(name: Notification.Name("refreshLines"), object: self)
                        NotificationCenter.default.post(name: Notification.Name("CBLineValuesToDisplayDidChangeNotification"), object: self)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            self.tableViewReloadWithHud() // tableViewReload
                        }
                    }
                    else if (self.bidPeriod!.containsVacay?.boolValue == true && self.bidPeriod!.vacayAlertDisplayed?.boolValue == false) {
                        AlertService.showAlertForTopVC(title: "Vacation detected!", message: "Vacation weeks are overlaid in green.")
                        self.bidPeriod!.vacayAlertDisplayed = NSNumber(value: true)
                    }
                    else {
                        self.disableVacationButton()
                    }
                    self.view.hideActivityIndicator()
                    self.btnSwaptimizer.isEnabled = true
                    self.btnWbidMax.isEnabled = true
                }
                else {
                    //                self.sortsTableController.tableView.reloadData()
                    //                self.filtersTableController.objFilterTableView.reloadData()
                    if self.btnWbidMax.isSelected && self.bidPeriod?.isWBidmaxOverlapWithEom() == true {
                        self.removeCurrentVacation()
                    }
                    self.bidPeriod!.userVacationWbidOrCrewBid = ""
                    self.disableVacationButton()
                    self.view.hideActivityIndicator()
                    self.btnSwaptimizer.isEnabled = true
                    self.btnWbidMax.isEnabled = true
                    NotificationCenter.default.post(name: Notification.Name("refreshLines"), object: self)
                }
            }
        }
    }
    func showEOMAlert() {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM"
//      added an extra condition to check vacation startdate is equal eom vacation start date
        let vacations = self.bidPeriod!.vacations!.allObjects
        var firstVacation = vacations.first as! BIVacation
        if vacations.count > 0 {
            let vacationmonthForCheck = firstVacation.startDate!
            let month = Calendar.current.component(.month, from: vacationmonthForCheck)
            if self.bidPeriod!.month!.intValue == month {
                firstVacation = vacations.last as! BIVacation
            }
        }
        let startDate = firstVacation.startDate!
        let endDate = firstVacation.endDate!
        var vacationStartDateDisp = formatter.string(from: startDate)
        var dayComponent = DateComponents()
        dayComponent.day = -1 // because the vacation.endDate is 1 day ahead

        let calendar = Calendar.current
        if var exactVacEndDate = calendar.date(byAdding: dayComponent, to: endDate) {
            if (self.bidPeriod!.vacations?.allObjects.count ?? 0 > 1) {
                var array: NSArray = self.bidPeriod!.vacations!.allObjects as NSArray
                let sortDescriptor = [NSSortDescriptor(key: "startDate", ascending: false)]
                array = (array.sortedArray(using: sortDescriptor) as NSArray)
                exactVacEndDate = calendar.date(byAdding: dayComponent, to: endDate)!
                var subtractSixDays =  DateComponents()
                subtractSixDays.day = -6
                let resultDate = calendar.date(byAdding: subtractSixDays, to: exactVacEndDate)!
                vacationStartDateDisp = formatter.string(from: resultDate)
            }
            
            btnEOM.isSelected = true
            self.bidPeriod!.isEomOn = NSNumber(value: true)
            btnEOM.backgroundColor = UIColor(red: 35.0/255.0, green: 177.0/255.0, blue: 76.0/255.0, alpha: 1.0)
            btnEOM.setTitleColor(.white, for: .selected)
            let vacationEndDateDisp = formatter.string(from: exactVacEndDate)
            let alertMessage = "You have an `EOM` Vacation: \(vacationStartDateDisp) - \(vacationEndDateDisp).\n\nEOM weeks can affect the vacation pay in the current bid period and also the next month.\n\nWe have two documents regarding Month-to-Month vacations that also apply to EOM vacation weeks.\n\nWe suggest you read the following documents to improve your bidding knowledge."
            let storyboard = UIStoryboard(name: "BidActions", bundle: nil)
            if didDisplayMonthToMonthAlert == false {
                let storyboard : UIStoryboard = UIStoryboard(name: "BidActions", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "CBMonthToMonthAlertVC") as! CBMonthToMonthAlertVC
                vc.text = alertMessage
//                vc.delegate = self
                vc.preferredContentSize = CGSize(width: 700, height: 600)
//                vc.providesPresentationContextTransitionStyle = true
//                vc.definesPresentationContext = true
//                vc.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
//                vc.view.backgroundColor = UIColor.clear
//                    vc.onDoneBlock = { result in
//                        dismissHandler(true)
//                    }
                self.present(vc, animated: true, completion: nil)
            }
        }
    }
    
    func faVacation(vDL: CBVacationDownloader) {
        if (app.connectedToInternet() == false && self.bidPeriod!.faFileIntent == nil) {
            self.bidPeriod?.userVacationWbidOrCrewBid = ""
            self.disableVacationButton()
            AlertService.showAlertForTopVC(title: "No Internet Connection" , message: "An internet connection is required to download the vacation file. Please connect to the internet and try again.")
            btnWbidMax.isEnabled = true
            return
        }
//        if (app.isUserInformationAvailable() == false) {
//            self.bidPeriod?.userVacationWbidOrCrewBid = ""
//            AlertService.showAlertForTopVC(title: "CrewBid" , message: "User information not available,you have to create user account to access WBidMax vacation. Please create user account by clicking on new bid period (+) from home screen.")
//            btnWbidMax.isEnabled = true
//            return
//        }
        
        DispatchQueue.main.async {
            self.view.showActivityIndicator(message: "Processing Vacation ...")
            vDL.downloadFaVacationFilesWithHud() { finished in
                if (finished) {
                    self.btnWbidMax.isEnabled = true
                    if (self.bidPeriod!.containsVacay?.boolValue == true) {
                        self.selectWBidVacationButton()
                        self.setVacationBackgroundColor()
                        self.enableOrDisableEOMButton()
                        NotificationCenter.default.post(name: NSNotification.Name("ReloadSortTable"), object: self)
                        NotificationCenter.default.post(name: NSNotification.Name("ReloadFilterTable"), object: self)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            NotificationCenter.default.post(name: Notification.Name("refreshLines"), object: self)
                        }
                        NotificationCenter.default.post(name: Notification.Name("CBLineValuesToDisplayDidChangeNotification"), object: self)
                        self.perform(#selector(self.tableViewReloadForFAWithHud), with: nil, afterDelay: 0.2)

                    }
                    else if (self.bidPeriod!.vacayAlertDisplayed?.boolValue == false && self.bidPeriod!.containsVacay?.boolValue == true) {
                        DispatchQueue.main.async {
                            AlertService.showAlertForTopVC(title: "Vacation detected!", message: "Vacation weeks are overlaid in green.")
                        }
                        self.bidPeriod!.vacayAlertDisplayed = NSNumber(value: true)
                    }
                    else {
                        if self.bidPeriod!.containsVacay?.boolValue == false {
                            self.disableVacationButton()
                        }
                        self.btnWbidMax.isEnabled = true
                        self.view.hideActivityIndicator()
                    }
                    self.btnWbidMax.isUserInteractionEnabled = true
                    self.btnWbidMax.alpha = 1
                }
                else {
                    NotificationCenter.default.post(name: Notification.Name("refreshLines"), object: self)
                    self.bidPeriod!.userVacationWbidOrCrewBid = ""
                    self.disableVacationButton()
                    DispatchQueue.main.async {
                        self.view.hideActivityIndicator()
                    }
        //            self.view.hideActivityIndicator()
                    self.btnWbidMax.isEnabled = true
                }
            }
//            self.sortsTableController.tableView.reloadData()
//            self.filtersTableController.objFilterTableView.reloadData()
           
        }
    }
    
    func eomForFAVacation(vDL: CBVacationDownloader) {
        executeEOMForFAVacation(vDL: vDL)
    }
    
    func executeEOMForFAVacation(vDL: CBVacationDownloader) {
//        if (app.isUserInformationAvailable() == false) {
//            self.disableVacationButton()
//            self.bidPeriod!.userVacationWbidOrCrewBid = ""
//            AlertService.showAlertForTopVC(title: "CrewBid", message: "User information not available,you have to create user account to access WBidMax vacation. Please create user account by clicking on new bid period (+) from home screen.")
//            btnWbidMax.isEnabled = true
//            return
//        }
        self.view.showActivityIndicator(message: "Getting EOM Vacation...")
        DispatchQueue.main.async {
            if self.eomSelectedIndex.isEmpty {
                vDL.EOMSelectedIndex = self.eomSelectedIndex
            }
            else {
                vDL.EOMSelectedIndex = self.bidPeriod!.faEomSelectedDate?.stringValue ?? ""
            }
            vDL.downloadFaVacationEOMFilesWithHud() { finished in
                if (finished) {
                    self.btnWbidMax.isEnabled = true
                    if (self.bidPeriod!.containsVacay?.boolValue == true) {
                        self.selectWBidVacationButton()
                        self.setVacationBackgroundColor()
                        self.reprocessWorkBlock()
                        NotificationCenter.default.post(name: NSNotification.Name("ReloadSortTable"), object: self)
                        NotificationCenter.default.post(name: NSNotification.Name("ReloadFilterTable"), object: self)
                        NotificationCenter.default.post(name: Notification.Name("refreshLines"), object: self)
                        NotificationCenter.default.post(name: Notification.Name("CBLineValuesToDisplayDidChangeNotification"), object: self)
                        self.perform(#selector(self.tableViewReloadForFAWithHud), with: nil, afterDelay: 0.2)
                    }
                    else if (self.bidPeriod!.vacayAlertDisplayed?.boolValue == false && self.bidPeriod!.containsVacay?.boolValue == true) {
                        AlertService.showAlertForTopVC(title: "Vacation detected!", message: "Vacation weeks are overlaid in green.")
                        self.bidPeriod!.vacayAlertDisplayed = NSNumber(value: true)
                    }
                    else {
                        if (self.bidPeriod!.containsVacay?.boolValue == false) {
                            self.disableVacationButton()
                        }
                        self.view.hideActivityIndicator()
                    }
                    self.btnWbidMax.isUserInteractionEnabled = true
                    self.btnWbidMax.alpha = 1
                }
                else {
                    NotificationCenter.default.post(name: Notification.Name("refreshLines"), object: self)
                    self.disableVacationButton()
                    self.view.hideActivityIndicator()
                    self.btnWbidMax.isEnabled = true
                }
            }
            DispatchQueue.main.async {
//                self.sortsTableController.tableView.reloadData()
//                self.filtersTableController.objFilterTableView.reloadData()
               
            }
        }
    }
    func executeEOMOnlyFA(vDL: CBVacationDownloader) {
//        if (app.isUserInformationAvailable() == false) {
//            self.disableVacationButton()
//            self.bidPeriod!.userVacationWbidOrCrewBid = ""
//            AlertService.showAlertForTopVC(title: "CrewBid", message: "User information not available,you have to create user account to access WBidMax vacation. Please create user account by clicking on new bid period (+) from home screen.")
//            self.btnWbidMax.isEnabled = true
//            return
//        }
        
        DispatchQueue.main.async {
            self.view.showActivityIndicator(message: "Getting EOM Vacation...")
            if self.eomSelectedIndex.isEmpty {
                vDL.EOMSelectedIndex = self.eomSelectedIndex
            }
            else {
                vDL.EOMSelectedIndex = self.bidPeriod!.faEomSelectedDate!.stringValue
            }
            vDL.downloadFaVacationWithOnlyEOMFilesWithHud() { finished in
                if finished {
                    self.btnWbidMax.isEnabled = true
                    if (self.bidPeriod!.containsVacay?.boolValue == true) {
                        NotificationCenter.default.post(name: Notification.Name("refreshLines"), object: self)
                        self.selectWBidVacationButton()
                        self.setVacationBackgroundColor()
                        self.reprocessWorkBlock()
                        NotificationCenter.default.post(name: NSNotification.Name("ReloadSortTable"), object: self)
                        NotificationCenter.default.post(name: NSNotification.Name("ReloadFilterTable"), object: self)
                        NotificationCenter.default.post(name: Notification.Name("refreshLines"), object: self)
                        NotificationCenter.default.post(name: Notification.Name("CBLineValuesToDisplayDidChangeNotification"), object: self)
                        self.perform(#selector(self.tableViewReloadForFAWithHud), with: nil, afterDelay: 0.2)
                    }
                    else if (self.bidPeriod!.vacayAlertDisplayed?.boolValue == false && self.bidPeriod!.containsVacay?.boolValue == true) {
                        DispatchQueue.main.async {
                            AlertService.showAlertForTopVC(title: "Vacation detected!", message: "Vacation weeks are overlaid in green.")
                        }
                        self.bidPeriod!.vacayAlertDisplayed = NSNumber(value: true)
                    }
                    else {
                        if self.bidPeriod!.containsVacay?.boolValue == false {
                            self.disableVacationButton()
                        }
                        self.btnWbidMax.isEnabled = true
                        self.view.hideActivityIndicator()
                    }
                    self.btnWbidMax.isUserInteractionEnabled = true
                    self.btnWbidMax.alpha = 1
                }
                else {
                    NotificationCenter.default.post(name: Notification.Name("refreshLines"), object: self)
                    self.bidPeriod!.userVacationWbidOrCrewBid = ""
                    self.disableVacationButton()
                    self.view.hideActivityIndicator()
                    self.btnWbidMax.isEnabled = true
                }
            }
//            self.sortsTableController.tableView.reloadData()
//            self.filtersTableController.objFilterTableView.reloadData()
            
        }
    }
    
    @objc func tableViewReloadForFAWithHud() {
        let condition1 = !self.btnEOM.isHidden && !self.btnWbidMax.isSelected
        let condition2 = !self.btnEOM.isSelected
        let condition3 = !self.btnWbidMax.isSelected
        let condition4 = !self.manageVacationsEnabled
        DispatchQueue.main.async {
            if (condition1) {
                if (condition2) {
                    if (condition4) {
                        self.bidPeriod!.faVacationStatus = BIFaVacationStatus.noVacation.rawValue as NSNumber
                        UserDefaults.standard.set(true, forKey: kCBHideVacationKey)
                        DispatchQueue.main.async {
                            self.reprocessAfterChangedIncludeDroppedTrips() { finished in
                                if (finished) {
                                    self.resetDisplayTypesOfAllDays()
                                    self.view.hideActivityIndicator()
                                    if (UserDefaults.standard.bool(forKey: KCBIsSyncEnabled)) {
                                        NotificationCenter.default.post(name: Notification.Name("RefreshBidListLineCountFilter"), object: self)
                                        NotificationCenter.default.post(name: Notification.Name(kCBPresetSyncReload), object: self)
                                    }
                                    if (self.isVacationsRemoved) {
                                        self.resetAllVacationDetails()
                                    }
                                    if (self.bidPeriod!.isReportReleaseFilterApplied?.boolValue == true) {
                                        NotificationCenter.default.post(name: Notification.Name("ReloadFilterTable"), object: self)
                                    }
                                }
                                NotificationCenter.default.post(name: Notification.Name("refreshLines"), object: self)
                            }
                        }
                    }
                    return
                }
                // Observe line values to display change.
                DispatchQueue.main.async {
//                    self.scratchpadTableController.scratchPadTableView.reloadData()
                    NotificationCenter.default.post(name: Notification.Name("refreshLines"), object: self)
                }
                self.reprocessAfterChangedIncludeDroppedTrips() { finished in
                    if (finished) {
                        if (UserDefaults.standard.bool(forKey: KCBIsSyncEnabled)) {
                            NotificationCenter.default.post(name: Notification.Name("RefreshBidListLineCountFilter"), object: self)
                            NotificationCenter.default.post(name: Notification.Name(kCBPresetSyncReload), object: self)
                        }
                        if (self.isVacationsRemoved) {
                            self.resetAllVacationDetails()
                        }
                        if (self.bidPeriod!.isReportReleaseFilterApplied?.boolValue == true) {
                            NotificationCenter.default.post(name: Notification.Name("ReloadFilterTable"), object: self)
                        }
                    }
                }
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: Notification.Name("refreshLines"), object: self)
                    self.view.hideActivityIndicator()
                }
                return
            }
            if (condition3) {
                if (condition4) {
                    self.bidPeriod!.faVacationStatus = BIFaVacationStatus.noVacation.rawValue as NSNumber
                    UserDefaults.standard.set(true, forKey: kCBHideVacationKey)
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: Notification.Name("refreshLines"), object: self)
                        self.view.hideActivityIndicator()
                    }
                }
                return
            }
            // Observe line values to display change.
            DispatchQueue.main.async {
//                self.scratchpadTableController.scratchPadTableView.reloadData()
                NotificationCenter.default.post(name: Notification.Name("refreshLines"), object: self)
            }
            
            self.reprocessAfterChangedIncludeDroppedTrips() { finished in
                if (finished) {
                    if (UserDefaults.standard.bool(forKey: KCBIsSyncEnabled)) {
                        NotificationCenter.default.post(name: Notification.Name("RefreshBidListLineCountFilter"), object: self)
                        
                        NotificationCenter.default.post(name: Notification.Name(kCBPresetSyncReload), object: self)
                    }
                    DispatchQueue.main.asyncAfter(wallDeadline: .now() + 0.7) {
                        NotificationCenter.default.post(name: Notification.Name("refreshLines"), object: self)
                    }
                    if (self.isVacationsRemoved) {
                        self.resetAllVacationDetails()
                    }
                    let fetchRequest: NSFetchRequest<BILineSort> = BILineSort.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "category == 4")
                    do {
                        let arrayCommutingSort = try self.context!.fetch(fetchRequest)
                        if (arrayCommutingSort.count > 0) {
                            let lineSort = arrayCommutingSort[0]
                            self.commutingSortCell = CBCommutingSortCell()
                            self.commutingSortCell.bidPeriod = self.bidPeriod
                            self.commutingSortCell.outsideFlag = "1"
                            lineSort.ascending = NSNumber(value: false)
                            self.commutingSortCell.lineSort = lineSort
                            self.commutingSortCell.calculateSortAfterVacationLoading()
                        }
                    }
                    catch {
                        print("error fetching \(error.localizedDescription)")
                    }
                    self.perform(#selector(self.showAlertforVacationLoading), with: nil, afterDelay: 0.5)
                }
            }
            DispatchQueue.main.async {
//                DispatchQueue.main.asyncAfter(wallDeadline: .now() + 0.7) {
                    NotificationCenter.default.post(name: Notification.Name("refreshLines"), object: self)
//                }
                self.view.hideActivityIndicator()
            }
        }
    }
    
    func eomVacationDateSelect(fromBtnAction: Bool) {
        // For checking if the EOM Dates selection alert shown for first time (after bid downloaded newly for vacation user).
        let keyStr = "isEomDatesAlertShownFirstTimeFor"
        let key = "\(keyStr)-\(bidPeriod!.crewIdentifier!)-\(bidPeriod!.base!)-\(bidPeriod!.round!)-\(bidPeriod!.positionType!)"

        let userDefaults = UserDefaults.standard
        var alertShown = false

        if userDefaults.object(forKey: key) == nil {
            userDefaults.set(true, forKey: key)
            alertShown = false
        } else {
            alertShown = true
        }

//        let funcName = #function

        let day1 = "\(eomJanuaryMonthCase()) \(eomDayForFA()["Day1"] ?? 0)"
        let day2 = "\(eomMonth()) \(eomDayForFA()["Day2"] ?? 0)"
        let day3 = "\(eomMonth()) \(eomDayForFA()["Day3"] ?? 0)"
        let numbersArrayList = [day1, day2, day3]

        let alert = UIAlertController(title: "Which day your vacation starts on ?", message: nil, preferredStyle: .alert)

        for titleString in numbersArrayList {
            let action = UIAlertAction(title: titleString, style: .default) { _ in
                self.alertTitleAction(titleString)
            }
            alert.addAction(action)
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            if alertShown && fromBtnAction {
                self.btnEOM.isSelected = true
                self.btnEOMAction(btnTemp: self.btnEOM)
            } else {
                self.bidPeriod!.eomIsNo = "YES"
                do {
                    try self.self.context!.save()
                } catch {
                    print("Error saving context: \(error)")
                }

                if self.bidPeriod!.containsVacay?.boolValue == true {
                    if self.bidPeriod!.isMaxSubScriptionOfEnteredUser?.boolValue != true {
//                        MARK: need to add subscription case
//                        if CBIAPHelper.sharedInstance().daysRemainingOnSubscription() > 0 {
                            self.bidPeriod!.userVacationWbidOrCrewBid = "FAVacation"
                            self.checkForSWAPtimizerFile()
//                        } else {
//                            self.wbidMaxErrorMessageEOM(isAutot: true)
//                        }
                    } else {
//                        MARK: need to add checkSecretUser function
//                        self.checkSecretUser()
                    }
                } else {
                    self.btnEOM?.isSelected = true
                    self.btnEOMAction(btnTemp: self.btnEOM)
                }
            }
        }

        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }

    
    func eomMonth() -> String {
        let startDate = Date()
        let calendar = Calendar.current
        let timeZone = TimeZone.current
        var components = calendar.dateComponents(in: timeZone, from: startDate)
        components.day = 1
        components.month = self.bidPeriod!.month!.intValue
        components.year = self.bidPeriod!.year!.intValue
        let originalDate = calendar.date(from: components)!
        let newDate = calendar.date(byAdding: .month, value: 1, to: originalDate)!
        let updatedComponents = calendar.dateComponents([.year, .month, .day], from: newDate)
        return CBUtils.shortMonthName(month: updatedComponents.month!, uc: false)
    }
    
    func eomDayForFA() -> [String: Int] {
        var dictDays: [String: Int] = [:]

        let monthValue = bidPeriod!.month!.intValue
        if monthValue == 1 {
            dictDays["Day1"] = 31
            dictDays["Day2"] = 1
            dictDays["Day3"] = 2
        } else if monthValue == 2 {
            dictDays["Day1"] = 2
            dictDays["Day2"] = 3
            dictDays["Day3"] = 4
        } else {
            dictDays["Day1"] = 1
            dictDays["Day2"] = 2
            dictDays["Day3"] = 3
        }
        return dictDays
    }
    
    func alertTitleAction(_ title: String) {
        let dayForFA = eomDayForFA()
        
        if title == "\(eomJanuaryMonthCase()) \(dayForFA["Day1"] ?? 0)" {
            bidPeriod!.faEomSelectedDate = 1
            eomSelectedIndex = "1"
            alertShouldDisplay = true
            enableFAVacationF()
        } else if title == "\(eomMonth()) \(dayForFA["Day2"] ?? 0)" {
            bidPeriod!.faEomSelectedDate = 2
            eomSelectedIndex = "2"
            alertShouldDisplay = true
            enableFAVacationF()
        } else if title == "\(eomMonth()) \(dayForFA["Day3"] ?? 0)" {
            bidPeriod!.faEomSelectedDate = 3
            eomSelectedIndex = "3"
            alertShouldDisplay = true
            enableFAVacationF()
        }
    }

    func eomJanuaryMonthCase() -> String {
        let startDate = Date()
        let calendar = Calendar.current
        let timeZone = TimeZone.current
        var month = 1
        var components = calendar.dateComponents(in: timeZone, from: startDate)
        components.day = 1
        components.month = self.bidPeriod!.month!.intValue
        components.year = self.bidPeriod!.year!.intValue
        let originalDate = calendar.date(from: components)!
        if self.bidPeriod!.month!.intValue == 1 {
            month = 0
        }
        else {
            month = 1
        }
        let newDate = calendar.date(byAdding: .month, value: month, to: originalDate)
        let updatedComponents = calendar.dateComponents([.year, .month, .day], from: newDate!)
        return CBUtils.shortMonthName(month: updatedComponents.month!, uc: false)
    }
    
    func enableFAVacationF() {
//        let funcName = #function
        self.bidPeriod!.currentDateTime = Date()
        self.bidPeriod!.isStateFileModifiedToSync = NSNumber(value: true)
        btnEOM.isSelected = true
        self.bidPeriod!.isEomOn = NSNumber(value: true)
        btnEOM.backgroundColor = UIColor(red: 35.0/255.0, green: 177.0/255.0, blue: 76.0/255.0, alpha: 1.0)
        btnEOM.setTitleColor(.white, for: .selected)
        let vDL = CBVacationDownloader()
        vDL.bidPeriod = self.bidPeriod
        vDL.calendarData = self.calendarData
        let vacationType = self.bidPeriod!.userVacationWbidOrCrewBid
        if (vacationType == "FAVacationEomOnly" || self.bidPeriod!.seniorityVacayAvailable?.boolValue == false) {
            self.executeEOMOnlyFA(vDL: vDL)
        }
        else {
            self.executeEOMForFAVacation(vDL: vDL)
        }
    }

    func wbidMaxErrorMessageEOM(isAutot: Bool) {
        return
    }
    
    func btnEOMAction(btnTemp: UIButton) {
//        let funcName = #function
        self.bidPeriod!.currentDateTime = Date()
        self.bidPeriod!.isStateFileModifiedToSync = NSNumber(value: true)
        let vDL = CBVacationDownloader()
        vDL.bidPeriod = self.bidPeriod
        vDL.calendarData = self.calendarData
        if (btnEOM.isSelected) {
            btnEOM.isSelected = false
            self.bidPeriod!.isEomOn = NSNumber(value: false)
            btnEOM.backgroundColor = .white
            btnEOM.setTitleColor(.black, for: .normal)
            if (self.bidPeriod!.seniorityVacayAvailable?.boolValue != true) {
                if btnWbidMax.isSelected {
                    btnWbidMax.isSelected = false
                    btnWbidMax.backgroundColor = .white
                    btnWbidMax.setTitleColor(.black, for: .normal)
                }
            }
        }
        else {
            btnEOM.isSelected = true
            self.bidPeriod!.isEomOn = NSNumber(value: true)
//            DispatchQueue.main.async {
                self.btnEOM.backgroundColor = UIColor(red: 35.0/255.0, green: 177.0/255.0, blue: 76.0/255.0, alpha: 1.0)
                self.btnEOM.setTitleColor(.white, for: .selected)
//            }
            self.bidPeriod!.isSwaptimizerOn = NSNumber(value: false)
            btnSwaptimizer.backgroundColor = .white
            btnSwaptimizer.setTitleColor(.black, for: .normal)
        }
        if btnEOM.isSelected {
            // Added below code to set swaptimizer status
            if self.bidPeriod!.isSwaptimizerOn!.boolValue == true {
                self.bidPeriod!.userVacationWbidOrCrewBid = "CREWBIDF"
                self.eomVacationDateSelectForPilot(fromBtnAction: true)
                return
            }
            else if btnWbidMax.isSelected && self.bidPeriod?.isFABid() == false {
                self.bidPeriod!.userVacationWbidOrCrewBid = "WBIDF"
                self.eomVacationDateSelectForPilot(fromBtnAction: true)
                return
            }
            else if (!btnWbidMax.isSelected && self.bidPeriod?.isFABid() == true) {
                self.bidPeriod!.userVacationWbidOrCrewBid = "FAVacationEomOnly"
                self.eomVacationDateSelect(fromBtnAction: true)
                return
            }
            else if (btnWbidMax.isSelected && self.bidPeriod?.isFABid() == true) {
                self.bidPeriod!.userVacationWbidOrCrewBid = "FAVacationF"
                self.eomVacationDateSelect(fromBtnAction: true)
                try? self.context!.save()
                return
            }
            else {
                self.bidPeriod!.userVacationWbidOrCrewBid = "WBIDF"
                self.eomVacationDateSelectForPilot(fromBtnAction: true)
                return
            }
        }
        else {
            if btnSwaptimizer.isSelected   {
                self.crewbid(vDL: vDL)
                return
            }
            else if (btnWbidMax.isSelected && (self.bidPeriod!.wbFileIntent != nil || self.bidPeriod!.wbFileIntentF != nil)) {
                if (self.bidPeriod!.userVacationWbidOrCrewBid == "" || self.bidPeriod?.userVacationWbidOrCrewBid == "WBIDF") {
                    self.wbid(vDL: vDL)
                }
                return
            }
            else if ((btnWbidMax.isSelected == false) && self.bidPeriod!.userVacationWbidOrCrewBid == "WBID") {
                self.wbid(vDL: vDL)
                return
            }
            else if (btnWbidMax.isSelected && self.bidPeriod?.isFABid() == true) {
                if (self.bidPeriod!.containsVacay?.boolValue == true) {
                    self.faVacation(vDL: vDL)
                    return
                }
                else {
                    btnEOM.isSelected = false
                    self.bidPeriod!.isEomOn = NSNumber(value: false)
                    btnEOM.backgroundColor = .white
                    btnEOM.setTitleColor(.black, for: .normal)
                    self.eomVacationDateSelect(fromBtnAction: true)
                }
            }
            else {
                self.bidPeriod!.userVacationWbidOrCrewBid = ""
                self.bidPeriod!.vacationType = ""
                do {
                    try self.context!.save()
                }
                catch {
                    print("error saving \(error.localizedDescription)")
                }
                self.removeCurrentVacation()
//                self.scratchpadTableController.scratchPadTableView.reloadData()
                self.bidPeriod?.isSwaptimizerOn = NSNumber(value: false)
                btnSwaptimizer.backgroundColor = .white
                btnSwaptimizer.setTitleColor(.black, for: .normal)
                btnWbidMax.isSelected = false
                self.bidPeriod!.isWbidMaxOn = NSNumber(value: false)
                btnWbidMax.backgroundColor = .white
                btnWbidMax.setTitleColor(.black, for: .normal)
//                self.sortsTableController.tableView.reloadData()
//                self.filtersTableController.objFilterTableView.reloadData()
                NotificationCenter.default.post(name: Notification.Name("refreshLines"), object: self)
            }
        }
    }
    
    func eomVacationDateSelectForPilot(fromBtnAction: Bool) {
        // For checking if the EOM Dates selection alert shown for first time (after bid downloaded newly for vacation user).
        let keyStr = "isEomDatesAlertShownFirstTimeFor"
        let key = "\(keyStr)-\(bidPeriod!.crewIdentifier!)-\(bidPeriod!.base!)-\(bidPeriod!.round!)-\(bidPeriod!.positionType!)"
        let userDefaults = UserDefaults.standard
        var alertShown = false
        if userDefaults.object(forKey: key) == nil {
            userDefaults.set(true, forKey: key)
            alertShown = false
        } else {
            alertShown = true
        }
//        let funcName = #function

        let day1 = "\(eomMonth()) \(eomDayForPilot()["Day1"] ?? 0)"
        let day2 = "\(eomMonth()) \(eomDayForPilot()["Day2"] ?? 0)"
        let day3 = "\(eomMonth()) \(eomDayForPilot()["Day3"] ?? 0)"
        let numbersArrayList = [day1, day2, day3]

        let alert = UIAlertController(title: "Which day your vacation starts on?", message: nil, preferredStyle: .alert)

        for titleString in numbersArrayList {
            let action = UIAlertAction(title: titleString, style: .default) { _ in
                self.alertTitleActionPilot(titleString)
            }
            alert.addAction(action)
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            self.bidPeriod!.currentDateTime = Date()
            self.bidPeriod!.isStateFileModifiedToSync = NSNumber(value: true)
            self.btnEOM.isSelected = false
            self.bidPeriod!.isEomOn = NSNumber(value: false)
            self.bidPeriod!.userVacationWbidOrCrewBid = "WBID"

            self.btnEOM.backgroundColor = .white
            self.btnEOM.setTitleColor(.black, for: .normal)

            if alertShown && fromBtnAction {
                self.btnEOM?.isSelected = true
                self.btnEOMAction(btnTemp: self.btnEOM)
            } else {
                self.bidPeriod!.eomIsNo = "YES"
                do {
                    try self.context!.save()
                } catch {
                    print("Error saving context: \(error)")
                }

                if self.bidPeriod!.containsVacay?.boolValue == true && self.bidPeriod!.swaptimizerStatus?.intValue == 0 {
                    if self.bidPeriod!.isMaxSubScriptionOfEnteredUser?.boolValue == false {
//                    MARK: needed to add subscription case
//                        if CBIAPHelper.sharedInstance().daysRemainingOnSubscription() > 0 {
                            self.bidPeriod!.userVacationWbidOrCrewBid = "WBID"
                            self.checkForSWAPtimizerFile()
//                        } else {
//                            self.wbidMaxErrorMessageEOM(true)
//                        }
                    } else {
//                    MARK: needed to add checkSecretUser function
//                        self.checkSecretUser()
                    }
                } else {
                    // Refresh EOM highlighter
                    self.btnEOM.isSelected = true
                    self.btnEOMAction(btnTemp: self.btnEOM)
                }
            }
        }

        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }

    
    func eomDayForPilot() -> [String: Int] {
        var dictDays: [String: Int] = [:]
        dictDays["Day1"] = 1
        dictDays["Day2"] = 2
        dictDays["Day3"] = 3
        return dictDays
    }
    
    func alertTitleActionPilot(_ title: String) {
        let dayForPilot = eomDayForPilot()
        let eomMonthString = eomMonth()
        didDisplayMonthToMonthAlert = false
        if let day1 = dayForPilot["Day1"] {
            if title == "\(eomMonthString) \(day1)" {
                bidPeriod!.faEomSelectedDate = 1
                eomSelectedIndex = "1"
                if bidPeriod!.isMaxSubScriptionOfEnteredUser?.boolValue == true {
                    //                checkSecretUser()
                } else {
                    alertShouldDisplay = true
                    checkForSWAPtimizerFile()
                }
            }
        }
        if let day2 = dayForPilot["Day2"] {
            if title == "\(eomMonthString) \(day2)" {
                bidPeriod!.faEomSelectedDate = 2
                eomSelectedIndex = "2"
                if bidPeriod!.isMaxSubScriptionOfEnteredUser?.boolValue == true {
                    //                checkSecretUser()
                } else {
                    alertShouldDisplay = true
                    checkForSWAPtimizerFile()
                }
            }
        }
        if let day3 = dayForPilot["Day3"] {
            if title == "\(eomMonthString) \(day3)" {
                bidPeriod!.faEomSelectedDate = 3
                eomSelectedIndex = "3"
                if bidPeriod!.isMaxSubScriptionOfEnteredUser?.boolValue == true {
                    //                checkSecretUser()
                } else {
                    alertShouldDisplay = true
                    checkForSWAPtimizerFile()
                }
            }
        }
    }

    func removeCurrentVacation() {
        DispatchQueue.main.async {
            self.view.showActivityIndicator(message: "Removing Vacation...")
            self.bidPeriod!.isVacationRemoved = NSNumber(value: true)
            let vDL = CBVacationDownloader()
            vDL.bidPeriod = self.bidPeriod
            vDL.calendarData = self.calendarData
            vDL.deleteAllVacation()
        }
        UserDefaults.standard.set(true, forKey: kCBIncludeDroppedTripsInProcessingKey)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if (self.bidPeriod!.isFABid() == true) {
                self.perform(#selector(self.tableViewReloadForFAWithHud), with: nil, afterDelay: 0.2)
            }
            else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.tableViewReloadWithHud() // tableViewReload
                }
            }
            self.reprocessWorkBlock()
            self.view.hideActivityIndicator()
            
            let fetchRequest: NSFetchRequest<BILineSort> = BILineSort.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "category == 4")
            do {
                let arrayCommutingSort = try self.context!.fetch(fetchRequest)
                if (arrayCommutingSort.count > 0) {
                    let lineSort = arrayCommutingSort[0]
                    self.commutingSortCell = CBCommutingSortCell()
                    self.commutingSortCell.bidPeriod = self.bidPeriod
                    self.commutingSortCell.outsideFlag = "1"
                    lineSort.ascending = NSNumber(value: false)
                    self.commutingSortCell.lineSort = lineSort
                    self.commutingSortCell.calculateSortAfterVacationLoading()
                }
            }
            catch {
                print("error fetching \(error.localizedDescription)")
            }
        }
    }
    
    func executeEOMModule() {
        if self.bidPeriod!.vacationType == "CREWBIDF" {
            self.bidPeriod?.userVacationWbidOrCrewBid = "CREWBIDF"
            alertShouldDisplay = false
            self.checkForSWAPtimizerFile()
        }
        else if self.bidPeriod!.vacationType == "CREWBID" {
            self.bidPeriod?.userVacationWbidOrCrewBid = "CREWBID"
            alertShouldDisplay = false
            self.checkForSWAPtimizerFile()
//            self.selectSwaptimizerVacationButton()
        }
        else if self.bidPeriod!.vacationType == "WBID" {
            self.bidPeriod?.userVacationWbidOrCrewBid = "WBID"
            alertShouldDisplay = false
            self.checkForSWAPtimizerFile()
        }
        else if self.bidPeriod!.vacationType == "WBIDF" {
            self.bidPeriod?.userVacationWbidOrCrewBid = "WBIDF"
            alertShouldDisplay = false
            self.checkForSWAPtimizerFile()
        }
        else {
            self.showEomVacationConfirmationAlertForPilot()
        }
    }
    
    func selectEOMButton() {
        btnEOM.isSelected = true
        self.bidPeriod!.isEomOn = NSNumber(value: true)
        btnEOM.backgroundColor = UIColor(red: 35.0/255.0, green: 177.0/255.0, blue: 76.0/255.0, alpha: 1.0)
        btnEOM.setTitleColor(.white, for: .selected)
    }
    // To show this alert whenever open the bid from home screen.
    func showEomVacationConfirmationAlertForPilot() {
        if ((!(bidPeriod!.eomIsNo == "YES") && !(bidPeriod!.isFABid())) ||
            bidPeriod!.vacationType == "WBID" || bidPeriod!.vacationType == "WBIDF") {
            AlertService.showAlertForTopVC(title: "Vacation!", message: "Do you have Vacation Starting in the first 3 days of the next bid period \(self.eomMonth()) ?", actions: [(
                title: "Yes",
                style: .default,
                handler: { _ in
                    self.bidPeriod!.eomIsNo = "NO"
                    try? self.context!.save()
                    self.bidPeriod!.userVacationWbidOrCrewBid = "WBIDF"
                    self.eomVacationDateSelectForPilot(fromBtnAction: false)
                }
            ),
            (
                title: "No",
                style: .cancel,
                handler: { _ in
                    self.bidPeriod!.eomIsNo = "YES"
                    try? self.context!.save()
                    
                    if self.bidPeriod!.isMaxSubScriptionOfEnteredUser?.boolValue == false {
                        // Check for CreBidMax - Subscription available
//                        if CBIAPHelper.sharedInstance().daysRemainingOnSubscription() > 0 {
                        self.bidPeriod!.userVacationWbidOrCrewBid = "WBID"
                        self.checkForSWAPtimizerFile()
//                        }
//                    else {
//                        self.wbidMaxErrorMessageEOM(isAuto: true)
//                        }
                    }
                    else {
//                        self.checkSecretUser()
                    }
                }
            )])
        }
    }
    
    @IBAction func btnEomActionFromStoryBoard(_ sender: UIButton) {
        self.btnEOMAction(btnTemp: self.btnEOM)
    }
    
    @IBAction func btnWbidMaxAction(_ sender: UIButton) {
        //        MARK: btn action for FA
        if self.btnWbidMax.currentTitle == "VAC" {
            if (btnWbidMax.isSelected) {
                AlertService.showAlertForTopVC(title: "Warning!", message: "You want to turn off vacation providers.  This will disable any vacation sorts or filters you currently have set.  Your bid list will NOT be affected.  When you again select any vacation provider to whom you have a subscription, your vacation sorts and filters will again be enabled.", actions: [(
                    title: "OK",
                    style: .default,
                    handler: { _ in
                        self.faVacationButtonAction(btnTemp: self.btnWbidMax)
                    }
                ),(
                    title: "Cancel",
                    style: .cancel,
                    handler: { _ in
                        if (self.btnEOM.isSelected) {
                            self.bidPeriod?.userVacationWbidOrCrewBid = "FAVacationF"
                            self.checkForSWAPtimizerFile()
                        }
                        else {
                            self.bidPeriod?.userVacationWbidOrCrewBid = "FAVacation"
                            self.checkForSWAPtimizerFile()
                        }
                    }
                )
                ])
            }
            else {
                alertShouldDisplay = true
                if btnEOM.isSelected {
                    self.bidPeriod!.userVacationWbidOrCrewBid = "FAVacationF"
                    self.checkForSWAPtimizerFile()
                }
                else {
                    self.bidPeriod!.userVacationWbidOrCrewBid = "FAVacation"
                    self.checkForSWAPtimizerFile()
                }
            }
        }
//        MARK: btn action for WBID
        else {
            if (self.btnWbidMax.isSelected) {
                if (self.bidPeriod!.containsCFV?.boolValue == true) {
                    UserDefaults.standard.set(true, forKey: "RemoveCfv")
                }
            }
            else {
                if (self.bidPeriod!.containsCFV?.boolValue == true) {
                    UserDefaults.standard.set(false, forKey: "RemoveCfv")
                }
                alertShouldDisplay = true
            }
            switch (app.objNetworkType) {
            case .free:
                AlertService.showAlertForTopVC(title: "Sorry!", message: "You cannot get needed access via SouthwestWifi or 2Wire. Try again later when you are safely on the ground and have another internet access. \(self.eomMonth())")
                return
            default:
                break
            }
            if app.isFlightNetwork {
                AlertService.showAlertForTopVC(title: "Sorry!", message: "You cannot get needed access via SouthwestWifi or 2Wire. Try again later when you are safely on the ground and have another internet access. \(self.eomMonth())")
                return
            }
            let seniorityVacayValue = self.bidPeriod?.seniorityVacayAvailable!
            if (!(self.bidPeriod!.seniorityVacayAvailable?.boolValue ?? false) && !btnWbidMax.isSelected && seniorityVacayValue != 0) {
                AlertService.showAlertForTopVC(title: "Vacation", message: "You do not have Vacation this month.  If you have vacation starting in the 1st 3 days of \(self.eomMonth()), then touch the EOM button")
            }
            else {
                self.bidPeriod!.currentDateTime = Date()
                self.bidPeriod!.isStateFileModifiedToSync = NSNumber(value: true)
                if (btnWbidMax.isSelected && !btnSwaptimizer.isSelected) {
                    AlertService.showAlertForTopVC(
                        title: "Warning!",
                        message: "You want to turn off both vacation providers (WBidMax - Swaptimizer). This will disable any vacation sorts or filters you currently have set. Your bid list will NOT be affected. When you again select any vacation provider to whom you have a subscription, your vacation sorts and filters will again be enabled.",
                        actions: [
                            (
                                title: "OK",
                                style: UIAlertAction.Style.default,
                                handler: { (_: UIAlertAction) in
                                    let btn = UIButton()
                                    btn.tag = 20
                                    if self.bidPeriod?.containsFvVacay?.boolValue == true {
                                        DispatchQueue.main.async {
                                            self.view.showActivityIndicator(message: "Removing Vacation...")
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                                self.view.hideActivityIndicator()
                                            }
                                        }
                                    }
                                    self.perform(#selector(self.wbidVacationButtonActionDelay(_:)), with: btn, afterDelay: 0.01)
                                }
                            ),
                            (
                                title: "cancel",
                                style: UIAlertAction.Style.cancel,
                                handler: { (_: UIAlertAction) in }
                            )
                        ]
                    )

                }
                else {
                    if (self.bidPeriod!.onlyContainEOM == "NO") {
                        if (self.btnEOM.isSelected) {
                            self.bidPeriod!.userVacationWbidOrCrewBid = "WBIDF"
                            self.checkForSWAPtimizerFile()
                        }
                        else {
                            self.wbidVacationButtonAction(sender)
                        }
                    }
                    else {
                        if (self.btnEOM.isSelected) {
                            self.bidPeriod!.userVacationWbidOrCrewBid = "WBIDF"
                            self.checkForSWAPtimizerFile()
                        }
                        else {
                            self.bidPeriod!.userVacationWbidOrCrewBid = "WBID"
                            self.checkForSWAPtimizerFile()
                        }
                    }
                }
            }
        }
    }
    
    func faVacationButtonAction(btnTemp: UIButton) {
        let vDl = CBVacationDownloader()
        vDl.bidPeriod = self.bidPeriod
        vDl.calendarData = self.calendarData
        if btnWbidMax.isSelected {
            btnWbidMax.isSelected = false
            self.bidPeriod!.isFAVacationOn = NSNumber(value: false)
            btnWbidMax.setTitleColor(UIColor.black, for: .normal)
            btnWbidMax.backgroundColor = UIColor.white
            self.bidPeriod!.currentDateTime = Date()
            self.bidPeriod!.isStateFileModifiedToSync = NSNumber(value: true)
        }
        self.bidPeriod!.userVacationWbidOrCrewBid = ""
        self.bidPeriod!.vacationType = ""
        do {
            try self.context?.save()
            print("after removing vacation from fa")
        }
        catch {
            print("error while saving \(error.localizedDescription)")
        }
        self.removeCurrentVacation()
        self.bidPeriod!.isSwaptimizerOn = NSNumber(value: false)
        self.btnSwaptimizer.backgroundColor = UIColor.white
        btnSwaptimizer.setTitleColor(UIColor.black, for: .normal)
        self.bidPeriod!.currentDateTime = Date()
        self.bidPeriod!.isStateFileModifiedToSync = NSNumber(value: true)
        NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
        self.enableOrDisableEOMButton()
    }
    
    @objc func wbidVacationButtonActionDelay(_ btn: UIButton) {
        self.wbidVacationButtonAction(btn)
    }
    
    func wbidVacationButtonAction(_ btn: UIButton) {
        if btn.tag == 21 {
            btnSwaptimizer.isSelected = !btnSwaptimizer.isSelected
            if btnSwaptimizer.isSelected {
                self.selectSwaptimizerVacationButton()
                if btnEOM.isSelected {
                    self.bidPeriod!.userVacationWbidOrCrewBid = "CREWBIDF"
                }
                else {
                    self.bidPeriod!.userVacationWbidOrCrewBid = "CREWBID"
                }
                self.checkForSWAPtimizerFile()
            }
            else {
                self.removeCurrentVacation()
                self.bidPeriod!.isSwaptimizerOn = NSNumber(value: false)
                btnSwaptimizer.backgroundColor = .white
                btnSwaptimizer.setTitleColor(.black, for: .normal)
                self.bidPeriod!.currentDateTime = Date()
                self.bidPeriod!.isStateFileModifiedToSync = NSNumber(value: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    NotificationCenter.default.post(name: Notification.Name("refreshLines"), object: self)
                }
            }
        }
        else {
            btnWbidMax.isSelected = !btnWbidMax.isSelected
            if btnWbidMax.isSelected {
                if btnEOM.isSelected {
                    self.bidPeriod!.userVacationWbidOrCrewBid = "WBIDF"
                }
                else {
                    self.bidPeriod!.userVacationWbidOrCrewBid = "WBID"
                }
                self.checkForSWAPtimizerFile()
            }
            else {
                self.removeCurrentVacation()
                self.bidPeriod!.userVacationWbidOrCrewBid = ""
                self.bidPeriod!.vacationType = ""
                self.bidPeriod!.isWbidMaxOn = NSNumber(value: false)
                btnWbidMax.backgroundColor = .white
                btnWbidMax.setTitleColor(.black, for: .normal)
                self.bidPeriod!.currentDateTime = Date()
                self.bidPeriod!.isStateFileModifiedToSync = NSNumber(value: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3){
                    NotificationCenter.default.post(name: Notification.Name("refreshLines"), object: self)
                }
                do {
                    try self.context?.save()
                    print(" saved successfully from wbidVacationButtonAction")
                }
                catch {
                    print("error saving from wbidVacationButtonAction \(error.localizedDescription)")
                }
            }
            self.enableOrDisableEOMButton()
        }
    }
    
    @IBAction func btnCrewBidVacationButtonAction(_ sender: UIButton) {
        if (!btnWbidMax.isSelected && btnSwaptimizer.isSelected) {
            AlertService.showAlertForTopVC(
                title: "Warning!",
                message: "You want to turn off both vacation providers (WBidMax - Swaptimizer). This will disable any vacation sorts or filters you currently have set. Your bid list will NOT be affected. When you again select any vacation provider to whom you have a subscription, your vacation sorts and filters will again be enabled.",
                actions: [
                    (
                        title: "OK",
                        style: UIAlertAction.Style.default,
                        handler: { (_: UIAlertAction) in
                            let btn = UIButton()
                            btn.tag = 21
                            if self.bidPeriod?.containsFvVacay?.boolValue == true {
                                DispatchQueue.main.async {
                                    self.view.showActivityIndicator(message: "Processing")
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                        self.view.hideActivityIndicator()
                                    }
                                }
                            }
                            self.perform(#selector(self.wbidVacationButtonActionDelay(_:)), with: btn, afterDelay: 0.01)
                        }
                    ),
                    (
                        title: "cancel",
                        style: UIAlertAction.Style.cancel,
                        handler: { (_: UIAlertAction) in }
                    )
                ]
            )

        }
        else {
            if (self.bidPeriod!.onlyContainEOM == "NO") {
                if (self.btnEOM.isSelected) {
                    self.bidPeriod!.userVacationWbidOrCrewBid = "CREWBIDF"
                    self.checkForSWAPtimizerFile()
                }
                else {
                    self.wbidVacationButtonAction(sender)
                }
            }
            else {
                if (self.btnEOM.isSelected) {
                    self.bidPeriod!.userVacationWbidOrCrewBid = "CREWBIDF"
                    self.checkForSWAPtimizerFile()
                }
                else {
                    alertShouldDisplay = true
                    self.bidPeriod!.userVacationWbidOrCrewBid = "CREWBID"
                    self.checkForSWAPtimizerFile()
                }
            }
        }
    }
    
    @objc func tapWBidMaxBtn() {
        if bidPeriod?.isFABid() == false {
            wbidVacationButtonAction(btnWbidMax)
        }
    }
}

