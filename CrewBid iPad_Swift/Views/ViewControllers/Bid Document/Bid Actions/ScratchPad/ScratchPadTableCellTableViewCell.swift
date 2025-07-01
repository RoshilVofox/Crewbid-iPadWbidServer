//
//  ScratchPadTableCellTableViewCell.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 15/04/25.
//

import UIKit

class ScratchPadTableCellTableViewCell: UITableViewCell,UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout {

    var kCBLineValueViewWidth : CGFloat = 55.0
    var kCBLineValueViewHeight : CGFloat = 28.0
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var lineValuesView: UIView!
    @IBOutlet weak var moveBidListButton: UIButton!
    @IBOutlet weak var removeButton: UIButton!
    @IBOutlet weak var calendarView: UIView!
    @IBOutlet weak var orderLabel: UILabel!
    @IBOutlet weak var lineNumberLabel: UILabel!
    @IBOutlet weak var redEyeImage: UIImageView!
    
    var app: AppDelegate?
    var calendarData: BICalendarData?
    var line: BILine?
    var index: Int?
    var tableView: UITableView?
    var availableFaLines : [BILine] = []
    var bidPeriod: BIBidPeriod?
    var tripButtons: NSMutableArray?
    var vacationButtons: NSMutableArray?
    var fvVacationButtons: NSMutableArray?
    var cfvVacationButtons: NSMutableArray?
    var tripButtonsArray = NSMutableArray()
    var vacayGestureRecognizers = NSMutableArray()
    var userFlagIconView: UIView = UIView()
    var warningButton: UIButton = UIButton ()
    var posAView: UIView = UIView()
    var posBView: UIView = UIView()
    var posCView: UIView = UIView()
    var posDView: UIView = UIView()
    var posAGrayView: UIView = UIView()
    var posBGrayView: UIView = UIView()
    var posCGrayView: UIView = UIView()
    var posDGrayView: UIView = UIView()
    var posNAView: UIView = UIView()
    var posMView: UIView = UIView()
    var tripButtonActionBlock: CBLineCellTripButtonActionBlock?
    var daysArray:[String] = []
    var numDays = 0
    var numDays1 = 0
    private var kLineNumberViewTag: Int = 10
    private var kLineNumberVertOrigin: Int = 73
    private var kCircleSize: Int = 20 //25
    private var kCircleHorizontalOffset: Int = 30 //28
    private var kCircleVerticalOffset: Int = 120 //90
    private var kCircleVerticalIncrement: Int = 30 //30
    private var kPosAViewTag: Int = 500
    private var kPosBViewTag: Int = 510
    private var kPosCViewTag: Int = 520
    private var kPosDViewTag: Int = 530
    private var kPosAGrayViewTag: Int = 600
    private var kPosBGrayViewTag: Int = 610
    private var kPosCGrayViewTag: Int = 620
    private var kPosDGrayViewTag: Int = 630
    let kCBButtonTag = 800
    var view: UIView!
    var arrayLinesDetails:NSArray = NSArray()
    var calendarDaysArr : [BICalendarDay] = []
    var calendarDay : [BICalendarDay] = []
    var deletedObjArray:[String] = []
    typealias CBLineCellTripButtonActionBlock = (_ tripButton: CBTripButton) -> Void

    

    func cellLayout(){
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        collectionView.collectionViewLayout = layout
    }
    //--------------------------
    
    
    func refreshTripButtons(highlightFlag:Bool) {
        
    }
    
    
    
