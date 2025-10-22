//
//  CBTripAwardTextViewController.swift
//  CrewBid iPad_Swift
//
//  Created by Developer on 17/04/25.
//

import UIKit
import EventKit
import MessageUI
import EventKitUI

class CBTripAwardTextViewController: UIViewController, UIPrintInteractionControllerDelegate {

    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var txtView: UITextView!
    @IBOutlet weak var btnBack: UIButton!
    var bidPeriod : BIBidPeriod?
    var trip : BITrip?
    var fileName : String?
    var tripTitleTxt : String?
    let eventStore = EKEventStore()
    let permissionMsg = "CrewBid needs access Calendar to add awards.\nGo to device Settings -> Privacy -> Calendars to enable access"
    var selectedCalendarType: EKCalendar?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        txtView.font = UIFont(name: "Courier New Bold", size: 12)
        txtView.text = trip?.tripText()
        lblTitle.text = tripTitleTxt
    }
    
    func setupUI() {
        btnBack.setTitle("", for: .normal)
    }
    
    @IBAction func btnDismissAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func btnShareAction(_ sender: Any) {
        let actions: [(title: String, style: UIAlertAction.Style, handler: ((UIAlertAction) -> Void)?)] = [
            ("Email Trip Sheet", .default, { [weak self] _ in
                self?.handleShareAction(title: "Email Trip Sheet")
            }),
            ("Print Trip Sheet", .default, { [weak self] _ in
                self?.handleShareAction(title: "Print Trip Sheet")
            }),
            ("Export to FFDO format", .default, { [weak self] _ in
                self?.handleShareAction(title: "Export to FFDO format")
            }),
            ("Add Trip to Calender", .default, { [weak self] _ in
                self?.handleShareAction(title: "Add Trip to Calender")
            }),
            ("Cancel", .cancel, nil)
        ]

        AlertService.showAlertForTopVC(
            title: "Actions",
            message: nil,
            actions: actions
        )
    }
    
    func handleShareAction(title: String) {
        var tripText = ""
        let a = trip!
        tripText.append(a.tripText())
        tripText.append("\n\n")
        tripText.append("------------------------------------------------------")
        tripText.append("\n")
        
        switch title {
            case "Email Trip Sheet":
                emailTextFile(text: tripText)

            case "Print Trip Sheet":
                showPrintController(text: tripText)

            case "Export to FFDO format":
                if bidPeriod?.isFABid() ?? true {
                    AlertService.showAlertForTopVC(
                        title: "FFDO Export Not Allowed",
                        message: "FFDO format export is only allowed for pilot lines.")
                } else {
                    emailFFDO(trip: trip!)
                }

            case "Add Trip to Calender":
                addTriptoCalendar()

            default:
                break
        }
    }
    
    func emailFFDO(trip : BITrip){
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            if let data = trip.tripFfdoLegs(trip: trip, doubleSpacing: false).data(using: .utf8) {
                mail.addAttachmentData(data as Data, mimeType: "text/plain" , fileName: "SingleSpacing_FFDO_Format_Trip_Sheets")
            }
            if let data = trip.tripFfdoLegs(trip: trip, doubleSpacing: true).data(using: .utf8) {
                mail.addAttachmentData(data as Data, mimeType: "text/plain" , fileName: "DoubleSpacing_FFDO_Format_Trip_Sheets")
            }
            mail.setSubject("FFDO Format")
            present(mail, animated: true)
        }
    }
    
    func emailTextFile(text : String){
        let file = self.tripTitleTxt!
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            if let data = text.data(using: .utf8) {
                mail.addAttachmentData(data as Data, mimeType: "text/plain" , fileName: file)
            }
            mail.setSubject(title ?? "")
            present(mail, animated: true)
        }
    }
    
    func showPrintController(text : String){
        let printController = UIPrintInteractionController.shared
        printController.delegate = self
        
        let printInfo = UIPrintInfo.printInfo()
        printInfo.outputType = .grayscale
        printInfo.duplex = .none
        printInfo.jobName = fileName!
        printController.printInfo = printInfo
        printInfo.orientation = .landscape
        
        let printFormatter = UISimpleTextPrintFormatter(text: text)
        printFormatter.startPage = 0
        printFormatter.font = .systemFont(ofSize: 10)
        printController.printFormatter = printFormatter
        printController.present(animated: true, completionHandler: nil)
    }
    
    func addTriptoCalendar() {
        
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
    
    func addTripstoCalendar() {
        
        let event = EKEvent(eventStore: eventStore)
        
        var eventTitle = String(format: "%04zd", trip!.info!.reportTime().intValue)
        for dayInfo in trip!.info!.orderedDays() {
            eventTitle += " \(dayInfo.city!)"
        }
        eventTitle += String(format: " %04zd", trip!.info!.releaseTime().intValue)
        
        event.title = eventTitle
        event.isAllDay = true
        event.notes = trip!.calendarTripText()
        event.startDate = trip!.startDate as Date?
        
        let calendar = BICalendarData.bidPeriodCalendar()
        var dc = DateComponents()
        dc.day = trip!.info!.calendarDaysCount!.intValue
        event.endDate = calendar!.date(byAdding: dc, to: trip!.startDate! as Date)
        
        event.calendar = selectedCalendarType ?? eventStore.defaultCalendarForNewEvents
        
        do {
            try eventStore.save(event, span: .thisEvent)
            AlertService.showAlertForTopVC(title: "Success", message: "All trips successfully added to calendar", actions: [(title: "OK", style: .default, handler:{ _ in
                DispatchQueue.main.async {
                    self.dismiss(animated: true)
                }})])
        } catch let error as NSError {
            AlertService.showAlertForTopVC(title: "Event Adding Failed", message: error.localizedDescription)
            return
        }
    }
}

extension CBTripAwardTextViewController : MFMailComposeViewControllerDelegate{
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}

extension CBTripAwardTextViewController: EKCalendarChooserDelegate {
    func calendarChooserDidFinish(_ calendarChooser: EKCalendarChooser) {
        print(calendarChooser.selectedCalendars)
        calendarChooser.dismiss(animated: true) {
            self.selectedCalendarType = calendarChooser.selectedCalendars.first
            self.addTripstoCalendar()
        }
    }
    
    func calendarChooserDidCancel(_ calendarChooser: EKCalendarChooser) {
        dismiss(animated: true, completion: nil)
    }
}
