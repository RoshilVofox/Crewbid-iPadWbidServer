//
//  CBDayMonthRuleCell.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 24/03/25.
//

import UIKit

class CBDayMonthRuleCell: UITableViewCell {
    
    @IBOutlet weak var calendarCollectionView: CBLineCalendarCollectionView!
    @IBOutlet weak var monthLabel: UILabel!
    
    var filterRule: BIFilterRule?
    var bidPeriod: BIBidPeriod?
    var calendarData: BICalendarData?
    let context = CBGlobalMethods.shared.selectedBidPeriod?.managedObjectContext
    var isPreviousMonth: Bool = false
    var cellWidth = CGFloat()
    var cellHeight = CGFloat()
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        bidPeriod = CBGlobalMethods.shared.selectedBidPeriod!
        calendarCollectionView.delegate = self
        calendarCollectionView.dataSource = self
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        for subview in self.calendarCollectionView.subviews {
            if subview.tag > 499 {
                subview.removeFromSuperview()
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        monthLabel.translatesAutoresizingMaskIntoConstraints = true
        monthLabel.center.x = 20
        
        let dateString = String(format: "%@", bidPeriod!.month!)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM"
        let myDate: NSDate = dateFormatter.date(from: dateString)! as NSDate
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        var calTitle = formatter.string(from: myDate as Date)
        if filterRule?.type?.intValue == BIDaysOfMonthFilterRuleType.BIDaysOfMonthOffType.rawValue {
            calTitle.append(" (Days Off)")
        }
        else if filterRule?.type?.intValue == BIDaysOfMonthFilterRuleType.BIDaysOfMonthIncludedType.rawValue {
            calTitle.append(" (Work Days)")
        }
        else if filterRule?.type?.intValue == BIDaysOfMonthFilterRuleType.BIDaysOfMonthFilterRuleTypeTripStartDates.rawValue {
            calTitle.append(" (Trip Start)")
        }
        else {
            calTitle.append(" (Trip End)")
        }
        
        // Remove any old redSelectedBubbles
        for calendarDay in (calendarData?.calendarDays as! [BICalendarDay]) {
            let i = Int(calendarDay.text)!
            let viewTag = i + 500
            let viewToRemove = calendarCollectionView.viewWithTag(viewTag)
            if viewToRemove != nil {
                viewToRemove?.removeFromSuperview()
            }
        }
        monthLabel.text = calTitle
        monthLabel.transform = CGAffineTransform(rotationAngle: CGFloat(-90.0 * .pi / 180.0))
        self.calendarCollectionView.reloadData()
    }
    
    
    @IBAction func deleteCellRow(_ sender: Any) {
        bidPeriod!.loadedPresetIdentifier = nil
        bidPeriod!.currentDateTime = nil
        bidPeriod!.isStateFileModifiedToSync = true
        for case let view in calendarCollectionView.subviews {
            if view.tag > 499 {
                view.removeFromSuperview()
            }
            // Remove the sorting by the days of the month
            var monthBits: UInt64 = filterRule!.variables!["MONTH_BITS"] as! CUnsignedLongLong
            monthBits = 0
            let MONTH_BITS = monthBits
            let dict  = NSDictionary(object: MONTH_BITS, forKey: "MONTH_BITS" as NSCopying)
            filterRule?.variables = dict
        }
        self.context?.delete(filterRule!)
        try? self.context?.save()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){
            NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
        }
    }
}

// Manipulating calendar using BICalendarData

