//
//  CBLineSortCell.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 24/03/25.
//

import UIKit

class CBLineSortCell: UITableViewCell, UIPopoverControllerDelegate {
    
    @IBOutlet weak var LHsegment: UISegmentedControl!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var cityNametxt: UITextField!
    
    var bidPeriod: BIBidPeriod?
    private var lineSort1: BILineSort!
    var context = CBGlobalMethods.shared.selectedBidPeriod?.managedObjectContext
    var swapImgView: UIImageView!
    var cityTextFieldDelegate: CBCityTextFieldDelegate!
    var menuItems: NSArray!
    var tapGesture: UITapGestureRecognizer!
    var citiesMenuController: CBMenuTableVC!
    
    var lineSort: BILineSort? {
        set(newLineSort){
           lineSort1 = newLineSort
            if let nameLabel = nameLabel {
                nameLabel.text = newLineSort?.name
            }
            if let LHsegment = self.LHsegment {
                LHsegment.selectedSegmentIndex = ((newLineSort?.ascending?.boolValue) ?? false) ? 0 : 1
                LHsegment.isHidden = !(newLineSort?.isMutable!.boolValue)!
            }
        }
        get {
            return lineSort1
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.cityTextFieldDelegate = CBCityTextFieldDelegate(textField: self.cityNametxt, delegate: self)
        if let cityTextField = self.cityNametxt {
            if let lineSort = self.lineSort {
                cityTextField.text = lineSort.city
            }
        }
        swapImgView = UIImageView(frame: CGRect(x: self.contentView.frame.width - 310, y: (self.contentView.frame.height/2) - 15, width: 30, height: 30))
        swapImgView.isHidden = true
        self.addSubview(swapImgView)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func layoutSubviews() {
        if let cityTextFeild = self.cityNametxt {
            cityTextFeild.placeholder = "City"
//            cityTextFeild.isEnabled = true
        }
        if self.lineSort != nil {
            let type = self.lineSort?.type?.intValue
            let category = self.lineSort?.category?.intValue
            if ((category == BILineSortCategory.BIDeadheadsLineSortCategory.rawValue && (type == BIDeadheadLineSortType.BIDeadheadAtStartSortType.rawValue || type == BIDeadheadLineSortType.BIDeadheadAtEndSortType.rawValue || type == BIDeadheadLineSortType.BIDeadheadAtBothSortType.rawValue))
                || (category == BILineSortCategory.BICitiesLineSortCategory.rawValue && (type == BICityLineSortType.BIOvernightCityLineSortType.rawValue || type == BICityLineSortType.BILegCityLineSortType.rawValue))) {
                cityNametxt.isHidden = false
            }
            else {
                cityNametxt.isHidden = true
            }
            
            if ((category == BILineSortCategory.BIDeadheadsLineSortCategory.rawValue && (type == BIDeadheadLineSortType.BIDeadheadAtStartSortType.rawValue || type == BIDeadheadLineSortType.BIDeadheadAtEndSortType.rawValue || type == BIDeadheadLineSortType.BIDeadheadAtBothSortType.rawValue)) || (category == BILineSortCategory.BICitiesLineSortCategory.rawValue && (type == BICityLineSortType.BICitiesLineSortTypeEastCoast.rawValue || type == BICityLineSortType.BICitiesLineSortTypeWestCoast.rawValue || type == BICityLineSortType.BICitiesLineSortTypeNonConus.rawValue || type == BICityLineSortType.BICitiesLineSortTypeIntl.rawValue || type == BICityLineSortType.BICitiesLineSortTypeHawaii.rawValue))) {
                self.cityNametxt.isEnabled = false
                self.cityNametxt.alpha = 1.0
                if (self.tapGesture == nil) {
                    self.tapGesture = UITapGestureRecognizer(target: self, action: #selector(didRecognizeTapGesture))
                    self.cityNametxt.superview?.addGestureRecognizer(tapGesture!)
                }
                if (category == BILineSortCategory.BICitiesLineSortCategory.rawValue && (type == BICityLineSortType.BICitiesLineSortTypeEastCoast.rawValue || type == BICityLineSortType.BICitiesLineSortTypeWestCoast.rawValue || type == BICityLineSortType.BICitiesLineSortTypeNonConus.rawValue || type == BICityLineSortType.BICitiesLineSortTypeIntl.rawValue || type == BICityLineSortType.BICitiesLineSortTypeAll.rawValue || type == BICityLineSortType.BICitiesLineSortTypeHawaii.rawValue)) {
                    self.cityNametxt.placeholder = "Cities"
                    self.cityNametxt.isHidden = false
//                    self.cityNametxt.isEnabled = true
                    var filterVars = self.lineSort?.variables?.mutableCopy() as? [String: Any] ?? [:]
                    // If the lineSort was just added calculate the sort
                    if filterVars["SET"] == nil {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
                            if self.lineSort!.sortHighlightsTrips() {
                                self.lineSort!.highlightTrips()
                            }
                            let set = NSSet(array: (self.lineSort?.selectedRegionalCities())!)
                            filterVars["SET"] = set
                            self.lineSort?.variables = NSDictionary(dictionary: filterVars)
                            self.lineSort?.keyPath = self.lineSort?.bidPeriod?.lineSortKeyForCityLineSort(cityLineSort: self.lineSort!, city: "")
                            if (self.lineSort?.sortHighlightsTrips())! {
                                self.lineSort?.highlightTrips()
                            }
                        }
                    }
                }
            }
            else {
                if let cityTextFeild = self.cityNametxt {
                    cityTextFeild.isEnabled = true
                    cityTextFeild.alpha = 1.0
                }
            }
        }
    }
    
    @objc func didRecognizeTapGesture(gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: gesture.view)
        if gesture.state == .ended {
            if self.cityNametxt.frame.contains(point) {
                self.showCityOptions()
            }
        }
    }
    
    func showCityOptions() {
        let storyboard = UIStoryboard(name: "Filter", bundle: nil)
        let menuController = storyboard.instantiateViewController(withIdentifier: "CBMenuTableVC") as! CBMenuTableVC
        self.menuItems = self.cityMenuItems() as NSArray
        self.menuItems = self.menuItems.filter { $0 as! String != ""} as NSArray
        guard menuItems.count > 0 else {
            print("No cities available to display.")
            return
        }
        menuController.menuItems = menuItems! 
        menuController.width = 140
        menuController.lineSort = lineSort
        if self.lineSort?.category?.intValue == BILineSortCategory.BICitiesLineSortCategory.rawValue {
            menuController.selectedItems = NSMutableSet(array: (lineSort?.selectedRegionalCities())!)
        }
        self.citiesMenuController = menuController;
        menuController.delegate = self
        menuController.showPopover(sourceView: self, sourceRect: self.cityNametxt.frame)
    }
    
    func cityMenuItems() -> NSArray {
        var menuItems = NSArray()
        let type = self.lineSort?.type?.intValue
        let category = self.lineSort?.category?.intValue
        if category == BILineSortCategory.BICitiesLineSortCategory.rawValue {
            if type == BICityLineSortType.BICitiesLineSortTypeEastCoast.rawValue {
                menuItems = UserDefaults.standard.array(forKey: kCBEastCoastCitiesList)! as NSArray
            }
            else if type == BICityLineSortType.BICitiesLineSortTypeWestCoast.rawValue {
                menuItems = UserDefaults.standard.array(forKey: kCBWestCoastCitiesList)! as NSArray
            }
            else if type == BICityLineSortType.BICitiesLineSortTypeNonConus.rawValue {
                menuItems = UserDefaults.standard.array(forKey: kCBNonConusCitiesList)! as NSArray
            }
            else if type == BICityLineSortType.BICitiesLineSortTypeIntl.rawValue {
                menuItems = UserDefaults.standard.array(forKey: kCBInternationalCitiesList)! as NSArray
            }
            else if type == BICityLineSortType.BICitiesLineSortTypeAll.rawValue {
                menuItems = UserDefaults.standard.array(forKey: kCBAllCitiesList)! as NSArray
            }
            else if type == BICityLineSortType.BICitiesLineSortTypeHawaii.rawValue {
                menuItems = UserDefaults.standard.array(forKey: kCBHawaiiCitiesList)! as NSArray
            }
            let descriptor: NSSortDescriptor = NSSortDescriptor(key: "description", ascending: true)
            menuItems = menuItems.sortedArray(using: [descriptor]) as NSArray
        }
        else {
            var deadheadCitiesSet = NSMutableSet()
            if lineSort?.bidPeriod == nil {
                lineSort?.bidPeriod = self.bidPeriod
            }
            if type == BIDeadheadLineSortType.BIDeadheadAtStartSortType.rawValue {
                let deadheadCitiesSet1 = lineSort?.bidPeriod?.deadheadAtStartCities?.value(forKey: "city") as! NSSet
                deadheadCitiesSet = deadheadCitiesSet1.mutableCopy() as! NSMutableSet
            }
            if type == BIDeadheadLineSortType.BIDeadheadAtEndSortType.rawValue {
                let deadheadCitiesSet1 = lineSort?.bidPeriod?.deadheadAtEndCities?.value(forKey: "city") as! NSSet
                deadheadCitiesSet = deadheadCitiesSet1.mutableCopy() as! NSMutableSet
            }
            else {
                let deadheadCitiesSet1 = lineSort?.bidPeriod?.deadheadAtStartCities?.value(forKey: "city") as! NSSet
                deadheadCitiesSet = deadheadCitiesSet1.mutableCopy() as! NSMutableSet
                deadheadCitiesSet.union(lineSort?.bidPeriod?.deadheadAtEndCities?.value(forKey: "city") as! Set<AnyHashable>)
            }
            let sortDescriptor = [NSSortDescriptor(key: "description", ascending: true)]
            let deadheadCities = deadheadCitiesSet.sortedArray(using: sortDescriptor)
            menuItems = deadheadCities as NSArray
        }
        return menuItems
    }
    
    func setLineSort(lineSort: BILineSort) {
        self.lineSort = lineSort
        self.nameLabel.text = lineSort.name
        self.LHsegment.selectedSegmentIndex = lineSort.ascending!.boolValue ? 0 : 1
        self.LHsegment.isHidden = !lineSort.isMutable!.boolValue
    }

    @IBAction func btnCloseAction(_ sender: Any) {
//        self.cityTextFieldDelegate.delegate?.shouldEndEditing(true)
        CBGlobalMethods.shared.selectedBidPeriod!.loadedPresetIdentifier = nil
        CBGlobalMethods.shared.selectedBidPeriod?.currentDateTime = Date()
        CBGlobalMethods.shared.selectedBidPeriod?.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)
        if lineSort?.name == nil || lineSort?.category == nil {
            return
        }
        if (self.lineSort?.sortHighlightsTrips())! {
            self.lineSort?.deHighlightTrips()
        }
        if self.tapGesture != nil {
            if let cityTextfield = self.cityNametxt {
                cityTextfield.superview?.removeGestureRecognizer(self.tapGesture)
            }
            self.tapGesture = nil
        }
        let keyMapToDelete = self.lineSort!.lineSortKeyMap
        if (keyMapToDelete) != nil {
            CBGlobalMethods.shared.selectedBidPeriod!.managedObjectContext!.delete(keyMapToDelete!)
        }
        context!.delete(lineSort!)
        if let cityTextfield = self.cityNametxt {
            cityTextfield.text = nil
        }
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
    
    @IBAction func LHsegmentAction(_ sender: Any) {
        CBGlobalMethods.shared.selectedBidPeriod!.loadedPresetIdentifier = nil
        CBGlobalMethods.shared.selectedBidPeriod?.currentDateTime = Date()
        CBGlobalMethods.shared.selectedBidPeriod?.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)
        if let cityNameTextField = self.cityNametxt {
            cityNameTextField.resignFirstResponder()
        }
        self.lineSort?.ascending = NSNumber(booleanLiteral: !(self.lineSort?.ascending!.boolValue)!)
        try? context?.save()
        
        NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
    }
}

