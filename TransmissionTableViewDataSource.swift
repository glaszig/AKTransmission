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

public class TransmissionTableViewDataSource: NSObject, UITableViewDataSource {

    public var pollInterval: NSTimeInterval = 2
    public var cellIdentifier: String = "cell"
    var torrentTimer: NSTimer!
    var torrents: [TransmissionTorrent] = []

    weak var theTableview: UITableView!
    weak var client: Transmission!

    public var polling: Bool = false {
        didSet {
            if polling {
                torrentTimer.fireDate = NSDate()
            } else {
                torrentTimer.fireDate = NSDate.distantFuture()
            }
        }
    }

    init(client: Transmission) {
        self.client = client
        super.init()

        torrentTimer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: #selector(TransmissionTableViewDataSource.pollTorrent), userInfo: nil, repeats: true)
        polling = false
    }

    public func deleteRowsAtIndexPaths(indexPaths: [NSIndexPath], withRowAnimation animation: UITableViewRowAnimation) {
        // make sure its descending
        indexPaths.reverse().forEach {
            torrents.removeAtIndex($0.row)
        }
        theTableview.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
    }

    public func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }

    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        theTableview = tableView
        return torrents.count
    }

    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        theTableview = tableView
        guard let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as? TransmissionTableViewCell else {
            fatalError("Need to implement TransmissionTableViewCell")
        }
        cell.torrent = torrents[indexPath.row]
        return cell as! UITableViewCell
    }

    func pollTorrent() {
        client.torrentGet { [weak self] result, err in
            guard let ss = self, torrents = result else {
                return
            }
            var updateIndex: [Int] = []
            var countInsert = 0

            torrents.forEach { torrent in
                if let index = ss.torrents.indexOf(torrent) {
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
                self?.torrents.indexOf($0)
            }

            // Insert rows
            if countInsert > 0 {
                let indexPaths: [NSIndexPath] = (0..<countInsert).flatMap {
                    NSIndexPath(forRow: ss.theTableview.numberOfRowsInSection(0) + $0, inSection: 0)
                }
                ss.theTableview.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
            }
            // Update rows
            if updateIndex.count > 0 {
                let indexPaths = updateIndex.flatMap { NSIndexPath(forRow: $0, inSection: 0) }
                ss.theTableview.indexPathsForVisibleRows?.filter { indexPaths.contains($0) }.forEach {
                    (ss.theTableview.cellForRowAtIndexPath($0) as? TransmissionTableViewCell)?.torrent = torrents[$0.row]
                }
            }
            // Delete rows
            if deletedIndexes.count > 0 {
                deletedIndexes.forEach {
                    ss.torrents.removeAtIndex($0)
                }
                ss.theTableview.deleteRowsAtIndexPaths(deletedIndexes.flatMap({NSIndexPath(forRow: $0, inSection: 0)}), withRowAnimation: .None)
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
