//
//  ViewController.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 18/03/25.
//

import UIKit

class BaseViewController: UIViewController {
    var app = UIApplication.shared.delegate as! AppDelegate
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
            self.dismiss(animated: true, completion: nil)
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
        UserDefaults.standard.set("1200", forKey: KCBCustomizedHerbValue)
        let vc = UIStoryboard(name: "HelpMenu", bundle: nil).instantiateViewController(withIdentifier: "quickTutorialViewController") as! quickTutorialViewController
        vc.preferredContentSize = CGSize(width: 764, height: 630)
        present(vc, animated: true)
        UserDefaults.standard.set(true, forKey: "isFirstLaunch")
    }
    
}

extension UIViewController {

    func showToast(message: String, duration: TimeInterval = 2.0) {
        let toastLabel = UILabel()
        toastLabel.text = message
        toastLabel.textAlignment = .center
        toastLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        toastLabel.numberOfLines = 0
        toastLabel.alpha = 0.0
        toastLabel.layer.cornerRadius = 10
        toastLabel.clipsToBounds = true
        toastLabel.textColor = .label
        toastLabel.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.95)

        let maxWidthPercentage: CGFloat = 0.85
        let maxTitleSize = CGSize(
            width: view.bounds.width * maxWidthPercentage,
            height: view.bounds.height
        )

        var expectedSize = toastLabel.sizeThatFits(maxTitleSize)
        expectedSize.width += 28
        expectedSize.height += 20

        toastLabel.frame = CGRect(
            x: (view.bounds.width - expectedSize.width) / 2,
            y: view.bounds.height - expectedSize.height - 110,
            width: expectedSize.width,
            height: expectedSize.height
        )

        view.addSubview(toastLabel)

        UIView.animate(withDuration: 0.25) {
            toastLabel.alpha = 1.0
        } completion: { _ in
            UIView.animate(
                withDuration: 0.25,
                delay: duration,
                options: .curveEaseOut
            ) {
                toastLabel.alpha = 0.0
            } completion: { _ in
                toastLabel.removeFromSuperview()
            }
        }
    }
}
