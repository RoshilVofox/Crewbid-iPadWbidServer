//
//  CBSpreadsheetImportController.swift
//  CrewBid iPad_Swift
//
//  Created by Developer on 22/04/25.
//

import UIKit

class CBSpreadsheetImportController: UIViewController {

    @IBOutlet weak var btnImportText: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        btnImportText.layer.borderColor = CBColor.purpleColor().cgColor
        btnImportText.layer.borderWidth = 2
        btnImportText.layer.cornerRadius = 4

        // Do any additional setup after loading the view.
    }
    

    @IBAction func btnDismissAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func btnImportTextAction(_ sender: Any) {
    }
}
