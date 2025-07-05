//
//  CBDayMonthSortCell.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 24/03/25.
//

import UIKit

enum DaysSortType {
    case Off
    case Work
    case TripStart
}

class CBDayMonthSortCell: UITableViewCell {
    
    var filterRule: BIFilterRule?
    var bidPeriod: BIBidPeriod?
    var calendarData: BICalendarData?
    let context = CBGlobalMethods.shared.selectedBidPeriod?.managedObjectContext
    var lineSort : BILineSort?
    
    var type : DaysSortType?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func btnCloseAction(_ sender: Any) {
        NotificationCenter.default.post(
            name: Notification.Name("DeleteCellNotification"),
            object: self // Pass the cell itself as the object
        )
    }
}
