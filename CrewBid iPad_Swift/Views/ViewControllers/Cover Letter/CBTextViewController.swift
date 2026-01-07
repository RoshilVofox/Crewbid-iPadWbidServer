//
//  CBTextViewController.swift
//  CrewBid iPad_Swift
//
//  Created by Developer on 18/04/25.
//

import UIKit
import CoreData

class CBTextViewController: BaseViewController, UIPopoverPresentationControllerDelegate{
    
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var btnClose: UIButton!
    @IBOutlet weak var btnShare: UIButton!
    
    
    var tableViewTF: NMTextField!
    var msgLabel: UILabel!
    var bidPeriod: BIBidPeriod?
    var dataTypeSelected : TextFileType = .seniorityList
    var bidActionType : BidActionType = .BidActions
    var bidReceipt : BIBidReceipt?
    var awardData : String?
    public var titleText = String()
    public var text = String()
    public var textFile = String()
    var isFromFirstTimeOpenBid : Bool = false
    
    var actionsPopoverController: UIPopoverPresentationController?
    weak var actionsNavigationController: UINavigationController?
    
    var listArray = [String]()
    var filteredListArray = [String]()
    var isSearchActive : Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.clipsToBounds = true
        textView.layer.cornerRadius = 5
        tableView.clipsToBounds = true
        tableView.layer.cornerRadius = 5
        textAppending()
    }
    func textAppending() {
        textView.font = UIFont(name: "Courier New Bold", size: 15)
        
        switch dataTypeSelected {
            case .seniorityList:
                lblTitle.text = "Seniority List"
                titleText = "Seniority List"
            textView.text = self.bidPeriod?.textFile(withName: BISeniorityListTextFileName)?.text
                
                tableView.isHidden = false
                tableView.keyboardDismissMode = .onDrag
                textView.isHidden = true
                searchBar.isHidden = false
                searchBar.delegate = self
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
            
            if let lines = self.bidPeriod?.textFile(withName: BISeniorityListTextFileName)?.text {
                    for line in lines.components(separatedBy: "\n") {
                        listArray.append(String(line))
                    }
                    tableView.separatorStyle = .none
                    tableView.reloadData()
                }
            
                msgLabel = UILabel()
                msgLabel.text = "No seniority data found.\nTry with other keywords."
                msgLabel.font = UIFont.systemFont(ofSize: 22)
                msgLabel.textAlignment = .center
                msgLabel.numberOfLines = 0
                msgLabel.isHidden = true
                self.view.addSubview(msgLabel)
                self.view.bringSubviewToFront(msgLabel)
                msgLabel.translatesAutoresizingMaskIntoConstraints = false
            
                let leadingConstraint = msgLabel.leadingAnchor.constraint(equalTo: self.textView.leadingAnchor, constant: 20)
                let trailingConstraint = msgLabel.trailingAnchor.constraint(equalTo: self.textView.trailingAnchor, constant: -20)
                let topConstraint = msgLabel.topAnchor.constraint(equalTo: self.textView.topAnchor, constant: 100)
                let heightConstraint = NSLayoutConstraint(item: self.msgLabel!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 100.0)
                
                NSLayoutConstraint.activate([leadingConstraint, trailingConstraint, topConstraint, heightConstraint])
            
                break
            case .coverLetter:
                lblTitle.text = "Cover Letter"
                titleText = "Cover Letter"
                textView.text = self.bidPeriod?.textFile(withName: BICoverLetterTextFileName)?.text
                if self.bidPeriod!.coverLetterDisplayed?.boolValue != true {
                self.bidPeriod!.coverLetterDisplayed = NSNumber(booleanLiteral: true)
                try? self.bidPeriod?.managedObjectContext?.save()
            }
                break
            case .awardText:
                lblTitle.text = "Bid Awards"
                titleText = "Bid Awards"
                textView.text = self.bidPeriod?.awardString
                break
            case .faMemo:
                lblTitle.text = "FA Memo"
                titleText = "FA Memo"
                textView.text = self.bidPeriod?.textFile(withName: BIFaMemoTextFileName)?.text
                break
            case .tripText:
                lblTitle.text = "Trips Text"
                titleText = "Trips Text"
                textView.text = self.bidPeriod?.textFile(withName: BITripsTextFileName)?.text
                break
            case .lineText:
                lblTitle.text = "Lines Text"
                titleText = "Lines Text"
                textView.text = self.bidPeriod?.textFile(withName: BILinesTextFileName)?.text
                break
            case .bidReceipt:
                lblTitle.text = "Bid Receipt"
                titleText = "Bid Receipt"
            if let receiptText = self.bidReceipt?.condensedText{
                textView.attributedText = self.buildReceiptAttributedText(receiptText: receiptText)
            }
                break
        }
    }
    
    private func buildReceiptAttributedText(receiptText: String) -> NSMutableAttributedString {

        let attrBlank: [NSAttributedString.Key: Any] = [
            .backgroundColor: UIColor.systemBlue,
            .foregroundColor: UIColor.white,
            .strokeWidth: -3.0,
            .font: UIFont(name: "Courier", size: 15)!
        ]

        let attrReserve: [NSAttributedString.Key: Any] = [
            .backgroundColor: UIColor.systemRed,
            .foregroundColor: UIColor.white,
            .strokeWidth: -3.0,
            .font: UIFont(name: "Courier", size: 15)!
        ]

        let attrClear: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.label,
            .font: UIFont(name: "Courier", size: 15)!
        ]

        let condensedText = NSMutableAttributedString()

        var readFirstLine = true
        var readBidLineNumbers = false
        var readFinalLine = false
        var count = 0

        receiptText.enumerateLines { line, _ in

            if readFirstLine {
                condensedText.append(NSAttributedString(string: "\(line)\n", attributes: attrClear))
                readFirstLine = false
                readBidLineNumbers = true
                return
            }

            if readBidLineNumbers {

                if line == "*E" {
                    condensedText.append(NSAttributedString(string: "*E\n", attributes: attrClear))
                    readBidLineNumbers = false
                    readFinalLine = true
                    return
                }

                count += 1
                let padded = String(format: "%5s", line)

                var attrs = attrClear

                if let n = Int(line) {

                    let lineObj = self.fetchLine(lineNumber: n)

                    if lineObj?.orderedTrips.count == 0 {
                        attrs = attrBlank
                    }
                    else if let type = lineObj?.type?.intValue,
                            type == 3 || type == 6 || type == 12 {
                        attrs = attrReserve
                    }
                }

                condensedText.append(NSAttributedString(string: padded, attributes: attrs))

                if count % 10 == 0 {
                    condensedText.append(NSAttributedString(string: "\n", attributes: attrClear))
                }
                return
            }
            
            if readFinalLine {
                condensedText.append(
                    self.highlightedFinalLine(line: line,
                                         attrClear: attrClear,
                                         attrBlank: attrBlank,
                                         attrReserve: attrReserve)
                )
            }
        }

        return addLeftMarginToString(condensedText, leftMargin: 30)
    }
    
    
    private func fetchLine(lineNumber: Int) -> BILine? {
        let request = NSFetchRequest<BILine>(entityName: "Line")
        request.predicate = NSPredicate(format: "number == %@", NSNumber(value: lineNumber))
        request.sortDescriptors = [NSSortDescriptor(key: "number", ascending: true)]

        return try? bidPeriod?
            .managedObjectContext?
            .fetch(request)
            .first
    }
    private func highlightedFinalLine(
        line: String,
        attrClear: [NSAttributedString.Key: Any],
        attrBlank: [NSAttributedString.Key: Any],
        attrReserve: [NSAttributedString.Key: Any]
    ) -> NSAttributedString {

        let result = NSMutableAttributedString(
            string: "\(line)\n",
            attributes: attrClear
        )

        let regex = try? NSRegularExpression(pattern: "(\\d+)\\.(\\d+)")
        let matches = regex?.matches(
            in: line,
            range: NSRange(location: 0, length: line.count)
        ) ?? []

        for match in matches {
            guard match.numberOfRanges >= 3 else { continue }

            let nsLine = line as NSString
            let lineNumberString = nsLine.substring(with: match.range(at: 2))

            if let n = Int(lineNumberString),
               let lineObj = fetchLine(lineNumber: n) {

                var attrs = attrClear

                if lineObj.orderedTrips.count == 0 {
                    attrs = attrBlank
                }
                else if let type = lineObj.type?.intValue,
                        type == 3 || type == 6 || type == 12 {
                    attrs = attrReserve
                }

                result.addAttributes(attrs, range: match.range(at: 0))
            }
        }

        return result
    }
    
    func addLeftMarginToString(
        _ text: NSMutableAttributedString,
        leftMargin: CGFloat
    ) -> NSMutableAttributedString {

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.firstLineHeadIndent = leftMargin

        text.addAttribute(
            .paragraphStyle,
            value: paragraphStyle,
            range: NSRange(location: 0, length: text.length)
        )

        return text
    }
    
    
    
    @IBAction func btnDismissAction(_ sender: Any) {
        if self.presentingViewController != nil {
                self.dismiss(animated: true, completion: nil)
            } else {
                let transition = CATransition()
                transition.duration = 0.4
                transition.type = .fade
                transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

                self.navigationController?.view.layer.add(transition, forKey: kCATransition)
                self.navigationController?.popViewController(animated: false)
            }
        
        if self.bidPeriod?.isHistoric?.boolValue ?? false{
            return
        }
        
        if dataTypeSelected == .seniorityList {
            if !(self.bidPeriod?.coverLetterDisplayed ?? 0).boolValue {
                let details = ["isFromFirstTimeOpenBid":true]
                NotificationCenter.default.post(name: NSNotification.Name(KCBOpenCoverletter), object: self,userInfo: details)
                dataTypeSelected = .seniorityList
                return
            }
        }
        if isFromFirstTimeOpenBid == true {
            self.dismiss(animated: false, completion: {
                CBGlobalMethods.shared.isLatestNewsDisplayed = true
                let storyboard = UIStoryboard(name: "HelpMenu", bundle: nil)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if let rootVC = UIApplication.shared.windows.first?.rootViewController {
                        let vc = storyboard.instantiateViewController(withIdentifier: "CBHelpMenuController") as! CBHelpMenuController
                        vc.preferredContentSize = CGSize(width: 764, height: 630)
                        vc.modalTransitionStyle = .crossDissolve
                        vc.isModalInPresentation = true
                        rootVC.present(vc, animated: false, completion: nil)
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.bidPeriod?.latestNewsDisplayed = true
                    NotificationCenter.default.post(name: NSNotification.Name("goToLatestNews"), object: nil)
                }
            })
        }
    }
  
    @IBAction func btnShareAction(_ sender: Any) {
        let storyboard = UIStoryboard(name: "BidActions", bundle: nil)
        
        if self.dataTypeSelected == .awardText {
            let bidActionVC = storyboard.instantiateViewController(withIdentifier: "AwardActionsTableController") as! AwardActionsTableController
            bidActionVC.preferredContentSize = CGSize(width: 350, height: 260)
            bidActionVC.contentSize = CGSize(width: 350, height: 260)
            bidActionVC.title = self.titleText
            bidActionVC.text = textView.text
            bidActionVC.dataTypeSelected = TextFileType.awardText
            bidActionVC.modalPresentationStyle = .popover
            bidActionVC.showPopover(sourceView: btnShare)
        }
        
        else if self.dataTypeSelected == .tripText {
            let bidActionVC = storyboard.instantiateViewController(withIdentifier: "AwardActionsTableController") as! AwardActionsTableController
            bidActionVC.preferredContentSize = CGSize(width: 350, height: 210)
            bidActionVC.contentSize = CGSize(width: 350, height: 210)
            bidActionVC.title = self.titleText
            bidActionVC.text = textView.text
            bidActionVC.dataTypeSelected = TextFileType.tripText
            bidActionVC.modalPresentationStyle = .popover
            bidActionVC.showPopover(sourceView: btnShare)
        }
        
        else if self.dataTypeSelected == .lineText {
            let bidActionVC = storyboard.instantiateViewController(withIdentifier: "AwardActionsTableController") as! AwardActionsTableController
            bidActionVC.preferredContentSize = CGSize(width: 350, height: 260)
            bidActionVC.contentSize = CGSize(width: 350, height: 260)
            bidActionVC.title = self.titleText
            bidActionVC.text = textView.text
            bidActionVC.dataTypeSelected = TextFileType.lineText
            bidActionVC.modalPresentationStyle = .popover
            bidActionVC.showPopover(sourceView: btnShare)
        }
        else{
            let bidActionVC = storyboard.instantiateViewController(withIdentifier: "AwardActionsTableController") as! AwardActionsTableController
            bidActionVC.preferredContentSize = CGSize(width: 350, height: 160)
            bidActionVC.contentSize = CGSize(width: 350, height: 160)
            bidActionVC.title = self.titleText
            bidActionVC.attributedTxt = textView.attributedText
            bidActionVC.dataTypeSelected = self.dataTypeSelected
            bidActionVC.modalPresentationStyle = .popover
            bidActionVC.showPopover(sourceView: btnShare)
        }
        
        
    }
}

