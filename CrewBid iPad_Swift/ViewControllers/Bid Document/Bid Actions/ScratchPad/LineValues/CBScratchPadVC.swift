//
//  CBScatchPadVC.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 21/03/25.
//

import UIKit

class CBScratchPadVC: BaseViewController {

    
    @IBOutlet weak var lblTrashLineCount: UILabel!
    @IBOutlet weak var btnTrash: UIButton!
    @IBOutlet weak var btnFlag: UIButton!
    @IBOutlet weak var btnMoveToLine: UIButton!
    @IBOutlet weak var btnMoveAllToBidList: UIButton!
    @IBOutlet weak var lblScratchpadLineCount: UILabel!
    @IBOutlet weak var scratchPadTableView: UITableView!
    

    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scratchPadTableView.delegate = self
        scratchPadTableView.dataSource = self
        
        //Tap gesture for refresh button.
        let refreshTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.trashRefreshButton))
        btnTrash.addGestureRecognizer(refreshTapGesture)
        refreshTapGesture.delaysTouchesBegan = true
    }
    
    //Tap gesture for refresh button in trash menu.
    @objc func trashRefreshButton(_ gesture: UITapGestureRecognizer) {
        let storyboard : UIStoryboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let refreshViewController = storyboard.instantiateViewController(withIdentifier: "RefreshMenuController") as! RefreshMenuController
        refreshViewController.popOverType = PopoverViewType.Refresh
        refreshViewController.modalPresentationStyle = .popover
        let frame = CGRect(x: btnTrash.frame.origin.x - 40, y: btnTrash.frame.origin.y + 20 , width: 0, height: 0)
        refreshViewController.showPopover(sourceView: self.btnTrash, sourceRect: frame)
    }

    @IBAction func btnFlagAction(_ sender: Any) {
        let storyboard : UIStoryboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let lineValuesController = storyboard.instantiateViewController(withIdentifier: "CBUserFlagTableController") as! CBUserFlagTableController
        lineValuesController.modalPresentationStyle = .popover
        lineValuesController.showPopover(sourceView: self.btnFlag)
    }
}
extension CBScratchPadVC: UITableViewDelegate,UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ScratchPadTableCellTableViewCell") as! ScratchPadTableCellTableViewCell
        cell.selectionStyle = .none
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 340
    }
    
}
