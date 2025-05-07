//
//  CBRulesMenuTableVC.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 25/03/25.
//

import UIKit
import CoreData

protocol CBRulesMenuFilterDelegate: AnyObject {
    func filterSelected(filter: NSDictionary)
}

class CBRulesMenuTableVC: UIViewController,UITableViewDelegate,UITableViewDataSource,KUIPopOverUsable {
    private var kCellReuseIdentifier = "menuCell"
    var menuItems = NSArray()
    var disabledCellIndexPaths = NSArray()
    var arrowDirection: UIPopoverArrowDirection = UIPopoverArrowDirection.right

    weak var delegate: AnyObject?
    var contentSize: CGSize {
        var height : CGFloat = 40 * CGFloat(self.menuItems.count)
        if height > 700 {
            height = 700
        }
        preferredContentSize = CGSize(width: 310, height: height + 30)
        return CGSize(width: preferredContentSize.width, height: preferredContentSize.height)
    }
    

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: kCellReuseIdentifier)
        self.tableView.separatorInset = .zero
        self.tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var title:String?
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: kCellReuseIdentifier, for: indexPath)
        let item: NSDictionary = menuItems[indexPath.row] as! NSDictionary
        title = item.object(forKey: "title") as? String
        if title == nil {
            title = item.object(forKey: "name") as? String
        }
        let types = item["types"] as? [Any]
        if (types != nil && types!.count > 0) {
            cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
        } else {
            cell.accessoryType = UITableViewCell.AccessoryType.none
        }
        cell.textLabel?.text = title!
        cell.selectionStyle = .gray
        
       
        
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
  
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            let item:NSDictionary = menuItems[indexPath.row] as! NSDictionary
            let types:NSArray?
            types = item.object(forKey: "types") as? NSArray
            var category:Int = 0
            let categoryAny = item.object(forKey: "category")
            if (categoryAny != nil) {
                category = (item.object(forKey: "category") as? Int)!
            }
            
            var title:String?
            title = item.object(forKey: "title") as? String
            if title == nil {
                title = item.object(forKey: "name") as? String
            }
            selectFilterMenuAt(indexPath: indexPath, with: category, and: types)
        
    }
    func selectFilterMenuAt(indexPath: IndexPath, with category: Int, and types: NSArray?) {
        let item  = menuItems.object(at: indexPath.row) as! [String: Any]
        if let types = types as? [Any], !types.isEmpty {
            let storyboard = UIStoryboard(name: "Filter", bundle: nil)
            let subRulesTableVC = storyboard.instantiateViewController(withIdentifier: "CBRulesMenuTableVC") as! CBRulesMenuTableVC
            subRulesTableVC.menuItems = types as NSArray
            subRulesTableVC.title = item["title"] as? String
            subRulesTableVC.navigationItem.title = item["title"] as? String
            subRulesTableVC.navigationController?.navigationBar.prefersLargeTitles = false
            subRulesTableVC.delegate = delegate
            navigationController?.pushViewController(subRulesTableVC, animated: true)
        } else {
//            MARK: in the case of commute auto
            if item["name"] as? String == "Commuting - Auto" {
                print("commute auto")
                if let presentingVC = self.presentingViewController {
                    self.dismiss(animated: true) {
                        let storyboard = UIStoryboard(name: "BidDocument", bundle: nil)
                        let vc = storyboard.instantiateViewController(withIdentifier: "CommuteInformation") as! CBCommuteInfoViewController
                        vc.preferredContentSize = CGSize(width: 320, height: 320)
                        presentingVC.present(vc, animated: true)
                    }
                }
                return
                
            }
            //MARK: Used delegate method, needed to be removed when using actual data
            if let delegate = delegate as? CBRulesMenuFilterDelegate {
                delegate.filterSelected(filter: item as NSDictionary)
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
}