extension CBTextViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.tableView {
            if (self.isSearchActive) {
                if (msgLabel != nil) {
                    self.msgLabel.isHidden = (self.filteredListArray.count != 0);
                }
                return self.filteredListArray.count;
            } else {
                if (msgLabel != nil) {
                    self.msgLabel.isHidden = true;
                }
                return self.listArray.count;
            }
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == self.tableView {
            let cell = UITableViewCell()
            
            cell.selectionStyle = .none
            
            tableViewTF = NMTextField()
            tableViewTF.delegate = self
            tableViewTF.inputView = UIView()
            tableViewTF.inputAssistantItem.leadingBarButtonGroups = []
            tableViewTF.inputAssistantItem.trailingBarButtonGroups = []
            tableViewTF.autocorrectionType = .no
            
            tableViewTF.backgroundColor = UIColor.appColor(.contentBgColor)
            if #available(iOS 13.0, *) {
                tableViewTF.textColor = .label
            } else {
                tableViewTF.textColor = .black
            }
            if let courierFont = UIFont(name: "Courier New Bold", size: 16.0) {
                tableViewTF.font = courierFont
            }
            let data = isSearchActive ? filteredListArray[indexPath.row] : listArray[indexPath.row]
            tableViewTF.text = """
            \(data)
            """
            
