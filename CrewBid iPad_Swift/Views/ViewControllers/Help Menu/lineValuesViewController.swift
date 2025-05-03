

import UIKit
import WebKit

class lineValuesViewController: UIViewController {

    @IBOutlet weak var webView: WKWebView!
    override func viewDidLoad() {
        super.viewDidLoad()

        loadWebView()
        
    }
    
    @IBAction func btnBackAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func btnDoneAction(_ sender: Any) {
        self.dismiss(animated: false, completion: nil)
    }
    
    func loadWebView() {
        if let path = Bundle.main.path(forResource: "LineValues", ofType: "pdf") {
            let targetURL = URL(fileURLWithPath: path)
            let request = URLRequest(url: targetURL)
            webView.load(request)
        }
        
    }
   

}
