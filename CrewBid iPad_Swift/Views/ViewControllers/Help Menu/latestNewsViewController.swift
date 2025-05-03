
import UIKit
import WebKit

class latestNewsViewController: UIViewController {

    @IBOutlet weak var webView: WKWebView!
    override func viewDidLoad() {
        super.viewDidLoad()

        loadWebView()
        
    }
    @IBAction func btnDoneAction(_ sender: Any) {
        self.dismiss(animated: false, completion: nil)
    }
    
    @IBAction func btnBackAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func loadWebView() {
        if let path = Bundle.main.path(forResource: "LatestNewssdsds", ofType: "pdf") {
            let targetURL = URL(fileURLWithPath: path)
            let request = URLRequest(url: targetURL)
            webView.load(request)
        }
    }

}
