//
//  CBBrightnessViewController.swift
//  CrewBid iPad_Swift
//
//  Created by Developer on 05/05/25.
//

import UIKit

class CBBrightnessViewController: UIViewController {
    @IBOutlet weak var brightnessSlider: UISlider!
    @IBOutlet weak var darkModeSwitch: UISwitch!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        brightnessSlider.value = Float(UIScreen.main.brightness)
        brightnessSlider.minimumValue = 0.0
        brightnessSlider.maximumValue = 1.0

        // Get current user interface style from the window
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                darkModeSwitch.isOn = (window.overrideUserInterfaceStyle == .dark)
            }
        // Do any additional setup after loading the view.
    }
    

     @IBAction func btnBackAction(_ sender: Any) {
         self.navigationController?.popViewController(animated: true)
     }

    @IBAction func brightnessSliderValueChanged(_ sender: Any) {
        UIScreen.main.brightness = CGFloat(brightnessSlider.value)
    }
    @IBAction func darkModeSwitchAction(_ sender: Any) {
        let style: UIUserInterfaceStyle = (sender as AnyObject).isOn ? .dark : .light

            // Set it for the entire window
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.overrideUserInterfaceStyle = style
            }

            // Optional: Also update the current view controller to reflect change immediately
            self.overrideUserInterfaceStyle = style
    }
}
