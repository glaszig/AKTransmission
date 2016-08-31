//
//  TransmissionTableViewDataSource.swift
//  AKTransmission
//
//  Created by Florian Morello on 17/08/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import Alamofire

open class TransmissionTableViewCell: UITableViewCell {
    @IBOutlet public weak var progressView: UIProgressView?
    @IBOutlet public weak var torrentName: UILabel?
    @IBOutlet public weak var torrentInfo: UILabel?
    @IBOutlet public weak var torrentSpeed: UILabel?

    private func timeToHuman(_ time: TimeInterval) -> String {
        let interval: Int = Int(time)
        let day = (interval / (3600 * 24)) % (3600*24)
        let hrs = ((interval - (day * 3600 * 24)) / 3600) % 3600
        let min = (interval - (hrs * 3600) / 60) % 60
        return String(format: "%2ldd %dh%dm", day, hrs, min)
    }

    open var torrent: TransmissionTorrent! {
        didSet {
            progressView?.progress = torrent.percentDone

            let bc = ByteCountFormatter()
            bc.countStyle = .file
            bc.allowsNonnumericFormatting = false
            bc.allowedUnits = [.useKB, .useMB, .useGB]

            torrentName?.text = torrent.name
            torrentInfo?.text = String(format: "%@ of %@ (%.2f%%)", bc.string(fromByteCount: Int64(Float(torrent.totalSize) * torrent.percentDone)), bc.string(fromByteCount: torrent.totalSize), torrent.percentDone * 100)
            if torrent.isFinished {
                progressView?.progressTintColor = .green
                torrentSpeed?.text = "Seeding complete"
            } else if torrent.status == .seeding {
                progressView?.progressTintColor = .green
                torrentSpeed?.text = String(format: "Seeding to %d of %d peers - UL: %@/s", torrent.peersGettingFromUs, torrent.peersConnected, bc.string(fromByteCount: torrent.rateUpload))
                torrentInfo?.text = String(format: "%@, uploaded %@",
                                            bc.string(fromByteCount: torrent.totalSize),
                                            bc.string(fromByteCount: torrent.uploadedEver)
                )
            } else if torrent.status == .downloading {
                progressView?.progressTintColor = .blue
                progressView?.trackTintColor = .lightGray
                torrentInfo?.text?.append(String(format: " - %@ remaining", timeToHuman(torrent.eta)))
                torrentSpeed?.text = String(format: "Downloading from %d of %d peers - DL: %@/s, UL: %@/s",
                                            torrent.peersSendingToUs,
                                            torrent.peersConnected,
                                            bc.string(fromByteCount: torrent.rateDownload),
                                            bc.string(fromByteCount: torrent.rateUpload)
                )
            } else if torrent.status == .paused {
                torrentSpeed?.text = "Paused"
                progressView?.progressTintColor = .gray
                progressView?.trackTintColor = .white
            }
        }
    }
}

public class TransmissionTableViewDataSource: NSObject {

    public var pollInterval: TimeInterval = 2
    public var cellIdentifier: String = "cell"
    var torrentTimer: Timer!
    var torrents: [TransmissionTorrent] = []

    weak var theTableview: UITableView!
    weak var client: Transmission!

    public var polling: Bool = false {
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

    public func deleteRowsAtIndexPaths(_ indexPaths: [IndexPath], withRowAnimation animation: UITableViewRowAnimation) {
        // make sure its descending
        indexPaths.reversed().forEach {
            torrents.remove(at: ($0 as NSIndexPath).row)
        }
        theTableview.deleteRows(at: indexPaths, with: .automatic)
    }

    public func torrent(at indexPath: IndexPath) -> TransmissionTorrent? {
        return torrents[indexPath.row]
    }

    public func pauseTorrent(at indexPath: IndexPath) -> Request? {
        return client.pauseTorrent([torrents[indexPath.row]]) { result, error in
            return
        }
    }

    public func resumeTorrent(at indexPath: IndexPath) -> Request? {
        return client.resumeTorrent([torrents[indexPath.row]]) { [weak self] result, error in
            self?.torrentTimer.fire()
        }
    }

    public func pauseAll() -> Request {
        return client.pauseTorrent(torrents) { [weak self] result, error in
            self?.torrentTimer.fire()
        }
    }

    public func resumeAll() -> Request {
        return client.resumeTorrent(torrents) { [weak self] result, error in
            self?.torrentTimer.fire()
        }
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

extension TransmissionTableViewDataSource: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        theTableview = tableView
        return torrents.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        theTableview = tableView
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? TransmissionTableViewCell else {
            fatalError("Need to implement TransmissionTableViewCell")
        }
        cell.torrent = torrents[(indexPath as NSIndexPath).row]
        return cell
    }
}
