

import UIKit
import WebKit

class faqViewController: UIViewController {

    
    @IBOutlet weak var webView: WKWebView!
    override func viewDidLoad() {
        super.viewDidLoad()

        loadWebView()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func btnBackAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func btnDoneAction(_ sender: Any) {
        self.dismiss(animated: false, completion: nil)
    }
    func loadWebView() {
        if let path = Bundle.main.path(forResource: "FAQs", ofType: "pdf") {
            let targetURL = URL(fileURLWithPath: path)
            let request = URLRequest(url: targetURL)
            webView.load(request)
        }
    }

}
