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

	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var slowModeButton: UIBarButtonItem?

	let client: Transmission = Transmission(host: "localhost", username: "admin", password: "admin")
	var session: TransmissionSession?
	var timers: [NSTimer] = []
	var torrents: [TransmissionTorrent] = []

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)

		tableView.tableFooterView = UIView()

		// schedule polling
		timers.append(NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: #selector(ViewController.pollSession), userInfo: nil, repeats: true))
		timers.append(NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: #selector(ViewController.pollTorrent), userInfo: nil, repeats: true))

		// fire them
		timers.forEach {
			$0.fire()
		}
	}

	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)

		// stop polling
		timers.forEach {
			$0.invalidate()
		}
		timers = []
	}

	func pollSession() {
		client.sessionGet { [weak self] result, error in
			if let session = result {
				self?.session = session
                self?.slowModeButton?.tintColor = session.altSpeedEnabled ? UIColor.redColor() : UIColor.blueColor()
			}
		}
	}

	func pollTorrent() {
		client.torrentGet { [weak self] result, err in
			guard let ss = self else {
				return
			}
			if let torrents = result {
				var updateIndex: [Int] = []
				var countInsert = 0

				torrents.forEach { torrent in
					if let index = ss.torrents.indexOf(torrent) {
						ss.torrents[index] = torrent
						updateIndex.append(index)
						// update value

					} else {
						ss.torrents.append(torrent)
						countInsert += 1
					}
				}

				let deletedIndexes = self?.torrents.filter {
						!torrents.contains($0)
					} .flatMap {
						self?.torrents.indexOf($0)
					}

				// Insert rows
				if countInsert > 0 {
                    let indexPaths: [NSIndexPath] = (0..<countInsert).flatMap {
						NSIndexPath(forRow: ss.tableView.numberOfRowsInSection(0) + $0, inSection: 0)
					}
                    ss.tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
				}
				// Update rows
				if updateIndex.count > 0 {
                    ss.tableView.reloadRowsAtIndexPaths(updateIndex.flatMap({NSIndexPath(forRow: $0, inSection: 0)}), withRowAnimation: .None)
				}
				// Delete rows
				if deletedIndexes?.count > 0 {
					deletedIndexes?.forEach {
						ss.torrents.removeAtIndex($0)
					}
                    ss.tableView.deleteRowsAtIndexPaths(deletedIndexes!.flatMap({NSIndexPath(forRow: $0, inSection: 0)}), withRowAnimation: .None)
				}

//				print("DEL : \(deletedIndexes?.count)")
//				print("INS : \(countInsert)")
//				print("UPD : \(updateIndex.count)")
			}
		}
	}

	@IBAction func toggleSlowAction(sender: AnyObject) {
		client.sessionSet(["alt-speed-enabled": !session!.altSpeedEnabled]) { (result, _) in
			print(result)
		}
	}

	@IBAction func downloadAction(sender: AnyObject) {
		let debianMagnetLink = "magnet:?xt=urn:btih:CD8158937344B2A066446BED7E7A0C45214F1245&dn=debian+8+2+0+amd64+dvd+1+iso&tr=udp%3A%2F%2Ftracker.openbittorrent.com%3A80%2Fannounce&tr=udp%3A%2F%2Fopen.demonii.com%3A1337"
		client.loadMagnetLink(debianMagnetLink) { success, error in
			print(success)
		}
	}

	private func timeToHuman(time: NSTimeInterval) -> String {
		let interval: Int = Int(time)
		let day = (interval / (3600 * 24)) % (3600*24)
		let hrs = ((interval - (day * 3600 * 24)) / 3600) % 3600
		let min = (interval - (hrs * 3600) / 60) % 60
		return String(format: "%2ldd %dh%dm", day, hrs, min)
	}

	private func bytesToHuman(bytes: Int) -> String {
		let b = Float(bytes)
		let base: Float = 1000
		if b > pow(base, 3) {
			return String(format: "%.02f GB", b/pow(base, 3))
		} else if b > pow(base, 2) {
			return String(format: "%.02f MB", b/pow(base, 2))
		} else if b > base {
			return String(format: "%.02f KB", b/base)
		} else {
			return "\(bytes) B"
		}

	}
}

extension ViewController: UITableViewDataSource {
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return torrents.count
	}

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("aCell")!

		let torrent = torrents[indexPath.row]
		(cell.viewWithTag(1) as? UILabel)?.text = torrent.name
		(cell.viewWithTag(4) as? UIProgressView)?.progress = torrent.percentDone

		(cell.viewWithTag(2) as? UILabel)?.text = String(format: "%@ of %@ (%.2f%%) - %@ remaining", bytesToHuman(Int(Float(torrent.totalSize) * torrent.percentDone)), bytesToHuman(torrent.totalSize), torrent.percentDone*100, timeToHuman(torrent.eta))


		if torrent.status == .downloading {
			(cell.viewWithTag(3) as? UILabel)?.text = String(format: "Downloading from %d of %d peers %@/s", torrent.peersSendingToUs, torrent.peersConnected, bytesToHuman(torrent.rateDownload))

		} else if torrent.status == .paused {
			(cell.viewWithTag(3) as? UILabel)?.text = "Paused"
		}

		return cell
	}
}

extension ViewController: UITableViewDelegate {

	func tableView(tableView: UITableView, canEditRowAtindexPath: NSIndexPath) -> Bool {
		return true
	}

	func tableView(tableView: UITableView, willBeginEditingRowAt indexPath: NSIndexPath) {
		// pause polling
		timers.forEach {
			$0.fireDate = NSDate.distantFuture()
		}
	}

	func tableView(tableView: UITableView, didEndEditingRowAtindexPath: NSIndexPath) {
		// resume polling
		timers.forEach {
			$0.fireDate = NSDate()
		}
	}

	func tableView(tableView: UITableView, editActionsForRowAt indexPath: NSIndexPath) -> [UITableViewRowAction]? {
		let torrent = torrents[indexPath.row]
		var actions = [
			UITableViewRowAction(style: .Destructive, title: "Delete", handler: { (_, indexPath) in
				self.client.removeTorrent([torrent], trashData: true) { result, error in
					if (result as? Bool) == true {
						self.torrents.removeAtIndex(indexPath.row)
						self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
						self.tableView.setEditing(false, animated: true)
					}
				}
			})
		]
		if torrent.status == .paused {
			actions.append(UITableViewRowAction(style: .Normal, title: "Resume", handler: { (_, indexPath) in
				self.client.resumeTorrent([torrent], completion: { _, _ in
					tableView.setEditing(false, animated: true)
				})
			}))
		} else if torrent.status == .downloading || torrent.status == .seeding {
			actions.append(UITableViewRowAction(style: .Normal, title: "Pause", handler: { (_, indexPath) in
                self.client.pauseTorrent([torrent], completion: { _, _ in
                    tableView.setEditing(false, animated: true)
				})
			}))
		}
		return actions
	}
}