extension CBLineSortCell: CBCityTextFieldDelegateDelegate {
    func cityTextFieldDelegateSetCityOnly(_ cityTextFieldDelegate: CBCityTextFieldDelegate?, textFieldDidEnterValidCity city: String?) {
        let keyMapToDelete = self.lineSort?.lineSortKeyMap
        if keyMapToDelete != nil {
            context!.delete(keyMapToDelete!)
        }
        if (self.lineSort?.sortHighlightsTrips())! {
            self.lineSort?.highlightTrips()
        }
        self.lineSort?.city = city
        try? context!.save()
    }
    
    func shouldEndEditing(_ shouldEndEditing: Bool) {
        if cityNametxt.isFirstResponder {
            self.cityTextFieldDelegate.shouldEndEditing = shouldEndEditing
            self.cityNametxt.endEditing(true)
        }
    }
    
    func cityTextFieldDelegate(_ cityTextFieldDelegate: CBCityTextFieldDelegate?, textFieldDidEnterValidCity city: String?) {
        let keyMapToDelete = self.lineSort!.lineSortKeyMap
        if (keyMapToDelete) != nil {
            CBGlobalMethods.shared.selectedBidPeriod!.managedObjectContext!.delete(keyMapToDelete!)
        }
        
        if (self.lineSort?.sortHighlightsTrips())! {
            self.lineSort?.deHighlightTrips()
        }
        self.lineSort?.setCity = city
        if (self.lineSort?.sortHighlightsTrips())! {
            self.lineSort?.highlightTrips()
        }
        try? CBGlobalMethods.shared.selectedBidPeriod!.managedObjectContext!.save()
        self.lineSort?.didSave()
        
        CBGlobalMethods.shared.showActivityIndicator(bgColor: .purple)
        NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
        CBGlobalMethods.shared.hideActivityIndicator()
    }
}

