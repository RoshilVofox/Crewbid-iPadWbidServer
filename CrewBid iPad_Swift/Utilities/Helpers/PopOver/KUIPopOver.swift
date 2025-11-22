//
//  KUIPopOver.swift
//  CrewBid iPad_Swift
//
//  Created by Fayaz on 25/03/25.
//

import Foundation
import UIKit

fileprivate class KUIPopOverUsableDismissHandlerWrapper {
    typealias DismissHandler = ((Bool) -> Void)
    var closure: DismissHandler?
    
    init(_ closure: DismissHandler?) {
        self.closure = closure
    }
}

fileprivate extension UIView {
    
    struct AssociatedKeys {
        static let onDismissHandler = "onDismissHandler"
    }
    
    var onDismissHandler: KUIPopOverUsableDismissHandlerWrapper.DismissHandler? {
        get { return (objc_getAssociatedObject(self, AssociatedKeys.onDismissHandler) as? KUIPopOverUsableDismissHandlerWrapper)?.closure }
        set { objc_setAssociatedObject(self, AssociatedKeys.onDismissHandler, KUIPopOverUsableDismissHandlerWrapper(newValue), .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
}


extension KUIPopOverUsable where Self: UIView {

    public var contentView: UIView {
        return self
    }
    
    public var contentSize: CGSize {
        return frame.size
    }
    
    public func showPopover(sourceView: UIView, sourceRect: CGRect? = nil) {
        let usableViewController = KUIPopOverUsableViewController(popOverUsable: self)
        usableViewController.showPopover(sourceView: sourceView, sourceRect: sourceRect)
        onDismissHandler = { [weak self] animated in
            usableViewController.dismiss(animated: animated, completion: nil)
            self?.onDismissHandler = nil
        }
    }
    
    public func showPopover(barButtonItem: UIBarButtonItem) {
        let usableViewController = KUIPopOverUsableViewController(popOverUsable: self)
        usableViewController.showPopover(barButtonItem: barButtonItem)
        onDismissHandler = { [weak self] animated in
            usableViewController.dismiss(animated: animated, completion: nil)
            self?.onDismissHandler = nil
        }
    }
    
    public func dismissPopover(animated: Bool) {
        onDismissHandler?(animated)
    }
}

extension KUIPopOverUsable where Self: UIViewController {
    
    public var contentView: UIView {
        return view
    }
    
    private var rootViewController: UIViewController? {
        // Get the active window scene
        guard let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
              let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }),
              var topController = keyWindow.rootViewController else {
            return nil
        }

        // Optional: apply your shadow styling here
        keyWindow.layer.shadowColor = UIColor.black.cgColor
        keyWindow.layer.shadowOpacity = 1
        keyWindow.layer.shadowOffset = .zero
        keyWindow.layer.shadowRadius = 10

        // Traverse through any presented view controllers
        while let presented = topController.presentedViewController {
            topController = presented
        }

        return topController
        
//        let yourView = UIApplication.shared.keyWindow!
//        yourView.layer.shadowColor = UIColor.black.cgColor
//        yourView.layer.shadowOpacity = 1
//        yourView.layer.shadowOffset = .zero
//        yourView.layer.shadowRadius = 10
//        return UIApplication.shared.keyWindow?.rootViewController?.topPresentedViewController
    }
    
    private var popOverUsableNavigationController: KUIPopOverUsableNavigationController {
        let naviController = KUIPopOverUsableNavigationController(rootViewController: self)
        naviController.modalPresentationStyle = .popover
        naviController.popoverPresentationController?.delegate = KUIPopOverDelegation.shared
        naviController.popoverPresentationController?.backgroundColor = popOverBackgroundColor
        naviController.popoverPresentationController?.permittedArrowDirections = arrowDirection
        return naviController
    }
    
    private func setup(isMidOn:Bool = false) {
        modalPresentationStyle = .popover
        preferredContentSize = contentSize
        if isMidOn{
            preferredContentSize = CGSize(width: 320, height: 80)
        }
        popoverPresentationController?.delegate = KUIPopOverDelegation.shared
        popoverPresentationController?.backgroundColor = popOverBackgroundColor
        popoverPresentationController?.permittedArrowDirections = arrowDirection

    }
    
    public func setupPopover(sourceView: UIView, sourceRect: CGRect? = nil, isMidOn: Bool = false) {
        setup(isMidOn: isMidOn)
        
        if let sourceRect = sourceRect {
            let convertedRect = sourceView.convert(sourceRect, to: rootViewController?.view)
            popoverPresentationController?.sourceView = rootViewController?.view
            popoverPresentationController?.sourceRect = convertedRect
        } else {
            let convertedBounds = sourceView.convert(sourceView.bounds, to: rootViewController?.view)
            popoverPresentationController?.sourceView = rootViewController?.view
            popoverPresentationController?.sourceRect = convertedBounds
        }
    }
    
    public func setupPopover(barButtonItem: UIBarButtonItem) {
        setup()
        popoverPresentationController?.barButtonItem = barButtonItem
    }
    
    public func showPopover(sourceView: UIView, sourceRect: CGRect? = nil,isMidOn:Bool = false) {
        setupPopover(sourceView: sourceView, sourceRect: sourceRect,isMidOn:isMidOn)
        DispatchQueue.main.async { [self] in
            rootViewController?.present(self, animated: true, completion: nil)
        }
    }
    
    public func showPopover(withNavigationController sourceView: UIView, sourceRect: CGRect? = nil) {
        let naviController = popOverUsableNavigationController
            if let sourceRect = sourceRect {
                let convertedRect = sourceView.convert(sourceRect, to: rootViewController?.view)
                naviController.popoverPresentationController?.sourceView = rootViewController?.view
                naviController.popoverPresentationController?.sourceRect = convertedRect
            } else {
                let convertedBounds = sourceView.convert(sourceView.bounds, to: rootViewController?.view)
                naviController.popoverPresentationController?.sourceView = rootViewController?.view
                naviController.popoverPresentationController?.sourceRect = convertedBounds
            }

        rootViewController?.present(naviController, animated: true, completion: nil)
    }
    
    public func showPopover(barButtonItem: UIBarButtonItem) {
        setupPopover(barButtonItem: barButtonItem)
        rootViewController?.present(self, animated: true, completion: nil)
    }
    
    public func showPopover(withNavigationController barButtonItem: UIBarButtonItem) {
        let naviController = popOverUsableNavigationController
        naviController.popoverPresentationController?.barButtonItem = barButtonItem
        rootViewController?.present(naviController, animated: true, completion: nil)
    }
    
    public func dismissPopover(animated: Bool) {
        dismiss(animated: true, completion: nil)
    }
}

private final class KUIPopOverUsableNavigationController: UINavigationController {
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if let popOverUsable = visibleViewController as? KUIPopOverUsable {
            preferredContentSize = popOverUsable.contentSize
        } else {
            preferredContentSize = visibleViewController?.preferredContentSize ?? preferredContentSize
        }
    }
    
}

private final class KUIPopOverUsableViewController: UIViewController, KUIPopOverUsable {
    
    var contentSize: CGSize {
        return popOverUsable.contentSize
    }
    
    var contentView: UIView {
        return view
    }
    
    
    var popOverBackgroundColor: UIColor? {
        return popOverUsable.popOverBackgroundColor
    }
    
    var arrowDirection: UIPopoverArrowDirection {
        return popOverUsable.arrowDirection
    }
    
    private var popOverUsable: KUIPopOverUsable!
    
    convenience init(popOverUsable: KUIPopOverUsable) {
        self.init()
        self.popOverUsable = popOverUsable
        preferredContentSize = popOverUsable.contentSize
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(popOverUsable.contentView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        popOverUsable.contentView.frame = view.bounds
    }
    
}

private final class KUIPopOverDelegation: NSObject, UIPopoverPresentationControllerDelegate {
    
    static let shared = KUIPopOverDelegation()
    
    // MARK: - UIPopoverPresentationControllerDelegate
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}

private extension UIViewController {
    
    var topPresentedViewController: UIViewController {
        return presentedViewController?.topPresentedViewController ?? self
    }
    
}