extension CBDayMonthRuleCell: UICollectionViewDataSource, UICalendarViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return (calendarData?.calendarDays.count)!
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let kDayLabelTag = 200
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DayCell", for: indexPath)
        let day: BICalendarDay? = calendarData?.calendarDays[indexPath.row] as? BICalendarDay
        let dayLabel = cell.viewWithTag(kDayLabelTag) as? UILabel
        dayLabel?.text = day?.text
        dayLabel?.textColor = day?.isCurrentMonth != nil ? UIColor.gray : UIColor.lightGray
        
        if day!.isCurrentMonth {
            isPreviousMonth = false
        }
        else {
            if let dayText = dayLabel?.text, let day = Int(dayText), (26...31).contains(day) {
                isPreviousMonth = true
            }
        }
        if !((calendarData?.calendarDays[indexPath.row] as? BICalendarDay)?.isCurrentMonth ?? true) {
            dayLabel?.textColor = .lightGrey
        }
        
        if (day?.text == "31") && (bidPeriod?.month?.intValue == 2) && (bidPeriod?.positionType?.intValue == BICrewPositionType.FlightAttendant.rawValue) {
            isPreviousMonth = false
        }
        
        if isPreviousMonth {
            cell.isUserInteractionEnabled = false
        }
        else {
            cell.isUserInteractionEnabled = true
        }
        
        let monthBits: UInt64 = filterRule!.variables!["MONTH_BITS"] as! CUnsignedLongLong
        
        let one: UInt64 = 1
        var mask: UInt64 = 0

        mask = one << indexPath.row
        
        if monthBits & mask != 0 {
            let viewTag: Int = indexPath.row + 500
            let viewToAdd: UIView? = calendarCollectionView.viewWithTag(viewTag)
            if viewToAdd == nil {
                addRedBubbleWithViewTag(viewTag, index: indexPath.row, cellWidth: cell.frame.size.width, cellHeight: cell.frame.size.height)
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        bidPeriod!.loadedPresetIdentifier = nil
        bidPeriod!.currentDateTime = nil
        bidPeriod!.isStateFileModifiedToSync = true
        
        let index = indexPath.row
        let viewTag = index + 500
        let viewToRemove = calendarCollectionView.viewWithTag(viewTag)
        if viewToRemove != nil {
            let viewToRemove = self.calendarCollectionView.viewWithTag(viewTag)
            configureMonthDayFilter(index, addDay: false)
            viewToRemove?.removeFromSuperview()
        }
        else {
            addRedBubbleWithViewTag(viewTag, index: index, cellWidth: cellWidth, cellHeight: cellHeight)
            configureMonthDayFilter(index, addDay: true)
        }
    }
    
    func addRedBubbleWithViewTag( _ viewTag:Int, index:Int, cellWidth: CGFloat, cellHeight: CGFloat) {
        
        let flowLayout = calendarCollectionView.collectionViewLayout as? UICollectionViewFlowLayout
        let itemSize: CGSize? = flowLayout?.itemSize
        let hInset: CGFloat = (itemSize?.height ?? 0.0) / 2.0
        let wInset: CGFloat = (itemSize?.width ?? 0.0) / 2.0
        let insets: UIEdgeInsets = UIEdgeInsets(top: hInset, left: wInset, bottom: hInset, right: wInset)
        var redSelectedFrame = CGRect(x: 0.0, y: 0.0, width: cellWidth - 2.0, height: cellHeight)
        var buttonImage: UIImage? = nil
        var redSelected: UIImageView? = nil
        let layout: UICollectionViewLayoutAttributes? = flowLayout?.layoutAttributesForItem(at: IndexPath(item: index, section: 0))
        redSelectedFrame.origin.x = layout?.frame.origin.x ?? 0.0
        redSelectedFrame.origin.y = layout?.frame.origin.y ?? 0.0
        
        redSelected = UIImageView(frame: redSelectedFrame)
        redSelected?.tag = viewTag
        
        // Add the day number
        let labelFrame: CGRect = redSelected!.bounds
        let label = UILabel(frame: labelFrame)
        
        if filterRule?.type?.intValue == BIDaysOfMonthFilterRuleType.BIDaysOfMonthOffType.rawValue {
            buttonImage = UIImage(named: "TripButton-rounded-both-red")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
            label.font = UIFont.boldSystemFont(ofSize: 20.0)
            label.text = "X"
        } else if BIDaysOfMonthFilterRuleType.BIDaysOfMonthIncludedType.rawValue == filterRule?.type?.intValue {
            buttonImage = UIImage(named: "TripButton-rounded-both-green")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
            //[label setFont:[UIFont fontWithName:@"Arial Unicode MS" size:20.0f]];
            if let aSize = UIFont(name: "ZapfDingbatsITC", size: 20.0) {
                label.font = aSize
            }
            label.text = "✔"
        } else {
            buttonImage = UIImage(named: "TripButton-rounded-both-orange")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
            label.font = UIFont.boldSystemFont(ofSize: 20.0)
            label.text = "X"
        }
        
        redSelected?.image = buttonImage
        label.textAlignment = .center
        label.textColor = UIColor.white
        
        label.backgroundColor = UIColor.clear
        
        redSelected?.addSubview(label)
        calendarCollectionView.addSubview(redSelected!)
        
    }
    
    func configureMonthDayFilter(_ index: Int, addDay shouldAdd: Bool) {
        var mask: UInt64 = 0
        var monthBits: UInt64 = filterRule!.variables?["MONTH_BITS"] as! UInt64
        
        let one: UInt64 = 1
        
        mask = UInt64(bitPattern: Int64(one << index))
        
        if shouldAdd {
            
            // Set bit.
            monthBits |= mask
        } else {
            // Clear bit.
            monthBits &= ~mask
        }
        
        let MONTH_BITS = monthBits
        
        
        let dict  = NSDictionary(object: MONTH_BITS, forKey: "MONTH_BITS" as NSCopying)
        filterRule?.variables = dict
        try? self.bidPeriod!.managedObjectContext!.save()
        NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
        
    }
}

extension CBDayMonthRuleCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var counter: CGFloat = 0
        for dayCount in 0..<calendarData!.calendarDays.count {
            if dayCount % 6 == 0 {
                counter += 1
            }
        }
        let cellWidth = calendarCollectionView.frame.size.width / 7
        let cellHeight = calendarCollectionView.frame.size.height / (counter + 1)
        self.cellWidth = cellWidth
        self.cellHeight = cellHeight
        return CGSize(width: cellWidth, height: cellHeight)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10.0
    }
}

