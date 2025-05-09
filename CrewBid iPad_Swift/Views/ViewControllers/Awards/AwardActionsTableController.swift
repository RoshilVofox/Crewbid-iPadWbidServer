//
//  AwardActionsTableController.swift
//  CrewBid iPad_Swift
//
//  Created by Developer on 18/04/25.
//

import UIKit

class AwardActionsTableController: UIViewController, KUIPopOverUsable {
    
    var contentSize: CGSize {
        return CGSize(width: 300, height: 300)
    }
    
    var awardACtionArray = ["Email Bid Awards","Print Bid Awards","Show Awarded Line","Add Awarded Line to Calendar"]
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
}


extension AwardActionsTableController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return awardACtionArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = awardACtionArray[indexPath.row]
        cell.textLabel?.font = .boldSystemFont(ofSize: 17)
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = awardACtionArray[indexPath.row]
        if item == "Show Awarded Line" {
            if let presentingVC = self.presentingViewController {
                self.dismiss(animated: true) {
                    let storyboard = UIStoryboard(name: "BidActions", bundle: nil)
                    let vc = storyboard.instantiateViewController(withIdentifier: "EmbeddedAwardEmpValidationVC") as! EmbeddedAwardEmpValidationVC
                    vc.preferredContentSize = CGSize(width: 600, height: 500)
                    presentingVC.present(vc, animated: true)
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
}


