//
//  CBFlagSortPopUp.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 19/04/25.
//

import UIKit

class CBFlagSortPopUp: UIViewController {

    @IBOutlet weak var btnClose: UIButton!
    @IBOutlet weak var btnAdd: UIButton!
    @IBOutlet weak var flagCheckTableView: UITableView!
    
    @IBOutlet weak var noColorFlag: UIImageView!
    @IBOutlet weak var greenFlag: UIImageView!
    @IBOutlet weak var yellowFlag: UIImageView!
    @IBOutlet weak var orangeFlag: UIImageView!
    @IBOutlet weak var redFlag: UIImageView!
    @IBOutlet weak var blueFlag: UIImageView!
    @IBOutlet weak var brownFlag: UIImageView!
    @IBOutlet weak var pinkFlag: UIImageView!
    
    @IBOutlet weak var checkNoColorFlag: UIButton!
    @IBOutlet weak var checkGreenFlag: UIButton!
    @IBOutlet weak var checkYellowFlag: UIButton!
    @IBOutlet weak var checkOrangeFlag: UIButton!
    @IBOutlet weak var checkRedFlag: UIButton!
    @IBOutlet weak var checkBlueFlag: UIButton!
    @IBOutlet weak var checkBrownFlag: UIButton!
    @IBOutlet weak var checkPinkFlag: UIButton!
    
    var lineSort: BILineSort!
    var bidPeriod: BIBidPeriod!
    var nextSortOrder: NSNumber!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
}

class FlagCheckTableViewCell: UITableViewCell{
    
    @IBOutlet weak var imgFlag: UIImageView!
    @IBOutlet weak var imgCheckBox: UIImageView!
}

extension CBFlagSortPopUp: UITableViewDataSource, UITableViewDelegate{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FlagCheckTableViewCell") as! FlagCheckTableViewCell
        return cell
    }
    
    
}
