//
//  CBSeniorityListVC.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 22/12/25.
//

import UIKit

class CBSeniorityListVC: UIViewController {

    @IBOutlet weak var lblTitle: UILabel!
//    @IBOutlet weak var searchBar: UISearchBar!
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
    private var isPresentingInvalidTokenAlert = false
    
    var currentSearchText: String = ""
    let searchBar = UISearchBar()
    let previousButton = UIButton(type: .system)
    let nextButton = UIButton(type: .system)
    let resultLabel = UILabel()

    var matchIndexPaths: [IndexPath] = []
    var currentMatchIndex: Int = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchSeniorityData()
        if !isFromFirstTimeOpenBid {
            refreshSeniorityList()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(handleAuthFlowEnded), name: Notification.Name("AuthFlowEnded"), object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("AuthFlowEnded"), object: nil)
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
        setupSearchUI()
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
    
    func setupSearchUI() {
        
        let containerView = UIStackView()
        containerView.axis = .horizontal
        containerView.spacing = 8
        containerView.alignment = .center
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // SearchBar
        searchBar.placeholder = "Search"
        searchBar.delegate = self
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.widthAnchor.constraint(equalToConstant: 200).isActive = true
        
        // Previous Button
        previousButton.setTitle("◀︎", for: .normal)
        previousButton.addTarget(self, action: #selector(previousTapped), for: .touchUpInside)
        
        // Next Button
        nextButton.setTitle("▶︎", for: .normal)
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
        
        // Result Label
        resultLabel.text = ""
        resultLabel.font = UIFont.systemFont(ofSize: 14)
        
        previousButton.isEnabled = false
        previousButton.isHidden = true
        nextButton.isEnabled = true
        nextButton.isHidden = true
        
        containerView.addArrangedSubview(searchBar)
        containerView.addArrangedSubview(previousButton)
        containerView.addArrangedSubview(resultLabel)
        containerView.addArrangedSubview(nextButton)
        
        view.addSubview(containerView)
        
        NSLayoutConstraint.activate([
            // Align vertically with btnShare
            containerView.centerYAnchor.constraint(equalTo: btnShare.centerYAnchor),
            // Place it to the LEFT of btnShare
            containerView.trailingAnchor.constraint(equalTo: btnShare.leadingAnchor, constant: -10),
            // Optional: prevent going off left edge
            containerView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 10)
        ])
    }
    
    func fetchSeniorityData() {
        let set = bidPeriod?.seniorityList as? Set<SeniorityList> ?? []
        seniorityList = Array(set)

        filteredSeniorityList = (seniorityList?.sorted {
            ($0.baseSeniority?.intValue ?? 0) < ($1.baseSeniority?.intValue ?? 0)
        })!

        tableView.reloadData()
    }
    
//    func shouldRefreshSeniority() -> Bool {
//        guard let bidPeriod = bidPeriod else { return false }
//        
//        if bidPeriod.isHistoric?.boolValue == true {
//            return false
//        }
//
//        if bidPeriod.isOldBid?.boolValue == true {
//            return false
//        }
//        
//        return bidPeriod.isFABid() == true &&
//               bidPeriod.isSwaAPI?.boolValue == true
//    }

    func refreshSeniorityList() {
        guard
            bidPeriod?.isFABid() == true,
            bidPeriod?.isSwaAPI?.boolValue == true,
            let bidPeriod = bidPeriod
        else { return }
        
        DispatchQueue.main.async {
            self.showToast(message: "Refreshing seniority list…")
            print("Refreshing seniority list…")
        }
        let downloader = BISwaBidDataDownload()

        downloader?.getSwaSeniorityList { [weak self] result in
            switch result {

            case .success:
                let parser = BISwaBidDataParsing(dataSource: GlobalBidInfo.shared)

                parser?.refreshSeniorityFromDownloadedJSON(bidPeriod: bidPeriod) { saveResult in
                    DispatchQueue.main.async {
                        switch saveResult {
                        case .success:
                            self?.fetchSeniorityData()
                            self?.showToast(message: "Seniority list updated")
                            print("Seniority list updated")
                        case .failure(let error):
                            print("Save failed: \(error.localizedDescription)")
                            DispatchQueue.main.async {
                                self?.showToast(message: "Unable to refresh. Showing saved list.")
                            }
                        }
                    }
                }

            case .failure(let error):
                if self?.isTokenExpiredError(error) == true {
                    self?.showInvalidTokenAlertOnce()
                    return
                }

                print("Download failed: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.showToast(message: "Unable to refresh. Showing saved list.")
                }
            }
        }
    }
    
