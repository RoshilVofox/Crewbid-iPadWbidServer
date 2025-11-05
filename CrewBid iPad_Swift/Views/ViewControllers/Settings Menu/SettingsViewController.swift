//
//  SettingsViewController.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 19/04/25.
//

import UIKit

class SettingsViewController: BaseViewController,KUIPopOverUsable {
    
    var contentSize: CGSize {
        return CGSize(width: 300, height: self.bidPeriod == nil ? 376 : 400)
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
    @IBOutlet weak var localTimeLabel: UILabel!
    
    var bidPeriod: BIBidPeriod?
    var calendarData = BICalendarData()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewBG.layer.cornerRadius = 5
        viewBG.layer.masksToBounds = true
        setSwitchState()
        amPmTime.delegate = self
        amPmTime.layer.borderWidth = 0.5
        amPmTime.layer.borderColor = UIColor.lightGray.cgColor
        amPmTime.keyboardType = .numberPad
        
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        brightnessView.isUserInteractionEnabled = true
        brightnessView.addGestureRecognizer(tapGesture)
        
        if UserDefaults.standard.integer(forKey: kCBTimeZoneSetting) != CBTimeZoneSetting.localTime.rawValue{
            localTimeLabel.text = "(in Herb Time)"
            amPmTime.placeholder = "Herb Time"
        }
        setUiForCell()
        setupMyCalView()
    }
    
    @IBAction func syncAction(_ sender: UISwitch) {
        if sender.isOn {
            UserDefaults.standard.set(true, forKey: KCBIsSyncEnabled)
        }
        else {
            UserDefaults.standard.set(false, forKey: KCBIsSyncEnabled)
        }
        NotificationCenter.default.post(name: NSNotification.Name("SyncButtonVisibilityChange"), object: nil)
    }
    
    @IBAction func firstTakeOffBtnAction(_ sender: Any) {
        UserDefaults.standard.set(false, forKey: "IsSelectedReporTimeForTripButton")
        setUiForCell()
        NotificationCenter.default.post(name: NSNotification.Name("amPmValueChangedFromButton"), object: nil)
        NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
    }
    @IBAction func reportTimeBtnAction(_ sender: Any) {
        UserDefaults.standard.set(true, forKey: "IsSelectedReporTimeForTripButton")
        setUiForCell()
        NotificationCenter.default.post(name: NSNotification.Name("amPmValueChangedFromButton"), object: nil)
        NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
    }
   
    @IBAction func myCalSwitchAction(_ sender: UISwitch) {
        bidPeriod?.myCalEnabled = NSNumber(booleanLiteral: sender.isOn)
        NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
    }
    
    @IBAction func myCalAction(_ sender: Any) {
    }
    
