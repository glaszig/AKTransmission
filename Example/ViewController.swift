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

    let client: Transmission = Transmission(host: "localhost", username: "admin", password: "admin", port: 9091)
	var session: TransmissionSession?
	var sessionTimer: Timer!

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.tableFooterView = UIView()
        let datasource = client.tableviewDataSource
        datasource.cellIdentifier = "aCell"
        datasource.pollInterval = 5
        tableView.dataSource = datasource

        // schedule polling
        sessionTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(ViewController.pollSession), userInfo: nil, repeats: true)
        sessionTimer.fireDate = Date.distantFuture
    }

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

        (tableView.dataSource as? TransmissionTableViewDataSource)?.polling = true
        sessionTimer.fireDate = Date()
	}

	override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        (tableView.dataSource as? TransmissionTableViewDataSource)?.polling = false
        sessionTimer.fireDate = Date.distantFuture
	}

	func pollSession() {
		let _ = client.sessionGet { [weak self] result, error in
			if let session = result {
				self?.session = session
                self?.slowModeButton?.tintColor = session.altSpeedEnabled ? UIColor.red : UIColor.blue
			}
		}
	}

	@IBAction func toggleSlowAction(_ sender: AnyObject) {
		let _ = client.sessionSet(["alt-speed-enabled": !session!.altSpeedEnabled]) { result, _ in
			print(result)
		}
	}

	@IBAction func downloadAction(_ sender: AnyObject) {
		let debianMagnetLink = "magnet:?xt=urn:btih:CD8158937344B2A066446BED7E7A0C45214F1245&dn=debian+8+2+0+amd64+dvd+1+iso&tr=udp%3A%2F%2Ftracker.openbittorrent.com%3A80%2Fannounce&tr=udp%3A%2F%2Fopen.demonii.com%3A1337" // swiftlint:disable:this line_length
		let _ = client.loadMagnetLink(debianMagnetLink) { success, error in
			print(success)
		}
	}
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        guard let datasource = (tableView.dataSource as? TransmissionTableViewDataSource),
            let torrent = datasource.torrent(at: indexPath) else {
            return nil
        }
		var actions = [
			UITableViewRowAction(style: .destructive, title: "Delete", handler: { [weak self] _, _ in
				let _ = self?.client.removeTorrent([torrent], trashData: true) { result, error in
					if (result as? Bool) == true {
                        datasource.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .automatic)
						self?.tableView.setEditing(false, animated: true)
					}
				}
			})
		]
		if torrent.status == .paused {
			actions.append(UITableViewRowAction(style: .normal, title: "Resume", handler: { (_, _) in
				let _ = self.client.resumeTorrent([torrent], completion: { _, _ in
					tableView.setEditing(false, animated: true)
				})
			}))
		} else if torrent.status == .downloading || torrent.status == .seeding {
			actions.append(UITableViewRowAction(style: .normal, title: "Pause", handler: { (_, _) in
                let _ = self.client.pauseTorrent([torrent], completion: { _, _ in
                    tableView.setEditing(false, animated: true)
				})
			}))
		}
		return actions
	}
}
