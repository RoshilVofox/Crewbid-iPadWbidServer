//
//  CBCityComparisonRuleCell.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 24/03/25.
//

import UIKit

class CBCityComparisonRuleCell: CBComparisonRuleCell, UITextFieldDelegate {
    
    @IBOutlet weak var deleteButton: UIButton!
    //    @IBOutlet weak var titleLabel: UILabel!
    //    @IBOutlet weak var valueButton: UIButton!
    @IBOutlet weak var cityTextField: UITextField!
    //    @IBOutlet weak var comparisonButton: UIButton!
    
    var bidPeriod: BIBidPeriod?
    //    var filterRule: BIFilterRule?
    //    var context = CBGlobalMethods.shared.selectedBidPeriod?.managedObjectContext
    var tapGesture: UITapGestureRecognizer?
    var shouldEndEditing = false
    var canDismissTheKeyBoard = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        NotificationCenter.default.addObserver(self, selector: #selector(self.filterViewWillDisappear), name: NSNotification.Name("FilterViewWillDisappear"), object: nil)
    }
    
    @objc func filterViewWillDisappear(){
        canDismissTheKeyBoard = true
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        cityTextField.placeholder = "City"
        
        // If it's a regional city filter
        let type: Int = filterRule!.type as! Int
        if ((filterRule?.category?.intValue == BIFilterRuleCategory.BIDeadheadsFilterRuleCategory.rawValue && type == BIDeadheadsFilterRuleType.BIDeadheadsAtStartType.rawValue || type == BIDeadheadsFilterRuleType.BIDeadheadsAtEndType.rawValue || type == BIDeadheadsFilterRuleType.BIDeadheadsAtEitherType.rawValue || (filterRule?.category?.intValue == BIFilterRuleCategory.BICitiesFilterRuleCategory.rawValue && BICitiesFilterRuleType.BICitiesFilterRuleTypeEastCoast.rawValue == type || BICitiesFilterRuleType.BICitiesFilterRuleTypeWestCoast.rawValue == type || BICitiesFilterRuleType.BICitiesFilterRuleTypeNonConus.rawValue == type || BICitiesFilterRuleType.BICitiesFilterRuleTypeIntl.rawValue == type || BICitiesFilterRuleType.BICitiesFilterRuleTypeAll.rawValue == type || BICitiesFilterRuleType.BICitiesFilterRuleTypeHawaii.rawValue == type))) {
            cityTextField.isEnabled = false
            cityTextField.alpha = 1.0
            if !(tapGesture != nil) {
                tapGesture = UITapGestureRecognizer(target: self, action:#selector(self.didRecognizeTapGesture(_:)))
                cityTextField.superview?.addGestureRecognizer(tapGesture!)
            }
            if (filterRule!.category?.intValue == BIFilterRuleCategory.BICitiesFilterRuleCategory.rawValue && (BICitiesFilterRuleType.BICitiesFilterRuleTypeEastCoast.rawValue == type || BICitiesFilterRuleType.BICitiesFilterRuleTypeWestCoast.rawValue == type || BICitiesFilterRuleType.BICitiesFilterRuleTypeNonConus.rawValue == type || BICitiesFilterRuleType.BICitiesFilterRuleTypeIntl.rawValue == type || BICitiesFilterRuleType.BICitiesFilterRuleTypeAll.rawValue == type || BICitiesFilterRuleType.BICitiesFilterRuleTypeHawaii.rawValue == type)) {
                cityTextField.placeholder = "Cities"
            }
        }
        else {
            cityTextField.isEnabled = true
            cityTextField.alpha = 1.0
        }
    }
    
    @IBAction override func showValueOptions(_ sender: Any) {
        self.cityTextField.resignFirstResponder()
        super.showValueOptions(sender)
    }
    
    
    @IBAction override func showComparisonOptions(_ sender: Any) {
        
        self.cityTextField.resignFirstResponder()
        super.showComparisonOptions(sender)
        
    }
    
    @IBAction func deleteCellAction(_ sender: Any) {
        if cityTextField.isFirstResponder {
            self.shouldEndEditing = true
            cityTextField.resignFirstResponder()
        }
        CBGlobalMethods.shared.selectedBidPeriod!.loadedPresetIdentifier = nil
        CBGlobalMethods.shared.selectedBidPeriod?.currentDateTime = Date()
        CBGlobalMethods.shared.selectedBidPeriod?.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)
        let type:NSInteger = (self.filterRule?.type?.intValue)!
        if self.filterRule?.category?.intValue == BIFilterRuleCategory.BICitiesFilterRuleCategory.rawValue {
            if BICitiesFilterRuleType.BICitiesFilterRuleTypeEastCoast.rawValue == type
            {
                let arrEastCoast:NSArray = NSArray(array: UserDefaults .standard .object(forKey: kCBEastCoastCitiesList) as! NSArray)
                let eccs: [AnyHashable: Any] = [ kCBSelectedEastCoastCities : arrEastCoast ]
                UserDefaults.standard.set(arrEastCoast, forKey: kCBSelectedEastCoastCities)
                UserDefaults.standard.register(defaults: eccs as? [String : Any] ?? [String : Any]())
            }
            else if BICitiesFilterRuleType.BICitiesFilterRuleTypeWestCoast.rawValue == type
            {
                let arrWestCoast:NSArray = NSArray(array: UserDefaults .standard .object(forKey: kCBWestCoastCitiesList) as! NSArray)
                let wccs: [AnyHashable: Any] = [ kCBSelectedWestCoastCities : arrWestCoast ]
                UserDefaults.standard.set(arrWestCoast, forKey: kCBSelectedWestCoastCities)
                UserDefaults.standard.register(defaults: wccs as? [String : Any] ?? [String : Any]())
            }
            else if BICitiesFilterRuleType.BICitiesFilterRuleTypeNonConus.rawValue == type
            {
                let arrNonConUs:NSArray = NSArray(array: UserDefaults .standard .object(forKey: kCBNonConusCitiesList) as! NSArray)
                let nccs: [AnyHashable: Any] = [ kCBSelectedNonConusCities : arrNonConUs ]
                UserDefaults.standard.set(arrNonConUs, forKey: kCBSelectedNonConusCities)
                UserDefaults.standard.register(defaults: nccs as? [String : Any] ?? [String : Any]())
            }
            else if BICitiesFilterRuleType.BICitiesFilterRuleTypeIntl.rawValue == type
            {
                let arrIntl:NSArray = NSArray(array: UserDefaults .standard .object(forKey: kCBInternationalCitiesList) as! NSArray)
                let iccs: [AnyHashable: Any] = [ kCBSelectedInternationalCities : arrIntl ]
                UserDefaults.standard.set(arrIntl, forKey: kCBSelectedInternationalCities)
                UserDefaults.standard.register(defaults: iccs as? [String : Any] ?? [String : Any]())
            }
            else if BICitiesFilterRuleType.BICitiesFilterRuleTypeAll.rawValue == type
            {
                let arrAllCities:NSArray = NSArray(array: UserDefaults .standard .object(forKey: kCBAllCitiesList) as! NSArray)
                let accs: [AnyHashable: Any] = [ kCBSelectedAllCities : arrAllCities ]
                UserDefaults.standard.set(arrAllCities, forKey: kCBSelectedAllCities)
                UserDefaults.standard.register(defaults: accs as? [String : Any] ?? [String : Any]())
            }
            else if BICitiesFilterRuleType.BICitiesFilterRuleTypeHawaii.rawValue == type
            {
                let arrHawaii:NSArray = NSArray(array: UserDefaults .standard .object(forKey: kCBHawaiiCitiesList) as! NSArray)
                let hawaii: [AnyHashable: Any] = [ kCBSelectedHawaiiCities : arrHawaii ]
                UserDefaults.standard.set(arrHawaii, forKey: kCBSelectedHawaiiCities)
                UserDefaults.standard.register(defaults: hawaii as? [String : Any] ?? [String : Any]())
            }
        }
        
        
        if (filterRule?.ruleHighlightsTrips())! {
            filterRule?.deHighlightTrips()
        }
        if (self.tapGesture != nil)
        {
            self.cityTextField.superview?.removeGestureRecognizer(self.tapGesture!)
            self.tapGesture = nil
        }
        
        let variables = NSMutableDictionary(dictionary: (filterRule?.variables)! )
        let blankCity = ""
        variables.setValue(blankCity, forKey: BIFilterRuleCityVariablesKey)
        filterRule?.variables = variables
        CBGlobalMethods.shared.selectedBidPeriod!.managedObjectContext!.delete(filterRule!)
        try?  CBGlobalMethods.shared.selectedBidPeriod!.managedObjectContext!.save()
        // filterRule?.managedObjectContext?.delete(filterRule!)
        cityTextField.text = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){
            NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
        }
    }
    
    func showCityOptions () {
        let storyboard : UIStoryboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let refreshViewController = storyboard.instantiateViewController(withIdentifier: "RefreshController") as! RefreshController
        refreshViewController.popOverType = PopoverViewType.cityPopUp
        refreshViewController.bidPeriod = CBGlobalMethods.shared.selectedBidPeriod!
        refreshViewController.selectedValue = cityTextField.text ?? ""
        //Edited by Kripa to resolve the crash issue on 11 Dec
        var arrayCities = cityMenuItems()
        arrayCities.remove("")
        guard arrayCities.count > 0 else  {
            print("No cities available to display.")
            return
        }
        refreshViewController.menuItems = arrayCities
        refreshViewController.arrCellParameters = arrayCities
        refreshViewController.filterRule = self.filterRule
        refreshViewController.modalPresentationStyle = .popover
        refreshViewController.showPopover(sourceView: cityTextField)
    }
    
    @objc func didRecognizeTapGesture(_ gesture: UITapGestureRecognizer?) {
        let point: CGPoint? = gesture?.location(in: gesture?.view)
        if gesture?.state == .ended {
            if cityTextField.frame.contains(point!) {
                showCityOptions()
            }
        }
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        
        var shouldReturn = true
        if let city = textField.text?.uppercased() {
            
            textField.text = city
            
            if (filterRule?.ruleHighlightsTrips())! {
                filterRule?.deHighlightTrips()
            }
            // Set city in filter rule variables.
            //NSDictionary *variables = self.filterRule.variables;
            //self.filterRule.variables = @{BIFilterRuleCityVariablesKey: city, BIFilterRuleValueVariablesKey: variables[BIFilterRuleValueVariablesKey]};
            let variables = (filterRule?.variables)?.mutableCopy() as? NSMutableDictionary
            variables?.setValue(city, forKey: BIFilterRuleCityVariablesKey)
            filterRule?.variables = variables
            if (filterRule?.ruleHighlightsTrips())! {
                filterRule?.highlightTrips()
            }
            
            var arrAllCities = NSArray()
            if let aList = UserDefaults.standard.object(forKey: kCBAllCitiesList) as? [Any] {
                arrAllCities = NSArray(array: aList)
            }
            if city.count == 0 || (city.count == 3 && arrAllCities.contains(city)) {
                shouldReturn = true
                NotificationCenter.default.post(name: Notification.Name("refreshLines"), object: self)
            } else {
                shouldReturn = false
                textField.shakeTextField()
            }
            return canDismissTheKeyBoard ? true : shouldReturn
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if (filterRule?.ruleHighlightsTrips())! {
            filterRule?.deHighlightTrips()
        }
        // Set city in filter rule variables.
        let city = textField.text?.uppercased()
        textField.text = city
        //NSDictionary *variables = self.filterRule.variables;
        //self.filterRule.variables = @{BIFilterRuleCityVariablesKey: city, BIFilterRuleValueVariablesKey: variables[BIFilterRuleValueVariablesKey]};
        let variables = (filterRule?.variables)?.mutableCopy() as? NSMutableDictionary
        variables?.setValue(city, forKey: BIFilterRuleCityVariablesKey)
        filterRule?.variables = variables
        if (filterRule?.ruleHighlightsTrips())! {
            filterRule?.highlightTrips()
        }
        
        var arrAllCities = NSArray()
        if let aList = UserDefaults.standard.object(forKey: kCBAllCitiesList) as? [Any] {
            arrAllCities = NSArray(array: aList)
        }
        if 3 != (textField.text?.count ?? 0) || !arrAllCities.contains(city ?? "") {
            textField.text = ""
        }
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
        return shouldChangeCharacters
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let city = textField.text?.uppercased() {
            
            textField.text = city
            
            if (filterRule?.ruleHighlightsTrips())! {
                filterRule?.deHighlightTrips()
            }
            // Set city in filter rule variables.
            //NSDictionary *variables = self.filterRule.variables;
            //self.filterRule.variables = @{BIFilterRuleCityVariablesKey: city, BIFilterRuleValueVariablesKey: variables[BIFilterRuleValueVariablesKey]};
            let variables = (filterRule?.variables)?.mutableCopy() as? NSMutableDictionary
            variables?.setValue(city, forKey: BIFilterRuleCityVariablesKey)
            filterRule?.variables = variables
            if (filterRule?.ruleHighlightsTrips())! {
                filterRule?.highlightTrips()
            }
            
            var shouldReturn = true
            var arrAllCities = NSArray()
            if let aList = UserDefaults.standard.object(forKey: kCBAllCitiesList) as? [Any] {
                arrAllCities = NSArray(array: aList)
            }
            if city.count == 0 || (city.count == 3 && arrAllCities.contains(city)) {
                shouldReturn = true
                NotificationCenter.default.post(name: Notification.Name("refreshLines"), object: self)
                textField.resignFirstResponder()
            } else {
                shouldReturn = false
                textField.shakeTextField()
            }
            return shouldReturn
        }
        return true
    }
    
    func cityMenuItems() -> NSMutableArray {
        var menuItems = NSMutableArray()
        if filterRule?.category?.intValue == BIFilterRuleCategory.BICitiesFilterRuleCategory.rawValue {
            if BICitiesFilterRuleType.BICitiesFilterRuleTypeEastCoast.rawValue == filterRule?.type?.intValue {
                if let aList = UserDefaults.standard.object(forKey: kCBEastCoastCitiesList) as? [Any] {
                    menuItems = NSMutableArray(array: aList)
                }
            } else if BICitiesFilterRuleType.BICitiesFilterRuleTypeWestCoast.rawValue == filterRule?.type?.intValue {
                if let aList = UserDefaults.standard.object(forKey: kCBWestCoastCitiesList) as? [Any] {
                    menuItems = NSMutableArray(array: aList)
                }
            } else if BICitiesFilterRuleType.BICitiesFilterRuleTypeNonConus.rawValue == filterRule?.type?.intValue {
                if let aList = UserDefaults.standard.object(forKey: kCBNonConusCitiesList) as? [Any] {
                    menuItems = NSMutableArray(array: aList)
                }
            } else if BICitiesFilterRuleType.BICitiesFilterRuleTypeIntl.rawValue == filterRule?.type?.intValue {
                if let aList = UserDefaults.standard.object(forKey: kCBInternationalCitiesList) as? [Any] {
                    menuItems = NSMutableArray(array: aList)
                }
            } else if BICitiesFilterRuleType.BICitiesFilterRuleTypeAll.rawValue == filterRule?.type?.intValue {
                if let aList = UserDefaults.standard.object(forKey: kCBAllCitiesList) as? [Any] {
                    menuItems = NSMutableArray(array: aList)
                }
            }
            else if BICitiesFilterRuleType.BICitiesFilterRuleTypeHawaii.rawValue == filterRule?.type?.intValue {
                if let hawaiiList = UserDefaults.standard.object(forKey: kCBHawaiiCitiesList) as? [Any] {
                    menuItems = NSMutableArray(array: hawaiiList)
                }
            }
            let itemArray:NSArray = (menuItems as NSArray).sortedArray(using: [NSSortDescriptor(key: "description", ascending: true)]) as NSArray
            let value = itemArray.sortedArray(using: [NSSortDescriptor(key: "description", ascending: true)])
            menuItems = NSMutableArray(array: value)
            // menuItems = (menuItems as NSArray?)?.sortedArray(using: [NSSortDescriptor(key: "description", ascending: true)]) as! NSMutableArray
        } else {
            var deadheadCitiesSet = NSMutableSet()
            if filterRule?.type?.intValue == BIDeadheadsFilterRuleType.BIDeadheadsAtStartType.rawValue {
                if let aKey = bidPeriod?.deadheadAtStartCities?.value(forKey: "city")  {
                    
                    let array = NSArray(array: [aKey], copyItems: true)
                    let setValue:NSSet = array.object(at: 0) as! NSSet
                    deadheadCitiesSet = setValue.mutableCopy() as! NSMutableSet
                }
            } else if filterRule?.type?.intValue == BIDeadheadsFilterRuleType.BIDeadheadsAtEndType.rawValue {
                if let aKey = bidPeriod?.deadheadAtEndCities?.value(forKey: "city") {
                    
                    let array = NSArray(array: [aKey], copyItems: true)
                    let setValue:NSSet = array.object(at: 0) as! NSSet
                    deadheadCitiesSet = setValue.mutableCopy() as! NSMutableSet
                    
                }
            } else {
                if let aCopy = bidPeriod?.deadheadAtStartCities?.value(forKey: "city")  {
                    
                    let array = NSArray(array: [aCopy], copyItems: true)
                    let setValue:NSSet = array.object(at: 0) as! NSSet
                    deadheadCitiesSet = setValue.mutableCopy() as! NSMutableSet
                    
                }
                deadheadCitiesSet.union(bidPeriod!.deadheadAtEndCities!.value(forKey: "city") as! Set<AnyHashable>)
            }
            let deadheadCities = deadheadCitiesSet.sortedArray(using: [NSSortDescriptor(key: "description", ascending: true)])
            menuItems = NSMutableArray(array: deadheadCities)
        }
        return menuItems
        
    }
}
