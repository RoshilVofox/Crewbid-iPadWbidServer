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
    
    //Variables
    
    var userFlagControlNoColor: UIControl!
    var userFlagControlYellow: UIControl!
    var userFlagControlOrange: UIControl!
    var userFlagControlRed: UIControl!
    var userFlagControlBlue: UIControl!
    var userFlagControlGreen: UIControl!
    var userFlagControlBrown: UIControl!
    var userFlagControlPink: UIControl!
    var variables: [String: Int]!
    var arrayVariables: [Int]!
    
    //Contants
    let kUserFlagFilterHorizontalSpace: CGFloat = 20.0
    let kUserFlagWidthHeight: CGFloat = 50.0
    let kUserFlagX: CGFloat = 60.0
    let kUserFlagY: CGFloat = 53.0
    let kUserCheckX: CGFloat = 220.0
    let kUserCheckY: CGFloat = 68.0
    
    var selectedFlagsIndexArray = [String]()
    var isCheck = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIDecoration()
    }
    
    private func UIDecoration() {
        flagCheckTableView.delegate = self
        flagCheckTableView.dataSource = self
        flagCheckTableView.isHidden = true
        
        variables = [String: Int]()
        arrayVariables = [Int]()
        
        // To get a rounded imageview with gray border
        //        noColorFlag
        
        noColorFlag.roundedImageViewWithGrayBorder()
        yellowFlag.roundedImageViewWithGrayBorder()
        orangeFlag.roundedImageViewWithGrayBorder()
        redFlag.roundedImageViewWithGrayBorder()
        blueFlag.roundedImageViewWithGrayBorder()
        greenFlag.roundedImageViewWithGrayBorder()
        brownFlag.roundedImageViewWithGrayBorder()
        pinkFlag.roundedImageViewWithGrayBorder()
        
        // Initially Unchecking Check Box
        
        checkNoColorFlag.addBorder()
        checkYellowFlag.addBorder()
        checkOrangeFlag.addBorder()
        checkRedFlag.addBorder()
        checkBlueFlag.addBorder()
        checkGreenFlag.addBorder()
        checkBrownFlag.addBorder()
        checkPinkFlag.addBorder()
        
    }
    @IBAction func btnCloseAction(_ sender: Any) {
        CBGlobalMethods.shared.selectedBidPeriod!.loadedPresetIdentifier = nil
        CBGlobalMethods.shared.selectedBidPeriod?.currentDateTime = Date()
        CBGlobalMethods.shared.selectedBidPeriod?.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didUpdateCheckBox(_ sender: UIButton) {
        CBGlobalMethods.shared.selectedBidPeriod!.loadedPresetIdentifier = nil
        CBGlobalMethods.shared.selectedBidPeriod?.currentDateTime = Date()
        CBGlobalMethods.shared.selectedBidPeriod?.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)
        let tag = sender.tag
        
        if selectedFlagsIndexArray.contains("\(tag)") {
            let tagIndex = selectedFlagsIndexArray.firstIndex(of: "\(tag)")
            if let tagIndex = tagIndex {
                selectedFlagsIndexArray.remove(at: tagIndex)
            }
            sender.addBorder()
            sender.layer.sublayers = nil
            switch sender.tag {
            case 0:
                removingUnselectedFlagFromArray(with: BISortNoColorVariablesKey, and: CBUserFlagType.none.rawValue)
            case 1:
                removingUnselectedFlagFromArray(with: BISortGreenColorVariablesKey, and: CBUserFlagType.green.rawValue)
            case 2:
                removingUnselectedFlagFromArray(with: BISortYellowVariablesKey, and: CBUserFlagType.yellow.rawValue)
            case 3:
                removingUnselectedFlagFromArray(with: BISortOrangeVariablesKey, and: CBUserFlagType.orange.rawValue)
            case 4:
                removingUnselectedFlagFromArray(with: BISortRedVariablesKey, and: CBUserFlagType.red.rawValue)
            case 5:
                removingUnselectedFlagFromArray(with: BISortBlueVariablesKey, and: CBUserFlagType.blue.rawValue)
            case 6:
                removingUnselectedFlagFromArray(with: BISortBrownVariablesKey, and: CBUserFlagType.brown.rawValue)
            case 7:
                removingUnselectedFlagFromArray(with: BISortPinkVariablesKey, and: CBUserFlagType.pink.rawValue)
            default:
                break
            }
        } else {
            selectedFlagsIndexArray.append("\(tag)")
            sender.addCheckMark()
            
            switch sender.tag {
            case 0:
                variables[BISortNoColorVariablesKey] = CBUserFlagType.none.rawValue
                arrayVariables.append(CBUserFlagType.none.rawValue)
            case 1:
                variables[BISortGreenColorVariablesKey] = CBUserFlagType.green.rawValue
                arrayVariables.append(CBUserFlagType.green.rawValue)
            case 2:
                variables[BISortYellowVariablesKey] = CBUserFlagType.yellow.rawValue
                arrayVariables.append(CBUserFlagType.yellow.rawValue)
            case 3:
                variables[BISortOrangeVariablesKey] = CBUserFlagType.orange.rawValue
                arrayVariables.append(CBUserFlagType.orange.rawValue)
            case 4:
                variables[BISortRedVariablesKey] = CBUserFlagType.red.rawValue
                arrayVariables.append(CBUserFlagType.red.rawValue)
            case 5:
                variables[BISortBlueVariablesKey] = CBUserFlagType.blue.rawValue
                arrayVariables.append(CBUserFlagType.blue.rawValue)
            case 6:
                variables[BISortBrownVariablesKey] = CBUserFlagType.brown.rawValue
                arrayVariables.append(CBUserFlagType.brown.rawValue)
            case 7:
                variables[BISortPinkVariablesKey] = CBUserFlagType.pink.rawValue
                arrayVariables.append(CBUserFlagType.pink.rawValue)
            default:
                break
            }
            
        }
    }
    
    private func removingUnselectedFlagFromArray(with key: String, and index: Int) {
        let vIndex = variables.firstIndex(where: {$0.key == key})
        let aIndex = arrayVariables.firstIndex(of: index)
        if let vIndex = vIndex {
            variables.remove(at: vIndex)
        }
        if let aIndex = aIndex {
            arrayVariables.remove(at: aIndex)
        }
    }
    
    @IBAction func btnAddAction(_ sender: Any) {
        if let variables = self.variables {
            if (!(variables.count > 0)) {
                let alert = UIAlertController(title: "CrewBid 2", message: "Please select any Flags", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "Ok", style: .default) { (action) in
                }
                alert.addAction(okAction)
                self.present(alert, animated: true, completion: nil)
                return;
            }
            self.lineSort = BILineSort(context: bidPeriod.managedObjectContext!)
            if (self.bidPeriod.isBidListSortOn?.boolValue == true){
                lineSort.isBidListSort = NSNumber(value: true)
            }else {
                lineSort.isBidListSort = NSNumber(value: false)
            }
            var dicDetails = [String: Any]()
            dicDetails["abbreviation"] = "flag"
            dicDetails["arrayVariables"] = arrayVariables
            dicDetails["category"] = NSNumber(10)
            dicDetails["name"] = "Flags"
            dicDetails["keyPath"] = "flagOrder"
            dicDetails["isMutable"] = NSNumber(1)
            dicDetails["ascending"] = NSNumber(1)
            dicDetails["variables"] = variables
            self.lineSort.setValuesForKeys(dicDetails)
            self.lineSort.order = self.nextSortOrder
            self.lineSort.bidPeriod = CBGlobalMethods.shared.selectedBidPeriod!
            
            var arrIndexValue: Int
            for i: Int in 0..<arrayVariables.count {
                arrIndexValue = arrayVariables[i]
                let notBlankPredicate = NSPredicate(format: "userFlagType == %d", arrIndexValue)
                let sortedLines = CBGlobalMethods.shared.selectedBidPeriod!.lines!.allObjects.filter { notBlankPredicate.evaluate(with: $0) } as! [BILine]
                for line in sortedLines {
                    line.flagOrder = NSNumber(integerLiteral: i)
                }
            }
            
            
            do {
                try CBGlobalMethods.shared.selectedBidPeriod!.managedObjectContext!.save()
            } catch {
                print(error)
            }
            DispatchQueue.main.async {
                self.dismiss(animated: true, completion: nil)
            }
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "DismissSortMenuTable"), object: self)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1){
                NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
            }
        } else {
            CBGlobalMethods.shared.ShowAlert(TitleString: "CrewBid 2", MessageString: "Please select any of these Flags")
        }
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


