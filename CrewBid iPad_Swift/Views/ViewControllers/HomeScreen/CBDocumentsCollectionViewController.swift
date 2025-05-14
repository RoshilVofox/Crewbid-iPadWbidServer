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
        bdPrd = 0
    }
    
    @IBAction func downloadBid(_ sender: Any) {
        if isPlusImage {
            let storyboard = UIStoryboard(name: "BidInfo", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "CBNewBidVC") as! CBNewBidVC
            vc.preferredContentSize = CGSize(width: 600, height: 550)
            self.present(vc, animated: true)
        }
        else {
            guard !selectedRows.isEmpty else { return }
            let sortedIndices = selectedRows.sorted(by: >)
            for index in sortedIndices {
                collectionViewData.remove(at: index)
            }
            let indexPaths = sortedIndices.map { IndexPath(item: $0, section: 0) }
            collectionView.deleteItems(at: indexPaths)
            selectedRows.removeAll()
            //            MARK: wait
            //            bidDownloadButton.setImage(UIImage(systemName: "trash"), for: .normal)
        }
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
        collectionView.allowsMultipleSelection = true
        
        if self.editButton.currentTitle == "Edit" {
            cell.stopWiggleAnimation()
        } else {
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
}
