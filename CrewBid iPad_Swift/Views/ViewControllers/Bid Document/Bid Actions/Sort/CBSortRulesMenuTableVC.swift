//
//  CBSortRulesMenuTableVC.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 25/03/25.
//

import UIKit
import CoreData

class CBSortRulesMenuTableVC: UIViewController,UITableViewDelegate,UITableViewDataSource,KUIPopOverUsable {

    @IBOutlet weak var tableView: UITableView!
    var menuItems = NSArray()
    private var kCellReuseIdentifier = "menuCell"
    var arrowDirection: UIPopoverArrowDirection = AppData.shared.isBidListSort == true ? UIPopoverArrowDirection.left : UIPopoverArrowDirection.right
    var bidPeriod: BIBidPeriod?
    var disabledCellIndexPaths = NSArray()
    var nextSortOrder: NSNumber!
    
    var contentSize: CGSize {
        var height : CGFloat = 40 * CGFloat(self.menuItems.count)
        if height > 700 {
            height = 700
        }
        preferredContentSize = CGSize(width: 310, height: height + 30)
        return CGSize(width: preferredContentSize.width, height: preferredContentSize.height)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bidPeriod = CBGlobalMethods.shared.selectedBidPeriod!
        setupViewDidLoad()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: kCellReuseIdentifier)
        self.tableView.separatorInset = .zero
        self.tableView.reloadData()
        // Do any additional setup after loading the view.
    }
    
    func setupViewDidLoad() {
        bidPeriod = CBGlobalMethods.shared.selectedBidPeriod
        let moc = bidPeriod?.managedObjectContext
        let fetchRequest: NSFetchRequest<BILineSort> = BILineSort.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
        let predicate1 = NSPredicate(format: "bidPeriod == %@", bidPeriod!)
        var predicate2: NSPredicate?
        if self.bidPeriod?.isBidListSortOn?.boolValue == true {
            predicate2 = NSPredicate(format: "isBidListSort == %@", NSNumber(value: true))
            
        }
        else {
            predicate2 = NSPredicate(format: "isBidListSort != %@", NSNumber(value: true))
        }
        var abbreviations = menuItems.value(forKey: "abbreviation") as? NSArray
        let tempAbbreviations = abbreviations!.mutableCopy() as? NSMutableArray
        for i in 0..<abbreviations!.count {
            let abbreviation = abbreviations![i]
            if !(abbreviation is NSNull) {
                if let abbreviationStr = abbreviation as? String,
                   abbreviationStr == "LegsThru" || abbreviationStr == "OvernightCity" {
                    tempAbbreviations!.replaceObject(at: i, with: NSNull())
                }
            }
        }
        abbreviations = tempAbbreviations
        let predicate3 = NSPredicate(format: "abbreviation IN %@", (abbreviations as? NSArray)!)
        let combinedPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate1, predicate2!, predicate3])
        fetchRequest.predicate = combinedPredicate
        do {
            let results = try moc?.fetch(fetchRequest)
            let disabledCellIndexPaths = NSMutableArray(capacity: menuItems.count)
            for linerule in results ?? [] {
                let index = abbreviations!.index(of: linerule.abbreviation)
                if index != NSNotFound {
                    let indexPath = IndexPath(row: index, section: 0)
                    disabledCellIndexPaths.add(indexPath)
                }
            }

            self.disabledCellIndexPaths = disabledCellIndexPaths
            navigationController?.navigationBar.backgroundColor = UIColor.lightGray
            if #available(iOS 15, *) {
                if navigationController != nil {
                    let appearance = navigationController!.navigationBar.standardAppearance
                    navigationController?.navigationBar.compactAppearance = appearance
                    navigationController?.navigationBar.standardAppearance = appearance
                    navigationController?.navigationBar.scrollEdgeAppearance = appearance
                    navigationController?.navigationBar.compactScrollEdgeAppearance = appearance
                }
            }
        }
        catch {
            print("error fetching BILineSort \(error.localizedDescription)")
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: kCellReuseIdentifier, for: indexPath)
        cell.selectionStyle = .gray
        let item = self.menuItems[indexPath.row] as! [String: Any]
        var title = item[kCategoryTitleLineSortKey] as? String
        if title == nil {
            title = (item[kNameLineSortKey] as! String)
        }
        cell.textLabel?.text = title
        let types = item[kCategoryTypesLineSortKey] as? [Any] ?? []
        if (types.count > 0) {
            cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
        }
        else {
            cell.accessoryType = UITableViewCell.AccessoryType.none
        }
        let num = item["category"] as? Int ?? 0
        let category = BILineSortCategory(rawValue: num)
        if category == BILineSortCategory.BISwaptimizerLineSortCategory || title == "SWAPtimizer" {
            var typeInt: Int = 0
            if item["type"] != nil {
                typeInt = item["type"] as! Int
            }
            let type = BIVacationLineSortType(rawValue: typeInt)!
            if title != "SWAPtimizer" && self.cellIsHiddenForType(type: type) {
                var size = self.preferredContentSize
                size.height -= self.tableView.rowHeight
                self.preferredContentSize = size
                cell.isHidden = true
            }
            else {
                let swapImage = UIImage(named: SwaptimizerVacationImage)
                if types.count > 0 {
                    if SwaptimizerVacationImage == "SwaptAlert" {
                        cell.textLabel?.text = "SWAPtimizer"
                    }
                    else if SwaptimizerVacationImage == "WBidmax-logo" {
                        cell.textLabel?.text = "WBidMax"
                    }
                }
                let swapImgView = UIImageView(frame: CGRect(x: 200, y: 3, width: 34, height: 34))
                swapImgView.tag = 101
                swapImgView.image = swapImage
                cell.contentView.addSubview(swapImgView)
                //Enabling or disabling vacation sort
                if (!(self.bidPeriod?.vacationType?.count ?? 0 > 1)) {
                    swapImgView.alpha = 0.5
                    cell.textLabel?.alpha = 0.5
                    cell.isUserInteractionEnabled = false
                }
            }
        }
        else if BILineSortCategory.BIFaVacationLineSortCategory == category || title == "Vacation" {
            let swapImage = UIImage(named: "FA_Vacation_Image_Shadow")
            let swapImgView = UIImageView(frame: CGRect(x: 200, y: 2, width: 40, height: 40))
            swapImgView.tag = 101
            swapImgView.image = swapImage
            cell.contentView.addSubview(swapImgView)
        }
        else {
            let viewToRemove = cell.contentView.viewWithTag(101)
            if let viewToRemove = viewToRemove {
                viewToRemove.removeFromSuperview()
            }
        }
        
        if disabledCellIndexPaths.contains(indexPath) {
            cell.textLabel?.textColor = .lightGray
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = self.menuItems[indexPath.row] as! [String: Any]
        let num = item["category"] as? Int ?? 0
        let category = BILineSortCategory(rawValue: num)
        if (category == BILineSortCategory.BISwaptimizerLineSortCategory) {
            let type = BIVacationLineSortType(rawValue: item["type"] as! Int)!
            if self.cellIsHiddenForType(type: type) {
                return 0
            }
            else {
                return 40
            }
        }
        else {
            return 40
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Don't select cells that represent line sorts that are already in the
        // list of line sorts.
        if self.disabledCellIndexPaths.contains(indexPath) {
            return
        }
        let item = self.menuItems[indexPath.row] as! [String: Any]
        let types = item[kCategoryTypesLineSortKey] as? [Any] ?? []
        if types.count > 0 {
            let storyboard = UIStoryboard(name: "Filter", bundle: nil)
            let menuController = storyboard.instantiateViewController(withIdentifier: "CBSortRulesMenuTableVC") as! CBSortRulesMenuTableVC
            menuController.nextSortOrder = self.nextSortOrder
            menuController.menuItems = types as NSArray
            menuController.bidPeriod = self.bidPeriod
            menuController.title = item[kCategoryTitleLineSortKey] as? String
            if menuController.title?.lowercased() == "swaptimizer" {
                if SwaptimizerVacationImage == "SwaptAlert" {
                    menuController.title = "SWAPtimizer"
                }
                else if SwaptimizerVacationImage == "WBidmax-logo" {
                    menuController.title = "WBidMax"
                }
            }
            // Determine which cells should be disabled, so that there are no
            // duplicate sorts.
            let moc = bidPeriod?.managedObjectContext
            var fetchRequest: NSFetchRequest<BILineSort> = BILineSort.fetchRequest()
            var subPredicates: [NSPredicate] = []
            if (self.bidPeriod?.isBidListSortOn?.boolValue == true) {
                subPredicates.append(NSPredicate(format: "isBidListSort == \(NSNumber(value: true))"))
            }
            else {
                subPredicates.append(NSPredicate(format: "isBidListSort != \(NSNumber(value: true))"))
            }
            subPredicates.append(NSPredicate(format: "bidPeriod == %@", bidPeriod!))
            var abbreviations = menuItems.value(forKey: "abbreviation") as? NSArray
            var tempAbbreviations = abbreviations!.mutableCopy() as? NSMutableArray
            for i in 0..<abbreviations!.count {
                let abbreviation = abbreviations![i]
                if !(abbreviation is NSNull) {
                    if let abbreviationStr = abbreviation as? String,
                       abbreviationStr == "LegsThru" || abbreviationStr == "OvernightCity" {
                        tempAbbreviations!.replaceObject(at: i, with: NSNull())
                    }
                }
            }
            abbreviations = tempAbbreviations
            subPredicates.append(NSPredicate(format: "abbreviation IN %@", (abbreviations as? NSArray)!))
            let combinedPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: subPredicates)
            fetchRequest.predicate = combinedPredicate
            do {
                let results = try moc?.fetch(fetchRequest)
                let disabledCellIndexPaths = NSMutableArray(capacity: menuItems.count)
                for linerule in results ?? [] {
                    let index = abbreviations!.index(of: linerule.abbreviation)
                    if index != NSNotFound {
                        let indexPath = IndexPath(row: index, section: 0)
                        disabledCellIndexPaths.add(indexPath)
                    }
                }

                self.disabledCellIndexPaths = disabledCellIndexPaths
                self.navigationController?.pushViewController(menuController, animated: false)
            }
            catch {
                print("error fetching BILineSort \(error.localizedDescription)")
            }
        }
        else {
            tableView.allowsSelection = false
            let item = self.menuItems[indexPath.row] as! [String: Any]
            var lineSort: BILineSort!
            let num = item["category"] as? Int ?? 0
            let category = BILineSortCategory(rawValue: num)
            if category == BILineSortCategory.BICommutabilityLineSortCategory {
                var sortPredicate = NSPredicate(format: "isBidListSort != \(NSNumber(value: true))")
                if self.bidPeriod?.isBidListSortOn?.boolValue == true {
                    sortPredicate = NSPredicate(format: "isBidListSort == \(NSNumber(value: true))")
                }
                let predicate1:NSPredicate = NSPredicate(format: "category == 12")
                let predicate2:NSPredicate = NSPredicate(format: "category == 4")
                let compound1:NSCompoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [sortPredicate,predicate2])
                //Filter Fetch
                let resultFilter = (CBGlobalMethods.shared.selectedBidPeriod!.lineFilters!.allObjects as NSArray).filtered(using: predicate1) as! [BIFilterRule]
                //Sort Fetch
                let resultSort = (CBGlobalMethods.shared.selectedBidPeriod!.lineSorts!.allObjects as NSArray).filtered(using: compound1) as! [BILineSort]
                if resultSort.count > 0 || resultFilter.count > 0 {
                    AlertService.showAlertForTopVC(title: "Crewbid", message: "You can only add a Commutable Line - Auto or a Commutable Line - Manual constraint, but NOT both.", actions: [(title: "Ok", style: .default, handler: { action in
                        print("Button clicked: \(action.title ?? "")")
                        DispatchQueue.main.async {
                            self.dismiss(animated: true, completion: nil)
                        }
                    }),
                     (title: "Cancel", style: .default, handler: { action in
                        print("Button clicked: \(action.title ?? "")")
                        tableView.allowsSelection = true
                    })])
                    return
                }
                else {
                    let fetchRequest: NSFetchRequest<Commutability> = Commutability.fetchRequest()
                    let context = bidPeriod?.managedObjectContext
                    fetchRequest.predicate = NSPredicate(format: "commutableType == %d", CommutabilityType.filter.rawValue)
                    do {
                        let fetchedObjects = try context?.fetch(fetchRequest) ?? []
                        if fetchedObjects.count > 0 {
                            let lineSort = BILineSort(context: context!)
                            if (self.bidPeriod?.isBidListSortOn?.boolValue == true) {
                                lineSort.isBidListSort = NSNumber(value: true)
                            }
                            else {
                                lineSort.isBidListSort = NSNumber(value: false)
                            }
                            var dicCommutablility = [String: Any]()
                            dicCommutablility["abbreviation"] = "CmAuto"
                            dicCommutablility["category"] = NSNumber(integerLiteral: 9)
                            dicCommutablility["type"] = NSNumber(integerLiteral: 1)
                            dicCommutablility["name"] = "Commutability"
                            dicCommutablility["keyPath"] = "commutabilityOverall"
                            dicCommutablility["isMutable"] = NSNumber(integerLiteral: 1)
                            dicCommutablility["ascending"] = NSNumber(integerLiteral: 0)
                            let dicVariables = [String: Any]()
                            dicCommutablility["variables"] = dicVariables
                            lineSort.setValuesForKeys(dicCommutablility)
                            
                            let ObjcommutabilityFilter: Commutability!
                            ObjcommutabilityFilter = fetchedObjects[0]
                            let ObjcommutabilitySort: Commutability!
                            ObjcommutabilitySort = Commutability(context: context!)                     
                            ObjcommutabilitySort.type = 1
                            ObjcommutabilitySort.secondCellValue = 1
                            ObjcommutabilitySort.thirdCellValue = 3
                            ObjcommutabilitySort.value = 100
                            ObjcommutabilitySort.commutableType = 1
                            ObjcommutabilitySort.city = ObjcommutabilityFilter.city;
                            ObjcommutabilitySort.checkInTime = ObjcommutabilityFilter.checkInTime;
                            ObjcommutabilitySort.connectTime = ObjcommutabilityFilter.connectTime;
                            ObjcommutabilitySort.baseTime = ObjcommutabilityFilter.baseTime;
                            
                            do {
                                try context?.save()
                            }
                            catch {
                                print("error saving commutablity \(error.localizedDescription)")
                            }
                        }
                        else {
                            DispatchQueue.main.async {
                                self.dismiss(animated: true, completion: nil)
                            }
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ShowCommutabilitySortView"), object: self)
                        }
                    }
                    catch {
                        print("error fetching commutablity \(error.localizedDescription)")
                        DispatchQueue.main.async {
                            self.dismiss(animated: true, completion: nil)
                        }
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ShowCommutabilitySortView"), object: self)
                    }
                }
                
            }
            else if category == BILineSortCategory.BICommutingLineSortCategory{
                var sortPredicate = NSPredicate(format: "isBidListSort != \(NSNumber(value: true))")
                if self.bidPeriod!.isBidListSortOn?.boolValue == true {
                    sortPredicate = NSPredicate(format: "isBidListSort == \(NSNumber(value: true))")
                }
                let predicate1:NSPredicate = NSPredicate(format: "category == 33")
                let predicate2:NSPredicate = NSPredicate(format: "category == 9")
                let compound1:NSCompoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [sortPredicate,predicate2])
                //Filter Fetch
                let resultFilter = (CBGlobalMethods.shared.selectedBidPeriod!.lineFilters!.allObjects as NSArray).filtered(using: predicate1) as! [BIFilterRule]
                //Sort Fetch
                let resultSort = (CBGlobalMethods.shared.selectedBidPeriod!.lineSorts!.allObjects as NSArray).filtered(using: compound1) as! [BILineSort]
                if resultSort.count > 0 || resultFilter.count > 0 {
                    AlertService.showAlertForTopVC(title: "Crewbid", message: "You can only add a Commutable Line - Auto or a Commutable Line - Manual constraint, but NOT both.", actions: [(title: "Ok", style: .default, handler: { action in
                        print("Button clicked: \(action.title ?? "")")
                        DispatchQueue.main.async {
                            self.dismiss(animated: true, completion: nil)
                        }
                    }),
                     (title: "Cancel", style: .default, handler: { action in
                        print("Button clicked: \(action.title ?? "")")
                        tableView.allowsSelection = true
                    })])
                    return
                }
                else {
                    let context = self.bidPeriod?.managedObjectContext
                    let lineSort = BILineSort(context: context!)
                    if (self.bidPeriod!.isBidListSortOn?.boolValue == true){
                        lineSort.isBidListSort = NSNumber(value: true)
                    }else {
                        lineSort.isBidListSort = NSNumber(value: false)
                    }
                    lineSort.setValuesForKeys(item)
                    lineSort.bidPeriod = self.bidPeriod
                    lineSort.order = self.nextSortOrder
                }
            }
            else if category == BILineSortCategory.BIFlagLineSortCategory {
                tableView.allowsSelection = true
                let storyboard = UIStoryboard(name: "BidDocument", bundle: nil)
                let flagPopUp = storyboard.instantiateViewController(withIdentifier: "CBFlagSortPopUp") as! CBFlagSortPopUp
                flagPopUp.preferredContentSize = CGSize(width: 320, height: 510)
                flagPopUp.bidPeriod = self.bidPeriod
                flagPopUp.nextSortOrder = self.nextSortOrder
                flagPopUp.modalPresentationStyle = UIModalPresentationStyle.formSheet
                flagPopUp.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
                self.present(flagPopUp, animated: true, completion: nil)
                return
            }
            else if !(category == BILineSortCategory.BIPositionsLineSortCategory) {
                let context = self.bidPeriod?.managedObjectContext
                let lineSort = BILineSort(context: context!)
                lineSort.setValuesForKeys(item)
                lineSort.bidPeriod = self.bidPeriod
                if (self.bidPeriod!.isBidListSortOn?.boolValue == true){
                    lineSort.isBidListSort = NSNumber(value: true)
                }else {
                    lineSort.isBidListSort = NSNumber(value: false)
                }
                // Note that, for some sorts (e.g., cities) the sort values from the
                // menu items may not contain a key path because the key path cannot
                // be determined until a value is set (e.g., city) for that sort.
                lineSort.order = self.nextSortOrder
                if lineSort.sortHighlightsTrips() && lineSort.category?.intValue != BILineSortCategory.BICommutingLineSortCategory.rawValue {
                    let type = lineSort.type?.intValue
                    if lineSort.category?.intValue == BILineSortCategory.BICitiesLineSortCategory.rawValue && (BICityLineSortType.BICitiesLineSortTypeEastCoast.rawValue == type || BICityLineSortType.BICitiesLineSortTypeWestCoast.rawValue == type || BICityLineSortType.BICitiesLineSortTypeNonConus.rawValue == type || BICityLineSortType.BICitiesLineSortTypeIntl.rawValue == type || BICityLineSortType.BICitiesLineSortTypeAll.rawValue == type || BICityLineSortType.BICitiesLineSortTypeHawaii.rawValue == type) {
                        var filterVars = lineSort.variables?.mutableCopy() as? [String: Any] ?? [:]
                        if filterVars["SET"] == nil {
                            lineSort.deHighlightTrips()
                            let set = NSSet(array: lineSort.selectedRegionalCities())
                            filterVars["SET"] = set
                            lineSort.variables = filterVars as NSDictionary
                            lineSort.keyPath = lineSort.bidPeriod?.lineSortKeyForCityLineSort(cityLineSort: lineSort, city: "")
                        }
                    }
                    lineSort.highlightTrips()
                }
            }
            else {
                // If it's the quick Add ABC selection, add ABC positions, but don't double up
                let fetchRequest: NSFetchRequest<BILineSort> = BILineSort.fetchRequest()
                let context = CBGlobalMethods.shared.selectedBidPeriod?.managedObjectContext!
                let num = item["type"] as? Int ?? 0
                if num == BIPositionsLineSortType.BIPositionQuickAddABCType.rawValue {
                    let abbreviations = self.menuItems.value(forKey: "abbreviation") as? [Any]
                    var subpredicates: [NSPredicate] = []
                    
                    if (self.bidPeriod!.isBidListSortOn!.boolValue){
                        subpredicates.append(NSPredicate(format: "isBidListSort == \(NSNumber(value: true))"))
                    }else{
                        subpredicates.append(NSPredicate(format: "isBidListSort != \(NSNumber(value: true))"))
                    }
                    subpredicates.append(NSPredicate(format: "abbreviation IN %@", abbreviations!))
                    
                    let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: subpredicates)
                    fetchRequest.predicate = predicate
                    fetchRequest.fetchLimit = self.menuItems.count
                    let results = try! context?.fetch(fetchRequest)
                    for i in 0..<3 {
                        let newItems = self.menuItems[i + 1] as! [String: Any]
                        // Check to make sure we're not doubling up on the Positions
                        let pred = NSPredicate(format: "abbreviation ==[c] %@", newItems["abbreviation"] as! String)
                        let filtered = results!.filter { pred.evaluate(with: $0)}
                        if filtered.count == 0 {
                            let posSort = BILineSort(context: context!)
                            posSort.setValuesForKeys(item)
                            let arr = ["Position A","Position B","Position C","Position D"]
                            let arr2 = ["A","B","C","D"]
                            posSort.setValue(arr[i], forKey: "name")
                            posSort.setValue(arr2[i], forKey: "abbreviation")
                            posSort.type = NSNumber(value: i)
                            posSort.bidPeriod = self.bidPeriod
                            posSort.order = self.nextSortOrder
                            // Craete the position lineSort keypath
                            posSort.keyPath = self.bidPeriod!.lineSortKeyForPosition(posLineSort: posSort)
                            //For correct position order
                            posSort.order = NSNumber(integerLiteral: (nextSortOrder?.intValue ?? 1) + i )
                            if (self.bidPeriod?.isBidListSortOn?.boolValue == true) {
                                posSort.isBidListSort = NSNumber(value: true)
                            }
                            else {
                                posSort.isBidListSort = NSNumber(value: false)
                            }
                        }
                    }
                }
                else {
                    let context = self.bidPeriod?.managedObjectContext
                    let lineSort = BILineSort(context: context!)
                    lineSort.setValuesForKeys(item)
                    lineSort.bidPeriod = self.bidPeriod
                    if (self.bidPeriod!.isBidListSortOn?.boolValue == true) {
                        lineSort.isBidListSort = NSNumber(value: true)
                    }
                    else {
                        lineSort.isBidListSort = NSNumber(value: false)
                    }
                    lineSort.order = self.nextSortOrder
                    lineSort.keyPath = self.bidPeriod!.lineSortKeyForPosition(posLineSort: lineSort)
                }
            }
            if let lineSort = lineSort {
                if (self.bidPeriod!.isBidListSortOn?.boolValue == true){
                    lineSort.isBidListSort = NSNumber(value: true)
                }else {
                    lineSort.isBidListSort = NSNumber(value: false)
                }
                if lineSort.sortHighlightsTrips() {
                    lineSort.highlightTrips()
                    lineSort.bidPeriod = self.bidPeriod
                }
            }
            try? bidPeriod?.managedObjectContext!.save()
            NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
            self.dismissPopover(animated: true)
        }
