//
//  CBBidActionsViewController.swift
//  CrewBid iPad_Swift
//
//  Created by Developer on 21/04/25.
//

import UIKit

class CBBidActionsViewController: UIViewController, KUIPopOverUsable {
    var contentSize: CGSize {
        return CGSize(width: 410, height: 480)
    }
    
    @IBOutlet weak var btnBack: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    lazy var employeeNum: UITextField = {
        let tf = UITextField()
        tf.keyboardType = .numberPad
        return tf
    }()
    
    lazy var comfirmEmployeeNum: UITextField = {
        let tf = UITextField()
        tf.keyboardType = .numberPad
        return tf
    }()
    
    var arr:[String] = []
    var prev: [String] = []
    let arrForPilotWithAwdTxt = ["Submit Bid","Show Bid Receipt","Show Awards","Show Bid File","Line Importer","Vacation", "Show CAP","Retrieve Awards","Restore Last Bid","ReDownload Flt Data"]
    let pilotFileArray = ["Cover Letter","Seniority List","Lines Text","Trips Text"]
    let vacationFAArray = ["Keep Pulled Trips In Filters/Sorts", "Re Download WBID Maz Vac File", "Re Download Swaptimizer Maz Vac File"]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        arr = arrForPilotWithAwdTxt
        btnBack.isHidden = true
        btnBack.setTitle("", for: .normal)
        
        
        
    }
    
    
    @IBAction func btnBackAction(_ sender: Any) {
        arr = prev
        tableView.reloadData()
        btnBack.isHidden = true
    }
    
    
    
    
}

