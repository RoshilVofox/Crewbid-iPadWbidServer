//
//  CBTripTextViewController.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 19/04/25.
//

import UIKit

class CBTripTextViewController: UIViewController, KUIPopOverUsable {
    var contentSize: CGSize {
        let textSize: CGRect = tripText1.boundingRect(with: CGSize(width: 1024, height: 1024),
                                                      options: NSStringDrawingOptions.usesLineFragmentOrigin,
                                                      attributes: [NSAttributedString.Key.font: UIFont(name: "CourierNewPS-BoldMT", size: 13)!],
                                                      context: nil)
        preferredContentSize = CGSize(width: textSize.size.width + 60, height: textSize.size.height + 30)
        return CGSize(width: preferredContentSize.width, height: preferredContentSize.height)
    }
    
    var tripText1 = ""
    var button = CBTripButton()
    var isFromScratchpad: Bool = false
    var isFromBidList: Bool = false
    @IBOutlet weak var btnTimeToggleView: UIView!
    @IBOutlet weak var objScrollView: UIScrollView!
    
    @IBOutlet weak var tripTextBackgroundView: UIView!
    
    @IBOutlet weak var tripTextView: UITextView!
    @IBOutlet weak var herbLabel: UILabel!
    @IBOutlet weak var localLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()

            }
    class func instantiateFromStoryboard(withTripText tripText: String, button: CBTripButton) -> Any {
        let storyboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let tripTextController = storyboard.instantiateViewController(withIdentifier:"CBTripTextViewController") as! CBTripTextViewController
        tripTextController.tripText1 = tripText
        tripTextController.button = button
        return tripTextController
    }
}
