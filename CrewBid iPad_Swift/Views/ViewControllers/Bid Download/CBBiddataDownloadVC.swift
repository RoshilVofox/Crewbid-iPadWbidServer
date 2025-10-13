//
//  CBBiddataDownloadVC.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 20/03/25.
//

import UIKit
import CoreData

class CBBiddataDownloadVC: BaseViewController {
    
    // base
    @IBOutlet weak var btnATL: dataDownloadingButton!
    @IBOutlet weak var btnBNA: dataDownloadingButton!
    @IBOutlet weak var btnBWI: dataDownloadingButton!
    @IBOutlet weak var btnDAL: dataDownloadingButton!
    @IBOutlet weak var btnDEN: dataDownloadingButton!
    @IBOutlet weak var btnHOU: dataDownloadingButton!
    @IBOutlet weak var btnLAS: dataDownloadingButton!
    @IBOutlet weak var btnLAX: dataDownloadingButton!
    @IBOutlet weak var btnMCO: dataDownloadingButton!
    @IBOutlet weak var btnMDW: dataDownloadingButton!
    @IBOutlet weak var btnOAK: dataDownloadingButton!
    @IBOutlet weak var btnPHX: dataDownloadingButton!
    // position
    @IBOutlet weak var btnCP: dataDownloadingButton!
    @IBOutlet weak var btnFO: dataDownloadingButton!
    @IBOutlet weak var btnFA: dataDownloadingButton!
    // round
    @IBOutlet weak var btnFirstRound: dataDownloadingButton!
    @IBOutlet weak var btnSecondRound: dataDownloadingButton!
    // month
    @IBOutlet weak var btnJAN: dataDownloadingButton!
    @IBOutlet weak var btnFEB: dataDownloadingButton!
    @IBOutlet weak var btnMAR: dataDownloadingButton!
    @IBOutlet weak var btnAPR: dataDownloadingButton!
    @IBOutlet weak var btnMAY: dataDownloadingButton!
    @IBOutlet weak var btnJUN: dataDownloadingButton!
    @IBOutlet weak var btnJUL: dataDownloadingButton!
    @IBOutlet weak var btnAUG: dataDownloadingButton!
    @IBOutlet weak var btnSEP: dataDownloadingButton!
    @IBOutlet weak var btnOCT: dataDownloadingButton!
    @IBOutlet weak var btnNOV: dataDownloadingButton!
    @IBOutlet weak var btnDEC: dataDownloadingButton!
    // year
    @IBOutlet weak var btnBeforePrevious: dataDownloadingButton!
    @IBOutlet weak var btnPreviousYear: dataDownloadingButton!
    @IBOutlet weak var btnCurrentYear: dataDownloadingButton!
    
    @IBOutlet weak var viewBase: UIView!
    @IBOutlet weak var viewPosition: UIView!
    @IBOutlet weak var viewRound: UIView!
    @IBOutlet weak var viewMonth: UIView!
    @IBOutlet weak var viewYear: UIView!
    
