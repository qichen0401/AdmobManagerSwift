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
 when orientation change, interstitial orientation not always right
 */

import UIKit

import GoogleMobileAds

class AdmobManager: NSObject {
    
    static let shared = AdmobManager()
    
    func setup(bannerAdUnitID: String, interstitialAdUnitID: String) {
        self.bannerAdUnitID = bannerAdUnitID
        self.interstitialAdUnitID = interstitialAdUnitID
    }
    
    func start() {
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        
        bannerView = createBannerView()
        configureViewHierarchy()
        add(bannerView, to: rootViewController)
        configureConstraints()
        load(bannerView)
        
        interstitial = createAndLoadInterstitial()
        
        NotificationCenter.default.addObserver(self, selector: #selector(AdmobManager.applicationWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(AdmobManager.applicationWillChangeStatusBarOrientation(notification:)), name: UIApplication.willChangeStatusBarOrientationNotification, object: nil)
        
        reachabilityStart()
    }
    
    @objc private func applicationWillEnterForeground() {
        load(bannerView)
        interstitial = createAndLoadInterstitial()
    }
    
    @objc private func applicationWillChangeStatusBarOrientation(notification: NSNotification) {
        let newIsPortrait = UIInterfaceOrientation(rawValue: (notification.userInfo![UIApplication.statusBarOrientationUserInfoKey] as! NSNumber).intValue)!.isPortrait
        if isPortrait != newIsPortrait {
            bannerView.adSize = newIsPortrait ? kGADAdSizeSmartBannerPortrait : kGADAdSizeSmartBannerLandscape
        }
    }
    
    private let reachability = Reachability()!
    private var isReachable = true
    
    private func reachabilityStart() {
        reachability.whenReachable = { [unowned self] _ in
            if self.isReachable == false {
                self.isReachable = true
                self.load(self.bannerView)
                self.interstitial = self.createAndLoadInterstitial()
            }
        }
        reachability.whenUnreachable = { [unowned self] _ in
            self.isReachable = false
        }
        
        do {
            try reachability.startNotifier()
        } catch {
            print("Unable to start notifier")
        }
    }
    
    func stop() {
        NotificationCenter.default.removeObserver(self)
        
        reachability.stopNotifier()
        
        UIView.animate(withDuration: 0.5, animations: { [unowned self] in
            self.bannerView.alpha = 0
        }, completion: { [unowned self] _ in
            self.bannerView.removeFromSuperview()
            
            UIView.animate(withDuration: 0.5, animations: { [unowned self] in
                let childView = self.childViewController.view!
                let rootView = self.rootViewController.view!
                
                childView.removeConstraints(childView.constraints)
                
                rootView.addConstraints([
                    NSLayoutConstraint(item: childView,
                                       attribute: .leading,
                                       relatedBy: .equal,
                                       toItem: rootView,
                                       attribute: .leading,
                                       multiplier: 1,
                                       constant: 0),
                    NSLayoutConstraint(item: childView,
                                       attribute: .trailing,
                                       relatedBy: .equal,
                                       toItem: rootView,
                                       attribute: .trailing,
                                       multiplier: 1,
                                       constant: 0),
                    NSLayoutConstraint(item: childView,
                                       attribute: .top,
                                       relatedBy: .equal,
                                       toItem: rootView,
                                       attribute: .top,
                                       multiplier: 1,
                                       constant: 0),
                    NSLayoutConstraint(item: childView,
                                       attribute: .bottom,
                                       relatedBy: .equal,
                                       toItem: rootView,
                                       attribute: .bottom,
                                       multiplier: 1,
                                       constant: 0)
                    ])
                    
                rootView.layoutIfNeeded()
            }, completion: { [unowned self] _ in
                self.restoreViewHierarchy()
                
                self.bannerView = nil
                self.interstitial = nil
            })
        })
    }
    
    // MARK: - Banner View
    
    private var bannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"
    
    private var bannerView: GADBannerView!
    private var bannerViewPosition = BannerViewPosition.bottom
    
    enum BannerViewPosition {
        case top
        case bottom
    }
    
    private var rootViewController: UIViewController!
    private var childViewController: UIViewController!
    
    var rootViewBackgroundColor = UIColor.gray {
        didSet {
            rootViewController.view.backgroundColor = rootViewBackgroundColor
        }
    }
    
    private func createBannerView() -> GADBannerView {
        let bannerView = GADBannerView(adSize: isPortrait ? kGADAdSizeSmartBannerPortrait : kGADAdSizeSmartBannerLandscape)
        bannerView.adUnitID = bannerAdUnitID
        bannerView.delegate = self
        return bannerView
    }
    
    private func load(_ bannerView: GADBannerView) {
        let request = GADRequest()
        request.testDevices = ["32d006772c3f4d1f1f0fe6a9da84ec86"]
        bannerView.load(request)
//        bannerView.load(GADRequest())
    }
    
    private func add(_ bannerView: GADBannerView, to rootViewController: UIViewController) {
        rootViewController.view.addSubview(bannerView)
        bannerView.rootViewController = rootViewController
    }
    
    private func configureViewHierarchy() {
        childViewController = window.rootViewController!
        
        rootViewController = UIViewController()
        rootViewController.view.backgroundColor = rootViewBackgroundColor
        
        window.rootViewController = rootViewController
        
        rootViewController.addChild(childViewController)
        rootViewController.view.addSubview(childViewController.view)
        childViewController.didMove(toParent: rootViewController)
        
        window.makeKeyAndVisible()
    }
    
    private func restoreViewHierarchy() {
        childViewController.willMove(toParent: nil)
        childViewController.view.removeFromSuperview()
        childViewController.removeFromParent()
        
        window.rootViewController = childViewController
        window.makeKeyAndVisible()
        
        rootViewController = nil
        childViewController = nil
    }
    
    private func configureConstraints() {
        let rootView = rootViewController.view!
        let childView = childViewController.view!
        
        childView.translatesAutoresizingMaskIntoConstraints = false
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        
        if #available(iOS 11.0, *) {
            let safeAreaLayoutGuide = rootViewController.view.safeAreaLayoutGuide
            var constraints = [childView.leftAnchor.constraint(equalTo: rootView.leftAnchor),
                               childView.rightAnchor.constraint(equalTo: rootView.rightAnchor),
                               safeAreaLayoutGuide.leftAnchor.constraint(equalTo: bannerView.leftAnchor),
                               safeAreaLayoutGuide.rightAnchor.constraint(equalTo: bannerView.rightAnchor)]
            switch bannerViewPosition {
            case .top:
                constraints.append(contentsOf: [safeAreaLayoutGuide.topAnchor.constraint(equalTo: bannerView.topAnchor),
                                                childView.topAnchor.constraint(equalTo: bannerView.bottomAnchor),
                                                childView.bottomAnchor.constraint(equalTo: rootView.bottomAnchor)
                    ])
            case .bottom:
                constraints.append(contentsOf: [childView.topAnchor.constraint(equalTo: rootView.topAnchor),
                                                childView.bottomAnchor.constraint(equalTo: bannerView.topAnchor),
                                                safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: bannerView.bottomAnchor)])
            }
            NSLayoutConstraint.activate(constraints)
        } else {
            let rootView = rootViewController.view!
            
            rootView.addConstraints([
                NSLayoutConstraint(item: childView,
                                   attribute: .leading,
                                   relatedBy: .equal,
                                   toItem: rootView,
                                   attribute: .leading,
                                   multiplier: 1,
                                   constant: 0),
                NSLayoutConstraint(item: childView,
                                   attribute: .trailing,
                                   relatedBy: .equal,
                                   toItem: rootView,
                                   attribute: .trailing,
                                   multiplier: 1,
                                   constant: 0),
                NSLayoutConstraint(item: bannerView!,
                                   attribute: .leading,
                                   relatedBy: .equal,
                                   toItem: rootView,
                                   attribute: .leading,
                                   multiplier: 1,
                                   constant: 0),
                NSLayoutConstraint(item: bannerView!,
                                   attribute: .trailing,
                                   relatedBy: .equal,
                                   toItem: rootView,
                                   attribute: .trailing,
                                   multiplier: 1,
                                   constant: 0)
                ])
            
            switch bannerViewPosition {
            case .top:
                rootView.addConstraints([
                    NSLayoutConstraint(item: bannerView!,
                                       attribute: .top,
                                       relatedBy: .equal,
                                       toItem: rootViewController.topLayoutGuide,
                                       attribute: .bottom,
                                       multiplier: 1,
                                       constant: 0),
                    NSLayoutConstraint(item: childView,
                                       attribute: .top,
                                       relatedBy: .equal,
                                       toItem: bannerView,
                                       attribute: .bottom,
                                       multiplier: 1,
                                       constant: 0),
                    NSLayoutConstraint(item: childView,
                                       attribute: .bottom,
                                       relatedBy: .equal,
                                       toItem: rootView,
                                       attribute: .bottom,
                                       multiplier: 1,
                                       constant: 0)
                    ])
            case .bottom:
                rootView.addConstraints([
                    NSLayoutConstraint(item: bannerView!,
                                       attribute: .bottom,
                                       relatedBy: .equal,
                                       toItem: rootViewController.bottomLayoutGuide,
                                       attribute: .top,
                                       multiplier: 1,
                                       constant: 0),
                    NSLayoutConstraint(item: childView,
                                       attribute: .top,
                                       relatedBy: .equal,
                                       toItem: rootView,
                                       attribute: .top,
                                       multiplier: 1,
                                       constant: 0),
                    NSLayoutConstraint(item: childView,
                                       attribute: .bottom,
                                       relatedBy: .equal,
                                       toItem: bannerView,
                                       attribute: .top,
                                       multiplier: 1,
                                       constant: 0)
                    ])
            }
        }
    }
    
    // MARK: - Interstitial
    
    private var interstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910"
    private var interstitial: GADInterstitial!
    
    private func createAndLoadInterstitial() -> GADInterstitial {
        let interstitial = GADInterstitial(adUnitID: interstitialAdUnitID)
        interstitial.delegate = self
        let request = GADRequest()
        request.testDevices = ["32d006772c3f4d1f1f0fe6a9da84ec86"]
        interstitial.load(request)
        return interstitial
    }
    
    func presentInterstitial() {
        guard let interstitial = interstitial else { return }
        if interstitial.isReady {
            interstitial.present(fromRootViewController: window.rootViewController!)
        }
    }
}

// MARK: - GADBannerViewDelegate

extension AdmobManager: GADBannerViewDelegate {
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        bannerView.alpha = 0
        UIView.animate(withDuration: 1.0) {
            bannerView.alpha = 1
        }
    }
    
    func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError) {
        print("adView:didFailToReceiveAdWithError: \(error.localizedDescription)")
    }
}

// MARK: - GADInterstitialDelegate

extension AdmobManager: GADInterstitialDelegate {
    func interstitialDidDismissScreen(_ ad: GADInterstitial) {
        interstitial = createAndLoadInterstitial()
    }
    
    func interstitial(_ ad: GADInterstitial, didFailToReceiveAdWithError error: GADRequestError) {
        print("interstitial:didFailToReceiveAdWithError: \(error.localizedDescription)")
    }
}

// MARK: - Utilities

fileprivate var window: UIWindow {
    get {
        return UIApplication.shared.delegate!.window!!
    }
}

fileprivate var isPortrait: Bool {
    get {
        return UIApplication.shared.statusBarOrientation.isPortrait
    }
}
