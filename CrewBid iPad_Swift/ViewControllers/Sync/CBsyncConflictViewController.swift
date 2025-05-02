

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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    @IBAction func btnSyncDataAction(_ sender: Any) {
    }
    

}
