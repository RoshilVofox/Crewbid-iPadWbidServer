//
//  CBDocumentsCollectionViewController.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 20/03/25.
//

import UIKit

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
    var collectionViewData = [1,2,3,4,5,6,7,8,9]
    
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
    }
    
    @IBAction func downloadBid(_ sender: Any) {
        if isPlusImage {
            let storyboard = UIStoryboard(name: "BidInfo", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "CBNewBidVC") as! CBNewBidVC
            vc.preferredContentSize = CGSize(width: 600, height: 550)
            vc.modalPresentationStyle = .formSheet
            vc.isModalInPresentation = true
            present(vc, animated: true)
        }
        else {
           deleteCellRow()
        }
    }
    
    func deleteCellRow() {
        guard !selectedRows.isEmpty else { return }
        let sortedIndices = selectedRows.sorted(by: >)
        for index in sortedIndices {
            collectionViewData.remove(at: index)
        }
        let indexPaths = sortedIndices.map { IndexPath(item: $0, section: 0) }
        collectionView.deleteItems(at: indexPaths)
        selectedRows.removeAll()
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
        if let helpMenuVC = storyBoard.instantiateViewController(withIdentifier: "helpMenuViewController") as? helpMenuViewController{
            //            helpMenuVC.modalPresentationStyle = .formSheet
            helpMenuVC.preferredContentSize = CGSize(width: 764, height: 630)
            present(helpMenuVC, animated: true)
        }
    }
}


extension CBDocumentsCollectionViewController: UICollectionViewDataSource,UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionViewData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DocumentCell", for: indexPath) as! DocumentCell
        cell.layer.cornerRadius = 10
        cell.layer.borderWidth = 8
        cell.layer.borderColor = CBColor.cbPurpleColor?.cgColor
        
        
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
