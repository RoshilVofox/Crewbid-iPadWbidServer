//
//  RefreshMenuController.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 17/04/25.
//

import UIKit

class RefreshMenuController: BaseViewController,UITableViewDelegate,UITableViewDataSource,KUIPopOverUsable {

    var contentSize: CGSize{
        return CGSize(width: 160.0, height: 180)
    }
    
    @IBOutlet weak var viewBackground: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    var bidPeriod:BIBidPeriod!
    var lines:[BILine] = []
    private let refreshArray = ["Recover All","Recover Last","Trash All","Cancel"]
    var arrayLinesDetails:NSArray = NSArray()
    var popOverType = PopoverViewType.MockYear
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        viewBackground.clipsToBounds = true
        viewBackground.layer.cornerRadius = 5
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var rowsCount :Int?
        if popOverType == PopoverViewType.Refresh
        {
            rowsCount = 4
        } else if popOverType == PopoverViewType.warning || popOverType == PopoverViewType.CommutingManualNoMidInfo || popOverType == PopoverViewType.CommutingManualNoMidInfoSort
        {
            rowsCount = 1
        }
        return rowsCount!
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RefreshMenuTableViewCell") as! RefreshMenuTableViewCell
        cell.lblTitle.text = refreshArray[indexPath.row]
        
        if indexPath.row == 0 { //Recover All
            if (self.bidPeriod.lastTrashedDetails?.count ?? 0) > 0 {
                cell.isUserInteractionEnabled = true
                cell.lblTitle.alpha = 1.0
            }else{
                cell.isUserInteractionEnabled = false
                cell.lblTitle.alpha = 0.3
            }
        }else if indexPath.row == 1 { //Recover Last
            if (self.bidPeriod.lastTrashedDetails?.count ?? 0) > 0 {
                cell.isUserInteractionEnabled = true
                cell.lblTitle.alpha = 1.0
            }else{
                cell.isUserInteractionEnabled = false
                cell.lblTitle.alpha = 0.3
            }
        }else if indexPath.row == 2 { //Trash All
            if lines.count > 0 {
                cell.isUserInteractionEnabled = true
                cell.lblTitle.alpha = 1.0
            }else{
                cell.isUserInteractionEnabled = false
                cell.lblTitle.alpha = 0.3
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        bidPeriod.loadedPresetIdentifier = nil
        bidPeriod.currentDateTime = Date()
        bidPeriod.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)
//        CBGlobalMethods.shared.selectedBidPeriod!.loadedPresetIdentifier = nil
//        CBGlobalMethods.shared.selectedBidPeriod?.currentDateTime = Date()
//        CBGlobalMethods.shared.selectedBidPeriod?.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)
        if popOverType == PopoverViewType.Refresh{
            if indexPath.row == 0{ //Recover All
                NotificationCenter.default.post(name: NSNotification.Name("recoverAllTrashed"), object: nil)
                self.dismissPopover(animated: true)
            }else if indexPath.row == 1{ //Recover Last
                NotificationCenter.default.post(name: NSNotification.Name("undoTrashLast"), object: nil)
                self.dismissPopover(animated: true)
            }else if indexPath.row == 2{ //Trash all
                NotificationCenter.default.post(name: NSNotification.Name("trashAll"), object: nil)
                self.dismissPopover(animated: true)
            }else if indexPath.row == 3{ //Cancel
                self.dismissPopover(animated: true)
            }
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 38
    }

}
