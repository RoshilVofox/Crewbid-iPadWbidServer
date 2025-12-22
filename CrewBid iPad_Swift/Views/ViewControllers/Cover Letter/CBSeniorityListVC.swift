//
//  CBSeniorityListVC.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 22/12/25.
//

import UIKit

class CBSeniorityListVC: UIViewController {

    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var btnShare: UIButton!
    @IBOutlet weak var btnClose: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var bidInfoLbl: UILabel!
    
    var bidPeriod:BIBidPeriod?
    var isFromFirstTimeOpenBid = false
    var isSearchActive = false
    var listArray = [String]()
    var filteredSeniorityList = [SeniorityList]()
    var seniorityList:[SeniorityList]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchSeniorityData()
    }
    
    func bidInfoHeader() -> String{
        var bidInfo = ""
        if self.bidPeriod?.isFirstRoundBid() == true{
            bidInfo = String(format: "Southwest Airlines\nSeniority Bid List\n%@ -- %@, %d\n\n", self.bidPeriod?.base ?? "",
                CBUtils.fullMonthName(month: self.bidPeriod?.month?.intValue ?? 0),
                self.bidPeriod?.year?.intValue ?? 0)
        }else{
            bidInfo = String(format: "Southwest Airlines\n%@ %d\nReserve List %@ Base\n\n", CBUtils.fullMonthName(month: self.bidPeriod?.month?.intValue ?? 0), self.bidPeriod?.year?.intValue ?? 0, self.bidPeriod?.base ?? "")
        }
        
        return bidInfo
    }
    
    
    func setupUI(){
        tableView.keyboardDismissMode = .onDrag
        tableView.separatorStyle = .none
        tableView.separatorInset = .zero
        tableView.layoutMargins = .zero
        tableView.layer.cornerRadius = 5
        tableView.clipsToBounds = true
        textView.isHidden = true
        searchBar.isHidden = false
        searchBar.delegate = self
        self.lblTitle.text = "Seniority List"
        let font = UIFont(name: "Courier New Bold", size: 14)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 7.5

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font!,
            .paragraphStyle: paragraphStyle
        ]

        let attributedText = NSAttributedString(
            string: self.bidInfoHeader(),
            attributes: attributes
        )

        self.bidInfoLbl.attributedText = attributedText
        
        if #available(iOS 15.0, *) {
            searchBar.tintColor = .tintColor
        } else {
            searchBar.tintColor = .systemBlue
        }
    
        if #available(iOS 13.0, *) {
            searchBar.searchTextField.backgroundColor = .systemGray6
        }
    
        for view in searchBar.subviews.last!.subviews {
            if view.isKind(of: NSClassFromString("UISearchBarBackground")!) {
                view.alpha = 0
            }
        }
    }
    
    func fetchSeniorityData() {

        let set = bidPeriod?.seniorityList as? Set<SeniorityList> ?? []
        seniorityList = Array(set)

        filteredSeniorityList = (seniorityList?.sorted {
            ($0.baseSeniority?.intValue ?? 0) < ($1.baseSeniority?.intValue ?? 0)
        })!

        tableView.reloadData()
    }
    
    
    
    @IBAction func btnShareAction(_ sender: Any) {
        let storyboard = UIStoryboard(name: "BidActions", bundle: nil)
        let bidActionVC = storyboard.instantiateViewController(withIdentifier: "AwardActionsTableController") as! AwardActionsTableController
        bidActionVC.preferredContentSize = CGSize(width: 350, height: 160)
        bidActionVC.contentSize = CGSize(width: 350, height: 160)
        bidActionVC.titleText = self.lblTitle.text ?? ""
        bidActionVC.text = self.generateTextFileFromTableView()
        bidActionVC.dataTypeSelected = TextFileType.seniorityList
        bidActionVC.modalPresentationStyle = .popover
        bidActionVC.showPopover(sourceView: btnShare)
    }
    
    
    func generateTextFileFromTableView() -> String{
        var text = ""
        
        text.append(self.bidInfoHeader())
        
        let col0Width = self.bidPeriod!.isFirstRoundBid() ? 5 : 2
        let col1Width = 8   //Base Seq
        let col3Width = 32  //Name
        let col4Width = 7  //Emp ID
        let col5Width = 5  //Vacation left space
        
        let sortedSeniority = (seniorityList?.sorted {
            ($0.companySeniority?.intValue ?? 0) < ($1.companySeniority?.intValue ?? 0)
        })!
        
        for i in 0..<sortedSeniority.count{
            let emp = sortedSeniority[i]
            
            var baseSeq = ""
            var name = ""
            var empID = ""
            
            if self.bidPeriod?.isFirstRoundBid() == true{
                baseSeq = (emp.baseSeniority?.stringValue ?? "").padding(toLength: col1Width, withPad: " ", startingAt: 0)
                name = (emp.legalName?.uppercased() ?? "").padding(toLength: col3Width, withPad: " ", startingAt: 0)
                empID = "(\(emp.employeeId ?? ""))"
            }else{
                baseSeq = String(format: "%ld -", i+1).padding(toLength: col1Width, withPad: " ", startingAt: 0)
                name = (emp.legalName?.uppercased() ?? "").padding(toLength: col3Width, withPad: ".", startingAt: 0)
                empID = "[\(emp.employeeId ?? "")]"
            }
            
            let leftPadding = "".padding(toLength: col0Width, withPad: " ", startingAt: 0)
            let empIDWithSpace = empID.padding(toLength: col4Width, withPad: " ", startingAt: 0)
            let vacationLeftPadding = "".padding(toLength: col5Width, withPad: " ", startingAt: 0)
            let vacation = "\(emp.vacationString)"
            
            var rowString = ""
            
            if self.bidPeriod?.isFirstRoundBid() == true {
                if emp.vacationString == "N/A" {
                    rowString = "\(leftPadding)\(baseSeq)\(name)\(empIDWithSpace)\n"
                }else{
                    rowString = "\(leftPadding)\(baseSeq)\(name)\(empIDWithSpace)\(vacationLeftPadding)\(vacation)\n"
                }
            }else{
                rowString = "\(leftPadding)\(baseSeq)\(name)\(empIDWithSpace)\n"
            }
            text.append(rowString)
        }
        
//        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
//        let filename = "Seniority_\(self.bidPeriod?.base ?? "")\(self.bidPeriod?.year ?? 0)\(self.bidPeriod?.month ?? 0)\(self.bidPeriod?.round ?? 1).txt"
//        let fileURL = docs.appendingPathComponent(filename)
//
//        do {
//            try text.write(to: fileURL, atomically: true, encoding: .utf8)
//            return fileURL.path
//        } catch {
//            return nil
//        }
        return text
    }
    
    
    @IBAction func btnDismissAction(_ sender: Any) {
        self.dismiss(animated: true)
            if self.presentingViewController != nil {
                    self.dismiss(animated: true, completion: nil)
                } else {
                    let transition = CATransition()
                    transition.duration = 0.4
                    transition.type = .fade
                    transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

                    self.navigationController?.view.layer.add(transition, forKey: kCATransition)
                    self.navigationController?.popViewController(animated: false)
                    return
                }
            
            if self.bidPeriod?.isHistoric?.boolValue ?? false{
                return
            }
            

            if !(self.bidPeriod?.coverLetterDisplayed ?? 0).boolValue {
                let details = ["isFromFirstTimeOpenBid":true]
                NotificationCenter.default.post(name: NSNotification.Name(KCBOpenCoverletter), object: self,userInfo: details)
            return
            }
            
//            if isFromFirstTimeOpenBid == true {
//                self.dismiss(animated: false, completion: {
//                    CBGlobalMethods.shared.isLatestNewsDisplayed = true
//                    let storyboard = UIStoryboard(name: "HelpMenu", bundle: nil)
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                        if let rootVC = UIApplication.shared.windows.first?.rootViewController {
//                            let vc = storyboard.instantiateViewController(withIdentifier: "CBHelpMenuController") as! CBHelpMenuController
//                            vc.preferredContentSize = CGSize(width: 764, height: 630)
//                            vc.modalTransitionStyle = .crossDissolve
//                            vc.isModalInPresentation = true
//                            rootVC.present(vc, animated: false, completion: nil)
//                        }
//                    }
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//                        self.bidPeriod?.latestNewsDisplayed = true
//                        NotificationCenter.default.post(name: NSNotification.Name("goToLatestNews"), object: nil)
//                    }
//                })
//            }
    }
}

