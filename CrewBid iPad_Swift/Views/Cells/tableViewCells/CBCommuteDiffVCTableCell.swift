

import UIKit

class CBCommuteDiffVCTableCell: UITableViewCell {
    
    @IBOutlet weak var lineLabel: UILabel!
    @IBOutlet weak var oldCmtOvLabel: UILabel!
    @IBOutlet weak var newCmtOvLabel: UILabel!
    @IBOutlet weak var oldCmtOvFrLabel: UILabel!
    @IBOutlet weak var newCmtOvFrLabel: UILabel!
    @IBOutlet weak var oldCmtOvBaLabel: UILabel!
    @IBOutlet weak var newCmtOvBaLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
