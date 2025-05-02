

import UIKit

class AwardCalendarCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var dayLabel: UILabel!
    @IBOutlet weak var selImg: UIImageView!
    
    func toggleSelected () {
        if (isSelected) {
            selImg.image = UIImage(named: "Tick")
        } else {
            selImg.image = nil
        }
    }
}