extension CBBidActionsViewController: UITableViewDataSource, UITableViewDelegate{
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if arr[0] == "Submit Bid" {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CBBidActionTableCell", for: indexPath) as! CBBidActionTableCell
            
            if arr[indexPath.row] == "Show Bid File" || arr[indexPath.row] == "Vacation" {
                cell.label.text = arrForPilotWithAwdTxt[indexPath.row]
                cell.imgv.image = UIImage(named: "newarrow")
                cell.imgv.isHidden = false
            } else {
                cell.label.text = arr[indexPath.row]
                cell.imgv.isHidden = true
            }
            return cell
            
        } else if arr[0] == "Keep Pulled Trips In Filters/Sorts" {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchTableViewCell", for: indexPath) as! SwitchTableViewCell
            cell.switch.isHidden = arr[indexPath.row] == "Keep Pulled Trips In Filters/Sorts" ? false : true
            cell.label.text = arr[indexPath.row]
            
            // configure CBFlightCell here
            return cell
            
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CBBidActionTableCell", for: indexPath) as! CBBidActionTableCell
            cell.label.text = arr[indexPath.row]
            cell.imgv.isHidden = true
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        
        // MARK: - Vacation Selection
        let item = arr[indexPath.row]
        if item == "Vacation" {
            prev = arr
            arr = vacationFAArray
            tableView.reloadData()
            btnBack.isHidden = false
        }
        // MARK: - Show Bid File Selection
        if item == "Show Bid File" {
            prev = arr
            arr = pilotFileArray
            tableView.reloadData()
            btnBack.isHidden = false
        }
        // MARK: - cover Letter Selection
        if item == "Cover Letter" {
            if let presentingVC = self.presentingViewController {
                self.dismiss(animated: true) {
                    let storyboard = UIStoryboard(name: "BidActions", bundle: nil)
                    let vc = storyboard.instantiateViewController(withIdentifier: "CBTextViewController") as! CBTextViewController
                    vc.modalPresentationStyle = .fullScreen
                    vc.type = "cover letter"
                    presentingVC.present(vc, animated: true)
                }
            }
            
        }
        // MARK: - Seniority List Selection
        if item == "Seniority List" {
            if let presentingVC = self.presentingViewController {
                self.dismiss(animated: true) {
                    let storyboard = UIStoryboard(name: "BidActions", bundle: nil)
                    let vc = storyboard.instantiateViewController(withIdentifier: "CBTextViewController") as! CBTextViewController
                    vc.modalPresentationStyle = .fullScreen
                    vc.type = "Seniority List"
                    presentingVC.present(vc, animated: true)
                }
            }
            
        }
        // MARK: - Bid recipt Selection
        if item == "Show Bid Receipt" {
            if let presentingVC = self.presentingViewController {
                self.dismiss(animated: true) {
                    let storyboard = UIStoryboard(name: "BidActions", bundle: nil)
                    let vc = storyboard.instantiateViewController(withIdentifier: "CBBidReciptViewController") as! CBBidReciptViewController
                    vc.modalPresentationStyle = .fullScreen
                    presentingVC.present(vc, animated: true)
                }
            }
            
        }
        // MARK: - LIne Importer Selection
        if item == "Line Importer" {
            if let presentingVC = self.presentingViewController {
                self.dismiss(animated: true) {
                    let storyboard = UIStoryboard(name: "BidActions", bundle: nil)
                    let vc = storyboard.instantiateViewController(withIdentifier: "EmbeddedLineImporterVC") as! EmbeddedLineImporterVC
                    vc.preferredContentSize = CGSize(width: 680, height: 700)
                    presentingVC.present(vc, animated: true)
                }
            }
        }
        
        // MARK: - Show CAP Selection
        if item == "Show CAP" {
            if let presentingVC = self.presentingViewController {
                self.dismiss(animated: true) {
                    let storyboard = UIStoryboard(name: "BidActions", bundle: nil)
                    let vc = storyboard.instantiateViewController(withIdentifier: "EmbeddedShowCAPVC") as! EmbeddedShowCAPVC
                    vc.preferredContentSize = CGSize(width: 500, height: 500)
                    presentingVC.present(vc, animated: true)
                }
            }
        }
        
        // MARK: - Show Awards Selection
        if item == "Show Awards" {
            if let presentingVC = self.presentingViewController {
                self.dismiss(animated: true) {
                    let storyboard = UIStoryboard(name: "BidActions", bundle: nil)
                    let vc = storyboard.instantiateViewController(withIdentifier: "EmbeddedCredentialVC") as! EmbeddedCredentialVC
                    vc.preferredContentSize = CGSize(width: 600, height: 500)
                    presentingVC.present(vc, animated: true)
                }
            }
        }
        
        if item == "Submit Bid" {
            let alert = UIAlertController(
                title: "Submit Bid",
                message: "Please enter Employee number (no \"e\") for whom the bid is being submitted",
                preferredStyle: .alert
            )
            alert.addTextField { textField in
                textField.placeholder = "Employee Number"
                self.employeeNum = textField
            }
            
            //cancel
            let cancelAction = UIAlertAction(title: "cancel", style: .cancel)
            //add
            let okAction = UIAlertAction(title: "ok", style: .default) { _ in
                self.submitBidAlert()
            }
            alert.addAction(okAction)
            alert.addAction(cancelAction)
            
            present(alert, animated: true)
        }
    }
                                          

    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50 // set your fixed height
    }
    
    
    func submitBidAlert() {
        let alert = UIAlertController(
            title: "Submit Bid",
            message: "To confirm, please enter the Employee number again.",
            preferredStyle: .alert
        )
        alert.addTextField { textField in
            textField.placeholder = "Employee Number"
            self.comfirmEmployeeNum = textField
        }
        
        //cancel
        let cancelAction = UIAlertAction(title: "cancel", style: .cancel)
        //add
        let okAction = UIAlertAction(title: "ok", style: .default) { _ in
            self.ConfirmSubmitBidAlert()
        }
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    func ConfirmSubmitBidAlert() {
        if self.comfirmEmployeeNum.text == self.employeeNum.text {
            let alert = UIAlertController(
                title: "Alert",
                message: "If you are Buddy Bidding you need to verify that you are buddy bidders on your Buddy list, and they know you are buddy bidding with them.",
                preferredStyle: .alert
            )
            let buddyBiddingAction = UIAlertAction(title: "I have Verified", style: .default) { _ in
                self.buddyBidSelected()
            }
            let notBuddyBiddingAction = UIAlertAction(title: "I am not Buddy Bidding", style: .default) { _ in
                self.buddyBidNotSelected()
            }
            alert.addAction(buddyBiddingAction)
            alert.addAction(notBuddyBiddingAction)
            present(alert, animated: true)
        }
        
        else {
            let alert = UIAlertController(
                title: "Alert",
                message: "The entered employee number does not match the original entry. Please check and try again.",
                preferredStyle: .alert
            )
            let cancelAction = UIAlertAction(title: "ok", style: .cancel)
            alert.addAction(cancelAction)
            present(alert, animated: true)
        }
    }
    
    func buddyBidSelected() {
        let storyboard = UIStoryboard(name: "BidActions", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBOptionalEmployeesPageViewController") as! CBOptionalEmployeesPageViewController
        vc.preferredContentSize = CGSize(width: 600, height: 500)
        present(vc, animated: true)
    }
    
    func buddyBidNotSelected() {
//        self.finalAlert()
        let storyboard = UIStoryboard(name: "BidActions", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBSubmitCredentialVC") as! CBSubmitCredentialVC
        vc.preferredContentSize = CGSize(width: 600, height: 500)
        present(vc, animated: true)
        self.finalAlert()
    }
    
    func finalAlert() {
        let alert = UIAlertController(
            title: "Buddy Bidding Terms",
            message: "By continuing, you represent that you have the permission of your buddy or buddies to Buddy Bid with them and you have taken the necessary steps inSwA lite to out them on vour BuddyBidding list.I Understand and Accept",
            preferredStyle: .alert
        )
        let cancelAction = UIAlertAction(title: "ok", style: .cancel)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
    
}

