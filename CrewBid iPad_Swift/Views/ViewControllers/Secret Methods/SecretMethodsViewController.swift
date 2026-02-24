
//

import UIKit

class SecretMethodsViewController: UIViewController {
    
    @IBOutlet weak var qaTestSegment: UISegmentedControl!
    @IBOutlet weak var closeBtn: UIButton!
    @IBOutlet weak var mockDataSegment: UISegmentedControl!
    @IBOutlet weak var secretVacationSegment: UISegmentedControl!
    @IBOutlet weak var secretAwardSegment: UISegmentedControl!
    @IBOutlet weak var envSegment: UISegmentedControl!
    @IBOutlet weak var envLbl: UILabel!
    @IBOutlet weak var txtSecretUser: UITextField!
    
    @IBOutlet weak var secretStack1: UIStackView!
    @IBOutlet weak var secretStack2: UIStackView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        let tap = UITapGestureRecognizer(target: self, action: #selector(qaSegmentTapped(_:)))
        tap.cancelsTouchesInView = false
        qaTestSegment.addGestureRecognizer(tap)
    }
    
    func setupUI() {
        let isQATest = UserDefaults.standard.bool(forKey: "isQATest")
            qaTestSegment.selectedSegmentIndex = isQATest ? 0 : 1
        mockDataSegment.selectedSegmentIndex = 1
        secretVacationSegment.selectedSegmentIndex = 1
        secretAwardSegment.selectedSegmentIndex = 1
        closeBtn.setTitle("", for: .normal)
        
        let env = UserDefaults.standard.string(forKey: "SwaApiEnv") ?? "Prod"
        switch env {
        case "Prod":
            envSegment.selectedSegmentIndex = 0
        case "QA":
            envSegment.selectedSegmentIndex = 1
        case "Dev":
            envSegment.selectedSegmentIndex = 2
        default:
            envSegment.selectedSegmentIndex = 0
        }
        
        if let secretID = UserDefaults.standard.string(forKey: "SecretVDuserName"), !secretID.isEmpty{
            self.txtSecretUser.text = secretID
            secretAwardSegment.selectedSegmentIndex = 0
        }else{
            secretAwardSegment.selectedSegmentIndex = 1
        }
        
        if secretAwardSegment.selectedSegmentIndex == 0{
            self.secretStack2.isHidden = false
        }else{
            self.secretStack2.isHidden = true
        }
        
        
        if CBGlobalMethods.shared.selectedBidPeriod == nil {
            self.secretStack1.isHidden = true
//            self.secretStack2.isHidden = true
        }else{
            self.secretStack1.isHidden = false
            
        }

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
    @objc private func qaSegmentTapped(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: qaTestSegment)

        let segmentWidth = qaTestSegment.bounds.width / CGFloat(qaTestSegment.numberOfSegments)
        let tappedIndex = Int(location.x / segmentWidth)

        let isQAMode = UserDefaults.standard.bool(forKey: "isQATest")

        // QA segment tapped again while already in QA mode
        if tappedIndex == 0 && isQAMode {
            alertinQASegment()
        }
    }
    @IBAction func qaTestSegmentAction(_ sender: Any) {
        guard let segmentedControl = sender as? UISegmentedControl else { return }
           
           let selectedIndex = segmentedControl.selectedSegmentIndex
           if selectedIndex == 0 {
               alertinQASegment()
           } else if selectedIndex == 1 {
//               self.envSegment.isHidden = true
//               self.envSegment.selectedSegmentIndex = 0
//               self.envLbl.isHidden = true
               UserDefaults.standard.setValue(false, forKey: "isQATest")
               NotificationCenter.default.post(name: NSNotification.Name("updateTitle"), object: nil)
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
                NotificationCenter.default.post(name: NSNotification.Name("updateTitle"), object: nil)
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
            self.envSegment.selectedSegmentIndex = 0
            UserDefaults.standard.setValue(false, forKey: "isQATest")
            NotificationCenter.default.post(name: NSNotification.Name("updateTitle"), object: nil)
        })

        self.present(alert, animated: true)
    }

    @IBAction func envChanged(_ sender: UISegmentedControl) {
        let selectedIndex = sender.selectedSegmentIndex
        let environment: String

        switch selectedIndex {
        case 0:
            environment = "Prod"
        case 1:
            environment = "QA"
        case 2:
            environment = "Dev"
        default:
            environment = "Prod"
        }

        UserDefaults.standard.set(environment, forKey: "SwaApiEnv")
        NotificationCenter.default.post(name: NSNotification.Name("updateTitle"), object: nil)
    }
    
    @IBAction func secretSgmntAction(_ sender: UISegmentedControl) {
        let selectedIndex = sender.selectedSegmentIndex
        if selectedIndex == 0{
            self.secretStack2.isHidden = false
        }else{
            self.secretStack2.isHidden = true
            UserDefaults.standard.set(nil, forKey: "SecretVDuserName")
            self.txtSecretUser.text = nil
        }
    }
    
    @IBAction func secretSubmitAction(_ sender: Any) {
        
        if let txt = self.txtSecretUser.text, !txt.isEmpty{
            self.txtSecretUser.resignFirstResponder()
            UserDefaults.standard.set(txt, forKey: "SecretVDuserName")
        }else{
            UserDefaults.standard.set(nil, forKey: "SecretVDuserName")
        }
        
        self.dismiss(animated: true)
    }
    
}
