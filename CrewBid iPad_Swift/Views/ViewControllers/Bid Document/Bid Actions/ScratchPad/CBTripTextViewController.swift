//
//  CBTripTextViewController.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 19/04/25.
//

import UIKit

var CBLineTableCellTripButtonDehighlightNotification = "CBLineTableCellTripButtonDehighlightNotification"

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
    @IBOutlet weak var btnTimeToggle: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        objScrollView.clipsToBounds = true
        objScrollView.layer.cornerRadius = 5
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemGray2
        appearance.titleTextAttributes = [.foregroundColor: UIColor.black]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.black]
        let backButtonAppearance = UIBarButtonItemAppearance()
        backButtonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.systemBlue]
        appearance.backButtonAppearance = backButtonAppearance
        let backImage = UIImage(systemName: "chevron.backward")?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal)
        appearance.setBackIndicatorImage(backImage, transitionMaskImage: backImage)
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        tripTextView.text = tripText1
        // Add the Herb Time - Local Time toggle button
        btnTimeToggleView.layer.borderWidth = 1
        btnTimeToggleView.layer.borderColor = UIColor.black.cgColor
        btnTimeToggleView.layer.cornerRadius = 11
    
        
        herbLabel.layer.borderColor = UIColor.white.cgColor
        herbLabel.layer.borderWidth = 0.4
        herbLabel.layer.cornerRadius = 10
        herbLabel.clipsToBounds = true
        
        localLabel.layer.borderColor = UIColor.white.cgColor
        localLabel.layer.borderWidth = 0.4
        localLabel.layer.cornerRadius = 10
        localLabel.clipsToBounds = true
        
        if UserDefaults.standard.integer(forKey: kCBTimeZoneSetting) == CBTimeZoneSetting.herbTime.rawValue {
            //btnTimeToggle.setTitle("Herb Time", for: .normal)
            herbLabel.backgroundColor = .purple
            herbLabel.textColor = .white
            localLabel.backgroundColor = .white
            localLabel.textColor = .black
            
        }
        else {
            //btnTimeToggle.setTitle("Local Time", for: .normal)
            localLabel.backgroundColor = .purple
            localLabel.textColor = .white
            herbLabel.backgroundColor = .white
            herbLabel.textColor = .black
        }
        
        
    }
    
    
    class func instantiateFromStoryboard(withTripText tripText: String, button: CBTripButton) -> Any {
        let storyboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let tripTextController = storyboard.instantiateViewController(withIdentifier:"CBTripTextViewController") as! CBTripTextViewController
        tripTextController.tripText1 = tripText
        tripTextController.button = button
        return tripTextController
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        button.setHighlighted(false)
    }
    @IBAction func BtnTimeToggleAction(_ sender: Any) {
        if UserDefaults.standard.integer(forKey: kCBTimeZoneSetting) == CBTimeZoneSetting.herbTime.rawValue {
            UserDefaults.standard.set(CBTimeZoneSetting.localTime.rawValue, forKey: kCBTimeZoneSetting)
           // btnTimeToggle.setTitle("Local Time", for: .normal)
            localLabel.backgroundColor = .purple
            localLabel.textColor = .white
            herbLabel.backgroundColor = .white
            herbLabel.textColor = .black
        }
        else {
            UserDefaults.standard.set(CBTimeZoneSetting.herbTime.rawValue, forKey: kCBTimeZoneSetting)
            //btnTimeToggle.setTitle("Herb Time", for: .normal)
            herbLabel.backgroundColor = .purple
            herbLabel.textColor = .white
            localLabel.backgroundColor = .white
            localLabel.textColor = .black
        }
        let tripButton  = button
        
        tripTextView.text = "\(tripButton.trip!.tripText())"
        NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
    }
}
