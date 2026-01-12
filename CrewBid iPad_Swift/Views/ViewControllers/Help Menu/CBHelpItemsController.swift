import UIKit

class CBHelpItemsController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var menuTitle: UILabel!
    var helpMenuItems: [HelpMenuItem] = []
    
    
    struct HelpMenuItem {
        let imageName:String?
        let itemLabel:String?
        let viewControllerName: String?
    }
    
    @IBOutlet weak var collectionView: UICollectionView!

    @IBOutlet weak var secretView: UIView!
    @IBOutlet weak var closeBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.menuTitle.text = String(format: "Help Menu (CrewBid Version %@)", CBUtils.AppVersion())
        setupUI()
//        NotificationCenter.default.addObserver(self, selector: #selector(self.openSubScriptionPage), name: Notification.Name(openSubscriptionPageNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.openLatestNews), name: Notification.Name("goToLatestNews"), object: nil)
    }
    
    @objc func openLatestNews(){
        let storyboard : UIStoryboard = UIStoryboard(name: "HelpMenu", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBNewsController") as! CBNewsController
        vc.isFromBidVC = true
        self.navigationController?.pushViewController(vc, animated: true)
    }
    /*
    @objc func openSubScriptionPage(){
        let storyboard : UIStoryboard = UIStoryboard(name: "HelpMenu", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBSubscriptionInfoController") as! CBSubscriptionInfoController
        self.navigationController?.pushViewController(vc, animated: true)
    }*/
    
    func setupUI() {
        collectionView.dataSource = self
        collectionView.delegate = self
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        collectionView.setCollectionViewLayout(layout, animated: true)
        closeBtn.setTitle("", for: .normal)
        readhelpMenuItems()
        configureSecretGesture()
    }
    
    private func configureSecretGesture(){
        secretView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(showSecretMenu(_:)))
        tap.numberOfTapsRequired = 2
        secretView.addGestureRecognizer(tap)
    }
    
    @objc func showSecretMenu(_ recognizer: UITapGestureRecognizer){
        guard recognizer.state == .recognized else { return }

        // Avoid showing multiple alerts / VCs if already presented
        if self.presentedViewController != nil { return }

        // Present password alert
        let alert = UIAlertController(title: "Secret Menu",
                                      message: "Please enter the password:",
                                      preferredStyle: .alert)

        alert.addTextField { textField in
            textField.placeholder = "Enter Password here"
            textField.isSecureTextEntry = true
            textField.keyboardType = .default
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            // nothing to do
        })

        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let entered = alert.textFields?.first?.text ?? ""
            if entered == "Vofox2013-1" {
                self.presentSecretMethods()
            } else {
                // you can show a small invalid message or shake animation
                let invalid = UIAlertController(title: "Invalid Password",
                                                message: "The password you entered is incorrect.",
                                                preferredStyle: .alert)
                invalid.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(invalid, animated: true)
            }
        })

        present(alert, animated: true)
    }
    
    private func presentSecretMethods() {
        let storyBoard = UIStoryboard(name: "Secret", bundle: nil)
        guard let helpMenuVC = storyBoard.instantiateViewController(withIdentifier: "SecretMethodsViewController") as? SecretMethodsViewController else {
            return
        }
        // Prevent swipe-to-dismiss if you want it modal and required
        helpMenuVC.isModalInPresentation = true
        helpMenuVC.preferredContentSize = CGSize(width: 700, height: 600)
        // choose presentation style you prefer
        helpMenuVC.modalPresentationStyle = .formSheet
        present(helpMenuVC, animated: true)
    }
    
