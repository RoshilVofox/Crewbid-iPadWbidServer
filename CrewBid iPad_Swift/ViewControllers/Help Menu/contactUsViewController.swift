
import UIKit

class contactUsViewController: UIViewController, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var collectionView: UICollectionView!
    
    struct CItem {
        var imageName: String
        var itemLabel: String
    }
    
    var items: [CItem] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        readItems()
        
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 20
        layout.minimumLineSpacing = 0
        collectionView.setCollectionViewLayout(layout, animated: true)
        // Do any additional setup after loading the view.
        
    }
    
    func readItems() {
        items.append(CItem(imageName: "Chat", itemLabel: "Send a\nComment/Question"))
        items.append(CItem(imageName: "Box", itemLabel: "Report a Bug"))
    }
    
    
    @IBAction func btnBackAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func btnDoneAction(_ sender: Any) {
        self.dismiss(animated: false, completion: nil)
    }
    
    

}

extension contactUsViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! contactUsCollectionViewCell
        cell.itemLabel.text = items[indexPath.row].itemLabel
        cell.imageView.image = UIImage(named: items[indexPath.row].imageName)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 200, height: 200)
    }
    
    
}
