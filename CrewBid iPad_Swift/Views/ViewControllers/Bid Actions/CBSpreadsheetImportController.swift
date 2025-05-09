//
//  CBSpreadsheetImportController.swift
//  CrewBid iPad_Swift
//
//  Created by Developer on 22/04/25.
//

import UIKit

class CBSpreadsheetImportController: UIViewController {

    @IBOutlet weak var btnImportText: UIButton!
    @IBOutlet weak var btnClose: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
       
        setupUI()
    }
    
    func setupUI() {
        btnClose.setTitle("", for: .normal)
        btnImportText.layer.borderColor = CBColor.purpleColor.cgColor
        btnImportText.layer.borderWidth = 2
        btnImportText.layer.cornerRadius = 4
    }

    @IBAction func btnDismissAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func btnImportTextAction(_ sender: Any) {
    }
}
