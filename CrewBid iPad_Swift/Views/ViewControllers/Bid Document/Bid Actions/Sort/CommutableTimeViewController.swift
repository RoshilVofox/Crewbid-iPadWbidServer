//
//  CommutableTimeViewController.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 17/04/25.
//

import UIKit

class CommutableTimeViewController: UIViewController,KUIPopOverUsable {
    var contentSize: CGSize = CGSize(width: 400, height: 450)
    @IBOutlet weak var collectionView: UICollectionView!
    var dates = ["01", "02", "03"]
    var dep = ["1200","0500","1000"]
    var arr = ["1700", "1400", "1100"]
    

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
    }
    
    @IBAction func btnDoneAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
}


extension CommutableTimeViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dates.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ArrivalDepartureTimeCell", for: indexPath) as! ArrivalDepartureTimeCell
        cell.dateLabel.text = dates[indexPath.row]
        cell.earliestDepartureLabel.text = dep[indexPath.row]
        cell.latestArrivalLabel.text = arr[indexPath.row]
        return cell
    }
}
