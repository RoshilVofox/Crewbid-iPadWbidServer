//
//  CBBIdListVC.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 21/03/25.
//

import UIKit

class CBBidListVC: BaseViewController {

    @IBOutlet weak var btnNormalView: UIButton!
    @IBOutlet weak var btnCalendarView: UIButton!
    @IBOutlet weak var btnExpandedView: UIButton!
    @IBOutlet weak var btnActions: UIButton!
    @IBOutlet weak var btnASort: UIButton!
    @IBOutlet weak var tableViewNormalView: UITableView!
    var isAwardSort = false
    var isSubmitSort = false
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    func setupUI(){
        self.btnNormalView.backgroundColor = .orange
        btnNormalView.layer.borderWidth = 1
        btnNormalView.layer.borderColor = UIColor.lightGray.cgColor
        btnCalendarView.layer.borderWidth = 1
        btnCalendarView.layer.borderColor = UIColor.lightGray.cgColor
        btnExpandedView.layer.borderWidth = 1
        btnExpandedView.layer.borderColor = UIColor.lightGray.cgColor
    }

    @IBAction func btnFiltersAction(_ sender: Any) {
        AppData.shared.isBidListSort = false
        NotificationCenter.default.post(name: NSNotification.Name("SortBidListAction"), object: self)

        let storyboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBFilterRulesTableVC") as! CBFilterRulesTableVC

        // Setup new VC
        vc.view.frame = self.view.bounds
        vc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.addChild(vc)

        // Perform flip transition from current view to new VC's view
        UIView.transition(with: self.view, duration: 0.65, options: .transitionFlipFromLeft,
                          animations: {
                              self.view.addSubview(vc.view)
                          },
                          completion: { _ in
                              vc.didMove(toParent: self)
                          })
    }

    
    @IBAction func btnActionsTapped(_ sender: Any) {
        let storyboard : UIStoryboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "BidListActionVC") as! BidListActionVC
        vc.modalPresentationStyle = .custom
        let frame = CGRect(x: 15, y: 35, width: 0, height: 0)
        vc.showPopover(sourceView: btnActions, sourceRect: frame)
    }
    
    @IBAction func btnASortAction(_ sender: Any) {
        let sortOptionVC = UIStoryboard(name: "BidDocument", bundle: nil).instantiateViewController(withIdentifier: "CBBidListSortOptions") as! CBBidListSortOptions
        sortOptionVC.yAxis = btnASort.globalFrame!.minY
        sortOptionVC.xAxis = btnASort.globalFrame!.minX
        self.addChild(sortOptionVC)
        self.view.addSubview(sortOptionVC.view)
        sortOptionVC.view.frame = self.view.bounds
    }
    
    @IBAction func btnExpandedViewAction(_ sender: Any) {
        let storyboard : UIStoryboard = UIStoryboard(name: "BidDocument", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBExpandedBidLinesTableController") as! CBExpandedBidLinesTableController
        vc.navTitle = "Expanded Bid List"
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true)
    }
    
    @IBAction func btnNormalViewAction(_ sender: Any) {
        UserDefaults.standard.set(false, forKey: "isSelectedCalanderView")
        manageViewSelection()
    }
    
    @IBAction func btnCalendarViewAction(_ sender: Any) {
        UserDefaults.standard.set(true, forKey: "isSelectedCalanderView")
        manageViewSelection()
    }
    
    func manageViewSelection(){
        
        var bgColor: UIColor = .white
        bgColor = .secondarySystemBackground
        
        
        if UserDefaults.standard.bool(forKey: "isSelectedCalanderView"){
            self.btnNormalView.backgroundColor = bgColor
            self.btnCalendarView.backgroundColor = .orange
        }else{
            self.btnCalendarView.backgroundColor = bgColor
            self.btnNormalView.backgroundColor = .orange
        }
    }
}
