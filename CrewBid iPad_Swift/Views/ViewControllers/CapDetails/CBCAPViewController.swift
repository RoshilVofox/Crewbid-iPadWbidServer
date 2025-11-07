

import UIKit

class CBCAPViewController: BaseViewController {

    @IBOutlet weak var prevMonthLabel: UILabel!
    @IBOutlet weak var currentMonthLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    var dict : [String:Any]?
    var arrCAPList: NSArray?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showData()
        let currentDate = Date()
        let cal = Calendar(identifier: .gregorian)
        let comp = cal.dateComponents([.day,.month,.year], from: currentDate)
        let month = comp.month ?? 0
        prevMonthLabel.text = CBGlobalMethods.shortMonthNameOf(monthInt: month)
        currentMonthLabel.text = CBGlobalMethods.shortMonthNameOf(monthInt: month + 1)
    }
    
    @IBAction func btnOkAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func showData(){
        if app.connectedToInternet(){
            self.fetchCAPData()
        }else{
            AlertService.showAlertForTopVC(title: "Network not available!", message: "Please check your Internet connection")
        }
    }
    
    func fetchCAPData(){
        self.view.showActivityIndicator(message: "Sending request...")
        var dateComp = DateComponents()
        dateComp.month = 1
        let cal = Calendar.current
        let newDate = cal.date(byAdding: dateComp,to: Date())
        let comp = cal.dateComponents([.day, .month, .year], from: newDate!)
        let month = comp.month
        let year = comp.year
        var dict = [String:Any]()
        dict["Month"] = NSNumber(value:month!)
        dict["Year"] = NSNumber(value: year!)
        let jsonData = try! JSONSerialization.data(withJSONObject: dict)
        let jsonString = String(data: jsonData, encoding: .utf8)
        let bodyData = jsonString!.data(using: .utf8)
        APIService.shared.fetch(
            urlString: EndPoint.shared.getCAPData,
            method: .POST,
            body: bodyData,
            headers: ["Content-Type":"application/x-www-form-urlencoded"],
            parse: {data in
                guard let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
                else {
                    throw Errors.decodingError
                }
                return jsonArray
            },
            completion: { result in
                DispatchQueue.main.sync {
                    self.view.hideActivityIndicator()
                    switch result {
                    case .success(let responseArray):
                        self.arrCAPList = responseArray as NSArray
                        self.tableView.reloadData()
                    case .failure(let error):
                        print(error)
                    }
                }
            })
        
    }
    
}


extension CBCAPViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.arrCAPList?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ShowCAPTableViewCell", for: indexPath) as! ShowCAPTableViewCell
        let currentMonthNum = (arrCAPList![indexPath.row] as? [String:Any])!["CurrentMonthCap"] as? NSNumber
        if currentMonthNum != nil {
            let floatVal = Float(truncating: currentMonthNum!)
            let formattedNum = String(format: "%.02f", floatVal)
            cell.lblNextMonth.text = formattedNum
        }else{
            cell.lblNextMonth.text = "null"
        }
        
        let prevMonthNum = (arrCAPList![indexPath.row] as? [String:Any])!["PreviousMonthCap"] as? NSNumber
        if prevMonthNum != nil {
            let floatVal = Float(truncating: prevMonthNum!)
            let formattedNum = String(format: "%.02f", floatVal)
            cell.lblThisMonth.text = formattedNum
        }else{
            cell.lblThisMonth.text = "null"
        }
        
        if let obj = (arrCAPList![indexPath.row] as? [String:Any])!["Domicile"] {
            cell.lblBase.text = "\(obj)"
        }
        if let obj = (arrCAPList![indexPath.row] as? [String:Any])!["Position"] {
            cell.lblSeat.text = "\(obj)"
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 35
    }
}
