//
//  CBVacationDataVC.swift
//  CrewBid iPad_Swift
//
//  Created by Rishad on 02/12/25.
//

import UIKit
import CoreData


class CBVacationDataVC: BaseViewController{
    
    var line: BILine!
    var bidPeriod: BIBidPeriod?
    
    @IBOutlet weak var lineNumberLabel: UILabel!
    
    
    @IBOutlet weak var vpCUValueLabel: UILabel!
    @IBOutlet weak var VOFcuValueLabel: UILabel!
    @IBOutlet weak var VAbpValueLabel: UILabel!
    @IBOutlet weak var VAPbpValueLabel: UILabel!
    @IBOutlet weak var VOBcuValueLabel: UILabel!
    
    
    @IBOutlet weak var vpNeValueLabel: UILabel!
    @IBOutlet weak var voFneValueLabel: UILabel!
    @IBOutlet weak var vAneValueLabel: UILabel!
    @IBOutlet weak var vapneValueLabel: UILabel!
    @IBOutlet weak var voBneValueLabel: UILabel!
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        preferredContentSize = CGSize(width: 320, height: view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
     
        // If using Auto Layout with safeArea
            if let topConstraint = lineNumberLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12) as NSLayoutConstraint? {
                topConstraint.isActive = true
            }
        
        lineNumberLabel.text = "Vacation Data - Line \(line.number ?? 0)"
        vpCUValueLabel.text   = String(format: "%.2f", line.vVacationPay?.doubleValue ?? 0.0)
        VOFcuValueLabel.text  = String(format: "%.2f", line.vFrontVoPay?.doubleValue ?? 0.0)
        VAbpValueLabel.text   = String(format: "%.2f", line.vAbp?.doubleValue ?? 0.0)
        VAPbpValueLabel.text  = String(format: "%.2f", line.vAPbp?.doubleValue ?? 0.0)
        VOBcuValueLabel.text  = String(format: "%.2f", line.vBackVoPay?.doubleValue ?? 0.0)
        if bidPeriod?.isFABid() ?? false {
            vpNeValueLabel.text   = String(format: "%.2f", line.vVacayCarryOutPay?.doubleValue ?? 0.0)
        }
        else{
            
            vpNeValueLabel.text   = String(format: "%.2f", line.vVacayPayNextBP?.doubleValue ?? 0.0)
        }
        voFneValueLabel.text  = String(format: "%.2f", line.vOFne?.doubleValue ?? 0.0)
        vAneValueLabel.text   = String(format: "%.2f", line.vAne?.doubleValue ?? 0.0)
        vapneValueLabel.text  = String(format: "%.2f", line.vAPne?.doubleValue ?? 0.0)
        voBneValueLabel.text  = String(format: "%.2f", line.vOBne?.doubleValue ?? 0.0)
    }
}
