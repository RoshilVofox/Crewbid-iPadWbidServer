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
    @IBOutlet weak var textView: UITextView!
    
    var bidPeriod: BIBidPeriod!
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bidPeriod = CBGlobalMethods.shared.selectedBidPeriod!
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
        let bidListText = self.textView.text!
        let scanner = Scanner(string: bidListText)
        let numCharSet = CharacterSet(charactersIn: "0123456789")
        let positionCharSet = CharacterSet(charactersIn: "ABCDabcd")
        var lines = [BILine]()
        _ = scanner.scanUpToCharacters(from: numCharSet)
        var lineNumber: NSString?
        var position: NSString?
        
        while !scanner.isAtEnd{
            lineNumber = scanner.scanCharacters(from: numCharSet) as? NSString
            position = scanner.scanCharacters(from: positionCharSet) as? NSString
            if lineNumber!.intValue > 0 && lineNumber!.integerValue < 9999 {
                var line: [BILine] = []
                if bidPeriod.isFABid() && position != nil {
                    line = bidPeriod.getLineWithLineNumberAndFAPos(number: Int((lineNumber ?? "0") as String)!, position: position! as String)
                }else{
                    line = bidPeriod.getLineWithLineNumber(number: Int((lineNumber ?? "0") as String)!)
                }
                
                for ln in line{
                    lines.append(ln)
                }
                _ = scanner.scanUpToCharacters(from: numCharSet)
            }
        }
        if lines.count == 0 {
            AlertService.showAlertForTopVC(title: "Import Error", message: "No valid lines were entered")
        }else{
            let bidlist = CBBidListVC()
            bidlist.setupVariables()
            bidlist.insertLines(lines)
            self.dismiss(animated: true)
            NotificationCenter.default.post(name: NSNotification.Name("flipToBidList"), object: nil)
        }
    }
}
