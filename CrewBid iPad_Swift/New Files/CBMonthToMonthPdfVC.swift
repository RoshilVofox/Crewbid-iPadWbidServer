//
//  CBMonthToMonthPdfVC.swift
//  CrewBid iPad_Swift
//
//  Created by Rishad on 23/08/25.
//

import UIKit
import WebKit

class CBMonthToMonthPdfVC: UIViewController, WKNavigationDelegate {
    
    @IBOutlet var wkWebView: WKWebView!
    var urlString: String?
    var titles: String?
    @IBOutlet weak var titleLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.showActivityIndicator(color: .gray)
        // Check if a valid URL string is provided
        if let urlString = urlString,
            let encodedData = urlString.data(using: .utf8),
           let percentEncodedURLString = URL(dataRepresentation: encodedData, relativeTo: nil)?.relativeString,
            let url = URL(string: percentEncodedURLString) {
            
            let request = URLRequest(url: url)
            wkWebView.navigationDelegate = self
            wkWebView.load(request)
            DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                self.view.hideActivityIndicator()
            }
        }
    }
    
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

}
