//
//  ViewController.swift
//  AdmobDemoSwift
//
//  Created by Qi Chen on 08/03/2018.
//  Copyright © 2018 Qi Chen. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
    }
    @IBAction func presentInterstitial(_ sender: Any) {
        AdmobManager.shared.presentInterstitial()
    }
    @IBAction func stopAds(_ sender: Any) {
        AdmobManager.shared.stop()
    }

}

