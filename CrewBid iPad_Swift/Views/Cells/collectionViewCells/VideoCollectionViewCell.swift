

import UIKit
import WebKit

class VideoCollectionViewCell: UICollectionViewCell,WKNavigationDelegate {
    
    @IBOutlet weak var videoTitleLbl: UILabel!
    @IBOutlet weak var webView: WKWebView!
    
    //Below code was updated on Nov 3rd 2025 by Kripa
    private var currentVideoID: String?
    private let webViewTag = 122
    override func awakeFromNib() {
        super.awakeFromNib()
        if let existingWebView = webView {
            configureWebView(existingWebView)
        }
    }
    
    func loadVideo(videoID: String) {
        
        if currentVideoID == videoID { return }
        currentVideoID = videoID
        
        var webViewToUse: WKWebView?
        
        if let storyboardWebView = webView {
            webViewToUse = storyboardWebView
        } else {
            
            if let foundWebView = contentView.viewWithTag(webViewTag) as? WKWebView {
                webViewToUse = foundWebView
            } else {
                let config = WKWebViewConfiguration()
                config.allowsInlineMediaPlayback = true
                
                if #available(iOS 10.0, *) {
                    config.mediaTypesRequiringUserActionForPlayback = []
                }
                
                let newWebView = WKWebView(frame: contentView.bounds, configuration: config)
                newWebView.tag = webViewTag
                newWebView.scrollView.isScrollEnabled = false
                newWebView.scrollView.bounces = false
                newWebView.isOpaque = false
                newWebView.backgroundColor = .black
                
                contentView.addSubview(newWebView)
                webView = newWebView
                webViewToUse = newWebView
            }
        }
        
        guard let webView = webViewToUse else { return }
        
        
        let html = """
            <!DOCTYPE html><html><head><meta name="viewport" content="initial-scale=1.0, maximum-scale=1.0">
            <style>body,html{margin:0;padding:0;background:black;height:100%}#player{position:absolute;top:0;left:0;right:0;bottom:0}</style>
            </head><body>
            <div id='player'>
            <iframe width='100%' height='100%'
            src='https://www.youtube.com/embed/\(videoID)?playsinline=1&enablejsapi=1&rel=0&modestbranding=1'
            frameborder='0' allow='autoplay; encrypted-media; picture-in-picture' allowfullscreen
            referrerpolicy='strict-origin'></iframe>
            </div></body></html>
            """
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            webView.loadHTMLString(html, baseURL: URL(string: "https://youtube.com"))
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        currentVideoID = nil
        webView?.stopLoading()
    }
    
    private func configureWebView(_ webView: WKWebView) {
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.isOpaque = false
        webView.backgroundColor = .black
        
        webView.configuration.allowsInlineMediaPlayback = true
        
        if #available(iOS 10.0, *) {
            webView.configuration.mediaTypesRequiringUserActionForPlayback = []
        }
    }
}

