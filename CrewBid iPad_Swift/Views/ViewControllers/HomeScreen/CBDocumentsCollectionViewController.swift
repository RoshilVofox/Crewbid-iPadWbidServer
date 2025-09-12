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
    var bdPrd:Int!
    
    var isPlusImage = true
    var selectedRows : [Int] = []
//    var collectionViewData = [1,2,3,4,5,6,7,8,9]
    var bidPeriodList : [BIBidPeriod] = []
    var dataSource = GlobalBidInfo.shared
    
    let viewModel = DocumentsCollectionViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.initialize()
        collectionView.delegate = self
        collectionView.dataSource = self
        isPlusImage = true
        bdPrd = 0
        if !UserDefaults.standard.bool(forKey: "isFirstLaunch"){
            self.showQuickTutorialForFirstTime()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(refreshBidPeriods), name: NSNotification.Name(ReloadCollectionView), object: nil)
        refreshBidPeriods()
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshBidPeriods()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(ReloadCollectionView)
    }
    @IBAction func downloadBid(_ sender: Any) {
        if isPlusImage {
            let storyboard = UIStoryboard(name: "BidInfo", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "CBNewBidVC") as! CBNewBidVC
            vc.preferredContentSize = CGSize(width: 600, height: 550)
            vc.modalPresentationStyle = .formSheet
            vc.isModalInPresentation = true
            present(vc, animated: true)
            self.bidDownloadButton.tag = 1
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
                self.view.showActivityIndicator(color: CBColor.cbPurpleColor, message: "deleting...")
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
                        
                        self.dataSource.managedObjectContext.delete(obj)
                        do {
                            try self.dataSource.managedObjectContext.save()
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
        print("HelpMenu")
        //        print("HelpMenu")
        let storyBoard = UIStoryboard(name: "HelpMenu", bundle: nil)
        if let helpMenuVC = storyBoard.instantiateViewController(withIdentifier: "CBHelpMenuController") as? CBHelpMenuController{
            //            helpMenuVC.modalPresentationStyle = .formSheet
            helpMenuVC.preferredContentSize = CGSize(width: 764, height: 630)
            present(helpMenuVC, animated: true)
        }
    }
    
    @objc func refreshBidPeriods() {
        DispatchQueue.main.async {
            var qaString = ""
            if UserDefaults.standard.bool(forKey: "IsQAEnabled") == true {
                qaString = " (QA Mode)"
            }
            
            let version = CBUtils.AppVersion()
            if UserDefaults.standard.bool(forKey: "isTestDBSelected") {
                self.lblHome.text = "Home (\(version)) (Test DB)" + qaString
            } else {
                self.lblHome.text = "Home (\(version))" + qaString
            }

            let context = self.dataSource.managedObjectContext
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
            let entity = NSEntityDescription.entity(forEntityName: "BidPeriod", in: context)
            fetchRequest.entity = entity
            // Fetch bid periods and reverse to show newest first
        
            self.bidPeriodList = try! context.fetch(fetchRequest) as! [BIBidPeriod]
            self.bidPeriodList = self.bidPeriodList.reversed()
            self.collectionView.reloadData()
            
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
        let cell: UICollectionViewCell = collectionView.cellForItem(at: indexPath)!
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
            let storyboard = UIStoryboard(name: "BidDocument", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "CBBidDocumentController") as! CBBidDocumentController
            let bidPeriod : BIBidPeriod = bidPeriodList[indexPath.item]
            dataSource.year = (bidPeriod.year as? Int)!
            dataSource.base = bidPeriod.base!
            dataSource.month = (bidPeriod.month as? Int)!
            dataSource.round = (bidPeriod.round as? Int)!
            CBGlobalMethods.shared.selectedBidPeriod = bidPeriod
            if let rawValue = bidPeriod.positionType as? Int,
               let position = BICrewPositionType(rawValue: rawValue) {
                // Successfully converted and initialized the enum
                dataSource.position = position
            }
            self.navigationController?.pushViewController(vc, animated: true)
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


