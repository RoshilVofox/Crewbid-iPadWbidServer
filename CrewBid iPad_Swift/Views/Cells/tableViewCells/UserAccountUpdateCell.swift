//
//  UserAccountUpdateCell.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 07/10/25.
//

import UIKit

protocol UserAccountUpdateCellDelegate: AnyObject {
    func userAccountCell(_ cell: UserAccountUpdateCell, didChangeSegmentAt index: Int, forKey key: String)
}

class UserAccountUpdateCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var selectionSegment: UISegmentedControl!
    weak var delegate: UserAccountUpdateCellDelegate?
    var headerKey: String = ""
    override func awakeFromNib() {
        super.awakeFromNib()
    }


    @IBAction func segmentSelected(_ sender: UISegmentedControl) {
        delegate?.userAccountCell(self, didChangeSegmentAt: sender.selectedSegmentIndex, forKey: headerKey)
    }
}
