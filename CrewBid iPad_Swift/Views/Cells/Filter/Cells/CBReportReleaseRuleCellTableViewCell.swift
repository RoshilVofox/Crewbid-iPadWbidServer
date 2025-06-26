//
//  CBReportReleaseRuleCellTableViewCell.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 24/03/25.
//

import UIKit
import CoreData

enum BIReportReleaseType: Int {
    case specific
    case all
}


class CBReportReleaseRuleCellTableViewCell: UITableViewCell {
    
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var txtReport: UITextField!
    @IBOutlet weak var txtRelease: UITextField!
    @IBOutlet weak var btnCalculate: CBBorderToggleButton!
    @IBOutlet weak var btnChooseDate: CBBorderToggleButton!
    @IBOutlet weak var btnDelete: UIButton!
    @IBOutlet weak var viewAllDays: UIView!
    @IBOutlet weak var viewTripOrWorkDays: UIView!
    @IBOutlet weak var viewDates: UIView!
    @IBOutlet weak var allDaysCheckButton: UIButton!
    
    @IBOutlet weak var tripWorkBlkButton: UIButton!
    @IBOutlet weak var tripFirstButton: UIButton!
    @IBOutlet weak var tripLastButton: UIButton!
    @IBOutlet weak var noMidButton: UIButton!
    
    @IBOutlet weak var dateButton: UIButton!
    @IBOutlet weak var calendarCollectionView: UICollectionView!
    
    var bidPeriod: BIBidPeriod?
    var filterRule: BIFilterRule?
    var calendarData: BICalendarData?
    var managedObjectContext: NSManagedObjectContext?
    var rptRlsType: BIReportReleaseType?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    @IBAction func deleteCellRow(_ sender: Any) {
        //MARK: Delegate
        NotificationCenter.default.post(
            name: Notification.Name("DeleteCellNotification"),
            object: self // Pass the cell itself as the object
        )
    }
    
    func handleExistingCases() {
        var variables = self.filterRule?.variables as? NSMutableDictionary
        let strReport = variables![BIFilterRuleReportVariablesKey] as? String ?? ""
        var strRelease = variables![BIFilterRuleReleaseVariablesKey] as? String ?? ""
        var isFirstChecked = (variables![BIFilterRuleCheckStateIsFirstVariablesKey] as? Bool)
        var isLastChecked = (variables![BIFilterRuleCheckstateIsLastVariablesKey] as? Bool)
        var isNoMidChecked = (variables![BIFilterRuleCheckstateIsNoMidVariablesKey] as? Bool)
        var isAllDays = (variables!["isAllDays"] as? Bool)
        var isCalendar = (variables!["isCalendar"] as? Bool)
        if strReport.count > 1 {
            txtReport.text = strReport
        }
        if strRelease.count > 1 {
            txtRelease.text = strRelease
        }
        if isAllDays == true {
            rptRlsType = BIReportReleaseType.all
            self.selectAllDays()
        }
        else if isCalendar == true {
            self.selectDates()
        }
        else {
            rptRlsType = BIReportReleaseType.specific
            self.selectTripOrWorkBlock()
        }
        if isFirstChecked == true {
            self.tripFirstButton.isSelected = true
        }
        else {
            self.tripFirstButton.isSelected = false
        }
        if isLastChecked == true {
            self.tripLastButton.isSelected = true
        }
        else {
            self.tripLastButton.isSelected = false
        }
        if isNoMidChecked == true {
            self.noMidButton.isSelected = true
        }
        else {
            self.noMidButton.isSelected = false
        }
        if (self.bidPeriod?.isReportReleaseFilterApplied?.boolValue == true) {
            var textField = UITextField()
            if txtReport.text?.count == 4 && txtRelease.text?.count == 4 {
                textField = txtReport
                if (self.allDaysCheckButton.isSelected == true) {
                    self.multiplReportReleaseAllDays()
                }
                else {
                    self.multiplReportRelease()
                }
                self.bidPeriod?.isReportReleaseFilterApplied = false
            }
            else if txtReport.text?.count == 4 {
                textField = txtReport
                if (self.allDaysCheckButton.isSelected == true) {
                    self.multiplReportReleaseAllDays()
                }
                else {
                    self.multiplReportRelease()
                }
                self.bidPeriod?.isReportReleaseFilterApplied = false
            }
            else if txtRelease.text?.count == 4 {
                textField = txtRelease
                if (self.allDaysCheckButton.isSelected == true) {
                    self.multiplReportReleaseAllDays()
                }
                else {
                    self.multiplReportRelease()
                }
                self.bidPeriod?.isReportReleaseFilterApplied = false
            }
        }
    }
    
    func selectAllDays() {
        self.allDaysCheckButton.isSelected = true
        self.tripWorkBlkButton.isSelected = false
        self.tripFirstButton.isSelected = false
        self.tripLastButton.isSelected = false
        self.dateButton.isSelected = false
        self.btnChooseDate.isSelected = false
        self.noMidButton.isSelected = false
        self.collectionViewSetEnabled(enabled: false)
    }
    
    func selectDates() {
        self.allDaysCheckButton.isSelected = false
        self.tripWorkBlkButton.isSelected = false
        self.tripFirstButton.isSelected = false
        self.tripLastButton.isSelected = false
        self.dateButton.isSelected = true
        self.btnChooseDate.isSelected = true
        self.noMidButton.isSelected = false
        self.collectionViewSetEnabled(enabled: true)
    }
    
    func selectTripOrWorkBlock() {
        self.allDaysCheckButton.isSelected = false
        self.tripWorkBlkButton.isSelected = true
        self.tripFirstButton.isSelected = true
        self.tripLastButton.isSelected = true
        self.dateButton.isSelected = false
        self.btnChooseDate.isSelected = false
        self.noMidButton.isSelected = true
        self.collectionViewSetEnabled(enabled: false)
    }
    
    func collectionViewSetEnabled(enabled: Bool) {
        if enabled == true {
            self.calendarCollectionView.alpha = 1
            self.calendarCollectionView.isUserInteractionEnabled = true
        }
        else {
            self.calendarCollectionView.alpha = 0.5
            self.calendarCollectionView.isUserInteractionEnabled = false
        }
    }
    
    func multiplReportReleaseAllDays() {
//        needed to add code here
    }
    
    func multiplReportRelease() {
//        needed to add code here
    }
}
