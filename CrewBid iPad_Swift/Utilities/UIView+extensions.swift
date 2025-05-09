//
//  UIView+extensions.swift
//  CrewBid iPad_Swift
//
//  Created by Raja on 09/05/25.
//

import Foundation

extension UIView {
    
    func showActivityIndicator(color: UIColor? = CBColor.cbPurpleColor ,message: String? = "loading..." ) {
        MBProgressHUD.showAdded(to: self, animated: true, title: message, backgroundColor: color)
    }
    
    func hideActivityIndicator() {
        MBProgressHUD.hide(for: self, animated: true)
    }
}
