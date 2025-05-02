
import UIKit

class howToVideosViewController: UIViewController,UICollectionViewDelegateFlowLayout {
    var abc = ["dsjkfdks","sdfhnjkds","sdfhjkg", "sdhfjkg"]

    @IBOutlet weak var collectionView: UICollectionView!
    override func viewDidLoad() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 20
        layout.minimumLineSpacing = 10
        collectionView.setCollectionViewLayout(layout, animated: true)
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    
    @IBAction func btnBackAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
}

extension howToVideosViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        abc.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! howToVideoCollectionViewCell
        cell.webViewLabel.text = abc[indexPath.row]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 300, height: 275)
    }
    
    
}
