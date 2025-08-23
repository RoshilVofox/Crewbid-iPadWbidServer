

import UIKit

class CBHelpItemsController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    var helpMenuItems: [HelpMenuItem] = []
    struct HelpMenuItem {
        let imageName:String?
        let itemLabel:String?
        let viewControllerName: String?
    }
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var btnSecretBidload1: UIButton!
    @IBOutlet weak var btnSecretBidload2: UIButton!
    @IBOutlet weak var closeBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        NotificationCenter.default.addObserver(self, selector: #selector(self.openSubScriptionPage), name: Notification.Name(openSubscriptionPageNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.openLatestNews), name: Notification.Name("goToLatestNews"), object: nil)
    }
    
    @objc func openLatestNews(){
        let storyboard : UIStoryboard = UIStoryboard(name: "HelpMenu", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBNewsController") as! CBNewsController
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func openSubScriptionPage(){
        let storyboard : UIStoryboard = UIStoryboard(name: "HelpMenu", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "CBSubscriptionInfoController") as! CBSubscriptionInfoController
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func setupUI() {
        collectionView.dataSource = self
        collectionView.delegate = self
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        collectionView.setCollectionViewLayout(layout, animated: true)
        btnSecretBidload1.setTitle("", for: .normal)
        btnSecretBidload2.setTitle("", for: .normal)
        closeBtn.setTitle("", for: .normal)
        readhelpMenuItems()
    }
    
    @IBAction func btnSecretBidDownload(_ sender: Any) {
        if (self.btnSecretBidload1.isTouchInside &&  self.btnSecretBidload2.isTouchInside){
            print("hello")
            let storyBoard = UIStoryboard(name: "Secret", bundle: nil)
            if let helpMenuVC = storyBoard.instantiateViewController(withIdentifier: "SecretMethodsViewController") as? SecretMethodsViewController{
                //            helpMenuVC.modalPresentationStyle = .formSheet
                helpMenuVC.preferredContentSize = CGSize(width: 700, height: 600)
                present(helpMenuVC, animated: true)
            }
        }
    }
    
    func readhelpMenuItems() {
        helpMenuItems.removeAll()
        helpMenuItems.append(HelpMenuItem(imageName: "Quick Tutorial1", itemLabel: "Quick Tutorial", viewControllerName: "quickTutorial"))
        helpMenuItems.append(HelpMenuItem(imageName: "Movie", itemLabel: "How-To Videos ", viewControllerName: "quickTutorial"))
        helpMenuItems.append(HelpMenuItem(imageName: "Notebook", itemLabel: "defenitions", viewControllerName: "quickTutorial"))
        helpMenuItems.append(HelpMenuItem(imageName: "document", itemLabel: "Line Values", viewControllerName: "quickTutorial"))
        helpMenuItems.append(HelpMenuItem(imageName: "Update", itemLabel: "Update", viewControllerName: "quickTutorial"))
        helpMenuItems.append(HelpMenuItem(imageName: "Help_preserver", itemLabel: "FAQ", viewControllerName: "quickTutorial"))
        helpMenuItems.append(HelpMenuItem(imageName: "Shopping", itemLabel: "My Subscription", viewControllerName: "quickTutorial"))
        helpMenuItems.append(HelpMenuItem(imageName: "Mail", itemLabel: "Contact Us", viewControllerName: "quickTutorial"))
        helpMenuItems.append(HelpMenuItem(imageName: "Link", itemLabel: "Latest News", viewControllerName: "quickTutorial"))
        helpMenuItems.append(HelpMenuItem(imageName: "Vacation1", itemLabel: "Vacation", viewControllerName: "quickTutorial"))
        helpMenuItems.append(HelpMenuItem(imageName: "user", itemLabel: "User Account", viewControllerName: "quickTutorial"))
        helpMenuItems.append(HelpMenuItem(imageName: "agreement@2x", itemLabel: "Service Agreement", viewControllerName: "quickTutorial"))
    }
    
    @IBAction func btnDismissAction(_ sender: Any) {
        self.dismiss(animated: true)
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
            
        case 6:
            let vc = UIStoryboard(name: "HelpMenu", bundle: nil).instantiateViewController(withIdentifier: "mySubscriptionViewController") as! CBSubscriptionInfoController
            self.navigationController?.pushViewController(vc, animated: true)
            break
            
        case 7:
            let vc = UIStoryboard(name: "HelpMenu", bundle: nil).instantiateViewController(withIdentifier: "contactUsViewController") as! contactUsViewController
            self.navigationController?.pushViewController(vc, animated: true)
            break
            
        case 8:
            let vc = UIStoryboard(name: "HelpMenu", bundle: nil).instantiateViewController(withIdentifier: "CBNewsController") as! CBNewsController
            self.navigationController?.pushViewController(vc, animated: true)
            break
            
        case 9:
            let userAccount = UIStoryboard(name: "HelpMenu", bundle: nil).instantiateViewController(withIdentifier: "swaptimizerHelpMenuViewController") as! swaptimizerHelpMenuViewController
            self.navigationController?.pushViewController(userAccount, animated: true)
            break
            
        case 10:
            let vc = UIStoryboard(name: "HelpMenu", bundle: nil).instantiateViewController(withIdentifier: "userAccountViewController") as! userAccountViewController
            self.navigationController?.pushViewController(vc, animated: true)
            break
            
            
        case 11:
            let vc = UIStoryboard(name: "HelpMenu", bundle: nil).instantiateViewController(withIdentifier: "serviceAgreementViewController") as! serviceAgreementViewController
            self.navigationController?.pushViewController(vc, animated: true)
            break
            
            
        default:
            print("default")
        }
        
        //        userAccount.modalPresentationStyle = .overCurrentContext
        //        present(userAccount, animated: false)
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.layer.borderColor = UIColor.clear.cgColor
        cell?.isSelected = false
    }
}

