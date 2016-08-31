//
//  TransmissionTableViewCell.swift
//  AKTransmission
//
//  Created by Florian Morello on 31/08/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit

public class TransmissionTableViewCell: UITableViewCell {
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
