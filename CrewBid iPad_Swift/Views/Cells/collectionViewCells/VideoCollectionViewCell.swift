

import UIKit
import WebKit
import AVFoundation

class VideoCollectionViewCell: UICollectionViewCell,WKNavigationDelegate {
    
    @IBOutlet weak var videoTitleLbl: UILabel!
    @IBOutlet weak var webView: WKWebView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.webView.navigationDelegate = self
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("Started to load")
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("Finished loading")
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: any Error) {
        print(error.localizedDescription)
    }
}
