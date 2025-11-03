

import UIKit
import CoreData

class CBsyncConflictViewController: UIViewController {
    
    @IBOutlet weak var lblStateLocalDate: UILabel!
    @IBOutlet weak var lblStateServerDate: UILabel!
    @IBOutlet weak var lblStateLocalTime: UILabel!
    @IBOutlet weak var lblStateServerTime: UILabel!
    @IBOutlet weak var stateSegment: UISegmentedControl!
    
    @IBOutlet weak var lblPresetLocalDate: UILabel!
    @IBOutlet weak var lblPresetServerDate: UILabel!
    @IBOutlet weak var lblPresetLocalTime: UILabel!
    @IBOutlet weak var lblPresetServerTime: UILabel!
    @IBOutlet weak var presetSegment: UISegmentedControl!
    
    @IBOutlet weak var viewState: UIView!
    @IBOutlet weak var viewPreset: UIView!
    
    var selectedType: GRCheckButtonType!
    var arrResponceDetails: [[String: Any]]?
    var bidPeriod: BIBidPeriod?
    var fileType = 0
    var linesManager: BILinesManager?
    var objdatabuilder = ODataBuilder()
    var objCoredataSync = CBCoreDataSync()
    var syncType: UserSyncType?
    let context = CBGlobalMethods.shared.selectedBidPeriod!.managedObjectContext!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        setupUI()

    }
    
    func setupUI() {
        if fileType == 2 {
            viewState.isHidden = false
            viewPreset.isHidden = false
        }
        if fileType == 0 {
            viewPreset.isHidden = true
            
        }
        if fileType == 1 {
            viewState.isHidden = true
        }
        
        // Fetch and display time data
       timeDataFetch()
    }
    
    func timeDataFetch() {
        let arrayDictRecived = arrResponceDetails![0]
        // Define a minimum date string
        let minDateString = "1/1/0001 6:00:00 AM"
        // Fetch StateLastUpdatedDate from arrayDictRecived
        let val = arrayDictRecived["StateLastUpdatedDate"] as? String
        // Check if StateLastUpdatedDate is not NSNull and equal to minDateString
        if !(arrayDictRecived["StateLastUpdatedDate"] is NSNull) && minDateString == val {
            stateSegment.selectedSegmentIndex = 0
            stateSegment.isUserInteractionEnabled = false
            stateSegment.setWidth(0.1, forSegmentAt: 1)
            stateSegment.setEnabled(false, forSegmentAt: 1)
        }
        
        //Date and Time from local for preset
        let dateFormatter = DateFormatter()
        dateFormatter.locale = .current
        dateFormatter.dateFormat = "MM/dd/yyyy"
        
        // TODO: - Need to handle current date
        var presetLocaldateString =  "--/--/--"
        dateFormatter.dateFormat = "hh:mm:ss a"
        var presteLocalTimeString =  "--/--/--"
        dateFormatter.string(from: self.bidPeriod!.currentDateTime ?? Date())
        if let time = self.bidPeriod!.currentDateTime {
            dateFormatter.dateFormat = "MM/dd/yyyy"
            presetLocaldateString = dateFormatter.string(from: time)
            dateFormatter.dateFormat = "hh:mm:ss a"
            presteLocalTimeString = dateFormatter.string(from: time)
        }
        
        //Date and Time from server for preset
        var presetServerDateString = ""
        var presetServerTimeString = ""
        
        if let presetValue = arrayDictRecived["PresetLastUpdated"] {
            if !(presetValue is NSNull) {
                let serverDateTime = self.getDateFromJSON(presetValue as! String)
                
                let dateFormatter = DateFormatter()
                dateFormatter.locale = Locale.current
                dateFormatter.timeZone = TimeZone.current
                dateFormatter.dateFormat = "MM/dd/yyyy"
                presetServerDateString = dateFormatter.string(from: serverDateTime!)
                dateFormatter.dateFormat = "hh:mm:ss a"
                presetServerTimeString = dateFormatter.string(from: serverDateTime!)
            }
        }
        
        lblPresetLocalDate.text = presetLocaldateString
        lblPresetLocalTime.text = presteLocalTimeString
        lblPresetServerDate.text = "--/--/--"
        lblPresetServerTime.text = "--:--:--"
        
        if let val = arrayDictRecived["PresetLastUpdated"] {
            if !(val is NSNull) && minDateString != val as! String {
                lblPresetServerDate.text = presetServerDateString
                lblPresetServerTime.text = presetServerTimeString
            }
        }
        
        //Date and Time from local for state
        dateFormatter.locale = .current
        dateFormatter.dateFormat = "MM/dd/yyyy"
        // TODO: - Need to handle current date
        
        let stateLocaldateString = dateFormatter.string(from: self.bidPeriod!.currentDateTime ?? Date())
        dateFormatter.dateFormat = "hh:mm:ss a"
        let stateLocalTimeString = dateFormatter.string(from: self.bidPeriod!.currentDateTime ?? Date())
        
        //Date and Time from server for state
        var stateServerDateString = ""
        var stateServerTimeString = ""
        
        if let stateValue = arrayDictRecived["StateLastUpdate"] {
            if !(stateValue is NSNull) {
                stateServerDateString = self.getLocalDateFrom(dateString: stateValue as! String, fromFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS", toFormat: "MM/dd/yyyy")
                stateServerTimeString = self.getLocalDateFrom(dateString: stateValue as! String, fromFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS", toFormat: "hh:mm:ss a")
                lblStateServerDate.text = stateServerDateString
                lblStateServerTime.text = stateServerTimeString
            }
        }
        lblStateLocalDate.text = stateLocaldateString
        lblStateLocalTime.text = stateLocalTimeString
        if !(arrayDictRecived["StateLastUpdate"] is NSNull) && minDateString != arrayDictRecived["StateLastUpdate"] as! String {
            lblStateServerDate.text = stateServerDateString
            lblStateServerTime.text = stateServerTimeString
        }
        else{
            lblStateServerDate.text = "--/--/--"
            lblStateServerTime.text = "--:--:--"
        }
    }
    
    // Converts a GMT date string from one format to another in the local time zone.
    private func getLocalDateFrom(dateString: String, fromFormat: String, toFormat: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = fromFormat
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        guard let date = dateFormatter.date(from: dateString) else {
            print("Invalid timestamp format")
           return ""
        }
        
        let dateFormat1 = DateFormatter()
        dateFormat1.locale = Locale.current
        dateFormat1.timeZone = TimeZone.current
        dateFormat1.dateFormat = toFormat
        let serverDateString = dateFormat1.string(from: date)
        return serverDateString
    }

    @IBAction func btnSyncDataAction(_ sender: Any) {
        CBGlobalMethods.shared.showCustomActivityIndicator(message: "Fetching Data", bgcolor: .purple, height: 100)
        let app = UIApplication.shared.delegate as! AppDelegate
        if app.connectedToInternet() {
            objCoredataSync.managedObjectContext = self.bidPeriod!.managedObjectContext!
            objCoredataSync.bidPeriod = self.bidPeriod!
            
            let jsonSyncVC = CBJSONSyncParsing()
            jsonSyncVC.bidPeriod = bidPeriod
            jsonSyncVC.lineManger = linesManager
            jsonSyncVC.arrayDictRecived = self.arrResponceDetails
            jsonSyncVC.initcalendarData()
            
            if presetSegment.selectedSegmentIndex == 0 && viewState.isHidden == true {
                self.checkPresetIsEmpty()
                jsonSyncVC.syncType = .presetLocal
                syncType = .presetLocal
                jsonSyncVC.presetKeepLocal()
            }
            else if presetSegment.selectedSegmentIndex == 1 && viewState.isHidden == true {
                jsonSyncVC.syncType = .presetServer
                syncType = .presetServer
                jsonSyncVC.presetTakeServer() { response in
                    DispatchQueue.main.async {
                        self.saveSyncDataToLocalFromResponse(response ?? []) { success in
                            if success{
                                jsonSyncVC.presetKeepLocal()
                            }
                        }
                    }
                }
                
            }
            else if stateSegment.selectedSegmentIndex == 0 && viewPreset.isHidden == true {
                syncType = .stateLocal
                jsonSyncVC.syncType = .stateLocal
                jsonSyncVC.stateKeepLocal()
            }
            else if stateSegment.selectedSegmentIndex == 1 && viewPreset.isHidden == true {
                syncType = .stateServer
                jsonSyncVC.syncType = .stateServer
                jsonSyncVC.stateTakeServerWithCompletion() {response in
                    DispatchQueue.main.async {
                        self.saveSyncDataToLocalFromResponse(response ?? []) { success in
                            if success {
                                jsonSyncVC.stateKeepLocal()
                            }
                        }
                    }
                }
            }
//            unfinished 686
        }
        else {
            DispatchQueue.main.async {
                CBGlobalMethods.shared.hideCustomActivityIndicator()
                AlertService.showAlertForTopVC(title: "Network not available!!", message: "Please check your internet connection ")
            }
        }
    }
    
    func checkPresetIsEmpty() {
        let presetTVC = CBPresetsTVC()
        let arr = presetTVC.openPresetsFromFileWithBidPeriod(bidPeriod: self.bidPeriod!)
        if arr.count == 0 {
            AlertService.showAlertForTopVC(title: "Crewbid", message: "You have NO Presets to Sync")
            return
        }
    }
    
    func getDateFromJSON(_ string: String?) -> Date? {
        guard let string = string, string.count > 1 else { return nil }
        
        // .NET JSON Date pattern: /Date(1234567890000+0530)/
        let pattern = #"^/Date\((-?\d+)(?:([+-])(\d{2})(\d{2}))?\)/$"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        
        let range = NSRange(location: 0, length: string.utf16.count)
        guard let match = regex.firstMatch(in: string, options: [], range: range) else {
            return nil
        }
        
        // Extract milliseconds
        guard let msRange = Range(match.range(at: 1), in: string),
              let msValue = Double(String(string[msRange])) else {
            return nil
        }
        var seconds = msValue / 1000.0
        
        // Handle timezone offset if present
        if match.range(at: 2).location != NSNotFound,
           let signRange = Range(match.range(at: 2), in: string),
           let hourRange = Range(match.range(at: 3), in: string),
           let minuteRange = Range(match.range(at: 4), in: string) {
            
            let sign = String(string[signRange])
            let hours = Double(String(string[hourRange])) ?? 0
            let minutes = Double(String(string[minuteRange])) ?? 0
            
            let offsetSeconds = (hours * 3600) + (minutes * 60)
            if sign == "+" {
                seconds -= offsetSeconds
            } else {
                seconds += offsetSeconds
            }
        }
        
        return Date(timeIntervalSince1970: seconds)
    }

    func saveSyncDataToLocalFromResponse(_ arrResponse: [[String: Any]], completionHandler: @escaping (Bool) -> Void) {
        guard let app = UIApplication.shared.delegate as? AppDelegate else {
            completionHandler(false)
            return
        }

        if syncType == .stateServer {
            if let dataBytes = arrResponse.first?["OldStateContent"] as? [Any] {
//                saveStateFilesToDirectory(dataBytes)
            }
            bidPeriod?.isStateFileModifiedToSync = false

        } else if syncType == .presetServer {
            if let dataBytes = arrResponse.first?["OldPresetContent"] as? [Any] {
                savePresetFileToDirectory(dataBytes)
            }
        }

        DispatchQueue.main.async {
            completionHandler(true)
        }
    }

//    func saveStateFilesToDirectory(_ dataBytes: [Any]) {
//        guard !dataBytes.isEmpty else {
//            return
//        }
//
//        let count = dataBytes.count
//        var bytes = [UInt8](repeating: 0, count: count)
//
//        for (index, element) in dataBytes.enumerated() {
//            if let str = element as? String, let byte = UInt8(str) {
//                bytes[index] = byte
//            }
//        }
//
//        let tempData = Data(bytes)
//
//        guard let stateDirectoryURL = CBCoreDataSync.syncDocumentDirectory(),
//              let stateFilename = CBCoreDataSync.syncFilename(withBidPeriod: bidPeriod)
//        else {
//            return
//        }
//
//        let dataWriteURL = stateDirectoryURL.appendingPathComponent(stateFilename)
//        let fileManager = FileManager.default
//
//        do {
//            if fileManager.fileExists(atPath: dataWriteURL.path) {
//                print("File exists — removing old file")
//                try fileManager.removeItem(at: dataWriteURL)
//            }
//
//            try tempData.write(to: dataWriteURL)
//            print("State file write success")
//
//            objCoredataSync.fetchStatePlistForSync { completedFetching in
//                if completedFetching {
//                    self.syncSuccessAlertDisplay()
//                } else {
//                    CBGlobalMethods.shared.hideCustomActivityIndicator()
//                    self.dismiss(animated: true, completion: nil)
//                }
//            }
//
//        } catch {
//            print("Error writing state file: \(error)")
//        }
//    }

    func savePresetFileToDirectory(_ dataBytes: [Any]) {
        // Validate input
        guard !dataBytes.isEmpty else { return }

        // Convert string bytes to UInt8 array
        var bytes = [UInt8](repeating: 0, count: dataBytes.count)
        for (index, element) in dataBytes.enumerated() {
            if let str = element as? String, let byte = UInt8(str) {
                bytes[index] = byte
            }
        }

        let tempData = Data(bytes)

        // Get destination URL
        let presetsDirectoryURL = CBPresetsTVC().presetsDocumentDirectory()
        let presetsFilename = CBPresetsTVC().presetsFilenameWithBidPeriod(bidPeriod: bidPeriod!)
        let dataWriteURL = presetsDirectoryURL!.appendingPathComponent(presetsFilename)
        let fileManager = FileManager.default
        
        do {
            // Remove old file if exists
            if fileManager.fileExists(atPath: dataWriteURL.path) {
                print("File exists — removing old preset file")
                try fileManager.removeItem(at: dataWriteURL)
            }

            // Write new data
            try tempData.write(to: dataWriteURL)
            print("Preset file write success")

            // Update user defaults
            UserDefaults.standard.set(false, forKey: kCBIsPresetModified)

            // Notify success
            syncSuccessAlertDisplay()

        } catch {
            print("Error writing preset file: \(error)")
        }
    }
    
    func syncSuccessAlertDisplay() {
        self.refreshLines()
        NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
        self.bidPeriod?.isStateFileModifiedToSync = false
        UserDefaults.standard.set(false, forKey: kCBIsPresetModified)
        if (syncType == .presetServer || syncType == .stateKeepLocalAndPresetTakeServer || syncType == .stateTakeServerAndPresetTakeServer || syncType == .presetConversion) {
            perform(#selector(presetsTableRefresh), with: nil, afterDelay: 0.5)
        }
    }

    func refreshLines() {
       let fetchRequest: NSFetchRequest<BILine> = BILine.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "bidOrder", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "bidOrder > 0")
        let result = try? self.context.fetch(fetchRequest)
        self.bidPeriod?.bidListLineCount = result?.count as NSNumber? ?? 0
    }
    
    @objc func presetsTableRefresh() {
        NotificationCenter.default.post(name: NSNotification.Name(kCBPresetSyncReload), object: self)
    }
}
