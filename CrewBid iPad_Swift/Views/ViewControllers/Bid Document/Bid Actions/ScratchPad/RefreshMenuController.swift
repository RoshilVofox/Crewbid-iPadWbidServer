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
    
    private let refreshArray = ["Recover All","Recover Last","Trash All","Cancel"]
    var popOverType = PopoverViewType.MockYear
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.dismissPopover(animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 38
    }

}
