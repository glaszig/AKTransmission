//
//  TransmissionTorrent.swift
//  Pods
//
//  Created by Florian Morello on 09/11/15.
//
//

import Foundation

// TODO: Make it work
public enum TransmissionTorrentStatus: Int {
	case paused = 0
	case queued = 3
	case downloading = 4
	case seeding = 6
}

public func == (left: TransmissionTorrent, right: TransmissionTorrent) -> Bool {
	return left.hashValue == right.hashValue
}

open class TransmissionTorrent: Hashable {

	/// Torrent id
	open let id: Int

	open let percentDone: Float // 0.0 > 1
	open let downloadDir: String
	open let name: String
	open let queuePosition: Int

	open let peersGettingFromUs: Int
	open let peersSendingToUs: Int
	open let peersConnected: Int

	open let status: TransmissionTorrentStatus
	open let totalSize: Int64 // byte size

	open let addedDate: Date
	open let rateDownload: Int64 // byte size
	open let rateUpload: Int64 // byte size
	open let isFinished: Bool // Downloading & Seeding
	open let eta: TimeInterval


	init?(data: [String: AnyObject]) {
		guard let identifier = data["id"] as? Int else {
			return nil
		}

		id = identifier
		name = data["name"] as! String
		downloadDir = data["downloadDir"] as! String
		percentDone = data["percentDone"] as! Float
		queuePosition = data["queuePosition"] as! Int
		peersSendingToUs = data["peersSendingToUs"] as! Int
		peersGettingFromUs = data["peersGettingFromUs"] as! Int
		peersConnected = data["peersConnected"] as! Int
		isFinished = data["isFinished"] as! Bool
		if let c = data["status"] as? Int,
            let stt = TransmissionTorrentStatus(rawValue: c) {
			status = stt
		} else {
			print(data["status"])
			fatalError("Unknow status please report to the autor")
		}
		totalSize = Int64(data["totalSize"] as! Int)
		eta = data["eta"] as! TimeInterval
		rateDownload = Int64(data["rateDownload"] as! Int)
		rateUpload = Int64(data["rateUpload"] as! Int)
		addedDate = Date(timeIntervalSince1970: data["addedDate"] as! Double)
	}

	open var hashValue: Int {
		return id
	}
}
