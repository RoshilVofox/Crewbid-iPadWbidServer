//
//  ViewController.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 18/03/25.
//

import UIKit

class BaseViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    func shakeTextField(textField: UITextField){
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.07
        animation.repeatCount = 3
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint(x: textField.center.x - 10, y: textField.center.y))
        animation.toValue = NSValue(cgPoint: CGPoint(x: textField.center.x + 10, y: textField.center.y))
        textField.layer.add(animation, forKey: "position")
        textField.attributedPlaceholder = NSAttributedString(string: textField.placeholder ?? "",
                                                             attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])
    }
    func dismissFn() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.dismiss(animated: false, completion: nil)
        }
    }
    
    
    // Function to modify a user ID by adding a prefix if needed.
    func getUserIdAfterValidation(userId: String) -> String {
        // Check the first letter of the user ID.
         // If it doesn't have a prefix, add one.
        let firstLetter = userId.prefix(1).description
        if firstLetter == "x" || firstLetter == "e" {
            return userId
        } else {
            return "e" + userId
        }
    }
    
    func showQuickTutorialForFirstTime(){
        let vc = UIStoryboard(name: "HelpMenu", bundle: nil).instantiateViewController(withIdentifier: "quickTutorialViewController") as! quickTutorialViewController
        vc.preferredContentSize = CGSize(width: 764, height: 630)
        present(vc, animated: true)
        UserDefaults.standard.set(true, forKey: "isFirstLaunch")
    }
    
}

