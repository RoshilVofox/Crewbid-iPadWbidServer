//
//  CBPresetsTVC.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 24/03/25.
//

import UIKit
import CoreData

class CBPresetsTVC: BaseViewController, CBPresetCellDelegate, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var btnBidListCount: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    var presetsArray: [Any] = []
    var bidPeriod: BIBidPeriod?
    var justChangedPreset: Bool = false
    var justAddedAPreset: Bool = false
    var isKeyboardVisisble: Bool = false
    let context = CBGlobalMethods.shared.selectedBidPeriod!.managedObjectContext!
    var arrCommuteTimeDetails: [CommuteTime]? = nil
    var calendarData = BICalendarData()
    var justLoadedFilterPreset = false
    var justLoadedSortPreset = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bidPeriod = CBGlobalMethods.shared.selectedBidPeriod!
        setupUI()
        self.view.clipsToBounds = true
        self.view.layer.cornerRadius = 5
        NotificationCenter.default.addObserver(self, selector: #selector(updateBidListCount), name: NSNotification.Name("updateBidListCount"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updatePresets(_:)), name: NSNotification.Name("refreshLines"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(deselectPresetsNotification), name: NSNotification.Name(CBLineValuesToDisplayDidChangeNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(setPrestsNotification), name: NSNotification.Name("presetSynched"), object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(deselectPresetsNotification), name: NSNotification.Name("refreshLines"), object: nil)
        NotificationCenter.default.removeObserver(kCBPresetSyncReload)
        CBGlobalMethods.shared.isSortAvailable = false
        tableView.allowsSelectionDuringEditing = true
        calendarData = calendarData.initWithBidPeriod(bidPeriod: bidPeriod!)!
    }
    
    func setupUI(){
        btnBidListCount.layer.cornerRadius = btnBidListCount.frame.height/2
        updateBidListCount()
        setPrests()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.removeObserver(kCBPresetSyncReload)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadViewSync), name: NSNotification.Name(kCBPresetSyncReload), object: nil)
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
    @objc func setPrestsNotification() {
        self.setPrests()
    }
    
    @IBAction func btnFilterAction(_ sender: Any) {
        let storyboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBFilterRulesTableVC") as! CBFilterRulesTableVC
        vc.bidPeriod = CBGlobalMethods.shared.selectedBidPeriod
        self.navigationController?.pushViewController(vc, animated: false)
    }
    
    @IBAction func btnSortAction(_ sender: Any) {
        let storyboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBLineSortsTVC") as! CBLineSortsTVC
        //        vc.bidPeriod = self.bidPeriod
        vc.bidPeriod = CBGlobalMethods.shared.selectedBidPeriod
        self.navigationController?.pushViewController(vc, animated: false)
    }
    
    @IBAction func btnBidsAction(_ sender: Any) {
//        let storyboard = UIStoryboard(name: "BidDocument", bundle: nil)
//        let vc = storyboard.instantiateViewController(withIdentifier: "CBBidListVC") as! CBBidListVC
//        self.navigationController?.pushViewController(vc, animated: false)
//        UIView.transition(from: self.view, to: vc.view, duration: 0.65, options: [.transitionFlipFromLeft])
        guard let nav = self.navigationController else { return }
        if let topVC = nav.topViewController, topVC is CBBidListVC {
            return
        }
        if let existingVC = nav.viewControllers.first(where: { $0 is CBBidListVC }) {
            nav.popToViewController(existingVC, animated: false)
            UIView.transition(with: nav.view,duration: 0.65,options: [.transitionFlipFromLeft],animations: nil)
            return
        }
        let vc = UIStoryboard(name: "BidDocument", bundle: nil).instantiateViewController(withIdentifier: "CBBidListVC") as! CBBidListVC
        nav.pushViewController(vc, animated: false)
        UIView.transition(with: nav.view,duration: 0.65,options: [.transitionFlipFromLeft],animations: nil)
    }
    
    
    @IBAction func btnBidListCountAction(_ sender: Any) {
    }
    
    
    @objc func updatePresets(_ notification: Notification) {
        if let sender = notification.object as? UIViewController, sender === self {
                // 👇 Ignore notification posted by self
                return
            }
        tableView.reloadData()
    }
    
    func setPrests() {
        let fileManager = FileManager.default
        presetsArray = []
//        let app = UIApplication.shared.delegate as! AppDelegate
        if app.ObjUserAccount?.position == 3 {
            if self.bidPeriod!.isFABid() == true {
                let presetFileName = app.ObjUserAccount?.employeeNumber
                let arr = openPresetsFromFileWithFileName(presetFileName: presetFileName!)
                self.setPresetswithArray(array: arr)
                if self.presetsArray.isEmpty {
                    if fileManager.fileExists(atPath: self.presetsDocumentFilePathWithFileName(presetFileName: "CrewBidFAPresets.plist")) {
                        let arr = self.openPresetsFromFileWithFileName(presetFileName: "CrewBidFAPresets.plist")
                        self.setPresetswithArray(array: arr)
                        UserDefaults.standard.set(false, forKey: "isConversion")
                        for case let preset as CBPreset in presetsArray {
                            if preset.appVersion?.isEmpty == true {
                                for pRule in preset.filterRules {
                                    if (pRule.category!.intValue > 1 && pRule.category?.intValue != BIFilterRuleCategory.BIOvernightLengthFilterRuleCategory.rawValue) {
                                        pRule.category = pRule.category!.intValue + 1 as NSNumber
                                    }
                                }
                                preset.appVersion = self.bidPeriod!.appVersion
                            }
                        }
                    }
                    if presetsArray.count > 0 {
                        self.savePresets()
                    }
                }
            }
        }
            else {
                let presetFileName = app.ObjUserAccount?.employeeNumber
                let arr = openPresetsFromFileWithFileName(presetFileName: presetFileName!)
                self.setPresetswithArray(array: arr)
                if presetsArray.isEmpty {
                    if fileManager.fileExists(atPath: self.presetsDocumentFilePathWithFileName(presetFileName: "CrewBidRound2Presets.plist")) {
                        let arr = self.openPresetsFromFileWithFileName(presetFileName: "CrewBidRound2Presets.plist")
                        self.setPresetswithArray(array: arr)
                        UserDefaults.standard.set(false, forKey: "isConversion")
                        for case let preset as CBPreset in presetsArray {
                            preset.name = "(Round2) \(String(describing: preset.name))"
                            
                            if preset.appVersion?.isEmpty == true {
                                for pRule in preset.filterRules {
                                    if (pRule.category!.intValue > 1 && pRule.category?.intValue != BIFilterRuleCategory.BIOvernightLengthFilterRuleCategory.rawValue) {
                                        pRule.category = pRule.category!.intValue + 1 as NSNumber
                                    }
                                }
                                preset.appVersion = self.bidPeriod!.appVersion
                            }
                        }
                    }
                    if presetsArray.count > 0 {
                        self.savePresets()
                    }
                    
                    if fileManager.fileExists(atPath: presetsDocumentFilePathWithFileName(presetFileName: "CrewBidPilotPresets.plist")) {
                        let arr = self.openPresetsFromFileWithFileName(presetFileName: "CrewBidPilotPresets.plist")
                        self.setPresetswithArray(array: arr)
                        UserDefaults.standard.set(false, forKey: "isConversion")
                        for case let preset as CBPreset in presetsArray {
                            if preset.appVersion?.isEmpty == true {
                                for pRule in preset.filterRules {
                                    if (pRule.category!.intValue > 1 && pRule.category?.intValue != BIFilterRuleCategory.BIOvernightLengthFilterRuleCategory.rawValue) {
                                        pRule.category = pRule.category!.intValue + 1 as NSNumber
                                    }
                                }
                                preset.appVersion = self.bidPeriod!.appVersion
                            }
                        }
                    }
                    if presetsArray.count > 0 {
                        self.savePresets()
                    }
                }
            }
            
            if fileManager.fileExists(atPath: presetsDocumentFilePathWithBidPeriod(bidPeriod: self.bidPeriod!)) {
                let arr = self.openPresetsFromFileWithBidPeriod(bidPeriod: bidPeriod!)
                self.setPresetswithArray(array: arr)
                UserDefaults.standard.set(false, forKey: "isConversion")
                for case let preset as CBPreset in presetsArray {
                    if preset.appVersion?.isEmpty == true {
                        for pRule in preset.filterRules {
                            if (pRule.category!.intValue > 1 && pRule.category?.intValue != BIFilterRuleCategory.BIOvernightLengthFilterRuleCategory.rawValue) {
                                
                            }
                        }
                        preset.appVersion = self.bidPeriod!.appVersion
                    }
                }
            }
            else {
                self.presetsArray = []
                self.savePresets()
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    
    func openPresetsFromFileWithFileName(presetFileName: String) -> [Any] {
        let result = FileManager.default.contents(atPath: self.presetsDocumentFilePathWithFileName(presetFileName: presetFileName))
        var presets: [Any] = []
        
        do {
            if let result = result {
                do {
                    // Try secure unarchiving first
                    if let unarchived = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSArray.self, NSDictionary.self, NSString.self, NSNumber.self], from: result) as? [Any] {
                        presets = unarchived
                        print("Presets:")
                    }
                } catch {
                    // Fallback for legacy archives (Objective-C style)
                    if let legacyPresets = try? NSKeyedUnarchiver(forReadingFrom: result).decodeTopLevelObject() as? [Any] {
                        presets = legacyPresets
                        print("Legacy presets decoded")
                    } else if let legacyPresets = NSKeyedUnarchiver.unarchiveObject(with: result) as? [Any] {
                        presets = legacyPresets
                        print("Legacy unarchive success")
                    } else {
                        print("Failed to unarchive presets")
                    }
                }
            }

        } catch {
            print("Unarchive error: \(error.localizedDescription)")
            
            // Compare iOS version >= 16.0.0
            if let systemVersion = Double(UIDevice.current.systemVersion), systemVersion >= 16.0 {
                DispatchQueue.main.async {
                    let defaults = UserDefaults.standard
                    if defaults.string(forKey: "iOS16PresetSavedToServer") != "YES" {
                        self.saveiOS16PresetsToServerwithData(data: result!)
                    }
                }
            }
        }
        
        return presets
    }
    
    func presetsDocumentFilePathWithFileName(presetFileName: String) -> String {
        let presetsDirectoryURL = self.presetsDocumentDirectory()
        let presetsDocument = presetsDirectoryURL!.appendingPathComponent(presetFileName).path
        return presetsDocument
    }
    
    func presetsDocumentDirectory() -> URL? {
        let presetsURL = BIBidInfo.shared.documentsDirectory().appendingPathComponent("Presets")
        
        do {
            try FileManager.default.createDirectory(at: presetsURL,
                                                    withIntermediateDirectories: true,
                                                    attributes: nil)
            return presetsURL
        } catch {
            // You could log or handle the error here if needed
            return nil
        }
    }
    
    func saveiOS16PresetsToServerwithData(data: Data) {
//        let app = UIApplication.shared.delegate as! AppDelegate
        var dicInfo: [String: Any] = [:]
        dicInfo["EmployeeNumber"] = app.ObjUserAccount?.employeeNumber
        dicInfo["PresetFileName"] = "\(String(describing: app.ObjUserAccount?.employeeNumber)).plist"
        
        // Convert Data -> [NSNumber] (like Objective-C loop)
        let bytes = [UInt8](data)
        let resArr = bytes.map { NSNumber(value: $0) }
        dicInfo["PresetContent"] = resArr
        
        guard let url = URL(string: "http://www.wbidmax.com:8000/WBidDataDwonloadAuthService.svc/SaveCrashedPresetToServer") else {
            return
        }
        
        var urlRequest = URLRequest(url: url)
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dicInfo, options: [])
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                urlRequest.httpBody = jsonString.data(using: .utf8)
            }
        } catch {
            print("JSON serialization error: \(error)")
            return
        }
        
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            guard let data = data, error == nil else { return }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                do {
                    if let res = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves) as? [String: Any] {
                        UserDefaults.standard.setValue("YES", forKey: "iOS16PresetSavedToServer")
                        print(res)
                    }
                } catch {
                    print("Response JSON parse error: \(error)")
                }
            }
        }
        task.resume()
    }
    
    func setPresetswithArray(array: [Any]) {
        presetsArray = []
        for preset in array {
            if let dict = preset as? [String: Any] {
                var linesSorts: [CBPresetLineSort] = []
                var filterRules: [CBPresetFilterRule] = []
                if let dictFilterRule = dict["filterRules"] as? [[String: Any]] {
                    for filter in dictFilterRule {
                        let filt = CBPresetFilterRule()
                        filt.category = filter["category"] as? NSNumber
                        filt.type = filter["type"] as? NSNumber
                        filt.name = filter["name"] as? String
                        filt.keyPath = filter["keyPath"] as? String
                        filt.abbreviation = filter["abbreviation"] as? String
                        filt.comparison = filter["comparison"] as? NSNumber
                        filt.variables = filter["variables"] as? [String: Any]
                        filterRules.append(filt)
                    }
                }
                if let dictSortRules = dict["lineSorts"] as? [[String: Any]] {
                    for sort in dictSortRules {
                        let sortObj = CBPresetLineSort()
                        sortObj.category = sort["category"] as? NSNumber
                        sortObj.type = sort["type"] as? NSNumber
                        sortObj.name = sort["name"] as? String
                        sortObj.keyPath = sort["keyPath"] as? String
                        sortObj.abbreviation = sort["abbreviation"] as? String
                        sortObj.ascending = sort["ascending"] as? NSNumber
                        sortObj.isMutable = sort["isMutable"] as? NSNumber
                        sortObj.city = sort["city"] as? String
                        sortObj.expression = sort["expression"] as? String
                        sortObj.order = sort["order"] as? NSNumber
                        sortObj.lineSortKeyMap = sort["lineSortKeyMap"] as? [String: Any]
                        sortObj.variables = sort["variables"] as? [String: Any]
                        sortObj.arrayVariables = sort["arrayVariables"] as? NSMutableArray
                        linesSorts.append(sortObj)
                    }
                }
                let pr = CBPreset()
                pr.name = dict["name"] as? String
                pr.month = dict["month"] as? NSNumber
                pr.year = dict["year"] as? NSNumber
                pr.position = dict["position"] as? NSNumber
                pr.appVersion = dict["appVersion"] as? String
                pr.lineValues = dict["lineValues"] as? [Any] ?? []
                pr.selected = dict["selected"] as? NSNumber
                pr.presetIdentifier = dict["presetIdentifier"] as? String
                pr.overnight = dict["overnight"] as? NSMutableArray
                pr.commuteTimeDetails = dict["commuteTimeDetails"] as? NSMutableArray
                pr.commutabilityFilterDetails = dict["commutabilityFilterDetails"] as? NSMutableDictionary
                pr.commutabilitySortDetails = dict["commutabilitySortDetails"] as? NSMutableDictionary
                pr.filterRules = filterRules
                pr.lineSorts = linesSorts
                self.presetsArray.append(pr)
            }
            else if let presetObj = preset as? CBPreset {
                presetsArray.append(presetObj)
            }
        }
    }
    
    func presetsDocumentFilePathWithBidPeriod(bidPeriod: BIBidPeriod) -> String {
        let prestesDirectoryURL = self.presetsDocumentDirectory()
        let isConversion = UserDefaults.standard.bool(forKey: "isConversion")
        if isConversion {
            let presetsFileName = presetsFilenameWithBidPeriod(bidPeriod: bidPeriod)
            let presetsDocument = prestesDirectoryURL!.appendingPathComponent(presetsFileName).path
            return presetsDocument
        }
        else {
//            let app = UIApplication.shared.delegate as! AppDelegate
            let presetsFileName = (app.ObjUserAccount?.employeeNumber)!
            let presetsDocument = prestesDirectoryURL!.appendingPathComponent(presetsFileName).path
            return presetsDocument
        }
    }
    
    func presetsFilenameWithBidPeriod(bidPeriod: BIBidPeriod) -> String {
        var presetFileName: String = ""
        if bidPeriod.isFABid() {
            presetFileName = "CrewBidFAPresets.plist"
        }
        else if bidPeriod.isSecondRoundBid() {
            presetFileName = "CrewBidRound2Presets.plist"
        }
        else {
            presetFileName = "CrewBidPilotPresets.plist"
        }
        return presetFileName
    }
    
    func openPresetsFromFileWithBidPeriod(bidPeriod: BIBidPeriod) -> [Any] {
        let result = FileManager.default.contents(atPath: self.presetsDocumentFilePathWithBidPeriod(bidPeriod: bidPeriod))
        var presets: [Any] = []
        do {
            if let result = result {
                do {
                    // Try secure unarchiving first
                    if let unarchived = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSArray.self, NSDictionary.self, NSString.self, NSNumber.self], from: result) as? [Any] {
                        presets = unarchived
                        print("Presets:")
                    }
                } catch {
                    // Fallback for legacy archives (Objective-C style)
                    if let legacyPresets = try? NSKeyedUnarchiver(forReadingFrom: result).decodeTopLevelObject() as? [Any] {
                        presets = legacyPresets
                        print("Legacy presets decoded")
                    } else if let legacyPresets = NSKeyedUnarchiver.unarchiveObject(with: result) as? [Any] {
                        presets = legacyPresets
                        print("Legacy unarchive success")
                    } else {
                        print("Failed to unarchive presets")
                    }
                }
            }

        } catch {
            print("Unarchive error: \(error.localizedDescription)")
            
            // Compare iOS version >= 16.0.0
            if let systemVersion = Double(UIDevice.current.systemVersion), systemVersion >= 16.0 {
                DispatchQueue.main.async {
                    let defaults = UserDefaults.standard
                    if defaults.string(forKey: "iOS16PresetSavedToServer") != "YES" {
                        if result != nil {
                            self.saveiOS16PresetsToServerwithData(data: result!)
                        }
                    }
                    self.getCrashedPresetFromServerWithBidPeriod(bidPeriod: bidPeriod)
                }
            }
        }
        return presets
    }
    
    func getCrashedPresetFromServerWithBidPeriod(bidPeriod: BIBidPeriod) {
//        let app = UIApplication.shared.delegate as! AppDelegate
        
        var dicInfo: [String: Any] = [:]
        dicInfo["EmployeeNumber"] = app.ObjUserAccount?.employeeNumber
        dicInfo["PresetFileName"] = "\(String(describing: app.ObjUserAccount?.employeeNumber)).json"
        
        guard let url = URL(string: "http://www.wbidmax.com:8000/WBidDataDwonloadAuthService.svc/GetCrashedCBPresetFromServer") else { return }
        
        var urlRequest = URLRequest(url: url)
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dicInfo, options: [])
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                urlRequest.httpBody = jsonString.data(using: .utf8)
            }
        } catch {
            print("JSON error: \(error)")
            return
        }
        
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let dataTask = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            guard let data = data, error == nil else { return }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                do {
                    if let res = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves) as? [String: Any] {
                        print("Response: \(res)")
                        
                        if let presetContent = res["PresetContent"] as? [String] {
                            let bytes = presetContent.compactMap { UInt8($0) }
                            let tempp = Data(bytes)
                            
                            if let jsonArray = try JSONSerialization.jsonObject(with: tempp, options: .mutableLeaves) as? [Any], !jsonArray.isEmpty {
                                
                                if let plistData = try? NSKeyedArchiver.archivedData(withRootObject: jsonArray, requiringSecureCoding: false) {
                                    // Save with bidPeriod
                                    let path1 = self.presetsDocumentFilePathWithBidPeriod(bidPeriod: bidPeriod)
                                    try? plistData.write(to: URL(fileURLWithPath: path1))
                                    
                                    
                                    // Save with employeeNumber
                                    let presetsFilename = String(self.app.ObjUserAccount!.employeeNumber)
                                    let path2 = self.presetsDocumentFilePathWithFileName(presetFileName: presetsFilename)
                                    try? plistData.write(to: URL(fileURLWithPath: path2))
                                    
                                    
                                    DispatchQueue.main.async {
                                        UserDefaults.standard.set(false, forKey: kCBIsPresetModified)
                                        NotificationCenter.default.post(name: Notification.Name("presetSynched"), object: self)
                                        NotificationCenter.default.post(name: Notification.Name(kCBPresetSyncReload), object: self)
                                    }
                                }
                            }
                        } else {
                            self.sendMailForUnConvertedFile()
                        }
                    }
                } catch {
                    print("Parsing error: \(error)")
                }
            }
        }
        dataTask.resume()
    }
    
    func sendMailForUnConvertedFile() {
        //        MARK: needed to add code here
    }
    
    func savePresets() {
        var jsonArray: [Any] = []
        var plistData: Data? = nil
        if let systemVersion = Double(UIDevice.current.systemVersion), systemVersion >= 16.0 {
            for case let preset as CBPreset in self.presetsArray {
                var jsonDict: [String: Any] = [:]
                var lineSorts: NSMutableArray = []
                var filterRules: NSMutableArray = []
                for filter in preset.filterRules {
                    var filtDict: [String: Any] = [:]
                    filtDict["category"] = filter.category
                    filtDict["type"] = filter.type
                    filtDict["name"] = filter.name
                    filtDict["keyPath"] = filter.keyPath
                    filtDict["abbreviation"] = filter.abbreviation
                    filtDict["comparison"] = filter.comparison
                    var vrb: [String: Any] = filter.variables!
                    if let set = vrb["SET"] as? NSSet {
                        vrb["SET"] = set.allObjects
                    }
                    filtDict["variables"] = vrb
                    filterRules.add(filtDict)
                }
                
                for sort in preset.lineSorts {
                    var sortDict: [String: Any] = [:]
                    sortDict["category"] = sort.category
                    sortDict["type"] = sort.type
                    sortDict["keyPath"] = sort.keyPath
                    sortDict["abbreviation"] = sort.abbreviation
                    sortDict["ascending"] = sort.ascending
                    sortDict["isMutable"] = sort.isMutable
                    sortDict["city"] = sort.city
                    sortDict["expression"] = sort.expression
                    sortDict["order"] = sort.order
                    sortDict["lineSortKeyMap"] = sort.lineSortKeyMap
                    sortDict["variables"] = sort.variables
                    sortDict["name"] = sort.name
                    sortDict["arrayVariables"] = sort.arrayVariables
                    sortDict["isBidListSort"] = sort.isBidListSort
                    lineSorts.add(sortDict)
                }
                jsonDict["lineSorts"] = lineSorts
                jsonDict["filterRules"] = filterRules
                jsonDict["name"] = preset.name
                jsonDict["month"] = self.bidPeriod!.month!.intValue
                jsonDict["year"] = self.bidPeriod!.year!.intValue
                jsonDict["position"] = self.bidPeriod!.positionType
                jsonDict["appVersion"] = self.bidPeriod!.appVersion
                jsonDict["lineValues"] = preset.lineValues
                jsonDict["selected"] = preset.selected
                jsonDict["presetIdentifier"] = preset.presetIdentifier
                jsonDict["overnight"] = preset.overnight
                jsonDict["commutabilityFilterDetails"] = preset.commutabilityFilterDetails
                jsonDict["commutabilitySortDetails"] = preset.commutabilitySortDetails
                jsonArray.append(jsonDict)
            }
            do {
                plistData = try NSKeyedArchiver.archivedData(withRootObject: jsonArray,
                                                             requiringSecureCoding: false)
            } catch {
                print("Archiving error: \(error)")
            }
        } else {
            do {
                plistData = try NSKeyedArchiver.archivedData(withRootObject: self.presetsArray,
                                                             requiringSecureCoding: false)
            } catch {
                print("Archiving error: \(error)")
            }
        }
        if let plistData = plistData {
            let filePath = self.presetsDocumentFilePathWithBidPeriod(bidPeriod: self.bidPeriod!)
            let fileURL = URL(fileURLWithPath: filePath)
            
            do {
                try plistData.write(to: fileURL, options: .atomic)
                print("Presets saved at: \(fileURL.path)")
            } catch {
                print("Failed to save presets: \(error)")
            }
        }
    }
    
    func startPresetSecretConversionWithInt(num: Int) {
        let userArray = ["107175.plist", "127030.plist", "133622.plist", "140695.plist", "141249.plist", "146787.plist", "149865.plist", "82309.plist"]
        let next = num + 1
        let fileName = userArray[num]
        let arrayOfComponents = fileName.components(separatedBy: ".")
        let secretEmpNum = arrayOfComponents[0]
        
        var dictDetails: [String: Any] = [:]
        dictDetails["Employeeumber"] = secretEmpNum
        dictDetails["PresetFileName"] = fileName
        getSecretCrewbidPresetFileLOOP(with: dictDetails) { success in
            let jsonArray: NSMutableArray = []
            for case let preset as CBPreset in self.presetsArray {
                var jsonDict = [String: Any]()
                var lineSorts: NSMutableArray = []
                var filterRules: NSMutableArray = []
                for filter in preset.filterRules {
                    var filtDict: [String: Any] = [:]
                    filtDict["category"] = filter.category
                    filtDict["type"] = filter.type
                    filtDict["name"] = filter.name
                    filtDict["abbreviation"] = filter.abbreviation
                    filtDict["comparison"] = filter.comparison
                    var vrb: [String: Any] = filter.variables!
                    if let set = vrb["SET"] as? NSSet {
                        vrb["SET"] = set.allObjects
                    }
                    filtDict["variables"] = vrb
                    filterRules.add(filtDict)
                }
                
                for sort in preset.lineSorts {
                    var sortDict: [String: Any] = [:]
                    sortDict["category"] = sort.category
                    sortDict["type"] = sort.type
                    sortDict["name"] = sort.name
                    sortDict["keyPath"] = sort.keyPath
                    sortDict["abbreviation"] = sort.abbreviation
                    sortDict["ascending"] = sort.ascending
                    sortDict["isMutable"] = sort.isMutable
                    sortDict["city"] = sort.city
                    sortDict["expression"] = sort.expression
                    sortDict["order"] = sort.order
                    sortDict["lineSortKeyMap"] = sort.lineSortKeyMap
                    sortDict["variables"] = sort.variables
                    sortDict["arrayVariables"] = sort.arrayVariables
                    var vrb: [String: Any] = sort.variables!
                    if let set = vrb["SET"] as? NSSet {
                        vrb["SET"] = set.allObjects
                    }
                    sortDict["variables"] = vrb
                    lineSorts.add(sortDict)
                }
                jsonDict["lineSorts"] = lineSorts
                jsonDict["filterRules"] = filterRules
                jsonDict["name"] = preset.name
                jsonDict["month"] = self.bidPeriod!.month!.intValue
                jsonDict["year"] = self.bidPeriod!.year!.intValue
                jsonDict["position"] = self.bidPeriod!.positionType
                jsonDict["appVersion"] = self.bidPeriod!.appVersion
                jsonDict["lineValues"] = preset.lineValues
                jsonDict["selected"] = preset.selected
                jsonDict["presetIdentifier"] = preset.presetIdentifier
                jsonDict["overnight"] = preset.overnight
                jsonDict["commutabilityFilterDetails"] = preset.commutabilityFilterDetails
                jsonDict["commutabilitySortDetails"] = preset.commutabilitySortDetails
                jsonArray.add(jsonDict)
            }
            do {
                let jsonData2 = try JSONSerialization.data(withJSONObject: jsonArray, options: .prettyPrinted)
                if let jsonString = String(data: jsonData2, encoding: .utf8) {
                    self.saveSecretCrewbidPresetFileLOOP(with: dictDetails, data: jsonString) { status in
                        self.startPresetSecretConversionWithInt(num: next)
                    }
                }
            } catch {
                print("JSON serialization error: \(error)")
            }
            
        }
    }
    
    func getSecretCrewbidPresetFileLOOP(with dict: [String: Any], completion presetCompletionHandler: @escaping (Bool) -> Void) {
        guard let url = URL(string: "http://www.wbidmax.com:8000/WBidDataDwonloadAuthService.svc/GetCrashedCBPresetFromServer") else {
            presetCompletionHandler(false)
            return
        }
        
        var urlRequest = URLRequest(url: url)
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dict, options: [])
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                urlRequest.httpBody = jsonString.data(using: .utf8)
            }
        } catch {
            print("JSON serialization error: \(error)")
            presetCompletionHandler(false)
            return
        }
        
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let dataTask = URLSession.shared.dataTask(with: urlRequest) { [weak self] data, response, error in
            guard let self = self else { return }
            guard let data = data, error == nil else {
                presetCompletionHandler(false)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                do {
                    if let res = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves) as? [String: Any] {
                        print("Response: \(res)")
                        
                        if let databytess = res["PresetContent"] as? [String] {
                            let c = databytess.count
                            var bytes = [UInt8](repeating: 0, count: c)
                            
                            for (i, str) in databytess.enumerated() {
                                if let byte = Int(str) {
                                    bytes[i] = UInt8(byte)
                                }
                            }
                            
                            let tempp = Data(bytes: bytes, count: c)
                            
                            if let presetsNSArray = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSArray.self, from: tempp),
                               let presets = presetsNSArray as? [Any] {
                                self.presetsArray = []
                                
                                for preset in presets {
                                    if let cbPreset = preset as? CBPreset {
                                        self.presetsArray.append(cbPreset)
                                    }
                                }
                                
                                presetCompletionHandler(true)
                                return
                            }
                        }
                    }
                } catch {
                    print("JSON parse/unarchive error: \(error)")
                }
            }
            
            presetCompletionHandler(false)
        }
        dataTask.resume()
    }
    
    func saveSecretCrewbidPresetFileLOOP(with dict: [String: Any], data: String, completion presetCompletionHandler: @escaping (Bool) -> Void) {
        var dicInfo: [String: Any] = [:]
        
        if let employeeNumber = dict["Employeeumber"] as? String {
            dicInfo["EmployeeNumber"] = employeeNumber
            dicInfo["PresetFileName"] = "\(employeeNumber).json"
        }
        
        dicInfo["PresetContent"] = data
        
        guard let url = URL(string: "http://www.wbidmax.com:8000/WBidDataDwonloadAuthService.svc/SaveConvertedPresetToServer") else {
            presetCompletionHandler(false)
            return
        }
        
        var urlRequest = URLRequest(url: url)
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dicInfo, options: [])
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                urlRequest.httpBody = jsonString.data(using: .utf8)
            }
        } catch {
            print("JSON serialization error: \(error)")
            presetCompletionHandler(false)
            return
        }
        
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let dataTask = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            guard let data = data, error == nil else {
                presetCompletionHandler(false)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                do {
                    if let res = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves) as? [String: Any] {
                        print("\(dict["Employeeumber"] ?? "") Completed preset conversion")
                        print("Response: \(res)")
                        presetCompletionHandler(true)
                        return
                    }
                } catch {
                    print("Response parse error: \(error)")
                }
            }
            
            presetCompletionHandler(false)
        }
        dataTask.resume()
    }
    
    @objc func reloadViewSync() {
        self.viewDidLoad()
        tableView.reloadData()
    }
    
    //    MARK: CBPReset cell delegate
    
    func deleteButtonPressed(presetCell: CBPresetCell, indexpath: IndexPath) {
        AlertService.showAlertForTopVC(title: "Delete preset?", message: "Tap OK to confirm.", actions: [
            (
               title: "Cancel",
               style: .default,
               handler: nil
            ),
            (
            title: "OK",
            style: .default,
            handler: { _ in
                UserDefaults.standard.set(true, forKey: kCBIsPresetModified)
                if indexpath.row < self.presetsArray.count {
                    self.presetsArray.remove(at: indexpath.row)
                }
                else {
                    print("index out of bounds")
                }
                self.savePresets()
                self.tableView.reloadData()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.tableView.reloadData()
                }
            }
        )])
    }
    
    func nameTextFieldEndedEditing(presetCell: CBPresetCell) {
        isKeyboardVisisble = false
        var indexPath = presetCell.indexPath
        guard let indexPath = indexPath else { return }
        guard indexPath.row < presetsArray.count else { return }
        print("cell Row - \(indexPath.row), array count - \(presetsArray.count)")
        let preset: CBPreset = presetsArray[indexPath.row] as! CBPreset
        if presetCell.nameTextField.text?.isEmpty ?? true {
            preset.name = "Preset \(indexPath.row + 1)"
        }
        else {
            preset.name = presetCell.nameTextField.text!
        }
        self.savePresets()
        // Reload only the edited row without animation
        tableView.beginUpdates()
        tableView.reloadRows(at: [indexPath], with: .none)
        tableView.endUpdates()
    }
    
    func nameTextFieldBeginEditing(presetCell: CBPresetCell) {
        isKeyboardVisisble = true
        presetCell.nameTextField.becomeFirstResponder()
    }
    
    @objc func deselectPresetsNotification() {
        if !justChangedPreset {
            self.deselectPresets()
        }
    }
    
    func deselectPresets() {
        self.bidPeriod!.loadedPresetIdentifier = nil
        self.tableView.reloadData()
    }
    
    //    MARK: Table view
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.presetsArray.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "presetCell", for: indexPath) as! CBPresetCell
        cell.selectionStyle = .none
        cell.Delegate = self
        if indexPath.row == self.presetsArray.count {
            cell.nameLabel.text = "New Preset With Current Settings"
            cell.isEditing = true
            cell.deleteButton.alpha = 0
            cell.nameTextField.alpha = 0
            cell.nameLabel.alpha = 1
            cell.nameLabel.textColor = .label
            cell.addButton.alpha = 1
            cell.loadLabel.alpha = 0
        }
        else {
            let preset: CBPreset = self.presetsArray[indexPath.row] as! CBPreset
            cell.nameLabel.text = preset.name
            cell.nameLabel.alpha = 0
            cell.nameTextField.alpha = 1
            cell.nameTextField.text = preset.name
            cell.nameTextField.borderStyle = .none
            cell.indexPath = indexPath
            if preset.presetIdentifier == self.bidPeriod!.loadedPresetIdentifier {
                cell.loadLabel.alpha = 1
                cell.loadLabel.textColor = .label
                cell.loadLabel.layer.borderColor = CBColor.purple.cgColor
                cell.loadLabel.text = "Loaded"
            }
            else {
                cell.nameTextField.textColor = .label
                cell.loadLabel.alpha = 0.6
                cell.loadLabel.textColor = .label
                cell.loadLabel.layer.borderColor = CBColor.buttonLightTextColor.cgColor
                cell.loadLabel.text = "Load"
            }
            if (justAddedAPreset && indexPath.row == self.presetsArray.count - 1) {
                cell.nameTextField.becomeFirstResponder()
                justAddedAPreset = false
            }
            cell.addButton.alpha = 0
            cell.deleteButton.alpha = 1
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        UserDefaults.standard.set(true, forKey: kCBIsPresetModified)
        if (indexPath.row == self.presetsArray.count || isKeyboardVisisble) {
            return false
        }
        else {
            return true
        }
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        UserDefaults.standard.set(true, forKey: kCBIsPresetModified)
        let originRow = sourceIndexPath.row
        let destinationRow = destinationIndexPath.row
        if (originRow == destinationRow || destinationRow == self.presetsArray.count) {
            self.tableView.reloadData()
            return
        }
        let presetToMove = self.presetsArray[originRow]
        self.presetsArray.remove(at: originRow)
        self.presetsArray.insert(presetToMove, at: destinationRow)
        self.savePresets()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        if indexPath.row == self.presetsArray.count {
            return .insert
        }
        else {
            return .none
        }
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        UserDefaults.standard.set(true, forKey: kCBIsPresetModified)
        if indexPath.row == self.presetsArray.count {
            return false
        }
        else {
            return true
        }
    }
    
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let app = UIApplication.shared.delegate as! AppDelegate
        var objCommuteFilter: Commutability? = nil
        var objCommuteSort: Commutability? = nil
        if isKeyboardVisisble {
            return
        }
        // If user selected the last row, add a preset
        if indexPath.row == self.presetsArray.count {
            UserDefaults.standard.set(true, forKey: kCBIsPresetModified)
            
            // See if a current preset was selected, and if so, reload that row
            if let loadedID = bidPeriod?.loadedPresetIdentifier,
               let presetArrayHere = presetsArray as? [CBPreset],
               let selectedPreset = presetArrayHere.first(where: { $0.presetIdentifier == loadedID }),
               let row = presetArrayHere.firstIndex(where: { $0 === selectedPreset }) {
                
                bidPeriod?.loadedPresetIdentifier = nil

                tableView.beginUpdates()
                let indexPath = IndexPath(row: row, section: 0)
                tableView.reloadRows(at: [indexPath], with: .none)
                tableView.endUpdates()
            }

            
            // Grab the current filters set and add to the preset
            // FILTERS FETCH
            let fetchRequest: NSFetchRequest<BIFilterRule> = BIFilterRule.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "category", ascending: true), NSSortDescriptor(key: "type", ascending: true)]
            var filterResults = try? self.context.fetch(fetchRequest)
            fetchRequest.predicate = NSPredicate(format: "category == 33")
            let arrFilterCommute = try? self.context.fetch(fetchRequest)
            if (arrFilterCommute?.count) ?? 0 > 0 {
                //                checking commute filter
                let commutabiltyFetch: NSFetchRequest<Commutability> = Commutability.fetchRequest()
                commutabiltyFetch.predicate = NSPredicate(format: "commutableType == %d", CommutabilityType.filter.rawValue)
                let commutabiltyResult = try? self.context.fetch(commutabiltyFetch)
                if (commutabiltyResult?.count) ?? 0 > 0 {
                    objCommuteFilter = commutabiltyResult![0]
                }
                //Fetch commuteTime details and save
                let fetchCommuteTime: NSFetchRequest<CommuteTime> = CommuteTime.fetchRequest()
                let commuteTimeResult = try? self.context.fetch(fetchCommuteTime)
                if (commuteTimeResult?.count) ?? 0 > 0 {
                    arrCommuteTimeDetails = commuteTimeResult!
                }
                else {
                    // FILTER FETCH used the same code from the above
                    for filter in arrFilterCommute! {
                        self.context.delete(filter)
                    }
                    NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
                }
            }
            
            // Grab the current sorts set and add to the preset
            // SORT FETCH
            let fetchSort: NSFetchRequest<BILineSort> = BILineSort.fetchRequest()
            fetchSort.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
            let sortResult = try? self.context.fetch(fetchSort)
            fetchSort.predicate = NSPredicate(format: "category == 9")
            let arrSortCommute = try? self.context.fetch(fetchSort)
            if (arrSortCommute?.count) ?? 0 > 0 {
                let commutabiltyFetch: NSFetchRequest<Commutability> = Commutability.fetchRequest()
                commutabiltyFetch.predicate = NSPredicate(format: "commutableType == %d", CommutabilityType.sort.rawValue)
                let commutabiltyResult = try? self.context.fetch(commutabiltyFetch)
                if (commutabiltyResult?.count) ?? 0 > 0 {
                    objCommuteSort = commutabiltyResult![0]
                }
                //Fetch commuteTime details and save
                let fetchCommuteTime: NSFetchRequest<CommuteTime> = CommuteTime.fetchRequest()
                let commuteTimeResult = try? self.context.fetch(fetchCommuteTime)
                if (commuteTimeResult?.count) ?? 0 > 0 {
                    arrCommuteTimeDetails = commuteTimeResult!
                }
                else {
                    // FILTER FETCH used the same code from the above
                    for filter in arrFilterCommute! {
                        self.context.delete(filter)
                    }
                    NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
                }
            }
            //            line Values
            let lineValuesKey = CBLineValuesMenuController.lineValuesKeyForBidPeriod(bidPeriod: bidPeriod!)
            let fetchRequest1: NSFetchRequest<BIFilterRule> = BIFilterRule.fetchRequest()
            fetchRequest1.sortDescriptors = [NSSortDescriptor(key: "category", ascending: true), NSSortDescriptor(key: "type", ascending: true)]
            var filterResults1 = try? self.context.fetch(fetchRequest1)
            let fetchSort1: NSFetchRequest<BILineSort> = BILineSort.fetchRequest()
            fetchSort1.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
            let sortResult1 = try? self.context.fetch(fetchSort1)
            let lineValues = UserDefaults.standard.value(forKey: lineValuesKey) as? [Any] ?? []
            let newPreset = CBPreset(rules: filterResults1!, sorts: sortResult1!, lineValues: lineValues, name: "")
            newPreset.month = bidPeriod!.month
            newPreset.year = bidPeriod!.year
            newPreset.position = self.bidPeriod!.positionType
            newPreset.appVersion = bidPeriod!.appVersion
            
            if (arrFilterCommute?.count ?? 0 > 0 && !(arrSortCommute?.count ?? 0 > 0)) {
                newPreset.commutabilityFilterDetails = NSMutableDictionary()
                newPreset.commutabilityFilterDetails?["baseTime"] = objCommuteFilter!.baseTime
                newPreset.commutabilityFilterDetails?["checkInTime"] = objCommuteFilter!.checkInTime
                newPreset.commutabilityFilterDetails?["city"] = objCommuteFilter!.city
                newPreset.commutabilityFilterDetails?["commutableType"] = objCommuteFilter!.commutableType
                newPreset.commutabilityFilterDetails?["commuteCity"] = objCommuteFilter!.commuteCity
                newPreset.commutabilityFilterDetails?["connectTime"] = objCommuteFilter!.connectTime
                newPreset.commutabilityFilterDetails?["secondCellValue"] = objCommuteFilter!.secondCellValue
                newPreset.commutabilityFilterDetails?["thirdCellValue"] = objCommuteFilter!.thirdCellValue
                newPreset.commutabilityFilterDetails?["type"] = objCommuteFilter!.type
                newPreset.commutabilityFilterDetails?["value"] = objCommuteFilter!.value
                newPreset.commutabilityFilterDetails?["weight"] = objCommuteFilter!.weight
                newPreset.commutabilityFilterDetails?["isNonStop"] = objCommuteFilter!.isNonStop
            }
            
            if (arrSortCommute?.count ?? 0 > 0 && !(arrFilterCommute?.count ?? 0 > 0)) {
                newPreset.commutabilitySortDetails = NSMutableDictionary()
                newPreset.commutabilitySortDetails!["baseTime"] = objCommuteSort!.baseTime
                newPreset.commutabilitySortDetails!["checkInTime"] = objCommuteSort!.checkInTime
                newPreset.commutabilitySortDetails!["city"] = objCommuteSort!.city
                newPreset.commutabilitySortDetails!["commutableType"] = objCommuteSort!.commutableType
                newPreset.commutabilitySortDetails!["commuteCity"] = objCommuteSort!.commuteCity
                newPreset.commutabilitySortDetails!["connectTime"] = objCommuteSort!.connectTime
                newPreset.commutabilitySortDetails!["secondCellValue"] = objCommuteSort!.secondCellValue
                newPreset.commutabilitySortDetails!["thirdCellValue"] = objCommuteSort!.thirdCellValue
                newPreset.commutabilitySortDetails!["type"] = objCommuteSort!.type
                newPreset.commutabilitySortDetails!["value"] = objCommuteSort!.value
                newPreset.commutabilitySortDetails!["weight"] = objCommuteSort!.weight
                newPreset.commutabilitySortDetails!["isNonStop"] = objCommuteSort!.isNonStop
            }
            
            if (arrFilterCommute?.count ?? 0 > 0 && arrSortCommute?.count ?? 0 > 0) {
                newPreset.commutabilityFilterDetails = NSMutableDictionary()
                newPreset.commutabilityFilterDetails!["baseTime"] = objCommuteFilter!.baseTime
                newPreset.commutabilityFilterDetails!["checkInTime"] = objCommuteFilter!.checkInTime
                newPreset.commutabilityFilterDetails!["city"] = objCommuteFilter!.city
                newPreset.commutabilityFilterDetails!["commutableType"] = objCommuteFilter!.commutableType
                newPreset.commutabilityFilterDetails!["commuteCity"] = objCommuteFilter!.commuteCity
                newPreset.commutabilityFilterDetails!["connectTime"] = objCommuteFilter!.connectTime
                newPreset.commutabilityFilterDetails!["secondCellValue"] = objCommuteFilter!.secondCellValue
                newPreset.commutabilityFilterDetails!["thirdCellValue"] = objCommuteFilter!.thirdCellValue
                newPreset.commutabilityFilterDetails!["type"] = objCommuteFilter!.type
                newPreset.commutabilityFilterDetails!["value"] = objCommuteFilter!.value
                newPreset.commutabilityFilterDetails!["weight"] = objCommuteFilter!.weight
                newPreset.commutabilityFilterDetails!["isNonStop"] = objCommuteFilter!.isNonStop
                
                newPreset.commutabilitySortDetails = NSMutableDictionary()
                newPreset.commutabilitySortDetails!["baseTime"] = objCommuteSort!.baseTime
                newPreset.commutabilitySortDetails!["checkInTime"] = objCommuteSort!.checkInTime
                newPreset.commutabilitySortDetails!["city"] = objCommuteSort!.city
                newPreset.commutabilitySortDetails!["commutableType"] = objCommuteSort!.commutableType
                newPreset.commutabilitySortDetails!["commuteCity"] = objCommuteSort!.commuteCity
                newPreset.commutabilitySortDetails!["connectTime"] = objCommuteSort!.connectTime
                newPreset.commutabilitySortDetails!["secondCellValue"] = objCommuteSort!.secondCellValue
                newPreset.commutabilitySortDetails!["thirdCellValue"] = objCommuteSort!.thirdCellValue
                newPreset.commutabilitySortDetails!["type"] = objCommuteSort!.type
                newPreset.commutabilitySortDetails!["value"] = objCommuteSort!.value
                newPreset.commutabilitySortDetails!["weight"] = objCommuteSort!.weight
                newPreset.commutabilitySortDetails!["isNonStop"] = objCommuteSort!.isNonStop
            }
            
            // Commute time details for commutability filter
            if (self.arrCommuteTimeDetails?.count ?? 0 > 0) {
                let arrModifiedValues: NSMutableArray = []
                for i in 0 ..< self.arrCommuteTimeDetails!.count {
                    let dictData = NSMutableDictionary()
                    dictData["bidDay"] = self.arrCommuteTimeDetails![i].value(forKey: "bidDay")
                    dictData["earliestArrivel"] = self.arrCommuteTimeDetails![i].value(forKey: "earliestArrivel")
                    dictData["latestDeparture"] = self.arrCommuteTimeDetails![i].value(forKey: "latestDeparture")
                    dictData["type"] = self.arrCommuteTimeDetails![i].value(forKey: "type")
                    dictData["bidDayStringValue"] = self.arrCommuteTimeDetails![i].value(forKey: "bidDayStringValue")
                    arrModifiedValues.add(dictData)
                }
                newPreset.commuteTimeDetails = arrModifiedValues
            }
            
            // Fetch the applied overnight bulk cities list export for syncing.
            let fetchOvernightBulk: NSFetchRequest<OvernightBulk> = OvernightBulk.fetchRequest()
            let ovwerNightBulkResult = try? self.context.fetch(fetchOvernightBulk)
            if ovwerNightBulkResult?.count ?? 0 > 0 {
                let first = ovwerNightBulkResult![0]
                if let dict = first.citystatus as? [String: Any] {
                    let array = NSMutableArray(array: [dict])
                    newPreset.overnight = array
                }
            }
            self.presetsArray.append(newPreset)
            self.bidPeriod?.loadedPresetIdentifier = newPreset.presetIdentifier
            self.savePresets()
            
            let ip = IndexPath(row: indexPath.row, section: 0)
            
            justAddedAPreset = true
            tableView.beginUpdates()
            tableView.insertRows(at: [ip], with: .automatic)
            tableView.endUpdates()
            
        }
        //If user selected any other row, load that preset
        else {
            self.view.showActivityIndicator()
            UserDefaults.standard.set(true, forKey: kCBIsPresetModified)
            let cell = tableView.cellForRow(at: indexPath)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.justChangedPreset = true
                let preset: CBPreset = self.presetsArray[indexPath.row] as! CBPreset
                let valuesArrayforFilter = preset.filterRules.filter { rule in
                    guard let abbreviation = rule.abbreviation?.lowercased() else { return false }
                    return ["500s", "300s", "classic", "ng"].contains(abbreviation)
                }
                if valuesArrayforFilter.count > 0 {
                    print("")
                }
                preset.filterRules.removeAll { item in
                    valuesArrayforFilter.contains { ($0 as AnyObject) === (item as AnyObject) }
                }
                let valuesArrayforSorts = preset.lineSorts.filter { rule in
                    guard let abbreviation = rule.abbreviation?.lowercased() else { return false }
                    return ["500s", "300s", "classic", "ng"].contains(abbreviation)
                }
                if valuesArrayforSorts.count > 0 {
                    print("")
                }
                preset.lineSorts.removeAll { item in
                    valuesArrayforSorts.contains { ($0 as AnyObject) === (item as AnyObject) }
                }
                // Reset the trip highlight count
                BITrip.resetTripHighlightCount(in: self.context)
                
                // Delete all old filters and sorts
                // FILTERS FETCH
                let filterFetch: NSFetchRequest<BIFilterRule> = BIFilterRule.fetchRequest()
                filterFetch.sortDescriptors = [NSSortDescriptor(key: "category", ascending: true), NSSortDescriptor(key: "type", ascending: true)]
                let results = try? self.context.fetch(filterFetch)
                for filter in results  ?? [] {
                    self.context.delete(filter)
                }
                // SORT FETCH
                let sortFetch: NSFetchRequest<BILineSort> = BILineSort.fetchRequest()
                sortFetch.sortDescriptors = [NSSortDescriptor(key: "order", ascending: true)]
                let sortResults = try? self.context.fetch(sortFetch)
                for sort in sortResults ?? [] {
                    if (sort.lineSortKeyMap != nil) {
                        self.context.delete(sort.lineSortKeyMap!)
                    }
                    self.context.delete(sort)
                }
                //                delete commute filter and sort
                let commuteFetch: NSFetchRequest<Commutability> = Commutability.fetchRequest()
                commuteFetch.predicate = NSPredicate(format: "commutableType == %d || commutableType == %d", CommutabilityType.sort.rawValue, CommutabilityType.filter.rawValue)
                let commuteResults = try? self.context.fetch(commuteFetch)
                for commute in commuteResults  ?? [] {
                    self.context.delete(commute)
                }
                try? self.context.save()
                let fetchOvernightBulk: NSFetchRequest<OvernightBulk> = OvernightBulk.fetchRequest()
                let overNightBulkResults = try? self.context.fetch(fetchOvernightBulk)
                for over in overNightBulkResults ?? [] {
                    self.context.delete(over)
                }
                
                //                add filters from preset
                var isCommutabilityFilter = false
                var isCommutabilitySort = false
                var isOverNightBulkApplied = false
                
                for case let pRule in preset.filterRules {
                    let shouldRemoveFilter = self.removeDefaultFilter(category: pRule.category!)
                    if shouldRemoveFilter {
                        continue
                    }
                    let rule = BIFilterRule(context: self.context)
                    rule.loadFilterPreset(pRule: pRule)
                    rule.bidPeriod = self.bidPeriod
                    
                    if (pRule.category?.intValue == BIFilterRuleCategory.BIDaysOfMonthFilterRuleCategory.rawValue && (!( self.bidPeriod?.month?.intValue == preset.month?.intValue) || !(self.bidPeriod?.year?.intValue == preset.year?.intValue))) {
                        var monthBits = (pRule.variables!["MONTH_BITS"] as? NSNumber)?.uint64Value ?? 0
                        let zero: UInt64 = 0
                        monthBits = zero
                        let MONTH_BITS = NSNumber(value: monthBits)
                        rule.variables = ["MONTH_BITS": MONTH_BITS]
                    }
                    else if (pRule.category?.intValue == BIFilterRuleCategory.BICitiesFilterRuleCategory.rawValue && (pRule.type?.intValue == BICitiesFilterRuleType.BICitiesFilterRuleTypeEastCoast.rawValue || pRule.type?.intValue == BICitiesFilterRuleType.BICitiesFilterRuleTypeWestCoast.rawValue || pRule.type?.intValue == BICitiesFilterRuleType.BICitiesFilterRuleTypeNonConus.rawValue || pRule.type?.intValue == BICitiesFilterRuleType.BICitiesFilterRuleTypeIntl.rawValue || pRule.type?.intValue == BICitiesFilterRuleType.BICitiesFilterRuleTypeAll.rawValue || pRule.type?.intValue == BICitiesFilterRuleType.BICitiesFilterRuleTypeHawaii.rawValue)) {
                        let filterVars = pRule.variables
                        if let selectedCities = filterVars!["SET"] as? Set<String> {
                            rule.saveSelectedCities(Array(selectedCities))
                        }
                    }
                    else if (pRule.category?.intValue == BIFilterRuleCategory.BITypeFilterRuleCategory.rawValue) {
                        let filterVars = pRule.variables
                        if filterVars!["SET"] == nil {
                            var mutableFilterVars = filterVars
                            let tempSet = Set<AnyHashable>()
                            mutableFilterVars!["SET"] = tempSet
                            rule.variables = mutableFilterVars as NSDictionary?
                        }
                    }
                    else if pRule.category?.intValue == BIFilterRuleCategory.BICommutingFilterRuleCategory.rawValue {
                        let defaultCommuteTimes = UserDefaults.standard.value(forKey: kCBDefaultCommutingTimesKey) as? [Any] ?? []
                        if defaultCommuteTimes.isEmpty != true {
                            let monThursDept = (defaultCommuteTimes[0] as! NSNumber).intValue
                            let monThursRet = (defaultCommuteTimes[1] as! NSNumber).intValue
                            let friDept = (defaultCommuteTimes[2] as! NSNumber).intValue
                            let friRet = (defaultCommuteTimes[3] as! NSNumber).intValue
                            let satDept = (defaultCommuteTimes[4] as! NSNumber).intValue
                            let satRet = (defaultCommuteTimes[5] as! NSNumber).intValue
                            let sunDept = (defaultCommuteTimes[6] as! NSNumber).intValue
                            let sunRet = (defaultCommuteTimes[7] as! NSNumber).intValue
                            var variables = pRule.variables
                            if monThursDept > -1 {
                                variables![BIFilterRuleMonThursDepartTimeVariablesKey] = monThursDept
                            }
                            else {
                                variables![BIFilterRuleMonThursReturnTimeVariablesKey] = -1
                            }
                            if friDept > -1 {
                                variables![BIFilterRuleFriDepartTimeVariablesKey] = friDept
                            }
                            else {
                                variables![BIFilterRuleFriDepartTimeVariablesKey] = -1
                            }
                            if satDept > -1 {
                                variables![BIFilterRuleSatDepartTimeVariablesKey] = satDept
                            }
                            else {
                                variables![BIFilterRuleSatDepartTimeVariablesKey] = -1
                            }
                            if sunDept > -1 {
                                variables![BIFilterRuleSunDepartTimeVariablesKey] = sunDept
                            }
                            else {
                                variables![BIFilterRuleSunDepartTimeVariablesKey] = -1
                            }
                            if monThursRet < 3000 {
                                variables![BIFilterRuleMonThursReturnTimeVariablesKey] = monThursRet
                            }
                            else {
                                variables![BIFilterRuleMonThursReturnTimeVariablesKey] = 3000
                            }
                            if friRet < 3000 {
                                variables![BIFilterRuleFriReturnTimeVariablesKey] = friRet
                            }
                            else {
                                variables![BIFilterRuleFriReturnTimeVariablesKey] = 3000
                            }
                            if satRet < 3000 {
                                variables![BIFilterRuleSatReturnTimeVariablesKey] = satRet
                            }
                            else {
                                variables![BIFilterRuleSatReturnTimeVariablesKey] = 3000
                            }
                            if sunRet < 3000 {
                                variables![BIFilterRuleSunReturnTimeVariablesKey] = sunRet
                            }
                            else {
                                variables![BIFilterRuleSunReturnTimeVariablesKey] = 3000
                            }
                            pRule.variables = variables
                        }
                        else {
                            
                            self.calculateCommuteMannualfilter(variables: pRule.variables!)
                        }
                    }
                    else if pRule.category?.intValue == BIFilterRuleCategory.BIOvernightCitiesBulkRuleCategory.rawValue {
                        let overNIghtBulk = OvernightBulk(context: self.context)
                        overNIghtBulk.citystatus = preset.overnight
                        try? self.context.save()
                        if preset.overnight?.count ?? 0 > 0 {
                            isOverNightBulkApplied = true
                        }
                    }
                    
                    else if pRule.category?.intValue == BIFilterRuleCategory.BICommutabilityFilterRuleCategory.rawValue {
                        isCommutabilityFilter = true
                        let filterVars = pRule.variables
                        if filterVars!["SET"] == nil {
                            var mutableFilterVars = filterVars
                            let tempSet = Set<AnyHashable>()
                            mutableFilterVars!["SET"] = tempSet
                            rule.variables = mutableFilterVars as NSDictionary?
                        }
                        let objCommutability = Commutability(context: self.context)
                        objCommutability.thirdCellValue = preset.commutabilityFilterDetails!["thirdCellValue"] as? NSNumber
                        objCommutability.secondCellValue = preset.commutabilityFilterDetails!["secondCellValue"] as? NSNumber
                        objCommutability.city = preset.commutabilityFilterDetails!["city"] as? String
                        objCommutability.checkInTime = preset.commutabilityFilterDetails!["checkInTime"] as? NSNumber
                        objCommutability.connectTime = preset.commutabilityFilterDetails!["connectTime"] as? NSNumber
                        objCommutability.baseTime = preset.commutabilityFilterDetails!["baseTime"] as? NSNumber
                        objCommutability.type = preset.commutabilityFilterDetails!["type"] as? NSNumber
                        objCommutability.weight = preset.commutabilityFilterDetails!["weight"] as? NSNumber
                        objCommutability.value = preset.commutabilityFilterDetails!["value"] as? NSNumber
                        objCommutability.isNonStop = preset.commutabilityFilterDetails!["isNonStop"] as? NSNumber
                        
                        for i in 0..<(preset.commuteTimeDetails?.count ?? 0) {
                            var objCommuteTimeImport = CommuteTime(context: self.context)
                            objCommuteTimeImport.bidDay = (preset.commuteTimeDetails![i] as? [String: Any])?["bidDay"] as? Date
                            objCommuteTimeImport.earliestArrivel = (preset.commuteTimeDetails![i] as? [String: Any])?["earliestArrivel"] as? Date
                            objCommuteTimeImport.latestDeparture = (preset.commuteTimeDetails![i] as? [String: Any])?["latestDeparture"] as? Date
                            objCommuteTimeImport.type = (preset.commuteTimeDetails![i] as? [String: Any])?["type"] as? NSNumber
                            objCommuteTimeImport.bidDayStringValue = (preset.commuteTimeDetails![i] as? [String: Any])?["bidDayStringValue"] as? String
                        }
                        try? self.context.save()
                        let thirdCellValue = preset.commutabilityFilterDetails!["thirdCellValue"] as? NSNumber
                        let secondCellValue = preset.commutabilityFilterDetails!["secondCellValue"] as? NSNumber
                        let value = preset.commutabilityFilterDetails!["value"] as? NSNumber
                        let city = preset.commutabilityFilterDetails!["city"] as? String
                        let checkInTime = preset.commutabilityFilterDetails!["checkInTime"] as? NSNumber
                        let connectTime = preset.commutabilityFilterDetails!["connectTime"] as? NSNumber
                        let baseTime = preset.commutabilityFilterDetails!["baseTime"] as? NSNumber
                        let nonStop = preset.commutabilityFilterDetails!["isNonStop"] as? NSNumber
                        
                        var commuteCity = city ?? ""
                        var isNonStop = nonStop?.boolValue ?? false
                        
                        let commuteVC = CommuteCityViewController()
//                        CBGlobalMethods.shared.showCustomActivityIndicator(message: "Calculating commute values..", bgcolor: .purple, height: 100)
                        let (success, commuteCityReturn) = commuteVC.commutabilityCalculationWithForSync(city: city!, isNonStop: isNonStop, connectTimeFromPreset: connectTime as! Int)
//                        CBGlobalMethods.shared.hideCustomActivityIndicator()
                        let commutInfoVC = CBCommuteInfoViewController()
                        commutInfoVC.backToBaseFromSync = self.getHours(minutes: baseTime!)
                        let connectTimeStr = self.getHours(minutes: connectTime!)
                        if connectTimeStr == "--:--" {
                            commutInfoVC.connectTimeFromSync = "0:0"
                        }
                        else {
                            commutInfoVC.connectTimeFromSync = connectTimeStr
                        }
                        commutInfoVC.checkInFromSync = self.getHours(minutes: checkInTime!)
                        commutInfoVC.bidPeriod = self.bidPeriod
                        commutInfoVC.commutabilityType = CommutabilityType.filter
                        commutInfoVC.isNonStop = isNonStop
                        commutInfoVC.commuteCityFromSync = city
                        commutInfoVC.thirdCellValue = thirdCellValue!
                        commutInfoVC.secondCellValue = secondCellValue ?? 0
                        commutInfoVC.value = value ?? 0
                        commutInfoVC.calculateCommuteLineProperties()
                        NotificationCenter.default.post(name: NSNotification.Name("refreshWorkBlock"), object: self)
                        try? self.context.save()
                    }
                    else if pRule.category?.intValue == BIFilterRuleCategory.BIReportReleaseFilterCategory.rawValue {
                        if rule.variables!["selectedOption"] != nil {
                            let variables = rule.variables
                            let dict2 = variables
                            var reportValue = ""
                            var releaseValue = ""
                            var isLast = 0
                            var isNoMid = 0
                            var isCalendar = 0
                            var isFirst = 0
                            var isAllDays = 0
                            var isSelectedAll = 0
                            let selectedDates = NSMutableArray()
                            var selectedIndices = NSMutableArray()
                            selectedIndices = (dict2!["selectedIndex"] as? NSMutableArray)!
                            if dict2!["reportValue"] != nil {
                                reportValue = (dict2!["reportValue"] as? String)!
                            }
                            if dict2!["releaseValue"] != nil {
                                releaseValue = (dict2!["releaseValue"] as? String)!
                            }
                            if dict2!["isFirst"] != nil {
                                isFirst = ((dict2!["isFirst"] as? Int)!)
                            }
                            if dict2!["isLast"] != nil {
                                isLast = ((dict2!["isLast"] as? Int)!)
                            }
                            if dict2!["isNoMid"] != nil {
                                isNoMid = ((dict2!["isNoMid"] as? Int)!)
                            }
                            if dict2!["selectedOption"] != nil {
                                let tmp = dict2!["selectedOption"] as? Int
                                if tmp == 0 {
                                    isSelectedAll = 1
                                    isAllDays = 1
                                }
                                else if tmp == 2 {
                                    isCalendar = 1
                                }
                            }
                            
                            var tempDict = [String: Any]()
                            tempDict["isAllDays"] = isAllDays
                            tempDict["isCalendar"] = isCalendar
                            tempDict["isFirst"] = isFirst
                            tempDict["isLast"] = isLast
                            tempDict["isNoMid"] = isNoMid
                            tempDict["isSelectedAll"] = isSelectedAll
                            tempDict["releaseValue"] = releaseValue
                            tempDict["reportValue"] = reportValue
                            
                            var MONTH_BITS = NSNumber(value: 0)
                            for i in 0 ..< selectedIndices.count {
                                var strDay: [String] = []
                                let indexValue = selectedIndices[i] as! Int
                                let nsi = indexValue
                                var mask: UInt64 = 0
                                var monthBits: UInt64 = 0
                                let one: UInt64 = 1
                                if MONTH_BITS != 0 {
                                    monthBits = MONTH_BITS.uint64Value
                                }
                                mask = one << UInt64(nsi)
                                monthBits |= mask
                                MONTH_BITS = NSNumber(value: monthBits)
                                
                                let day = self.calendarData.calendarDays[i] as? BICalendarDay
                                if !(day!.isCurrentMonth) {
                                    if self.bidPeriod?.month?.intValue == 12 {
                                        let month = NSNumber(value: 1)
                                        let year = self.bidPeriod!.year!
                                        strDay.append(String(i))
                                        strDay.append(String(describing: month))
                                        strDay.append(String(describing: year))
                                    }
                                    else {
                                        strDay.append(day!.text)
                                        strDay.append(String(self.bidPeriod!.month!.intValue + 1))
                                        strDay.append(String(describing: self.bidPeriod!.year!))
                                    }
                                }
                                else {
                                    strDay.append(day!.text)
                                    strDay.append(String(self.bidPeriod!.month!.intValue))
                                    strDay.append(String(describing: self.bidPeriod!.year!))
                                }
                                selectedDates.add(strDay.joined(separator: "-"))
                            }
                            tempDict["SELECTED_DATES"] = selectedDates
                            tempDict["MONTH_BITS"] = MONTH_BITS
                            rule.variables = tempDict as NSDictionary
                            try? self.context.save()
                        }
                    }
                    if rule.ruleHighlightsTrips() {
                        rule.highlightTrips()
                    }
                }
                
                self.addDefaultFilter(presetFylterRules: preset.filterRules, context: self.context)
                if preset.filterRules.count > 0 {
                    self.justLoadedFilterPreset = true
                }
                
                //                 add sorts from preset
                for pSort in preset.lineSorts {
                    let sort = BILineSort(context: self.context)
                    sort.isBidListSort = NSNumber(booleanLiteral: false)
                    sort.loadLineSort(pSort: pSort)
                    sort.bidPeriod = self.bidPeriod
                    if sort.category?.intValue == BILineSortCategory.BIFlagLineSortCategory.rawValue {
                        if pSort.arrayVariables == nil {
                            let variables = NSMutableArray()
                            if pSort.variables!["NO_COLOR_FLAG"] != nil {
                                variables.add(0)
                            }
                            if pSort.variables!["BLUE_COLOR_FLAG"] != nil {
                                variables.add(1)
                            }
                            if pSort.variables!["GREEN_COLOR_FLAG"] != nil {
                                variables.add(2)
                            }
                            if pSort.variables!["RED_COLOR_FLAG"] != nil {
                                variables.add(3)
                            }
                            if pSort.variables!["YELLOW_COLOR_FLAG"] != nil {
                                variables.add(4)
                            }
                            if pSort.variables!["ORANGE_COLOR_FLAG"] != nil {
                                variables.add(5)
                            }
                            if pSort.variables!["ORANGE_COLOR_FLAG"] != nil {
                                variables.add(6)
                            }
                            if pSort.variables!["PINK_COLOR_FLAG"] != nil {
                                variables.add(7)
                            }
                            sort.arrayVariables = variables
                        }
                        else {
                            sort.arrayVariables = pSort.arrayVariables
                        }
                    }
                    else if sort.category?.intValue == BILineSortCategory.BIDeadheadsLineSortCategory.rawValue && (sort.type?.intValue == BIDeadheadLineSortType.BIDeadheadAtEndSortType.rawValue || sort.type?.intValue == BIDeadheadLineSortType.BIDeadheadAtBothSortType.rawValue || sort.type?.intValue == BIDeadheadLineSortType.BIDeadheadAtStartSortType.rawValue) {
                        var deadHeadCitiesSet = NSMutableSet()
                        var alertMsg: String = ""
                        if sort.type?.intValue == BIDeadheadLineSortType.BIDeadheadAtStartSortType.rawValue {
                            if let cities = self.bidPeriod!.deadheadAtStartCities?.value(forKey: "city") as? [Any] {
                                deadHeadCitiesSet = NSMutableSet(array: cities)
                            }
                            alertMsg = "at start to"
                        }
                        else if sort.type?.intValue == BIDeadheadLineSortType.BIDeadheadAtEndSortType.rawValue {
                            if let cities = self.bidPeriod!.deadheadAtEndCities?.value(forKey: "city") as? [Any] {
                                deadHeadCitiesSet = NSMutableSet(array: cities)
                            }
                            alertMsg = "at end from"
                        }
                        else {
                            if let startCities = self.bidPeriod!.deadheadAtStartCities?.value(forKey: "city") as? [Any] {
                                deadHeadCitiesSet = NSMutableSet(array: startCities)
                            }
                            
                            if let endCities = self.bidPeriod!.deadheadAtEndCities?.value(forKey: "city") as? [Any] {
                                deadHeadCitiesSet.union(NSMutableSet(array: endCities) as Set<NSObject>)
                            }
                            alertMsg = "at either from/to"
                        }
                        if deadHeadCitiesSet.contains(pSort.city ?? "Jsut for default") {
                            sort.city = pSort.city
                        }
                        else {
                            AlertService.showAlertForTopVC(title: "Deadhead City Not Found", message: "This month's lines do not contain deadheads \(alertMsg) \(String(describing: pSort.city))")
                        }
                    }
                    else if sort.category?.intValue == BILineSortCategory.BICitiesLineSortCategory.rawValue {
                        if (sort.type?.intValue == BICityLineSortType.BICitiesLineSortTypeEastCoast.rawValue || sort.type?.intValue == BICityLineSortType.BICitiesLineSortTypeWestCoast.rawValue || sort.type?.intValue == BICityLineSortType.BICitiesLineSortTypeNonConus.rawValue ||
                            sort.type?.intValue == BICityLineSortType.BICitiesLineSortTypeIntl.rawValue ||
                            sort.type?.intValue == BICityLineSortType.BICitiesLineSortTypeAll.rawValue ||
                            sort.type?.intValue == BICityLineSortType.BICitiesLineSortTypeHawaii.rawValue) {
                            let filterVars = sort.variables
                            if let set = filterVars!["SET"] as? NSSet {
                                let selectedCities = set.allObjects
                                sort.saveSelectedCities(selectedCities)
                            }
                            sort.keyPath = sort.bidPeriod?.lineSortKeyForCityLineSort(cityLineSort: sort, city: "")
                        }
                        else if (pSort.city != nil && pSort.city != "") {
                            sort.city = pSort.city
                        }
                    }
                    else if sort.category?.intValue == BILineSortCategory.BICommutingLineSortCategory.rawValue {
                        if let variables = sort.variables {
                            for key in variables.allKeys {
                                if let key = key as? String,
                                   let value = variables[key] as? String,
                                   let intValue = Int(value) {
                                    
                                    let tempDict = variables.mutableCopy() as! NSMutableDictionary
                                    tempDict[key] = intValue
                                    sort.variables = tempDict
                                }
                            }
                            sort.keyPath = "commutabilityOverall"
                            self.calculateCommuteMannualSort(pRule: pSort.variables!)
                        }
                    }
                    else if sort.category?.intValue == BILineSortCategory.BIDaysOffLineSortCategory.rawValue {
                        sort.ascending = 1
                        sort.keyPath = self.bidPeriod?.lineSortKeyForDaysOff(lineSort: sort)
                    }
                    else if sort.category?.intValue == BILineSortCategory.BIDaysWorkLineSortCategory.rawValue {
                        sort.ascending = 1
                        sort.keyPath = self.bidPeriod?.lineSortKeyForDaysWork(lineSort: sort)
                    }
                    else if sort.category?.intValue == BILineSortCategory.BIDaysTripStartSortCategory.rawValue {
                        sort.ascending = 1
                        sort.keyPath = self.bidPeriod?.lineSortKeyForTripStartDays(lineSort: sort)
                    }
                    else if sort.category?.intValue == BILineSortCategory.BICommutabilityLineSortCategory.rawValue {
                        isCommutabilitySort = true
                        var objCommutability = Commutability()
                        var objCommuteTimeImport = CommuteTime()
                        objCommutability = Commutability(context: self.context)
                        objCommutability.thirdCellValue = preset.commutabilitySortDetails!["thirdCellValue"] as? NSNumber
                        objCommutability.secondCellValue = preset.commutabilitySortDetails!["secondCellValue"] as? NSNumber
                        objCommutability.commutableType = CommutabilityType.sort.rawValue as NSNumber
                        objCommutability.city = preset.commutabilitySortDetails!["city"] as? String
                        objCommutability.checkInTime = preset.commutabilitySortDetails!["checkInTime"] as? NSNumber
                        objCommutability.connectTime = preset.commutabilitySortDetails!["connectTime"] as? NSNumber
                        objCommutability.baseTime = preset.commutabilitySortDetails!["baseTime"] as? NSNumber
                        objCommutability.type = preset.commutabilitySortDetails!["type"] as? NSNumber
                        objCommutability.weight = preset.commutabilitySortDetails!["weight"] as? NSNumber
                        objCommutability.value = preset.commutabilitySortDetails!["value"] as? NSNumber
                        objCommutability.isNonStop = preset.commutabilitySortDetails!["isNonStop"] as? NSNumber
                        try? self.context.save()
                        
                        for i in 0 ..< (preset.commuteTimeDetails?.count ?? 0) {
                            objCommuteTimeImport = CommuteTime(context: self.context)
                            objCommuteTimeImport.bidDay = (preset.commuteTimeDetails![i] as? [String: Any])?["bidDay"] as? Date
                            objCommuteTimeImport.earliestArrivel = (preset.commuteTimeDetails![i] as? [String: Any])?["earliestArrivel"] as? Date
                            objCommuteTimeImport.latestDeparture = (preset.commuteTimeDetails![i] as? [String: Any])?["latestDeparture"] as? Date
                            objCommuteTimeImport.type = (preset.commuteTimeDetails![i] as? [String: Any])?["type"] as? NSNumber
                            objCommuteTimeImport.bidDayStringValue = (preset.commuteTimeDetails![i] as? [String: Any])?["bidDayStringValue"] as? String
                        }
                        try? self.context.save()
                        let thirdCellValue = preset.commutabilitySortDetails!["thirdCellValue"] as? NSNumber
                        let secondCellValue = preset.commutabilitySortDetails!["secondCellValue"] as? NSNumber
                        let value = preset.commutabilitySortDetails!["value"] as? NSNumber
                        let city = preset.commutabilitySortDetails!["city"] as? String
                        let checkInTime = preset.commutabilitySortDetails!["checkInTime"] as? NSNumber
                        let connectTime = preset.commutabilitySortDetails!["connectTime"] as? NSNumber
                        let baseTime = preset.commutabilitySortDetails!["baseTime"] as? NSNumber
                        let nonStop = preset.commutabilitySortDetails!["isNonStop"] as? NSNumber
                        
                        var commuteCity = city ?? ""
                        var isNonStop = nonStop?.boolValue ?? false
                        
                        let commuteVC = CommuteCityViewController()
//                        CBGlobalMethods.shared.showCustomActivityIndicator(message: "Calculating commute values..", bgcolor: .purple, height: 100)
                        let (success, commuteCityReturn) = commuteVC.commutabilityCalculationWithForSync(city: city!, isNonStop: isNonStop, connectTimeFromPreset: connectTime as! Int)
//                        CBGlobalMethods.shared.hideCustomActivityIndicator()
                        let commutInfoVC = CBCommuteInfoViewController()
                        commutInfoVC.backToBaseFromSync = self.getHours(minutes: baseTime!)
                        let connectTimeStr = self.getHours(minutes: connectTime!)
                        if connectTimeStr == "--:--" {
                            commutInfoVC.connectTimeFromSync = "0:0"
                        }
                        else {
                            commutInfoVC.connectTimeFromSync = connectTimeStr
                        }
                        commutInfoVC.checkInFromSync = self.getHours(minutes: checkInTime!)
                        commutInfoVC.bidPeriod = self.bidPeriod
                        commutInfoVC.commutabilityType = CommutabilityType.sort
                        commutInfoVC.isNonStop = isNonStop
                        commutInfoVC.commuteCityFromSync = city
                        commutInfoVC.secondCellValue = secondCellValue ?? 0
                        commutInfoVC.value = value ?? 0
                        commutInfoVC.thirdCellValue = thirdCellValue!
                        commutInfoVC.calculateCommuteLineProperties()
                        NotificationCenter.default.post(name: NSNotification.Name("refreshWorkBlock"), object: self)
                        try? self.context.save()
                    }
                    else if sort.category?.intValue == BILineSortCategory.BIPositionsLineSortCategory.rawValue {
                        sort.keyPath = self.bidPeriod?.lineSortKeyForPosition(posLineSort: sort)
                    }
                    if sort.sortHighlightsTrips() == true {
                        sort.highlightTrips()
                    }
                    if preset.lineSorts.count > 0 {
                        self.justLoadedSortPreset = true
                    }
                }
                
                if isOverNightBulkApplied {
                    self.bidPeriod?.isOverNightBulkApplied = "YES"
                    
                    // Fetch OvernightBulk objects
                    let fetchRequest: NSFetchRequest<OvernightBulk> = OvernightBulk.fetchRequest()
                    
                    if let fetchedObjects = try? self.context.fetch(fetchRequest),
                       let firstObject = fetchedObjects.first,
                       let cityStatus = firstObject.value(forKey: "citystatus") as? [String: String] {
                        
                        // Filter keys where value == "1"
                        let noArray = cityStatus.filter { $0.value == "1" }.map { $0.key }
                        
                        CBUtils.overnightBulkRedApply(noArray: noArray as NSArray)
                        
                    } else {
                        // No objects or cityStatus is nil
                        CBUtils.overnightBulkRedApply(noArray: [])
                    }
                    
                    NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
                }
                var linesValueKey = ""
                if self.bidPeriod?.containsVacay?.boolValue == false {
                    linesValueKey = self.bidPeriod!.isSecondRoundBid() && self.bidPeriod!.isFABid() != true ? kCBRound2DefaultLineValuesKey : kCBDefaultLineValuesKey
//                    AlertService.showAlertForTopVC(title: "Alert", message: "Your Preset includes line vacation properties.Because you do not have vacation, we are displaying the default line properties.")
                }
                else {
                    linesValueKey = CBLineValuesMenuController.lineValuesKeyForBidPeriod(bidPeriod: self.bidPeriod!)
                    UserDefaults.standard.set(preset.lineValues, forKey: linesValueKey)
                }
                self.deselectPresets()
                let presetToSelect = self.presetsArray[indexPath.row] as! CBPreset
                presetToSelect.selected = true
                self.bidPeriod!.loadedPresetIdentifier = presetToSelect.presetIdentifier
                try! self.context.save()
                self.tableView.reloadData()
                NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
                //                    need to add observer for notification
                self.view.hideActivityIndicator()
            }
            try? self.context.save()
        }
    }
    
    func removeDefaultFilter(category: NSNumber) -> Bool {
        if self.bidPeriod?.isFABid() == true {
            if self.bidPeriod!.isFirstRoundBid() {
                if category.intValue == BIFilterRuleCategory.BIFaReserveFilterRuleCategory.rawValue {
                    return true
                }
            }
        }
        else {
            if ( category.intValue == BIFilterRuleCategory.BIFaReserveFilterRuleCategory.rawValue || category.intValue == BIFilterRuleCategory.BIPositionFilterRuleCategory.rawValue) {
                return true
            }
        }
        return false
    }
    
    func addDefaultFilter(presetFylterRules: [CBPresetFilterRule], context: NSManagedObjectContext) {
        if (presetFylterRules.count == 0) {
            return
        }
        let categories = NSMutableArray()
        for rule in presetFylterRules {
            if rule.category != nil {
                categories.add(rule.category!)
            }
        }
        var rule: BIFilterRule? = nil
        if bidPeriod?.isFABid() == true {
            if bidPeriod!.isFirstRoundBid() {
                if categories.contains(BIFilterRuleCategory.BIPositionFilterRuleCategory.rawValue) == false {
                    rule = BIFilterRule(context: self.context)
                    rule?.bidPeriod = self.bidPeriod
                    rule!.category = BIFilterRuleCategory.BIPositionFilterRuleCategory.rawValue as NSNumber
                    rule!.type = BIPositionFilterRuleType.BIPositionCompoundType.rawValue as NSNumber
                    let SET: Set<Int> = [BIFaPosition.FaPositionA.rawValue, BIFaPosition.FaPositionA.rawValue, BIFaPosition.FaPositionB.rawValue, BIFaPosition.FaPositionC.rawValue, BIFaPosition.FaPositionD.rawValue, BIFaPosition.FaPositionMultiple.rawValue, BIFaPosition.FaPositionNA.rawValue]
                    rule!.variables = ["SET": SET]
                }
            }
            if bidPeriod!.isSecondRoundBid() {
                if categories.contains(BIFilterRuleCategory.BIPositionFilterRuleCategory.rawValue) == false {
                    rule = BIFilterRule(context: self.context)
                    rule?.bidPeriod = self.bidPeriod
                    rule!.category = BIFilterRuleCategory.BIPositionFilterRuleCategory.rawValue as NSNumber
                    rule!.type = BIPositionFilterRuleType.BIPositionCompoundType.rawValue as NSNumber
                    let SET: Set<Int> = [BIFaPosition.FaPositionA.rawValue, BIFaPosition.FaPositionA.rawValue, BIFaPosition.FaPositionB.rawValue, BIFaPosition.FaPositionC.rawValue, BIFaPosition.FaPositionD.rawValue, BIFaPosition.FaPositionMultiple.rawValue, BIFaPosition.FaPositionNA.rawValue]
                    rule!.variables = ["SET": SET]
                }
                if categories.contains(BIFilterRuleCategory.BIFaReserveFilterRuleCategory.rawValue) == false {
                    rule = BIFilterRule(context: self.context)
                    rule?.bidPeriod = self.bidPeriod
                    rule?.category = BIFilterRuleCategory.BIFaReserveFilterRuleCategory.rawValue as NSNumber
                    let SET: Set<Int> = [BIFaPosition.FaPositionA.rawValue, BIFaReserveLineType.SnrAMres.rawValue, BIFaReserveLineType.SnrPMres.rawValue, BIFaReserveLineType.JnrAMres.rawValue, BIFaReserveLineType.JnrPMres.rawValue, BIFaReserveLineType.JnrLateRes.rawValue, BIFaReserveLineType.NoType.rawValue]
                    rule!.variables = ["SET": SET]
                }
            }
        }
        
        if rule != nil {
            do {
                try self.context.save()
            }
            catch {
                print("unable to save managed object context after adding default filter rules. \(error.localizedDescription)")
            }
        }
    }
    
    func getHours(minutes: NSNumber) -> String {
        let hours = Int(minutes.intValue / 60)
        let mins = Int(minutes.intValue % 60)
        return String(format: "%02d:%02d", hours, mins)
    }
    
    func calculateCommuteMannualfilter(variables: [String: Any]) {
        if setCommuteTimeForDaysForManualFilter(variables: variables) {
            let obj = CBCommutingCellHelper()
            
            // Helper to safely extract string
            func stringValue(for key: String, from dict: [String: Any]) -> String {
                guard let value = dict[key] else { return "" }
                if let str = value as? String { return str }
                if let num = value as? NSNumber { return num.stringValue }
                if let intVal = value as? Int { return String(intVal) }
                return ""
            }
            
            // Helper to safely extract Int
            func intValue(for key: String, from dict: [String: Any]) -> Int {
                guard let value = dict[key] else { return 0 }
                if let num = value as? NSNumber { return num.intValue }
                if let intVal = value as? Int { return intVal }
                if let str = value as? String, let intVal = Int(str) { return intVal }
                return 0
            }
            
            // Safely extract values
            let noMidCheckState = intValue(for: "NoMidCheckState", from: variables)
            let monThursDept = stringValue(for: BIFilterRuleMonThursDepartTimeVariablesKey, from: variables)
            let monThursRet = stringValue(for: BIFilterRuleMonThursReturnTimeVariablesKey, from: variables)
            let friDept = stringValue(for: BIFilterRuleFriDepartTimeVariablesKey, from: variables)
            let friRet = stringValue(for: BIFilterRuleFriReturnTimeVariablesKey, from: variables)
            let satDept = stringValue(for: BIFilterRuleSatDepartTimeVariablesKey, from: variables)
            let satRet = stringValue(for: BIFilterRuleSatReturnTimeVariablesKey, from: variables)
            let sunDept = stringValue(for: BIFilterRuleSunDepartTimeVariablesKey, from: variables)
            let sunRet = stringValue(for: BIFilterRuleSunReturnTimeVariablesKey, from: variables)
            
            guard let bidPeriod = self.bidPeriod else {
                print("⚠️ Missing bidPeriod")
                return
            }
            
            // Compute based on mode
            if noMidCheckState == 1 {
                obj.calculateCommuteLinePropertiesForWorkblock(withDepartureMonThursText: monThursDept, departureFriText: friDept, departureSatText: satDept, departureSunText: sunDept, returnMonThursText: monThursRet, returnSunText: sunRet, returnSatText: satRet, returnFriText: friRet, bidPeriod: bidPeriod)
            } else {
                obj.calculateCommuteLinePropertiesForManualTrips(withDepartureMonThursText: monThursDept, departureFriText: friDept, departureSatText: satDept, departureSunText: sunDept, returnMonThursText: monThursRet, returnSunText: sunRet,returnSatText: satRet,returnFriText: friRet,bidPeriod: bidPeriod)
            }
        }
        NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
    }
    
    func calculateCommuteMannualSort(pRule: [String: Any]) {
        if setCommuteTimeForDaysForManualSort(pRule: pRule) {
            let obj = CBCommutingCellHelper()
            
            let variables = pRule
            
            // Helper to safely extract string
            func stringValue(for key: String, from dict: [String: Any]) -> String {
                guard let value = dict[key] else { return "" }
                if let str = value as? String { return str }
                if let num = value as? NSNumber { return num.stringValue }
                if let intVal = value as? Int { return String(intVal) }
                return ""
            }
            
            // Helper to safely extract Int
            func intValue(for key: String, from dict: [String: Any]) -> Int {
                guard let value = dict[key] else { return 0 }
                if let num = value as? NSNumber { return num.intValue }
                if let intVal = value as? Int { return intVal }
                if let str = value as? String, let intVal = Int(str) { return intVal }
                return 0
            }
            
            // Safely extract values
            let noMidCheckState = intValue(for: "NoMidCheckState", from: variables)
            let monThursDept = stringValue(for: BIFilterRuleMonThursDepartTimeVariablesKey, from: variables)
            let monThursRet = stringValue(for: BIFilterRuleMonThursReturnTimeVariablesKey, from: variables)
            let friDept = stringValue(for: BIFilterRuleFriDepartTimeVariablesKey, from: variables)
            let friRet = stringValue(for: BIFilterRuleFriReturnTimeVariablesKey, from: variables)
            let satDept = stringValue(for: BIFilterRuleSatDepartTimeVariablesKey, from: variables)
            let satRet = stringValue(for: BIFilterRuleSatReturnTimeVariablesKey, from: variables)
            let sunDept = stringValue(for: BIFilterRuleSunDepartTimeVariablesKey, from: variables)
            let sunRet = stringValue(for: BIFilterRuleSunReturnTimeVariablesKey, from: variables)
            
            guard let bidPeriod = self.bidPeriod else {
                print("⚠️ Missing bidPeriod")
                return
            }
            
            // Compute based on mode
            if noMidCheckState == 1 {
                obj.calculateCommuteLinePropertiesForWorkblock(withDepartureMonThursText: monThursDept, departureFriText: friDept, departureSatText: satDept, departureSunText: sunDept, returnMonThursText: monThursRet, returnSunText: sunRet, returnSatText: satRet, returnFriText: friRet, bidPeriod: bidPeriod)
            } else {
                obj.calculateCommuteLinePropertiesForManualTrips(withDepartureMonThursText: monThursDept, departureFriText: friDept, departureSatText: satDept, departureSunText: sunDept, returnMonThursText: monThursRet, returnSunText: sunRet,returnSatText: satRet,returnFriText: friRet,bidPeriod: bidPeriod)
            }
        }
        NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
    }
    

    func setCommuteTimeForDaysForManualFilter(variables: [String: Any]) -> Bool {
        let result = CBGlobalMethods.shared.selectedBidPeriod!.commuteTime?.allObjects
        for basket in result! {
            self.context.delete(basket as! NSManagedObject)
        }
        let startDate = self.startOfMonth()
        let dateFormat = DateFormatter()
        var endDate = self.endOfMonth()
        let daysToAdd = 4
        endDate = endDate?.addingTimeInterval(TimeInterval(60 * 60 * 24 * daysToAdd))
        let minDateString = "01/01/0001 00:00:00"
        
        dateFormat.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormat.locale = Locale.current
        dateFormat.dateFormat = "MM/dd/yyyy hh:mm:ss"
        
        let minDate = dateFormat.date(from: minDateString)
        var oneWeek = DateComponents()
        oneWeek.day = 1
        oneWeek.hour = 1
        //
        var tempStartDate = startDate
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        
        let dateFormatterForDayname = DateFormatter()
        dateFormatterForDayname.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatterForDayname.dateFormat = "EEEE"
        
        while tempStartDate?.compare(endDate!) == .orderedAscending || tempStartDate?.compare(endDate!) == .orderedSame {
            //Set WorkBlock Details
            let commuteEntity = NSEntityDescription.entity(forEntityName: "CommuteTime", in: (bidPeriod?.managedObjectContext)!)
            var objcommuteTime: CommuteTime? = nil
            objcommuteTime = CommuteTime(entity: commuteEntity!, insertInto: context)
            objcommuteTime?.commutable = bidPeriod
            let date = formatter.string(from: tempStartDate!)
            objcommuteTime?.bidDay = tempStartDate as NSDate? as Date?
            objcommuteTime?.bidDayStringValue = date
            objcommuteTime?.earliestArrivel = minDate as Date?
            objcommuteTime?.latestDeparture = minDate as Date?
            let dayName = dateFormatterForDayname.string(from: tempStartDate!)
            
            let variables = variables as NSDictionary
            var depMonThurs1 : String = (variables["MON_THURS_DEPART"] as? Int ?? -1) == -1 ? "" : "\(variables["MON_THURS_DEPART"] as! Int)"
            var returnMonThurs1 : String = (variables["MON_THURS_RETURN"] as? Int ?? 3000) == 3000 ? "" : "\(variables["MON_THURS_RETURN"] as! Int)"
            var depFriday1 : String = (variables["FRI_DEPART"] as? Int ?? -1) == -1 ? "" : "\(variables["FRI_DEPART"] as! Int)"
            var returnFriday1 : String = (variables["FRI_RETURN"] as? Int ?? 3000) == 3000 ? "" : "\(variables["FRI_RETURN"] as! Int)"
            var depSat1 : String = (variables["SAT_DEPART"] as? Int ?? -1) == -1 ? "" : "\(variables["SAT_DEPART"] as! Int)"
            var returnSat1 : String = (variables["SAT_RETURN"] as? Int ?? 3000) == 3000 ? "" : "\(variables["SAT_RETURN"] as! Int)"
            var depSun1 : String = (variables["SUN_DEPART"] as? Int ?? -1) == -1 ? "" : "\(variables["SUN_DEPART"] as! Int)"
            var returnSun1 : String = (variables["SUN_RETURN"] as? Int ?? 3000) == 3000 ? "" : "\(variables["SUN_RETURN"] as! Int)"
            
            depMonThurs1 = self.getCompleteTime(timeString: depMonThurs1)
            returnMonThurs1 = self.getCompleteTime(timeString: returnMonThurs1)
            depFriday1 = self.getCompleteTime(timeString: depFriday1)
            returnFriday1 = self.getCompleteTime(timeString: returnFriday1)
            depSat1 = self.getCompleteTime(timeString: depSat1)
            returnSat1 = self.getCompleteTime(timeString: returnSat1)
            depSun1 = self.getCompleteTime(timeString: depSun1)
            returnSun1 = self.getCompleteTime(timeString: returnSun1)
            
//            mon - thurs
            if depMonThurs1.length > 0 {
                if dayName == "Monday" || dayName == "Tuesday" || dayName == "Wednesday" || dayName == "Thursday" {
                    objcommuteTime?.earliestArrivel = addminutesWithDates(CurrentDate: tempStartDate!, Minutes: depMonThurs1)
                }
            }
            if returnMonThurs1.length > 0 {
                if dayName == "Monday" || dayName == "Tuesday" || dayName == "Wednesday" || dayName == "Thursday" {
                    objcommuteTime?.latestDeparture = addminutesWithDates(CurrentDate: tempStartDate!, Minutes: returnMonThurs1)
                }
            }
//            friday
            if depFriday1.length > 0 {
                if dayName == "Friday" {
                    objcommuteTime?.earliestArrivel = addminutesWithDates(CurrentDate: tempStartDate!, Minutes: depFriday1)
                }
            }
            if returnFriday1.length > 0 {
                if dayName == "Friday" {
                    objcommuteTime?.latestDeparture = addminutesWithDates(CurrentDate: tempStartDate!, Minutes: returnFriday1)
                }
            }
//            saturday
            if depSat1.length > 0 {
                if dayName == "Saturday" {
                    objcommuteTime?.earliestArrivel = addminutesWithDates(CurrentDate: tempStartDate!, Minutes: depSat1)
                }
            }
            if returnSat1.length > 0 {
                if dayName == "Saturday" {
                    objcommuteTime?.latestDeparture = addminutesWithDates(CurrentDate: tempStartDate!, Minutes: returnSat1)
                }
            }
//            sunday
            if depSun1.length > 0 {
                if dayName == "Sunday" {
                    objcommuteTime?.earliestArrivel = addminutesWithDates(CurrentDate: tempStartDate!, Minutes: depSun1)
                }
            }
            if returnSun1.length > 0 {
                if dayName == "Sunday" {
                    objcommuteTime?.latestDeparture = addminutesWithDates(CurrentDate: tempStartDate!, Minutes: returnSun1)
                }
            }
            objcommuteTime?.type = 0
            let tempdate = Calendar.current.date(byAdding: oneWeek, to: tempStartDate!)
            var cal = Calendar(identifier: .gregorian)
            cal.timeZone = TimeZone(secondsFromGMT: 0)!
            var comps: DateComponents = cal.dateComponents([.year, .month, .day], from: tempdate!)
            comps.hour = 0
            comps.minute = 0
            comps.second = 0
            tempStartDate = cal.date(from: comps)!
            
            if tempStartDate!.compare(endDate!) == .orderedSame {
                try? self.context.save()
                return true
            }
        }
        try? self.context.save()
        return false
    }
    
    func setCommuteTimeForDaysForManualSort(pRule: [String: Any]) -> Bool {
        let context = self.bidPeriod?.managedObjectContext
        let result = CBGlobalMethods.shared.selectedBidPeriod!.commuteTime?.allObjects
        for basket in result! {
            context?.delete(basket as! NSManagedObject)
        }
        let startDate = self.startOfMonth()
        let dateFormat = DateFormatter()
        var endDate = self.endOfMonth()
        let daysToAdd = 4
        endDate = endDate!.addingTimeInterval(TimeInterval(60 * 60 * 24 * daysToAdd))
        
        let minDateString = "01/01/0001 00:00:00"
        
        dateFormat.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormat.locale = Locale.current
        dateFormat.dateFormat = "MM/dd/yyyy hh:mm:ss"
        
        let minDate = dateFormat.date(from: minDateString)
        var oneWeek = DateComponents()
        oneWeek.day = 1
        oneWeek.hour = 1
        //
        var TempStartDate = startDate
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        
        let dateFormatterForDayname = DateFormatter()
        dateFormatterForDayname.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatterForDayname.dateFormat = "EEEE"

        while TempStartDate!.compare(endDate!) == .orderedAscending || TempStartDate!.compare(endDate!) == .orderedSame {
            //Set WorkBlock Details
            let CommuteEntity = NSEntityDescription.entity(forEntityName: "CommuteTime", in: (context!))
            var ObjcommuteTime: CommuteTime? = nil
            ObjcommuteTime = CommuteTime(entity: CommuteEntity!, insertInto: (bidPeriod?.managedObjectContext)!)
            ObjcommuteTime?.commutable = bidPeriod
            let date = formatter.string(from: TempStartDate!)
            ObjcommuteTime?.bidDay = TempStartDate as NSDate? as Date?
            ObjcommuteTime?.bidDayStringValue = date
            ObjcommuteTime?.earliestArrivel = minDate as Date?
            ObjcommuteTime?.latestDeparture = minDate as Date?
            let dayName = dateFormatterForDayname.string(from: TempStartDate!)
            
            let variables = pRule as NSDictionary
            var depMonThurs1 : String = (variables["MON_THURS_DEPART"] as? Int ?? -1) == -1 ? "" : "\(variables["MON_THURS_DEPART"] as! Int)"
            var returnMonThurs1 : String = (variables["MON_THURS_RETURN"] as? Int ?? 3000) == 3000 ? "" : "\(variables["MON_THURS_RETURN"] as! Int)"
            var depFriday1 : String = (variables["FRI_DEPART"] as? Int ?? -1) == -1 ? "" : "\(variables["FRI_DEPART"] as! Int)"
            var returnFriday1 : String = (variables["FRI_RETURN"] as? Int ?? 3000) == 3000 ? "" : "\(variables["FRI_RETURN"] as! Int)"
            var depSat1 : String = (variables["SAT_DEPART"] as? Int ?? -1) == -1 ? "" : "\(variables["SAT_DEPART"] as! Int)"
            var returnSat1 : String = (variables["SAT_RETURN"] as? Int ?? 3000) == 3000 ? "" : "\(variables["SAT_RETURN"] as! Int)"
            var depSun1 : String = (variables["SUN_DEPART"] as? Int ?? -1) == -1 ? "" : "\(variables["SUN_DEPART"] as! Int)"
            var returnSun1 : String = (variables["SUN_RETURN"] as? Int ?? 3000) == 3000 ? "" : "\(variables["SUN_RETURN"] as! Int)"
     
            depMonThurs1 = self.getCompleteTime(timeString: depMonThurs1)
            returnMonThurs1 = self.getCompleteTime(timeString: returnMonThurs1)
            depFriday1 = self.getCompleteTime(timeString: depFriday1)
            returnFriday1 = self.getCompleteTime(timeString: returnFriday1)
            depSat1 = self.getCompleteTime(timeString: depSat1)
            returnSat1 = self.getCompleteTime(timeString: returnSat1)
            depSun1 = self.getCompleteTime(timeString: depSun1)
            returnSun1 = self.getCompleteTime(timeString: returnSun1)
            
            
            
            if depMonThurs1.length > 0 {
                if dayName == "Monday" || dayName == "Tuesday" || dayName == "Wednesday" || dayName == "Thursday" {
                    ObjcommuteTime?.earliestArrivel = addMinuteWithDates(currentDate: TempStartDate!, Minutes: depMonThurs1)
                }
            }
            if returnMonThurs1.length > 0 {
                if dayName == "Monday" || dayName == "Tuesday" || dayName == "Wednesday" || dayName == "Thursday" {
                    ObjcommuteTime?.latestDeparture = self.addMinuteWithDates(currentDate: TempStartDate!, Minutes: returnMonThurs1)
                }
            }
            if depFriday1.length > 0 {
                if dayName == "Friday" {
                    ObjcommuteTime?.earliestArrivel = self.addMinuteWithDates(currentDate: TempStartDate!, Minutes: depFriday1)
                }
            }
            if returnFriday1.length > 0 {
                if dayName == "Friday" {
                    ObjcommuteTime?.latestDeparture = self.addMinuteWithDates(currentDate: TempStartDate!, Minutes: returnFriday1)
                }
            }
            if depSat1.length > 0 {
                if dayName == "Saturday" {
                    ObjcommuteTime?.earliestArrivel = self.addMinuteWithDates(currentDate: TempStartDate!, Minutes: depSat1)
                }
            }
            if returnSat1.length > 0 {
                if dayName == "Saturday" {
                    ObjcommuteTime?.latestDeparture = self.addMinuteWithDates(currentDate: TempStartDate!, Minutes: returnSat1)
                }
            }
            if depSun1.length > 0 {
                if dayName == "Sunday" {
                    ObjcommuteTime?.earliestArrivel = self.addMinuteWithDates(currentDate: TempStartDate!, Minutes: depSun1)
                }
            }
            if returnSun1.length > 0 {
                if dayName == "Sunday" {
                    ObjcommuteTime?.latestDeparture = self.addMinuteWithDates(currentDate: TempStartDate!, Minutes: returnSun1)
                }
            }
            
            ObjcommuteTime?.type = 0
            let tempdate = Calendar.current.date(byAdding: oneWeek, to: TempStartDate!)
            var cal = Calendar(identifier: .gregorian)
            cal.timeZone = TimeZone(secondsFromGMT: 0)!
            var comps: DateComponents = cal.dateComponents([.year, .month, .day], from: tempdate!)
            comps.hour = 0
            comps.minute = 0
            comps.second = 0
            TempStartDate = cal.date(from: comps)!
            
            
            if TempStartDate!.compare(endDate!) == .orderedSame {
                try? self.context.save()
                return true
            }
        }
        try? self.context.save()
        return false
    }
    
    
    func startOfMonth() -> Date? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale.current
        if let aName = TimeZone(secondsFromGMT: 0) {
            calendar.timeZone = aName as TimeZone
        }
        var day: NSNumber?
        var month: NSNumber?
        var year: NSNumber?
        var components = DateComponents()
        if (bidPeriod?.isFABid() == true) && (bidPeriod?.month?.intValue == 2) {
            
            day = 31
            month = 1
            year = bidPeriod?.year
        } else if (bidPeriod!.isFABid() == true) && (bidPeriod?.month?.intValue == 3) {
            day = 2
            month = bidPeriod?.month
            year = bidPeriod?.year
        } else {
            day = 1
            month = bidPeriod?.month
            year = bidPeriod?.year
        }
        components.day = Int(truncating: day ?? 0)
        components.month = Int(truncating: month ?? 0)
        components.year = Int(truncating: year ?? 0)
        components.minute = 0
        components.hour = 0
        components.second = 0
        
        return calendar.date(from: components)
    }
    
    func endOfMonth() -> Date? {
        var daysToAdd: Int = 1
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale.current
        if let aName = TimeZone(secondsFromGMT: 0) {
            calendar.timeZone = aName as TimeZone
        }
        var components = DateComponents()
        let day = 1
        let month = bidPeriod?.month
        let year = bidPeriod?.year
        components.day = day
        components.month = month as? Int
        components.year = year as? Int
        components.minute = 0
        components.hour = 0
        components.second = 0
        
        
        var dateComponents = DateComponents()
        dateComponents.month = 1
        dateComponents.day = -1
        
        var lastDayOfMonth: Date? = nil
        lastDayOfMonth = calendar.date(byAdding: dateComponents, to: calendar.date(from: components)!)
        
        //in case of februaury month for FA the last date should be march 1.
        if (bidPeriod!.isFABid() == true) && bidPeriod?.month == 2 {
            
            lastDayOfMonth = lastDayOfMonth?.addingTimeInterval(TimeInterval(60 * 60 * 24 * daysToAdd))
            return lastDayOfMonth
        } else if (bidPeriod!.isFABid() == true) && bidPeriod?.month?.intValue == 1 {
            daysToAdd = -1
            lastDayOfMonth = lastDayOfMonth?.addingTimeInterval(TimeInterval(daysToAdd * 24 * 60 * 60))
            return lastDayOfMonth
        }
        else {
            return lastDayOfMonth
        }
    }
    
    func addminutesWithDates(CurrentDate: Date, Minutes mns: String) -> Date {
        var temp = ""
        if mns.count == 4 {
            temp = mns
        } else if mns.count == 3 {
            temp = "0" + mns
        }else if mns.count == 2 {
            temp = "00" + mns
        }else if mns.count == 1 {
            temp = "000" + mns
        }else{
            temp = "0000"
        }
        var hours = Int(temp.substring(to: 2))!
        let mins = Int(temp.substring(with: 2..<2))!
        hours = (hours * 60) + mins;
        let ModifiedDate = CurrentDate.addingTimeInterval(TimeInterval(hours * 60))
        return ModifiedDate
    }
    
    func getCompleteTime(timeString: String) -> String {
        if timeString == "-1" || timeString == "3000"{
            return ""
        }
        var timeStr = timeString
        while timeStr.length < 4 {
            timeStr = "0\(timeStr)"
        }
        return timeStr
    }
    
    func addMinuteWithDates(currentDate: Date, Minutes mns: String) -> Date {
        var temp = ""
        if mns.count == 4 {
            temp = mns
        }
        else if mns.count == 3 {
            temp = "0\(mns)"
        }
        else if mns.count == 2 {
            temp = "00\(mns)"
        }
        else if mns.count == 1 {
            temp = "000\(mns)"
        }
        else {
            temp = "0000"
        }
        var hours = Int(temp.substring(to: 2))!
        let mins = Int(temp.substring(with: 2..<2))!
        hours = (hours * 60) + mins
        let modifiedDate = currentDate.addingTimeInterval(TimeInterval(hours * 60))
        return modifiedDate
    }
    
}

//CBFilterRulesTableVC
//CBLineSortsTVC

