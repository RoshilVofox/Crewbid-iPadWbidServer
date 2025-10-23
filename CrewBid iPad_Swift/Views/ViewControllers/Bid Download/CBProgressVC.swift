//
//  CBProgressVC.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 20/03/25.
//

import UIKit

extension Notification.Name {
    static let bidInfoReadError = Notification.Name("bidInfoReadError")
}

class CBProgressVC: UIViewController {

    @IBOutlet weak var text1: UILabel!
    @IBOutlet weak var text2: UILabel!
    @IBOutlet weak var text3: UILabel!
    @IBOutlet weak var text4: UILabel!
    @IBOutlet weak var text5: UILabel!
    
    @IBOutlet weak var button1: GRRoundButton!
    @IBOutlet weak var button2: GRRoundButton!
    @IBOutlet weak var button3: GRRoundButton!
    @IBOutlet weak var button4: GRRoundButton!
    @IBOutlet weak var button5: GRRoundButton!
    
    @IBOutlet weak var indicator1: UIActivityIndicatorView!
    @IBOutlet weak var indicator2: UIActivityIndicatorView!
    @IBOutlet weak var indicator3: UIActivityIndicatorView!
    @IBOutlet weak var indicator4: UIActivityIndicatorView!
    @IBOutlet weak var indicator5: UIActivityIndicatorView!
    
    @IBOutlet weak var rectProgress: RectangularProgressView!
    
    let reachability = try! Reachability()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        button1.layer.cornerRadius = 22.5
        button2.layer.cornerRadius = 22.5
        button3.layer.cornerRadius = 22.5
        button4.layer.cornerRadius = 22.5
        button5.layer.cornerRadius = 22.5
        
