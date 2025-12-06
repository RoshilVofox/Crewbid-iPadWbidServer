

import UIKit
import WebKit

class faqViewController: UIViewController {

    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var btnDone: UIButton!
    @IBOutlet weak var btnBack: UIButton!
    var isVacation = false
    override func viewDidLoad() {
        super.viewDidLoad()

       setupUI()
    }
    
    func setupUI() {
        loadWebView()
        btnBack.setTitle("", for: .normal)
        btnDone.setTitle("", for: .normal)
    }
    
    @IBAction func btnBackAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func btnDoneAction(_ sender: Any) {
        self.dismiss(animated: false, completion: nil)
    }
    func loadWebView() {
        if isVacation {
            let path = Bundle.main.path(forResource: "SWAPtimizerFAQ", ofType: "pdf")!
            let targetURL = URL(fileURLWithPath: path)
            let request = URLRequest(url: targetURL)
            webView.load(request)
        }
        else {
            if let path = Bundle.main.path(forResource: "FAQs", ofType: "pdf") {
                let targetURL = URL(fileURLWithPath: path)
                let request = URLRequest(url: targetURL)
                webView.load(request)
            }
        }
    }

}
