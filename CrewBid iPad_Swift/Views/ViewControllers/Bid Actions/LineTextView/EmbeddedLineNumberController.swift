//
//  EmbeddedLineNumberController.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 18/10/25.
//

import UIKit

class EmbeddedLineNumberController: BaseViewController {

    @IBOutlet weak var containerView: UIView!
    var selectedOption:String?
    override func viewDidLoad() {
        super.viewDidLoad()
        containerView.layer.borderColor = UIColor.black.cgColor
        containerView.layer.borderWidth = 1
        containerView.layer.cornerRadius = 5
        containerView.layer.masksToBounds = false
    }
  
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
       let navVC = segue.destination as? UINavigationController
       let vc = navVC?.viewControllers.first as! CBLineNumberController
        vc.action = selectedOption
    }
}
