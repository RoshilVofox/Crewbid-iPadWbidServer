//
//  CBBIdListVC.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 21/03/25.
//

import UIKit

class CBBidListVC: BaseViewController {
//    func didTappedAwardSort(isOn: Bool) {
//        <#code#>
//    }
//    
//    func didTappedSubmitSort(isOn: Bool) {
//        <#code#>
//    }
    

    @IBOutlet weak var btnASort: UIButton!
    
    var isAwardSort = false
    var isSubmitSort = false
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    @IBAction func btnFiltersAction(_ sender: Any) {
        let storyboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBFilterRulesTableVC") as! CBFilterRulesTableVC
        self.navigationController?.pushViewController(vc, animated: false)
        UIView.transition(from: self.view, to: vc.view, duration: 0.65, options: [.transitionFlipFromLeft])
    }
    
    @IBAction func btnASortAction(_ sender: Any) {
        let sortOptionVC = UIStoryboard(name: "BidDocument", bundle: nil).instantiateViewController(withIdentifier: "CBBidListSortOptions") as! CBBidListSortOptions
        sortOptionVC.yAxis = btnASort.globalFrame!.minY
        sortOptionVC.xAxis = btnASort.globalFrame!.minX
        sortOptionVC.isAwardSortSelected = isAwardSort
        sortOptionVC.isSubmitOredrSortSelected = isSubmitSort
        self.addChild(sortOptionVC)
        self.view.addSubview(sortOptionVC.view)
        sortOptionVC.view.frame = self.view.bounds
    }
}
