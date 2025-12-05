//
//  CBFlagSortCell.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 24/03/25.
//

import UIKit
import CoreData

class CBFlagSortCell: UITableViewCell {
    
    @IBOutlet weak var objFlagTableView: UITableView!
    private var lineSort1: BILineSort!
    var lineSort2: BILineSort!
    var bidPeriod: BIBidPeriod!
    var context = CBGlobalMethods.shared.selectedBidPeriod?.managedObjectContext
    var sortRule: [BILineSort] = []
    
    var lineSort: BILineSort? {
        set(newLineSort){
           lineSort1 = newLineSort
        }
        get {
            return lineSort1
        }
    }
    
    private var myReorderImage : UIImage? = nil
    var userFlags: [Int]!
    var userFlagColors: [UIColor]!
    var lines: [BILine] = []

    override func awakeFromNib() {
        super.awakeFromNib()
        
        objFlagTableView.isEditing = true
        
        objFlagTableView.delegate = self
        objFlagTableView.dataSource = self
        bidPeriod = CBGlobalMethods.shared.selectedBidPeriod
        
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        self.lineSort?.ascending = NSNumber(booleanLiteral: true)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if self.lineSort?.arrayVariables != nil {
            let arrayVariables = self.lineSort?.arrayVariables as! [NSNumber]
            userFlags = [Int]()
            userFlagColors = [UIColor]()
            
            for variable in arrayVariables {
                switch variable.intValue {
                case 0:
                    userFlags.append(CBUserFlagType.none.rawValue)
                    userFlagColors.append(.clear)
                    break
                case 1:
                    userFlags.append(CBUserFlagType.blue.rawValue)
                    userFlagColors.append(CBColor.faPosAColor)
                    break
                case 2:
                    userFlags.append(CBUserFlagType.green.rawValue)
                    userFlagColors.append(CBColor.faPosBColor)
                    break
                case 3:
                    userFlags.append(CBUserFlagType.red.rawValue)
                    userFlagColors.append(CBColor.faPosDColor)
                    break
                case 4:
                    userFlags.append(CBUserFlagType.yellow.rawValue)
                    userFlagColors.append(CBColor.faPosCColor)
                    break
                case 5:
                    userFlags.append(CBUserFlagType.orange.rawValue)
                    userFlagColors.append(.orange)
                    break
                case 6:
                    userFlags.append(CBUserFlagType.brown.rawValue)
                    userFlagColors.append(CBColor.oldbrownColor)
                    break
                case 7:
                    userFlags.append(CBUserFlagType.pink.rawValue)
                    userFlagColors.append(UIColor.systemPink.withAlphaComponent(0.8))
                    break
                default:
                    break
                }
            }
        }
    }
    
    func resetFlagOrder() {
        var arrIndexValue: Int
        for line in lines {
            if userFlags.contains(line.userFlagType!.intValue) {
                line.flagOrder = NSNumber(integerLiteral: 8)
            }
            for i in 0..<userFlags.count {
                arrIndexValue = userFlags[i]
                let notBlankPredicate = NSPredicate(format: "userFlagType == %d", arrIndexValue)
                let sortedLines = lines.filter { notBlankPredicate.evaluate(with: $0) }
                for line in sortedLines {
                    line.flagOrder = NSNumber(integerLiteral: i)
                }
            }
            do {
                try context?.save()
            }
            catch {
                print("error saving rest flag order \(error.localizedDescription)")
            }
        }
    }
    
