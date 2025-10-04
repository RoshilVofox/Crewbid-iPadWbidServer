//
//  UIView+extensions.swift
//  CrewBid iPad_Swift
//
//  Created by Raja on 09/05/25.
//

import Foundation

extension UIView {
    
    func showActivityIndicator(color: UIColor? = CBColor.cbPurpleColor ,message: String? = "Loading..." ) {
        MBProgressHUD.showAdded(to: self, animated: true, title: message, backgroundColor: color)
    }
    
    func hideActivityIndicator() {
        MBProgressHUD.hide(for: self, animated: true)
    }
    
    func updateActivityIndicator(message: String) {
        DispatchQueue.main.async {
            MBProgressHUD.forView(self)?.label.text = message
        }
    }
}
