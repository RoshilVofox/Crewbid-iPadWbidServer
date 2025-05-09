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
    @IBOutlet weak var btnClose: UIButton!
    @IBOutlet weak var btnShare: UIButton!
    var type: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    func setupUI() {
        btnClose.setTitle("", for: .normal)
        btnShare.setTitle("", for: .normal)
        if type == "Seniority List" {
            lblTitle.text = "Seniority List"
            searchBar.backgroundColor = .white
            searchBar.isHidden = false
        }
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
