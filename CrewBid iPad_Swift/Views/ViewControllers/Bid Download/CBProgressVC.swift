//
//  CBProgressVC.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 20/03/25.
//

import UIKit

class CBProgressVC: UIViewController {

    @IBOutlet weak var text1: UILabel!
    @IBOutlet weak var text2: UILabel!
    @IBOutlet weak var text3: UILabel!
    @IBOutlet weak var text4: UILabel!
    
    @IBOutlet weak var button1: GRRoundButton!
    @IBOutlet weak var button2: GRRoundButton!
    @IBOutlet weak var button3: GRRoundButton!
    @IBOutlet weak var button4: GRRoundButton!
    
    @IBOutlet weak var indicator1: UIActivityIndicatorView!
    @IBOutlet weak var indicator2: UIActivityIndicatorView!
    @IBOutlet weak var indicator3: UIActivityIndicatorView!
    @IBOutlet weak var indicator4: UIActivityIndicatorView!
    
    let reachability = try! Reachability()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        button1.layer.cornerRadius = 22.5
        button2.layer.cornerRadius = 22.5
        button3.layer.cornerRadius = 22.5
        button4.layer.cornerRadius = 22.5
        
        if reachability.isReachable{
            self.button1.backgroundColor = .white
            self.button1.setImage(UIImage.init(named:"CheckBoxChecked"), for: .normal)
            self.indicator1.isHidden = true
            self.indicator2.isHidden = false
            self.indicator3.isHidden = true
            self.indicator4.isHidden = true
            self.indicator2.color = .white
            self.indicator2.startAnimating()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(notificationAction(notification: )), name: Notification.Name("DownloadingBid"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(notificationAction(notification: )), name: Notification.Name("ParsingBid"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(notificationAction(notification: )), name: Notification.Name("ParsingVacation"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(notificationAction(notification: )), name: Notification.Name("CloseProgressView"), object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func notificationAction(notification:Notification){
        let name = notification.name.rawValue
        if name == "DownloadingBid"{
            DispatchQueue.main.async {
                self.button2.backgroundColor = .white
                self.button2.setImage(UIImage.init(named: "CheckBoxChecked"), for: .normal)
                self.indicator1.isHidden = true
                self.indicator2.isHidden = true
                self.indicator3.isHidden = false
                self.indicator4.isHidden = true
                self.indicator3.color = .white
                self.indicator2.stopAnimating()
                self.indicator3.startAnimating()
            }
        }else if name == "ParsingBid"{
            DispatchQueue.main.async {
                self.button3.setImage(UIImage.init(named: "CheckBoxChecked"), for: .normal)
                self.button3.backgroundColor = .white
                self.indicator1.isHidden = true
                self.indicator2.isHidden = true
                self.indicator3.isHidden = true
                self.indicator4.isHidden = false
                self.indicator4.color = .white
                self.indicator3.stopAnimating()
                self.indicator4.startAnimating()
            }
        }else if name == "ParsingVacation"{
            DispatchQueue.main.async {
                self.button4.setImage(UIImage.init(named: "CheckBoxChecked"), for: .normal)
                self.button4.backgroundColor = .white
                self.indicator1.isHidden = true
                self.indicator2.isHidden = true
                self.indicator3.isHidden = true
                self.indicator4.isHidden = true
                self.indicator4.stopAnimating()
            }
        }else if name == "CloseProgressView"{
            DispatchQueue.main.async {
                self.dismiss(animated: true)
            }
        }
    }
}
