//
//  TransmissionTableViewDataSource.swift
//  AKTransmission
//
//  Created by Florian Morello on 17/08/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit

public protocol TransmissionTableViewCell: class {
    var torrent: TransmissionTorrent! { get set }
}

open class TransmissionTableViewDataSource: NSObject, UITableViewDataSource {

    open var pollInterval: TimeInterval = 2
    open var cellIdentifier: String = "cell"
    var torrentTimer: Timer!
    var torrents: [TransmissionTorrent] = []

    weak var theTableview: UITableView!
    weak var client: Transmission!

    open var polling: Bool = false {
        didSet {
            if polling {
                torrentTimer.fireDate = Date()
            } else {
                torrentTimer.fireDate = Date.distantFuture
            }
        }
    }

    init(client: Transmission) {
        self.client = client
        super.init()

        torrentTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(TransmissionTableViewDataSource.pollTorrent), userInfo: nil, repeats: true)
        polling = false
    }

    open func deleteRowsAtIndexPaths(_ indexPaths: [IndexPath], withRowAnimation animation: UITableViewRowAnimation) {
        // make sure its descending
        indexPaths.reversed().forEach {
            torrents.remove(at: ($0 as NSIndexPath).row)
        }
        theTableview.deleteRows(at: indexPaths, with: .automatic)
    }

    open func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        theTableview = tableView
        return torrents.count
    }

    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        theTableview = tableView
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? TransmissionTableViewCell else {
            fatalError("Need to implement TransmissionTableViewCell")
        }
        cell.torrent = torrents[(indexPath as NSIndexPath).row]
        return cell as! UITableViewCell
    }

    func pollTorrent() {
        let _ = client.torrentGet { [weak self] result, err in
            guard let ss = self, let torrents = result else {
                return
            }
            var updateIndex: [Int] = []
            var countInsert = 0

            torrents.forEach { torrent in
                if let index = ss.torrents.index(of: torrent) {
                    ss.torrents[index] = torrent
                    updateIndex.append(index)
                } else {
                    ss.torrents.append(torrent)
                    countInsert += 1
                }
            }

            let deletedIndexes = ss.torrents.filter {
                !torrents.contains($0)
            } .flatMap {
                self?.torrents.index(of: $0)
            }

            // Insert rows
            if countInsert > 0 {
                let indexPaths: [IndexPath] = (0..<countInsert).flatMap {
                    IndexPath(row: ss.theTableview.numberOfRows(inSection: 0) + $0, section: 0)
                }
                ss.theTableview.insertRows(at: indexPaths, with: .automatic)
            }
            // Update rows
            if updateIndex.count > 0 {
                let indexPaths: [IndexPath] = updateIndex.flatMap { IndexPath(row: $0, section: 0) }
                ss.theTableview.indexPathsForVisibleRows?.filter {
                    indexPaths.contains($0)
                }.forEach {
                    (ss.theTableview.cellForRow(at: $0) as? TransmissionTableViewCell)?.torrent = torrents[$0.row]
                }
            }
            // Delete rows
            if deletedIndexes.count > 0 {
                deletedIndexes.forEach {
                    ss.torrents.remove(at: $0)
                }
                ss.theTableview.deleteRows(at: deletedIndexes.flatMap({IndexPath(row: $0, section: 0)}), with: .none)
            }
//            print("DEL : \(deletedIndexes.count)")
//            print("INS : \(countInsert)")
//            print("UPD : \(updateIndex.count)")
        }
    }

    deinit {
        torrentTimer.invalidate()
    }
}
