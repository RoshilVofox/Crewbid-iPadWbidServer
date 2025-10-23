//
//  CBDocumentsCollectionViewController.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 20/03/25.
//

import UIKit
import CoreData

class CBDocumentsCollectionViewController: BaseViewController {
    
    @IBOutlet weak var bidDownloadButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var lblHome: UILabel!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var helpMenuButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    var bdPrd = 0
    
    var isPlusImage = true
    var selectedRows : [Int] = []
    var bidPeriodList : [BIBidPeriod] = []
    var dataSource = GlobalBidInfo.shared
    
    let viewModel = DocumentsCollectionViewModel()
    private var didPostInitialSubscriptionCheck = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.initialize()
        collectionView.delegate = self
        collectionView.dataSource = self
        isPlusImage = true
        if !UserDefaults.standard.bool(forKey: "isFirstLaunch"){
            self.showQuickTutorialForFirstTime()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(refreshBidPeriods), name: NSNotification.Name(ReloadCollectionView), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateTitle), name: NSNotification.Name("updateTitle"), object: nil)
        refreshBidPeriods()
        isUpdateAvailable()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(checkSubscription), name: NSNotification.Name("checkSubscription"), object: nil)
        refreshBidPeriods()
        if !didPostInitialSubscriptionCheck {
            didPostInitialSubscriptionCheck = true
            NotificationCenter.default.post(name: NSNotification.Name("checkSubscription"), object: nil)
        }
        NotificationCenter.default.addObserver(self, selector: #selector(showVersionAlert), name: NSNotification.Name("versionAlert"), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(ReloadCollectionView)
    }
    
    @objc func showVersionAlert(_ notification: Notification){
        DispatchQueue.main.async {
            guard let dict = notification.object as? [String: String],
                  let appStoreVersion = dict["appStoreVersion"],
                  let currentVersion = dict["currentVersion"] else { return }

            let message = "You do not have the newest version of Crewbid. You are using version \(currentVersion) and the latest version is \(appStoreVersion)."
            
            AlertService.showAlertForTopVC(title: "App Update Available!", message: message, actions: [(title:"Go To AppStore", style: .default, handler:{_ in
                if let url = URL(string: "https://itunes.apple.com/us/app/crewbid/id563832596?mt=8") {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }),(title: "Cancel", style: .cancel, handler:{_ in
//                self.dismiss(animated: true)
                self.view.hideActivityIndicator()
            })])
        }
    }
    
    
    @objc func checkSubscription(){
        // show alert for expiry check
        if let authDetails = app.ObjUserAccount?.dicLoginAuthDetails, authDetails.count > 0 {
            DispatchQueue.main.async {
                self.view.showActivityIndicator(message: "Subscription Checking...")
            }
            // Trigger an update of subscription details (network-driven)
            CBSubscriptionInfoController().updateSubscriptionDetails(silent: true)
            // After a short delay, evaluate and present the appropriate alert
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                self.checkingAlertFunction()
            }
        } else {
            self.view.hideActivityIndicator()
        }
    }
    
    
    @IBAction func downloadBid(_ sender: Any) {
//        if isPlusImage {
//            UserDefaults.standard.set(false, forKey: "isSecretForAllDomicileDownloadEnabled")
//            let storyboard = UIStoryboard(name: "BidInfo", bundle: nil)
//            let vc = storyboard.instantiateViewController(withIdentifier: "CBNewBidVC") as! CBNewBidVC
//            vc.preferredContentSize = CGSize(width: 600, height: 550)
//            vc.modalTransitionStyle = .crossDissolve
//            vc.isModalInPresentation = true
//            present(vc, animated: true)
//            self.bidDownloadButton.tag = 1
//        }
//        else {
//            self.bidDownloadButton.tag = 2
//            deleteCellRow()
//        }
        if isPlusImage {
            UserDefaults.standard.set(false, forKey: "isSecretForAllDomicileDownloadEnabled")

            let presentNewBid: () -> Void = {
                let storyboard = UIStoryboard(name: "BidInfo", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "CBNewBidVC") as! CBNewBidVC
                vc.preferredContentSize = CGSize(width: 600, height: 550)
                vc.modalTransitionStyle = .crossDissolve
                vc.isModalInPresentation = true
                self.present(vc, animated: true)
                self.bidDownloadButton.tag = 1
            }
            if let authDetails = app.ObjUserAccount?.dicLoginAuthDetails, authDetails.count > 0 {
                if app.connectedToInternet() {
                    DispatchQueue.main.async {
                        self.view.showActivityIndicator(message: "Checking User Account")
                    }
                    CBSubscriptionInfoController().updateSubscriptionDetails(silent: true)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.view.hideActivityIndicator()
                        presentNewBid()
                    }
                } else {
                    let alert = UIAlertController(title: "Network not available!!", message: "Please check your internet connection", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            } else {
                presentNewBid()
            }
        }
        else {
            self.bidDownloadButton.tag = 2
            deleteCellRow()
        }
    }
    
    func deleteCellRow() {
            if selectedRows.isEmpty {
                return
            }
            let alertController = UIAlertController(title: "Warning!", message: "All data, including bid receipts, will be deleted.", preferredStyle:UIAlertController.Style.alert)
            alertController.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))
            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default)
                                      { action -> Void in
                // Iterate over selected rows and delete corresponding bid data
                self.view.showActivityIndicator(color: CBColor.cbPurpleColor, message: "Deleting...")
                DispatchQueue.main.async{
    //                self.view.showActivityIndicator(color: CBColor.cbPurpleColor, message: "deleting...")
                    for index in self.selectedRows {
                        let obj = self.bidPeriodList[index]
                        self.dataSource.month = (obj.month as? Int)!
                        self.dataSource.base = obj.base!
                        self.dataSource.round = (obj.round as? Int)!
                        let rawValue = obj.positionType!.intValue
                        self.dataSource.position = BICrewPositionType(rawValue: rawValue)!
                        
                        // Build file path
                        let tempDir = BIBidInfo.temporaryDirectory()
                        let originalFileName = BIBidInfo.shared.bidDataFilename()
                        let fileNameWithoutSuffix: String
                        if let range = originalFileName.range(of: ".737", options: .backwards) {
                            fileNameWithoutSuffix = String(originalFileName[..<range.lowerBound])
                        } else {
                            fileNameWithoutSuffix = originalFileName
                        }
                        let fileURL = tempDir.appendingPathComponent(fileNameWithoutSuffix)
     
                          // Delete the file if it exists
                          let fileManager = FileManager.default
                          if fileManager.fileExists(atPath: fileURL.path) {
                              do {
                                  try fileManager.removeItem(at: fileURL)
                                  print(" Deleted file: \(fileURL.lastPathComponent)")
                              } catch {
                                  print(" Failed to delete file: \(error.localizedDescription)")
                              }
                          }
                        let context = CoreDataManager.shared.persistentContainer.viewContext
                        context.delete(obj)
                        do {
                            try context.save()
                        } catch {
                            print("Error", error.localizedDescription)
                        }
                        self.selectedRows.removeAll()
                        //                self.refreshBidPeriods()
                    }
                    
                    if self.bidDownloadButton.tag == 2 {
                        let plusImage = UIImage(named: "plus")
                        self.bidDownloadButton.setBackgroundImage(nil, for: .normal)
                        self.bidDownloadButton.setBackgroundImage(plusImage, for: .normal)
                        self.editButton.setTitle("Edit", for: .normal)
                        self.isPlusImage = true
                        self.refreshBidPeriods()
                    }
                    self.view.hideActivityIndicator()
                }
            })
            self.present(alertController, animated: true, completion: nil)
            return
        }
    
    @IBAction func settingsAction(_ sender: Any) {
        let storyboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "EmbeddedSettingsVC") as! EmbeddedSettingsVC
        //        vc.bidPeriod = nil
        vc.bdPrd = bdPrd
        vc.preferredContentSize = CGSize(width: 300, height: 210)
        vc.modalPresentationStyle = .custom
        let frame = CGRect(x: 15, y: 35, width: 0, height: 0)
        vc.showPopover(sourceView: settingsButton, sourceRect: frame)
    }
    
    @IBAction func editAction(_ sender: Any) {
        if self.editButton.currentTitle! == "Edit" {
            selectedRows = []
            self.editButton.setTitle("Done", for: .normal)
            isPlusImage = false
            let trashImage = UIImage(systemName: "trash.fill")
            bidDownloadButton.setBackgroundImage(nil, for: .normal)
            bidDownloadButton.setBackgroundImage(trashImage, for: .normal)
            bidDownloadButton.tintColor = .white
            bidDownloadButton.isEnabled = false
            
        } else {
            self.editButton.setTitle("Edit", for: .normal)
            isPlusImage = true
            let plusImage = UIImage(named: "plus")
            bidDownloadButton.setBackgroundImage(nil, for: .normal)
            bidDownloadButton.setBackgroundImage(plusImage, for: .normal)
            bidDownloadButton.isEnabled = true
        }
        self.collectionView.reloadData()
    }
    
    @IBAction func helpAction(_ sender: Any) {
        let storyBoard = UIStoryboard(name: "HelpMenu", bundle: nil)
        if let helpMenuVC = storyBoard.instantiateViewController(withIdentifier: "CBHelpMenuController") as? CBHelpMenuController{
            //            helpMenuVC.modalPresentationStyle = .formSheet
            helpMenuVC.preferredContentSize = CGSize(width: 764, height: 630)
            helpMenuVC.modalTransitionStyle = .crossDissolve
            present(helpMenuVC, animated: true)
        }
    }
    
    func isUpdateAvailable(){
        guard let infoDictionary = Bundle.main.infoDictionary,
              let bundleID = infoDictionary["CFBundleIdentifier"] as? String
        else { return }

        let urlString = "http://itunes.apple.com/lookup?bundleId=\(bundleID)"
        guard let url = URL(string: urlString) else { return }
        let session = URLSession.shared
        let task = session.dataTask(with: url) { data, _, error in
            if let error = error {
                print("Error checking update: \(error.localizedDescription)")
                return
            }
            guard let data = data else { return }
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String:Any],
                    let results = jsonResponse["results"] as? [[String: Any]],
                    let appInfo = results.first,
                    let appStoreVersion = appInfo["version"] as? String,
                    let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")as? String {
                    if appStoreVersion.compare(currentVersion, options: .numeric) == .orderedDescending {
                        DispatchQueue.main.async {
                            self.textColorBlinking()
                        }
                    }
                }
            } catch {
                print("JSON parsing error: \(error.localizedDescription)")
            }
        }
        task.resume()
    }
    func textColorBlinking() {
        self.lblHome.textColor = .white
        self.lblHome.backgroundColor = .clear
        self.lblHome.isUserInteractionEnabled = true
        
        if let app = UIApplication.shared.delegate as? AppDelegate, let domain = app.Domain, domain.contains("122") {
                self.lblHome.text = "Home (\(CBUtils.AppVersion()) VOFOX SERVER)"
            } else {
                self.lblHome.text = "Home (\(CBUtils.AppVersion()))"
            }
        
        let animation = CATransition()
        animation.duration = 1.0
        animation.fillMode = .forwards
        animation.repeatCount = .infinity
        animation.isRemovedOnCompletion = false
        animation.type = .fade
        animation.subtype = .fromTop
        
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            self.lblHome.layer.add(animation, forKey: "animation")
            self.lblHome.textColor = .white
        }
        
        self.lblHome.textColor = .red
        CATransaction.commit()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(newVersionDownload))
        tapGesture.numberOfTapsRequired = 1
        self.lblHome.addGestureRecognizer(tapGesture)
    }
    
    @objc func newVersionDownload() {
        if let url = URL(string: "https://apps.apple.com/us/app/crewbid/id563832596") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    @objc func updateTitle(){
            var qaString = ""
            if UserDefaults.standard.string(forKey: "isQATest") == "1" {
                qaString = " (QA Mode)"
            }
            
            let version = CBUtils.AppVersion()
            if UserDefaults.standard.bool(forKey: "isTestDBSelected") {
                self.lblHome.text = "Home (\(version)) (Test DB)" + qaString
            } else {
                self.lblHome.text = "Home (\(version))" + qaString
            }
    }
    
    @objc func refreshBidPeriods() {
        DispatchQueue.main.async {
            
            self.updateTitle()
            let context = CoreDataManager.shared.persistentContainer.viewContext
            
//            let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
//            let entity = NSEntityDescription.entity(forEntityName: "BidPeriod", in: context)
//            fetchRequest.entity = entity
//            // Fetch bid periods and reverse to show newest first
//        
//            self.bidPeriodList = try! context.fetch(fetchRequest) as! [BIBidPeriod]
//            self.bidPeriodList = self.bidPeriodList.reversed()
//            self.collectionView.reloadData()
            
            
             let fetchRequest: NSFetchRequest<BIBidPeriod> = BIBidPeriod.fetchRequest()
             let sortDescriptor = NSSortDescriptor(key: "created", ascending: false)
             fetchRequest.sortDescriptors = [sortDescriptor]

             do {
                 self.bidPeriodList = try context.fetch(fetchRequest)
                 self.collectionView.reloadData()
             } catch {
                 print("Failed to fetch BidPeriods: \(error)")
             }
             
            
            if (self.bidPeriodList.count == 0) {
                self.editButton.setTitle("Edit", for: .normal)
                self.isPlusImage = true
                self.bidDownloadButton.setBackgroundImage(nil, for: .normal)
                let plusImage = UIImage(named: "plus")
                self.bidDownloadButton.setBackgroundImage(plusImage, for: .normal)
                self.bidDownloadButton.isEnabled = true
            }

            
            self.editButton.isHidden = self.bidPeriodList.isEmpty
        }
    }
    
    private func expiryDateCheck() -> [String: String] {
        // Converted from Objective-C ExpiryDateCheck implementation
        var result: [String: String] = [:]
        // Defaults as in Obj-C
        result["expired"] = " "
        result["message"] = " "
        result["ButtonTitle"] = ""

        guard let details = app.ObjUserAccount?.dicLoginAuthDetails as? [String: Any] else {
            // No details available; default to non-expired with a Go button
            result["expired"] = "0"
            result["message"] = ""
            result["ButtonTitle"] = "Go"
            return result
        }

        // Parse dates from server-provided values
        let expiryDateString = "\(details["CBExpirationDate"] ?? "")"
        let expiryDate = getDateFromJSON(expiryDateString)
        let currentDate = Date()

        let isPending = (details["IsPending"] as? Bool) ?? false
        let pendingPaidDateString = "\(details["PendingPaidDate"] ?? "")"
        let pendingPaidDate = getDateFromJSON(pendingPaidDateString)

        // Strip time components to compare full days only (MM-dd-yyyy)
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yyyy"
        let startDate = formatter.date(from: formatter.string(from: currentDate))
        let endDate = expiryDate.flatMap { formatter.date(from: formatter.string(from: $0)) }

        let calendar = Calendar(identifier: .gregorian)
        let daysBetween: Int = {
            guard let s = startDate, let e = endDate else { return 0 }
            return calendar.dateComponents([.day], from: s, to: e).day ?? 0
        }()

        let message = "\(details["Message"] ?? "")"
        let messageExpired = "Subscription Expired"

        if message == messageExpired {
            // Mirror Obj-C: treat as not expired but show the message
            result["expired"] = "0"
            result["message"] = message
        } else {
            // if (days < 5 && days > 0)
            if daysBetween < 5 && daysBetween > 0 {
                if !isRenewable() {
                    if isPending && isDateInFutureOrToday(pendingPaidDate) {
                        // User has pending payment with a valid future/today date; do not show expired alert
                    } else {
                        result["expired"] = "1"
                        result["message"] = "Your Subscription will expire in \"\(daysBetween)\" days."
                    }
                }
            }
            // else if (days <= 0 && message != "Success")
            else if daysBetween <= 0 && message != "Success" {
                if !message.contains(" - ") {
                    result["expired"] = "0"
                    result["message"] = message
                } else {
                    result["expired"] = "1"
                    let parts = message.components(separatedBy: " - ")
                    result["message"] = parts.first ?? message
                    result["ButtonTitle"] = parts.count > 1 ? parts[1] : ""
                }
            }
        }

        // Default ButtonTitle to "Go" if empty/space
        let title = result["ButtonTitle"] ?? ""
        if title.trimmingCharacters(in: .whitespaces).isEmpty {
            result["ButtonTitle"] = "Go"
        }

        return result
    }

    // MARK: - Helpers converted from Obj-C usage
    private func getDateFromJSON(_ string: String?) -> Date? {
        guard let s = string, !s.isEmpty else { return nil }

        // Handle "/Date(1588291200000)/" style
        if let startRange = s.range(of: "Date("), let endRange = s.range(of: ")") {
            let numberString = String(s[startRange.upperBound..<endRange.lowerBound]).filter { "-0123456789".contains($0) }
            if let millis = Double(numberString) {
                let seconds = millis > 100000000000 ? millis / 1000.0 : millis
                return Date(timeIntervalSince1970: seconds)
            }
        }

        // Try ISO 8601 first
        let iso = ISO8601DateFormatter()
        if let d = iso.date(from: s) { return d }

        // Try common formats
        let formats = [
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd HH:mm:ss",
            "MM/dd/yyyy",
            "MM-dd-yyyy"
        ]
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        for f in formats {
            df.dateFormat = f
            if let d = df.date(from: s) { return d }
        }
        return nil
    }

    private func isRenewable() -> Bool {
        // Best-effort Swift equivalent for Obj-C isReniewable
        // Consider these as renewable subscriptions
        return (app.ObjUserAccount?.isMonthlySubscribed == true) ||
               (app.ObjUserAccount?.isYearlySubscribed == true) ||
               (app.ObjUserAccount?.isCBMonthlySubscribed == true) ||
               (app.ObjUserAccount?.isCBYearlySubscribed == true)
    }

    private func isDateInFutureOrToday(_ date: Date?) -> Bool {
        guard let date else { return false }
        let cal = Calendar(identifier: .gregorian)
        let d1 = cal.startOfDay(for: date)
        let d2 = cal.startOfDay(for: Date())
        return d1 >= d2
    }

    @objc private func checkingAlertFunction() {
        // Hide any activity indicator shown earlier
        self.view.hideActivityIndicator()

        let expiryDic = self.expiryDateCheck()
        let expired = expiryDic["expired"]
        let message = expiryDic["message"] ?? ""
        let buttonTitle = expiryDic["ButtonTitle"]

        if expired == "1" {
            let alert = UIAlertController(title: "CrewBid", message: message, preferredStyle: .alert)
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            let gotoWeb = UIAlertAction(title: buttonTitle, style: .default) { _ in
                if let url = URL(string: "https://www.crewbid.com/") {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }
            alert.addAction(gotoWeb)
            alert.addAction(cancel)
            self.present(alert, animated: true, completion: nil)
        } else if expired == "0" {
            let alert = UIAlertController(title: "CrewBid", message: message, preferredStyle: .alert)
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            let go = UIAlertAction(title: "Go", style: .default) { _ in
                // Present Help Menu (Subscription Info). If a specific push is required,
                // integrate here based on your CBHelpMenuController API.
                let storyBoard = UIStoryboard(name: "HelpMenu", bundle: nil)
                if let helpMenuVC = storyBoard.instantiateViewController(withIdentifier: "CBHelpMenuController") as? CBHelpMenuController {
                    helpMenuVC.preferredContentSize = CGSize(width: 764, height: 630)
                    helpMenuVC.modalTransitionStyle = .crossDissolve
                    self.present(helpMenuVC, animated: true, completion: nil)
                }
            }
            alert.addAction(cancel)
            alert.addAction(go)
            self.present(alert, animated: true, completion: nil)
        }
    }

}



extension CBDocumentsCollectionViewController: UICollectionViewDataSource,UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return bidPeriodList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DocumentCell", for: indexPath) as! DocumentCell
        cell.layer.cornerRadius = 10
        cell.layer.borderWidth = 8
        cell.layer.borderColor = CBColor.cbPurpleColor?.cgColor
        
        let bidPeriod : BIBidPeriod = bidPeriodList[indexPath.item]
        cell.base.text = bidPeriod.base
        let positionArray = ["Captain","First Officer","Flight Attendant"]
        cell.position.text = positionArray[bidPeriod.positionType!.intValue]
        cell.monthRoundLabel.text = CBGlobalMethods.shortMonthNameOf(monthInt: bidPeriod.month!.intValue) + " " +  bidPeriod.year!.stringValue + " Round " + bidPeriod.round!.stringValue
        
        
        if self.editButton.currentTitle == "Edit" {
            collectionView.allowsMultipleSelection = false
            cell.stopWiggleAnimation()
        } else {
            collectionView.allowsMultipleSelection = true
            cell.startWiggleAnimation()
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        let cell: UICollectionViewCell = collectionView.cellForItem(at: indexPath)!
        guard let cell = collectionView.cellForItem(at: indexPath) as? DocumentCell else { return }
        if self.editButton.currentTitle! == "Done" {
            
            cell.layer.borderColor = UIColor.systemOrange.cgColor
            if selectedRows.contains(indexPath.item) {
                selectedRows.remove(at: selectedRows.firstIndex(of: indexPath.item)!)
            }else {
                selectedRows.append(indexPath.item)
            }
            if selectedRows.count > 0 {
                bidDownloadButton.isEnabled = true
            }
            else {
                bidDownloadButton.isEnabled = false
            }
        }
        else {
            
            bidDownloadButton.isEnabled = true
            cell.activityIndicator.isHidden = false
            cell.activityIndicator.startAnimating()
            cell.isUserInteractionEnabled = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                let storyboard = UIStoryboard(name: "BidDocument", bundle: nil)
                guard let vc = storyboard.instantiateViewController(withIdentifier: "CBBidDocumentController") as? CBBidDocumentController else {
                    cell.isUserInteractionEnabled = true
                    return
                    }

                let bidPeriod = self.bidPeriodList[indexPath.item]
                vc.bidPeriod = bidPeriod
                self.dataSource.year = bidPeriod.year?.intValue ?? 0
                self.dataSource.base = bidPeriod.base ?? ""
                self.dataSource.month = bidPeriod.month?.intValue ?? 0
                self.dataSource.round = bidPeriod.round?.intValue ?? 0
                CBGlobalMethods.shared.selectedBidPeriod = bidPeriod
                CBGlobalMethods.shared.selectedBidPeriod!.loadedPresetIdentifier = nil
                if let rawValue = bidPeriod.positionType?.intValue,
                    let position = BICrewPositionType(rawValue: rawValue) {
                    self.dataSource.position = position
                }
                cell.activityIndicator.stopAnimating()
                cell.isUserInteractionEnabled = true
                cell.backgroundView = nil
//                self.navigationController?.pushViewController(vc, animated: true)
                let transition = CATransition()
                transition.duration = 0.4
                transition.type = .fade  // cross dissolve effect
                transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

                self.navigationController?.view.layer.add(transition, forKey: kCATransition)
                self.navigationController?.pushViewController(vc, animated: false)
                }
//            let storyboard = UIStoryboard(name: "BidDocument", bundle: nil)
//            let vc = storyboard.instantiateViewController(withIdentifier: "CBBidDocumentController") as! CBBidDocumentController
//            vc.modalTransitionStyle = .crossDissolve
//            vc.bidPeriod = self.bidPeriodList[indexPath.item]
//            let bidPeriod : BIBidPeriod = bidPeriodList[indexPath.item]
//            dataSource.year = (bidPeriod.year as? Int)!
//            dataSource.base = bidPeriod.base!
//            dataSource.month = (bidPeriod.month as? Int)!
//            dataSource.round = (bidPeriod.round as? Int)!
//            CBGlobalMethods.shared.selectedBidPeriod = bidPeriod
//            if let rawValue = bidPeriod.positionType as? Int,
//               let position = BICrewPositionType(rawValue: rawValue) {
//                // Successfully converted and initialized the enum
//                dataSource.position = position
//            }
//            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell: UICollectionViewCell = collectionView.cellForItem(at: indexPath)!
        if self.editButton.currentTitle! == "Done" {
            cell.layer.borderColor = CBColor.cbPurpleColor?.cgColor
            if selectedRows.contains(indexPath.item) {
                selectedRows.remove(at: selectedRows.firstIndex(of: indexPath.item)!)
            }
        }
        if selectedRows.count > 0 {
            bidDownloadButton.isEnabled = true
        }else {
            bidDownloadButton.isEnabled = false
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,layout collectionViewLayout: UICollectionViewLayout,sizeForItemAt indexPath: IndexPath) -> CGSize {
        let itemsPerRow: CGFloat = 2
        let spacing: CGFloat = 10
        let sectionInsets = UIEdgeInsets(top: 30, left: 30, bottom: 30, right: 30)
        let totalSpacing = sectionInsets.left + sectionInsets.right + (spacing * (itemsPerRow - 1))
        let availableWidth = collectionView.bounds.width - totalSpacing
        let availableHeight = collectionView.bounds.height - totalSpacing
        let cellWidth = floor(availableWidth / itemsPerRow)
        let cellHeight = floor(availableHeight / itemsPerRow)
        let finalWidth = cellWidth - 60
        let finalHeight = cellHeight - 90
        return CGSize(width: finalWidth, height: finalHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView,layout collectionViewLayout: UICollectionViewLayout,minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }

    func collectionView(_ collectionView: UICollectionView,layout collectionViewLayout: UICollectionViewLayout,minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 30
    }

    func collectionView(_ collectionView: UICollectionView,layout collectionViewLayout: UICollectionViewLayout,insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50)
    }
}
