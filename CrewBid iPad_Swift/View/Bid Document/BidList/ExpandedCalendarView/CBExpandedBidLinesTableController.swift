//
//  CBExpandedBidLinesTableController.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 17/04/25.
//

import UIKit

class CBExpandedBidLinesTableController: BaseViewController {
    @IBOutlet weak var btnClose: UIButton!
    @IBOutlet weak var btnShare: UIButton!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var expandedTableView: UITableView!
    
    
    var navTitle = "Expanded Bid List"
    var tempRows = [0,1,2,3,4]
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    func setupUI(){
        lblTitle.text = navTitle
        let closeImg = UIImage(named: "NewBid-navbar-xcancelbutton")?.withRenderingMode(.alwaysTemplate)
        let shareImg = UIImage(named: "NavBarGray-ActionButton")?.withRenderingMode(.alwaysTemplate)
        btnClose.setImage(closeImg, for: .normal)
        btnShare.setImage(shareImg, for: .normal)
        btnClose.imageView?.tintColor = .white
        btnShare.imageView?.tintColor = .white
        btnClose.tintColor = .white
    }

    @IBAction func btnCloseAction(_ sender: Any) {
        (sender as? UIButton)?.isEnabled = false
        self.dismiss(animated: true)
    }

}
extension CBExpandedBidLinesTableController: UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tempRows.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CBExpandedBidLinesTableControllerCell") as! CBExpandedBidLinesTableControllerCell
        cell.textLabel?.text = "\(tempRows[indexPath.row]+1)"
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
}

class ExpandedCalendarCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var lblWeekDays: UILabel!
    @IBOutlet weak var dayLabel: UILabel!
    
    
}
