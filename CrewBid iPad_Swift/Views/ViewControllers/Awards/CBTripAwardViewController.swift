//
//  CBTripAwardViewController.swift
//  CrewBid iPad_Swift
//
//  Created by Developer on 17/04/25.
//

import UIKit
import CoreData

class CBTripAwardViewController: BaseViewController {
    
    @IBOutlet weak var lblMonthTitle: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var txtTripID: customUITextField!
    @IBOutlet weak var txtPosition: customUITextField!
    @IBOutlet weak var viewWeekDays: UIView!
    @IBOutlet weak var btnClose: UIButton!
    var collectionCellCalendarDaysArr = [Any]()
    var calendarData = BICalendarData()
    var calendarDayArr : [BICalendarDay] = []
    public var bidPeriod: BIBidPeriod!
    var tripStartDate: Date?
    var startDateToString: String?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    func setupUI() {
        btnClose.setTitle("", for: .normal)
        txtTripID.delegate = self
        txtPosition.delegate = self
        self.bidPeriod = CBGlobalMethods.shared.selectedBidPeriod
        calendarData = calendarData.initWithBidPeriod(bidPeriod: self.bidPeriod!)!
        calendarDayArr = calendarData.calendarDays as! [BICalendarDay]
        monthTitle()
        txtTripID.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: txtTripID.frame.height))
        txtTripID.leftViewMode = .always
        txtPosition.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: txtPosition.frame.height))
        txtPosition.leftViewMode = .always
        
        if self.bidPeriod!.isFABid() {
            if (bidPeriod?.isSecondRoundBid())! {
                self.txtPosition.isHidden = true
            }else{
                self.txtPosition.isHidden = false
            }
        } else {
            self.txtPosition.isHidden = true
        }
    }
    
    
    func monthTitle() {
        let currDate = Date()
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.day, .month, .year], from: currDate)
        let month = components.month ?? 0
        lblMonthTitle.text = CBGlobalMethods.fullMonthNameOf(monthInt: (month + 1))
    }
    
    
    @IBAction func btnDismissAction(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func btnGoAction(_ sender: Any) {
        if (txtTripID.text?.count) == 0 {
            shakeTextField(textField: txtTripID)
        } else if tripStartDate == nil {
            DispatchQueue.main.async {
                CBGlobalMethods.shared.ShowAlert(TitleString: "Warning!", MessageString: "Select a Trip start date.")
            }
        } else {
            askForTripID()
        }
    }
    
    func askForTripID() {
        let position = self.txtPosition.text
        if let text = txtTripID.text, text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty {
            print("isEmpty")
        } else {
            let emp = txtTripID.text!
            var trip:BITrip?
            if self.bidPeriod!.isFABid() {
                let awardedTrip =  emp
                if awardedTrip != "" {
                    trip = self.tripForTripId(tripID: awardedTrip, startDate: tripStartDate!, position: position)
                    if !((trip != nil)) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            CBGlobalMethods.shared.ShowAlert(TitleString: "Alert", MessageString: "Trip \(emp) starting on \(self.startDateToString!) not found")
                            return
                        }
                    }
                } else {
                    dismissFn()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        CBGlobalMethods.shared.ShowAlert(TitleString: "Alert", MessageString: "Trip \(emp) starting on \(self.startDateToString!) not found")
                        return
                    }
                }
            } else {
                let awardedTrip =  emp
                if awardedTrip != "" {
                    trip = self.tripForTripId(tripID: awardedTrip, startDate: tripStartDate!, position: nil)
                    if !((trip != nil)) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            CBGlobalMethods.shared.ShowAlert(TitleString: "Alert", MessageString: "Trip \(emp) starting on \(self.startDateToString!) not found")
                            return
                        }
                    }
                } else {
                    dismissFn()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        CBGlobalMethods.shared.ShowAlert(TitleString: "Alert", MessageString: "Trip \(emp) starting on \(self.startDateToString!) not found")
                        return
                    }
                }
            }
            
            if trip != nil {
                self.showTripTextView(trip: trip!)
            }
        }
    }
    
    func showTripTextView(trip : BITrip){
        let storyboard : UIStoryboard = UIStoryboard(name: "BidActions", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBTripAwardTextViewController") as! CBTripAwardTextViewController
        vc.trip = trip
        vc.bidPeriod = bidPeriod
        vc.fileName = txtTripID.text
        vc.tripTitleTxt = txtTripID.text ?? "Trip"
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    
    func  tripForTripId(tripID: String, startDate: Date, position: String?) -> BITrip? {
        let moc = bidPeriod.managedObjectContext!
        let fetchRequest = NSFetchRequest<BITrip>(entityName: "Trip")
        let normalizedStartDate = calendarData.dateForDate(date: startDate)
            
            if let position = position {
                let faPos: NSNumber
                
                switch position {
                case "A":
                    faPos = NSNumber(value: BIFaPosition.FaPositionA.rawValue)
                case "B":
                    faPos = NSNumber(value: BIFaPosition.FaPositionB.rawValue)
                case "C":
                    faPos = NSNumber(value: BIFaPosition.FaPositionC.rawValue)
                case "D":
                    faPos = NSNumber(value: BIFaPosition.FaPositionD.rawValue)
                default:
                    return nil
                }
                
                fetchRequest.predicate = NSPredicate(format: "info.number == %@ AND startDate == %@ AND position == %@", tripID, normalizedStartDate! as CVarArg, faPos)
            } else {
                fetchRequest.predicate = NSPredicate(format: "info.number == %@ AND startDate == %@", tripID, normalizedStartDate! as CVarArg)
            }
            
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "number", ascending: true)]
            
            let controller = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                        managedObjectContext: moc,
                                                        sectionNameKeyPath: nil,
                                                        cacheName: nil)
            controller.delegate = self as? NSFetchedResultsControllerDelegate
            
            do {
                try controller.performFetch()
                if let trips = controller.fetchedObjects, !trips.isEmpty {
                    return trips[0]
                }
            } catch {
                print("Fetch error: \(error)")
            }
            
            return nil
    }
    
    
}

