//
//  CBLineTypeRuleCell.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 24/03/25.
//

import UIKit

class CBLineTypeRuleCell: UITableViewCell {

    @IBOutlet weak var hardLinesButton: CBBorderToggleButton!
    @IBOutlet weak var mixedLinesButton: CBBorderToggleButton!
    @IBOutlet weak var conusButton: CBBorderToggleButton!
    @IBOutlet weak var nonConusButton: CBBorderToggleButton!
    @IBOutlet weak var reserveLinesButton: CBBorderToggleButton!
    @IBOutlet weak var blankLinesButton: CBBorderToggleButton!
    @IBOutlet weak var etopsButton: CBBorderToggleButton!
    @IBOutlet weak var etopsResButton: CBBorderToggleButton!
    @IBOutlet weak var lodoButton: CBBorderToggleButton!
    
    weak var etopsfilterRule: BIFilterRule?
    weak var etopsResfilterRule: BIFilterRule?
    var bidPeriod: BIBidPeriod!
    var isETOPSON : Bool = false
    var isETOPSRESON : Bool = false
    var buttonTextColor: UIColor = .white
    var backViewColor: UIColor = .white
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if bidPeriod.isFABid() == true {
            blankLinesButton.isHidden = true
            mixedLinesButton.isHidden = true
            hardLinesButton.isHidden = true
            etopsResButton.isHidden = true
            if bidPeriod.isFirstRoundBid() == true {
                reserveLinesButton.isHidden = true
            }
        }
        else {
            lodoButton.isHidden = true
            if bidPeriod.isFirstRoundBid() == true {
                mixedLinesButton.isHidden = true
                hardLinesButton.isHidden = true
            }
            else {
                conusButton.isHidden = true
                nonConusButton.isHidden = true
                blankLinesButton.isHidden = true
            }
        }
    }

    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func buttonAction(_ sender: CBBorderToggleButton) {
        self.bidPeriod.loadedPresetIdentifier = nil
        CBGlobalMethods.shared.selectedBidPeriod?.currentDateTime = Date()
        CBGlobalMethods.shared.selectedBidPeriod?.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)
        sender.isSelected = !sender.isSelected
        let SET = NSMutableSet()
        // for CP data
        if !bidPeriod.isFABid() == true {
            // first Round data
            if bidPeriod.isFirstRoundBid() {
                var Etopsvariables:NSDictionary = etopsfilterRule?.variables ?? [:]
                var EtopsResvariables:NSDictionary = etopsResfilterRule?.variables ?? [:]
                if hardLinesButton.isSelected {
                    SET.add(BILineType.HardLine.rawValue)
                }
                if bidPeriod.isEtopsLinesContainsInBid?.boolValue == true {
                    if reserveLinesButton.isSelected {
                        SET.add(BILineType.NonEtopsReserve.rawValue)
                    }
                    if conusButton.isSelected {
                        SET.add(BILineType.NonEtopsConUS.rawValue)
                    }
                    if nonConusButton.isSelected {
                        SET.add(BILineType.NonEtopsNonConUS.rawValue)
                    }
                } else {
                    if reserveLinesButton.isSelected {
                        SET.add(BILineType.ReserveLine.rawValue)
                    }
                    if conusButton.isSelected {
                        SET.add(BILineType.HardConUS.rawValue)
                    }
                    if nonConusButton.isSelected {
                        SET.add(BILineType.HardNonConUS.rawValue)
                    }
                }
                if blankLinesButton.isSelected {
                    SET.add(BILineType.BlankLine.rawValue)
                }
                if mixedLinesButton.isSelected {
                    SET.add(BILineType.MixedLine.rawValue)
                }
                
                if etopsButton == sender {
                    if bidPeriod.containsEBG?.boolValue == true {
                        let ETOPS_ON = sender.isSelected
                        Etopsvariables = NSDictionary(object: ETOPS_ON, forKey: "ETOPS_ON" as NSCopying)
                        etopsfilterRule?.variables = Etopsvariables
                    } else {
                        let Etops_On = Etopsvariables.value(forKey: "ETOPS_ON") as! Bool
                        if Etops_On == true {
                            isETOPSON = false
                            let ETOPS_ON = sender.isSelected
                            Etopsvariables = NSDictionary(object: ETOPS_ON, forKey: "ETOPS_ON" as NSCopying)
                            etopsfilterRule?.variables = Etopsvariables
                        } else {
                            etopsButton.isSelected = false
                            let objAlertController = UIAlertController(title: "Alert!", message: "You are NOT in the ETOPS Bid Group.  You should not bid the ETOPS lines as you will not be awarded any ETOPS line.", preferredStyle: UIAlertController.Style.alert)
                            objAlertController.addAction(UIAlertAction(title: "Leave ON", style: UIAlertAction.Style.default, handler:{ (UIAlertAction)in
                                self.isETOPSON = false
                                let ETOPS_ON = false
                                Etopsvariables = NSDictionary(object: ETOPS_ON, forKey: "ETOPS_ON" as NSCopying)
                                self.etopsfilterRule?.variables = Etopsvariables
                                self.etopsButton.isSelected = ETOPS_ON
                            }))
                            objAlertController.addAction(UIAlertAction(title: "Turn OFF", style: UIAlertAction.Style.default, handler:{ (UIAlertAction)in
                                self.isETOPSON = true
                                let ETOPS_ON = true
                                Etopsvariables = NSDictionary(object: ETOPS_ON, forKey: "ETOPS_ON" as NSCopying)
                                self.etopsfilterRule?.variables = Etopsvariables
                                self.etopsButton.isSelected = ETOPS_ON
                                self.etopsButton.isSelected = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
                                }
                            }))
                            UIApplication.shared.keyWindow?.rootViewController?.present(objAlertController, animated: true, completion: nil)
                        }
                    }
                }
                
                if etopsResButton == sender {
                    if bidPeriod.containsEBG?.boolValue == true {
                        let ETOPSRES_ON = sender.isSelected
                        EtopsResvariables = NSDictionary(object: ETOPSRES_ON, forKey: "ETOPSRES_ON" as NSCopying)
                        etopsResfilterRule?.variables = EtopsResvariables
                    } else {
                        let ETOPSRES_ON = EtopsResvariables.value(forKey: "ETOPSRES_ON") as! Bool
                        if ETOPSRES_ON == true {
                            isETOPSRESON = false
                            let ETOPSRES_ON = sender.isSelected
                            EtopsResvariables = NSDictionary(object: ETOPSRES_ON, forKey: "ETOPSRES_ON" as NSCopying)
                            etopsResfilterRule?.variables = EtopsResvariables
                        } else {
                            etopsResButton.isSelected = false
                            let objAlertController = UIAlertController(title: "Alert!", message: "You are NOT in the ETOPS Bid Group.  You should not bid the ETOPS lines as you will not be awarded any ETOPS line.", preferredStyle: UIAlertController.Style.alert)
                            objAlertController.addAction(UIAlertAction(title: "Leave ON", style: UIAlertAction.Style.default, handler:{ (UIAlertAction)in
                                self.isETOPSRESON = false
                                let ETOPSRES_ON = false
                                EtopsResvariables = NSDictionary(object: ETOPSRES_ON, forKey: "ETOPSRES_ON" as NSCopying)
                                self.etopsResfilterRule?.variables = EtopsResvariables
                                self.etopsResButton.isSelected = ETOPSRES_ON
                            }))
                            objAlertController.addAction(UIAlertAction(title: "Turn OFF", style: UIAlertAction.Style.default, handler:{ (UIAlertAction)in
                                self.isETOPSRESON = true
                                let ETOPSRES_ON = true
                                EtopsResvariables = NSDictionary(object: ETOPSRES_ON, forKey: "ETOPSRES_ON" as NSCopying)
                                self.etopsResfilterRule?.variables = EtopsResvariables
                                self.etopsResButton.isSelected = ETOPSRES_ON
                                self.etopsResButton.isSelected = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
                                }
                            }))
                            UIApplication.shared.keyWindow?.rootViewController?.present(objAlertController, animated: true, completion: nil)
                        }
                    }
                }
                if bidPeriod.isEtopsLinesContainsInBid?.boolValue == true {
                    SET.add(BILineType.HardConUS.rawValue)
                    SET.add(BILineType.HardNonConUS.rawValue)
                    SET.add(BILineType.ReserveLine.rawValue)
                    SET.add(BILineType.NonReserveEtops.rawValue)
                    SET.add(BILineType.EtopsReserve.rawValue)
                }
            }
            // Second Round data
            else {
                var Etopsvariables:NSDictionary = etopsfilterRule?.variables ?? [:]
                var EtopsResvariables:NSDictionary = etopsResfilterRule?.variables ?? [:]
                if bidPeriod.isEtopsLinesContainsInBid?.boolValue == true {
                    if hardLinesButton.isSelected {
                        SET.add(BILineType.NonEtopsHard.rawValue)
                    }
                    if reserveLinesButton.isSelected {
                        SET.add(BILineType.NonEtopsReserve.rawValue)
                    }
                    if mixedLinesButton.isSelected {
                        SET.add(BILineType.NonEtopsMixed.rawValue)
                    }
                } else {
                    if hardLinesButton.isSelected {
                        SET.add(BILineType.HardLine.rawValue)
                    }
                    if reserveLinesButton.isSelected {
                        SET.add(BILineType.ReserveLine.rawValue)
                    }
                    if mixedLinesButton.isSelected {
                        SET.add(BILineType.MixedLine.rawValue)
                    }
                }
                
                if blankLinesButton.isSelected {
                    SET.add(BILineType.BlankLine.rawValue)
                }
                if conusButton.isSelected {
                    SET.add(BILineType.HardConUS.rawValue)
                }
                if nonConusButton.isSelected {
                    SET.add(BILineType.HardConUS.rawValue)  // change in crewbid Ipad
                }
                
                if etopsButton == sender {
                    if bidPeriod.containsEBG?.boolValue == true {
                        let ETOPS_ON = sender.isSelected
                        Etopsvariables = NSDictionary(object: ETOPS_ON, forKey: "ETOPS_ON" as NSCopying)
                        etopsfilterRule?.variables = Etopsvariables
                    } else {
                        let Etops_On = Etopsvariables.value(forKey: "ETOPS_ON") as! Bool
                        if Etops_On == true {
                            isETOPSON = false
                            let ETOPS_ON = sender.isSelected
                            Etopsvariables = NSDictionary(object: ETOPS_ON, forKey: "ETOPS_ON" as NSCopying)
                            etopsfilterRule?.variables = Etopsvariables
                        } else {
                            etopsButton.isSelected = false
                            let objAlertController = UIAlertController(title: "Alert!", message: "You are NOT in the ETOPS Bid Group.  You should not bid the ETOPS lines as you will not be awarded any ETOPS line.", preferredStyle: UIAlertController.Style.alert)
                            objAlertController.addAction(UIAlertAction(title: "Leave ON", style: UIAlertAction.Style.default, handler:{ (UIAlertAction)in
                                self.isETOPSON = false
                                let ETOPS_ON = false
                                Etopsvariables = NSDictionary(object: ETOPS_ON, forKey: "ETOPS_ON" as NSCopying)
                                self.etopsfilterRule?.variables = Etopsvariables
                                self.etopsButton.isSelected = ETOPS_ON
                            }))
                            objAlertController.addAction(UIAlertAction(title: "Turn OFF", style: UIAlertAction.Style.default, handler:{ (UIAlertAction)in
                                self.isETOPSON = true
                                let ETOPS_ON = true
                                Etopsvariables = NSDictionary(object: ETOPS_ON, forKey: "ETOPS_ON" as NSCopying)
                                self.etopsfilterRule?.variables = Etopsvariables
                                self.etopsButton.isSelected = ETOPS_ON
                                self.etopsButton.isSelected = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
                                }
                            }))
                            UIApplication.shared.keyWindow?.rootViewController?.present(objAlertController, animated: true, completion: nil)
                        }
                    }
                }
                if etopsResButton == sender {
                    if bidPeriod.containsEBG?.boolValue == true {
                        let ETOPSRES_ON = sender.isSelected
                        EtopsResvariables = NSDictionary(object: ETOPSRES_ON, forKey: "ETOPSRES_ON" as NSCopying)
                        etopsResfilterRule?.variables = EtopsResvariables
                    } else {
                        let ETOPSRES_ON = EtopsResvariables.value(forKey: "ETOPSRES_ON") as! Bool
                        if ETOPSRES_ON == true {
                            isETOPSRESON = false
                            let ETOPSRES_ON = sender.isSelected
                            EtopsResvariables = NSDictionary(object: ETOPSRES_ON, forKey: "ETOPSRES_ON" as NSCopying)
                            etopsResfilterRule?.variables = EtopsResvariables
                        } else {
                            etopsResButton.isSelected = false
                            let objAlertController = UIAlertController(title: "Alert!", message: "You are NOT in the ETOPS Bid Group.  You should not bid the ETOPS lines as you will not be awarded any ETOPS line.", preferredStyle: UIAlertController.Style.alert)
                            objAlertController.addAction(UIAlertAction(title: "Leave ON", style: UIAlertAction.Style.default, handler:{ (UIAlertAction)in
                                self.isETOPSRESON = false
                                let ETOPSRES_ON = false
                                EtopsResvariables = NSDictionary(object: ETOPSRES_ON, forKey: "ETOPSRES_ON" as NSCopying)
                                self.etopsResfilterRule?.variables = EtopsResvariables
                                self.etopsResButton.isSelected = ETOPSRES_ON
                            }))
                            objAlertController.addAction(UIAlertAction(title: "Turn OFF", style: UIAlertAction.Style.default, handler:{ (UIAlertAction)in
                                self.isETOPSRESON = true
                                let ETOPSRES_ON = true
                                EtopsResvariables = NSDictionary(object: ETOPSRES_ON, forKey: "ETOPSRES_ON" as NSCopying)
                                self.etopsResfilterRule?.variables = EtopsResvariables
                                self.etopsResButton.isSelected = ETOPSRES_ON
                                self.etopsResButton.isSelected = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
                                }
                            }))
                            UIApplication.shared.keyWindow?.rootViewController?.present(objAlertController, animated: true, completion: nil)
                        }
                    }
                }
                if bidPeriod.isEtopsLinesContainsInBid?.boolValue == true {
                    SET.add(BILineType.HardLine.rawValue)
                    SET.add(BILineType.MixedLine.rawValue)
                    SET.add(BILineType.ReserveLine.rawValue)
                    SET.add(BILineType.NonReserveEtops.rawValue)
                    SET.add(BILineType.EtopsReserve.rawValue)
                }
            }
        }
        // for FA data
        else {
            // first Round data
            if bidPeriod.isFirstRoundBid() {
                var Etopsvariables = etopsfilterRule?.variables
                if bidPeriod.isEtopsLinesContainsInBid?.boolValue == true {
                    if conusButton.isSelected {
                        SET.add(BILineType.NonEtopsConUS.rawValue)
                    }
                    if nonConusButton.isSelected {
                        SET.add(BILineType.NonEtopsNonConUS.rawValue)
                    }
                } else {
                    if conusButton.isSelected {
                        SET.add(BILineType.HardConUS.rawValue)
                    }
                    if nonConusButton.isSelected {
                        SET.add(BILineType.HardNonConUS.rawValue)
                    }
                }
                if etopsButton == sender {
                    let ETOPS_ON = sender.isSelected
                    Etopsvariables = NSDictionary(object: ETOPS_ON, forKey: "ETOPS_ON" as NSCopying)
                    etopsfilterRule?.variables = Etopsvariables
                }
                if bidPeriod.isEtopsLinesContainsInBid?.boolValue == true {
                    SET.add(BILineType.HardConUS.rawValue)
                    SET.add(BILineType.HardNonConUS.rawValue)
                    SET.add(BILineType.EtopsFAFirstRound.rawValue)
                    if (!self.nonConusButton.isSelected && !self.conusButton.isSelected && self.etopsButton.isSelected ) {
                        SET.removeAllObjects()
                        SET.add(BILineType.EtopsFAFirstRound.rawValue)
                    }
                }
            } else {
                // Second Round data
                var Etopsvariables = etopsfilterRule?.variables
                if bidPeriod.isEtopsLinesContainsInBid?.boolValue == true {
                    if reserveLinesButton.isSelected {
                        SET.add(BILineType.NonEtopsReserve.rawValue)
                    }
                    if conusButton.isSelected {
                        SET.add(BILineType.NonEtopsConUS.rawValue)
                    }
                    if nonConusButton.isSelected {
                        SET.add(BILineType.NonEtopsNonConUS.rawValue)
                    }
                } else {
                    if conusButton.isSelected {
                        SET.add(BILineType.HardConUS.rawValue)
                    }
                    if reserveLinesButton.isSelected {
                        SET.add(BILineType.ReserveLine.rawValue)
                    }
                    if nonConusButton.isSelected {
                        SET.add(BILineType.HardNonConUS.rawValue)
                    }
                }
                if etopsButton == sender {
                    let ETOPS_ON = sender.isSelected
                    Etopsvariables = NSDictionary(object: ETOPS_ON, forKey: "ETOPS_ON" as NSCopying)
                    etopsfilterRule?.variables = Etopsvariables
                }
                if bidPeriod.isEtopsLinesContainsInBid?.boolValue == true {
                    SET.add(BILineType.HardConUS.rawValue)
                    SET.add(BILineType.HardNonConUS.rawValue)
                    SET.add(BILineType.ReserveLine.rawValue)
                    SET.add(BILineType.NonReserveEtops.rawValue)
                    if (!self.nonConusButton.isSelected && !self.conusButton.isSelected && !self.reserveLinesButton.isSelected && self.etopsButton.isSelected ) {
                        SET.removeAllObjects()
                        SET.add(BILineType.NonReserveEtops.rawValue)
                    }
                    if (!self.conusButton.isSelected && !self.nonConusButton.isSelected && self.reserveLinesButton.isSelected && self.etopsButton.isSelected ) {
                        SET.removeAllObjects()
                        SET.add(BILineType.ReserveLine.rawValue)
                        SET.add(BILineType.NonEtopsReserve.rawValue)
                        SET.add(BILineType.NonReserveEtops.rawValue)
                    }
                }
            }
            if lodoButton.isSelected {
                SET.add(BILineType.BILineTypeLoDo.rawValue)
            }
        }
        let dict  = NSDictionary(object: SET, forKey: "SET" as NSCopying)
        filterRule.variables = dict
        try? CBGlobalMethods.shared.selectedBidPeriod!.managedObjectContext!.save()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
        }
    }
    
    
    private var _filterRule: BIFilterRule?
    var filterRule: BIFilterRule  {
        get {
            //code to execute
            return _filterRule!
        }
        set(newValue) {
            _filterRule = newValue
            if self.filterRule != filterRule {
                //self.filterRule = filterRule
            }
            // for CP data
            if !bidPeriod!.isFABid() == true {
                // first Round data
                if bidPeriod.isFirstRoundBid() {
                    var Etopsvariables = etopsfilterRule?.variables
                    var EtopsResvariables = etopsResfilterRule?.variables
                    var variables = NSSet()
                    if let value = filterRule.variables?["SET"] {
                        if let set = value as? NSSet {
                            variables = set
                        } else if let array = value as? [Any] {
                            variables = NSSet(array: array)
                        } else {
                            print("Unexpected type:", type(of: value))
                        }
                    }

//                    let variables = filterRule.variables?["SET"] as! NSSet
                    let arrVariables = NSMutableArray(array:variables.allObjects)
                    hardLinesButton.isSelected = arrVariables.contains(BILineType.HardLine.rawValue)
                    if bidPeriod.isEtopsLinesContainsInBid?.boolValue == true {
                        reserveLinesButton.isSelected = arrVariables.contains(BILineType.NonEtopsReserve.rawValue)
                        nonConusButton.isSelected = arrVariables.contains(BILineType.NonEtopsNonConUS.rawValue)
                        conusButton.isSelected = arrVariables.contains(BILineType.NonEtopsConUS.rawValue)
                    } else {
                        reserveLinesButton.isSelected = arrVariables.contains(BILineType.ReserveLine.rawValue)
                        nonConusButton.isSelected = arrVariables.contains(BILineType.HardNonConUS.rawValue)
                        conusButton.isSelected = arrVariables.contains(BILineType.HardConUS.rawValue)
                    }
                    
                    blankLinesButton.isSelected = arrVariables.contains(BILineType.BlankLine.rawValue)
                    mixedLinesButton.isSelected = arrVariables.contains(BILineType.MixedLine.rawValue)
                    if bidPeriod.containsEBG?.boolValue == true {
                        let EtopsOn = Etopsvariables!["ETOPS_ON"] as! Bool
                        etopsButton.isSelected = EtopsOn
                        
                        let EtopsResOn = EtopsResvariables!["ETOPSRES_ON"] as! Bool
                        etopsResButton.isSelected = EtopsResOn
                    } else {
                        let ETOPS_ON = Etopsvariables?.value(forKey: "ETOPS_ON") as? Bool ?? true
                        Etopsvariables = NSDictionary(object: ETOPS_ON, forKey: "ETOPS_ON" as NSCopying)
                        etopsfilterRule?.variables = Etopsvariables
                        etopsButton.isSelected = ETOPS_ON
                        
                        let ETOPSRES_ON = EtopsResvariables?.value(forKey: "ETOPSRES_ON") as? Bool ?? true
                        EtopsResvariables = NSDictionary(object: ETOPSRES_ON, forKey: "ETOPSRES_ON" as NSCopying)
                        etopsResfilterRule?.variables = EtopsResvariables
                        etopsResButton.isSelected = ETOPSRES_ON
                    }
                } else {
                    // Second Round data
                    var Etopsvariables = etopsfilterRule?.variables
                    var EtopsResvariables = etopsResfilterRule?.variables
                    var variables: Set<NSNumber> = NSSet() as! Set<NSNumber>
                    if let value = filterRule.variables?["SET"] {
                        if let set = value as? NSSet {
                            variables = set as! Set<NSNumber>
                        } else if let array = value as? [Any] {
                            variables = NSSet(array: array) as! Set<NSNumber>
                        } else {
                            print("Unexpected type:", type(of: value))
                        }
                    }
                    let arrVariables = NSMutableArray(array: Array(variables))
              //      hardLinesButton.isSelected = arrVariables.contains(BILineType.BIHardLineType.rawValue)
                    if bidPeriod.isEtopsLinesContainsInBid?.boolValue == true {
                        hardLinesButton.isSelected = arrVariables.contains(BILineType.NonEtopsHard.rawValue)
                        reserveLinesButton.isSelected = arrVariables.contains(BILineType.NonEtopsReserve.rawValue)
                        mixedLinesButton.isSelected = arrVariables.contains(BILineType.NonEtopsMixed.rawValue)
                    } else {
                        hardLinesButton.isSelected = arrVariables.contains(BILineType.HardLine.rawValue)
                        mixedLinesButton.isSelected = arrVariables.contains(BILineType.MixedLine.rawValue)
                        reserveLinesButton.isSelected = arrVariables.contains(BILineType.ReserveLine.rawValue)
                    }
                    blankLinesButton.isSelected = arrVariables.contains(BILineType.BlankLine.rawValue)
                    nonConusButton.isSelected = arrVariables.contains(BILineType.HardNonConUS.rawValue)
                    conusButton.isSelected = arrVariables.contains(BILineType.HardConUS.rawValue)
                    if bidPeriod.containsEBG?.boolValue == true {
                        if Etopsvariables != nil {
                            let EtopsOn = Etopsvariables?.value(forKey: "ETOPS_ON") as? Bool ?? true
                            etopsButton.isSelected = EtopsOn
                            let EtopsResOn = EtopsResvariables!.value(forKey: "ETOPSRES_ON") as! Bool
                            etopsResButton.isSelected = EtopsResOn
                        }
                    } else {
                        if Etopsvariables != nil {
                            isETOPSON = Etopsvariables?.value(forKey: "ETOPS_ON") as? Bool ?? true
                            let ETOPS_ON = isETOPSON
                            Etopsvariables = NSDictionary(object: ETOPS_ON, forKey: "ETOPS_ON" as NSCopying)
                            etopsfilterRule?.variables = Etopsvariables
                            etopsButton.isSelected = ETOPS_ON
                            
                            isETOPSRESON = EtopsResvariables?.value(forKey: "ETOPSRES_ON") as? Bool ?? true
                            let ETOPSRES_ON = isETOPSRESON
                            EtopsResvariables = NSDictionary(object: ETOPSRES_ON, forKey: "ETOPSRES_ON" as NSCopying)
                            etopsResfilterRule?.variables = EtopsResvariables
                            etopsResButton.isSelected = ETOPSRES_ON
                        }
                    }
                    
                    
                }
            } else {  // for FA data
                // first Round data
                if bidPeriod.isFirstRoundBid() {
                    let Etopsvariables = etopsfilterRule?.variables
                    if filterRule.category?.intValue == 1 {
                        print("")
                    }
                    var variables = NSSet()
                    if let value = filterRule.variables?["SET"] {
                        if let set = value as? NSSet {
                            variables = set
                        } else if let array = value as? [Any] {
                            variables = NSSet(array: array)
                        } else {
                            print("Unexpected type:", type(of: value))
                        }
                    }
                    let arrVariables = NSMutableArray(array:variables.allObjects)
                    if bidPeriod.isEtopsLinesContainsInBid?.boolValue == true {
                        nonConusButton.isSelected = arrVariables.contains(BILineType.NonEtopsNonConUS.rawValue)
                        conusButton.isSelected = arrVariables.contains(BILineType.NonEtopsConUS.rawValue)
                        lodoButton.isSelected = arrVariables.contains(BILineType.BILineTypeLoDo.rawValue)
                    } else {
                        nonConusButton.isSelected = arrVariables.contains(BILineType.HardNonConUS.rawValue)
                        conusButton.isSelected = arrVariables.contains(BILineType.HardConUS.rawValue)
                        lodoButton.isSelected = arrVariables.contains(BILineType.BILineTypeLoDo.rawValue)
                    }
                    let EtopsOn = Etopsvariables?.value(forKey: "ETOPS_ON") as? Bool ?? true
                    etopsButton.isSelected = EtopsOn
                } else {
                    // Second Round data
                    let Etopsvariables = etopsfilterRule?.variables
                    var variables = NSSet()
                    if let value = filterRule.variables?["SET"] {
                        if let set = value as? NSSet {
                            variables = set
                        } else if let array = value as? [Any] {
                            variables = NSSet(array: array)
                        } else {
                            print("Unexpected type:", type(of: value))
                        }
                    }
                    let arrVariables = NSMutableArray(array:variables.allObjects)
                    if bidPeriod.isEtopsLinesContainsInBid?.boolValue == true {
                        reserveLinesButton.isSelected = arrVariables.contains(BILineType.NonEtopsReserve.rawValue)
                        nonConusButton.isSelected = arrVariables.contains(BILineType.NonEtopsNonConUS.rawValue)
                        conusButton.isSelected = arrVariables.contains(BILineType.NonEtopsConUS.rawValue)
                        lodoButton.isSelected = arrVariables.contains(BILineType.BILineTypeLoDo.rawValue)
                    } else {
                        nonConusButton.isSelected = arrVariables.contains(BILineType.HardNonConUS.rawValue)
                        conusButton.isSelected = arrVariables.contains(BILineType.HardConUS.rawValue)
                        reserveLinesButton.isSelected = arrVariables.contains(BILineType.ReserveLine.rawValue)
                        lodoButton.isSelected = arrVariables.contains(BILineType.BILineTypeLoDo.rawValue)
                    }
                    let EtopsOn = Etopsvariables?.value(forKey: "ETOPS_ON") as? Bool ?? true
                    etopsButton.isSelected = EtopsOn
                }
            }
        }
    }
        
}
