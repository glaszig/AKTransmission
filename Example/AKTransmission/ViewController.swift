//
//  ViewController.swift
//  AKTransmission
//
//  Created by Florian Morello on 11/03/2015.
//  Copyright (c) 2015 Florian Morello. All rights reserved.
//

import UIKit
import AKTransmission

class ViewController: UIViewController, UITableViewDataSource {

	@IBOutlet weak var tableView:UITableView!

	let client :Transmission = Transmission(host: "localhost", username: "test", password: "test")

	var torrents:[TransmissionTorrent] = []

    override func viewDidLoad() {
        super.viewDidLoad()

		client.torrentGet { (result, err) -> Void in
			if let torrents = result as? [TransmissionTorrent] {
				self.torrents = torrents
				self.tableView.reloadData()
			}
		}
    }

	@IBAction func downloadAction(sender: AnyObject) {
		let debianMagnetLink = "magnet:?xt=urn:btih:CD8158937344B2A066446BED7E7A0C45214F1245&dn=debian+8+2+0+amd64+dvd+1+iso&tr=udp%3A%2F%2Ftracker.openbittorrent.com%3A80%2Fannounce&tr=udp%3A%2F%2Fopen.demonii.com%3A1337"
		client.loadMagnetLink(debianMagnetLink) { (success, error) -> Void in
			print(success)
		}
	}

	// MARK: UITableViewDataSource

	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return torrents.count
	}

	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("aCell", forIndexPath: indexPath)

		let torrent = torrents[indexPath.row]
		(cell.viewWithTag(1) as? UILabel)?.text = torrent.name as? String
		(cell.viewWithTag(4) as? UIProgressView)?.progress = torrent.percentDone
		(cell.viewWithTag(2) as? UILabel)?.text = String(format: "%@ of %@ (%.2f%%) - %@ remaining", bytesToHuman(Int(Float(torrent.totalSize) * torrent.percentDone)), bytesToHuman(torrent.totalSize), torrent.percentDone*100, timeToHuman(torrent.eta))
		(cell.viewWithTag(3) as? UILabel)?.text = torrent.status!.contains(TransmissionTorrentStatus.TR_STATUS_STOPPING) ? "Paused" : String(format: "Downloading from %d of %d peers", torrent.peersSendingToUs, torrent.peersConnected)
		
		return cell
	}

	private func timeToHuman(time: NSTimeInterval) -> String {
		let interval: Int = Int(time)
		let day = (interval / (3600 * 24)) % (3600*24)
		let hrs = ((interval - (day * 3600 * 24)) / 3600) % 3600
		let min = (interval - (hrs * 3600) / 60) % 60
		return String(format: "%2ldd %0.2ld:%0.2ld", day, hrs, min)
	}

	private func bytesToHuman(bytes: Int) -> String {
		let b: Float = Float(bytes)
		let base: Float = 1000
		if b > pow(base, 3) {
			return String(format: "%.2f GB", b/pow(base, 3))
		}
		else if b > pow(base, 2) {
			return String(format: "%.2f MB", b/pow(base, 2))
		}
		else if bytes > 1024 {
			return String(format: "%.2f KB", b/base)
		}
		else  {
			return "\(bytes) B"
		}

	}
}

