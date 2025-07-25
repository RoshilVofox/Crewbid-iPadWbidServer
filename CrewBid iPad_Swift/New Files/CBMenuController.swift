//
//  CBMenuController.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 21/07/25.
//

import Foundation
import UIKit
import QuartzCore

// MARK: - Menu Item Type Enum
enum CBMenuItemType {
    case plain
    case destructive
    case disclosure
    case inertDisclosure
    case superDestructive
}

// MARK: - Menu Item
class CBMenuItem {
    var type: CBMenuItemType
    var title: String
    var completion: (() -> Void)?
    var submenuItems: [CBMenuItem]?
    var isEnabled: Bool = true
    
    init(type: CBMenuItemType, title: String, completion: (() -> Void)? = nil) {
        self.type = type
        self.title = title
        self.completion = completion
    }
    
    init(title: String, submenuItems: [CBMenuItem]) {
        self.type = .plain
        self.title = title
        self.submenuItems = submenuItems
    }
}


// MARK: - Cell Gradient Background View
class CBCellGradientBackgroundView: UIView {
    override class var layerClass: AnyClass { CAGradientLayer.self }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setGradient(reversed: false)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setGradient(reversed: false)
    }
    
    func reverseGradient() {
        setGradient(reversed: true)
    }
    
    private func setGradient(reversed: Bool) {
        guard let gradientLayer = self.layer as? CAGradientLayer else { return }
        let lightGradientColor = UIColor(red: 0.980, green: 0.349, blue: 0.161, alpha: 1.000)
        let darkGradientColor = UIColor(red: 0.529, green: 0.125, blue: 0.008, alpha: 1.000)
        gradientLayer.colors = reversed
            ? [darkGradientColor.cgColor, lightGradientColor.cgColor]
            : [lightGradientColor.cgColor, darkGradientColor.cgColor]
        gradientLayer.opacity = 0.86
    }
}


// MARK: - Menu Table Cell
class CBMenuTableCell: UITableViewCell {
    var menuItemType: CBMenuItemType = .plain {
        didSet { updateAppearance() }
    }
    
    private func updateAppearance() {
        selectionStyle = .gray
        textLabel?.alpha = 1.0
        backgroundView = nil
        selectedBackgroundView = nil
        accessoryType = .none
        
        let isNight = UserDefaults.standard.bool(forKey: "kCBNightTimeModeEnabled")
        
        switch menuItemType {
        case .plain:
            textLabel?.textColor = isNight ? .white : .darkGray
            
        case .destructive:
            addBackgroundView(for: .destructive)
            
        case .disclosure:
            textLabel?.textColor = isNight ? .white : .darkGray
            accessoryType = .disclosureIndicator
            
        case .inertDisclosure:
            textLabel?.textColor = isNight ? .white : .lightGray
            textLabel?.alpha = 0.5
            selectionStyle = .none
            accessoryType = .none
            
        case .superDestructive:
            addBackgroundView(for: .superDestructive)
        }
    }
    
    private func addBackgroundView(for type: CBMenuItemType) {
        let backgroundView = UIView(frame: .zero)
        let selectedBackgroundView = UIView(frame: .zero)
        
        textLabel?.backgroundColor = .clear
        textLabel?.textColor = .white
        textLabel?.shadowColor = UIColor(white: 0.0, alpha: 0.54)
        textLabel?.shadowOffset = CGSize(width: 0, height: -1)

        if type == .destructive {
            // backgroundView.backgroundColor = UIColor(red:1, green:0.227, blue:0, alpha:1)
            backgroundView.backgroundColor = UIColor.red
            selectedBackgroundView.backgroundColor = UIColor.red
        } else if type == .superDestructive {
            // backgroundView.backgroundColor = UIColor(red:1, green:0, blue:0, alpha:1)
            backgroundView.backgroundColor = CBColor.tripButtonredColor
            selectedBackgroundView.backgroundColor = CBColor.tripButtonredColor
        }

        let gradientView = CBCellGradientBackgroundView(frame: .zero)
        gradientView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.addSubview(gradientView)
        NSLayoutConstraint.activate([
            gradientView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor),
            gradientView.topAnchor.constraint(equalTo: backgroundView.topAnchor),
            gradientView.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor)
        ])
        
        let selectedGradientView = CBCellGradientBackgroundView(frame: .zero)
        selectedGradientView.reverseGradient()
        selectedGradientView.translatesAutoresizingMaskIntoConstraints = false
        selectedBackgroundView.addSubview(selectedGradientView)
        NSLayoutConstraint.activate([
            selectedGradientView.leadingAnchor.constraint(equalTo: selectedBackgroundView.leadingAnchor),
            selectedGradientView.trailingAnchor.constraint(equalTo: selectedBackgroundView.trailingAnchor),
            selectedGradientView.topAnchor.constraint(equalTo: selectedBackgroundView.topAnchor),
            selectedGradientView.bottomAnchor.constraint(equalTo: selectedBackgroundView.bottomAnchor)
        ])
        self.backgroundView = backgroundView
        self.selectedBackgroundView = selectedBackgroundView
    }
}


// MARK: - Menu Controller
class CBMenuController: UITableViewController {
    var menuItems: [CBMenuItem]
    
    init(menuItems: [CBMenuItem]) {
        self.menuItems = menuItems
        super.init(style: .plain)
        self.tableView.separatorColor = .lightGray
        if #available(iOS 11.0, *) {
            // Additional layout settings
        }
        self.tableView.separatorInset = .zero
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(CBMenuTableCell.self, forCellReuseIdentifier: "MenuItemCell")
        
        let isNight = UserDefaults.standard.bool(forKey: "kCBNightTimeModeEnabled")
        tableView.backgroundColor = isNight ? .black : .white
        tableView.separatorColor = isNight ? .white : .lightGray
    }
    
    // MARK: - Preferred Content Size
    override var preferredContentSize: CGSize {
        get { CGSize(width: 330.0, height: 44.0 * CGFloat(menuItems.count)) }
        set { super.preferredContentSize = newValue }
    }
    
    // MARK: - TableView Data Source
    
    override func numberOfSections(in tableView: UITableView) -> Int { 1 }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        menuItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MenuItemCell", for: indexPath) as? CBMenuTableCell else {
            return UITableViewCell()
        }
        
        let menuItem = menuItems[indexPath.row]
        cell.selectionStyle = .gray
        let isNight = UserDefaults.standard.bool(forKey: "kCBNightTimeModeEnabled")
        cell.backgroundColor = isNight ? .black : .white
        cell.textLabel?.textColor = isNight ? .white : .black
        
        if !menuItem.isEnabled {
            cell.selectionStyle = .none
            cell.textLabel?.textColor = .lightGray
            cell.isUserInteractionEnabled = false
        } else {
            cell.isUserInteractionEnabled = true
        }
        
        cell.menuItemType = menuItem.type
        cell.textLabel?.text = menuItem.title
        cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 17.0)
        return cell
    }
    
    // MARK: - TableView Delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let menuItem = menuItems[indexPath.row]
        if let completion = menuItem.completion {
            completion()
        } else if let submenuItems = menuItem.submenuItems {
            let menuController = CBMenuController(menuItems: submenuItems)
            navigationController?.pushViewController(menuController, animated: true)
        }
    }
}

