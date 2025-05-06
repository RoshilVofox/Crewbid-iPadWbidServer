//
//  CBLineValuesMenuController.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 16/04/25.
//

import UIKit

class CBLineValuesMenuController: BaseViewController,UITableViewDelegate,UITableViewDataSource,KUIPopOverUsable {

    

    

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var resetButton: UIButton!
    
    
    var lineValuesTemp:NSArray!
    
    var selectedValuesCount: Int = 0
    var lineValues = [Any]()
    weak var bidPeriod: BIBidPeriod?
    var menuItems = [Any]()
    
    
    var count = 0
    
    
    var contentSize: CGSize {
        return CGSize(width: 310.0, height: UIScreen.main.bounds.height - 120)
    }

    var arrowDirection: UIPopoverArrowDirection {
        return .left
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        lineValuesTemp = getLineValues()
        self.navigationController?.navigationBar.isHidden = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        self.tableView.separatorStyle = .singleLine
        self.tableView.allowsMultipleSelection = true
        
// ----------------------------------
        lineValues = lineValues1()
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return lineValuesTemp.count
        return lineValues.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
//        let value = lineValuesTemp[indexPath.row] as! NSDictionary
        let value = lineValues[indexPath.row] as! NSDictionary
        let title = value["name"] as? String
        cell.textLabel?.text = title
        cell.selectionStyle = .none
        if (cell.isSelected) {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if count < 5{
            tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
            count += 1
        }
        else{
            tableView.deselectRow(at: indexPath, animated: true)
            let alert = UIAlertController(title: "Cannot select more than 5 values.", message: "Please deselect values before adding new ones.", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.accessoryType = .none
        count -= 1
    }
    
    @IBAction func resetAction(_ sender: Any) {
        
    }
    func lineValues1() -> [Any] {
        var values: [Any]? = nil
        let path = Bundle.main.path(forResource: "LineValues", ofType: "plist")
        let valueDictionary = NSDictionary(contentsOfFile: path!)
        values = valueDictionary?["values"] as? [Any] ?? [Any]()
//        if CBSwaptimizerStatus.enabled.rawValue == Int(truncating: (bidPeriod?.swaptimizerStatus)!) || BIFaVacationStatus.enabled.rawValue == Int(truncating: (bidPeriod?.faVacationStatus)!) {
//            let swaptimizerFileURL = Bundle.main.path(forResource: "LineValuesVacation", ofType: "plist")
//            let swapValuesDictionary = NSDictionary(contentsOfFile: swaptimizerFileURL!)
//            var swapValuesArray = swapValuesDictionary?["values"] as? [Any]
//            if ((self.bidPeriod!.fvVacationArrayFromServer?.count ?? 0) > 0){
//                swapValuesArray?.remove(at: 3)
//            }
//            values = swapValuesArray! + values!
//        }
        return values!
    }
    
    func getLineValues() -> NSArray {
        var values: NSArray!
        let path = Bundle.main.path(forResource: "LineValues", ofType: "plist")
        let valueDictionary = NSMutableDictionary(contentsOfFile: path!)!
        values = (valueDictionary["values"]! as! NSArray)
        return values! as NSArray
    }

    
    
    
    
   
    
}
