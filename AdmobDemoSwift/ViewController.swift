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
        
        view.backgroundColor = .yellow
        
//        AdmobManager.shared.rootViewController = self
//        AdmobManager.shared.setup()
        
    }
    @IBAction func test2(_ sender: Any) {
        AdmobManager.shared.presentInterstitial()
    }
    @IBAction func show(_ sender: Any) {
//        AdmobManager.shared.showInterstitial()
        
        
        AdmobManager.shared.stop()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

