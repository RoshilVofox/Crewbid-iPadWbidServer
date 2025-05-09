//
//  BidListActionVC.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 19/04/25.
//

import UIKit

class BidListActionVC: BaseViewController,KUIPopOverUsable,UITableViewDelegate,UITableViewDataSource,UITextFieldDelegate {
    
    private let bidListActionArray = ["Scrolling Options","Deselect All Lines","Move Selected Lines","Undo","Redo","Return Selected Lines To Scratchpad","Return Unfrozen Lines To Scratchpad", "Start Over"]
    
    var contentSize: CGSize{
        return CGSize(width: 300, height: 355)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bidListActionArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CBBidListActionTableCell") as! CBBidListActionTableCell
        cell.lblTitle.text = bidListActionArray[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 42
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            // Handle Scrolling Options
            let alertWindow = UIWindow(frame: UIScreen.main.bounds)
            alertWindow.rootViewController = UIViewController()
            alertWindow.windowLevel = UIWindow.Level.alert + 1
            
            let alertController = UIAlertController(title: "Scroll to Line", message: "Enter a line number to scroll to <> or select another option.  You can auto-scroll to the top by tapping the middle of the gray bar above the Bid List.", preferredStyle: .alert)
            alertController.addTextField { (textField : UITextField!) -> Void in
                textField.delegate = self
                textField.autocapitalizationType = .allCharacters
                textField.keyboardType = .namePhonePad
                textField.tag = 401
            }
            
            let toLine = UIAlertAction(title: "Scroll to Line", style: UIAlertAction.Style.default) {
                UIAlertAction in
                let textField = alertController.textFields![0]
                let txtScrollToLineNumber = textField.text!
                let appendDictionary = NSMutableDictionary()
                appendDictionary["lineNumber"] = txtScrollToLineNumber
                self.dismiss(animated: true) {
                    //                    NotificationCenter
                }
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) {
                UIAlertAction in
                self.dismiss(animated: true, completion: nil)
            }
            
            let toInsertionBar = UIAlertAction(title: "Scroll to Insertion Bar", style: UIAlertAction.Style.default) {
                UIAlertAction in
                self.dismiss(animated: true) {
                    //                    NotificationCenter
                }
            }
            
            let toBottom = UIAlertAction(title: "Scroll to Bottom", style: UIAlertAction.Style.default) {
                UIAlertAction in
                self.dismiss(animated: true) {
                    //                    NotificationCenter
                }
            }
            alertController.addAction(toLine)
            alertController.addAction(toInsertionBar)
            alertController.addAction(toBottom)
            alertController.addAction(cancelAction)
            self.dismiss(animated: true) {
                UIApplication.topViewController()?.present(alertController, animated: true)
                alertWindow.makeKeyAndVisible()
            }
        }
    }
}