    private func showInvalidTokenAlertOnce() {
        DispatchQueue.main.async {
            guard !self.isPresentingInvalidTokenAlert else { return }
            self.isPresentingInvalidTokenAlert = true
            self.invalidTokenAlert()
        }
    }
    
    
    func invalidTokenAlert(){
        AlertService.showAlertForTopVC(title: "Invalid Token Alert", message: "The token has expired or is invalid. Please provide the credentials to proceed.", actions: [(title: "OK", style: .default, handler:{ _ in
            DispatchQueue.main.async {
                guard let vc = UIStoryboard(name: "BidInfo", bundle: nil).instantiateViewController(withIdentifier: "CBCredentialsPageVC") as? CBCredentialsPageVC else { return }
                vc.preferredContentSize = CGSize(width: 600, height: 550)
                vc.isModalInPresentation = true
                var dictInfo: [String: Any] = [:]
                dictInfo["base"] = self.bidPeriod?.base
                dictInfo["month"] = self.bidPeriod?.month
                dictInfo["round"] = self.bidPeriod?.round
                if let positionValue = self.bidPeriod?.positionType?.intValue,
                   let pos = BICrewPositionType(rawValue: positionValue){
                    dictInfo["position"] = CBUtils.shortName(for: pos)
                    vc.selectedPosition = pos
                }
                vc.isForReauth = true
                self.isPresentingInvalidTokenAlert = true
                self.present(vc, animated: true)
            }
        })])
    }
    
    func isTokenExpiredError(_ error: Error) -> Bool {
        let nsError = error as NSError
        let desc = nsError.localizedDescription.lowercased()

        if nsError.code == 401 { return true }
        if desc.contains("invalid_token") { return true }
        if desc.contains("token expired") { return true }
        if desc.contains("token not valid") { return true }

        return false
    }
    
