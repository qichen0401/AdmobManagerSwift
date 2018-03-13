//
//  AdmobManager.swift
//  AdmobDemoSwift
//
//  Created by Qi Chen on 08/03/2018.
//  Copyright © 2018 Qi Chen. All rights reserved.
//

/*
 to do:
 in debug mode, use test id
 return banner view on create small scrope
 */

import UIKit

import Firebase

class AdmobManager: NSObject, GADBannerViewDelegate {
    
    static let shared = AdmobManager()
    
    private var applicationID = "ca-app-pub-3940256099942544~1458002511"
    private var bannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"
    
    private var bannerView: GADBannerView!
    private var bannerViewPosition: BannerViewPosition!
    
    enum BannerViewPosition {
        case top
        case bottom
    }
    
    private var rootViewController: UIViewController!
    private var childViewController: UIViewController!
    
    var rootViewBackgroundColor = UIColor.gray {
        didSet {
            // will crash on rootView == nil
            
            rootViewController.view.backgroundColor = rootViewBackgroundColor
        }
    }
    
    
    func setup(applicationID: String,
               bannerAdUnitID: String,
               bannerViewPosition: BannerViewPosition = .bottom) {
        self.applicationID = applicationID
        self.bannerAdUnitID = bannerAdUnitID
        self.bannerViewPosition = bannerViewPosition
    }
    
    func start() {
        configureViewHierarchy()
        
        GADMobileAds.configure(withApplicationID: applicationID)
        
        createBannerView()
        
        add(bannerView: bannerView, to: rootViewController.view)
        
        configureChildView()
        
        loadBannerView()
    }
    
    // MARK: - Helper
    
    private var window: UIWindow {
        get {
            return UIApplication.shared.delegate!.window!!
        }
    }
    
    private var isPortrait: Bool {
        get {
            return UIApplication.shared.statusBarOrientation.isPortrait
        }
    }
    
    // MARK: - View Hierarchy
    
    private func configureViewHierarchy() {
        childViewController = window.rootViewController!
        
        rootViewController = UIViewController()
        rootViewController.view.backgroundColor = rootViewBackgroundColor
        
        window.rootViewController = rootViewController
        
        rootViewController.addChildViewController(childViewController)
        rootViewController.view.addSubview(childViewController.view)
        childViewController.didMove(toParentViewController: rootViewController)
        
        window.makeKeyAndVisible()
    }
    
    private func restoreViewHierarchy() {
        childViewController.willMove(toParentViewController: nil)
        childViewController.view.removeFromSuperview()
        childViewController.removeFromParentViewController()
        
        window.rootViewController = childViewController
        window.makeKeyAndVisible()
        
        rootViewController = nil
        childViewController = nil
    }
    