extension CBSeniorityListVC: UITableViewDelegate, UITableViewDataSource{
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.filteredSeniorityList.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return self.headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let seniority = self.filteredSeniorityList[indexPath.row]
        if tableView == self.tableView{
            if seniority.vacationString == "N/A"{
                return 35
            }else{
                return 54
            }
        }
        return 40
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CBSeniorityListTableViewCell") as! CBSeniorityListTableViewCell
        cell.selectionStyle = .none
        cell.layoutMargins = .zero
        cell.separatorInset = .zero
        let seniority = self.filteredSeniorityList[indexPath.row]
        if self.bidPeriod?.isFirstRoundBid() == true{
            cell.baseSeniorityLbl.text = String(format: "%@", seniority.baseSeniority?.stringValue ?? "")
            cell.empNumLbl.text = String(format: "(%@)", seniority.employeeId ?? "")
            cell.nameLbl.text = String(format: "%@", seniority.legalName?.uppercased() ?? "")
            if seniority.vacationString == "N/A"{
                cell.vacationTop.constant = 0
                cell.vacationLbl.text = ""
            }else{
                cell.vacationTop.constant = 5
                cell.vacationLbl.text = String(format: "%@", seniority.vacationString)
            }
        }else{
            cell.baseSeniorityLbl.text = String(format: "%ld - ", indexPath.row + 1)
            cell.empNumLbl.text = String(format: "[%@]", seniority.employeeId ?? "")
            cell.nameLbl.text = String(format: "%@......................", seniority.legalName?.uppercased() ?? "")
            cell.vacationTop.constant = 0
            cell.vacationLbl.text = ""
        }
        cell.nameLbl.adjustsFontSizeToFitWidth = false
        cell.nameLbl.lineBreakMode = .byClipping
        return cell
    }
    
    
}

