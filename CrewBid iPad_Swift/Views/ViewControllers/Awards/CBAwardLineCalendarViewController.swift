//
//  CBAwardLineCalendarViewController.swift
//  CrewBid iPad_Swift
//
//  Created by Developer on 17/04/25.
//

import UIKit

class CBAwardLineCalendarViewController: UIViewController, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var lblLineNumber: UILabel!
    @IBOutlet weak var lblFaPosition: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var viewLineValues: UIView!
    @IBOutlet weak var btnClose: UIButton!
    @IBOutlet weak var btnShare: UIButton!
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        btnClose.setTitle("", for: .normal)
        btnShare.setTitle("", for: .normal)
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
       
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        collectionView.collectionViewLayout = layout

        // Do any additional setup after loading the view.
    }
    

    @IBAction func btnShareAction(_ sender: Any) {
    }
    
    @IBAction func btnDismissAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension CBAwardLineCalendarViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 42
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AwardCalendarCollectionViewCell", for: indexPath) as! AwardCalendarCollectionViewCell
        cell.dayLabel.text = "\(indexPath.row + 1)"
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width / 7, height: 55)
    }
}
