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
    static func showDBAlert(title: String?, message: String? = nil, attributedMessage: NSAttributedString? = nil, from viewController: UIViewController) {
        let storyboard = UIStoryboard(name: "BidInfo", bundle: nil)
        guard let alertVC = storyboard.instantiateViewController(withIdentifier: "CBAlertVC") as? CBAlertVC else {
            return}
        alertVC.modalPresentationStyle = .formSheet
        alertVC.modalTransitionStyle = .crossDissolve
        alertVC.alertTitle = title
        if let attributedMessage = attributedMessage {
                alertVC.attributedMessage = attributedMessage
            } else if let message = message {
                let paragraphStyle = NSMutableParagraphStyle()
                    paragraphStyle.alignment = .center  // Center align
                    let attrs: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 18, weight: .regular), // Bigger font
                        .paragraphStyle: paragraphStyle
                    ]
                    alertVC.attributedMessage = NSAttributedString(string: message, attributes: attrs)
                alertVC.isSimpleAlert = true
            }
        alertVC.fromView = viewController
        alertVC.preferredContentSize = CGSize(width: 600, height: 500)
        viewController.present(alertVC, animated: true)
    }
    
    
    static func getAttributedMessage(from text: String, highlight: String? = nil) -> NSMutableAttributedString {
        let messageFont = UIFont.systemFont(ofSize: 20)
        let boldFont = UIFont.boldSystemFont(ofSize: 24)
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let attributedString = NSMutableAttributedString(string: text)
        let fullRange = NSRange(location: 0, length: (text as NSString).length)
        
        attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: fullRange)
        attributedString.addAttribute(.font, value: messageFont, range: fullRange)
        
        if let highlight = highlight, !highlight.isEmpty {
            let boldRange = (text as NSString).range(of: highlight)
            if boldRange.location != NSNotFound {
                attributedString.addAttribute(.font, value: boldFont, range: boldRange)
            }
        }
        
        return attributedString
    }
    
    static func showAlertForTopVC(
            title: String?,
            message: String?,
            actions: [(title: String, style: UIAlertAction.Style, handler: ((UIAlertAction, [UITextField]?) -> Void)?)]? = nil,
            textFields: [(placeholder: String, keyboardType: UIKeyboardType, tag: Int, delegate: UITextFieldDelegate?)]? = nil
        ) {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

            // Add text fields if provided
            if let tfArray = textFields {
                for tfData in tfArray {
                    alert.addTextField { textField in
                        textField.placeholder = tfData.placeholder
                        textField.keyboardType = tfData.keyboardType
                        textField.tag = tfData.tag
                        textField.delegate = tfData.delegate
                    }
                }
            }

            // Add actions
            if let actionArray = actions, !actionArray.isEmpty {
                for actionData in actionArray {
                    let action = UIAlertAction(
                        title: actionData.title,
                        style: actionData.style,
                        handler: { alertAction in
                            actionData.handler?(alertAction, alert.textFields)
                        }
                    )
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

        /// Backward-compatible version (keeps old signature)
        static func showAlertForTopVC(
            title: String?,
            message: String?,
            actions: [(title: String, style: UIAlertAction.Style, handler: ((UIAlertAction) -> Void)?)]?
        ) {
            let convertedActions = actions?.map { action -> (title: String, style: UIAlertAction.Style, handler: ((UIAlertAction, [UITextField]?) -> Void)?) in
                return (
                    title: action.title,
                    style: action.style,
                    handler: { alertAction, _ in
                        action.handler?(alertAction)
                    }
                )
            }

            showAlertForTopVC(title: title, message: message, actions: convertedActions, textFields: nil)
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
