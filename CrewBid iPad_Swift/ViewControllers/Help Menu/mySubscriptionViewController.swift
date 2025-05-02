

import UIKit

class mySubscriptionViewController: UIViewController, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var collectionView: UICollectionView!
    override func viewDidLoad() {
        super.viewDidLoad()
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .vertical // Ensure vertical scrolling
        
        let itemWidth: CGFloat = 184
        let collectionViewWidth = collectionView.frame.width
        let horizontalInset = (collectionViewWidth - itemWidth) / 2
        
        layout.sectionInset = UIEdgeInsets(top: 0, left: horizontalInset, bottom: 0, right: horizontalInset) // ✅ Center horizontally
        collectionView.setCollectionViewLayout(layout, animated: true)
        // Do any additional setup after loading the view.
    }
    
    
    
    @IBAction func btnBackAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func btnDoneAction(_ sender: Any) {
        self.dismiss(animated: false, completion: nil)
    }
    

}

extension mySubscriptionViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! mySubscriptionCollectionViewCell
        cell.label.text = "Subscribe for \n₹699.00"
        cell.imageView.image = UIImage(named: "oneMonth")
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 184, height: 220)
    }
    
    
}
