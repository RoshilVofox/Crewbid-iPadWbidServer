//
//  EmbeddedTripAwardViewController.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 17/10/25.
//

import UIKit

class EmbeddedTripAwardViewController: UIViewController {

    @IBOutlet weak var containerView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        containerView.layer.borderColor = UIColor.black.cgColor
        containerView.layer.borderWidth = 1
        containerView.layer.cornerRadius = 5
        containerView.layer.masksToBounds = false
    }


}