    func configureFlagSortCell() {
        let fetchSort: NSFetchRequest <BILineSort> = BILineSort.fetchRequest()
        fetchSort.sortDescriptors = [NSSortDescriptor(key: "category", ascending: true), NSSortDescriptor(key: "type", ascending: true)]
        let predicate1 = NSPredicate(format: "category == 10")
        let predicate2 = NSPredicate(format: "bidPeriod == %@", bidPeriod!)
        let combinedPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate1, predicate2])
        fetchSort.predicate = combinedPredicate
        
        let fetchLine: NSFetchRequest <BILine> = BILine.fetchRequest()
        fetchLine.predicate = predicate2
        fetchLine.sortDescriptors = [NSSortDescriptor(key: "number", ascending: true)]
        
        do {
            sortRule = try context!.fetch(fetchSort)
            lines = try context!.fetch(fetchLine)
            if sortRule.count > 0 {
                self.lineSort = sortRule[0]
                var arrayVariables = self.lineSort?.arrayVariables as? [NSNumber]
                if arrayVariables == nil {
                    if let dict = self.lineSort?.variables as? [String: Any] {
                        arrayVariables = dict.values.compactMap { $0 as? NSNumber }
                    }
                    self.lineSort?.arrayVariables = arrayVariables as NSArray?
                }
                userFlags = [Int]()
                userFlagColors = [UIColor]()
                
                for variable in arrayVariables! {
                    switch variable.intValue {
                    case 0:
                        userFlags.append(CBUserFlagType.none.rawValue)
                        userFlagColors.append(.clear)
                        break
                    case 1:
                        userFlags.append(CBUserFlagType.blue.rawValue)
                        userFlagColors.append(CBColor.faPosAColor)
                        break
                    case 2:
                        userFlags.append(CBUserFlagType.green.rawValue)
                        userFlagColors.append(CBColor.faPosBColor)
                        break
                    case 3:
                        userFlags.append(CBUserFlagType.red.rawValue)
                        userFlagColors.append(CBColor.faPosDColor)
                        break
                    case 4:
                        userFlags.append(CBUserFlagType.yellow.rawValue)
                        userFlagColors.append(CBColor.faPosCColor)
                        break
                    case 5:
                        userFlags.append(CBUserFlagType.orange.rawValue)
                        userFlagColors.append(.orange)
                        break
                    case 6:
                        userFlags.append(CBUserFlagType.brown.rawValue)
                        userFlagColors.append(CBColor.oldbrownColor)
                        break
                    case 7:
                        userFlags.append(CBUserFlagType.pink.rawValue)
                        userFlagColors.append(UIColor.systemPink.withAlphaComponent(0.8))
                        break
                    default:
                        break
                    }
                }
                
                self.lineSort!.arrayVariables = userFlags as NSArray
                self.lineSort!.ascending = NSNumber(booleanLiteral: true)
                try? self.context?.save()
            }
        }
        catch {
            print("Error fetching data \(error.localizedDescription)")
        }
    }

    @IBAction func btnCloseAction(_ sender: Any) {
        CBGlobalMethods.shared.selectedBidPeriod!.loadedPresetIdentifier = nil
        CBGlobalMethods.shared.selectedBidPeriod?.currentDateTime = Date()
        CBGlobalMethods.shared.selectedBidPeriod?.isStateFileModifiedToSync = NSNumber(booleanLiteral: true)
        for line in lines {
            line.flagOrder = NSNumber(integerLiteral: 8) //CBUserFlagType.none
        }
        try? CBGlobalMethods.shared.selectedBidPeriod!.managedObjectContext!.save()
        var dicDetails = [String: Any]()
        let newArray = [Any]()
        let arrVariables = [Any]()
        dicDetails["variables"] = newArray
        self.lineSort?.arrayVariables = arrVariables as NSArray
        self.lineSort?.variables = dicDetails as NSDictionary
        userFlags.removeAll()
        userFlagColors.removeAll()
        
        context!.delete(lineSort!)
        do {
            try context?.save()
        }
        catch {
            print("Error deleting object \(error.localizedDescription)")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2){
            NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
        }
    }
}

extension CBFlagSortCell: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let userFalgs = self.userFlags {
            return userFalgs.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SortflagCell", for: indexPath)
        cell.selectionStyle = .none
        cell.showsReorderControl = true
        // Get rid of any old views in the cell content view
        let oldView = cell.contentView.viewWithTag(500)
        if oldView != nil {
            oldView?.removeFromSuperview()
        }
//        configure the cell
        let circleDiameter: CGFloat = 40
        let originRow = indexPath.row
        let flagColor = userFlagColors[originRow]
        let circleView = CBUserFlagTableController.userFlagControlForColor(color: flagColor, diameter: circleDiameter)
        circleView.tag = 500
        circleView.isUserInteractionEnabled = false
//        figure out x an y offset
        var frame = circleView.frame
        var height: CGFloat = 50
        height -= circleDiameter
        height /= 2.0
        frame.origin.y = height
        var width: CGFloat = 50
        width -= circleDiameter
        width /= 2.0
        frame.origin.x = width
        circleView.frame = frame
        circleView.layer.borderWidth = 1.5
        circleView.layer.borderColor = UIColor.systemGray.cgColor
        cell.contentView.addSubview(circleView)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    

    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return UITableViewCell.EditingStyle.none
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let originRow = sourceIndexPath.row
        let destRow = destinationIndexPath.row
        if originRow == destRow {
            return
        }
        let object = userFlags[originRow]
        userFlags.remove(at: originRow)
        userFlags.insert(object, at: destRow)
        let objColor = userFlagColors[originRow]
        userFlagColors.remove(at: originRow)
        userFlagColors.insert(objColor, at: destRow)
        self.resetFlagOrder()
        self.lineSort?.arrayVariables = userFlags as NSArray
        self.lineSort?.ascending = NSNumber(booleanLiteral: true)
        
        do {
//            try context?.save()
            self.configureFlagSortCell()
        }
        catch {
            print("error saving flag while moving \(error.localizedDescription)")
        }
        self.objFlagTableView.reloadData()
        NotificationCenter.default.post(name: NSNotification.Name("refreshLines"), object: self)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 10 // adjust as needed
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView() // return empty view
    }

}