protocol CBCityTextFieldDelegateDelegate: NSObjectProtocol {
    func cityTextFieldDelegate(_ cityTextFieldDelegate: CBCityTextFieldDelegate?, textFieldDidEnterValidCity city: String?)
    func shouldEndEditing(_ shouldEndEditing: Bool)
    func cityTextFieldDelegateSetCityOnly(_ cityTextFieldDelegate: CBCityTextFieldDelegate?, textFieldDidEnterValidCity city: String?)
}

class CBCityTextFieldDelegate: NSObject, UITextFieldDelegate {
    weak var textField = UITextField()
    weak var delegate: CBCityTextFieldDelegateDelegate?
    var shouldEndEditing = false
    var canDismissTheKeyBoard = false
    
    init(textField: UITextField?, delegate: CBCityTextFieldDelegateDelegate?) {
        super.init()
        self.textField = textField
        self.textField?.delegate = self
        self.delegate = delegate
        NotificationCenter.default.addObserver(self, selector: #selector(self.sortViewWillDisappear), name: NSNotification.Name("SortViewWillDisappear"), object: nil)
    }
    @objc func sortViewWillDisappear(){
        canDismissTheKeyBoard = true
    }
    func textFieldDidBeginEditing(_ textField: UITextField) {
        shouldEndEditing = false
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        let city = textField.text?.uppercased()
        textField.text = city
        
        var arrAllCities = NSArray()
        if let aList = UserDefaults.standard.object(forKey: kCBAllCitiesList) as? [Any] {
            arrAllCities = NSArray(array: aList)
        }
        if 3 != (textField.text?.count) || !arrAllCities.contains(city ?? "") {
            textField.text = ""
        }
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        var shouldReturn = true
        if let city = textField.text?.uppercased() {
            textField.text = city
            
            var arrAllCities = NSArray()
            if let aList = UserDefaults.standard.object(forKey: kCBAllCitiesList) as? [Any] {
                arrAllCities = NSArray(array: aList)
            }
            if city.count == 0 || (city.count == 3 && arrAllCities.contains(city)) {
                shouldReturn = true
                CBGlobalMethods.shared.hideActivityIndicator()
                delegate?.cityTextFieldDelegate(self, textFieldDidEnterValidCity: city)
            }
            else {
                delegate?.cityTextFieldDelegateSetCityOnly(self, textFieldDidEnterValidCity: city)
                shouldReturn = false
                textField.shakeTextField()
            }
            return canDismissTheKeyBoard ? true : shouldReturn
        }
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Allow only letters in the text field.
        var nonLettersCharacterSet: CharacterSet? = nil
        if nil == nonLettersCharacterSet {
            var lettersOnly = CharacterSet.uppercaseLetters
            lettersOnly.formUnion(CharacterSet.lowercaseLetters)
            nonLettersCharacterSet = lettersOnly.inverted
        }
        var shouldChangeCharacters = true
        var rangeOfNonLetterCharacters: NSRange? = nil
        if let aSet = nonLettersCharacterSet {
            rangeOfNonLetterCharacters = (string as NSString).rangeOfCharacter(from: aSet)
        }
        if NSNotFound != Int(rangeOfNonLetterCharacters?.location ?? 0) {
            shouldChangeCharacters = false
        }
        let city = textField.text?.uppercased()
        textField.text = city
        return shouldChangeCharacters
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let city = textField.text?.uppercased() {
            textField.text = city
            // Text field should return only if the text contains exactly 3 characters,
            // the number of characters in a city identifier.
            var shouldReturn = true
            var arrAllCities = NSArray()
            if let aList = UserDefaults.standard.object(forKey: kCBAllCitiesList) as? [Any] {
                arrAllCities = NSArray(array: aList)
            }
            if city.count == 0 || (city.count == 3 && arrAllCities.contains(city)) {
                shouldReturn = true
                CBGlobalMethods.shared.hideActivityIndicator()
                delegate?.cityTextFieldDelegate(self, textFieldDidEnterValidCity: city)
                textField.resignFirstResponder()
            } else {
                shouldReturn = false
                delegate?.cityTextFieldDelegateSetCityOnly(self, textFieldDidEnterValidCity: city)
                textField.shakeTextField()
            }
            return shouldReturn
        }
        return true
    }
}

extension CBLineSortCell: CBMenuTableViewControllerDelegate {
    
