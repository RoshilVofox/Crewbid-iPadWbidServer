
import UIKit
import WebKit

class CBNewsController: BaseViewController, WKNavigationDelegate,WKUIDelegate {

    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var btnBack: UIButton!
    @IBOutlet weak var btnDone: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.webView.navigationDelegate = self
        self.webView.uiDelegate = self
        loadLatestNews()
    }
    
    @IBAction func btnDoneAction(_ sender: Any) {
        CBGlobalMethods.shared.hideActivityIndicator()
        self.dismiss(animated: true) {
            NotificationCenter.default.post(name: NSNotification.Name("DidDismissLatestNews"), object: nil)
        }
        
    }
    
    @IBAction func btnBackAction(_ sender: Any) {
        CBGlobalMethods.shared.hideActivityIndicator()
        self.navigationController?.popViewController(animated: true)
    }

    
    func loadLatestNews() {
        let fileURL = getLatestNewsFilePath()
        let directoryURL = fileURL.deletingLastPathComponent()
        webView.navigationDelegate = self

        if FileManager.default.fileExists(atPath: fileURL.path) {
            webView.loadFileURL(fileURL, allowingReadAccessTo: directoryURL)
        } else {
            if let bundlePath = Bundle.main.url(forResource: "LatestNews", withExtension: "pdf") {
                let bundleDir = bundlePath.deletingLastPathComponent()
                webView.loadFileURL(bundlePath, allowingReadAccessTo: bundleDir)
            } else {
                print("Could not find LatestNews.pdf in app bundle.")
            }
        }
    }
    
    
    //MARK: getLatestNewsFilePath
    func getLatestNewsFilePath() -> URL {
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            return documentsDir.appendingPathComponent("LatestNews.pdf")
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
}