        if reachability.isReachable{
            self.button1.backgroundColor = .white
            self.button1.setImage(UIImage.init(named:"CheckBoxChecked"), for: .normal)
            self.indicator1.isHidden = true
            self.indicator2.isHidden = false
            self.indicator3.isHidden = true
            self.indicator4.isHidden = true
            self.indicator5.isHidden = true
            self.indicator2.color = .white
            self.indicator2.startAnimating()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(notificationAction(notification: )), name: Notification.Name("BidDownloaded"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(notificationAction(notification: )), name: Notification.Name("ReadingTrips"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(notificationAction(notification: )), name: Notification.Name("UpdateProgress"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(notificationAction(notification: )), name: Notification.Name("ReadingLines"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(notificationAction(notification: )), name: Notification.Name("BidParsingCompleted"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(notificationAction(notification: )), name: Notification.Name("CloseProgressView"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showReadErrorAlert(_:)), name: .bidInfoReadError, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func showReadErrorAlert(_ notification: Notification) {
        guard let error = notification.object as? Error else { return }
        DispatchQueue.main.async {
            self.dismiss(animated: true){
                if let topVC = AlertService.currentTopViewController() {
                    AlertService.showDBAlert(title: "Error", message: error.localizedDescription, from: topVC)
                }
            }
        }
    }
    
    func dismissProgressView(){
        DispatchQueue.main.async {
            self.dismiss(animated: true)
        }
    }

    @objc func notificationAction(notification:Notification){
        let name = notification.name.rawValue
        if name == "BidDownloaded"{
            DispatchQueue.main.async {
                self.button2.backgroundColor = .white
                self.button2.setImage(UIImage.init(named: "CheckBoxChecked"), for: .normal)
                self.indicator1.isHidden = true
                self.indicator2.isHidden = true
                self.indicator3.isHidden = false
                self.indicator4.isHidden = true
                self.indicator5.isHidden = true
                self.indicator3.color = .white
                self.indicator2.stopAnimating()
                self.indicator3.startAnimating()
                self.rectProgress.updateProgress(to: 0.34, animated: true)
            }
        }else if name == "ReadingTrips"{
            DispatchQueue.main.async {
                self.button3.setImage(UIImage.init(named: "CheckBoxChecked"), for: .normal)
                self.button3.backgroundColor = .white
                self.indicator1.isHidden = true
                self.indicator2.isHidden = true
                self.indicator3.isHidden = true
                self.indicator4.isHidden = false
                self.indicator5.isHidden = true
                self.indicator4.color = .white
                self.indicator3.stopAnimating()
                self.indicator4.startAnimating()
            }
        }else if name == "UpdateProgress" {
            if let progress = notification.userInfo?["progress"] as? Float {
                DispatchQueue.main.async {
                    self.rectProgress.updateProgress(to: progress, animated: true)
                }
            }
        }else if name == "ReadingLines"{
            DispatchQueue.main.async {
                self.button4.setImage(UIImage.init(named: "CheckBoxChecked"), for: .normal)
                self.button4.backgroundColor = .white
                self.indicator1.isHidden = true
                self.indicator2.isHidden = true
                self.indicator3.isHidden = true
                self.indicator4.isHidden = true
                self.indicator5.isHidden = false
                self.indicator4.stopAnimating()
                self.indicator5.startAnimating()
            }
        }else if name == "BidParsingCompleted"{
            DispatchQueue.main.async {
                self.button5.setImage(UIImage.init(named: "CheckBoxChecked"), for: .normal)
                self.button5.backgroundColor = .white
                self.indicator1.isHidden = true
                self.indicator2.isHidden = true
                self.indicator3.isHidden = true
                self.indicator4.isHidden = true
                self.indicator5.isHidden = true
                self.indicator5.stopAnimating()
                self.rectProgress.updateProgress(to: 1.0, animated: true)
            }
        }
        else if name == "CloseProgressView"{
            DispatchQueue.main.async {
                self.dismiss(animated: true)
            }
        }
    }
}


//MARK: Progress View

class RectangularProgressView: UIView {

    private let progressBackground: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.lightGray.withAlphaComponent(0.3)
        view.layer.cornerRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let progressForeground: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 255, green: 97, blue: 0)
        view.layer.cornerRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let percentageLabel: UILabel = {
        let label = UILabel()
        label.text = "0%"
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textAlignment = .center
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Constraint to animate progress width
    private var progressWidthConstraint: NSLayoutConstraint!
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Setup UI
    private func setupView() {
        addSubview(progressBackground)
        progressBackground.addSubview(progressForeground)
        addSubview(percentageLabel)
        
        // Background Constraints
        NSLayoutConstraint.activate([
            progressBackground.leadingAnchor.constraint(equalTo: leadingAnchor),
            progressBackground.trailingAnchor.constraint(equalTo: trailingAnchor),
            progressBackground.topAnchor.constraint(equalTo: topAnchor),
            progressBackground.heightAnchor.constraint(equalToConstant: 20),
            
            percentageLabel.topAnchor.constraint(equalTo: progressBackground.bottomAnchor, constant: 8),
            percentageLabel.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
        
        // Foreground Constraints
        progressWidthConstraint = progressForeground.widthAnchor.constraint(equalToConstant: 0)
        NSLayoutConstraint.activate([
            progressForeground.leadingAnchor.constraint(equalTo: progressBackground.leadingAnchor),
            progressForeground.topAnchor.constraint(equalTo: progressBackground.topAnchor),
            progressForeground.bottomAnchor.constraint(equalTo: progressBackground.bottomAnchor),
            progressWidthConstraint
        ])
    }
    
    // MARK: - Update Progress
    func updateProgress(to progress: Float, animated: Bool = true) {
        let totalWidth = progressBackground.frame.width
        let newWidth = CGFloat(progress) * totalWidth
        
        if animated {
            UIView.animate(withDuration: 0.2) {
                self.progressWidthConstraint.constant = newWidth
                self.layoutIfNeeded()
            }
        } else {
            progressWidthConstraint.constant = newWidth
        }
        
        let percent = Int(progress * 100)
        percentageLabel.text = "\(percent)%"
    }
    
    // Call this in layoutSubviews to update width on rotation or initial layout
    override func layoutSubviews() {
        super.layoutSubviews()
        updateProgress(to: Float(progressWidthConstraint.constant / progressBackground.frame.width), animated: false)
    }
}

