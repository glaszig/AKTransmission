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

    let client: Transmission = Transmission(host: "nas.local", username: "admin", password: "admin", port: 8181)
	var session: TransmissionSession?
	var sessionTimer: NSTimer!

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.tableFooterView = UIView()
        let datasource = client.tableviewDataSource
        datasource.cellIdentifier = "aCell"
        datasource.pollInterval = 5
        tableView.dataSource = datasource

        // schedule polling
        sessionTimer = NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: #selector(ViewController.pollSession), userInfo: nil, repeats: true)
        sessionTimer.fireDate = NSDate.distantFuture()
    }

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)

        (tableView.dataSource as? TransmissionTableViewDataSource)?.polling = true
        sessionTimer.fireDate = NSDate()
	}

	override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        (tableView.dataSource as? TransmissionTableViewDataSource)?.polling = false
        sessionTimer.fireDate = NSDate.distantFuture()
	}

	func pollSession() {
		client.sessionGet { [weak self] result, error in
			if let session = result {
				self?.session = session
                self?.slowModeButton?.tintColor = session.altSpeedEnabled ? UIColor.redColor() : UIColor.blueColor()
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
}

extension ViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        guard let datasource = (tableView.dataSource as? TransmissionTableViewDataSource), torrent = (datasource.tableView(tableView, cellForRowAtIndexPath: indexPath) as? CustomCell)?.torrent else {
            return nil
        }
		var actions = [
			UITableViewRowAction(style: .Destructive, title: "Delete", handler: { [weak self] _, _ in
				self?.client.removeTorrent([torrent], trashData: true) { result, error in
					if (result as? Bool) == true {
                        datasource.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
						self?.tableView.setEditing(false, animated: true)
					}
				}
			})
		]
		if torrent.status == .paused {
			actions.append(UITableViewRowAction(style: .Normal, title: "Resume", handler: { (_, _) in
				self.client.resumeTorrent([torrent], completion: { _, _ in
					tableView.setEditing(false, animated: true)
				})
			}))
		} else if torrent.status == .downloading || torrent.status == .seeding {
			actions.append(UITableViewRowAction(style: .Normal, title: "Pause", handler: { (_, _) in
                self.client.pauseTorrent([torrent], completion: { _, _ in
                    tableView.setEditing(false, animated: true)
				})
			}))
		}
		return actions
	}
}

class CustomCell: UITableViewCell, TransmissionTableViewCell {
    private func timeToHuman(time: NSTimeInterval) -> String {
        let interval: Int = Int(time)
        let day = (interval / (3600 * 24)) % (3600*24)
        let hrs = ((interval - (day * 3600 * 24)) / 3600) % 3600
        let min = (interval - (hrs * 3600) / 60) % 60
        return String(format: "%2ldd %dh%dm", day, hrs, min)
    }

    var torrent: TransmissionTorrent! {
        didSet {
            let bc = NSByteCountFormatter()
            bc.countStyle = .File
            (viewWithTag(1) as? UILabel)?.text = torrent.name
            (viewWithTag(4) as? UIProgressView)?.progress = torrent.percentDone
            (viewWithTag(2) as? UILabel)?.text = String(format: "%@ of %@ (%.2f%%)", bc.stringFromByteCount(Int64(Float(torrent.totalSize) * torrent.percentDone)), bc.stringFromByteCount(torrent.totalSize), torrent.percentDone * 100)
            if torrent.status == .downloading {
                (viewWithTag(2) as? UILabel)?.text?.appendContentsOf(String(format: " - %@ remaining", timeToHuman(torrent.eta)))
                (viewWithTag(3) as? UILabel)?.text = String(format: "Downloading from %d of %d peers %@/s", torrent.peersSendingToUs, torrent.peersConnected, bc.stringFromByteCount(torrent.rateDownload))
            } else if torrent.status == .paused {
                (viewWithTag(3) as? UILabel)?.text = "Paused"
            }
        }
    }
}
