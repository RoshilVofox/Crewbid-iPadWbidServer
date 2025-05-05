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
    
}
