import UIKit

class quickTutorialViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    var pageControl: UIPageControl!
    
    var images: [String] = ["WelcomeSlide", "Slide01", "Slide02", "Slide03", "Slide04", "Slide05", "Slide06", "Slide07", "Slide08", "Slide09", "Slide10", "Slide11" , "Slide12", "Slide13", "Slide14", "Slide15", "Slide16", "Slide17", "Slide18", "Slide19", "Slide20", "Slide21", "Slide22", "Slide23", "Slide24", "Slide25", "Slide26", "Slide27", "Slide28", "Slide29"]
    var totalPages: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .horizontal
        collectionView.collectionViewLayout = layout
        
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isPagingEnabled = true
        

        totalPages = images.count
        pageControl = UIPageControl()
        pageControl.numberOfPages = totalPages
        pageControl.currentPage = 0
        pageControl.pageIndicatorTintColor = UIColor.lightGray
        pageControl.currentPageIndicatorTintColor = UIColor.red
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(pageControl)
        
        NSLayoutConstraint.activate([
            pageControl.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    
    @IBAction func btnDoneAction(_ sender: Any) {
        self.dismiss(animated: false, completion: nil)
    }
    
    
    
    @IBAction func btnBackAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    
}

extension quickTutorialViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! quickTutorialCollectionViewCell
        cell.imageView.image = UIImage(named: images[indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageIndex = round(scrollView.contentOffset.x / scrollView.frame.width)
        let adjustedPageIndex = Int(pageIndex)
        pageControl.currentPage = adjustedPageIndex
    }
}
