//
//  ViewController.swift
//  AKTransmission
//
//  Created by Florian Morello on 11/03/2015.
//  Copyright (c) 2015 Florian Morello. All rights reserved.
//

import UIKit
import AKTransmission

class ViewController: UIViewController {


	let client = Transmission(host: "localhost", username: "test", password: "test")

    override func viewDidLoad() {
        super.viewDidLoad()

		let debianMagnetLink = "magnet:?xt=urn:btih:CD8158937344B2A066446BED7E7A0C45214F1245&dn=debian+8+2+0+amd64+dvd+1+iso&tr=udp%3A%2F%2Ftracker.openbittorrent.com%3A80%2Fannounce&tr=udp%3A%2F%2Fopen.demonii.com%3A1337"
		client.loadMagnetLink(debianMagnetLink) { (success, error) -> Void in
			print(success)
		}
    }
}

