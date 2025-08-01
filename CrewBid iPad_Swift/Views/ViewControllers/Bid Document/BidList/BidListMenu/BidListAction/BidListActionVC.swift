//
//  BidListActionVC.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 19/04/25.
//

import UIKit

class BidListActionVC: BaseViewController,KUIPopOverUsable,UITableViewDelegate,UITableViewDataSource,UITextFieldDelegate {
    
    private let bidListActionArray = ["Scrolling Options","Deselect All Lines","Move Selected Lines","Undo","Redo","Return Selected Lines To Scratchpad","Return Unfrozen Lines To Scratchpad", "Start Over"]
    var bidPeriod = BIBidPeriod()
    var ArrLinesDetails: [BILine] = []
    var selectedLinesCount:NSMutableArray = NSMutableArray()
    
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
        cell.lblTitle.font = UIFont.systemFont(ofSize: 15)
        if indexPath.row == 0 {
            if ArrLinesDetails.count > 0 {
                cell.isUserInteractionEnabled = true
                cell.lblTitle.alpha = 1
            }else{
                cell.isUserInteractionEnabled = false
                cell.lblTitle.alpha = 0.5
            }
        }else if indexPath.row == 1 {
            if selectedLinesCount.count > 0 {
                cell.isUserInteractionEnabled = true
                cell.lblTitle.alpha = 1.0
            }
            else {
                cell.isUserInteractionEnabled = false
                cell.lblTitle.alpha = 0.5
            }
        }else if indexPath.row == 2 {
            cell.lblTitle.text = "Move Selected Line\(selectedLinesCount.count > 1 || !(selectedLinesCount.count > 0) ? "s" : "")"
            if selectedLinesCount.count > 0 {
                cell.isUserInteractionEnabled = true
                cell.lblTitle.alpha = 1.0
            } else {
                cell.isUserInteractionEnabled = false
                cell.lblTitle.alpha = 0.5
            }
        }else if indexPath.row == 3 {
            if (bidPeriod.managedObjectContext!.undoManager?.canUndo)! && !(bidPeriod.managedObjectContext!.undoManager?.undoActionName == "") {
                cell.lblTitle.text = bidPeriod.managedObjectContext!.undoManager?.undoMenuItemTitle
                cell.isUserInteractionEnabled = true
                cell.lblTitle.alpha = 1.0
            } else {
                cell.isUserInteractionEnabled = false
                cell.lblTitle.alpha = 0.5
            }
        } else if indexPath.row == 4 {
            cell.isUserInteractionEnabled = false
            cell.lblTitle.alpha = 0.5
            if bidPeriod.managedObjectContext!.undoManager != nil {
                if (bidPeriod.managedObjectContext!.undoManager?.canRedo)! {
                    cell.lblTitle.text = bidPeriod.managedObjectContext!.undoManager?.redoMenuItemTitle
                    cell.isUserInteractionEnabled = true
                    cell.lblTitle.alpha = 1.0
                }
            }
        } else if indexPath.row == 5 {
            cell.lblTitle.text = "Return Selected Line\(selectedLinesCount.count > 1 || !(selectedLinesCount.count > 0) ? "s" : "") to Scratchpad"
            if selectedLinesCount.count > 0 {
                cell.isUserInteractionEnabled = true
                cell.lblTitle.alpha = 1.0
                cell.lblTitle.textColor = UIColor.white
                cell.backgroundColor = UIColor.red
            }
            else {
                cell.isUserInteractionEnabled = false
                cell.lblTitle.alpha = 0.5
            }
        } else if indexPath.row == 6 {
            if ArrLinesDetails.count > 0 {
                cell.isUserInteractionEnabled = true
                cell.lblTitle.alpha = 1.0
                cell.lblTitle.textColor = UIColor.white
                cell.backgroundColor = UIColor.red
            }
            else {
                cell.isUserInteractionEnabled = false
                cell.lblTitle.alpha = 0.5
                cell.backgroundColor = UIColor.systemBackground
            }
        } else if indexPath.row == 7 {
            if ArrLinesDetails.count > 0 {
                cell.isUserInteractionEnabled = true
                cell.lblTitle.alpha = 1.0
                cell.lblTitle.textColor = UIColor.white
                cell.backgroundColor = UIColor( red: CGFloat(178/255.0), green: CGFloat(34/255.0), blue: CGFloat(34/255.0), alpha: CGFloat(1.0))
            }
            else {
                cell.isUserInteractionEnabled = false
                cell.lblTitle.alpha = 0.5
                if #available(iOS 13.0, *) {
                    cell.backgroundColor = UIColor.systemBackground
                } else {
                    cell.backgroundColor = UIColor.white // Fallback on earlier versions
                }
            }
        }
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
