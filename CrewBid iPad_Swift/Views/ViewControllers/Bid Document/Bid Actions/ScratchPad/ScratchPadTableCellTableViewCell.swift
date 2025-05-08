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
    
    
    var app: AppDelegate?
    var calendarData: BICalendarData?
    var line: BILine?
    var index: Int?
    var tableView: UITableView?
    var availableFaLines : [BILine] = []
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
//    var tripButtonActionBlock: CBLineCellTripButtonActionBlock?
    var daysArray:[String] = []
    var numDays = 0
    var numDays1 = 0
    private var kLineNumberViewTag: Int = 10
    private var kLineNumberVertOrigin: Int = 73
    private var kCircleSize: Int = 20 //25
    private var kCircleHorizontalOffset: Int = 30 //28
    private var kCircleVerticalOffset: Int = 165 //90
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
    //--------------------------
    var selectedValues:[String] = []
    var CalendarData: [[(day: Int?, isBidMonth: Bool)]] = []
    var tripIndexes: [(row: Int, col: Int)] = []
    let tripDays = [1,2,3,4,8,9,10,11,15,16,17,18,22,23,24,25]
    let month = 5
    let year = 2025
    func getCalendarData(for month: Int, year: Int){
        let calendar = Calendar.current
        //---------Bid Month Details-----------
        let firstDayOfBidMonth = calendar.date(from: DateComponents(year: year, month: month, day: 1))!
        let firstWeekdayofBidMonth = calendar.component(.weekday, from: firstDayOfBidMonth)     //S,M,T,W,T,F,S as 1,2,3,4,5,6,7
        let rangeBidMonth = calendar.range(of: .day, in: .month, for: firstDayOfBidMonth)!
        let totalDaysinBidMonth = rangeBidMonth.count
        //---------Previous Month Details----------
        let lastWeekDayofPreviousMonth = firstWeekdayofBidMonth - 1     //S,M,T,W,T,F,S as 1,2,3,4,5,6,7
        let previousMonth = calendar.date(byAdding: .month, value: -1, to: firstDayOfBidMonth)!
        let rangePrevMonth = calendar.range(of: .day, in: .month, for: previousMonth)!
        let totalDaysinPreviousMonth = rangePrevMonth.count
        
        var calendarData: [[(day:Int?,isBidMonth:Bool)]] = Array(repeating: Array(repeating: (nil,false), count: 7), count: 6)
        
        var currentDay = 1
        var day = totalDaysinPreviousMonth - lastWeekDayofPreviousMonth + 1
        
        for col in 0..<lastWeekDayofPreviousMonth {
            calendarData[0][col] = (day,false)
            day += 1
        }
        var row = 0
        var col = lastWeekDayofPreviousMonth
        while currentDay <= totalDaysinBidMonth {
            calendarData[row][col] = (currentDay,true)
            currentDay += 1
            col += 1
            if col == 7{
                col = 0
                row += 1
            }
        }
        var nextMonthDay = 1
            for row in 0..<6 {
                for col in 0..<7 {
                    if calendarData[row][col].day == nil {
                        calendarData[row][col] = (nextMonthDay,false)
                        nextMonthDay += 1
                    }
                }
            }
        CalendarData = calendarData
    }
    // Function to display the day and apply styles based on the bid month
    func displayDay(for collection: CBBidListSmallCollectionViewCell, day: Int?, isBidMonth: Bool) {
        // Display the day or placeholder if nil
        collection.dayLabel.text = day != nil ? "\(day!)" : ""
        
        // Change text color if it's not part of the bid month
        if !isBidMonth {
            collection.dayLabel.textColor = UIColor(red: 195/255, green: 195/255, blue: 197/255, alpha: 1.0)
        }
    }




    func cellLayout(){
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        collectionView.collectionViewLayout = layout
    }
    //--------------------------
    
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
        let iconView: UIControl? = CBUserFlagTableController.userFlagControlForColor(color: UIColor.blue, diameter: 30.0)
        iconView?.frame = CGRect(x: 23.0, y: 54.0, width: 30.0, height: 30.0)
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
        posAView.alpha = 0.0
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
        posAGrayView.alpha = 1.0
        
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
        posBGrayView.alpha = 1.0
        
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
        posCView.alpha = 0.0
        
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
        posCGrayView.alpha = 1.0
        
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
        posDView.alpha = 0.0
        
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
        posDGrayView.alpha = 1.0
        
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
        posMView.alpha = 0.0
        
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
        posNAView.alpha = 0.0
        //-----------------------
        
        getCalendarData(for: month, year: year)
       
        //-----------------------
        
    }

    @objc func longPressLineValueContainerView(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state != .ended {
            return
        }
        let storyboard : UIStoryboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let lineValuesController = storyboard.instantiateViewController(withIdentifier: "CBLineValuesMenuController") as! CBLineValuesMenuController
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
        return 42
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DayCell", for: indexPath as IndexPath) as! CBBidListSmallCollectionViewCell
        let row = indexPath.row/7
        let col = indexPath.row%7
        let data = CalendarData[row][col]
        let day = data.day
        let isbidmonth = data.isBidMonth
        displayDay(for: cell, day: day, isBidMonth: isbidmonth)
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = floor(collectionView.frame.width / 7)
        return CGSize(width: width, height: 55)

    }

    @IBAction func removeLineAction(_ sender: Any) {
    }
    @IBAction func moveLinesToBidListAction(_ sender: Any) {
        
    }
}