    func removeAllTripButtons() {
        for case let view as UIView in tripButtonsArray {
            view.removeFromSuperview()
        }
    }
    
    
    func setCircle(_ circleNum: Int, withPos pos: String, color: UIColor, isGray gray: Bool) {
        if circleNum == 0 {
            if gray {
                let posText = posAGrayView.viewWithTag(7) as? UILabel
                posText?.text = pos
                posAView.alpha = 0.0
            }
            else {
                let posText = posAView.viewWithTag(7) as? UILabel
                posText?.text = pos
                posAView.backgroundColor = color
                posAView.alpha = 1.0
                posAGrayView.alpha = 0.0
            }
        }
        else if circleNum == 1 {
            if gray {
                let posText = posBGrayView.viewWithTag(7) as? UILabel
                posText?.text = pos
                posBView.alpha = 0.0
            }
            else {
                let posText = posBView.viewWithTag(7) as? UILabel
                posText?.text = pos
                posBView.backgroundColor = color
                posBView.alpha = 1.0
                posBGrayView.alpha = 0.0
            }
        }
        else if circleNum == 2 {
            if gray {
                let posText = posCGrayView.viewWithTag(7) as? UILabel
                posText?.text = pos
                posCView.alpha = 0.0
            }
            else {
                let posText = posCView.viewWithTag(7) as? UILabel
                posText?.text = pos
                posCView.backgroundColor = color
                posCView.alpha = 1.0
                posCGrayView.alpha = 0.0
            }
        }
        else {
            if gray {
                let posText = posDGrayView.viewWithTag(7) as? UILabel
                posText?.text = pos
                posDView.alpha = 0.0
            }
            else {
                let posText = posDView.viewWithTag(7) as? UILabel
                posText?.text = pos
                posDView.backgroundColor = color
                posDView.alpha = 1.0
                posDGrayView.alpha = 0.0
            }
        }
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        cellLayout()
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isScrollEnabled = false
        
        let verticalSpace: CGFloat = 6.0
        for i in 0..<5 {
//            adding the line values as subview
            var lineValueView1 = CBLineValueView()
            lineValueView1 = lineValueView1.initWithFrame(aRect: CGRect.zero)
            lineValueView1.tag = LineValueViewTag + i * 10
            lineValueView1.translatesAutoresizingMaskIntoConstraints = false
            lineValuesView.addSubview(lineValueView1)
            // Line value view centered in container.
            lineValuesView.addConstraint(NSLayoutConstraint(item: lineValueView1, attribute: .centerX, relatedBy: .equal, toItem: lineValuesView, attribute: .centerX, multiplier: 1.0, constant: 0.0))
            // Top spacing from superview.
            lineValuesView.addConstraint(NSLayoutConstraint(item: lineValueView1, attribute: .top, relatedBy: .equal, toItem: lineValuesView, attribute: .top, multiplier: 1.0, constant: CGFloat(i) * (kCBLineValueViewHeight + verticalSpace)))
        }
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.longPressLineValueContainerView))
        longPressGesture.minimumPressDuration = 0.3
        lineValuesView.addGestureRecognizer(longPressGesture)
        longPressGesture.delaysTouchesBegan = true
