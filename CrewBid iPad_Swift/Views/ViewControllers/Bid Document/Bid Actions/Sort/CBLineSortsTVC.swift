//
//  CBLineSortsTVC.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 24/03/25.
//

import UIKit
import CoreData

class CBLineSortsTVC: UIViewController, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var btnBidListCount: UIButton!
    @IBOutlet weak var btnSortTheBidlist: UIButton!
    @IBOutlet weak var btnSortTheScratchpad: UIButton!
    @IBOutlet weak var btnFilter: UIButton!
    @IBOutlet weak var btnSort: UIButton!
    @IBOutlet weak var btnPreset: UIButton!
    @IBOutlet weak var btnBids: UIButton!
    @IBOutlet weak var tableView: UITableView!
    var sortsFetchController: NSFetchedResultsController<BILineSort> = NSFetchedResultsController()
    
    var bidPeriod: BIBidPeriod?
    var calendarData: BICalendarData =  BICalendarData()
    var ignoreDataModelChanges: Bool!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        self.view.clipsToBounds = true
        self.view.layer.cornerRadius = 5
        updateLines()
        NotificationCenter.default.addObserver(self, selector: #selector(updateBidListCount), name: NSNotification.Name("updateBidListCount"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.setupLayoutView), name: NSNotification.Name("SortBidListAction"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(updateLines), name: NSNotification.Name("refreshLines"), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver("refreshLines")
        NotificationCenter.default.removeObserver("SortBidListAction")
        NotificationCenter.default.post(name: NSNotification.Name("SortViewWillDisappear"), object: self)
    }
    
    @objc func updateBidListCount(){
        var linesArray : [BILine] = []
        for case let line as BILine in CBGlobalMethods.shared.selectedBidPeriod!.lines! {
            linesArray.append(line)
        }
        var array : [NSPredicate] = []
        array.append(NSPredicate(format: "bidOrder > %@", NSNumber(integerLiteral: 0)))
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: array)
        linesArray = (linesArray as NSArray).filtered(using: predicate) as! [BILine]
        DispatchQueue.main.async {
            self.btnBidListCount.setTitle("\(linesArray.count)", for: .normal)
        }
    }
    
    func setupUI(){
        btnBidListCount.layer.cornerRadius = btnBidListCount.frame.height/2
        btnSortTheBidlist.backgroundColor = .systemRed
        btnSortTheScratchpad.backgroundColor = .systemGreen
        tableView.isEditing = true
        calendarData = calendarData.initWithBidPeriod(bidPeriod: bidPeriod!)!
        updateBidListCount()
    }
    
    @objc func setupLayoutView() {
        if AppData.shared.isBidListSort {
            self.btnFilter.isHidden = true
            self.btnPreset.isHidden = true
            self.btnBids.isHidden = true
            btnSortTheBidlist.backgroundColor = .systemGreen
            btnSortTheScratchpad.backgroundColor = .systemRed
            
        }
        else {
            self.btnBidListCount.isHidden = false
            self.btnFilter.isHidden = false
            self.btnPreset.isHidden = false
            self.btnBids.isHidden = false
            btnSortTheBidlist.backgroundColor = .systemRed
            btnSortTheScratchpad.backgroundColor = .systemGreen
            
        }
    }
    
    @IBAction func btnFilterAction(_ sender: Any) {
        let storyboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBFilterRulesTableVC") as! CBFilterRulesTableVC
        self.navigationController?.pushViewController(vc, animated: false)
    }
    
    @IBAction func btnPresetAction(_ sender: Any) {
        let storyboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBPresetsTVC") as! CBPresetsTVC
        self.navigationController?.pushViewController(vc, animated: false)
    }
    
    @IBAction func btnBidsAction(_ sender: Any) {
        let storyboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBBidListVC") as! CBBidListVC
        self.navigationController?.pushViewController(vc, animated: false)
        UIView.transition(from: self.view, to: vc.view, duration: 0.65, options: [.transitionFlipFromLeft])
    }
    
    @IBAction func btnAddAction(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Filter", bundle: nil)
        let sortMenuController = storyboard.instantiateViewController(withIdentifier: "CBSortRulesMenuTableVC") as! CBSortRulesMenuTableVC
        let title = String(format: "Add Sort")
        sortMenuController.navigationItem.title = title
        sortMenuController.bidPeriod = CBGlobalMethods.shared.selectedBidPeriod!
        let count = (self.sortsFetchController.fetchedObjects?.count ?? 0) + 1
        sortMenuController.nextSortOrder = NSNumber(integerLiteral: count)
        sortMenuController.navigationController?.navigationBar.backgroundColor = .lightGray
        sortMenuController.menuItems = BILineSort.lineSortCategories(for: CBGlobalMethods.shared.selectedBidPeriod!) as NSArray
        sortMenuController.arrowDirection = .right
        if bidPeriod?.isBidListSortOn == true {
            sortMenuController.arrowDirection = .left
        }
        let navigationController = UINavigationController(rootViewController: sortMenuController)
        navigationController.navigationBar.isTranslucent = false
        navigationController.navigationBar.barTintColor = .lightGray
        let frame = CGRect(x: sender.frame.origin.x - 30, y: sender.frame.origin.y - 20, width: sender.frame.width, height: sender.frame.height)
        sortMenuController.showPopover(withNavigationController: sender, sourceRect: frame)
    }
    
    @IBAction func btnSortTheBidListAction(_ sender: Any) {
        if btnSortTheBidlist.backgroundColor == .systemRed {
            let alert = UIAlertController(title: "Confirmation", message: "Do you want to sort the bid list?", preferredStyle: .alert)
            let yesAction = UIAlertAction(title: "Yes", style: .default) { _ in
                self.btnSortTheBidlist.backgroundColor = .systemGreen
                self.btnSortTheScratchpad.backgroundColor = .systemRed
                AppData.shared.isBidListSort = true
                NotificationCenter.default.post(name: NSNotification.Name("SortBidListAction"), object: self)
                self.btnFilter.isHidden = true
                self.btnPreset.isHidden = true
                self.btnBids.isHidden = true
                self.btnBidListCount.isHidden = true
            }
            let noAction = UIAlertAction(title: "No", style: .cancel, handler: nil)
            alert.addAction(noAction)
            alert.addAction(yesAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func btnSortTheScratchpadAction(_ sender: Any) {
        if btnSortTheScratchpad.backgroundColor == .systemRed {
            btnSortTheScratchpad.backgroundColor = .systemGreen
            btnSortTheBidlist.backgroundColor = .systemRed
            AppData.shared.isBidListSort = false
            NotificationCenter.default.post(name: NSNotification.Name("SortBidListAction"), object: self)
            btnFilter.isHidden = false
            btnPreset.isHidden = false
            btnBids.isHidden = false
            btnBidListCount.isHidden = false
        }
    }
    
    
    @IBAction func btnBidListCountAction(_ sender: Any) {
    }
    
    @objc func updateLines() {
        bidPeriod = CBGlobalMethods.shared.selectedBidPeriod
        let moc = bidPeriod?.managedObjectContext
        let fetchRequest: NSFetchRequest<BILineSort> = BILineSort.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
        let predicate1 = NSPredicate(format: "bidPeriod == %@", bidPeriod!)
        if self.bidPeriod?.isBidListSortOn == true {
            let predicate2 = NSPredicate(format: "isBidListSort == %@", NSNumber(value: true))
            let combinedPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate1, predicate2])
            fetchRequest.predicate = combinedPredicate
        }
        else {
            let predicate2 = NSPredicate(format: "isBidListSort != %@", NSNumber(value: true))
            let combinedPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate1, predicate2])
            fetchRequest.predicate = combinedPredicate
        }
        self.sortsFetchController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc!, sectionNameKeyPath: nil, cacheName: nil)
        sortsFetchController.delegate = self
        do {
            try self.sortsFetchController.performFetch()
        }
        catch {
            print("Failed to perform filter rule fetch: \(error.localizedDescription)")
        }
        let fetchedObjects = try! moc!.fetch(fetchRequest)
        tableView.reloadData()
    }
}

