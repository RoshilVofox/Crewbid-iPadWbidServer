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

    }
    
}
