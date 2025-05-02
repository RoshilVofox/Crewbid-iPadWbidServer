//
//  CBBiddataDownloadVC.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 20/03/25.
//

import UIKit

class CBBiddataDownloadVC: UIViewController {
    // base
    @IBOutlet weak var btnATL: dataDownloadingButton!
    @IBOutlet weak var btnAUS: dataDownloadingButton!
    @IBOutlet weak var btnBNA: dataDownloadingButton!
    @IBOutlet weak var btnBWI: dataDownloadingButton!
    @IBOutlet weak var btnDAL: dataDownloadingButton!
    @IBOutlet weak var btnDEN: dataDownloadingButton!
    @IBOutlet weak var btnFLL: dataDownloadingButton!
    @IBOutlet weak var btnHOU: dataDownloadingButton!
    @IBOutlet weak var btnLAS: dataDownloadingButton!
    @IBOutlet weak var btnLAX: dataDownloadingButton!
    @IBOutlet weak var btnMCO: dataDownloadingButton!
    @IBOutlet weak var btnMDW: dataDownloadingButton!
    @IBOutlet weak var btnOAK: dataDownloadingButton!
    @IBOutlet weak var btnPHX: dataDownloadingButton!
    // position
    @IBOutlet weak var btnCP: dataDownloadingButton!
    @IBOutlet weak var btnFO: dataDownloadingButton!
    @IBOutlet weak var btnFA: dataDownloadingButton!
    // round
    @IBOutlet weak var btnFirstRound: dataDownloadingButton!
    @IBOutlet weak var btnSecondRound: dataDownloadingButton!
    // month
    @IBOutlet weak var btnJAN: dataDownloadingButton!
    @IBOutlet weak var btnFEB: dataDownloadingButton!
    @IBOutlet weak var btnMAR: dataDownloadingButton!
    @IBOutlet weak var btnAPR: dataDownloadingButton!
    @IBOutlet weak var btnMAY: dataDownloadingButton!
    @IBOutlet weak var btnJUN: dataDownloadingButton!
    @IBOutlet weak var btnJUL: dataDownloadingButton!
    @IBOutlet weak var btnAUG: dataDownloadingButton!
    @IBOutlet weak var btnSEP: dataDownloadingButton!
    @IBOutlet weak var btnOCT: dataDownloadingButton!
    @IBOutlet weak var btnNOV: dataDownloadingButton!
    @IBOutlet weak var btnDEC: dataDownloadingButton!
    // year
    @IBOutlet weak var btnBeforePrevious: dataDownloadingButton!
    @IBOutlet weak var btnPreviousYear: dataDownloadingButton!
    @IBOutlet weak var btnCurrentYear: dataDownloadingButton!
    
    @IBOutlet weak var viewBase: UIView!
    @IBOutlet weak var viewPosition: UIView!
    @IBOutlet weak var viewRound: UIView!
    @IBOutlet weak var viewMonth: UIView!
    @IBOutlet weak var viewYear: UIView!
    
    @IBOutlet weak var lblTitle: UILabel!
    var selectedRound: Int?
    var selectedPosition : String?
    var empNum : String?
    var selectedDomicile : String?
    var month :  Int?
    var isFromHistoric : Bool = false
    var Year : Int?
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        // Do any additional setup after loading the view.
    }
    

 
    @IBAction func btnNextAction(_ sender: Any) {
        let storyboard = UIStoryboard(name: "BidInfo", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBCredentialsPageVC") as! CBCredentialsPageVC
        vc.isFromHistoric = self.isFromHistoric
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func btnBackAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    
    
    @IBAction func btnBaseAction(_ sender: UIButton) {
        // Iterate over a range of button tags
        for i in (40..<54) {
            if i == (sender as AnyObject).tag {
                // Update the selected domicile based on the button title
                selectedDomicile = sender.titleLabel!.text!
                let button = self.view.viewWithTag(i) as! UIButton
                button.backgroundColor = UIColor.systemOrange
            } else {
                // Reset background color for other buttons
                let button = self.view.viewWithTag(i) as! UIButton
                button.backgroundColor = .secondarySystemBackground
                
            }
        }
        print("Base: \(selectedDomicile!)")
    }
    
    @IBAction func btnPositionAction(_ sender: UIButton) {
        for i in (14..<17) {
            if i == (sender as AnyObject).tag {
                let button = self.view.viewWithTag(i) as! UIButton
                button.backgroundColor = UIColor.systemOrange
            } else {
                let button = self.view.viewWithTag(i) as! UIButton
                button.backgroundColor = .secondarySystemBackground
            }
        }
        switch sender.tag {
        case 14:selectedPosition = "CP"
        case 15:selectedPosition = "FO"
        case 16:selectedPosition = "FA"
        default:break
        }
        print("Position: \(selectedPosition!)")
    }
    
    @IBAction func btnRoundAction(_ sender: UIButton) {
        for i in (17..<19) {
            if i == (sender as AnyObject).tag {
                let button = self.view.viewWithTag(i) as! UIButton
                button.backgroundColor = UIColor.systemOrange
            } else {
                let button = self.view.viewWithTag(i) as! UIButton
                button.backgroundColor = .secondarySystemBackground
            }
        }
        switch sender.tag {
        case 17:selectedRound = 1
        case 18:selectedRound = 2
        default:break
        }
        print("Round: \(selectedRound!)")
    }
    
    @IBAction func btnMonthAction(_ sender: UIButton) {
        for i in (1..<13) {
            if i == (sender as AnyObject).tag {
                let button = self.view.viewWithTag(i) as! UIButton
                button.backgroundColor = UIColor.systemOrange
            } else {
                let button = self.view.viewWithTag(i) as! UIButton
                button.backgroundColor = .secondarySystemBackground
            }
        }
        switch sender.tag {
        case 1:month = 1
        case 2:month = 2
        case 3:month = 3
        case 4:month = 4
        case 5:month = 5
        case 6:month = 6
        case 7:month = 7
        case 8:month = 8
        case 9:month = 9
        case 10:month = 10
        case 11:month = 11
        case 12:month = 12
        default:break
        }
        print("Month: \(month!)")
    }
    
    @IBAction func btnYearAction(_ sender: UIButton) {
        month = nil
        // Reset background color for all month buttons
//
//        for i in (1..<13) {
//            let button = self.view.viewWithTag(i) as! UIButton
//            button.backgroundColor = .secondarySystemBackground
//        }
        // Iterate over a range of button tags representing years

        for i in (60..<63) {
            if i == (sender as AnyObject).tag {
                let button = self.view.viewWithTag(i) as! UIButton
                button.backgroundColor = UIColor.systemOrange
            } else {
                let button = self.view.viewWithTag(i) as! UIButton
                button.backgroundColor = .secondarySystemBackground
            }
        }
    }
    
    func setupUI(){
        //Title setup
    if isFromHistoric == true {
        lblTitle.text = "Historic Bid Data"
    }else{
        lblTitle.text = "New Bid Data"
    }
    
    //Year button title
    let currentDate = Date()
    let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
    let nextMonthYear = Calendar.current.component(.year, from: nextMonth)

    btnBeforePrevious.setTitle("\(nextMonthYear - 2)", for: UIControl.State.normal)
    btnPreviousYear.setTitle("\(nextMonthYear - 1)", for: UIControl.State.normal)
    btnCurrentYear.setTitle("\(nextMonthYear)", for: UIControl.State.normal)


}
}
