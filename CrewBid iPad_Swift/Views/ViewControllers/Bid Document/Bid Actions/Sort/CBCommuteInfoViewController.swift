//
//  CBCommuteInfoViewController.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 17/04/25.
//

import UIKit

class CBCommuteInfoViewController: UIViewController {
    @IBOutlet weak var btnCommuterCity: UIButton!
    @IBOutlet weak var btnSetConnectTime: UIButton!
    @IBOutlet weak var btnReportPadTime: UIButton!
    @IBOutlet weak var btnPadForBackToBase: UIButton!
    @IBOutlet weak var btnNonStop: CheckBox!
    @IBOutlet weak var nonStopView: UIView!
    
    let checkInArray = NSArray(objects: "00:05","00:10","00:15","00:20","00:25","00:30","00:35","00:40","00:45","00:50","00:55","01:00","01:05","01:10","01:15","01:20","01:25","01:30","01:35","01:40","01:45","01:50","01:55","02:00","02:05","02:10","02:15","02:20","02:25","02:30","02:35","02:40","02:45","02:50","02:55","03:00")
    let connectTimeArray = NSArray(objects: "00:05","00:10","00:15","00:20","00:25","00:30","00:35","00:40","00:45","00:50","00:55","01:00")
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        // Do any additional setup after loading the view.
    }
    func setupUI(){
        let borderColor = UIColor.gray.cgColor
        
        btnCommuterCity.layer.borderColor = borderColor
        btnCommuterCity.layer.borderWidth = 1
        btnSetConnectTime.layer.borderColor = borderColor
        btnSetConnectTime.layer.borderWidth = 1
        btnReportPadTime.layer.borderColor = borderColor
        btnReportPadTime.layer.borderWidth = 1
        btnPadForBackToBase.layer.borderColor = borderColor
        btnPadForBackToBase.layer.borderWidth = 1
        
        btnNonStop.layer.borderColor = borderColor
        btnNonStop.layer.borderWidth = 3.0
        btnNonStop.layer.cornerRadius = btnNonStop.frame.size.width / 2
        btnNonStop.layer.masksToBounds = true
        btnNonStop.backgroundColor = UIColor.white
        
        nonStopView.layer.cornerRadius = nonStopView.frame.size.width / 2
        nonStopView.layer.masksToBounds = true
        nonStopView.isHidden = true
//        print(self.navigationController)
    }
//    selecting commutter city
    @IBAction func btnCommuterCityAction(_ sender: Any) {
        let storyboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CommuteCityView") as! CommuteCityViewController
        vc.modalPresentationStyle = .custom
//        let frame = CGRect(x: 15, y: 35, width: 0, height: 0)
        vc.preferredContentSize = CGSize(width: 400, height: 400)
        vc.showPopover(withNavigationController: self.view)
    }
    
    @IBAction func btnSetConnectTimeAction(_ sender: Any) {
        timeAlert(array: checkInArray, title: "Connect Time")
    }
    
    @IBAction func btnReportPadTimeAction(_ sender: Any) {
        timeAlert(array: connectTimeArray, title: "Report Pad Time")
    }
    
    @IBAction func btnPadForBackToBaseAction(_ sender: Any) {
        timeAlert(array: checkInArray, title: "")
    }
    
    @IBAction func btnNonStopAction(_ sender: Any) {
        nonStopView.isHidden.toggle()
        if nonStopView.isHidden{
            btnSetConnectTime.setTitle("00:30", for: .normal)
        }
        else {
            btnSetConnectTime.setTitle("-:-", for: .normal)
        }
        
    }
    
    @IBAction func btnViewCommuteTimeAction(_ sender: Any) {
        let storyboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CommutableTimeView") as! CommutableTimeViewController
        vc.modalPresentationStyle = .custom
//        let frame = CGRect(x: 15, y: 35, width: 0, height: 0)
        vc.preferredContentSize = CGSize(width: 400, height: 400)
        vc.showPopover(withNavigationController: self.view)
    }
    
    @IBAction func btnDoneSettingCommuteTimeAction(_ sender: Any) {
        let alert = UIAlertController(
            title: btnCommuterCity.title(for: .normal),
            message: "Is your commuter city?",
            preferredStyle: .alert
        )
        //cancel
        let cancelAction = UIAlertAction(title: "No", style: .cancel)
        //add
        let okAction = UIAlertAction(title: "Yes", style: .default) { _ in
            self.dismiss(animated: true, completion: nil)
        }
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    @IBAction func btnCancelAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    //    alert's function for setting time
    func timeAlert(array: NSArray, title: String){
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertController.Style.alert)
        for i in array{
            alert.addAction(UIAlertAction(title: "\(i)", style: UIAlertAction.Style.default, handler: { _ in
                switch title {
                    case "Connect Time":
                    self.btnSetConnectTime.setTitle("\(i)", for: .normal)
                    break
                case "Report Pad Time":
                    self.btnReportPadTime.setTitle("\(i)", for: .normal)
                    break
                default :
                    self.btnPadForBackToBase.setTitle("\(i)", for: .normal)
                }
            }))
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
        present(alert, animated: true, completion: nil)
    }
}
