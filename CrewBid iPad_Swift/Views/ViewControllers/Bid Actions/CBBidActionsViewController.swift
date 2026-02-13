//
//  CBBidActionsViewController.swift
//  CrewBid iPad_Swift
//
//  Created by Developer on 21/04/25.
//

import UIKit

class CBBidActionsViewController: BaseViewController, KUIPopOverUsable {
    
    var contentSize: CGSize {
        return CGSize(width: 400, height: 450)
    }
    
    @IBOutlet weak var btnBidAction: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var lblActionTitle: UILabel!
    
    
    lazy var employeeNum: UITextField = {
        let tf = UITextField()
        tf.keyboardType = .numberPad
        return tf
    }()
    
    lazy var comfirmEmployeeNum: UITextField = {
        let tf = UITextField()
        tf.keyboardType = .numberPad
        return tf
    }()
    
    var falistDict: [String: Any] = [:]
    var bidPeriod: BIBidPeriod?
    var isBuddingBiddingEnabled = false
    let arrForFAWithAwdTxt = ["Submit Bid","Show Bid Receipt","Show Awards","Show Bid File","Line Importer","Vacation","Retrieve Awards","swaSYNC","ReDownload Flt Data"]
    let arrForFAWithOutAwdTxt = ["Submit Bid","Show Bid Receipt","Retrieve Awards","Show Bid File","Line Importer","Vacation","swaSYNC","ReDownload Flt Data"]
    let arrForPilotWithAwdTxt = ["Submit Bid","Show Bid Receipt","Show Awards","Show Bid File","Line Importer","Vacation", "Show CAP","Retrieve Awards","Restore Last Bid","ReDownload Flt Data"]
    let arrForPilotWithOutAwdTxt = ["Submit Bid","Show Bid Receipt","Retrieve Awards","Show Bid File","Line Importer","Vacation","Show CAP","Restore Last Bid","ReDownload Flt Data"]
    
    let fileArrayFA = ["Cover Letter","Seniority List"/*,"Lines Text","Trips Text","FA Memo"*/]
    let fileArrayPilot = ["Cover Letter","Seniority List","Lines Text","Trips Text"]
    
    let vacPilotArray = ["Keep Pulled Trips In Filters/Sorts", "Hide Vacation in Scratchpad",/*"Check For",*/"Re-Download WBidMax Vac File","Re-Download Swaptimizer Vac File"]
    let vacationFAArray = ["Keep Pulled Trips In Filters/Sorts", "Hide Vacation in Scratchpad"]
    
    var bidActionTypeSelected : BidActionType = .BidActions
    var optionalEmployees = NSMutableArray ()
    var buddyTextField1: UITextField!
    var buddyTextField2: UITextField!
    var buddyTextField3: UITextField!
    var buddyNameLabel1: UILabel!
    var buddyNameLabel2: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.clipsToBounds = true
        self.tableView.layer.cornerRadius = 5
       setupUI()
    }
    
    func setupUI(){
        self.bidPeriod = CBGlobalMethods.shared.selectedBidPeriod
        btnBidAction.isHidden = true
        btnBidAction.setTitle("", for: .normal)
        NotificationCenter.default.addObserver(self, selector: #selector(saveStateToUserDefaults), name: Notification.Name("BidSubmissionCmpleted"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(contentSizeChange), name: Notification.Name("contentSizeChange"), object: nil)
    }
    
    @objc func contentSizeChange(notification: NSNotification) {
        if let size = notification.object as? CGSize {
            self.preferredContentSize = size
        }
    }
    @IBAction func switchAction(_ sender: UISwitch) {
        dismissFn()
        switch sender.tag{
        case 0:
            let currentValue = UserDefaults.standard.bool(forKey: kCBIncludeDroppedTripsInProcessingKey)
            if sender.isOn != currentValue{
                UserDefaults.standard.set(sender.isOn, forKey: kCBIncludeDroppedTripsInProcessingKey)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                NotificationCenter.default.post(name: NSNotification.Name("reprocessAfterChangedIncludeDroppedTrips"), object: self)
            }
        case 1:
            let currentValue = UserDefaults.standard.bool(forKey: kCBHideVacationKey)
            if sender.isOn != currentValue{
                UserDefaults.standard.set(sender.isOn, forKey: kCBHideVacationKey)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                NotificationCenter.default.post(name: NSNotification.Name("HideVacationScratchpad"), object: self)
            }
        default: break
        }
        
    }
    
    @IBAction func vacationCheckAction(_ sender: UISegmentedControl) {
        dismissFn()
        if sender.selectedSegmentIndex == 0{
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                NotificationCenter.default.post(name: NSNotification.Name("SwaptimizerAction"), object: self)
            }
        }else{
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                NotificationCenter.default.post(name: NSNotification.Name("WbidAction"), object: self)
            }
        }
        
        
    }
    @objc func saveStateToUserDefaults() {
        var stateValues = [AnyHashable : Any](minimumCapacity: 1)
        if self.bidPeriod?.lastBidDate != nil {
            stateValues[kCBBidDocumentLastBidDateKey] = bidPeriod!.lastBidDate
        }else{
            return
        }
    }
    
    @IBAction func btnBidActionTapped(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
}

