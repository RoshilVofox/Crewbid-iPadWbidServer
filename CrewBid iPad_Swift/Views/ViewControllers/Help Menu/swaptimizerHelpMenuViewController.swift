

import UIKit

class swaptimizerHelpMenuViewController: UIViewController, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var btnBack: UIButton!
    @IBOutlet weak var btnDone: UIButton!
    struct CItem {
        var imageName: String
        var itemLabel: String
    }
    var items: [CItem] = []
    override func viewDidLoad() {
        super.viewDidLoad()
       
        setupUI()
        // Do any additional setup after loading the view.
    }
    
    func setupUI() {
        btnBack.setTitle("", for: .normal)
        btnDone.setTitle("", for: .normal)
        
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        collectionView.setCollectionViewLayout(layout, animated: true)
        readitmes()
    }

    func readitmes() {
        items.append(CItem(imageName: "Folder", itemLabel: "Tutorial"))
        items.append(CItem(imageName: "Help_preserver", itemLabel: "FAQ"))
        items.append(CItem(imageName: "Notebook", itemLabel: "Definitions"))
    }
    
    @IBAction func btnDoneAction(_ sender: Any) {
        self.dismiss(animated: false, completion: nil)
    }
    
    @IBAction func btnBackAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}

extension swaptimizerHelpMenuViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! swaptimizerHelpMenuCollectionViewCell
        cell.itemLabel.text = items[indexPath.row].itemLabel
        cell.imageView.image = UIImage(named: items[indexPath.row].imageName)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width / 3, height: 150)
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
            let vc = UIStoryboard(name: "HelpMenu", bundle: nil).instantiateViewController(withIdentifier: "faqViewController") as! faqViewController
            self.navigationController?.pushViewController(vc, animated: true)
            break
            
        case 2:
            let vc = UIStoryboard(name: "HelpMenu", bundle: nil).instantiateViewController(withIdentifier: "defenitionsViewController") as! defenitionsViewController
            self.navigationController?.pushViewController(vc, animated: true)
            break
        default:
            print("default")
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.layer.borderColor = UIColor.clear.cgColor
        cell?.isSelected = false
    }
    
    
}
