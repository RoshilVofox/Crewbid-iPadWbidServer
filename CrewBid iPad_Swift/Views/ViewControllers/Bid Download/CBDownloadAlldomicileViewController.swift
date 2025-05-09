

import UIKit

class CBDownloadAlldomicileViewController: UIViewController {
    
    @IBOutlet weak var btnAllPilot: UIButton!
    @IBOutlet weak var btnAllFltAttendat: UIButton!
    @IBOutlet weak var txtMonth: DropDown!
    @IBOutlet weak var txtYear: UITextField!
    @IBOutlet weak var txtUserID: UITextField!
    @IBOutlet weak var btnFirstRound: UIButton!
    @IBOutlet weak var btnSecondRound: UIButton!
    @IBOutlet weak var btnBoth: UIButton!
    @IBOutlet weak var btnCp: UIButton!
    @IBOutlet weak var btnFo: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var btnOk: UIButton!
    
    @IBOutlet weak var btnAtl: UIButton!
    @IBOutlet weak var btnAus: UIButton!
    @IBOutlet weak var btnBna: UIButton!
    @IBOutlet weak var btnBwi: UIButton!
    @IBOutlet weak var btnDal: UIButton!
    @IBOutlet weak var btnDen: UIButton!
    @IBOutlet weak var btnFll: UIButton!
    @IBOutlet weak var btHou: UIButton!
    @IBOutlet weak var btnLas: UIButton!
    @IBOutlet weak var btnLax: UIButton!
    @IBOutlet weak var btnMco: UIButton!
    @IBOutlet weak var btnMdw: UIButton!
    @IBOutlet weak var btnOak: UIButton!
    @IBOutlet weak var btnPhx: UIButton!
    
    let selectionColor = UIColor(red: 52/255, green: 61/255, blue: 66/255, alpha:1.0)
    let deSelectionColor = UIColor(red: 212/255, green: 135/255, blue: 14/255, alpha:1.0)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setUpUI()
    }
    
    func setUpUI(){
        txtMonth.optionArray = ["1", "2", "3", "4", "5", "6", "7", "8","9","10","11","12"]
        txtMonth.didSelect{(selectedText , index ,id) in
            self.txtMonth.text = "\(selectedText)"
        }
        // Select initial buttons and hide the indicator

//        self.selectButton(button: btnAllPilot)
        self.selectButton(button: btnFirstRound)
//        self.selectButton(button: btnBoth)
        activityIndicator.isHidden = true
    }
    
    func selectButton(button : UIButton){
        button.isSelected = true
        if button.isSelected {
            button.backgroundColor = selectionColor
        }else{
            button.backgroundColor = deSelectionColor
        }
        button.setTitleColor(.white, for: .selected)
        button.setTitleColor(.white, for: .normal)
    }
    // Function to unselect a button

    func unselectButton(button : UIButton){
        button.isSelected = false
        if button.isSelected {
            button.backgroundColor = selectionColor
        }else{
            button.backgroundColor = deSelectionColor
        }
        button.setTitleColor(.white, for: .selected)
        button.setTitleColor(.white, for: .normal)
    }
    
    // MARK: - All flt btn
    @IBAction func btnAllFltAttndAction(_ sender: Any) {
        let btnArray: [UIButton] = [btnAtl, btnAus, btnBna, btnBwi, btnDal, btnDen, btnFll, btHou, btnLas, btnLax, btnMco, btnMdw, btnOak, btnPhx, btnAllFltAttendat]
        
        for btn in btnArray {
            self.selectButton(button: btn)
        }
        
        self.unselectButton(button: btnAllPilot)
    }
    
    // MARK: - All pilot btn
    @IBAction func btnAllPilotAction(_ sender: Any) {
        let btnArray: [UIButton] = [btnAtl, btnAus, btnBna, btnBwi, btnDal, btnDen, btnFll, btHou, btnLas, btnLax, btnMco, btnMdw, btnOak, btnPhx, btnAllPilot]
        
        for btn in btnArray {
            self.selectButton(button: btn)
        }
        let btnArray2 : [UIButton] = [btnAllFltAttendat, btnFll, btnAus]
        for btn in btnArray2 {
            self.unselectButton(button: btn)
        }
    }
    
    // MARK: -  firstRound btn
    @IBAction func btnFirstRoundAction(_ sender: Any) {
        self.selectButton(button: sender as! UIButton)
        self.unselectButton(button: btnSecondRound)
    }
    
    // MARK: -  Second Round btn
    @IBAction func btnSecondRoundAction(_ sender: Any) {
        self.selectButton(button: sender as! UIButton)
        self.unselectButton(button: btnFirstRound)
    }
    
    @IBAction func btnCancelAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: -  both btn
    @IBAction func btnBothAction(_ sender: Any) {
        self.selectButton(button: sender as! UIButton)
        self.unselectButton(button: btnCp)
        self.unselectButton(button: btnFo)
    }
    
    // MARK: -  CP btn
    @IBAction func btnCpAction(_ sender: Any) {
        self.selectButton(button: sender as! UIButton)
        self.unselectButton(button: btnBoth)
        self.unselectButton(button: btnFo)
    }
    
    // MARK: -  FO btn
    @IBAction func btnFoAction(_ sender: Any) {
        self.selectButton(button: sender as! UIButton)
        self.unselectButton(button: btnCp)
        self.unselectButton(button: btnBoth)
    }
    
    
    // MARK: -  OK btn
    @IBAction func btnOkAction(_ sender: Any) {
    }
    
    
}