            cell.contentView.addSubview(tableViewTF)
            tableViewTF.translatesAutoresizingMaskIntoConstraints = false
            
            let leadingConstraint = tableViewTF.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 0)
            let trailingConstraint = tableViewTF.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: 0)
            let topConstraint = tableViewTF.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 0)
            let bottomConstraint = tableViewTF.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: 0)
            
            NSLayoutConstraint.activate([leadingConstraint, trailingConstraint, topConstraint, bottomConstraint])
            
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == self.tableView {
            return 25
        }
        return 0
    }
    
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
            // Email is first cell.
        if tableView != self.tableView {
            if 0 == indexPath.row {
                cell.textLabel?.text = "Email \(title ?? "")"
                // Disable if unable to send email.
//                if MFMailComposeViewController.canSendMail() {
//                    cell.textLabel?.textColor = UIColor.lightGray
//                    cell.isUserInteractionEnabled = false
//                }
            }
            // Print is second cell.
            else if 1 == indexPath.row {
                cell.textLabel?.text = "Print \(title ?? "")"
                // Disable if unable to print.
                if !UIPrintInteractionController.isPrintingAvailable {
                    cell.textLabel?.textColor = UIColor.lightGray
                    cell.isUserInteractionEnabled = false
                }
            }
        }
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView != self.tableView {
            // Email is first cell.
//            if 0 == indexPath.row {
//                showEmailComposer()
//            } else if 1 == indexPath.row {
//                showPrintController()
//            }
        }
    }
}

