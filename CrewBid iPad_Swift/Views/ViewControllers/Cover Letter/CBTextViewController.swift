//
//  CBTextViewController.swift
//  CrewBid iPad_Swift
//
//  Created by Developer on 18/04/25.
//

import UIKit

class CBTextViewController: UIViewController {
    
    
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var txtView: UITextView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func btnDismissAction(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
  
    @IBAction func btnShareAction(_ sender: Any) {
    }
    
}

extension CBTextViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            cell.textLabel?.text = "Test"
            return cell
    }
}