    private func configureChildView() {
        let childView = childViewController.view!
        let rootView = rootViewController.view!
        
        childView.translatesAutoresizingMaskIntoConstraints = false
        
        if #available(iOS 11.0, *) {
            var constraints = [childView.leftAnchor.constraint(equalTo: rootView.leftAnchor),
                               childView.rightAnchor.constraint(equalTo: rootView.rightAnchor)]
            switch bannerViewPosition {
            case .top:
                constraints.append(contentsOf: [childView.topAnchor.constraint(equalTo: bannerView.bottomAnchor),
                                                childView.bottomAnchor.constraint(equalTo: rootView.bottomAnchor)])
            case .bottom:
                constraints.append(contentsOf: [childView.topAnchor.constraint(equalTo: rootView.topAnchor),
                                                childView.bottomAnchor.constraint(equalTo: bannerView.topAnchor)])
            default:
                break
            }
            NSLayoutConstraint.activate(constraints)
        } else {
            rootView.addConstraint(NSLayoutConstraint(item: childView,
                                                  attribute: .leading,
                                                  relatedBy: .equal,
                                                  toItem: rootView,
                                                  attribute: .leading,
                                                  multiplier: 1,
                                                  constant: 0))
            rootView.addConstraint(NSLayoutConstraint(item: childView,
                                                  attribute: .trailing,
                                                  relatedBy: .equal,
                                                  toItem: rootView,
                                                  attribute: .trailing,
                                                  multiplier: 1,
                                                  constant: 0))
            switch bannerViewPosition {
            case .top:
                rootView.addConstraint(NSLayoutConstraint(item: childView,
                                                      attribute: .top,
                                                      relatedBy: .equal,
                                                      toItem: bannerView,
                                                      attribute: .bottom,
                                                      multiplier: 1,
                                                      constant: 0))
                rootView.addConstraint(NSLayoutConstraint(item: childView,
                                                          attribute: .bottom,
                                                          relatedBy: .equal,
                                                          toItem: rootView,
                                                          attribute: .bottom,
                                                          multiplier: 1,
                                                          constant: 0))
            case .bottom:
                rootView.addConstraint(NSLayoutConstraint(item: childView,
                                                      attribute: .top,
                                                      relatedBy: .equal,
                                                      toItem: rootView,
                                                      attribute: .top,
                                                      multiplier: 1,
                                                      constant: 0))
                rootView.addConstraint(NSLayoutConstraint(item: childView,
                                                          attribute: .bottom,
                                                          relatedBy: .equal,
                                                          toItem: bannerView,
                                                          attribute: .top,
                                                          multiplier: 1,
                                                          constant: 0))
            default:
                break
            }
        }
    }
    
    // MARK: - Banner View
    
    func createBannerView() {
        bannerView = GADBannerView(adSize: isPortrait ? kGADAdSizeSmartBannerPortrait : kGADAdSizeSmartBannerLandscape)
        bannerView.adUnitID = bannerAdUnitID
        bannerView.rootViewController = rootViewController
        bannerView.delegate = self
    }
    
    func loadBannerView() {
        bannerView.load(GADRequest())
    }
    
    func add(bannerView: GADBannerView, to view: UIView) {
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bannerView)
        if #available(iOS 11.0, *) {
            // In iOS 11, we need to constrain the view to the safe area.
            position(bannerView, fullWidthAtBottomOf: rootViewController.view.safeAreaLayoutGuide)
        }
        else {
            // In lower iOS versions, safe area is not available so we use
            // bottom layout guide and view edges.
            position(bannerView, fullWidthAtBottomOf: rootViewController.view)
        }
    }
    
    // MARK: - view positioning
    @available (iOS 11, *)
    func position(_ bannerView: GADBannerView, fullWidthAtBottomOf safeAreaGuide: UILayoutGuide) {
        // Position the banner. Stick it to the bottom of the Safe Area.
        // Make it constrained to the edges of the safe area.
        var constraints = [safeAreaGuide.leftAnchor.constraint(equalTo: bannerView.leftAnchor),
                           safeAreaGuide.rightAnchor.constraint(equalTo: bannerView.rightAnchor)]
        switch bannerViewPosition {
        case .top:
            constraints.append(safeAreaGuide.topAnchor.constraint(equalTo: bannerView.topAnchor))
        case .bottom:
            constraints.append(safeAreaGuide.bottomAnchor.constraint(equalTo: bannerView.bottomAnchor))
        default:
            break
        }
        NSLayoutConstraint.activate(constraints)
    }
    
    func position(_ bannerView: GADBannerView, fullWidthAtBottomOf view: UIView) {
        view.addConstraint(NSLayoutConstraint(item: bannerView,
                                              attribute: .leading,
                                              relatedBy: .equal,
                                              toItem: view,
                                              attribute: .leading,
                                              multiplier: 1,
                                              constant: 0))
        view.addConstraint(NSLayoutConstraint(item: bannerView,
                                              attribute: .trailing,
                                              relatedBy: .equal,
                                              toItem: view,
                                              attribute: .trailing,
                                              multiplier: 1,
                                              constant: 0))
        switch bannerViewPosition {
        case .top:
            view.addConstraint(NSLayoutConstraint(item: bannerView,
                                                  attribute: .top,
                                                  relatedBy: .equal,
                                                  toItem: rootViewController.topLayoutGuide,
                                                  attribute: .bottom,
                                                  multiplier: 1,
                                                  constant: 0))
        case .bottom:
            view.addConstraint(NSLayoutConstraint(item: bannerView,
                                                  attribute: .bottom,
                                                  relatedBy: .equal,
                                                  toItem: rootViewController.bottomLayoutGuide,
                                                  attribute: .top,
                                                  multiplier: 1,
                                                  constant: 0))
        default:
            break
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    /*
    /// Tells the delegate an ad request loaded an ad.
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        print("adViewDidReceiveAd")
    }
    
    /// Tells the delegate an ad request failed.
    func adView(_ bannerView: GADBannerView,
                didFailToReceiveAdWithError error: GADRequestError) {
        print("adView:didFailToReceiveAdWithError: \(error.localizedDescription)")
    }
    
    /// Tells the delegate that a full-screen view will be presented in response
    /// to the user clicking on an ad.
    func adViewWillPresentScreen(_ bannerView: GADBannerView) {
        print("adViewWillPresentScreen")
    }
    
    /// Tells the delegate that the full-screen view will be dismissed.
    func adViewWillDismissScreen(_ bannerView: GADBannerView) {
        print("adViewWillDismissScreen")
    }
    
    /// Tells the delegate that the full-screen view has been dismissed.
    func adViewDidDismissScreen(_ bannerView: GADBannerView) {
        print("adViewDidDismissScreen")
    }
    
    /// Tells the delegate that a user click will open another app (such as
    /// the App Store), backgrounding the current app.
    func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
        print("adViewWillLeaveApplication")
    }
 */
}
