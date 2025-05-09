//
//  CBNewBidVC.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 21/03/25.
//

import UIKit

class CBNewBidVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }

    func setupUI() {
        self.view.clipsToBounds = true
        self.view.layer.borderColor = UIColor.darkGray.cgColor
        self.view.layer.borderWidth = 4
        self.view.layer.cornerRadius = 10
    }
}