//        NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
    }
    
    func cellIsHiddenForType(type: BIVacationLineSortType) -> Bool {
        let hiddendict = UserDefaults.standard.object(forKey: kCBSwaptimizerHiddenDict) as! [String: Any]
        
        if ((BIVacationLineSortType.VacationPayBothBP == type && hiddendict[kCBSwaptmizerVacPayBothBPHidden] as? Bool == true) || (BIVacationLineSortType.VacationPayNextBP == type && hiddendict[kCBSwaptmizerVacPayNextBPHidden] as? Bool == true) || (BIVacationLineSortType.EffectiveVacationLength == type && hiddendict[kCBSwaptmizerEffVacayLengthHidden] as? Bool == true) || (BIVacationLineSortType.LongestBlockofDaysOff == type && hiddendict[kCBSwaptmizerLongestBlockofDaysOffHidden] as? Bool == true) || (BIVacationLineSortType.CarryOutPay == type && hiddendict[kCBSwaptmizerCarryOutPayHidden] as? Bool == true) || (BIVacationLineSortType.FrontVoPay == type && hiddendict[kCBSwaptmizerFrontVoHidden] as? Bool == true) || (BIVacationLineSortType.BackVoPay == type && hiddendict[kCBSwaptmizerBackVoHidden] as? Bool == true) || (BIVacationLineSortType.VacayCarryOutPay == type && hiddendict[kCBSwaptmizerVacayCarryOutPayHidden] as? Bool == true) || (BIVacationLineSortType.CarryOutVoPay == type && hiddendict[kCBSwaptmizerCarryOutVoHidden] as? Bool == true)) {
            return true
        }
        else {
            return false
        }
    }
}

protocol CBMenuTableViewControllerDelegate {
    func menuTableViewController(menuController: CBMenuTableVC, didSelectRowAtIndexPath indexPath: IndexPath)
    func menuTableViewControllerCitySelection(menuController: CBMenuTableVC,selectedCities: NSMutableSet )
}
