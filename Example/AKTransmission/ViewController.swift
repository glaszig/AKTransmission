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
	var timers: [Timer] = []
	var torrents: [TransmissionTorrent] = []

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		tableView.tableFooterView = UIView()

		// schedule polling
		timers.append(Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(ViewController.pollSession), userInfo: nil, repeats: true))
		timers.append(Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(ViewController.pollTorrent), userInfo: nil, repeats: true))

		// fire them
		timers.forEach {
			$0.fire()
		}
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		// stop polling
		timers.forEach {
			$0.invalidate()
		}
		timers = []
	}

	func pollSession() {
		client.sessionGet { [weak self] result, error in
			if let session = result as? TransmissionSession {
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
			if let torrents = result as? [TransmissionTorrent] {
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
					let indexPaths = (0..<countInsert).flatMap {
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

	@IBAction func toggleSlowAction(_ sender: AnyObject) {
		client.sessionSet(["alt-speed-enabled": !session!.altSpeedEnabled]) { (result, _) in
			print(result)
		}
	}

	@IBAction func downloadAction(_ sender: AnyObject) {
		let debianMagnetLink = "magnet:?xt=urn:btih:CD8158937344B2A066446BED7E7A0C45214F1245&dn=debian+8+2+0+amd64+dvd+1+iso&tr=udp%3A%2F%2Ftracker.openbittorrent.com%3A80%2Fannounce&tr=udp%3A%2F%2Fopen.demonii.com%3A1337"
		client.loadMagnetLink(debianMagnetLink) { success, error in
			print(success)
		}
	}

	private func timeToHuman(_ time: TimeInterval) -> String {
		let interval: Int = Int(time)
		let day = (interval / (3600 * 24)) % (3600*24)
		let hrs = ((interval - (day * 3600 * 24)) / 3600) % 3600
		let min = (interval - (hrs * 3600) / 60) % 60
		return String(format: "%2ldd %dh%dm", day, hrs, min)
	}

	private func bytesToHuman(_ bytes: Int) -> String {
		let b = Float(bytes)
		let base: Float = 1000
		if b > pow(base, 3) {
			return String(format: "%.02f GB", b/pow(base, 3))
		} else if b > pow(base, 2) {
			return String(format: "%.02f MB", b/pow(base, 2))
		} else if b > base {
			return String(format: "%.02f KB", b/base)
		} else  {
			return "\(bytes) B"
		}

	}
}

extension ViewController: UITableViewDataSource {

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return torrents.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "aCell", for: indexPath)

		let torrent = torrents[indexPath.row]
		(cell.viewWithTag(1) as? UILabel)?.text = torrent.name
		(cell.viewWithTag(4) as? UIProgressView)?.progress = torrent.percentDone

		(cell.viewWithTag(2) as? UILabel)?.text = String(format: "%@ of %@ (%.2f%%) - %@ remaining", bytesToHuman(Int(Float(torrent.totalSize) * torrent.percentDone)), bytesToHuman(torrent.totalSize), torrent.percentDone*100, timeToHuman(torrent.eta))


		if torrent.status == .Downloading {
			(cell.viewWithTag(3) as? UILabel)?.text = String(format: "Downloading from %d of %d peers %@/s", torrent.peersSendingToUs, torrent.peersConnected, bytesToHuman(torrent.rateDownload))

		} else if torrent.status == .Paused {
			(cell.viewWithTag(3) as? UILabel)?.text = "Paused"
		}

		return cell
	}
}

extension ViewController: UITableViewDelegate {
	func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return true
	}

	func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
		// pause polling
		timers.forEach {
			$0.fireDate = Date.distantFuture
		}
	}

	func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath) {
		// resume polling
		timers.forEach {
			$0.fireDate = Date()
		}
	}

	func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
		let torrent = torrents[indexPath.row]
		var actions = [
			UITableViewRowAction(style: UITableViewRowActionStyle.Destructive, title: "Delete", handler: { (_, indexPath) in
				self.client.removeTorrent([torrent], trashData: true) { result, error in
					if (result as? Bool) == true {
						self.torrents.removeAtIndex(indexPath.row)
						self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
						self.tableView.editing = false
					}
				}
			})
		]
		if torrent.status == .Paused {
			actions.append(UITableViewRowAction(style: .Normal, title: "Resume", handler: { (_, indexPath) in
				self.client.resumeTorrent([torrent], completion: { (_, _) in
					tableView.editing = false
				})
			}))
		} else if torrent.status == .Downloading || torrent.status == .Seeding {
			actions.append(UITableViewRowAction(style: .Normal, title: "Pause", handler: { (_, indexPath) in
				self.client.pauseTorrent([torrent], completion: { (_, _) in
					tableView.editing = false
				})
			}))
		}
		return actions
	}
}
