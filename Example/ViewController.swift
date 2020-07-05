//
//  ViewController.swift
//  Example
//
//  Created by Johan Sellström on 2020-06-07.
//  Copyright © 2020 Svipe AB. All rights reserved.
//

import UIKit
import SvipeKit

class ViewController: UIViewController {

    let auth = SvipeKit.Authenticator()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func scanDocument(_ sender: Any) {

        auth.scanDocument(callbackURL: "https://demo.svipe.io/callback") { (passport, error) in
            print(passport)
        }
    }

}

