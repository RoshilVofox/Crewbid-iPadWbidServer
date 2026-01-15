//
//  CBBidLineMenuController.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 17/04/25.
//

import UIKit

protocol CBBidLineMenuControllerDelegate:AnyObject{
    func addReserveMRTline(indexpath:Int,isReserve:Bool)
    func removeReserveMRTline(indexpath:IndexPath,isReserve:Bool)
}

class CBBidLineMenuController: BaseViewController, UITableViewDelegate, UITableViewDataSource, KUIPopOverUsable {

    
    
    
    var bidPeriod: BIBidPeriod!
    
    var selectedLinesCount:NSMutableArray = NSMutableArray()
    var popOverType = PopoverViewType.MockYear
    var arrMonth :NSArray = NSArray()
    var arrYear :NSArray = NSArray()
    var arrFAPositions:NSMutableArray = NSMutableArray()
    var selectedIndexpath : Int = Int ()
    var selectedIndexpathValue : IndexPath = IndexPath ()
    
    var isCellHasMarker = false
    var isCellIsFrozen = false
    var rowsCount: Int = 0
    var isFaFirstRoundBid = false
    var isFaReserveLineExists = false
    var isFaMrtLineExists = false
    var line: BILine?
    var fromBidlist = false
    weak var delegate:CBBidLineMenuControllerDelegate?
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var bgView: UIView!
    
    var contentSize: CGSize{
        var size:CGSize?
        if bidPeriod.isFABid() {
            size = CGSize(width: 300.0, height: 350)
        } else {
            size = CGSize(width: 300.0, height: 270)
        }
        if fromBidlist {
            if (line?.isFrozen != 0) {
                if isCellHasMarker {
                    size?.height = 44.0 * 4
                } else {
                    size?.height = 44.0 * 3
                }
            } else {
                if isCellHasMarker {
                    if isFaFirstRoundBid && (!isFaMrtLineExists || !isFaReserveLineExists) {
                        if !isFaMrtLineExists && !isFaReserveLineExists {
                            size?.height = 44.0 * 9
                        } else {
                            size?.height = 44.0 * 8
                        }
                    } else {
                        size?.height = 44.0 * 7
                    }
                } else {
                    if isFaFirstRoundBid && (!isFaMrtLineExists || !isFaReserveLineExists) {
                        if !isFaMrtLineExists && !isFaReserveLineExists {
                            if bidPeriod.positionType?.intValue ==  BICrewPositionType.FlightAttendant.rawValue && bidPeriod.round == 2
                            {
                                size?.height = 44.0 * 6
                            }
                            else
                            {
                                size?.height = 44.0 * 8
                            }
                            
                            
                        } else {
                            size?.height = 44.0 * 7
                        }
                    } else {
                        size?.height = 44.0 * 6
                    }
                }
            }
            fromBidlist = false
        }
        size!.height = size!.height + 20
        return size!
    }
    