    func setSwitchState(){
        amPmTime.text = UserDefaults.standard.string(forKey: KCBCustomizedHerbValue) ?? "1200"
        if UserDefaults.standard.bool(forKey: KCBIsSyncEnabled) {
            self.syncSwitch.isOn = true
        } else {
            self.syncSwitch.isOn = false
        }
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
    
    func setupMyCalView(){
        if bidPeriod == nil{
            myCalViewHeight.constant = 0
            myCalView.isHidden = true
        }else{
            myCalView.isHidden = false
            myCalViewHeight.constant = 111.5
        }
        myCalSwitch.isOn = bidPeriod?.myCalEnabled as? Bool ?? false
        
        if bidPeriod != nil {
            calendarData = calendarData.initWithBidPeriod(bidPeriod: self.bidPeriod!)!
            let count = calendarData.calendarDays.count - 1
            
            let firstDay = calendarData.calendarDays[0] as! BICalendarDay
            let lastDay = calendarData.calendarDays[count] as! BICalendarDay
            
            let firstIndex = (calendarData.calendarDays as Array).firstIndex(where: {$0 === firstDay})
            let lastIndex = (calendarData.calendarDays as Array).firstIndex(where: {$0 === lastDay})
            
            let minimumDate = calendarData.dateForIndex(index: firstIndex!)
            let maximumDate = calendarData.dateForIndex(index: lastIndex!)
            
            startDatePicker.timeZone = TimeZone(abbreviation: "GMT")
            startDatePicker.minimumDate = minimumDate
            startDatePicker.maximumDate = maximumDate
            
            endDatePicker.timeZone = TimeZone(abbreviation: "GMT")
            endDatePicker.minimumDate = minimumDate
            endDatePicker.maximumDate = maximumDate
            
            if bidPeriod?.myCalStartDate == nil {
                bidPeriod?.myCalStartDate = minimumDate
            }
            if bidPeriod?.myCalEndDate == nil {
                bidPeriod?.myCalEndDate = minimumDate
            }
            
            startDatePicker.date = bidPeriod?.myCalStartDate ?? minimumDate ?? Date()
            endDatePicker.date = bidPeriod?.myCalEndDate ?? minimumDate ?? Date()
            
            startDatePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
            endDatePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
        }
    }

    @objc func dateChanged(_ sender: UIDatePicker){
        if sender == startDatePicker{
            let startDate = sender.date
            
            if let endDate = bidPeriod?.myCalEndDate{
                if startDate.compare(endDate) == .orderedDescending{
                    sender.date = bidPeriod?.myCalStartDate ?? sender.minimumDate!
                    AlertService.showAlertForTopVC(title: "Warning", message: "Start Date should be earlier than the End Date.")
                }else{
                    bidPeriod!.myCalStartDate = startDate
                    try? self.bidPeriod?.managedObjectContext?.save()
                    presentedViewController?.dismiss(animated: false)
                    NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
                }
            }else{
                bidPeriod!.myCalStartDate = startDate
                try? self.bidPeriod?.managedObjectContext?.save()
                presentedViewController?.dismiss(animated: false)
                NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
            }
        }
        
        if sender == endDatePicker{
            
            let endDate = sender.date
            
            if let startDate = bidPeriod?.myCalStartDate{
                if startDate.compare(endDate) == .orderedDescending{
                    sender.date = bidPeriod?.myCalEndDate ?? sender.minimumDate!
                    AlertService.showAlertForTopVC(title: "Warning", message: "End Date should be later than the Start Date.")
                }else{
                    bidPeriod!.myCalEndDate = endDate
                    presentedViewController?.dismiss(animated: false)
                    try? self.bidPeriod?.managedObjectContext?.save()
                    NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
                }
            }else{
                bidPeriod!.myCalEndDate = endDate
                presentedViewController?.dismiss(animated: false)
                try? self.bidPeriod?.managedObjectContext?.save()
                NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
            }
        }
    }
    
    
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

extension SettingsViewController: UITextFieldDelegate{
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if range.length + range.location > textField.text!.length{
            return false
        }
        let newLength = textField.text!.length + string.length - range.length
        let flag = newLength <= 4
        if !flag{
            return flag
        }
        if string.isEmpty {
            return true
        }
        let allowedCharacters = CharacterSet(charactersIn: "0123456789")
        
        if string.rangeOfCharacter(from: allowedCharacters.inverted) != nil {
            if textField.text?.length != 0 {
                AlertService.showAlertForTopVC(title: "Crewbid", message: "Invalid AM/PM time. Please update with valid time.", actions: [(title: "OK", style: .default, handler:{_ in
                    textField.becomeFirstResponder()
                })])
            }else{
                textField.resignFirstResponder()
            }
            return false
        }
        
        let currentText = textField.text ?? ""
        let newText = (currentText as NSString).replacingCharacters(in: range, with: string)
        return newText.count <= 4
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        switch textField.text?.length{
        case 0:DispatchQueue.main.asyncAfter(deadline: .now()+0.7, execute: {
            AlertService.showAlertForTopVC(title: "Crewbid", message: "Invalid AM/PM time. Plaese update with valid time.")
        })
            break
        case 1:textField.text = "000\(textField.text ?? "")"
            break
        case 2:textField.text = "00\(textField.text ?? "")"
            break
        case 3:textField.text = "0\(textField.text ?? "")"
            break
        default:break
        }
        
        if textField.text?.length == 4{
            UserDefaults.standard.setValue(textField.text, forKey: KCBCustomizedHerbValue)
            NotificationCenter.default.post(name: NSNotification.Name("amPmValueChanged"), object: nil)
        }
    }
}
