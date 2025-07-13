//
//  CBUserFlagTableController.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 19/04/25.
//

import UIKit

@objc enum CBUserFlagType : Int {
    case none
    case blue
    case green
    case red
    case yellow
    case orange
    case brown
    case pink
}

let kFlagImageTag: Int = 112
protocol CBUserFlagTableControllerDelegate {
    func changeLineUserFlagTypeTo(flagType: CBUserFlagType, selectedLine: BILine?)
    
}

class CBUserFlagTableController: UIViewController,UITableViewDelegate,UITableViewDataSource,KUIPopOverUsable {

    init(style: UITableView.Style) {
        super.init(nibName: nil, bundle: nil)
       userFlags = NSMutableArray()
       userFlagColors = NSDictionary ()
       userFlags = [CBUserFlagType.none,
                    CBUserFlagType.green,         // Green
                    CBUserFlagType.yellow,         // Yellow
                    CBUserFlagType.orange,
                    CBUserFlagType.red,         // Red
                    CBUserFlagType.blue,         // Blue
                    CBUserFlagType.brown,         //Brown
                    CBUserFlagType.pink          //Pink
       ]
       userFlagColors = [CBUserFlagType.none: UIColor.clear,
                         CBUserFlagType.green: CBColor.faPosBColor,         // Green
                         CBUserFlagType.yellow: CBColor.faPosCColor,         // Yellow
                         CBUserFlagType.orange: UIColor.orange,
                         CBUserFlagType.red: CBColor.faPosDColor,         // Red
                         CBUserFlagType.blue: CBColor.faPosAColor,
                         CBUserFlagType.brown: CBColor.oldbrownColor,
                         CBUserFlagType.pink: UIColor.systemPink.withAlphaComponent(0.8)] // Blue
   }
   
   required init?(coder aDecoder: NSCoder) {
       super.init(coder: aDecoder)
       userFlags = NSMutableArray()
       userFlagColors = NSDictionary ()
       userFlags = [CBUserFlagType.none.rawValue,
                    CBUserFlagType.green.rawValue,         // Green
                    CBUserFlagType.yellow.rawValue,         // Yellow
                    CBUserFlagType.orange.rawValue,
                    CBUserFlagType.red.rawValue,         // Red
                    CBUserFlagType.blue.rawValue,         // Blue
                    CBUserFlagType.brown.rawValue,         // Brown
                    CBUserFlagType.pink.rawValue        // Pink
       ]
       userFlagColors = [CBUserFlagType.none.rawValue: UIColor.clear,
                         CBUserFlagType.green.rawValue: CBColor.faPosBColor,         // Green
                         CBUserFlagType.yellow.rawValue: CBColor.faPosCColor,         // Yellow
                         CBUserFlagType.orange.rawValue: UIColor.orange,
                         CBUserFlagType.red.rawValue: CBColor.faPosDColor,         // Red
                         CBUserFlagType.blue.rawValue: CBColor.faPosAColor,
                         CBUserFlagType.brown.rawValue: CBColor.oldbrownColor,
                         CBUserFlagType.pink.rawValue: UIColor.systemPink.withAlphaComponent(0.8)]
   }

    var contentSize: CGSize {
        return CGSize(width: 64.0, height: 360)
    }
    
    @IBOutlet weak var userFlagTable: UITableView!
    var userFlags :NSMutableArray = NSMutableArray()
    var userFlagColors: NSDictionary = NSDictionary()
    var arrowDirection: UIPopoverArrowDirection = [.up,.down]
    var line:BILine?
    var delegate: CBUserFlagTableControllerDelegate? = nil
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        userFlagTable.rowHeight = 52
        userFlagTable.layer.cornerRadius = 10
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 8
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableView.frame.height / 8
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "UserFlagCell")!
        let circleDiameter: CGFloat = 35.0
        let flagColor = userFlagColors[userFlags[indexPath.row]]
        let circleView: UIControl = CBUserFlagTableController.userFlagControlForColor(color: flagColor as! UIColor, diameter: circleDiameter)
        circleView.tag = 500
        circleView.isUserInteractionEnabled = false
        // Figure out the X and Y offset
        var frame: CGRect? = circleView.frame
        var height: CGFloat = 44.0
        height -= circleDiameter
        height /= 2.0
        frame?.origin.y = height
        var width: CGFloat = 44.0
        width -= circleDiameter
        width /= 2.0
        frame?.origin.x = width
        circleView.frame = frame!
        circleView.alpha = 1
        if indexPath.row == 0 {
            circleView.alpha = 1
        }
        cell.contentView.addSubview(circleView)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        CBGlobalMethods.shared.selectedBidPeriod!.loadedPresetIdentifier = nil
        CBGlobalMethods.shared.selectedBidPeriod?.currentDateTime = Date()
        CBGlobalMethods.shared.selectedBidPeriod?.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)
        let flag = userFlags[indexPath.row]
        let flagTypeValue = CBUserFlagType(rawValue: flag as! Int)
        delegate?.changeLineUserFlagTypeTo(flagType: flagTypeValue!, selectedLine: line ?? nil)
        self.dismissPopover(animated: true)
    }
    
    @objc class func userFlagControlForColor(color: UIColor, diameter: CGFloat) -> UIControl {
        
        let circleView = UIControl(frame: CGRect(x: 0.0, y: 0.0, width: diameter, height: diameter))
        circleView.layer.cornerRadius = diameter / 2.0
        circleView.backgroundColor = color
        // Add the flag silhouette icon fill with only a % of the circle
        let flagDiameter: CGFloat = diameter * 0.6
        var flagImage: UIImageView? = nil
        flagImage = UIImageView(image: UIImage(named: "flag1"))
        //}
        flagImage?.frame = CGRect(x: 0.0, y: 0.0, width: flagDiameter, height: flagDiameter)
        // Center the flag in the view
        var frame: CGRect? = flagImage?.frame
        frame?.origin.x = (diameter - flagDiameter) / 2.0
        frame?.origin.y = (diameter - flagDiameter) / 2.0
        flagImage?.frame = frame!
        flagImage?.tag = 112
        circleView.addSubview(flagImage ?? UIView())
        //circleView.layer.borderWidth = 0.5;
        return circleView
    }
    
    @objc class func colorForUserFlagType(flagType: CBUserFlagType) -> UIColor  {
        var color: UIColor? = nil
        switch flagType {
        case CBUserFlagType.none:
            color = UIColor.clear
            
        case CBUserFlagType.yellow:
            color = CBColor.faPosCColor
            
        case CBUserFlagType.orange:
            color = UIColor.orange
            
        case CBUserFlagType.red:
            color = CBColor.faPosDColor
            
        case CBUserFlagType.green:
            color = CBColor.faPosBColor
            
        case CBUserFlagType.blue:
            color = CBColor.faPosAColor
            
        case CBUserFlagType.brown:
            color = CBColor.oldbrownColor
            
        case CBUserFlagType.pink:
            color = UIColor.systemPink.withAlphaComponent(0.8)
            
        }
        return color ?? UIColor.clear
    }
    
    

}
