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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.delegate = self
        collectionView.dataSource = self
        
        
    }
   
    @IBAction func downloadBid(_ sender: Any) {
        let storyboard = UIStoryboard(name: "BidInfo", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBNewBidVC") as! CBNewBidVC
        vc.preferredContentSize = CGSize(width: 600, height: 550)
        self.present(vc, animated: true)
    }
    
    @IBAction func settingsAction(_ sender: Any) {
        print("Settings")
    }
    
    
    @IBAction func editAction(_ sender: Any) {
        print("Edit")
    }
    
    @IBAction func helpAction(_ sender: Any) {
        print("HelpMenu")
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
        cell.layer.borderWidth = 6
        cell.layer.borderColor = UIColor.purple.cgColor
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBBidDocumentController") as! CBBidDocumentController
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
