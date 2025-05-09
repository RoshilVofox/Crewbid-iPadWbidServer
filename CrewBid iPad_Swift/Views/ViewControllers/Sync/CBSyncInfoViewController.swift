

import UIKit

enum GRCheckButtonType: Int {
    case cbState
    case preset
    case both
}

class CBSyncInfoViewController: UIViewController {

    @IBOutlet weak var btnBoth: UIButton!
    @IBOutlet weak var btnPreset: UIButton!
    @IBOutlet weak var btnState: UIButton!
    
    var checkedType: GRCheckButtonType!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()

    }
    
    func setupUI() {
        let image = UIImage(named: "RadioButton-On") as UIImage?
        btnState.setImage(image, for: .normal)
        btnState.isSelected = true
        checkedType = GRCheckButtonType.cbState
    }
    
    @IBAction func btnOkAction(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Sync", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBsyncConflictViewController") as! CBsyncConflictViewController
        vc.selectedType = checkedType!
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func btnCancelAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func btnStateAction(_ sender: Any) {
        checkedType = GRCheckButtonType.cbState
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
}
