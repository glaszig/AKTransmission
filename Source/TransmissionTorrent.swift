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

public class TransmissionTorrent: Hashable {

	/// Torrent id
	public let id: Int

	public let percentDone: Float // 0.0 > 1
	public let downloadDir: String
	public let name: String
	public let queuePosition: Int

	public let peersGettingFromUs: Int
	public let peersSendingToUs: Int
	public let peersConnected: Int

	public let status: TransmissionTorrentStatus
	public let totalSize: Int

	public let addedDate: Date
	public let rateDownload: Int
	public let rateUpload: Int
	public let isFinished: Bool // Downloading & Seeding
	public let eta: TimeInterval


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
		totalSize = data["totalSize"] as! Int
		eta = data["eta"] as! TimeInterval
		rateDownload = data["rateDownload"] as! Int
		rateUpload = data["rateUpload"] as! Int
		addedDate = Date(timeIntervalSince1970: data["addedDate"] as! Double)
	}

	public var hashValue: Int {
		return id
	}
}
