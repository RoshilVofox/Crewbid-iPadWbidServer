//
//  CommuteCityViewController.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 17/04/25.
//

import UIKit

protocol CityNameViewControllerDelegate: AnyObject {
    func setCityName(_ cityName: String?)
    func disableButtonsForNoConnection()
}

class CommuteCityViewController: UIViewController, KUIPopOverUsable {
    var contentSize: CGSize = CGSize(width: 320, height: 400)
    @IBOutlet weak var collectionView: UICollectionView!
    
    var delegate: CityNameViewControllerDelegate!
    var arrAllCities: NSMutableArray!
    var commuteTime: CommuteTime?
    var depTime: Int = 0
    var arrTime: Int = 0
    var bidPeriod: BIBidPeriod?
    var isNonStopOnly : Bool = false
    var connectTime : Int = 30
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        arrAllCities = ["ATL", "DEN", "DAL"]
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    @IBAction func btnCloseAction(_ sender: Any) {
        print("i am working")
        self.dismiss(animated: true, completion: nil)
    }
    
    func commutabilityCalculationWithForSync(city: String, isNonStop: Bool) -> (Bool, String) {
        return (true, "")
    }
    
}

extension CommuteCityViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return arrAllCities.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CityPickerCell", for: indexPath) as! CityPickerCell
        cell.cityLabel.text = "\(arrAllCities[indexPath.row])"
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! CityPickerCell
        let alert = UIAlertController(
            title: cell.cityLabel.text!,
            message: "Is your commuter city?",
            preferredStyle: .alert
        )
        //cancel
        let cancelAction = UIAlertAction(title: "No", style: .cancel)
        //add
        let okAction = UIAlertAction(title: "Yes", style: .default) { _ in
            self.dismiss(animated: true, completion: nil)
        }
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
}
