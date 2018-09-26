//
//  AdmobTabBarController.swift
//  loveTracker
//
//  Created by Qi Chen on 2018/9/26.
//  Copyright © 2018 Jie Liu. All rights reserved.
//

import UIKit

class AdmobTabBarController: UITabBarController {

    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        AdmobManager.shared.presentInterstitial()
    }

}
