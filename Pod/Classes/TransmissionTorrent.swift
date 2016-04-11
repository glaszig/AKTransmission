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
	case Paused = 0
	case Queued = 3
	case Downloading = 4
	case Seeding = 6
}

public func == (left: TransmissionTorrent, right: TransmissionTorrent) -> Bool {
	return left.hashValue == right.hashValue
}

public class TransmissionTorrent: Hashable {

	/// Torrent id
	public let id: Int

	public let percentDone: Float
	public let downloadDir: String
	public let name: String
	public let queuePosition: Int

	public let peersSendingToUs: Int
	public let peersConnected: Int

	public let status: TransmissionTorrentStatus
	public let totalSize: Int

	public let addedDate: NSDate
	public let rateDownload: Int
	public let rateUpload: Int
	public let isFinished: Bool
	public let eta: NSTimeInterval


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
		peersConnected = data["peersConnected"] as! Int
		isFinished = data["isFinished"] as! Bool
		if let c = data["status"] as? Int, stt = TransmissionTorrentStatus(rawValue: c) {
			status = stt
		} else {
			print(data["status"])
			fatalError("Unknow status please report to the autor")
		}
		totalSize = data["totalSize"] as! Int
		eta = data["eta"] as! NSTimeInterval
		rateDownload = data["rateDownload"] as! Int
		rateUpload = data["rateUpload"] as! Int
		addedDate = NSDate(timeIntervalSince1970: data["addedDate"] as! Double)
	}

	public var hashValue: Int {
		return id
	}
}
