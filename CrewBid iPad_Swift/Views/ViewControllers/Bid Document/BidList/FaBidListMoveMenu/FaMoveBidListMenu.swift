//
//  FaMoveBidListMenu.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 17/04/25.
//

import UIKit

class FaMoveBidListMenu: UIViewController,UITableViewDelegate,UITableViewDataSource,KUIPopOverUsable {

    
    var contentSize: CGSize{
        let height : CGFloat = CGFloat((38 * array.count) + 28)
        return CGSize(width: 300.0, height: height)
    }
    
    var arrowDirection: UIPopoverArrowDirection {
        return .left
    }
    
    @IBOutlet weak var viewBackground: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    var array : [String] = []
    var lines : [BILine] = []
    let bidListVC = CBBidListVC()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        viewBackground.clipsToBounds = true
        viewBackground.layer.cornerRadius = 5
        bidListVC.setupVariables()
    }
   
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return array.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FaMoveBidListCell") as! FaMoveBidListCell
        cell.lblTitle.text = array[indexPath.row]
        cell.lblTitle.textColor = UIColor.secondaryLabel
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedString = self.array[indexPath.row]
        CBGlobalMethods.shared.canPerformUndo = true
        CBGlobalMethods.shared.undoType = .undo
        NotificationCenter.default.post(name: NSNotification.Name("flipToBidList"), object: nil)
        switch selectedString {
        case "Move Position A to Bid List" :
            for line in self.lines {
                if line.faPositionString == "A" {
                    bidListVC.insertLines([line])
                }
            }
            break
        case "Move Position B to Bid List" :
            for line in self.lines {
                if line.faPositionString == "B" {
                    bidListVC.insertLines([line])
                }
            }
            break
        case "Move Position C to Bid List" :
            for line in self.lines {
                if line.faPositionString == "C" {
                    bidListVC.insertLines([line])
                }
            }
            break
        case "Move Position D to Bid List" :
            for line in self.lines {
                if line.faPositionString == "D" {
                    bidListVC.insertLines([line])
                }
            }
            break
        case "Move All Positions to Bid List" :
            bidListVC.insertLines(self.lines, faBidAllPositions: true)
            break
        default:
            break
        }
        self.dismiss(animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 38
    }
}