extension CBLineSortsTVC: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return (self.sortsFetchController.sections?.count) ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section
        if let sectionInfo = sortsFetchController.sections?[section] {
            return sectionInfo.numberOfObjects
        }
        // Fallback if sections is nil
        // return filterRulesController?.fetchedObjects?.count ?? 0
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let kLineSortCellIdentifier = "LineSortCell"
        let kCityLineSortCellIdentifier = "CityLineSortCell"
        let kCommutingLineSortCellIdentifier = "CommutingLineSortCell"
        let kCommutabilityLineSortCellIdentifier = "CommutabilitySortCell"
        let kDaysOffLineSortCellIdentifier = "DayMonthLineSortCell"
        let kFlagSortCellIdentifier = "flagSortCell"
        
        let lineSort = self.sortsFetchController.object(at: indexPath)
        var cellIdentifier = kLineSortCellIdentifier
        
        if ((lineSort.category?.intValue  == BILineSortCategory.BICitiesLineSortCategory.rawValue &&
             lineSort.type?.intValue != BICityLineSortType.BICitiesLineSortTypeNonConusLegs.rawValue) ||
            (lineSort.category?.intValue  == BILineSortCategory.BIDeadheadsLineSortCategory.rawValue &&
             (lineSort.type?.intValue == BIDeadheadLineSortType.BIDeadheadAtStartSortType.rawValue ||
                lineSort.type?.intValue == BIDeadheadLineSortType.BIDeadheadAtEndSortType.rawValue ||
              lineSort.type?.intValue == BIDeadheadLineSortType.BIDeadheadAtBothSortType.rawValue))) {
            
            cellIdentifier = kCityLineSortCellIdentifier
        }
        
        
        else if lineSort.category?.intValue == BILineSortCategory.BICommutingLineSortCategory.rawValue {
            cellIdentifier = kCommutingLineSortCellIdentifier
        }
        else if lineSort.category?.intValue == BILineSortCategory.BICommutabilityLineSortCategory.rawValue {
            cellIdentifier = kCommutabilityLineSortCellIdentifier
        }
        else if lineSort.category?.intValue == BILineSortCategory.BIDaysOffLineSortCategory.rawValue {
            cellIdentifier = kDaysOffLineSortCellIdentifier
        }
        else if lineSort.category?.intValue == BILineSortCategory.BIDaysWorkLineSortCategory.rawValue {
            cellIdentifier = kDaysOffLineSortCellIdentifier
        }
        else if lineSort.category?.intValue == BILineSortCategory.BIDaysTripStartSortCategory.rawValue {
            cellIdentifier = kDaysOffLineSortCellIdentifier
        }
        else if lineSort.category?.intValue == BILineSortCategory.BIFlagLineSortCategory.rawValue {
            cellIdentifier = kFlagSortCellIdentifier
        }
        
        if cellIdentifier == "flagSortCell" {
            let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! CBFlagSortCell
            self.configure(cell: cell, for: sortsFetchController.object(at: indexPath))
            return cell
        }
       else if  cellIdentifier == kCommutingLineSortCellIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! CBCommutingSortCell