    @IBOutlet weak var lblTitle: UILabel!
    var selectedRound: Int?
    var selectedPosition : String?
    var empNum : String?
    var selectedDomicile : String?
    var month :  Int?
    var isHistoricBid : Bool = false
    var loginType: LoginType = .newBid
    var isNewBid : Bool = false
    var year : Int?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        AppState.shared.jsonSecretIsOn = true
        setupUI()
        if isHistoricBid {
            self.setYearTitle()
            self.setEnabledMonthForHistoricBidData()
        }
    }
    
    @IBAction func btnNextAction(_ sender: UIButton) {
        if selectedDomicile == nil {
            self.shakeView(view: self.viewBase)
        } else if selectedPosition == nil {
            self.shakeView(view: self.viewPosition)
        } else if selectedRound == nil {
            self.shakeView(view: self.viewRound)
        } else if month == nil {
            self.shakeView(view: self.viewMonth)
        } else if year == nil {
            self.shakeView(view: self.viewYear)
        } else {
            
//            if self.bidAlreadyExists(){
//                self.showAlertForExistingBid {
//                    print("")
//                }
//            }
            AppData.shared.Round = self.selectedRound!
            AppData.shared.postion = self.selectedPosition!
            let emp = UserDefaults.standard.string(forKey: kCBDefaultEmployeeNumberKey)!
            print("Base:\(self.selectedDomicile!) Position:\(self.selectedPosition!) Rnd:\(self.selectedRound!) EmpNo:\(self.empNum ?? emp) Month:\(self.month!) Year:\(self.year!)")
            GlobalBidInfo.shared.base = self.selectedDomicile!
            if let positionCode = self.selectedPosition, let position = BICrewPositionType(from: positionCode){
                GlobalBidInfo.shared.position = position
            }
            GlobalBidInfo.shared.employeeNumber = self.empNum ?? emp
            GlobalBidInfo.shared.round = self.selectedRound!
            let isQATest = UserDefaults.standard.bool(forKey: "isQATest")
            if isQATest == true {
                let qaMonth = UserDefaults.standard.string(forKey: "QATestMonth") ?? "0"
                let qaYear = UserDefaults.standard.string(forKey: "QATestYear") ?? "0"
                GlobalBidInfo.shared.month = Int(qaMonth)!
                GlobalBidInfo.shared.year = Int(qaYear)!
            }
            else {
                GlobalBidInfo.shared.month = self.month!
                GlobalBidInfo.shared.year = self.year!
            }
            
//=======================================
            AppState.shared.mockDataMonth = self.month
            AppState.shared.mockDataYear = self.year
            let storyboard = UIStoryboard(name: "BidInfo", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "CBCredentialsPageVC") as! CBCredentialsPageVC
            vc.isNewBid = self.isNewBid
            vc.isHistoricBid = self.isHistoricBid
            vc.selectedDomicile = self.selectedDomicile
            if let positionCode = self.selectedPosition, let position = BICrewPositionType(from: positionCode){
                vc.selectedPosition = position
            }
            vc.selectedRound = self.selectedRound
            vc.empNum = self.empNum
            vc.month = self.month
            vc.year = self.year
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    
//    private func bidAlreadyExists() -> Bool {
//        var status = false
//        let context = CoreDataManager.shared.managedObjectContext
//        let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
//        let entity = NSEntityDescription.entity(forEntityName: "BidPeriod", in: context)
//        fetchRequest.entity = entity
//        let positionCode = self.selectedPosition!
//        let position = BICrewPositionType(from: positionCode)
//        var array:[NSPredicate] = []
//        array.append(NSPredicate(format: "base == %@", self.selectedDomicile!))
//        array.append(NSPredicate(format: "round == %d", self.selectedRound!))
//        array.append(NSPredicate(format: "month == %d", self.month!))
//        array.append(NSPredicate(format: "positionType == %d", position!.rawValue))
//        array.append(NSPredicate(format: "year == %d", self.year!))
//        
//        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: array)
//        let list = try! context.fetch(fetchRequest) as! [BIBidPeriod]
//        if list.count > 0 {
//            status = true
//        }
//        return status
//    }
//    
//    private func showAlertForExistingBid(onRetry: @escaping () -> Void) {
//        let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
//        let context = CoreDataManager.shared.managedObjectContext
//        let positionCode = self.selectedPosition!
//        let position = BICrewPositionType(from: positionCode)
//        let entity = NSEntityDescription.entity(forEntityName: "BidPeriod", in: context)
//        fetchRequest.entity = entity
//        var array:[NSPredicate] = []
//        array.append(NSPredicate(format: "base == %@", self.selectedDomicile!))
//        array.append(NSPredicate(format: "round == %d", self.selectedRound!))
//        array.append(NSPredicate(format: "month == %d", self.month!))
//        array.append(NSPredicate(format: "positionType == %d", position!.rawValue))
//        array.append(NSPredicate(format: "year == %d", self.year!))
//        
//        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: array)
//        let list = try! context.fetch(fetchRequest) as! [BIBidPeriod]
//        
//        let monthArr = ["January", "February", "March", "April", "May", "June", "July", "August","September","October","November","December"]
//        let alert = AlertService.showAlert(title: "Download Bid Again?", message: "The Bid for \(monthArr[self.month!-1]) \(self.selectedDomicile!) \(position!) Round \(self.selectedRound!) already exists. If you download it again, all existing data, including bid receipts, will be removed.", actions: [(title: "Download Again", style: .default, handler: {_ in
//            
//            // Build file path
//            let tempDir = BIBidInfo.temporaryDirectory()
//            let originalFileName = BIBidInfo.shared.dataFilenameBase()
//            let fileURL = tempDir.appendingPathComponent(originalFileName)
//             
//            // Delete the file if it exists
//            let fileManager = FileManager.default
//            if fileManager.fileExists(atPath: fileURL.path) {
//                do {
//                    try fileManager.removeItem(at: fileURL)
//                    print("Deleted file: \(fileURL.lastPathComponent)")
//                } catch {
//                    print("Failed to delete file: \(error.localizedDescription)")
//                }
//            }
//            if list.count > 0 {
//                let obj = list[0]
//                context.delete(obj)
//                do {
//                    try context.save()
//                } catch {
//                    print("Failed to save context after deletion: \(error)")
//                }
////                NotificationCenter.default.post(name: NSNotification.Name(ReloadCollectionView), object: nil)
//                onRetry()
//            }
//            
//        }), (title: "Cancel", style: .cancel, handler: {_ in}), (title: "Open Bid", style: .default, handler: {_ in
//            if list.count > 0 {
//                let obj = list[0]
//                CBGlobalMethods.shared.selectedBidPeriod = obj
//                UserDefaults.standard.setValue(obj.round!.intValue, forKey: "SelectedRound")
//                self.dismiss(animated: true)
//                self.loginActions()
//                NotificationCenter.default.post(name: NSNotification.Name("openBidPeriodFromDownloadPage"), object: nil)
//            }
//            
//        })])
//        self.present(alert, animated: true)
//    }
    
    
    
    @IBAction func btnBackAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func btnBaseAction(_ sender: UIButton) {
        // Iterate over a range of button tags
        for i in (40..<52) {
            if i == (sender as AnyObject).tag {
                // Update the selected domicile based on the button title
                selectedDomicile = sender.titleLabel!.text!
                let button = self.view.viewWithTag(i) as! UIButton
                button.backgroundColor = UIColor.systemOrange
            } else {
                // Reset background color for other buttons
                let button = self.view.viewWithTag(i) as! UIButton
                if #available(iOS 13.0, *) {
                    button.backgroundColor = .secondarySystemBackground
                } else {
                    button.backgroundColor = .white
                }
                
            }
        }

        print("Base: \(selectedDomicile!)")
        proceedIfReady()
    }
    
    @IBAction func btnPositionAction(_ sender: UIButton) {
        for i in (14..<17) {
            if i == (sender as AnyObject).tag {
                let button = self.view.viewWithTag(i) as! UIButton
                button.backgroundColor = UIColor.systemOrange
            } else {
                let button = self.view.viewWithTag(i) as! UIButton
                if #available(iOS 13.0, *) {
                    button.backgroundColor = .secondarySystemBackground
                } else {
                    button.backgroundColor = .white
                }
            }
        }
        switch sender.tag {
        case 14:selectedPosition = "CP"
        case 15:selectedPosition = "FO"
        case 16:selectedPosition = "FA"
        default:break
        }
        
        print("Position: \(selectedPosition!)")
        proceedIfReady()
    }
    
    @IBAction func btnRoundAction(_ sender: UIButton) {
        for i in (17..<19) {
            if i == (sender as AnyObject).tag {
                let button = self.view.viewWithTag(i) as! UIButton
                button.backgroundColor = UIColor.systemOrange
            } else {
                let button = self.view.viewWithTag(i) as! UIButton
                if #available(iOS 13.0, *) {
                    button.backgroundColor = .secondarySystemBackground
                } else {
                    button.backgroundColor = .white
                }
            }
        }
        switch sender.tag {
        case 17:selectedRound = 1
        case 18:selectedRound = 2
        default:break
        }
        print("Round: \(selectedRound!)")
        proceedIfReady()
    }
    
    @IBAction func btnMonthAction(_ sender: UIButton) {
        for i in (1..<13) {
            if i == (sender as AnyObject).tag {
                let button = self.view.viewWithTag(i) as! UIButton
                button.backgroundColor = UIColor.systemOrange
            } else {
                let button = self.view.viewWithTag(i) as! UIButton
                if #available(iOS 13.0, *) {
                    button.backgroundColor = .secondarySystemBackground
                } else {
                    button.backgroundColor = .white
                }
            }
        }
        switch sender.tag {
        case 1:month = 1
        case 2:month = 2
        case 3:month = 3
        case 4:month = 4
        case 5:month = 5
        case 6:month = 6
        case 7:month = 7
        case 8:month = 8
        case 9:month = 9
        case 10:month = 10
        case 11:month = 11
        case 12:month = 12
        default:break
        }
        print("Month: \(month!)")
        proceedIfReady()
    }
    
    @IBAction func btnYearAction(_ sender: UIButton) {
        month = nil
        // Reset background color for all month buttons
        
                for i in (1..<13) {
                    let button = self.view.viewWithTag(i) as! UIButton
                    if #available(iOS 13.0, *) {
                        button.backgroundColor = .secondarySystemBackground
                    } else {
                        button.backgroundColor = .white
                    }
                }
        // Iterate over a range of button tags representing years
        
        for i in (60..<63) {
            if i == (sender as AnyObject).tag {
                let button = self.view.viewWithTag(i) as! UIButton
                button.backgroundColor = UIColor.systemOrange
            } else {
                let button = self.view.viewWithTag(i) as! UIButton
                if #available(iOS 13.0, *) {
                    button.backgroundColor = .secondarySystemBackground
                } else {
                    button.backgroundColor = .white
                }
            }
        }
        if sender.tag == 60{
            let currentDate = Date()
            let indexYear = Calendar.current.component(.year, from: currentDate)
            year = indexYear - 2
            if isHistoricBid{
                let btnArray:[UIButton] = [btnJAN,btnFEB,btnMAR,btnAPR,btnMAY,btnJUN,btnJUL,btnAUG,btnSEP,btnOCT,btnNOV,btnDEC]
                for button in btnArray{
                    button.isUserInteractionEnabled = true
                    button.alpha = 1
                }
            }
        }else if sender.tag == 61{
            let currentDate = Date()
            let indexYear = Calendar.current.component(.year, from: currentDate)
            year = indexYear - 1
            if isHistoricBid{
                let btnArray:[UIButton] = [btnJAN,btnFEB,btnMAR,btnAPR,btnMAY,btnJUN,btnJUL,btnAUG,btnSEP,btnOCT,btnNOV,btnDEC]
                for button in btnArray{
                    button.isUserInteractionEnabled = true
                    button.alpha = 1
                }
            }
        }else if sender.tag == 62{
            let currentDate = Date()
            let indexYear = Calendar.current.component(.year, from: currentDate)
            year = indexYear
            if isHistoricBid{
                let btnArray:[UIButton] = [btnJAN,btnFEB,btnMAR,btnAPR,btnMAY,btnJUN,btnJUL,btnAUG,btnSEP,btnOCT,btnNOV,btnDEC]
                let monthInt = Calendar.current.component(.month, from: Date())
                let currentMonth:Int = monthInt
                for button in btnArray{
                    if button.tag > currentMonth{
                        button.isUserInteractionEnabled = false
                        button.alpha = 0.3
                    }
                }
            }
        }
        proceedIfReady()
    }
    
    func currentYear() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy"
        let year = dateFormatter.string(from: Date())
        return year
    }
    
    func currentMonth() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM"
        let year = dateFormatter.string(from: Date())
        return year
    }
    
    func setEnabledMonthForHistoricBidData() {
        let currentMonth = Int(self.currentMonth())
        let buttonLastBidMonth = self.view.viewWithTag(currentMonth!) as! UIButton
        self.btnMonthAction(buttonLastBidMonth)
    }
    
    func setYearTitle() {
        let buttonYearBeforeLast = self.view.viewWithTag(60) as! UIButton
        buttonYearBeforeLast.setTitle(String(Int(self.currentYear())! - 2), for: .normal)
        let buttonYearLast = self.view.viewWithTag(61) as! UIButton
        buttonYearLast.setTitle(String(Int(self.currentYear())! - 1), for: .normal)
        let buttonYearCurrent = self.view.viewWithTag(62) as! UIButton
        buttonYearCurrent.setTitle(self.currentYear(), for: .normal)
        self.btnYearAction(buttonYearCurrent)
    }
    
    func setupUI(){
        //Title setup
        if isHistoricBid == true {
            lblTitle.text = "Historic Bid Data"
            loginType = .historicBid
        }else{
            lblTitle.text = "New Bid Data"
        }
        let nextMonthDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())!
        let indexMonth = Calendar.current.component(.month, from: nextMonthDate)
        let indexYear = Calendar.current.component(.year, from: nextMonthDate)
        let year = CBUtils.getYearforBid(month: indexMonth, year: indexYear)
        btnBeforePrevious.setTitle("\(year-2)", for: .normal)
        btnPreviousYear.setTitle("\(year-1)", for: .normal)
        btnCurrentYear.setTitle("\(year)", for: .normal)
        month = indexMonth
        self.year = year
        if month == 12{
            self.year = year - 1
        }
        
        
        if !isHistoricBid {
            //Year view hiding for new bid period
            viewYear.isHidden = true
            let btnArray : [UIButton] = [btnJAN,btnFEB,btnMAR,btnAPR,btnMAY,btnJUN,btnJUL,btnAUG,btnSEP,btnOCT,btnNOV,btnDEC]
            let monthInt = Calendar.current.component(.month, from: Date())
            var bidMonth: Int = monthInt + 1
            for button in btnArray {
                if button.tag < bidMonth {
                    button.isUserInteractionEnabled = false
                    button.alpha = 0.3
                }
                if button.tag > bidMonth {
                    button.isUserInteractionEnabled = false
                    button.alpha = 0.3
                }
                if button.tag == bidMonth {
                    button.backgroundColor = UIColor.systemOrange
                }
                if bidMonth == 13 {
                    bidMonth = 1
                    if button.tag == bidMonth {
                        button.isUserInteractionEnabled = true
                        button.backgroundColor = UIColor.systemOrange
                        button.alpha = 1.0
                    }
                }
            }
        }
        if isHistoricBid {
            viewYear.isHidden = false
            let btnArray : [UIButton] = [btnJAN,btnFEB,btnMAR,btnAPR,btnMAY,btnJUN,btnJUL,btnAUG,btnSEP,btnOCT,btnNOV,btnDEC]
            let monthInt = Calendar.current.component(.month, from: Date())
            let bidMonth: Int = monthInt
            for button in btnArray {
                if button.tag > bidMonth {
                    button.isUserInteractionEnabled = false
                    button.alpha = 0.3
                }
                if button.tag == bidMonth {
                    button.backgroundColor = UIColor.systemOrange
                }
            }
            let btnYearArray : [UIButton] = [btnBeforePrevious,btnPreviousYear,btnCurrentYear]
            //            for btn in btnYearArray  {
            //                if btn.titleLabel?.text == "\(year)" {
            //                    btn.backgroundColor = UIColor.systemOrange
            //                }
            //            }
        }

        
    }
    func shakeView(view: UIView){
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.07
        animation.repeatCount = 3
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint(x: view.center.x - 10, y: view.center.y))
        animation.toValue = NSValue(cgPoint: CGPoint(x: view.center.x + 10, y: view.center.y))
        view.layer.add(animation, forKey: "position")
    }
    
    //Automatic navigation
    private func proceedIfReady() {
        guard let selectedDomicile = selectedDomicile,
              let selectedPosition = selectedPosition,
              let selectedRound = selectedRound,
              let month = month,
              let year = year else {
            return
        }
        
        // Save to shared data
        AppData.shared.Round = selectedRound
        AppData.shared.postion = selectedPosition
        
        let emp = UserDefaults.standard.string(forKey: kCBDefaultEmployeeNumberKey) ?? ""
        print("Base:\(selectedDomicile) Position:\(selectedPosition) Rnd:\(selectedRound) EmpNo:\(self.empNum ?? emp) Month:\(month) Year:\(year)")
        
        GlobalBidInfo.shared.base = selectedDomicile
        if let position = BICrewPositionType(from: selectedPosition) {
            GlobalBidInfo.shared.position = position
        }
        GlobalBidInfo.shared.employeeNumber = self.empNum ?? emp
        GlobalBidInfo.shared.round = selectedRound
        GlobalBidInfo.shared.month = month
        GlobalBidInfo.shared.year = year
        
        AppState.shared.mockDataMonth = month
        AppState.shared.mockDataYear = year
        
        // Navigate
        let storyboard = UIStoryboard(name: "BidInfo", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBCredentialsPageVC") as! CBCredentialsPageVC
        vc.isNewBid = self.isNewBid
        vc.isHistoricBid = self.isHistoricBid
        vc.selectedDomicile = selectedDomicile
        if let position = BICrewPositionType(from: selectedPosition) {
            vc.selectedPosition = position
        }
        vc.selectedRound = selectedRound
        vc.empNum = self.empNum
        vc.month = month
        vc.year = year
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