//            adding the flags values as subview
        let iconView: UIControl? = CBUserFlagTableController.userFlagControlForColor(color: UIColor.white, diameter: 30.0)
        iconView?.frame = CGRect(x: 23.0, y: 50, width: 30.0, height: 30.0)
        iconView?.addTarget(self, action: #selector(self.showUserFlagMenu), for: .touchUpInside)
        addSubview(iconView ?? UIView())
        self.userFlagIconView = iconView!

        // Set up the position circles
        
        // Position A Colored
        var posView = UIView(frame: CGRect(x: kCircleHorizontalOffset, y: kCircleVerticalOffset, width: kCircleSize, height: kCircleSize))
        addSubview(posView)
        posAView = posView
        posAView.tag = kPosAViewTag
        posAView.layer.cornerRadius = CGFloat(kCircleSize / 2)
        var circleFrame: CGRect = posAView.frame
        circleFrame.origin.x = 0.0
        circleFrame.origin.y = 0.0
        posAView.backgroundColor = CBColor.faPosAColor
        var posText = UILabel(frame: circleFrame)
        posText.backgroundColor = UIColor.clear
        posText.textAlignment = .center
        posText.textColor = UIColor.white
        posText.tag = 7
        posText.font = posText.font.withSize(10)
        posText.text = "A"
        posAView.addSubview(posText)
        posAView.alpha = 0
        self.posAView = posView
        
        // Position A Gray
        posView = UIView(frame: CGRect(x: kCircleHorizontalOffset, y: kCircleVerticalOffset, width: kCircleSize, height: kCircleSize))
        addSubview(posView)
        posAGrayView = posView
        posAGrayView.tag = kPosAGrayViewTag
        posAGrayView.layer.cornerRadius = CGFloat(kCircleSize / 2)
        posAGrayView.backgroundColor = UIColor.lightGray
        posText = UILabel(frame: circleFrame)
        posText.backgroundColor = UIColor.clear
        posText.textAlignment = .center
        posText.textColor = UIColor.white
        posText.tag = 7
        posText.font = posText.font.withSize(10)
        posText.text = "A"
        posAGrayView.addSubview(posText)
        posAGrayView.alpha = 0
        
        // Position B Colored
        posView = UIView(frame: CGRect(x: kCircleHorizontalOffset, y: kCircleVerticalOffset + kCircleVerticalIncrement, width: kCircleSize, height: kCircleSize))
        addSubview(posView)
        posBView = posView
        posBView.tag = kPosBViewTag
        posBView.layer.cornerRadius = CGFloat(kCircleSize / 2)
        posBView.backgroundColor = CBColor.faPosBColor
        posText = UILabel(frame: circleFrame)
        posText.backgroundColor = UIColor.clear
        posText.font = posText.font.withSize(10)
        posText.text = "B"
        posText.textAlignment = .center
        posText.tag = 7
        posText.textColor = UIColor.white
        posBView.addSubview(posText)
        posBView.alpha = 0.0
        
        // Position B Gray
        posView = UIView(frame: CGRect(x: kCircleHorizontalOffset, y: kCircleVerticalOffset + kCircleVerticalIncrement, width: kCircleSize, height: kCircleSize))
        addSubview(posView)
        posBGrayView = posView
        posBGrayView.tag = kPosBGrayViewTag
        posBGrayView.layer.cornerRadius = CGFloat(kCircleSize / 2)
        posBGrayView.backgroundColor = UIColor.lightGray
        posText = UILabel(frame: circleFrame)
        posText.backgroundColor = UIColor.clear
        posText.textAlignment = .center
        posText.textColor = UIColor.white
        posText.tag = 7
        posText.font = posText.font.withSize(10)
        posText.text = "B"
        posBGrayView.addSubview(posText)
        posBGrayView.alpha = 0
        
        // Position C colored
        posView = UIView(frame: CGRect(x: kCircleHorizontalOffset, y: kCircleVerticalOffset + 2 * kCircleVerticalIncrement, width: kCircleSize, height: kCircleSize))
        addSubview(posView)
        posCView = posView
        posCView.tag = kPosCViewTag
        posCView.layer.cornerRadius = CGFloat(kCircleSize / 2)
        posCView.backgroundColor = CBColor.faPosCColor
        posText = UILabel(frame: circleFrame)
        posText.backgroundColor = UIColor.clear
        posText.font = posText.font.withSize(10)
        posText.text = "C"
        posText.textAlignment = .center
        posText.tag = 7
        posText.textColor = UIColor.white
        posCView.addSubview(posText)
        posCView.alpha = 0
        
        // Position C Gray
        posView = UIView(frame: CGRect(x: kCircleHorizontalOffset, y: kCircleVerticalOffset + 2 * kCircleVerticalIncrement, width: kCircleSize, height: kCircleSize))
        addSubview(posView)
        posCGrayView = posView
        posCGrayView.tag = kPosCGrayViewTag
        posCGrayView.layer.cornerRadius = CGFloat(kCircleSize / 2)
        posCGrayView.backgroundColor = UIColor.lightGray
        posText = UILabel(frame: circleFrame)
        posText.backgroundColor = UIColor.clear
        posText.textAlignment = .center
        posText.tag = 7
        posText.textColor = UIColor.white
        posText.font = posText.font.withSize(10)
        posText.text = "C"
        posCGrayView.addSubview(posText)
        posCGrayView.alpha = 0
        
        // Position D Colored
        posView = UIView(frame: CGRect(x: kCircleHorizontalOffset, y: kCircleVerticalOffset + 3 * kCircleVerticalIncrement, width: kCircleSize, height: kCircleSize))
        addSubview(posView)
        posDView = posView
        posDView.tag = kPosDViewTag
        posDView.layer.cornerRadius = CGFloat(kCircleSize / 2)
        posDView.backgroundColor = CBColor.faPosDColor
        posText = UILabel(frame: circleFrame)
        posText.backgroundColor = UIColor.clear
        posText.font = posText.font.withSize(10)
        posText.text = "D"
        posText.textAlignment = .center
        posText.tag = 7
        posText.textColor = UIColor.white
        posDView.addSubview(posText)
        posDView.alpha = 0
        
        // Position D Gray
        posView = UIView(frame: CGRect(x: kCircleHorizontalOffset, y: kCircleVerticalOffset + 3 * kCircleVerticalIncrement, width: kCircleSize, height: kCircleSize))
        addSubview(posView)
        posDGrayView = posView
        posDGrayView.tag = kPosDGrayViewTag
        posDGrayView.layer.cornerRadius = CGFloat(kCircleSize / 2)
        posDGrayView.backgroundColor = UIColor.lightGray
        posText = UILabel(frame: circleFrame)
        posText.backgroundColor = UIColor.clear
        posText.textAlignment = .center
        posText.tag = 7
        posText.textColor = UIColor.white
        posText.font = posText.font.withSize(10)
        posText.text = "D"
        posDGrayView.addSubview(posText)
        posDGrayView.alpha = 0
        
        // M Colored
        posView = UIView(frame: CGRect(x: kCircleHorizontalOffset, y: kCircleVerticalOffset, width: kCircleSize, height: kCircleSize))
        addSubview(posView)
        posMView = posView
        posMView.tag = kPosDGrayViewTag
        posMView.layer.cornerRadius = CGFloat(kCircleSize / 2)
        posMView.backgroundColor = UIColor.purple
        posText = UILabel(frame: circleFrame)
        posText.backgroundColor = UIColor.clear
        posText.textAlignment = .center
        posText.tag = 7
        posText.textColor = UIColor.white
        posText.font = posText.font.withSize(10)
        posText.text = "M"
        posMView.addSubview(posText)
        posMView.alpha = 0
        
        // NA Colored
        posView = UIView(frame: CGRect(x: kCircleHorizontalOffset, y: kCircleVerticalOffset, width: kCircleSize, height: kCircleSize))
        addSubview(posView)
        posNAView = posView
        posNAView.tag = kPosDGrayViewTag
        posNAView.layer.cornerRadius = CGFloat(kCircleSize / 2)
        posNAView.backgroundColor = UIColor.black
        posText = UILabel(frame: circleFrame)
        posText.backgroundColor = UIColor.clear
        posText.textAlignment = .center
        posText.tag = 7
        posText.textColor = UIColor.white
        posText.text = "NA"
        posText.font = posText.font.withSize(10)
        posNAView.addSubview(posText)
        posNAView.alpha = 0
 
    }

    @objc func longPressLineValueContainerView(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state != .ended {
            return
        }
        let storyboard : UIStoryboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let lineValuesController = storyboard.instantiateViewController(withIdentifier: "CBLineValuesMenuController") as! CBLineValuesMenuController
        lineValuesController.bidPeriod = CBGlobalMethods.shared.selectedBidPeriod
        lineValuesController.modalPresentationStyle = .custom
        let touchPoint = gesture.location(in: self.lineValuesView)
        let frame = CGRect(x: lineValuesView.frame.origin.x, y: touchPoint.y - 80, width: lineValuesView.frame.width, height: lineValuesView.frame.height)
        lineValuesController.showPopover(sourceView: self.lineValuesView, sourceRect: frame)
    }
    
    @objc func showUserFlagMenu() {
        let storyboard : UIStoryboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let lineValuesController = storyboard.instantiateViewController(withIdentifier: "CBUserFlagTableController") as! CBUserFlagTableController
//        lineValuesController.line = line
//        lineValuesController.delegate = self
        lineValuesController.modalPresentationStyle = .popover
        lineValuesController.showPopover(sourceView: self.userFlagIconView)
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return calendarDaysArr.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DayCell", for: indexPath as IndexPath) as! CBBidListSmallCollectionViewCell
        cell.contentView.frame = cell.bounds
        cell.contentView.autoresizingMask = [.flexibleWidth,.flexibleHeight]
        let calendarDay = calendarDaysArr[indexPath.row]
        cell.dayLabel.text = calendarDay.text
        let currentMonth = calendarDay.isCurrentMonth
        if currentMonth {
            cell.dayLabel.alpha = 1
        }else{
            cell.dayLabel.alpha = 0.5
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSizeMake((self.contentView.frame.width - 160)/7, 45)
    }

    @IBAction func removeLineAction(_ sender: Any) {
        if self.bidPeriod!.isFABid() {
            NotificationCenter.default.post(name: NSNotification.Name("removedLines"), object: self.contentView.tag)
        }else{
            line?.isTrashed = true
            do{
                try self.bidPeriod?.managedObjectContext?.save()
            }catch{
                print("Error removing lines: \(error.localizedDescription)")
            }
            let lineNumber = line?.number as! Int
            let number = String(lineNumber)
            let objDeleteArray = NSMutableArray()
            objDeleteArray.add(number)
            NotificationCenter.default.post(name: NSNotification.Name("removedLines"), object: self.contentView.tag)
        }
        
        
    }
    
    @IBAction func moveLinesToBidListAction(_ sender: Any) {
        moveBidListButton.isUserInteractionEnabled = false
        perform(#selector(moveBidLineDelay), with: nil, afterDelay: 1.0)
//        if let sView = sender as? UIView {
//            sView.isUserInteractionEnabled = false
//            perform(#selector(resetButton(_:)), with: sView, afterDelay: 0.5)
//        }
        
    }
    
    @objc func moveBidLineDelay() {
        moveBidListButton.isUserInteractionEnabled = true
    }
//    
//    @objc func resetButton(_ sender: UIView) {
//        sender.isUserInteractionEnabled = true
//    }
}
