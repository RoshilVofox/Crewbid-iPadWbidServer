//
//  SettingsViewController.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 19/04/25.
//

import UIKit

class SettingsViewController: BaseViewController,KUIPopOverUsable {
    
    var contentSize: CGSize {
        return CGSize(width: 300, height: self.bdPrd == 0 ? 376 : 400)
    }

    
    @IBOutlet weak var viewBG: UIView!
    @IBOutlet weak var syncSwitch: UISwitch!
    @IBOutlet weak var amPmTime: UITextField!
    @IBOutlet weak var amPmTimeLabel: UILabel!
    @IBOutlet weak var amPmView: UIView!
    @IBOutlet weak var firstTakeOffBtn: UIButton!
    @IBOutlet weak var reportTimeBtn: UIButton!
    @IBOutlet weak var myCalView: UIView!
    @IBOutlet weak var myCalViewHeight: NSLayoutConstraint!
    @IBOutlet weak var myCalSwitch: UISwitch!
    @IBOutlet weak var myCalButton: UIButton!
    @IBOutlet weak var startDatePicker: UIDatePicker!
    @IBOutlet weak var endDatePicker: UIDatePicker!
    @IBOutlet weak var brightnessView: UIView!
    
    var bidPeriod: BIBidPeriod?
    var bdPrd:Int!
    var calendarData = BICalendarData()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewBG.layer.cornerRadius = 5
        viewBG.layer.masksToBounds = true
        setSwitchState()
        setUiForCell()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        brightnessView.isUserInteractionEnabled = true
        brightnessView.addGestureRecognizer(tapGesture)
    }
    
    @IBAction func syncAction(_ sender: Any) {
        if self.syncSwitch.isOn {
            AppData.shared.isSyncOn = true
        }
        else {
            AppData.shared.isSyncOn = false
        }
        NotificationCenter.default.post(name: Notification.Name("SyncSwitchStateAction"), object: nil)
    }
    
    @IBAction func firstTakeOffBtnAction(_ sender: Any) {
        UserDefaults.standard.set(false, forKey: "IsSelectedReporTimeForTripButton")
        setUiForCell()
    }
    @IBAction func reportTimeBtnAction(_ sender: Any) {
        UserDefaults.standard.set(true, forKey: "IsSelectedReporTimeForTripButton")
        setUiForCell()
    }
   
    @IBAction func myCalSwitchAction(_ sender: Any) {
        
    }
    
    @IBAction func myCalAction(_ sender: Any) {
    }
    
    func setSwitchState(){
        self.syncSwitch.isOn = AppData.shared.isSyncOn
        
//        amPmTime.text = UserDefaults.standard.string(forKey: KCBCustomizedHerbValue) ?? "1200"
//        
//        if UserDefaults.standard.bool(forKey: KCBIsSyncEnabled) {
//            self.syncSwitch.isOn = true
//        } else {
//            self.syncSwitch.isOn = false
//        }
    }
    func setUiForCell(){
        reportTimeBtn.setImage(UIImage(named: "radioButton-Off"), for: .normal)
        firstTakeOffBtn.setImage(UIImage(named: "RadioButton-On"), for: .normal)
        
        if UserDefaults.standard.bool(forKey: "IsSelectedReporTimeForTripButton") == true {
            reportTimeBtn.setImage(UIImage(named: "RadioButton-On"), for: .normal)
            firstTakeOffBtn.setImage(UIImage(named: "radioButton-Off"), for: .normal)
        }
    }
    @IBAction func startDateSelection(_ sender: Any) {}
        
    @IBAction func endDateSelection(_ sender: Any) {}
    
    

    
    @objc func viewTapped() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "CBBrightnessViewController") as? CBBrightnessViewController {
            vc.preferredContentSize = CGSize(width: 300, height: 200)
            self.navigationController?.pushViewController(vc, animated: true)
        } else {
            print("Failed to instantiate CBBrightnessViewController")
        }
    }
}
