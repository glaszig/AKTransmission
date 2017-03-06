//
//  ViewController.swift
//  Example macOS
//
//  Created by martin on 06.03.17.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import Cocoa
import AKTransmission

class ViewController: NSViewController {
    @IBOutlet weak var magnetLinkField: NSTextField!
    let client: Transmission = Transmission(host: "localhost",
                                            username: "admin",
                                            password: "admin",
                                            port: 9091)

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func downloadDebian(_ sender: AnyObject) {
        let debianMagnetLink = magnetLinkField.stringValue
        let _ = client.loadMagnetLink(debianMagnetLink) { success, error in
            print(success)
        }
    }

}

