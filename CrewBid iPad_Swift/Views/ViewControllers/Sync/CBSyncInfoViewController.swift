

import UIKit
import CoreData

enum GRCheckButtonType: Int {
    case cbState
    case preset
    case both
}

class CBSyncInfoViewController: UIViewController {

    @IBOutlet weak var btnBoth: UIButton!
    @IBOutlet weak var btnPreset: UIButton!
    @IBOutlet weak var btnState: UIButton!
    var fileType = 0
    var bidPeriod: BIBidPeriod?
    var objDatabuilder = ODataBuilder()
    let context = CBGlobalMethods.shared.selectedBidPeriod!.managedObjectContext!
    var syncPrest: PresetSync?
    var linesManager: BILinesManager?
    
    var checkedType: GRCheckButtonType!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        linesManager = BILinesManager.init(managedObjectContext: self.context)!

    }
    
    func setupUI() {
        let image = UIImage(named: "RadioButton-On") as UIImage?
        btnState.setImage(image, for: .normal)
        btnState.isSelected = true
        checkedType = GRCheckButtonType.cbState
        fileType = 0
    }
    
    @IBAction func btnCancelAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func btnStateAction(_ sender: Any) {
        checkedType = GRCheckButtonType.cbState
        fileType = 0
        if checkedType == GRCheckButtonType.cbState {
            (sender as AnyObject).setImage(UIImage(named: "RadioButton-On"), for: .normal)
            btnState.isSelected = true
            btnPreset.isSelected = false
            btnBoth.isSelected = false
            let image = UIImage(named: "radioButton-Off") as UIImage?
            btnPreset.setImage(image, for: .normal)
            btnBoth.setImage(image, for: .normal)
        }else{
            (sender as AnyObject).setImage(UIImage(named: "radioButton-Off"), for: .normal)
        }
    }
    
    @IBAction func btnPresetAction(_ sender: Any) {
        checkedType = GRCheckButtonType.preset
        fileType = 1
        if checkedType == GRCheckButtonType.preset{
            (sender as AnyObject).setImage(UIImage(named: "RadioButton-On"), for: .normal)
            btnPreset.isSelected = true
            btnState.isSelected = false
            btnBoth.isSelected = false
            let image = UIImage(named: "radioButton-Off") as UIImage?
            btnState.setImage(image, for: .normal)
            btnBoth.setImage(image, for: .normal)
        }else{
            (sender as AnyObject).setImage(UIImage(named: "radioButton-Off"), for: .normal)
        }
    }
    
    @IBAction func btnBothAction(_ sender: Any) {
        checkedType = GRCheckButtonType.both
        fileType = 2
        if checkedType == GRCheckButtonType.both{
            (sender as AnyObject).setImage(UIImage(named: "RadioButton-On"), for: .normal)
            btnBoth.isSelected = true
            btnState.isSelected = false
            btnPreset.isSelected = false
            let image = UIImage(named: "radioButton-Off") as UIImage?
            btnState.setImage(image, for: .normal)
            btnPreset.setImage(image, for: .normal)
        }else{
            (sender as AnyObject).setImage(UIImage(named: "radioButton-Off"), for: .normal)
        }
    }
    
    @IBAction func btnOkAction(_ sender: Any) {
        let app = UIApplication.shared.delegate as! AppDelegate
        var dicDetails: [String: Any] = [String: Any]()
        dicDetails["Employeeumber"] = Int(app.ObjUserAccount!.employeeNumber)
        if fileType == 0 {
            checkedType = GRCheckButtonType.cbState
            dicDetails["StateName"] = self.bidFilenameForState()
            dicDetails["PresetFileName"] = NSNull()

        }
        else if fileType == 1 {
            checkedType = GRCheckButtonType.preset
            dicDetails["PresetFileName"] = NSNumber(value: Int(app.ObjUserAccount!.employeeNumber)!)
            dicDetails["StateName"] = NSNull()
        }
        else {
            checkedType = GRCheckButtonType.both
            dicDetails["StateName"] = self.bidFilenameForState()
            dicDetails["PresetFileName"] = NSNumber(value: Int(app.ObjUserAccount!.employeeNumber)!)
        }
        dicDetails["Year"] = self.bidPeriod!.year!
        dicDetails["FileType"] = fileType
        objDatabuilder.getSyncVersionNumber(dictDetails: dicDetails) { result in
            if let dataArray = result {
                self.sericeResponse(arrResponse: dataArray)
            } else {
                print("Failed to fetch or parse data")
            }
        }
    }
    
    func bidFilenameForState() -> String {
        var bidRoundChar = "M"
        if self.bidPeriod!.isSecondRoundBid() {
            bidRoundChar = "W"
        }
        var dateString = "\(bidPeriod!.year!)"
        let twoDigitDate = String(dateString.suffix(2))
        let positionInt = self.bidPeriod!.positionType!.intValue
        let position = BICrewPositionType(rawValue: positionInt)
        let positionShortString = CBUtils.shortName(for: position!)
        let bidDataFilename = String(format: "CB%@%@%02ld%@%@", self.bidPeriod!.base!, positionShortString, self.bidPeriod!.month!.intValue, twoDigitDate, bidRoundChar)
        return bidDataFilename
    }
    
    func sericeResponse(arrResponse: [[String: Any]]) {
        if arrResponse.count > 0 {
            let first = arrResponse[0]
            var nilresponse = false
            if checkedType == .cbState {
                let localSyncVersion = self.bidPeriod!.stateSyncVersion?.intValue
                let serverSyncVersionNumber = first["StateVersionNumber"] as? Int
                nilresponse = (serverSyncVersionNumber == nil) && (localSyncVersion == nil) ? true : false
                if ((localSyncVersion == serverSyncVersionNumber) && (self.bidPeriod?.isStateFileModifiedToSync?.intValue == 0) && !nilresponse) {
                    AlertService.showAlertForTopVC(title: "Smart Sync", message: "Your App is already synchronized with the server ")
                }
                else {
                    self.displaySyncConflictView(arrResponse: arrResponse)
                }
            }
            else if checkedType == .preset {
                let fetchRequest: NSFetchRequest<PresetSync> = PresetSync.fetchRequest()
                let results = try? self.context.fetch(fetchRequest)
                if results?.count ?? 0 > 0 {
                    syncPrest = results![0]
                }
                let localPresetVersionNumber = syncPrest?.presetSyncVersion?.intValue
                let serverPrestVersionNumber = first["PresetVersionNumber"] as? Int
                nilresponse = (localPresetVersionNumber == nil) && (serverPrestVersionNumber == nil) ? true : false
                
                if localPresetVersionNumber == serverPrestVersionNumber && UserDefaults.standard.bool(forKey: kCBIsPresetModified) == true && !nilresponse {
                    AlertService.showAlertForTopVC(title: "Smart Sync", message: "Your App is already synchronized with the server ")
                }
                else {
                    self.displaySyncConflictView(arrResponse: arrResponse)
                }
            }
            else if checkedType == .both {
                let localSyncVersion = self.bidPeriod!.stateSyncVersion?.intValue
                let serverSyncVersionNumber = first["StateVersionNumber"] as? Int
                
                let fetchRequest: NSFetchRequest<PresetSync> = PresetSync.fetchRequest()
                let results = try? self.context.fetch(fetchRequest)
                if results?.count ?? 0 > 0 {
                    syncPrest = results![0]
                }
                let localPresetVersionNumber = syncPrest?.presetSyncVersion?.intValue
                let serverPrestVersionNumber = first["PresetVersionNumber"] as? Int
                nilresponse = (localPresetVersionNumber == nil) && (serverPrestVersionNumber == nil) ? true : false
                if localPresetVersionNumber == serverPrestVersionNumber && UserDefaults.standard.bool(forKey: kCBIsPresetModified) == true && !nilresponse {
                    AlertService.showAlertForTopVC(title: "Smart Sync", message: "Your App is already synchronized with the server ")
                }
                else {
                    self.displaySyncConflictView(arrResponse: arrResponse)
                }
            }
            else {
                self.displaySyncConflictView(arrResponse: arrResponse)
            }
        }
    }
    
    func displaySyncConflictView(arrResponse: [[String: Any]]) {
        DispatchQueue.main.async {
            let storyboard = UIStoryboard(name: "Sync", bundle: nil)
            guard let vc = storyboard.instantiateViewController(withIdentifier: "CBsyncConflictViewController") as? CBsyncConflictViewController else { return }
            
            vc.selectedType = self.checkedType!
            vc.arrResponceDetails = arrResponse
            vc.bidPeriod = self.bidPeriod
            vc.fileType = self.fileType
            vc.linesManager = self.linesManager
            
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

}
