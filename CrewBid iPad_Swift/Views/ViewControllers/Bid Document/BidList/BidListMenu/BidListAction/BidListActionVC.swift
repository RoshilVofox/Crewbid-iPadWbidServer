//
//  BidListActionVC.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 19/04/25.
//

import UIKit

class BidListActionVC: BaseViewController,KUIPopOverUsable,UITableViewDelegate,UITableViewDataSource,UITextFieldDelegate {
    
    private let bidListActionArray = ["Scrolling Options","Deselect All Lines","Move Selected Lines","Undo","Redo","Return Selected Lines to Scratchpad","Return Unfrozen Lines to Scratchpad", "Start Over"]
    var bidPeriod:BIBidPeriod!
    var ArrLinesDetails: [BILine] = []
    var selectedLinesCount:NSMutableArray = NSMutableArray()
    weak var delegate:StartOverDelegate?
    @IBOutlet weak var tableView: UITableView!
    var contentSize: CGSize{
        return CGSize(width: 300, height: 355)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.layer.cornerRadius = 5
        bidPeriod = CBGlobalMethods.shared.selectedBidPeriod!
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bidListActionArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CBBidListActionTableCell") as! CBBidListActionTableCell
        cell.lblTitle.text = bidListActionArray[indexPath.row]
        cell.lblTitle.font = UIFont.systemFont(ofSize: 17)
        cell.lblTitle.adjustsFontSizeToFitWidth = true
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
            if (bidPeriod.managedObjectContext!.undoManager?.canUndo)! || !(bidPeriod.managedObjectContext!.undoManager?.undoActionName == "") {
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
                    NotificationCenter.default.post(name: Notification.Name("ScrollToLineNotification"), object: appendDictionary)
                }
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) {
                UIAlertAction in
                self.dismiss(animated: true, completion: nil)
            }
            
            let toInsertionBar = UIAlertAction(title: "Scroll to Insertion Bar", style: UIAlertAction.Style.default) {
                UIAlertAction in
                self.dismiss(animated: true) {
                    NotificationCenter.default.post(name: Notification.Name("ScrollToInsertionLineNotification"), object: nil)
                }
            }
            
            let toBottom = UIAlertAction(title: "Scroll to Bottom", style: UIAlertAction.Style.default) {
                UIAlertAction in
                self.dismiss(animated: true) {
                    NotificationCenter.default.post(name: Notification.Name("ScrollToBottomLineNotification"), object: nil)
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
        }else if indexPath.row == 1{
            // Handle Deselect All Lines
            NotificationCenter.default.post(name: Notification.Name("CBDeselectAllLinesNotification"), object: nil)
            self.dismissPopover(animated: true)
        
        }else if indexPath.row == 2{
            // Handle Move Selected Lines
            NotificationCenter.default.post(name: Notification.Name("CBMoveSelectedNotification"), object: nil)
            self.dismissPopover(animated: true)
        }else if indexPath.row == 3{
            // Handle Undo
            NotificationCenter.default.post(name: Notification.Name("CBUndoNotification"), object: nil)
            self.dismissPopover(animated: true)
        }else if indexPath.row == 4{
            // Handle Redo
            NotificationCenter.default.post(name: Notification.Name("CBRedoNotification"), object: nil)
            self.dismissPopover(animated: true)
        }else if indexPath.row == 5{
            // Handle Return Selected Lines To Scratchpad
            NotificationCenter.default.post(name: Notification.Name("CBReturnSelectedLinesNotification"), object: nil)
            self.dismissPopover(animated: true)
        }else if indexPath.row == 6{
            // Handle Return Unfrozen Lines To Scratchpad
            let alertController = UIAlertController(title: "Tap OK to remove all unfrozen lines.", message: nil, preferredStyle: .alert)
            let OkAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) {
                UIAlertAction in
                NotificationCenter.default.post(name: Notification.Name("CBReturnUnfrozenLinesNotification"), object: nil)
                self.dismissPopover(animated: true)
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) {
                UIAlertAction in
                self.dismissPopover(animated: true)
            }
            alertController.addAction(OkAction)
            alertController.addAction(cancelAction)
            self.dismiss(animated: true) {
                UIApplication.topViewController()?.present(alertController, animated: true, completion: nil)
            }
        }else if indexPath.row == 7{
            // Handle Start Over
            if self.bidPeriod.isBidListSortOn == true {
                let alertController = UIAlertController(title: "Crewbid", message: "Please disable bid list sort to perform this operation", preferredStyle: .alert)
                let OkAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) {
                    UIAlertAction in
                    self.dismissPopover(animated: true)
                }
                alertController.addAction(OkAction)
                self.dismiss(animated: true) {
                    UIApplication.topViewController()?.present(alertController, animated: true, completion: nil)
                    
                }
            }else{
                let alertController = UIAlertController(title: "Confirm Start Over", message: "This removes all lines from the Bid List, even frozen ones, removes all sorts, and resets the filters to the default state. This action CANNOT be undone", preferredStyle: .alert)
                let OkAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) {
                    UIAlertAction in
                    self.startOverAlert()
                }
                let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) {
                    UIAlertAction in
                }
                alertController.addAction(OkAction)
                alertController.addAction(cancelAction)
                self.dismiss(animated: true) {
                    UIApplication.topViewController()?.present(alertController, animated: true, completion: nil)
                    
                }
            }
        }
    }
    
    func startOverAlert() {
        let alertController1 = UIAlertController(title: "Are you sure?", message: "Remember, This action cannot be undone", preferredStyle: .alert)
        let OkAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) {
            UIAlertAction in
            self.dismissPopover(animated: true)
            self.delegate?.startOver()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) {
            UIAlertAction in
        }
        alertController1.addAction(OkAction)
        alertController1.addAction(cancelAction)
        UIApplication.topViewController()?.present(alertController1, animated: true, completion: nil)
    }
}
