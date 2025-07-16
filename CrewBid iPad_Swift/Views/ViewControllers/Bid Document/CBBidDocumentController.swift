//
//  CBBidDocumentController.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 18/03/25.
//

import UIKit
import CoreData

class CBBidDocumentController: BaseViewController {

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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.bidPeriod = CBGlobalMethods.shared.selectedBidPeriod
        setupUI()
        NotificationCenter.default.addObserver(self, selector: #selector(self.setupLayoutView), name: NSNotification.Name("SortBidListAction"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.setupLayoutViewForSwitch), name: NSNotification.Name("SyncSwitchStateAction"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showCommutablilityFilterView), name: Notification.Name("ShowCommutabilityFilterView"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ShowCommutablilitySortView), name: Notification.Name("ShowCommutabilitySortView"), object: nil)
        
        firstTimeBidOpen()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        NotificationCenter.default.addObserver(self, selector: #selector(bidLines), name: NSNotification.Name(CBLinesTableBidLinesNotification), object: nil)
        
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver("SortBidListAction")
        NotificationCenter.default.removeObserver("SyncSwitchStateAction")
        NotificationCenter.default.removeObserver("ShowCommutabilityFilterView")
    }
    
    @objc func bidLines(_ notification: Notification){
        let linesToBid = notification.userInfo![CBLinesTableBidLinesArrayKey]
        if notification.name.rawValue == CBLinesTableBidLinesFaAllNotification {
            //needs code for FA bids
        }else{
            if (self.bidLinesController.view.window == nil) && (!UserDefaults.standard.bool(forKey: kCBNoAutoswitchToBids)) {
                
            }
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
        if bidPeriod?.containsVacay?.boolValue == true {
            self.view.showActivityIndicator(message: "Processing Vacation Files")
            if bidPeriod?.isFABid() == true{
                DispatchQueue.main.asyncAfter(deadline: .now() + 7) {
                    NotificationCenter.default.post(name: Notification.Name("refreshLines"), object: nil)
                    self.view.hideActivityIndicator()
                }
            }
            else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
                    NotificationCenter.default.post(name: Notification.Name("refreshLines"), object: nil)
                    self.view.hideActivityIndicator()
                }
            }
        }
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
    
}