    var popOverBackgroundColor: UIColor? {
        var color: UIColor?
        color = UIColor.white
        return color
    }
    var arrowDirection: UIPopoverArrowDirection = UIPopoverArrowDirection.unknown
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.preferredContentSize = contentSizeOf
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.bgView.clipsToBounds = true
        self.bgView.layer.cornerRadius = 5
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.reloadData()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        var numberOfSections: Int = 1
        rowsCount = 0
        // SCENARIO 1: Cell is Frozen
        if isCellIsFrozen {
            numberOfSections = 2
        } else if isFaFirstRoundBid && (!isFaReserveLineExists || !isFaMrtLineExists) {
            numberOfSections = 5
        } else {
            numberOfSections = 4
        }
        return numberOfSections
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var numberOfRows: Int = 1
        // Return the number of rows in the section.
        //SCENARIO 1
        if isCellIsFrozen {
            if 0 == section {
                // Marker
                numberOfRows = isCellHasMarker ? 2 : 1
            } else if 1 == section {
                // Freeze and Unfreeze
                numberOfRows = 2
            }
        } else if isFaFirstRoundBid && (!isFaReserveLineExists || !isFaMrtLineExists) {
            if 0 == section {
                // Insert Above and Insert Below
                numberOfRows = 2
            } else if 1 == section {
                numberOfRows = isCellHasMarker ? 2 : 1
            } else if 2 == section {
                // Freeze and Unfreeze
                numberOfRows = 2
            } else if 3 == section {
                // Insert Reserve, Insert MRT, or both
                if !isFaReserveLineExists && !isFaMrtLineExists {
                    numberOfRows = 2
                }
                // no need to check for 1 of them existing b/c we are only in this if statement if
                // at least one of them exists
            }
        }
        else {
            if 0 == section {
                // Insert Above and Insert Below
                numberOfRows = 2
            } else if 1 == section {
                // Marker
                numberOfRows = isCellHasMarker ? 2 : 1
            } else if 2 == section {
                // Freeze and Unfreeze
                numberOfRows = 2
            }
        }
        rowsCount += numberOfRows
        return numberOfRows
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let kRefreshMenuCell = "BidLineMenuCell"
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: kRefreshMenuCell)!
        self.tableView.separatorStyle = UITableViewCell.SeparatorStyle.singleLine
        self.tableView.separatorInset = UIEdgeInsets.zero
        cell.textLabel?.font = UIFont.systemFont(ofSize: 17.0, weight: .semibold)
        cell.backgroundColor = UIColor.systemBackground
        cell.textLabel?.textColor = UIColor.label
        cell.textLabel?.shadowColor = UIColor.clear
        cell.selectionStyle = .gray

        // SCENARIO 1
        if isCellIsFrozen {
            if 0 == indexPath.section {
                if isCellHasMarker {
                    if 0 == indexPath.row {
                        cell.textLabel?.text = "Edit Marker Title"
                    } else {
                        cell.textLabel?.text = "Remove Marker"
                    }
                } else {
                    cell.textLabel?.text = "Add Marker"
                }
            } else if 1 == indexPath.section {
                if 0 == indexPath.row {
                    cell.textLabel?.text = "Freeze lines from here up"
                } else {
                    cell.textLabel?.text = "Unfreeze top lines"
                }
            }
            // Background for section 1 only (freeze/unfreeze lines).
            if 1 == indexPath.section {
                cell.textLabel?.backgroundColor = UIColor.clear
                cell.textLabel?.textColor = UIColor.white
                cell.textLabel?.shadowColor = UIColor(white: 0.0, alpha: 0.54)
                cell.textLabel?.shadowOffset = CGSize(width: 0.0, height: -1.0)
                let backgroundView = UIView(frame: CGRect.zero)
                // Red 153 green 255 blue 255
                backgroundView.backgroundColor = UIColor(red: 0.0, green: 0.75, blue: 1.0, alpha: 1.0)
                cell.backgroundView = backgroundView
            } else {
                cell.backgroundView = nil
                cell.selectedBackgroundView = nil
            }
        }
        
        // SCENARIO 2
        else if isFaFirstRoundBid && (!isFaReserveLineExists || !isFaMrtLineExists) {
            if 0 == indexPath.section {
                if 0 == indexPath.row {
                    cell.textLabel?.text = "Insert Lines Above"
                } else {
                    cell.textLabel?.text = "Insert Lines Below"
                }
            } else if 1 == indexPath.section {
                if isCellHasMarker {
                    if 0 == indexPath.row {
                        cell.textLabel?.text = "Edit Marker Title"
                    } else {
                        cell.textLabel?.text = "Remove Marker"
                    }
                } else {
                    cell.textLabel?.text = "Add Marker"
                }
            } else if 2 == indexPath.section {
                if 0 == indexPath.row {
                    cell.textLabel?.text = "Freeze lines from here up"
                } else {
                    cell.textLabel?.text = "Unfreeze top lines"
                }
            } else if 3 == indexPath.section {
                if 0 == indexPath.row {
                    if !isFaReserveLineExists {
                        cell.textLabel?.text = "Insert Reserve Line"
                    } else {
                        cell.textLabel?.text = "Insert MRT Line"
                    }
                } else {
                    cell.textLabel?.text = "Insert MRT Line"
                }
            } else {
                if (line?.faBidLineReserve?.boolValue)! {
                    cell.textLabel?.text = "Remove Reserve Line"
                } else if (line?.faBidLineMrt?.boolValue)! {
                    cell.textLabel?.text = "Remove MRT Line"
                } else {
                    cell.textLabel?.text = "Return Line to Scratchpad"
                }
            }
            // Add background gradients
            if 2 == indexPath.section {
                cell.textLabel?.backgroundColor = UIColor.clear
                cell.textLabel?.textColor = UIColor.white
                cell.textLabel?.shadowColor = UIColor(white: 0.0, alpha: 0.54)
                cell.textLabel?.shadowOffset = CGSize(width: 0.0, height: -1.0)
                let backgroundView = UIView(frame: CGRect.zero)
                // Red 153 green 255 blue 255
                backgroundView.backgroundColor = UIColor(red: 0.0, green: 0.75, blue: 1.0, alpha: 1.0)
                cell.backgroundView = backgroundView
            }
            else if 3 == indexPath.section {
                // Only called if faBidFirstRound
                cell.textLabel?.backgroundColor = UIColor.clear
                cell.textLabel?.textColor = UIColor.white
                cell.textLabel?.shadowColor = UIColor(white: 0.0, alpha: 0.54)
                cell.textLabel?.shadowOffset = CGSize(width: 0.0, height: -1.0)
                let backgroundView = UIView(frame: CGRect.zero)
                // /////Red 255 green 58 blue 0
                backgroundView.backgroundColor = CBColor.faPosBColor
                cell.backgroundView = backgroundView
            }
            else  if 4 == indexPath.section {
                cell.textLabel?.backgroundColor = UIColor.clear
                cell.textLabel?.textColor = UIColor.white
                cell.textLabel?.shadowColor = UIColor(white: 0.0, alpha: 0.54)
                cell.textLabel?.shadowOffset = CGSize(width: 0.0, height: -1.0)
                let backgroundView = UIView(frame: CGRect.zero)
                // Red 255 green 58 blue 0
                backgroundView.backgroundColor = UIColor(red: 1.000, green: 0.227, blue: 0.000, alpha: 1.000)
                cell.backgroundView = backgroundView
            } else {
                cell.backgroundView = nil
                cell.selectedBackgroundView = nil
            }
        }
        
         // SCENARIO 3
        else {
            if 0 == indexPath.section {
                if 0 == indexPath.row {
                    cell.textLabel?.text = "Insert Lines Above"
                } else {
                    cell.textLabel?.text = "Insert Lines Below"
                }
            } else if 1 == indexPath.section {
                if isCellHasMarker {
                    if 0 == indexPath.row {
                        cell.textLabel?.text = "Edit Marker Title"
                    } else {
                        cell.textLabel?.text = "Remove Marker"
                    }
                } else {
                    cell.textLabel?.text = "Add Marker"
                }
            } else if 2 == indexPath.section {
                if 0 == indexPath.row {
                    cell.textLabel?.text = "Freeze lines from here up"
                } else {
                    cell.textLabel?.text = "Unfreeze top lines"
                }
            } else {
                if isFaFirstRoundBid {
                    if (line?.faBidLineReserve?.boolValue)! {
                        cell.textLabel?.text = "Remove Reserve Line"
                    } else if (line?.faBidLineMrt?.boolValue)! {
                        cell.textLabel?.text = "Remove MRT Line"
                    } else {
                        cell.textLabel?.text = "Return Line to Scratchpad"
                    }
                } else {
                    cell.textLabel?.text = "Return Line to Scratchpad"
                }
            }
            // Add background gradients
            if 2 == indexPath.section {
                cell.textLabel?.backgroundColor = UIColor.clear
                cell.textLabel?.textColor = UIColor.white
                cell.textLabel?.shadowColor = UIColor(white: 0.0, alpha: 0.54)
                cell.textLabel?.shadowOffset = CGSize(width: 0.0, height: -1.0)
                let backgroundView = UIView(frame: CGRect.zero)
                // Red 153 green 255 blue 255
                backgroundView.backgroundColor = UIColor(red: 0.0, green: 0.75, blue: 1.0, alpha: 1.0)
                cell.backgroundView = backgroundView
            } else if 3 == indexPath.section {
                cell.textLabel?.backgroundColor = UIColor.clear
                cell.textLabel?.textColor = UIColor.white
                cell.textLabel?.shadowColor = UIColor(white: 0.0, alpha: 0.54)
                cell.textLabel?.shadowOffset = CGSize(width: 0.0, height: -1.0)
                let backgroundView = UIView(frame: CGRect.zero)
                // Red 255 green 58 blue 0
                backgroundView.backgroundColor = UIColor(red: 1.000, green: 0.227, blue: 0.000, alpha: 1.000)
                cell.backgroundView = backgroundView
            } else {
                cell.backgroundView = nil
                cell.selectedBackgroundView = nil
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        CBGlobalMethods.shared.canPerformUndo = true
        CBGlobalMethods.shared.undoType = .undo
        self.bidPeriod.currentDateTime = Date()
        self.bidPeriod.isStateFileModifiedToSync = true
        let appendDictionary = NSMutableDictionary()
        // SCENARIO 1
        if isCellIsFrozen {
            if 0 == indexPath.section {
                if isCellHasMarker {
                    if 0 == indexPath.row {
                        appendDictionary["indexpath"] = selectedIndexpathValue
                        NotificationCenter.default.post(name: Notification.Name("CBEditMarkerNotification"), object: appendDictionary)
                        self.dismissPopover(animated: true)
                    } else {
                        appendDictionary["indexpath"] = selectedIndexpathValue
                        NotificationCenter.default.post(name: Notification.Name("CBRemoveMarkerNotification"), object: appendDictionary)
                        self.dismissPopover(animated: true)
                    }
                } else {
                    appendDictionary["indexpath"] = selectedIndexpathValue
                    NotificationCenter.default.post(name: Notification.Name("CBAddMarkerNotification"), object: appendDictionary)
                    self.dismissPopover(animated: true)
                }
            } else if 1 == indexPath.section {
                if 0 == indexPath.row {
                    appendDictionary["indexpath"] = selectedIndexpath
                    NotificationCenter.default.post(name: Notification.Name("CBFreezeLinesNotification"), object: appendDictionary)
                    self.dismissPopover(animated: true)
                } else {
                    appendDictionary["indexpath"] = selectedIndexpath
                    NotificationCenter.default.post(name: Notification.Name("CBUnFreezeLinesNotification"), object: appendDictionary)
                    self.dismissPopover(animated: true)                }
            }
        }
        
        // SCENARIO 2
        else if isFaFirstRoundBid && (!isFaReserveLineExists || !isFaMrtLineExists) {
            if 0 == indexPath.section {
                if 0 == indexPath.row {
                    appendDictionary["indexpath"] = selectedIndexpath
                    appendDictionary["above"] = true
                    NotificationCenter.default.post(name: Notification.Name("CBInsertLinesAboveNotification"), object: appendDictionary)
                    self.dismissPopover(animated: true)
                } else {
                    appendDictionary["indexpath"] = selectedIndexpath
                    appendDictionary["above"] = false
                    NotificationCenter.default.post(name: Notification.Name("CBInsertLinesBelowNotification"), object: appendDictionary)
                    self.dismissPopover(animated: true)
                }
            } else if 1 == indexPath.section {
                if isCellHasMarker {
                    if 0 == indexPath.row {
                        appendDictionary["indexpath"] = selectedIndexpathValue
                        NotificationCenter.default.post(name: Notification.Name("CBEditMarkerNotification"), object: appendDictionary)
                        self.dismissPopover(animated: true)
                    } else {
                        appendDictionary["indexpath"] = selectedIndexpathValue
                        NotificationCenter.default.post(name: Notification.Name("CBRemoveMarkerNotification"), object: appendDictionary)
                        self.dismissPopover(animated: true)
                    }
                } else {
                    appendDictionary["indexpath"] = selectedIndexpathValue
                    NotificationCenter.default.post(name: Notification.Name("CBAddMarkerNotification"), object: appendDictionary)
                    self.dismissPopover(animated: true)
                }
            }
            else if 2 == indexPath.section {
                if 0 == indexPath.row {
                    appendDictionary["indexpath"] = selectedIndexpath
                    NotificationCenter.default.post(name: Notification.Name("CBFreezeLinesNotification"), object: appendDictionary)
                    self.dismissPopover(animated: true)
                } else {
                    appendDictionary["indexpath"] = selectedIndexpath
                    NotificationCenter.default.post(name: Notification.Name("CBUnFreezeLinesNotification"), object: appendDictionary)
                    self.dismissPopover(animated: true)
                }
            } else if 3 == indexPath.section {
                if 0 == indexPath.row {
                    if !isFaReserveLineExists {
                        if ((bidPeriod.containsVacay?.boolValue ?? false) ||
                            (bidPeriod.containsFvVacay?.boolValue ?? false)) &&
                           (bidPeriod.seniorityVacayAvailable?.boolValue == true) {
                            let alert = UIAlertController(title: "Warning !", message: "You have vacation this month - you cannot bid reserve.", preferredStyle: .alert)
                                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                                        alert.dismiss(animated: true, completion: nil)
                                        self.dismissPopover(animated: true)
                                    }))
                                    present(alert, animated: true, completion: nil)
                        }
                        else{
                            let appendDictionary = NSMutableDictionary()
                            appendDictionary["indexpath"] = selectedIndexpath
                            delegate?.addReserveMRTline(indexpath: selectedIndexpath, isReserve: true)
                            self.dismissPopover(animated: true)
                        }
                    } else {
                        appendDictionary["indexpath"] = selectedIndexpath
                        delegate?.addReserveMRTline(indexpath: selectedIndexpath, isReserve: false)
                        self.dismissPopover(animated: true)
                    }
                } else {
                    appendDictionary["indexpath"] = selectedIndexpath
                    delegate?.addReserveMRTline(indexpath: selectedIndexpath, isReserve: false)
                    self.dismissPopover(animated: true)
                }
            } else {
                if (line?.faBidLineReserve?.boolValue)! {
                    appendDictionary["indexpath"] = selectedIndexpathValue
                    delegate?.removeReserveMRTline(indexpath: selectedIndexpathValue, isReserve: true)
                    self.dismissPopover(animated: true)
                } else if (line?.faBidLineMrt?.boolValue)! {
                    appendDictionary["indexpath"] = selectedIndexpathValue
                    delegate?.removeReserveMRTline(indexpath: selectedIndexpathValue, isReserve: false)
                    self.dismissPopover(animated: true)
                } else {
                    appendDictionary["indexpath"] = selectedIndexpathValue
                    NotificationCenter.default.post(name: Notification.Name("CBReturnLinesNotification"), object: appendDictionary)
                    self.dismissPopover(animated: true)
                }
            }
        }
        
        // SCENARIO 3
        else {
            if 0 == indexPath.section {
                if 0 == indexPath.row {
                    appendDictionary["indexpath"] = selectedIndexpath
                    appendDictionary["above"] = true
                    NotificationCenter.default.post(name: Notification.Name("CBInsertLinesAboveNotification"), object: appendDictionary)
                    self.dismissPopover(animated: true)
                } else {
                    appendDictionary["indexpath"] = selectedIndexpath
                    appendDictionary["above"] = false
                    NotificationCenter.default.post(name: Notification.Name("CBInsertLinesBelowNotification"), object: appendDictionary)
                    self.dismissPopover(animated: true)
                }
            }
            else if 1 == indexPath.section {
                if isCellHasMarker {
                    if 0 == indexPath.row {
                        appendDictionary["indexpath"] = selectedIndexpathValue
                        NotificationCenter.default.post(name: Notification.Name("CBEditMarkerNotification"), object: appendDictionary)
                        self.dismissPopover(animated: true)
                    } else {
                        appendDictionary["indexpath"] = selectedIndexpathValue
                        NotificationCenter.default.post(name: Notification.Name("CBRemoveMarkerNotification"), object: appendDictionary)
                        self.dismissPopover(animated: true)
                    }
                } else {
                    appendDictionary["indexpath"] = selectedIndexpathValue
                    NotificationCenter.default.post(name: Notification.Name("CBAddMarkerNotification"), object: appendDictionary)
                    self.dismissPopover(animated: true)
                }
            }
            else if 2 == indexPath.section {
                if 0 == indexPath.row {
                    appendDictionary["indexpath"] = selectedIndexpath
                    NotificationCenter.default.post(name: Notification.Name("CBFreezeLinesNotification"), object: appendDictionary)
                    self.dismissPopover(animated: true)
                } else {
                    appendDictionary["indexpath"] = selectedIndexpath
                    NotificationCenter.default.post(name: Notification.Name("CBUnFreezeLinesNotification"), object: appendDictionary)
                    self.dismissPopover(animated: true)
                }
            }
            else {
                if isFaFirstRoundBid {
                    if (line?.faBidLineReserve?.boolValue)! {
                        appendDictionary["indexpath"] = selectedIndexpathValue
                        delegate?.removeReserveMRTline(indexpath: selectedIndexpathValue, isReserve: true)
                        self.dismissPopover(animated: true)
                    } else if (line?.faBidLineMrt?.boolValue)! {
                        appendDictionary["indexpath"] = selectedIndexpathValue
                        delegate?.removeReserveMRTline(indexpath: selectedIndexpathValue, isReserve: false)
                        self.dismissPopover(animated: true)
                    } else {
                        appendDictionary["indexpath"] = selectedIndexpathValue
                        NotificationCenter.default.post(name: Notification.Name("CBReturnLinesNotification"), object: appendDictionary)
                        self.dismissPopover(animated: true)
                    }
                } else {
                    appendDictionary["indexpath"] = selectedIndexpathValue
                    NotificationCenter.default.post(name: Notification.Name("CBReturnLinesNotification"), object: appendDictionary)
                    self.dismissPopover(animated: true)
                }
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    public var contentSizeOf: CGSize {
        let width: CGFloat = 320.0
        let cellHeight: CGFloat = 44.0
        var height: CGFloat = cellHeight * CGFloat(rowsCount)
        if !isFaFirstRoundBid {
            height = height + 11.0
        } else {
            height = height + 25.0
        }
        if isCellHasMarker {
            height = height - 42.0
            height += cellHeight
        }
        height = height + 20
        return CGSize(width: width, height: height)
    }
    
}
