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
    
    @IBOutlet weak var calendarCollectionView: UICollectionView!
    @IBOutlet weak var calculateButton: UIButton!
    @IBOutlet weak var monthLabel: UILabel!
    
    var filterRule: BIFilterRule?
    var bidPeriod: BIBidPeriod?
    var calendarData: BICalendarData?
    let context = CBGlobalMethods.shared.selectedBidPeriod?.managedObjectContext
    var lineSort : BILineSort?
    var isPreviousMonth: Bool = false
    
    var type : DaysSortType = .Off
    var cellWidth = CGFloat()
    var cellHeight = CGFloat()
    var isLoading = false

    override func awakeFromNib() {
        super.awakeFromNib()
        
        calendarCollectionView.delegate = self
        calendarCollectionView.dataSource = self
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        isPreviousMonth = true
        monthLabel.translatesAutoresizingMaskIntoConstraints = true
        monthLabel.center.x = 20
        calculateButton.layer.cornerRadius = 5
        calculateButton.layer.borderWidth = 2
        calculateButton.layer.borderColor = CBColor.purpleColor.cgColor
        
        if calendarData == nil {
            print("")
        }
        
        // Grab the old calendar title if it exists.
        let callTitleToRemove = self.viewWithTag(67)
        if let callTitleToRemove = callTitleToRemove {
            callTitleToRemove.removeFromSuperview()
        }
        
        if let bidPeriod = self.bidPeriod {
            let month = bidPeriod.month!
            let dateString = String(format: "%@", month)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM"
            let myDate = dateFormatter.date(from: dateString)!
            
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM"
            var calTitle = formatter.string(from: myDate)
            if type == .Off {
                calTitle.append(" Days Off")
            }
            else if type == .Work {
                calTitle.append(" Days Work")
            }
            else {
                calTitle.append(" Trip Start")
            }
//            rotating the title
            monthLabel.text = calTitle
            monthLabel.transform = CGAffineTransform(rotationAngle: CGFloat(-90.0 * .pi / 180.0))
        }
        
        if let calendarData = self.calendarData {
            for i in 0..<calendarData.calendarDays.count {
                let viewTag = 500 + i
                let viewToRemove = self.calendarCollectionView.viewWithTag(viewTag)
                if let viewToRemove = viewToRemove {
                    viewToRemove.removeFromSuperview()
                }
            }
        }
    }
    
    @IBAction func calculateDaysOffSort(_ sender: Any) {
        guard !isLoading else {
            return
        }
        CBGlobalMethods.shared.selectedBidPeriod!.loadedPresetIdentifier = nil
        CBGlobalMethods.shared.selectedBidPeriod?.currentDateTime = Date()
        CBGlobalMethods.shared.selectedBidPeriod?.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)
        isLoading = true
        CBGlobalMethods.shared.showActivityIndicator(bgColor: .purple)
        var keypath : String? = nil
        if self.type == .Off {
            keypath = self.bidPeriod!.lineSortKeyForDaysOff(lineSort: self.lineSort!)
        }else if self.type == .Work {
            keypath = self.bidPeriod!.lineSortKeyForDaysWork(lineSort: self.lineSort!)
        }else {
            keypath = self.bidPeriod!.lineSortKeyForTripStartDays(lineSort: self.lineSort!)
        }
        self.lineSort?.keyPath = keypath!
        self.lineSort?.ascending = NSNumber(booleanLiteral: true)
        if self.type == .Work {
            self.lineSort?.ascending = NSNumber(booleanLiteral: false)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){
            try? self.context?.save()
            NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
            CBGlobalMethods.shared.hideActivityIndicator()
            self.isLoading = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.calendarCollectionView.reloadData()
            }

        }
    }
    
    @IBAction func btnCloseAction(_ sender: Any) {
        for view in self.calendarCollectionView.subviews {
            if view.tag > 499 {
                view.removeFromSuperview()
            }
        }
        
        // Remove the sorting by the days of the month
        let monthBits: UInt64 = 0
        let DICT = ["DAYS_OFF_MONTH_BITS": NSNumber(integerLiteral: Int(monthBits))]
        self.lineSort?.variables = DICT as NSDictionary
        context!.delete(lineSort!)
        do {
            try context?.save()
        }
        catch {
            print("Error deleting object \(error.localizedDescription)")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){
            NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
        }
    }
}

