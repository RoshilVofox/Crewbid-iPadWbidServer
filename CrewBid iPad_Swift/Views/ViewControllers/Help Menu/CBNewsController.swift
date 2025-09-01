
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
        setupUI()
        loadLatestNews()
    }
    
    func setupUI() {
//        btnBack.setTitle("", for: .normal)
//        btnDone.setTitle("", for: .normal)
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
        let path = getLatestNewsFilePath()
        webView.loadFileURL(path, allowingReadAccessTo: path)
        webView.navigationDelegate = self
        if path.pathComponents.count == 0 {
            let path1 = Bundle.main.path(forResource: "LatestNews", ofType: "pdf")!
            let targetUrl = URL(fileURLWithPath: path1)
            webView.loadFileURL(targetUrl, allowingReadAccessTo: targetUrl)
            webView.navigationDelegate = self
        }
    }
    
    
    //MARK: getLatestNewsFilePath
    func getLatestNewsFilePath() -> URL {
        let paths: [Any] = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDir: String = paths[0] as? String ?? ""
        return URL(fileURLWithPath: documentsDir).appendingPathComponent("LatestNews.pdf")
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
