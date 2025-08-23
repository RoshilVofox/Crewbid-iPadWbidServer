
import UIKit

class CBHelpMenuController: UIViewController {

    @IBOutlet weak var containerView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        containerView.layer.borderColor = UIColor.black.cgColor
        containerView.layer.borderWidth = 1
        containerView.layer.cornerRadius = 5
        containerView.layer.masksToBounds = false
        // Do any additional setup after loading the view.
    }
    

}
