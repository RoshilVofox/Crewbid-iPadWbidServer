//
//  CBLineNumberController.swift
//  CrewBid iPad_Swift
//
//  Created by Developer on 17/04/25.
//

import UIKit
import EventKit
import EventKitUI

class CBLineNumberController: BaseViewController {

    @IBOutlet weak var txtLineNumber: customUITextField!
    @IBOutlet weak var txtPosition: customUITextField!
    @IBOutlet weak var txtView: UITextView!
    @IBOutlet weak var btnClose: UIButton!
    public var bidPeriod: BIBidPeriod!
    var lineNumberFromInput : String = ""
    public var text = String()
    var calendarData = BICalendarData()
    var calendarDayArr : [BICalendarDay] = []
    var action:String?
    var selectedCalendarType: EKCalendar?
    var selectedLine: BILine?
    let eventStore = EKEventStore()
    let permissionMsg = "CrewBid needs access Calendar to add awards.\nGo to device Settings -> Privacy -> Calendars to enable access"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    func setupUI() {
        btnClose.setTitle("", for: .normal)
        txtLineNumber.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: txtLineNumber.frame.height))
        txtLineNumber.leftViewMode = .always
        txtPosition.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: txtPosition.frame.height))
        txtPosition.leftViewMode = .always
        txtPosition.delegate = self
        txtLineNumber.delegate = self
        self.bidPeriod = CBGlobalMethods.shared.selectedBidPeriod
        calendarData = calendarData.initWithBidPeriod(bidPeriod: self.bidPeriod!)!
        calendarDayArr = calendarData.calendarDays as! [BICalendarDay]
        self.txtPosition.autocapitalizationType = .allCharacters
        if self.bidPeriod!.isFABid() {
            self.txtPosition.isHidden = false
            self.txtView.text = "Enter the line number and position\nthat you would like to fetch."
        } else {
            self.txtPosition.isHidden = true
            self.txtView.text = "Enter the line number\n that you would like to fetch."
        }
        
    }
    
    @IBAction func btnDismissAction(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func btnGoAction(_ sender: Any) {
        if (txtLineNumber.text?.count) == 0 {
            shakeTextField(textField: txtLineNumber)
        } else {
            askForLineNumber()
        }
    }
    
    func askForLineNumber() {
        let position = txtPosition.text
        if let text = txtLineNumber.text, text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty {
            print("isEmpty")
        } else {
            self.txtLineNumber?.resignFirstResponder()
            self.txtPosition?.resignFirstResponder()
            self.txtView?.resignFirstResponder()
            
            let lineNum = txtLineNumber.text!
            self.lineNumberFromInput = lineNum
            var line:BILine?
            if self.bidPeriod!.isFABid() {
                let awardedLine =  Int(lineNum)
                if awardedLine != nil {
                    if let ln = self.fetchLine(lineNumber: awardedLine!, isFA: true, pos: position) {
                        line = ln
                    } else if position == "" {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            AlertService.showAlertForTopVC(title: "Alert", message: "Please enter position!")
                            return
                        }
                    } else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            AlertService.showAlertForTopVC(title: "Alert", message: "Line Not Found")
                            return
                        }
                    }
                } else {
                    dismissFn()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        AlertService.showAlertForTopVC(title: "Alert", message: "Line Not Found")
                        return
                    }
                }
            } else {
                let awardedLine =  Int(lineNum)
                if awardedLine != nil {
                    if let ln = self.fetchLine(lineNumber: awardedLine!, isFA: false, pos: nil) {
                        line = ln
                    } else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            AlertService.showAlertForTopVC(title: "Alert", message: "Line Not Found")
                            return
                        }
                    }
                    
                } else {
                    dismissFn()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        AlertService.showAlertForTopVC(title: "Alert", message: "Line Not Found")
                        return
                    }
                }
            }
            
            if action == "Add Line to Calendar"{
                if line != nil {
                    self.selectedLine = line
                    addLinetoCalendar()
                }
            }else{
                if line != nil {
                    self.showAwardedLineInCalenderView(line: line!)
                }
            }
        }
    }
    
    func addLinetoCalendar() {
        if selectedLine!.type!.intValue == BILineType.BlankLine.rawValue {
            let alert = UIAlertController(title: "Line type is \"Blank\"", message: "Cannot add a \"Blank\" line to Calendar", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ok", style: .default, handler: { action in
                self.dismissFn()
            })
            alert.addAction(okAction)
            present(alert, animated: true)
        } else {
            checkPermission()
        }
    }
    
    func checkPermission() {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .writeOnly, .fullAccess, .authorized:
            self.showCalendarChooser()
        case .denied:
            CBGlobalMethods.shared.ShowAlert(TitleString: "Permission Required", MessageString: permissionMsg)
        case .notDetermined:
            if #available(iOS 17, *) {
                eventStore.requestFullAccessToEvents {(granted, error) in
                    if granted {
                        self.showCalendarChooser()
                    } else {
                        CBGlobalMethods.shared.ShowAlert(TitleString: "Permission Required", MessageString: self.permissionMsg)
                    }
                }
            } else {
                eventStore.requestAccess(to: .event, completion: {(granted, error) in
                    if granted {
                        self.showCalendarChooser()
                    } else {
                        CBGlobalMethods.shared.ShowAlert(TitleString: "Permission Required", MessageString: self.permissionMsg)
                    }
                })
            }
        default:
            print("Default Selection")
        }
    }
    
    func showCalendarChooser() {
        DispatchQueue.main.async {
            let vc = EKCalendarChooser(selectionStyle: .single, displayStyle: .writableCalendarsOnly, entityType: .event, eventStore: self.eventStore)
            vc.showsDoneButton = true
            vc.showsCancelButton = true
            vc.delegate = self
            let nvc = UINavigationController(rootViewController: vc)
            self.present(nvc, animated: true, completion: nil)
        }
    }
    
    func showAwardedLineInCalenderView(line : BILine) {
        let storyboard : UIStoryboard = UIStoryboard(name: "BidActions", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBAwardLineCalendarViewController") as! CBAwardLineCalendarViewController
        vc.line = line
        vc.employeeNumber = self.lineNumberFromInput
        vc.bidPeriod = bidPeriod
        vc.calendarData = calendarData
        vc.isFromLineFetch = true
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func fetchLine(lineNumber: Int, isFA: Bool, pos: String?) -> BILine? {
        let lineTypeSort = NSSortDescriptor(key: "type", ascending: true)
        let lineNumberSort = NSSortDescriptor(key: "number", ascending: true)
        
        let lineSorts = [lineTypeSort, lineNumberSort]
        var predicate = NSPredicate(format: "number == %@", NSNumber(value: lineNumber))
        
        if isFA && !(bidPeriod?.isSecondRoundBid())! {
            var faPos : BIFaPosition = BIFaPosition.FaPositionA
            if pos == "A" {
                faPos = BIFaPosition.FaPositionA
            } else if pos == "B" {
                faPos = BIFaPosition.FaPositionB
            } else if pos == "C" {
                faPos = BIFaPosition.FaPositionC
            } else if pos == "D" {
                faPos = BIFaPosition.FaPositionD
            } else {
                return nil
            }
            let posPred = NSPredicate(format: "faPosition == %@", NSNumber(value: faPos.rawValue))
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, posPred])
        }
        
        let lines = (CBGlobalMethods.shared.selectedBidPeriod!.lines!.allObjects as NSArray).sortedArray(using: lineSorts)
        let results = (lines as NSArray).filtered(using: predicate) as! [BILine]
        
        if results.count > 0 {
            return results.first
        }
        return nil
    }
    
    func addTripstoCalendar() {
        let trips = self.selectedLine!.trips!
        let totalTripCount = trips.count
        var addedTripsCount = 0
        
        for trip1 in trips {
            if let trip = trip1 as? BITrip {
                let event = EKEvent(eventStore: eventStore)
                
                var eventTitle = String(format: "%04zd", trip.info!.reportTime().intValue)
                for dayInfo in trip.info!.orderedDays() {
                    eventTitle += " \(dayInfo.city!)"
                }
                eventTitle += String(format: " %04zd", trip.info!.releaseTime().intValue)
                
                event.title = eventTitle
                event.isAllDay = true
                event.notes = trip.calendarTripText()
                event.startDate = trip.startDate as Date?
                
                let calendar = BICalendarData.bidPeriodCalendar()
                var dc = DateComponents()
                dc.day = trip.info!.calendarDaysCount!.intValue
                event.endDate = calendar!.date(byAdding: dc, to: trip.startDate! as Date)
                
                event.calendar = selectedCalendarType ?? eventStore.defaultCalendarForNewEvents
                
                do {
                    try eventStore.save(event, span: .thisEvent)
                    addedTripsCount += 1
                } catch let e as NSError {
                    CBGlobalMethods.shared.ShowAlert(TitleString: "Event Adding Failed", MessageString: e.localizedDescription)
                    return
                }
            }
        }
        
        if addedTripsCount == totalTripCount {
            AlertService.showAlertForTopVC(title: "Success", message: "All trips successfully added to calendar", actions: [(title: "OK", style: .default, handler:{_ in
                DispatchQueue.main.async {
                    self.dismiss(animated: true, completion: nil)
                }})])
        }
    }
}

extension CBLineNumberController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.text!.isEmpty {
            textField.layer.borderWidth = 4
            textField.layer.borderColor = UIColor.purple.cgColor
        } else {
            textField.layer.borderWidth = 4
            textField.layer.borderColor = UIColor.gray.cgColor
        }
    }
}

extension CBLineNumberController: EKCalendarChooserDelegate {
    func calendarChooserDidFinish(_ calendarChooser: EKCalendarChooser) {
        print(calendarChooser.selectedCalendars)
        calendarChooser.dismiss(animated: true) {
            self.selectedCalendarType = calendarChooser.selectedCalendars.first
            self.addTripstoCalendar()
        }
    }
    
    func calendarChooserSelectionDidChange(_ calendarChooser: EKCalendarChooser) {
        print("Changed selection")
    }
    
    func calendarChooserDidCancel(_ calendarChooser: EKCalendarChooser) {
        print("Cancel tapped")
        dismiss(animated: true, completion: nil)
    }
}
