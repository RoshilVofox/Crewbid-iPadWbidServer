//
//  CBLicenseVC.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 05/10/25.
//

import UIKit
import WebKit

class CBLicenseVC: BaseViewController, WKNavigationDelegate {

    @IBOutlet weak var webView: WKWebView!
    override func viewDidLoad() {
        super.viewDidLoad()
        loadLicenseAgreement()
    }
    
    func loadLicenseAgreement(){
        let path = Bundle.main.path(forResource: "CrewBid License Agreement", ofType: "pdf")!
        let targetUrl = URL(fileURLWithPath: path)
        webView.loadFileURL(targetUrl, allowingReadAccessTo: targetUrl)
        webView.navigationDelegate = self
    }
  
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("Started to load")
        CBGlobalMethods.shared.showActivityIndicator(bgColor: .purple)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("Finished loading")
        CBGlobalMethods.shared.hideActivityIndicator()
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        CBGlobalMethods.shared.hideActivityIndicator()
        print(error.localizedDescription)
    }
    
    @IBAction func okBtnAction(_ sender: Any) {
        CBGlobalMethods.shared.hideActivityIndicator()
        self.dismiss(animated: true)
    }
}
