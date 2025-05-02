//
//  CBScatchPadVC.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 21/03/25.
//

import UIKit

class CBScatchPadVC: BaseViewController {

    
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
        // Do any additional setup after loading the view.
    }
    


}
extension CBScatchPadVC: UITableViewDelegate,UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ScratchPadTableCellTableViewCell") as! ScratchPadTableCellTableViewCell
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 250
    }
    
}