extension CBDayMonthSortCell: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
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
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let calendarData = self.calendarData {
            return calendarData.calendarDays.count
        }
        else {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let kDayCellIdentifer = "DayCell"
        let kDayLabelTag = 200
        let cell =  collectionView.dequeueReusableCell(withReuseIdentifier: kDayCellIdentifer, for: indexPath)
        let day = self.calendarData!.calendarDays[indexPath.row] as! BICalendarDay
        let dayLabel = cell.viewWithTag(kDayLabelTag) as! UILabel
        dayLabel.text = day.text
        dayLabel.textColor = day.isCurrentMonth ? UIColor.black : UIColor.lightGray
        if day.isCurrentMonth {
            isPreviousMonth = false
        }
        if day.text == "31" && self.bidPeriod?.month?.intValue == 2 && self.bidPeriod?.positionType?.intValue == BICrewPositionType.FlightAttendant.rawValue {
            isPreviousMonth = false
        }
        if isPreviousMonth {
            cell.isUserInteractionEnabled = false
        }
        else {
            cell.isUserInteractionEnabled = true
        }
        var monthBits: UInt64 = 0
        if self.lineSort?.variables != nil {
            monthBits = self.lineSort?.variables!["DAYS_OFF_MONTH_BITS"] as! UInt64
        }
        let one : UInt64 = 1
        var mask: UInt64 = 0
        mask = one << indexPath.row
        let bits: UInt64 = monthBits & mask
        if bits != 0 {
            let viewTag = indexPath.row + 500
            let viewToAdd = self.calendarCollectionView.viewWithTag(viewTag)
            if (viewToAdd == nil) {
                self.addRedBubbleWith(viewTag: viewTag, index: indexPath.row)
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // If you need to use the touched cell, you can retrieve it like so
        CBGlobalMethods.shared.selectedBidPeriod?.loadedPresetIdentifier = nil
        CBGlobalMethods.shared.selectedBidPeriod?.currentDateTime = Date()
        CBGlobalMethods.shared.selectedBidPeriod?.isStateFileModifiedToSync = NSNumber(booleanLiteral:  true)
        let index = indexPath.row
        let viewTag = index + 500
        let viewToRemove = self.calendarCollectionView.viewWithTag(viewTag)
        if let viewToRemove = viewToRemove {
            self.configureMonthDayFilter(index: index, shouldAddDat: false)
            viewToRemove.removeFromSuperview()
        } else {
            self.addRedBubbleWith(viewTag: viewTag, index: index)
            self.configureMonthDayFilter(index: index, shouldAddDat: true)
        }
    }
    
    func addRedBubbleWith(viewTag: Int, index: Int) {
        let flowLayout = self.calendarCollectionView.collectionViewLayout as! UICollectionViewFlowLayout
        var itemSize = flowLayout.itemSize
        itemSize.width = (calendarCollectionView.frame.width / 7) - 10
        let hInset = itemSize.height / 2.0
        let wInset = itemSize.width / 2.0
        let insets = UIEdgeInsets(top: hInset, left: wInset, bottom: hInset, right: wInset)
        var redSelectedFrame = CGRect(x: 0.0, y: 0.0, width: itemSize.width, height: itemSize.height)
        let buttonImage: UIImage!
        let redSelected: UIImageView!
        
        let layout = flowLayout.layoutAttributesForItem(at: IndexPath(item: index, section: 0))
        redSelectedFrame.origin.x = (layout?.frame.origin.x)!
        redSelectedFrame.origin.y = (layout?.frame.origin.y)!
        
        redSelected = UIImageView(frame: redSelectedFrame)
        redSelected.tag = viewTag
        
        // Add the day number
        let labelFrame = redSelected.bounds
        let label = UILabel(frame: labelFrame)
        if type == .Off{
            buttonImage = UIImage(named: "TripButton-rounded-both-red")?.resizableImage(withCapInsets: insets, resizingMode: .stretch)
            label.font = UIFont.boldSystemFont(ofSize: 20.0)
            label.text = "X"
        } else if type == .Work {
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
        self.calendarCollectionView.addSubview(redSelected)
    }
    
    func configureMonthDayFilter(index: Int, shouldAddDat: Bool) {
        var mask: UInt64 = 0
        var monthBits: UInt64 = 0
        if self.lineSort?.variables != nil {
            monthBits = self.lineSort?.variables!["DAYS_OFF_MONTH_BITS"] as! UInt64
        }
        let one: UInt64 = 1
        mask = one << index
        if (shouldAddDat) {
            // Set bit.
            monthBits |= mask;
        } else {
            // Clear bit.
            monthBits &= ~mask;
        }
        let DICT = ["DAYS_OFF_MONTH_BITS": NSNumber(integerLiteral: Int(monthBits))]
        self.lineSort?.variables = DICT as NSDictionary
    }
}
