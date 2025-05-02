//
//  CBReportReleaseCollectionViewController.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 17/04/25.
//

import UIKit

class CBReportReleaseCollectionViewController: UIViewController,KUIPopOverUsable {
    var contentSize: CGSize {
        return CGSize(width: 400.0, height: 250)
    }
    @IBOutlet weak var calendarCollectionView: UICollectionView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
