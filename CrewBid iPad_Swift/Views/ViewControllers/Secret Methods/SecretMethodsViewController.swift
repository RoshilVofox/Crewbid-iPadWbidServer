
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
        let isQATest = UserDefaults.standard.bool(forKey: "isQATest")
            qaTestSegment.selectedSegmentIndex = isQATest ? 0 : 1
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
                vc.isModalInPresentation = true 
                let navController = UINavigationController(rootViewController: vc)
                navController.setNavigationBarHidden(true, animated: false)
                presentingVC.present(navController, animated: true)
            }
        }
    }
    
    @IBAction func qaTestSegmentAction(_ sender: Any) {
        guard let segmentedControl = sender as? UISegmentedControl else { return }
           
           let selectedIndex = segmentedControl.selectedSegmentIndex
           if selectedIndex == 0 {
               alertinQASegment()
           } else if selectedIndex == 1 {
               UserDefaults.standard.setValue(false, forKey: "isQATest")
           }
    }
    
    func alertinQASegment() {
        let alert = UIAlertController(title: "QA Mode", message: "Please enter QA Month and Year", preferredStyle: .alert)

        // Text field for month
        alert.addTextField { textField in
            textField.placeholder = "Enter QA Month"
            textField.keyboardType = .numberPad
        }

        // Text field for year
        alert.addTextField { textField in
            textField.placeholder = "Enter QA Year"
            textField.keyboardType = .numberPad
        }

        // OK action
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            let qaMonth = alert.textFields?[0].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let qaYear = alert.textFields?[1].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            let monthInt = Int(qaMonth)
            let yearInt = Int(qaYear)

            let isValidMonth = monthInt != nil && (1...12).contains(monthInt!)
            let isValidYear = qaYear.count == 4 && yearInt != nil

            if isValidMonth && isValidYear {
                // Store in UserDefaults
                UserDefaults.standard.setValue(qaMonth, forKey: "QATestMonth")
                UserDefaults.standard.setValue(qaYear, forKey: "QATestYear")
                UserDefaults.standard.setValue(true, forKey: "isQATest")
                print("Saved QA Month: \(qaMonth), QA Year: \(qaYear)")
            } else {
                // Re-present the same alert with an error message
                let errorAlert = UIAlertController(title: "Invalid Input", message: "Month must be 1–12 and Year must be a 4-digit number.", preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                    // Re-open the input alert on error
                    self.alertinQASegment()
                })
                self.present(errorAlert, animated: true)
            }
        }

        alert.addAction(okAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            self.qaTestSegment.selectedSegmentIndex = 1
            UserDefaults.standard.setValue(false, forKey: "isQATest")
        })

        self.present(alert, animated: true)
    }

}