//           cell.titleLabel.text = title
           self.configure(cell: cell, for: sortsFetchController.object(at: indexPath))
            return cell
        }
        else if  cellIdentifier == kDaysOffLineSortCellIdentifier {
             let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! CBDayMonthSortCell
            self.configure(cell: cell, for: sortsFetchController.object(at: indexPath))
             return cell
         }
        else if  cellIdentifier == kCommutabilityLineSortCellIdentifier {
             let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! CBCommutabilitySortCell
            cell.btnTitle.setTitle(title, for: .normal)
            self.configure(cell: cell, for: sortsFetchController.object(at: indexPath))
             return cell
         }
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! CBLineSortCell
//        cell.titleLabel.text = title
        self.configure(cell: cell, for: sortsFetchController.object(at: indexPath))
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let sectionInfo = self.sortsFetchController.sections![indexPath.section] as? NSFetchedResultsSectionInfo
        let numOfRows = sectionInfo?.numberOfObjects ?? 0
        if numOfRows > indexPath.row {
            if let sort = self.sortsFetchController.object(at: indexPath) as? BILineSort {
                if sort.category?.intValue == BILineSortCategory.BICommutingLineSortCategory.rawValue {
                    return 270.0
                }
                else if sort.category?.intValue == BILineSortCategory.BIDaysOffLineSortCategory.rawValue {
                    return 330.0
                }
                else if sort.category?.intValue == BILineSortCategory.BIDaysWorkLineSortCategory.rawValue {
                    return 330.0
                }
                else if sort.category?.intValue == BILineSortCategory.BIDaysTripStartSortCategory.rawValue {
                    return 330.0
                }
                else if sort.category?.intValue == BILineSortCategory.BIFlagLineSortCategory.rawValue {
                    return CGFloat(((sort.variables?.count)! * 50) + 20)
                }
                else if sort.category?.intValue == BILineSortCategory.BIDeadheadsLineSortCategory.rawValue {
                    return 70.0
                }
                else if sort.category?.intValue == BILineSortCategory.BICommutabilityLineSortCategory.rawValue {
                    return 70.0
                }
                else {
                    return 70.0
                }
            }
        }
        else {
            return 70
        }
    }
    
    //MARK: - Sort table reordering
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        // If from row and to row are the same (not really a move), do nothing.
        if sourceIndexPath == destinationIndexPath { return }
        //         Since the table view already reflects the order of the objects, do not
        //         update the table view for these model changes.
                self.ignoreDataModelChanges = true
        let fromRow = sourceIndexPath.row
        let toRow = destinationIndexPath.row
        // Set the order of the moved line sort (at from row) to the to row.
        var lineSort = sortsFetchController.object(at: sourceIndexPath)
        lineSort.order = NSNumber(integerLiteral: toRow + 1)
        // From row greater than to row (move up in list). Change the order of line
        // sorts between (inclusive) of the from and to rows.
        if fromRow > toRow {
            // Set the order of the line sorts at the to row, down to the from row.
            for row in toRow..<fromRow {
                let indexPath = IndexPath(row: row, section: 0)
                lineSort = sortsFetchController.object(at: indexPath)
                //Added the default value to fix crash
                lineSort.order = NSNumber(integerLiteral: ((lineSort.order?.intValue ?? 1) + 1))
            }
        }
        // From row less than to row (move down in list).
        else {
            for row in (fromRow + 1) ... toRow {
                let indexPath = IndexPath(row: row, section: 0)
                lineSort = sortsFetchController.object(at: indexPath)
                //Added the default value to fix crash
                lineSort.order = NSNumber(integerLiteral: (lineSort.order!.intValue  - 1))
            }
        }
        try? bidPeriod?.managedObjectContext?.save()
        NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return UITableViewCell.EditingStyle.none
    }
    
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func configure(cell: UITableViewCell, for lineSort: BILineSort) {
        cell.showsReorderControl = true
        cell.textLabel?.alpha = 1
        cell.isUserInteractionEnabled = true
        cell.contentView.alpha = 1
        if lineSort.category?.intValue == BILineSortCategory.BICitiesLineSortCategory.rawValue || (lineSort.category?.intValue == BILineSortCategory.BIDeadheadsLineSortCategory.rawValue && (lineSort.type?.intValue == BIDeadheadLineSortType.BIDeadheadAtEndSortType.rawValue || lineSort.type?.intValue == BIDeadheadLineSortType.BIDeadheadAtStartSortType.rawValue || lineSort.type?.intValue == BIDeadheadLineSortType.BIDeadheadAtBothSortType.rawValue)) {
            let myCell = cell as! CBLineSortCell
            myCell.bidPeriod = self.bidPeriod
            myCell.lineSort = lineSort
            myCell.swapImgView.alpha = 0.0
            if let textField = myCell.cityNametxt {
                textField.text = lineSort.city ?? ""
            }
        }
        else if lineSort.category?.intValue == BILineSortCategory.BIDaysOffLineSortCategory.rawValue {
            let dayMonthCell = cell as! CBDayMonthSortCell
            dayMonthCell.bidPeriod = self.bidPeriod
            dayMonthCell.calendarData = self.calendarData
            dayMonthCell.lineSort = lineSort
            dayMonthCell.type = .Off
            dayMonthCell.calendarCollectionView.reloadData()
        }
        else if lineSort.category?.intValue == BILineSortCategory.BIDaysWorkLineSortCategory.rawValue {
            let dayMonthCell = cell as! CBDayMonthSortCell
            dayMonthCell.bidPeriod = self.bidPeriod
            dayMonthCell.calendarData = self.calendarData
            dayMonthCell.lineSort = lineSort
            dayMonthCell.type = .Work
            dayMonthCell.calendarCollectionView.reloadData()
        }
        else if lineSort.category?.intValue == BILineSortCategory.BIDaysTripStartSortCategory.rawValue {
            let dayMonthCell = cell as! CBDayMonthSortCell
            dayMonthCell.bidPeriod = self.bidPeriod
            dayMonthCell.calendarData = self.calendarData
            dayMonthCell.lineSort = lineSort
            dayMonthCell.type = .TripStart
            dayMonthCell.calendarCollectionView.reloadData()
        }
        else if lineSort.category?.intValue == BILineSortCategory.BICommutingLineSortCategory.rawValue {
            let sortCell = cell as! CBCommutingSortCell
            sortCell.bidPeriod = self.bidPeriod
            sortCell.lineSort = lineSort
            sortCell.CalculateCommutingManualSort() // need to code in this function
        }
        else if lineSort.category?.intValue == BILineSortCategory.BIFlagLineSortCategory.rawValue {
            let flagCell = cell as! CBFlagSortCell
            let viewToRemove = cell.contentView.viewWithTag(101)
            if (viewToRemove != nil) {
                viewToRemove?.removeFromSuperview()
            }
            flagCell.bidPeriod = self.bidPeriod
            flagCell.lineSort = lineSort
            flagCell.configureFlagSortCell()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                flagCell.objFlagTableView.reloadData()
            }
        }
        else if lineSort.category?.intValue == BILineSortCategory.BISwaptimizerLineSortCategory.rawValue {
            let myCell = cell as! CBLineSortCell
            myCell.lineSort = lineSort
            myCell.bidPeriod = self.bidPeriod
            myCell.swapImgView.isHidden = false
            myCell.swapImgView.image = UIImage(named: SwaptimizerVacationImage)
            myCell.contentView.addSubview(myCell.swapImgView)
            myCell.swapImgView.tag = 101
            if let lenght = bidPeriod!.vacationType?.count {
                if !(lenght > 0) {
                    myCell.swapImgView.alpha = 0.5
                    myCell.textLabel?.alpha = 0.5
                    myCell.isUserInteractionEnabled = false
                    myCell.contentView.alpha = 0.5
                }
                else {
                    myCell.swapImgView.alpha = 1
                    myCell.textLabel?.alpha = 1
                    myCell.isUserInteractionEnabled = true
                    myCell.contentView.alpha = 1
                }
            }
        }
        else if lineSort.category?.intValue == BILineSortCategory.BIFaVacationLineSortCategory.rawValue {
            let mycell = cell as! CBLineSortCell
            mycell.lineSort = lineSort
            mycell.bidPeriod = self.bidPeriod
            let swapImage = UIImage(named: SwaptimizerVacationImage)
            mycell.swapImgView.isHidden = false
            mycell.swapImgView.image = swapImage
            if let lenght = bidPeriod!.vacationType?.count {
                if !(lenght > 0) {
                    mycell.swapImgView.alpha = 0.5
                    mycell.textLabel?.alpha = 0.5
                    mycell.isUserInteractionEnabled = false
                    mycell.contentView.alpha = 0.5
                } else {
                    mycell.swapImgView.alpha = 1.0
                    mycell.textLabel?.alpha = 1.0
                    mycell.isUserInteractionEnabled = true
                    mycell.contentView.alpha = 1
                }
            }
        }
        else if lineSort.category?.intValue == BILineSortCategory.BICommutabilityLineSortCategory.rawValue {
            let sortCell = cell as! CBCommutabilitySortCell
            sortCell.lineSort1 = lineSort
            sortCell.lineSort = lineSort
            sortCell.configurecommutabilitySortCell()
        }
        else {
            let mycell = cell as! CBLineSortCell
            mycell.lineSort = lineSort
            mycell.bidPeriod = self.bidPeriod
            mycell.swapImgView.alpha = 0.0
            let viewToRemove = mycell.contentView.viewWithTag(101)
            if (viewToRemove != nil) {
                viewToRemove?.removeFromSuperview()
            }
        }
        // FIXME: for testing segmented control background image.
//        need to be added
        if lineSort.category?.intValue == BILineSortCategory.BIDeadheadsLineSortCategory.rawValue {
            print("DeadHeads")
            let mycell = cell as! CBLineSortCell
            mycell.lineSort = lineSort
            mycell.bidPeriod = self.bidPeriod
            mycell.swapImgView.alpha = 0.0
            let viewToRemove = cell.contentView.viewWithTag(101)
            if (viewToRemove != nil) {
                viewToRemove?.removeFromSuperview()
            }
        }
    }
    
}

