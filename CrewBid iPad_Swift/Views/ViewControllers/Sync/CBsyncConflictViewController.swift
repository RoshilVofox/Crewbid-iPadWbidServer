

import UIKit

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
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        setupUI()

    }
    
    func setupUI() {
        if selectedType == GRCheckButtonType.both {
            viewState.isHidden = false
            viewPreset.isHidden = false
        }
        if selectedType == GRCheckButtonType.cbState {
            viewPreset.isHidden = true
            
        }
        if selectedType == GRCheckButtonType.preset {
            viewState.isHidden = true
        }
    }

    @IBAction func btnSyncDataAction(_ sender: Any) {
    }
}