extension CBTextViewController : UISearchBarDelegate {
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
        
        self.isSearchActive = !searchText.isEmpty
        self.searchBar.showsCancelButton = true
        
        filteredListArray.removeAll()
        var recurringIndex = 0
        
        for index in 0..<listArray.count {
            
            if recurringIndex == index {
                recurringIndex = index + 1
                
                let currentItem = listArray[index]
                let previousItem = (index > 0) ? listArray[index - 1] : nil
                
                let nextIndex = (index < listArray.count-1) ? index + 1 : nil
                
                if currentItem.lowercased().contains(searchText.lowercased()) {
                    if let previous = previousItem {
                        if isStartsWithNumber(currentItem) == false {
                            filteredListArray.append(previous)
                            filteredListArray.append(currentItem)
                        } else {
                            filteredListArray.append(currentItem)
                        }
                    } else {
                        filteredListArray.append(currentItem)
                    }
                    
                    if let nextIndex = nextIndex {
                        for j in nextIndex..<listArray.count {
                            let nextItem = listArray[j]
                            if isStartsWithNumber(nextItem) == false {
                                filteredListArray.append(nextItem)
                            } else {
                                recurringIndex = j
                                break
                            }
                        }
                    }
                }
            }
        }
        self.tableView.reloadData()
    }
    
    func isStartsWithNumber(_ input: String) -> Bool {
        let trimmedInput = input.trimmingCharacters(in: .whitespaces)
        if let firstCharacter = trimmedInput.first, firstCharacter.isNumber {
            return true
        }
        return false
    }
}



class NMTextField: UITextField {
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(UIResponderStandardEditActions.paste(_:)) {
            return false
        }
        if action == #selector(UIResponderStandardEditActions.cut(_:)) {
            return false
        }
        if action == #selector(UIResponderStandardEditActions.delete(_:)) {
            return false
        }
        if action.description == "_promptForReplace:" {
            return false
        }
        if #available(iOS 16.0, *) {
            if action == #selector(UIResponderStandardEditActions.rename(_:)) {
                return false
            }
            if action == #selector(UIResponderStandardEditActions.findAndReplace(_:)) {
                return false
            }
        }
        return super.canPerformAction(action, withSender: sender)
    }
}

extension CBTextViewController : UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return false
    }
}
