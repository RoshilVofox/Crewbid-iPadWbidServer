//
//  CBMenuTableVC.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 25/03/25.
//

import UIKit

class CBMenuTableVC: UIViewController, UITableViewDataSource, UITableViewDelegate, KUIPopOverUsable {

    
    @IBOutlet weak var tableView: UITableView!
    public var menuItems = NSArray()
    public var delegate: CBMenuTableViewControllerDelegate?
    public var selectedItems: NSMutableSet = []
    public var scrollToIndexPath: IndexPath!
    public var width: CGFloat = 75
    var kCellReuseIdentifier = "menuCell"
    var lineSort: BILineSort?
    
    var contentSize: CGSize {
        var size: CGSize?
        size = CGSize(width: self.width, height: CGFloat(self.menuItems.count * 44))
        return size!
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if self.tableView.responds(to: #selector(getter: self.tableView.separatorInset)) {
            self.tableView.separatorInset = .zero
        }
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: kCellReuseIdentifier)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        adjustContentInset()
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if self.lineSort?.category?.intValue != BILineSortCategory.BIDeadheadsLineSortCategory.rawValue {
            self.delegate?.menuTableViewControllerCitySelection(menuController: self, selectedCities: selectedItems)
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: kCellReuseIdentifier, for: indexPath)
        cell.textLabel?.text = "\(self.menuItems[indexPath.row])"
        cell.selectionStyle = UITableViewCell.SelectionStyle.gray
        if selectedItems.count > 0 {
            if self.selectedItems.contains(self.menuItems[indexPath.row]) {
                cell.accessoryType = UITableViewCell.AccessoryType.checkmark
            }
            else {
                cell.accessoryType = UITableViewCell.AccessoryType.none
            }
        }
        else {
            cell.accessoryType = UITableViewCell.AccessoryType.none
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.lineSort?.category?.intValue == BILineSortCategory.BIDeadheadsLineSortCategory.rawValue {
            if self.delegate != nil {
                self.delegate?.menuTableViewController(menuController: self, didSelectRowAtIndexPath: indexPath)
            }
        }
        else {
            if self.selectedItems.contains(self.menuItems[indexPath.row]) {
                self.selectedItems.remove(self.menuItems[indexPath.row])
            }
            else {
                self.selectedItems.add(self.menuItems[indexPath.row])
            }
            self.tableView.reloadData()
        }
    }
    
    func scrollToIndexPath(indexPath: IndexPath) {
        tableView.scrollToRow(at: indexPath, at: UITableView.ScrollPosition.middle, animated: true)
    }
    
    private func adjustContentInset() {
        if self.menuItems.count == 1 {
            let tableViewHeight = self.tableView.frame.height
            let cellHeight: CGFloat = 44
            let inset = (tableViewHeight - cellHeight) / 2
            self.tableView.contentInset = UIEdgeInsets(top: inset, left: 0, bottom: inset, right: 0)
        } else {
            self.tableView.contentInset = .zero
        }
    }
}