extension CBTripAwardViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.text!.isEmpty {
            textField.layer.borderWidth = 4
            textField.layer.borderColor = UIColor.purple.cgColor
        } else {
            textField.layer.borderWidth = 4
            textField.layer.borderColor = UIColor.gray.cgColor
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == txtPosition {
            let uppercaseString = string.uppercased()
            let allowedCharacters = CharacterSet(charactersIn: "ABCDM")
            let stringCharacterSet = CharacterSet(charactersIn: uppercaseString)
            if allowedCharacters.isSuperset(of: stringCharacterSet) {
                textField.text = uppercaseString
            }
            return false
        }
        if textField == txtTripID {
            var uppercaseString = string.uppercased()
            let allowedCharacterSet = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
            uppercaseString = uppercaseString.components(separatedBy: allowedCharacterSet.inverted).joined()
            textField.text = (textField.text as NSString?)?.replacingCharacters(in: range, with: uppercaseString)
            return false
        }
        
        return false
    }
}

extension CBTripAwardViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return calendarDayArr.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let kDayCellIdentifer = "AwardCalendarCollectionViewCell"
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kDayCellIdentifer, for: indexPath as IndexPath) as! AwardCalendarCollectionViewCell
        cell.contentView.frame = cell.bounds
        cell.contentView.isUserInteractionEnabled = false
        cell.contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        if let indexPaths = collectionView.indexPathsForSelectedItems, let indexP = indexPaths.first {
            cell.contentView.backgroundColor = indexP == indexPath ? .white : .lightGray
        }
        let calendeday = calendarDayArr[indexPath.row]
        cell.dayLabel.text = calendeday.text
        let currentMonth = calendeday.isCurrentMonth
        if currentMonth {
            cell.dayLabel.textColor = UIColor .darkGray
            //cell.dayLabel.alpha = 1
        } else {
            cell.dayLabel.textColor = UIColor .lightGray
            //cell.dayLabel.alpha = 0.5
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (self.collectionView.frame.width)/7, height:45)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? AwardCalendarCollectionViewCell {
            //cell.contentView.backgroundColor = .green
            cell.toggleSelected()
            cell.isSelected = true
            tripStartDate = self.calendarData.dateForIndex(index: indexPath.row)
            print("tripStartDate>>>",tripStartDate as Any)
            
            //Converted date format for showing alert
            let dateFormatterGet = DateFormatter()
            dateFormatterGet.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let dateToString =  dateFormatterGet.string(from: tripStartDate!)
            let dateFormatterPrint = DateFormatter()
            dateFormatterPrint.dateFormat = "MMM dd,yyyy"
            if let date = dateFormatterGet.date(from: dateToString) {
                print(dateFormatterPrint.string(from: date))
                 startDateToString = dateFormatterPrint.string(from: date)
            } else {
                print("There was an error decoding the string")
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as? AwardCalendarCollectionViewCell
        cell?.isSelected = false
        cell?.toggleSelected()
    }
}
