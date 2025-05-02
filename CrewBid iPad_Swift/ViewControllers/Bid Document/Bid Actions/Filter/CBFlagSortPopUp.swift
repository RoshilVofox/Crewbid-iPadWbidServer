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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    


}
class FlagCheckTableViewCell{
    
    @IBOutlet weak var imgFlag: UIImageView!
    @IBOutlet weak var imgCheckBox: UIImageView!
}
