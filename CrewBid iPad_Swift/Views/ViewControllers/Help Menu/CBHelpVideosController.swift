
import UIKit
import AVFoundation

class CBHelpVideosController: BaseViewController,UICollectionViewDelegateFlowLayout {
    
    var abc = ["dsjkfdks","sdfhnjkds","sdfhjkg", "sdhfjkg"]
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var btnBack: UIButton!
    @IBOutlet weak var btnDone: UIButton!
    var videoIDs = [String]()
    var videoTitles = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    func setupUI(){
        btnBack.setTitle("", for: .normal)
        btnDone.setTitle("", for: .normal)
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 30, left: 40, bottom: 20, right: 40)
        layout.minimumInteritemSpacing = 15
        layout.minimumLineSpacing = 15
        layout.scrollDirection = .vertical
        collectionView!.collectionViewLayout = layout
        // Check if video URLs and titles are stored in UserDefaults
        
        if UserDefaults.standard.object(forKey: kCBHelpVideoURL) != nil && UserDefaults.standard.object(forKey: kCBHelpVideotitles) != nil {
            // Retrieve video URLs and titles from UserDefaults
            
            videoIDs = UserDefaults.standard.object(forKey: kCBHelpVideoURL) as! [String]
            videoTitles = UserDefaults.standard.object(forKey: kCBHelpVideotitles) as! [String]
        }
        // Check if the number of video IDs matches the number of titles
        
        if videoIDs.count != videoTitles.count {
            DispatchQueue.main.async {
                CBGlobalMethods.shared.ShowAlert(TitleString: "Video Load Error", MessageString: "The number of videos did not match the number of video titles. Please send a bug report to the support team.")
            }
        }
        // Configure the audio session for playback
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback)
        } catch {
            print(error)
            DispatchQueue.main.async {
                CBGlobalMethods.shared.ShowAlert(TitleString: "Video Load Error", MessageString: error.localizedDescription)
            }
        }
        collectionView.reloadData()
    }
    
    @IBAction func btnBackAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func doneBtnAction(_ sender: Any) {
        self.dismiss(animated: true)
    }
}

extension CBHelpVideosController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videoIDs.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let videoCell = collectionView.dequeueReusableCell(withReuseIdentifier: "videoCell", for: indexPath) as! VideoCollectionViewCell
        let index = indexPath.item
        videoCell.videoTitleLbl.text = videoTitles[index]
        let html = """
            <!DOCTYPE html>
            <html>
            <head>
            <meta name="viewport" content="initial-scale=1.0, maximum-scale=1.0">
            <style>
                body, html { margin: 0; padding: 0; height: 100%; background-color: black; }
                iframe { width: 100%; height: 100%; border: none; }
            </style>
            </head>
            <body>
            <iframe src="https://www.youtube.com/embed/\(videoIDs[index])?playsinline=1&rel=0&showinfo=0"
                    allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture"
                    allowfullscreen>
            </iframe>
            </body>
            </html>
            """
        videoCell.webView.loadHTMLString(html, baseURL: nil)
        return videoCell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 300.0, height: 260)
    }
    
    
}