    @objc func handleAuthFlowEnded() {
        print("Auth finished — refreshing seniority again")
        isPresentingInvalidTokenAlert = false
        refreshSeniorityList()
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
        let col3Width = 35  //Name
        let col4Width = 10 //Emp ID
        let col5Width = 13 //Vacation left space
        
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
        return text
    }
    
    
    @IBAction func btnDismissAction(_ sender: Any) {
//        self.dismiss(animated: true)
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
            
        guard bidPeriod?.isHistoric?.boolValue != true else { return }
            

        if bidPeriod?.coverLetterDisplayed?.boolValue != true {
                let details = ["isFromFirstTimeOpenBid":true]
                NotificationCenter.default.post(name: NSNotification.Name("KCBOpenCoverletterForFA"), object: self,userInfo: details)
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
    
    func highlightedText(fullText: String,
                         searchText: String,
                         isCurrentMatch: Bool) -> NSAttributedString {
        
        let attributedString = NSMutableAttributedString(
            string: fullText,
            attributes: [
//                .font: UIFont.systemFont(ofSize: 15),
                .foregroundColor: UIColor.label
            ]
        )
        
        guard !searchText.isEmpty else {
            return attributedString
        }
        
        let lowerFull = fullText.lowercased()
        let lowerSearch = searchText.lowercased()
        
        var searchRange = lowerFull.startIndex..<lowerFull.endIndex
        
        while let range = lowerFull.range(of: lowerSearch, range: searchRange) {
            
            let nsRange = NSRange(range, in: fullText)
            
            attributedString.addAttribute(
                .backgroundColor,
                value: isCurrentMatch ? UIColor.systemOrange : UIColor.systemYellow,
                range: nsRange
            )
            
            searchRange = range.upperBound..<lowerFull.endIndex
        }
        
        return attributedString
    }
    
    func updateResultLabel() {
        if matchIndexPaths.isEmpty {
            resultLabel.text = ""
            previousButton.isEnabled = false
            previousButton.isHidden = true
            nextButton.isEnabled = false
            nextButton.isHidden = true
        } else {
            resultLabel.text = "\(currentMatchIndex + 1) of \(matchIndexPaths.count)"
            previousButton.isEnabled = true
            previousButton.isHidden = false
            nextButton.isEnabled = true
            nextButton.isHidden = false
        }
    }
    
    @objc func nextTapped() {
        guard !matchIndexPaths.isEmpty else { return }
        
        currentMatchIndex += 1
        
        if currentMatchIndex >= matchIndexPaths.count {
            currentMatchIndex = 0
        }
        
        scrollToCurrentMatch()
    }

    @objc func previousTapped() {
        guard !matchIndexPaths.isEmpty else { return }
        
        currentMatchIndex -= 1
        if currentMatchIndex < 0 {
            currentMatchIndex = matchIndexPaths.count - 1
        }
        
        scrollToCurrentMatch()
    }
    
    func scrollToCurrentMatch() {
        
        guard !matchIndexPaths.isEmpty,
              currentMatchIndex < matchIndexPaths.count else { return }
        
        let indexPath = matchIndexPaths[currentMatchIndex]
        
        tableView.layoutIfNeeded()
        
        tableView.scrollToRow(at: indexPath,
                              at: .middle,
                              animated: true)
        
        updateVisibleCellsHighlight()
        updateResultLabel()
    }
    
    func updateVisibleCellsHighlight() {
        guard let visible = tableView.indexPathsForVisibleRows else { return }
        
        tableView.reloadRows(at: visible, with: .none)
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
            if CBGlobalMethods.shared.selectedBidPeriod!.isSwaAPI?.boolValue == true {
                if seniority.vacationString == "N/A"{
                    return 40
                }else{
                    return 60
                }
            }
            else {
                if seniority.vacationString == "N/A"{
                    return 35
                }else{
                    return 54
                }
            }
        }
        return 40
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "CBSeniorityListTableViewCell",
            for: indexPath
        ) as! CBSeniorityListTableViewCell
        
        cell.selectionStyle = .none
        cell.layoutMargins = .zero
        cell.separatorInset = .zero
        
        let seniority = filteredSeniorityList[indexPath.row]
        let indexPathMatch = IndexPath(row: indexPath.row, section: 0)

        let isCurrent =
            matchIndexPaths.indices.contains(currentMatchIndex) &&
            matchIndexPaths[currentMatchIndex] == indexPathMatch
        // Base Seniority
        let baseText = seniority.baseSeniority?.stringValue ?? ""
        cell.baseSeniorityLbl.attributedText =
            highlightedText(fullText: baseText,
                            searchText: currentSearchText, isCurrentMatch: isCurrent)
        
        // Employee Number
        let empText: String
        if bidPeriod?.isFirstRoundBid() == true {
            empText = "(\(seniority.employeeId ?? ""))"
        } else {
            empText = "[\(seniority.employeeId ?? "")]"
        }
        
        cell.empNumLbl.attributedText =
            highlightedText(fullText: empText,
                            searchText: currentSearchText, isCurrentMatch: isCurrent)
        
        // Name
        let legalName = seniority.legalName?.uppercased() ?? ""
        
        let nameText: String
        if bidPeriod?.isFirstRoundBid() == true {
            nameText = legalName
        } else {
            nameText = legalName + "......................"
        }
        
        cell.nameLbl.attributedText =
            highlightedText(fullText: nameText,
                            searchText: currentSearchText, isCurrentMatch: isCurrent)
        
        // 🔥 Vacation Handling (CRITICAL FIX)
        
        if bidPeriod?.isFirstRoundBid() == true {
            
            if seniority.vacationString == "N/A" {
                cell.vacationTop.constant = 0
                cell.vacationLbl.isHidden = true
                cell.vacationLbl.text = nil
                cell.vacationLbl.attributedText = nil
            } else {
                cell.vacationTop.constant = 5
                cell.vacationLbl.isHidden = false
                cell.vacationLbl.attributedText =
                    highlightedText(fullText: seniority.vacationString,
                                    searchText: currentSearchText, isCurrentMatch: isCurrent)
            }
            
        } else {
            // ✅ SECOND ROUND → COMPLETELY HIDE
            cell.vacationTop.constant = 0
            cell.vacationLbl.isHidden = true
            cell.vacationLbl.text = nil
            cell.vacationLbl.attributedText = nil
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
        
        currentSearchText = searchText
        matchIndexPaths.removeAll()
        currentMatchIndex = 0
        
        guard let seniorityList = seniorityList else { return }
        
        filteredSeniorityList = seniorityList.sorted {
            ($0.baseSeniority?.intValue ?? 0) < ($1.baseSeniority?.intValue ?? 0)
        }
        
        if !searchText.isEmpty {
            for (index, item) in filteredSeniorityList.enumerated() {
                if item.employeeId?.localizedCaseInsensitiveContains(searchText) == true ||
                   item.legalName?.localizedCaseInsensitiveContains(searchText) == true ||
                   item.vacationString.localizedCaseInsensitiveContains(searchText) ||
                   item.baseSeniority?.stringValue.localizedCaseInsensitiveContains(searchText) == true {
                    
                    matchIndexPaths.append(IndexPath(row: index, section: 0))
                }
            }
        }
        
        tableView.reloadData()
        
        // 🔥 Scroll AFTER reload + layout
        DispatchQueue.main.async {
            if !self.matchIndexPaths.isEmpty {
                self.scrollToCurrentMatch()
            }
        }
        
        updateResultLabel()
    }
    
    func isStartsWithNumber(_ input: String) -> Bool {
        let trimmedInput = input.trimmingCharacters(in: .whitespaces)
        if let firstCharacter = trimmedInput.first, firstCharacter.isNumber {
            return true
        }
        return false
    }
}