extension UIImageView {
    func roundedImageViewWithGrayBorder() {
        self.layer.borderColor = UIColor.gray.cgColor
        self.layer.borderWidth = 1.0
        self.layer.cornerRadius = self.frame.size.height / 2
    }
}

extension UIButton {
    func addBorder() {
        self.layer.cornerRadius = 8.0
        self.layer.borderWidth = 1.0
        self.layer.borderColor = UIColor.blue.cgColor
        
    }
    
    func addCheckMark() {
        
        let rect = self.frame
        let path = UIBezierPath()
        let shape = CAShapeLayer()
        let animator = CABasicAnimation(keyPath: "strokeEnd")
        let startPoint = CGPoint(x: 2.0, y: rect.height / 2)
        let point1 = CGPoint(x: rect.width * 0.4, y: rect.height * 0.80)
        let point2 = CGPoint(x: rect.width, y: 0.0)
        path.move(to: startPoint)
        path.addLine(to: point1)
        path.addLine(to: point2)
        
        animator.fromValue = 0.0
        animator.toValue = 1.0
        animator.duration = 0.3
        
        shape.strokeColor = UIColor.blue.cgColor
        shape.lineWidth = 3.0
        shape.fillColor = UIColor.clear.cgColor
        shape.path = path.cgPath
        shape.add(animator, forKey: "strokeEnd")
        self.layer.addSublayer(shape)
    }
}
