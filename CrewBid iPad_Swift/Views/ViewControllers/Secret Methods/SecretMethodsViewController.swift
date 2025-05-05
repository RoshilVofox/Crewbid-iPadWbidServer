
//

import UIKit

class SecretMethodsViewController: UIViewController {
    
    @IBOutlet weak var qaTestSegment: UISegmentedControl!
    
    @IBOutlet weak var closeBtn: UIButton!
    @IBOutlet weak var mockDataSegment: UISegmentedControl!
    
    @IBOutlet weak var secretVacationSegment: UISegmentedControl!
    
    @IBOutlet weak var secretAwsrdSegment: UISegmentedControl!
    
    

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
    }
    

    func setupUI() {
        qaTestSegment.selectedSegmentIndex = 1
        mockDataSegment.selectedSegmentIndex = 1
        secretVacationSegment.selectedSegmentIndex = 1
        secretAwsrdSegment.selectedSegmentIndex = 1
        closeBtn.setTitle("", for: .normal)
    }
    
    @IBAction func closeBtnAction(_ sender: Any) {
        self.dismiss(animated: true)
    }
    @IBAction func btnDonloadDomicileAction(_ sender: Any) {
        if let presentingVC = self.presentingViewController {
            self.dismiss(animated: true) {
                let storyboard = UIStoryboard(name: "Secret", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "CBDownloadAlldomicileViewController") as! CBDownloadAlldomicileViewController
                vc.preferredContentSize = CGSize(width: 700, height: 600)
                presentingVC.present(vc, animated: true)
            }
        }
    }
}