//    @IBAction func btnSecretBidDownload(_ sender: Any) {
//        if (self.btnSecretBidload1.isTouchInside &&  self.btnSecretBidload2.isTouchInside){
//            AlertService.showAlertForTopVC(
//                title: "Secret Menu",
//                message: "please enter the Password:",
//                actions: [
//                    (
//                        title: "Cancel",
//                        style: .cancel,
//                        handler: { _, _ in
//                            print("User tapped Cancel")
//                        }
//                    ),
//                    (
//                        title: "OK",
//                        style: .default,
//                        handler: { _, textFields in
//                            if let value = textFields?.first?.text {
//                                if value == "Vofox2013-1" {
//                                    let storyBoard = UIStoryboard(name: "Secret", bundle: nil)
//                                    if let helpMenuVC = storyBoard.instantiateViewController(withIdentifier: "SecretMethodsViewController") as? SecretMethodsViewController{
//                                        helpMenuVC.isModalInPresentation = true
//                                        //            helpMenuVC.modalPresentationStyle = .formSheet
//                                        helpMenuVC.preferredContentSize = CGSize(width: 700, height: 600)
//                                        self.present(helpMenuVC, animated: true)
//                                    }
//                                } else {
//                                    print("invalid input")
//                                }
//                            }
//                        }
//                    )
//                ],
//                textFields: [
//                    (
//                        placeholder: "Enter Password here",
//                        keyboardType: .default,
//                        tag: 0,
//                        delegate: nil
//                    )
//                ]
//            )
//        }
//    }
    
    func readhelpMenuItems() {
        helpMenuItems.removeAll()
        helpMenuItems.append(HelpMenuItem(imageName: "Quick Tutorial1", itemLabel: "Quick Tutorial", viewControllerName: "quickTutorial"))
        helpMenuItems.append(HelpMenuItem(imageName: "Movie", itemLabel: "How-To Videos ", viewControllerName: "quickTutorial"))
        helpMenuItems.append(HelpMenuItem(imageName: "Notebook", itemLabel: "Definitions", viewControllerName: "quickTutorial"))
        helpMenuItems.append(HelpMenuItem(imageName: "document", itemLabel: "Line Values", viewControllerName: "quickTutorial"))
        helpMenuItems.append(HelpMenuItem(imageName: "Update", itemLabel: "Update", viewControllerName: "quickTutorial"))
        helpMenuItems.append(HelpMenuItem(imageName: "Help_preserver", itemLabel: "FAQ", viewControllerName: "quickTutorial"))
//        helpMenuItems.append(HelpMenuItem(imageName: "Shopping", itemLabel: "My Subscription", viewControllerName: "quickTutorial"))
        helpMenuItems.append(HelpMenuItem(imageName: "Mail", itemLabel: "Contact Us", viewControllerName: "quickTutorial"))
        helpMenuItems.append(HelpMenuItem(imageName: "Link", itemLabel: "Latest News", viewControllerName: "quickTutorial"))
        helpMenuItems.append(HelpMenuItem(imageName: "Vacation1", itemLabel: "Vacation", viewControllerName: "quickTutorial"))
        helpMenuItems.append(HelpMenuItem(imageName: "user", itemLabel: "User Account", viewControllerName: "quickTutorial"))
        helpMenuItems.append(HelpMenuItem(imageName: "agreement@2x", itemLabel: "Service Agreement", viewControllerName: "quickTutorial"))
    }
    
    @IBAction func btnDismissAction(_ sender: Any) {
        self.modalTransitionStyle = .crossDissolve
        self.dismiss(animated: true)
    }
    
    func isUserInfoAvailable() -> Bool{
        var isAvailable = false
        let app = UIApplication.shared.delegate as! AppDelegate
        if app.isUserInformationAvailable(){
            isAvailable = true
        }
        return isAvailable
    }
    
    
    // MARK: - Collection View
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return helpMenuItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? helpMenuItemCollectionViewCell
        cell?.itemLabel.text = helpMenuItems[indexPath.row].itemLabel
        cell?.itemImage.image = UIImage(named: helpMenuItems[indexPath.row].imageName!)
        
        return cell!
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        //        let padding: CGFloat = 10
        //        let columnsInRow = 7
        //        let availableSpace = collectionView.frame.width - CGFloat(columnsInRow - 1) * padding
        //        let widthPerItem = availableSpace / CGFloat(columnsInRow)
        return CGSize(width: collectionView.frame.width / 4, height: 160)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.layer.borderColor = UIColor.purple.cgColor
        cell?.layer.borderWidth = 4
        cell?.layer.cornerRadius = 5
        cell?.isSelected = true
        switch indexPath.item {
        case 0:
            let vc = UIStoryboard(name: "HelpMenu", bundle: nil).instantiateViewController(withIdentifier: "quickTutorialViewController") as! quickTutorialViewController
            vc.isFirstTime = false
            self.navigationController?.pushViewController(vc, animated: true)
            break
            
        case 1:
            let vc = UIStoryboard(name: "HelpMenu", bundle: nil).instantiateViewController(withIdentifier: "howToVideosViewController") as! CBHelpVideosController
            self.navigationController?.pushViewController(vc, animated: true)
            break
            
        case 2:
            let vc = UIStoryboard(name: "HelpMenu", bundle: nil).instantiateViewController(withIdentifier: "defenitionsViewController") as! defenitionsViewController
            self.navigationController?.pushViewController(vc, animated: true)
            break
            
        case 3:
            let vc = UIStoryboard(name: "HelpMenu", bundle: nil).instantiateViewController(withIdentifier: "lineValuesViewController") as! lineValuesViewController
            self.navigationController?.pushViewController(vc, animated: true)
            break
            
        case 4:
            let alert = UIAlertController(title: "Notice", message: "This action is not available right now.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            break
            
            
        case 5:
            let vc = UIStoryboard(name: "HelpMenu", bundle: nil).instantiateViewController(withIdentifier: "faqViewController") as! faqViewController
            self.navigationController?.pushViewController(vc, animated: true)
            break
            
//        case 6:
//            if self.isUserInfoAvailable(){
//                let vc = UIStoryboard(name: "HelpMenu", bundle: nil).instantiateViewController(withIdentifier: "CBSubscriptionInfoController") as! CBSubscriptionInfoController
//                self.navigationController?.pushViewController(vc, animated: true)
//            }else{
//                AlertService.showAlertForTopVC(title: "CrewBid", message: "You cannot check your subscription because you have not yet validated.  To validate, all you have to do is download bid data.  Then you can verify your subscription details.", actions: nil)
//            }
//            break
            
        case 6:
            let vc = UIStoryboard(name: "HelpMenu", bundle: nil).instantiateViewController(withIdentifier: "contactUsViewController") as! contactUsViewController
            self.navigationController?.pushViewController(vc, animated: true)
            break
            
        case 7:
            let vc = UIStoryboard(name: "HelpMenu", bundle: nil).instantiateViewController(withIdentifier: "CBNewsController") as! CBNewsController
            self.navigationController?.pushViewController(vc, animated: true)
            break
            
        case 8:
            let userAccount = UIStoryboard(name: "HelpMenu", bundle: nil).instantiateViewController(withIdentifier: "swaptimizerHelpMenuViewController") as! swaptimizerHelpMenuViewController
            self.navigationController?.pushViewController(userAccount, animated: true)
            break
            
        case 9:
            if self.isUserInfoAvailable(){
                let vc = UIStoryboard(name: "HelpMenu", bundle: nil).instantiateViewController(withIdentifier: "userAccountViewController") as! userAccountViewController
                vc.isfrom = self
                self.navigationController?.pushViewController(vc, animated: true)
            }else{
                AlertService.showAlertForTopVC(title: "CrewBid", message: "User account not available.\nPlease login in CrewBid with your employee number.", actions: [(title: "OK", style: .default, handler: { _ in
                    self.dismiss(animated: true)
                })])
            }
            break
            
            
        case 10:
            let vc = UIStoryboard(name: "HelpMenu", bundle: nil).instantiateViewController(withIdentifier: "serviceAgreementViewController") as! serviceAgreementViewController
            self.navigationController?.pushViewController(vc, animated: true)
            break
            
            
        default:break
        }

    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.layer.borderColor = UIColor.clear.cgColor
        cell?.isSelected = false
    }
}

