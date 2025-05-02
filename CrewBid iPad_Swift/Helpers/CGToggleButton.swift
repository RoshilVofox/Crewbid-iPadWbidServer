//
//  CGToggleButton.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 21/03/25.
//

import Foundation
import UIKit

class GRRoundButton: UIButton {
    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = self.frame.height / 2
        self.layer.masksToBounds = true
    }
}
