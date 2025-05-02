

import UIKit

class ShowCAPTableViewCell: UITableViewCell {

    @IBOutlet weak var lblBase: UILabel!
    @IBOutlet weak var lblSeat: UILabel!
    @IBOutlet weak var lblThisMonth: UILabel!
    @IBOutlet weak var lblNextMonth: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