extension CBSeniorityListVC : UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        isSearchActive = ((searchBar.text?.isEmpty) != nil) ? false : true
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        isSearchActive = false;
        
        searchBar.text = nil
        searchBar.resignFirstResponder()
        tableView.resignFirstResponder()
        self.searchBar.showsCancelButton = false
        tableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        return true
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard let seniorityList = seniorityList else {
            filteredSeniorityList = []
            tableView.reloadData()
            return
        }
        
        if searchText.isEmpty{
            filteredSeniorityList = seniorityList.sorted {
                ($0.baseSeniority?.intValue ?? 0) < ($1.baseSeniority?.intValue ?? 0)
            }
        }else{
//            let predicate = NSPredicate(format:"employeeId CONTAINS[cd] %@ OR " +
//                                        "legalName CONTAINS[cd] %@ OR " +
//                                        "vacation CONTAINS[cd] %@ OR " +
//                                        "baseSeniority.stringValue CONTAINS[cd] %@",
//                                        searchText, searchText, searchText, searchText)
//            // Filter with predicate
//            let array = (seniorityList as NSArray).filtered(using: predicate)
//
//            // Safely cast results back to [SeniorityList]
//            filteredSeniorityList = array.compactMap { $0 as? SeniorityList }
//
//            // Sort
//            filteredSeniorityList.sort { $0.baseSeniority!.intValue < $1.baseSeniority!.intValue }
            filteredSeniorityList = seniorityList.filter {
                $0.employeeId?.localizedCaseInsensitiveContains(searchText) == true ||
                $0.legalName?.localizedCaseInsensitiveContains(searchText) == true ||
                $0.vacationString.localizedCaseInsensitiveContains(searchText) ||
                $0.baseSeniority?.stringValue.localizedCaseInsensitiveContains(searchText) == true
            }
            .sorted { $0.baseSeniority?.intValue ?? 0 < $1.baseSeniority?.intValue ?? 0 }
        }
        self.tableView.reloadData()
        
        
        
//        self.isSearchActive = !searchText.isEmpty
//        self.searchBar.showsCancelButton = true
//        
//        filteredSeniorityList.removeAll()
//        var recurringIndex = 0
//        
//        for index in 0..<listArray.count {
//            
//                        if recurringIndex == index {
//                            recurringIndex = index + 1
//            
//                            let currentItem = listArray[index]
//                            let previousItem = (index > 0) ? listArray[index - 1] : nil
//            
//                            let nextIndex = (index < listArray.count-1) ? index + 1 : nil
//            
//                            if currentItem.lowercased().contains(searchText.lowercased()) {
//                                if let previous = previousItem {
//                                    if isStartsWithNumber(currentItem) == false {
//                                        filteredSeniorityList.append(previous)
//                                        filteredSeniorityList.append(currentItem)
//                                    } else {
//                                        filteredSeniorityList.append(currentItem)
//                                    }
//                                } else {
//                                    filteredSeniorityList.append(currentItem)
//                                }
//            
//                                if let nextIndex = nextIndex {
//                                    for j in nextIndex..<listArray.count {
//                                        let nextItem = listArray[j]
//                                        if isStartsWithNumber(nextItem) == false {
//                                            filteredSeniorityList.append(nextItem)
//                                        } else {
//                                            recurringIndex = j
//                                            break
//                                        }
//                                    }
//                                }
//                            }
//                        }
//                    }
//            self.tableView.reloadData()
//        }
    }
    
    func isStartsWithNumber(_ input: String) -> Bool {
        let trimmedInput = input.trimmingCharacters(in: .whitespaces)
        if let firstCharacter = trimmedInput.first, firstCharacter.isNumber {
            return true
        }
        return false
    }
}
