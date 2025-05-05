//
//  CBSortRulesMenuTableVC.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 25/03/25.
//

import UIKit

class CBSortRulesMenuTableVC: UIViewController,UITableViewDelegate,UITableViewDataSource,KUIPopOverUsable {

    @IBOutlet weak var tableView: UITableView!
    var menuItems = NSArray()
    private var kCellReuseIdentifier = "menuCell"
    var arrowDirection: UIPopoverArrowDirection = AppData.shared.isBidListSort == true ? UIPopoverArrowDirection.left : UIPopoverArrowDirection.right

    
    var contentSize: CGSize {
        var height : CGFloat = 40 * CGFloat(self.menuItems.count)
        if height > 700 {
            height = 700
        }
        preferredContentSize = CGSize(width: 310, height: height + 30)
        return CGSize(width: preferredContentSize.width, height: preferredContentSize.height)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: kCellReuseIdentifier)
        self.tableView.separatorInset = .zero
        self.tableView.reloadData()
        // Do any additional setup after loading the view.
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
        cell.selectionStyle = .none
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
        selectSortMenuAt(indexPath: indexPath, with: category, and: types)
    }
    func selectSortMenuAt(indexPath: IndexPath, with category: Int, and types: NSArray?) {
        let item  = menuItems.object(at: indexPath.row) as! [String: Any]
        if (types != nil) && ((types?.count)! > 0) {
            let storyboard : UIStoryboard = UIStoryboard(name: "Filter", bundle: nil)
            let subRulesTableViewController = storyboard.instantiateViewController(withIdentifier: "CBSortRulesMenuTableVC") as! CBSortRulesMenuTableVC
            subRulesTableViewController.menuItems = types!
            subRulesTableViewController.title = (item["title"] as! String)
            navigationController?.pushViewController(subRulesTableViewController, animated: true)
        }
    }
}
