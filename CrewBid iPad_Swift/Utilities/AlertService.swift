//
//  AlertHelper.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 05/05/25.
//

import Foundation

class AlertService{
    
    static func showAlert(title: String?,
                           message: String?,
                           actions: [(title: String, style: UIAlertAction.Style, handler: ((UIAlertAction) -> Void)?)]?) -> UIAlertController
    {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        if let actionArray = actions, !actionArray.isEmpty {
            for actionData in actionArray {
                let action = UIAlertAction(title: actionData.title, style: actionData.style, handler: actionData.handler)
                alert.addAction(action)
            }
            return alert
        }else{
            let action = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(action)
            return alert
        }
    }
    static func showDBAlert(title: String?, attributedMessage: NSAttributedString?, from viewController: UIViewController) {
        let storyboard = UIStoryboard(name: "BidInfo", bundle: nil)
        guard let alertVC = storyboard.instantiateViewController(withIdentifier: "CBAlertVC") as? CBAlertVC else {
            return}
        alertVC.modalPresentationStyle = .currentContext
        alertVC.modalTransitionStyle = .coverVertical
        alertVC.alertTitle = title
        alertVC.attributedMessage = attributedMessage
        alertVC.fromView = viewController
        viewController.present(alertVC, animated: true)
    }
    
    
    static func getAttributedMessage(from text: String, highlight: String) -> NSMutableAttributedString {
        let messageFont = UIFont.systemFont(ofSize: 20)
        let boldFont = UIFont.boldSystemFont(ofSize: 24)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let fullRange = NSRange(location: 0, length: (text as NSString).length)
        let boldRange = (text as NSString).range(of: highlight)
        let attributedString = NSMutableAttributedString(string: text)
        attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: fullRange)
        attributedString.addAttribute(.font, value: messageFont, range: fullRange)

        if boldRange.location != NSNotFound {
            attributedString.addAttribute(.font, value: boldFont, range: boldRange)
        }
        return attributedString
    }
    
    static func showAlertForTopVC(
        title: String?,
        message: String?,
        actions: [(title: String, style: UIAlertAction.Style, handler: ((UIAlertAction) -> Void)?)]? = nil
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        if let actionArray = actions, !actionArray.isEmpty {
            for actionData in actionArray {
                let action = UIAlertAction(title: actionData.title, style: actionData.style, handler: actionData.handler)
                alert.addAction(action)
            }
        } else {
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
        }
        
        DispatchQueue.main.async {
            if let currentTopVC = currentTopViewController() {
                currentTopVC.present(alert, animated: true, completion: nil)
            }
        }
    }


    
    static func currentTopViewController() -> UIViewController? {
        // Get the connected scenes
        guard let windowScene = UIApplication.shared.connectedScenes
                .filter({ $0.activationState == .foregroundActive })
                .compactMap({ $0 as? UIWindowScene })
                .first,
              let window = windowScene.windows
                .first(where: { $0.isKeyWindow }),
              var topController = window.rootViewController else {
            return nil
        }
        
        // Traverse presented view controllers
        while let presentedVC = topController.presentedViewController {
            topController = presentedVC
        }
        
        return topController
    }


}
