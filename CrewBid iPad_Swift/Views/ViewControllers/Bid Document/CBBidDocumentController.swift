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
    
    @IBOutlet weak var leftShadowView: UIView!
    @IBOutlet weak var rightShadowView: UIView!
    @IBOutlet weak var leftContainerView: UIView!
    @IBOutlet weak var rightContainerView: UIView!
    @IBOutlet weak var bidView: UIView!
    
    @IBOutlet weak var bidCont: UIView!
    var bidPeriod: BIBidPeriod?
    var bidVC: CBBidListVC!
    var bidLinesController:CBBidListVC!
    var rightNavController:UINavigationController!
    var bidsTableNavController:UINavigationController!
    var dataSource = GlobalBidInfo.shared
    var linesManager:BILinesManager!
    var calendarData:BICalendarData = BICalendarData()
    var managedObjectContext: NSManagedObjectContext {
        return CoreDataManager.shared.persistentContainer.viewContext
    }
    var positionFlag1 = 0
    var tempPositionLine : [BILine] = []
    var filtersTableController = CBFilterRulesTableVC()
    var scratchpadTableController = CBScratchPadVC()
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
    var seniorityShowd = false
    var eomSelectedIndex = ""
    var commutingSortCell = CBCommutingSortCell()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateLocalHerbSwitchUI()
        self.bidPeriod = CBGlobalMethods.shared.selectedBidPeriod!
        self.context = CBGlobalMethods.shared.selectedBidPeriod!.managedObjectContext!
        self.linesManager = BILinesManager.init(managedObjectContext: self.managedObjectContext)
        self.calendarData = calendarData.initWithBidPeriod(bidPeriod: self.bidPeriod!)!
        isVacationsRemoved = false
        
        self.bidLinesController = self.storyboard?.instantiateViewController(withIdentifier: "CBBidListVC") as? CBBidListVC
        self.bidLinesController.managedObjectContext = self.managedObjectContext
        self.bidLinesController.bidPeriod = self.bidPeriod!
        
        setupUI()
        NotificationCenter.default.addObserver(self, selector: #selector(self.setupLayoutView), name: NSNotification.Name("SortBidListAction"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.setupLayoutViewForSwitch), name: NSNotification.Name("SyncSwitchStateAction"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showCommutablilityFilterView), name: Notification.Name("ShowCommutabilityFilterView"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ShowCommutablilitySortView), name: Notification.Name("ShowCommutabilitySortView"), object: nil)
        
        firstTimeBidOpen()
        
        NotificationCenter.default.addObserver(self, selector: #selector(openCoverLetter(notification:)), name: NSNotification.Name(KCBOpenCoverletter), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(openSeniority), name: NSNotification.Name(KCBOpenSeniority), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(openLineText), name: NSNotification.Name(KCBOpenLineText), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(openTripText), name: NSNotification.Name(KCBOpenTripText), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(openFAMemo), name: NSNotification.Name(KCBOpenFAMemo), object: nil)
    }
    
    @objc func openCoverLetter(notification: Notification) {
        let storyboard : UIStoryboard = UIStoryboard(name: "BidActions", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBTextViewController") as! CBTextViewController
        vc.bidPeriod = bidPeriod
        vc.dataTypeSelected = TextFileType.coverLetter
        if let userInfo = notification.userInfo as? NSDictionary {
            vc.isFromFirstTimeOpenBid = userInfo["isFromFirstTimeOpenBid"] as! Bool
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }
    //openSeniority view controller push action
@objc func openSeniority() {
    let storyboard : UIStoryboard = UIStoryboard(name: "BidActions", bundle: nil)
    let vc = storyboard.instantiateViewController(withIdentifier: "CBTextViewController") as! CBTextViewController
    vc.bidPeriod = bidPeriod
    vc.dataTypeSelected = TextFileType.seniorityList
    self.navigationController?.pushViewController(vc, animated: true)
}
    //LineText view controller push action
@objc func openLineText() {
    let storyboard : UIStoryboard = UIStoryboard(name: "BidActions", bundle: nil)
    let vc = storyboard.instantiateViewController(withIdentifier: "CBTextViewController") as! CBTextViewController
    vc.bidPeriod = bidPeriod
    vc.dataTypeSelected = TextFileType.lineText
    self.navigationController?.pushViewController(vc, animated: true)
}
    //TripText view controller push action
@objc func openTripText() {
    let storyboard : UIStoryboard = UIStoryboard(name: "BidActions", bundle: nil)
    let vc = storyboard.instantiateViewController(withIdentifier: "CBTextViewController") as! CBTextViewController
    vc.bidPeriod = bidPeriod
    vc.dataTypeSelected = TextFileType.tripText
    self.navigationController?.pushViewController(vc, animated: true)
}
    //LineText view controller push action
@objc func openFAMemo(){
    let storyboard : UIStoryboard = UIStoryboard(name: "BidActions", bundle: nil)
    let vc = storyboard.instantiateViewController(withIdentifier: "CBTextViewController") as! CBTextViewController
    vc.bidPeriod = bidPeriod
    vc.dataTypeSelected = TextFileType.faMemo
    self.navigationController?.pushViewController(vc, animated: true)
}
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        NotificationCenter.default.addObserver(self, selector: #selector(bidLines), name: Notification.Name(CBLinesTableBidLinesNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(bidLines), name: Notification.Name(CBLinesTableBidLinesFaAllNotification), object: nil)
        
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver("SortBidListAction")
        NotificationCenter.default.removeObserver("SyncSwitchStateAction")
        NotificationCenter.default.removeObserver("ShowCommutabilityFilterView")
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
//        guard let linesToBid = notification.userInfo?[CBLinesTableBidLinesArrayKey] as? [BILine] else { return }
//
//        let isFAAllNotification = notification.name.rawValue == CBLinesTableBidLinesFaAllNotification
//
//        if bidLinesController.view.window == nil {
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
//                self.bidLinesController.insertLines(linesToBid, faBidAllPositions: isFAAllNotification)
//            }
//        } else {
//            bidLinesController.insertLines(linesToBid, faBidAllPositions: isFAAllNotification)
//        }
    }
    
    func updateLocalHerbSwitchUI() {
        let setting = UserDefaults.standard.integer(forKey: kCBTimeZoneSetting)
        
        if setting == CBTimeZoneSetting.herbTime.rawValue {
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
    
    func showBidLines(completion: (() -> Void)? = nil) {
        
    }
    
    func setupUI(){
        let positionArray = ["CP","FO","FA"]
        let index = dataSource.position.rawValue
        lblHome.text = "(\(CBUtils.AppVersion())) " +
                       CBGlobalMethods.shortMonthNameOf(monthInt: dataSource.month) + " " +
                       "\(positionArray[index]) " +
        "\(dataSource.year) \(dataSource.base) Rnd \(dataSource.round)"

        btnLocalHerbView.layer.borderWidth = 1
        btnLocalHerbView.layer.borderColor = UIColor.black.cgColor
        btnLocalHerbView.layer.cornerRadius = 16
    
        herbLabel.backgroundColor = UIColor.purple
        herbLabel.textColor = UIColor.white
        
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
        print("iiiiii")
//            self.view.showActivityIndicator(message: "Processing Vacation Files")
//        CBVacationDownloader.shared.executeAutoDownload() { success in
//                self.view.hideActivityIndicator()
//        }
        self.handleVacationData()
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
            localLabel.backgroundColor = UIColor.purple
            localLabel.textColor = UIColor.white
            herbLabel.backgroundColor = UIColor.white
            herbLabel.textColor = UIColor.black
        }else{
            UserDefaults.standard.set(CBTimeZoneSetting.herbTime.rawValue, forKey: kCBTimeZoneSetting)
            localLabel.backgroundColor = UIColor.white
            localLabel.textColor = UIColor.black
            herbLabel.backgroundColor = UIColor.purple
            herbLabel.textColor = UIColor.white
        }
        NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
//        NotificationCenter.default.post(name: NSNotification.Name("amPmValueChangedFromButton"), object: self)
    }
    
    @IBAction func settingsAction(_ sender: Any) {
        let storyboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "EmbeddedSettingsVC") as! EmbeddedSettingsVC
//        vc.bidPeriod = self.bidPeriod
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
        print("HelpMenu")
        let storyBoard = UIStoryboard(name: "HelpMenu", bundle: nil)
        if let helpMenuVC = storyBoard.instantiateViewController(withIdentifier: "helpMenuViewController") as? helpMenuViewController{
//            helpMenuVC.modalPresentationStyle = .formSheet
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
        print("Presenting from topVC: \(topVC)")
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
            monthToMonthAlert.showAlertFromViewController(from: self) { tappedOk in
                if tappedOk {
                    self.bidPeriod?.vactionWeekAlertDisplayed = NSNumber(value: true)
                    completionHandler(true)
                }
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
            if self.bidPeriod!.latestNewsDisplayed?.boolValue == false {
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
        let funcName = #function
        if (self.bidPeriod?.vacationType == "CREWBIDF" || self.bidPeriod?.vacationType == "WBIDF" || self.bidPeriod?.vacationType == "FAVacationF" || self.bidPeriod?.vacationType == "FAVacationEomOnly") {
            self.bidPeriod?.currentDateTime = Date()
            self.bidPeriod?.isStateFileModifiedToSync = NSNumber(value: true)
            btnEOM.isEnabled = true
            btnEOM.alpha = 1
            btnEOM.isSelected = true
            self.bidPeriod?.isEomOn = NSNumber(value: true)
            btnEOM.backgroundColor = UIColor(red: 35.00/255.0, green: 177.0/255.0, blue: 76.0/255.0, alpha: 1.00)
            btnEOM.setTitleColor(.white, for: .normal)
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
            btnEOM.setTitleColor(.white, for: .normal)
        }
        if self.bidPeriod?.isFABid() == false {
            if ((self.bidPeriod?.isSwaptimizerOn?.boolValue == true) && (self.bidPeriod!.vacationType != nil) && (self.bidPeriod?.vacationType == "WBIDF")) {
                btnEOM.isSelected = false
                self.bidPeriod?.isEomOn = NSNumber(value: false)
                btnEOM.backgroundColor = .white
                btnEOM.setTitleColor(.white, for: .normal)
            }
        }
    }
    
    func executeEOMForFA() {
        if ( self.bidPeriod!.vacationType == "FAVacationF") {
            self.bidPeriod!.userVacationWbidOrCrewBid = "FAVacationF"
            self.checkForSWAPtimizerFile()
        }
        else if ( self.bidPeriod!.vacationType == "FAVacation") {
            self.bidPeriod!.userVacationWbidOrCrewBid = "FAVacation"
            self.checkForSWAPtimizerFile()
        }
        else if ( self.bidPeriod!.vacationType == "FAVacationEomOnly") {
            self.bidPeriod!.userVacationWbidOrCrewBid = "FAVacationEomOnly"
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
                default:
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
                default:
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
                default:
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
                default:
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
                default:
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
                default:
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
                default:
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
        let funcName = #function
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
        let funcName = #function
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
        var bidReader = BIBidInfoReader()
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
                }
            }
        }
        catch {
            print("failed to perform fetch \(error.localizedDescription)")
        }
    }
    
    func tableViewReloadWithHud() {
        let condition1 = /*!btnEOM.isHidden && !btnSwaptimizer.isSelected && !btnWbidMax.isSelected*/ false
        let condition2 = /*!btnEOM.isHidden*/ false
        let condition3 = /*!btnSwaptimizer.isSelected && !btnWbidMax.isSelected*/ false
        let condition4 = /*!self.manageVacationsEnabled*/ false
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
                    if (self.seniorityShowd == false && self.bidPeriod?.isHistoric?.boolValue == false) {
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
                        if (self.seniorityShowd == false && self.bidPeriod?.isHistoric?.boolValue == false) {
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
                            self.perform(#selector(self.showAlertforVacationLoading), with: nil, afterDelay: 0.5)
                        }
                    }
                    catch {
                        print("failed to fetch line sort \(error.localizedDescription)")
                    }
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
                print("saved instaed of quick save function")
            }
            catch {
                print("unable to save instead of quick save function \(error.localizedDescription)")
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
                        if (self.seniorityShowd == false && self.bidPeriod?.isHistoric?.boolValue == false) {
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
                        if (self.seniorityShowd == false && self.bidPeriod?.isHistoric?.boolValue == false) {
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
        let funcName = #function
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
            if (self.bidPeriod?.crewIdentifier?.intValue != self.bidPeriod?.swaptimizerIdentifier?.intValue) {
                self.enableOrDisableEOMButton()
                DispatchQueue.main.async {
                    AlertService.showAlertForTopVC(title: "SWAPtimizer loaded, but...", message: "There is a mismatch between the user for whom the bid package was downloaded (\(self.bidPeriod!.crewIdentifier?.stringValue ?? "")) and the user for whom the SWAPtimizer file is valid (\(self.bidPeriod!.swaptimizerIdentifier?.stringValue ?? "")).", actions: [(
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
            self.bidPeriod!.vacayAlertDisplayed = NSNumber(value: true)
        }
        else if (vacationType == "WBID" || vacationType == "WBIDF") {
            if (self.bidPeriod?.crewIdentifier?.intValue != self.bidPeriod?.swaptimizerIdentifier?.intValue) {
                DispatchQueue.main.async {
                    AlertService.showAlertForTopVC(title: "WBidmax loaded, but...", message: "There is a mismatch between the user for whom the bid package was downloaded (\(self.bidPeriod!.crewIdentifier?.stringValue ?? "")) and the user for whom the SWAPtimizer file is valid (\(self.bidPeriod!.swaptimizerIdentifier?.stringValue ?? "")).", actions: [(
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
            self.bidPeriod!.vacayAlertDisplayed = NSNumber(value: true)
        }
        else if (vacationType == "FAVacation" || vacationType == "FAVacationF") {
            if (self.bidPeriod?.crewIdentifier?.intValue != self.bidPeriod?.swaptimizerIdentifier?.intValue) {
                DispatchQueue.main.async {
                    AlertService.showAlertForTopVC(title: "Vacation loaded, but...", message: "There is a mismatch between the user for whom the bid package was downloaded (\(self.bidPeriod!.crewIdentifier?.stringValue ?? "")) and the user for whom the SWAPtimizer file is valid (\(self.bidPeriod!.swaptimizerIdentifier?.stringValue ?? "")).", actions: [(
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
        self.view.showActivityIndicator(color: UIColor.blue, message: "Contacting SWAPtimizer...")
        DispatchQueue.global(qos: .default).async {
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
        
        self.view.showActivityIndicator(message: "Contacting SWAPtimizer...")
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
                    self.disableVacationButton()
                    self.view.hideActivityIndicator()
                    self.btnSwaptimizer.isEnabled = true
                    self.btnWbidMax.isEnabled = true
                }
            }
        }
    }
    
    func selectWBidVacationButton() {
        let funcName = #function
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
        if app.isUserInformationAvailable() == false {
            self.disableVacationButton()
            AlertService.showAlertForTopVC(title: "CrewBid", message: "An internet connection is required to download the vacation file. Please connect to the internet and try again.")
            btnSwaptimizer.isEnabled = true
            btnWbidMax.isEnabled = true
            return
        }
        self.view.showActivityIndicator(message: "Contacting SWAPtimizer...")
        DispatchQueue.global(qos: .default).async {
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
//                self.sortsTableController.tableView.reloadData()
//                self.filtersTableController.objFilterTableView.reloadData()
                NotificationCenter.default.post(name: Notification.Name("refreshLines"), object: self)
                self.bidPeriod!.userVacationWbidOrCrewBid = ""
                self.disableVacationButton()
                self.view.hideActivityIndicator()
                self.btnSwaptimizer.isEnabled = true
                self.btnWbidMax.isEnabled = true
            }
        }
    }
    func showEOMAlert() {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM"
        if let vacations = self.bidPeriod?.vacations?.allObjects,
           let firstVacation = vacations.first as? BIVacation,
           let startDate = firstVacation.startDate,
           let endDate = firstVacation.endDate {
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
                let vacationEndDateDisp = formatter.string(from: exactVacEndDate)
                let alertMessage = "You have an `EOM` Vacation: \(vacationStartDateDisp) - \(vacationEndDateDisp).\n\nEOM weeks can affect the vacation pay in the current bid period and also the next month.\n\nWe have two documents regarding Month-to-Month vacations that also apply to EOM vacation weeks.\n\nWe suggest you read the following documents to improve your bidding knowledge."
                let storyboard = UIStoryboard(name: "BidActions", bundle: nil)
                let monthToMonthAlert = storyboard.instantiateViewController(withIdentifier: "CBMonthToMonthAlertVC") as! CBMonthToMonthAlertVC
                monthToMonthAlert.text = alertMessage
                monthToMonthAlert.showAlertFromViewController(from: self) { tappedOk in }
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
        if (app.isUserInformationAvailable() == false) {
            self.disableVacationButton()
            self.bidPeriod!.userVacationWbidOrCrewBid = ""
            AlertService.showAlertForTopVC(title: "CrewBid", message: "User information not available,you have to create user account to access WBidMax vacation. Please create user account by clicking on new bid period (+) from home screen.")
            btnWbidMax.isEnabled = true
            return
        }
        self.view.showActivityIndicator(message: "Contacting ...")
        DispatchQueue.global(qos: .default).async {
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
            }
            DispatchQueue.main.async {
//                self.sortsTableController.tableView.reloadData()
//                self.filtersTableController.objFilterTableView.reloadData()
                NotificationCenter.default.post(name: Notification.Name("refreshLines"), object: self)
                self.disableVacationButton()
                self.view.hideActivityIndicator()
                self.btnWbidMax.isEnabled = true
            }
        }
    }
    func executeEOMOnlyFA(vDL: CBVacationDownloader) {
        if (app.isUserInformationAvailable() == false) {
            self.disableVacationButton()
            self.bidPeriod!.userVacationWbidOrCrewBid = ""
            AlertService.showAlertForTopVC(title: "CrewBid", message: "User information not available,you have to create user account to access WBidMax vacation. Please create user account by clicking on new bid period (+) from home screen.")
            self.btnWbidMax.isEnabled = true
            return
        }
        self.view.showActivityIndicator(message: "Contacting ...")
        DispatchQueue.global(qos: .default).async {
            if self.eomSelectedIndex.isEmpty {
                vDL.EOMSelectedIndex = self.eomSelectedIndex
            }
            else {
                vDL.EOMSelectedIndex = self.bidPeriod!.faEomSelectedDate!.stringValue
            }
            vDL.downloadFaVacationWithOnlyEOMFilesWithHud() { finished in
                if finished {
                    if (self.bidPeriod!.containsVacay?.boolValue == true) {
                        self.selectWBidVacationButton()
                        self.setVacationBackgroundColor()
                        self.enableOrDisableEOMButton()
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
            }
//            self.sortsTableController.tableView.reloadData()
//            self.filtersTableController.objFilterTableView.reloadData()
            NotificationCenter.default.post(name: Notification.Name("refreshLines"), object: self)
            self.bidPeriod!.userVacationWbidOrCrewBid = ""
            self.disableVacationButton()
            self.view.hideActivityIndicator()
            self.btnWbidMax.isEnabled = true
        }
    }
    
    @objc func tableViewReloadForFAWithHud() {
        let condition1 = /*!self.btnEOM.isHidden && self.btnWbidMax.isSelected*/ false
        let condition2 = /*!self.btnEOM.isSelected*/ false
        let condition3 = /*!self.btnWbidMax.isSelected*/ false
        let condition4 = /*!self.manageVacationsEnabled*/ false
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
                    NotificationCenter.default.post(name: Notification.Name("refreshLines"), object: self)
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
                            self.perform(#selector(self.showAlertforVacationLoading), with: nil, afterDelay: 0.5)
                        }
                    }
                    catch {
                        print("error fetching \(error.localizedDescription)")
                    }
                }
            }
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name("refreshLines"), object: self)
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

        let funcName = #function

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
                    if self.bidPeriod!.isMaxSubScriptionOfEnteredUser?.boolValue == false {
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
            enableFAVacationF()
        } else if title == "\(eomMonth()) \(dayForFA["Day2"] ?? 0)" {
            bidPeriod!.faEomSelectedDate = 2
            eomSelectedIndex = "2"
            enableFAVacationF()
        } else if title == "\(eomMonth()) \(dayForFA["Day3"] ?? 0)" {
            bidPeriod!.faEomSelectedDate = 3
            eomSelectedIndex = "3"
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
        let funcName = #function
        self.bidPeriod!.currentDateTime = Date()
        self.bidPeriod!.isStateFileModifiedToSync = NSNumber(value: true)
        btnEOM.isSelected = true
        self.bidPeriod!.isEomOn = NSNumber(value: true)
        btnEOM.backgroundColor = UIColor(red: 35.0/255.0, green: 177.0/255.0, blue: 76.0/255.0, alpha: 1.0)
        btnEOM.setTitleColor(.white, for: .selected)
        let vDL = CBVacationDownloader()
        vDL.bidPeriod! = self.bidPeriod!
        vDL.calendarData = self.calendarData
        let vacationType = self.bidPeriod!.userVacationWbidOrCrewBid
        if (vacationType == "FAVacationEomOnly" || self.bidPeriod!.seniorityVacayAvailable?.boolValue == false) {
            self.executeEOMOnlyFA(vDL: vDL)
        }
        else {
            self.executeEOMOnlyFA(vDL: vDL)
        }
    }

    func wbidMaxErrorMessageEOM(isAutot: Bool) {
        return
    }
    
    func btnEOMAction(btnTemp: UIButton) {
        let funcName = #function
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
            if (self.bidPeriod!.seniorityVacayAvailable?.boolValue == false) {
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
            btnEOM.backgroundColor = UIColor(red: 35.0/255.0, green: 177.0/255.0, blue: 76.0/255.0, alpha: 1.0)
            btnEOM.setTitleColor(.white, for: .normal)
            btnSwaptimizer.backgroundColor = .white
            btnSwaptimizer.setTitleColor(.black, for: .normal)
        }
        if btnEOM.isSelected {
            // Added below code to set swaptimizer status
            if self.bidPeriod!.isSwaptimizerOn?.boolValue == true {
                self.bidPeriod!.userVacationWbidOrCrewBid = "CREWBIDF"
                self.eomVacationDateSelectForPilot(fromBtnAction: true)
                return
            }
            else if btnWbidMax.isSelected {
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
        let funcName = #function

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

        if title == "\(eomMonthString) \(String(describing: dayForPilot["Day1"]))" {
            bidPeriod!.faEomSelectedDate = 1
            eomSelectedIndex = "1"
            if bidPeriod!.isMaxSubScriptionOfEnteredUser?.boolValue == true {
//                checkSecretUser()
            } else {
                checkForSWAPtimizerFile()
            }

        } else if title == "\(eomMonthString) \(String(describing: dayForPilot["Day2"]))" {
            bidPeriod!.faEomSelectedDate = 2
            eomSelectedIndex = "2"
            if bidPeriod!.isMaxSubScriptionOfEnteredUser?.boolValue == true {
//                checkSecretUser()
            } else {
                checkForSWAPtimizerFile()
            }

        } else if title == "\(eomMonthString) \(String(describing: dayForPilot["Day3"]))" {
            bidPeriod!.faEomSelectedDate = 3
            eomSelectedIndex = "3"
            if bidPeriod!.isMaxSubScriptionOfEnteredUser?.boolValue == true {
//                checkSecretUser()
            } else {
                checkForSWAPtimizerFile()
            }
        }
    }

    func removeCurrentVacation() {
        DispatchQueue.main.async {
            self.view.showActivityIndicator(message: "Processing...")
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
            self.checkForSWAPtimizerFile()
        }
        else if self.bidPeriod!.vacationType == "CREWBID" {
            self.bidPeriod?.userVacationWbidOrCrewBid = "CREWBID"
            self.checkForSWAPtimizerFile()
        }
        else if self.bidPeriod!.vacationType == "WBID" {
            self.bidPeriod?.userVacationWbidOrCrewBid = "WBID"
            self.checkForSWAPtimizerFile()
        }
        else if self.bidPeriod!.vacationType == "WBIDF" {
            self.bidPeriod?.userVacationWbidOrCrewBid = "WBIDF"
            self.checkForSWAPtimizerFile()
        }
        else {
            self.showEomVacationConfirmationAlert()
        }
    }
    
    // To show this alert whenever open the bid from home screen.
    func showEomVacationConfirmationAlert() {
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
}