    func menuTableViewController(menuController: CBMenuTableVC, didSelectRowAtIndexPath indexPath: IndexPath) {
        if menuController == self.citiesMenuController {
            let type = lineSort?.type?.intValue
            if self.lineSort?.category?.intValue == BILineSortCategory.BIDeadheadsLineSortCategory.rawValue {
                // Notify delegate of valid city entry if the text is exactly 3 characters,
                // after changing characters to all uppercase.
                let selectedCity = self.citiesMenuController.menuItems[indexPath.row] as! String
                self.cityTextFieldDelegate(self.cityTextFieldDelegate, textFieldDidEnterValidCity: selectedCity)
                self.cityNametxt.text = selectedCity
                menuController.dismiss(animated: true)
            }
        }
    }
    
    func menuTableViewControllerCitySelection(menuController: CBMenuTableVC, selectedCities cities:NSMutableSet){
        if menuController == self.citiesMenuController {
            self.lineSort?.saveSelectedCities(cities.allObjects)
                CBGlobalMethods.shared.showActivityIndicator(bgColor: .purple)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
                    self.settingSort()
                    NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
                    CBGlobalMethods.shared.hideActivityIndicator()
                }
            
        }
    }
    
    func settingSort() {
        if (self.lineSort?.sortHighlightsTrips())! {
            self.lineSort?.deHighlightTrips()
        }
        let SET = NSSet(array: (self.lineSort?.selectedRegionalCities())!)
        var filterVars = [String : Any]()
        if let variables = self.lineSort?.variables {
            filterVars = (variables as? [String : Any])!
            filterVars["SET"] = SET
        }
        
        // Delete the old line sort key
        if let lineSortKeyMap = self.lineSort!.lineSortKeyMap {
            self.lineSort?.managedObjectContext?.delete(lineSortKeyMap)
        }
        
        self.lineSort?.variables = filterVars as NSDictionary
     //   lineSort?.ascending = NSNumber(booleanLiteral: true)
        self.lineSort?.keyPath = self.lineSort?.bidPeriod?.lineSortKeyForCityLineSort(cityLineSort: self.lineSort!, city: "")
        if (self.lineSort?.sortHighlightsTrips())! {
            self.lineSort?.highlightTrips()
        }
    }
    
    
}
