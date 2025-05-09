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
    
    let viewModel = DocumentsCollectionViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.initialize()
        collectionView.delegate = self
        collectionView.dataSource = self
        bdPrd = 0
    }
    
    @IBAction func downloadBid(_ sender: Any) {
        let storyboard = UIStoryboard(name: "BidInfo", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBNewBidVC") as! CBNewBidVC
        vc.preferredContentSize = CGSize(width: 600, height: 550)
        self.present(vc, animated: true)
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
        print("Edit")
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
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DocumentCell", for: indexPath) as! DocumentCell
        cell.layer.cornerRadius = 10
        cell.layer.borderWidth = 8
        cell.layer.borderColor = CBColor.cbPurpleColor?.cgColor
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBBidDocumentController") as! CBBidDocumentController
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