extension CBBidActionsViewController: UITableViewDataSource, UITableViewDelegate{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch bidActionTypeSelected {
            case .BidActions:
                    // Hide the ShowCap option if it's a FA bid
                if !((bidPeriod?.isFABid())!) { //Pilot
                    let textFile = self.bidPeriod?.awardString
                    if textFile != nil { //With text
                        return arrForPilotWithAwdTxt.count
                    } else { //Without text
                        return arrForPilotWithOutAwdTxt.count
                    }
                } else { //FA
                    let textFile = self.bidPeriod?.awardString
                    if textFile != nil { //With text
                        return arrForFAWithAwdTxt.count
                    } else { //Without text
                        return arrForFAWithOutAwdTxt.count
                    }
                }
            case .ShowFile:
                    // Hide the FA Memo option if it's a pilot bid
                if !((bidPeriod?.isFABid())!) {
                    return fileArrayPilot.count
                } else {
                    return fileArrayFA.count
                }
            case .Vacation:
                if !((bidPeriod?.isFABid())!) {
                    return vacPilotArray.count
                } else {
                    return vacationFAArray.count
                }
                
            case .ShowReceipt:
                return self.bidPeriod?.bidReceipts?.allObjects.count ?? 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CBBidActionTableCell") as! CBBidActionTableCell
        switch bidActionTypeSelected {
        case .BidActions:
            let textFile = self.bidPeriod?.awardString
            if !((bidPeriod?.isFABid())!) { //Pilot
                if textFile != nil { //With text
                    cell.lblTitle.text = arrForPilotWithAwdTxt[indexPath.row]
                    cell.imgNext.image = UIImage(named: arrForPilotWithAwdTxt[indexPath.item])
                } else { //Without text
                    cell.lblTitle.text = arrForPilotWithOutAwdTxt[indexPath.row]
                    cell.imgNext.image = UIImage(named: arrForPilotWithOutAwdTxt[indexPath.item])
                }
            } else { //FA
                if textFile != nil { //With text
                    cell.lblTitle.text = arrForFAWithAwdTxt[indexPath.row]
                    cell.imgNext.image = UIImage(named: arrForFAWithAwdTxt[indexPath.item])
                } else { //Without text
                    cell.lblTitle.text = arrForFAWithOutAwdTxt[indexPath.row]
                    cell.imgNext.image = UIImage(named: arrForFAWithOutAwdTxt[indexPath.item])
                }
            }
            if cell.lblTitle.text == "Show Bid Receipt"{
                if bidPeriod?.bidReceipts?.allObjects.count == 0 {
                    cell.lblTitle.textColor  = .lightGray
                    cell.isUserInteractionEnabled = false
                }
            }
        case .ShowFile:
            lblActionTitle.text = "Show File"
            btnBidAction.isHidden = false
            btnBidAction.setTitle("Bid Actions", for: .normal)
            if self.bidPeriod?.isFABid() == true && self.bidPeriod?.isSwaAPI?.boolValue == true {
                if self.bidPeriod?.coverLetterFileName == nil || self.bidPeriod?.coverLetterFileName == "" {
                    cell.selectionStyle = .none
                    cell.isUserInteractionEnabled = false
                    cell.lblTitle.textColor = .lightGrey
                }
            }else{
                if self.bidPeriod?.textFile(withName: BICoverLetterTextFileName) == nil{
                    cell.selectionStyle = .none
                    cell.isUserInteractionEnabled = false
                    cell.lblTitle.textColor = .lightGrey
                }
            }
            
            if self.bidPeriod?.isFABid() == true && self.bidPeriod?.isSwaAPI?.boolValue == true {
                if self.bidPeriod?.seniorityList == nil || self.bidPeriod?.seniorityList?.count == 0 {
                    cell.selectionStyle = .none
                    cell.isUserInteractionEnabled = false
                    cell.lblTitle.textColor = .lightGrey
                }
            }else{
                if self.bidPeriod?.textFile(withName: BISeniorityListTextFileName) == nil{
                    cell.selectionStyle = .none
                    cell.isUserInteractionEnabled = false
                    cell.lblTitle.textColor = .lightGrey
                }
            }
            
            
            if !((bidPeriod?.isFABid())!) {
                cell.lblTitle.text = fileArrayPilot[indexPath.row]
                cell.imgNext.isHidden = true
            } else {
                cell.lblTitle.text = fileArrayFA[indexPath.row]
                cell.imgNext.isHidden = true
            }

        case .ShowReceipt:
            lblActionTitle.text = "Show Bid Receipt"
            let timeStampFormatter = DateFormatter()
            timeStampFormatter.dateStyle = .long
            timeStampFormatter.timeStyle = .short
            timeStampFormatter.doesRelativeDateFormatting = true
            cell.lblTitle.text = "1"
            if indexPath.row < self.bidPeriod!.sortedBidReceipts().count {
                let receipt = self.bidPeriod!.sortedBidReceipts()[indexPath.row]
                if let timeStampDate = receipt.timeStamp {
                    let timeStamp = timeStampFormatter.string(from: timeStampDate as Date)
                    let title = "\(receipt.submittedFor!) \(timeStamp)"
                    if title != ""{
                        cell.lblTitle.text = title
                    }
                    
                }
            }
            btnBidAction.isHidden = false
            btnBidAction.setTitle("Bid Actions", for: .normal)
            cell.imgNext.isHidden = true
            
        case .Vacation:
            lblActionTitle.text = "Vacation"
            btnBidAction.isHidden = false
            btnBidAction.setTitle("Bid Actions", for: .normal)
            if !((bidPeriod?.isFABid())!) {
                switch indexPath.row {
                case 0,1:
                    let switchTableViewCell = tableView.dequeueReusableCell(withIdentifier: "SwitchTableViewCell") as! SwitchTableViewCell
                    switchTableViewCell.selectionStyle = .none
                    switchTableViewCell.lblTitle.text = vacPilotArray[indexPath.row]
                    if (bidPeriod?.swaptimizerStatus?.intValue == Int(CBSwaptimizerStatus.enabled.rawValue) || bidPeriod?.faVacationStatus?.intValue == BIFaVacationStatus.enabled.rawValue) {
                        switchTableViewCell.isUserInteractionEnabled = true
                        switchTableViewCell.lblTitle.textColor = UIColor.appColor(.bid_actions)
                    }else{
                        switchTableViewCell.isUserInteractionEnabled = false
                        switchTableViewCell.lblTitle.textColor = .lightGray
                    }
                    if indexPath.row == 0{
                        switchTableViewCell.switch.isOn = UserDefaults.standard.bool(forKey: kCBIncludeDroppedTripsInProcessingKey)
                        switchTableViewCell.switch.tag = 0
                    }else if indexPath.row == 1{
                        switchTableViewCell.switch.isOn = UserDefaults.standard.bool(forKey: kCBHideVacationKey)
                        switchTableViewCell.switch.tag = 1
                    }
                    return switchTableViewCell
//                case 2:
//                    let segmentedTableViewCell = tableView.dequeueReusableCell(withIdentifier: "SegmentedTableViewCell") as! SegmentedTableViewCell
//                    segmentedTableViewCell.lblTitle.text = vacPilotArray[indexPath.row]
//                    return segmentedTableViewCell
                default:
                    break
                }
                cell.lblTitle.text = vacPilotArray[indexPath.row]
                cell.imgNext.isHidden = true
            } else {
                switch indexPath.row {
                case 0,1:
                    let switchTableViewCell = tableView.dequeueReusableCell(withIdentifier: "SwitchTableViewCell") as! SwitchTableViewCell
                    switchTableViewCell.lblTitle.text = vacationFAArray[indexPath.row]
                    if indexPath.row == 0{
                        switchTableViewCell.switch.isOn = UserDefaults.standard.bool(forKey: kCBIncludeDroppedTripsInProcessingKey)
                        switchTableViewCell.switch.tag = 0
                    }else if indexPath.row == 1{
                        switchTableViewCell.switch.isOn = UserDefaults.standard.bool(forKey: kCBHideVacationKey)
                        switchTableViewCell.switch.tag = 1
                    }
                    return switchTableViewCell
                default:
                    break;
                }
                cell.lblTitle.text = vacationFAArray[indexPath.row]
                cell.imgNext.isHidden = true
            }
        }
        if cell.lblTitle.text == "Line Importer"{
            if bidPeriod?.isBidListSortOn?.boolValue ?? false{
                cell.lblTitle.textColor  = .lightGray
                cell.isUserInteractionEnabled = false
            }
        }
        cell.selectionStyle = .none
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if bidActionTypeSelected == BidActionType.BidActions {
            if !((self.bidPeriod?.isFABid())!) {
                switch indexPath.row {
                    case 0: //Submit Bid
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            NotificationCenter.default.post(name: NSNotification.Name("checkLinesAvailableInBidList"), object: self)
                        }
                        self.dismissFn()
                        break
                    case 1:
                        if self.bidPeriod!.sortedBidReceipts().count > 0{
                            let storyboard : UIStoryboard = UIStoryboard(name: "BidActions", bundle: nil)
                            let vc = storyboard.instantiateViewController(withIdentifier: "CBBidActionsViewController") as! CBBidActionsViewController
                            vc.bidActionTypeSelected = BidActionType.ShowReceipt
                            self.navigationController?.pushViewController(vc, animated: true)
                        }
                        break
                    case 2://Retrieve/Show Awards
                    let textFile = self.bidPeriod?.awardString
                        if textFile != nil {
                            NotificationCenter.default.post(name: NSNotification.Name(KCBOpenAwardData), object: self)
                            dismissFn()
                        } else {
                                //retrieveAward()
                            dismissFn()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                NotificationCenter.default.post(name: NSNotification.Name(KCBOpenretrieveAwardDownloadPage), object: self)
                            }
                        }
                        break
                    case 3://Show Bid File
                        print("Show Bid File")
                        let storyboard : UIStoryboard = UIStoryboard(name: "BidActions", bundle: nil)
                        let vc = storyboard.instantiateViewController(withIdentifier: "CBBidActionsViewController") as! CBBidActionsViewController
                        vc.bidActionTypeSelected = BidActionType.ShowFile
                        self.navigationController?.pushViewController(vc, animated: true)
                        break
                    case 4://Line Importer
                        dismissFn()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            NotificationCenter.default.post(name: NSNotification.Name(KCBOpenLineImporter), object: self)
                        }
                        break
                    case 5://Vacation
                        let storyboard : UIStoryboard = UIStoryboard(name: "BidActions", bundle: nil)
                        let vc = storyboard.instantiateViewController(withIdentifier: "CBBidActionsViewController") as! CBBidActionsViewController
                        vc.bidActionTypeSelected = BidActionType.Vacation
                        self.navigationController?.pushViewController(vc, animated: true)
                        break
                    case 6://Show CAP
                        dismissFn()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            NotificationCenter.default.post(name: NSNotification.Name(KCBOpenShowCAP), object: self)
                        }
                        break
                    case 7://Retrieve/Show Awards
                        let cell = tableView.cellForRow(at: indexPath) as! CBBidActionTableCell
                        if cell.lblTitle.text == "Retrieve Awards" {
                                dismissFn()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    NotificationCenter.default.post(name: NSNotification.Name(KCBOpenretrieveAwardDownloadPage), object: self)
                                }
                        }else if cell.lblTitle.text == "Restore Last Bid" {
                            self.dismiss(animated: false, completion: nil)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                let notification = Notification(name: Notification.Name("RestoreLastBidNotification"), object: nil)
                                NotificationCenter.default.post(notification)
                            }
                        }
                        break
                    case 8:
                    let cell = tableView.cellForRow(at: indexPath) as! CBBidActionTableCell
                    if cell.lblTitle.text == "Restore Last Bid" {
                        self.dismiss(animated: false, completion: nil)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            let notification = Notification(name: Notification.Name("RestoreLastBidNotification"), object: nil)
                            NotificationCenter.default.post(notification)
                        }
                    }
                    else if cell.lblTitle.text == "ReDownload Flt Data" {
                        self.dismiss(animated: false, completion: nil)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            NotificationCenter.default.post(name: NSNotification.Name("redownloadFltData"), object: self)
                        }
                    }
                        break
                case 9:
                    self.dismiss(animated: false, completion: nil)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        NotificationCenter.default.post(name: NSNotification.Name("redownloadFltData"), object: self)
                    }
                    break
                        
                    default:
                        break
                    }
            } else {
                switch indexPath.row {
                    case 0: //Submit Bid
                        
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        NotificationCenter.default.post(name: NSNotification.Name("checkLinesAvailableInBidList"), object: self)
                    }
                    dismissFn()
                        break
                    case 2://Retrieve/Show Awards
                    let textFile = self.bidPeriod?.awardString
                        if textFile != nil {
                            NotificationCenter.default.post(name: NSNotification.Name(KCBOpenAwardData), object: self)
                            dismissFn()
                        } else {
                                //retrieveAward()
                            dismissFn()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                NotificationCenter.default.post(name: NSNotification.Name(KCBOpenretrieveAwardDownloadPage), object: self)
                            }
                        }
                        break
                    case 3://Show Bid File
                        print("Show Bid File")
                        let storyboard : UIStoryboard = UIStoryboard(name: "BidActions", bundle: nil)
                        let vc = storyboard.instantiateViewController(withIdentifier: "CBBidActionsViewController") as! CBBidActionsViewController
                        vc.bidActionTypeSelected = BidActionType.ShowFile
                        self.navigationController?.pushViewController(vc, animated: true)
                        break
                    case 4://Line Importer
                        dismissFn()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            NotificationCenter.default.post(name: NSNotification.Name(KCBOpenLineImporter), object: self)
                        }
                        break
                    case 5://Vacation
                        let storyboard : UIStoryboard = UIStoryboard(name: "BidActions", bundle: nil)
                        let vc = storyboard.instantiateViewController(withIdentifier: "CBBidActionsViewController") as! CBBidActionsViewController
                        vc.bidActionTypeSelected = BidActionType.Vacation
                        self.navigationController?.pushViewController(vc, animated: true)
                        break
                    case 1://Show Bid Receipt
                        if self.bidPeriod!.sortedBidReceipts().count > 0{
                            let storyboard : UIStoryboard = UIStoryboard(name: "BidActions", bundle: nil)
                            let vc = storyboard.instantiateViewController(withIdentifier: "CBBidActionsViewController") as! CBBidActionsViewController
                            vc.bidActionTypeSelected = BidActionType.ShowReceipt
                            self.navigationController?.pushViewController(vc, animated: true)
                        }
                        break
                    case 6://Retrieve Awards
                        let cell = tableView.cellForRow(at: indexPath) as! CBBidActionTableCell
                        if cell.lblTitle.text == "Retrieve Awards" {
                            dismissFn()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                NotificationCenter.default.post(name: NSNotification.Name(KCBOpenretrieveAwardDownloadPage), object: self)
                            }
                        }else if cell.lblTitle.text == "swaSYNC" {
                            self.dismiss(animated: false, completion: nil)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                let notification = Notification(name: Notification.Name("RestoreLastBidNotification"), object: nil)
                                           NotificationCenter.default.post(notification)
                            }
                        }
                        break
                    case 7 :
                    let cell = tableView.cellForRow(at: indexPath) as! CBBidActionTableCell
                    if cell.lblTitle.text == "swaSYNC" {
                        self.dismiss(animated: false, completion: nil)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            let notification = Notification(name: Notification.Name("RestoreLastBidNotification"), object: nil)
                            NotificationCenter.default.post(notification)
                        }
                    }
                    else if cell.lblTitle.text == "ReDownload Flt Data" {
                        self.dismiss(animated: false, completion: nil)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            NotificationCenter.default.post(name: NSNotification.Name("redownloadFltData"), object: self)
                        }

                    }
                        break
                case 8 :
                    self.dismiss(animated: false, completion: nil)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        NotificationCenter.default.post(name: NSNotification.Name("redownloadFltData"), object: self)
                    }
                    break
                    default:
                        break
                        
                }
            }
        }
        if bidActionTypeSelected == BidActionType.ShowFile {
            switch indexPath.row {
            case 0: //Coverletter
                //dismissFn()
                let details = ["isFromFirstTimeOpenBid":false]
                if self.bidPeriod?.isFABid() == true && self.bidPeriod?.isSwaAPI?.boolValue == true {
                    // Open PDF with Quick Look
                    self.dismiss(animated: false) {
                        NotificationCenter.default.post(name: NSNotification.Name("KCBOpenCoverletterForFA"), object: nil)
                        
                    }
                }else{
                    self.dismiss(animated: false) {
                        NotificationCenter.default.post(name: NSNotification.Name(KCBOpenCoverletter), object: self,userInfo: details)
                    }
                }

                break
            case 1: //Seniority
                //dismissFn()
                self.dismiss(animated: false) {
                    NotificationCenter.default.post(name: NSNotification.Name(KCBOpenSeniority), object: self)
                }
                break
            case 2: //LineText
                //dismissFn()
                self.dismiss(animated: false) {
                    NotificationCenter.default.post(name: NSNotification.Name(KCBOpenLineText), object: self)
                }
                break
            case 3: //TripText
                //dismissFn()
                self.dismiss(animated: false) {
                    NotificationCenter.default.post(name: NSNotification.Name(KCBOpenTripText), object: self)
                }
                break
            case 4: //FAMemo
                //dismissFn()
                self.dismiss(animated: false) {
                    NotificationCenter.default.post(name: NSNotification.Name(KCBOpenFAMemo), object: self)
                }
                break
            default:
                break
            }
        }
        if bidActionTypeSelected == BidActionType.ShowReceipt {
            self.dismiss(animated: true, completion: nil)
            let recipt = self.bidPeriod!.sortedBidReceipts()[indexPath.row]
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                NotificationCenter.default.post(name: NSNotification.Name("showBidReceiptWithObject"), object: recipt)

            }
        }
        if bidActionTypeSelected == BidActionType.Vacation{
            if !((bidPeriod?.isFABid())!) {
                switch indexPath.row {
                case 0,1:
                    break
                case 2:
                    dismissFn()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            if (self.bidPeriod?.vacationArrayFromServer?.count ?? 0) > 0 {
                                NotificationCenter.default.post(name: NSNotification.Name("downloadWbidMax"), object: self)
                            } else {
                                // Dismiss any previously presented view controllers
                                self.dismiss(animated: true, completion: {
                                    AlertService.showAlertForTopVC(title: "WbidMax Error", message: "You do not have Vacation this month")
                                })
                            }
                        }
                
                    break
                case 3:
                    dismissFn()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        if (self.bidPeriod?.vacationArrayFromServer?.count ?? 0) > 0 {
                            NotificationCenter.default.post(name: NSNotification.Name("downloadSwaptimizer"), object: self)
                        }else {
                            // Dismiss any previously presented view controllers
                            self.dismiss(animated: true, completion: {
                                AlertService.showAlertForTopVC(title: "Swaptimizer Error", message: "You do not have Vacation this month")
                            })
                        }
                    }
                    break
                default:
                    break
                }
            }else{
                if indexPath.row == 1{
                    
                }
            }
        }
    }
                                          

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 45
    }
    
    
    func submitBidAlert() {
        let alert = UIAlertController(
            title: "Submit Bid",
            message: "To confirm, please enter the Employee number again.",
            preferredStyle: .alert
        )
        alert.addTextField { textField in
            textField.placeholder = "Employee Number"
            self.comfirmEmployeeNum = textField
        }
        
        //cancel
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        //add
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            self.ConfirmSubmitBidAlert()
        }
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    func ConfirmSubmitBidAlert() {
        if self.comfirmEmployeeNum.text == self.employeeNum.text {
            let alert = UIAlertController(
                title: "Alert",
                message: "If you are Buddy Bidding you need to verify that you are buddy bidders on your Buddy list, and they know you are buddy bidding with them.",
                preferredStyle: .alert
            )
            let buddyBiddingAction = UIAlertAction(title: "I have Verified", style: .default) { _ in
                self.buddyBidSelected()
            }
            let notBuddyBiddingAction = UIAlertAction(title: "I am not Buddy Bidding", style: .default) { _ in
                self.buddyBidNotSelected()
            }
            alert.addAction(buddyBiddingAction)
            alert.addAction(notBuddyBiddingAction)
            present(alert, animated: true)
        }
        
        else {
            let alert = UIAlertController(
                title: "Alert",
                message: "The entered employee number does not match the original entry. Please check and try again.",
                preferredStyle: .alert
            )
            let cancelAction = UIAlertAction(title: "OK", style: .cancel)
            alert.addAction(cancelAction)
            present(alert, animated: true)
        }
    }
    
    func buddyBidSelected() {
        let storyboard = UIStoryboard(name: "BidActions", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBOptionalEmployeesPageViewController") as! CBOptionalEmployeesPageViewController
        vc.bidPeriod = self.bidPeriod!
        vc.preferredContentSize = CGSize(width: 600, height: 500)
        present(vc, animated: true)
    }
    
    func buddyBidNotSelected() {
//        self.finalAlert()
        let storyboard = UIStoryboard(name: "BidActions", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBSubmitCredentialVC") as! CBSubmitCredentialVC
        vc.preferredContentSize = CGSize(width: 600, height: 500)
        present(vc, animated: true)
        self.finalAlert()
    }
    
    func finalAlert() {
        let alert = UIAlertController(
            title: "Buddy Bidding Terms",
            message: "By continuing, you represent that you have the permission of your buddy or buddies to Buddy Bid with them and you have taken the necessary steps inSwA lite to out them on vour BuddyBidding list.I Understand and Accept",
            preferredStyle: .alert
        )
        let cancelAction = UIAlertAction(title: "OK", style: .cancel)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
}

