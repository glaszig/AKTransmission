//
//  TransmissionTorrent.swift
//  Pods
//
//  Created by Florian Morello on 09/11/15.
//
//

import Foundation

// TODO: Make it work
public enum TransmissionTorrentStatus : Int {
	case Paused = 0
	case Downloading = 4 // DL & UL
	case Done = 6 // UL
}


public class TransmissionTorrent {
	public var id: Int!
	public var percentDone: Float!
	public var downloadDir: String!
	public var name: String!
	public var queuePosition: Int!

	public var peersSendingToUs: Int!
	public var peersConnected: Int!

	public var status: TransmissionTorrentStatus!
	public var totalSize: Int!

	public var addedDate: NSDate!
	public var rateDownload: Int!
	public var rateUpload: Int!
	public var isFinished: Bool!
	public var eta: NSTimeInterval!

	init(data:[String: AnyObject]) {
		name = data["name"] as? String
		downloadDir = data["downloadDir"] as? String
		id = data["id"] as? Int
		percentDone = data["percentDone"] as? Float
		queuePosition = data["queuePosition"] as? Int
		peersSendingToUs = data["peersSendingToUs"] as? Int
		peersConnected = data["peersConnected"] as? Int
		isFinished = data["isFinished"] as? Bool
		if let c = data["status"] as? Int {
			status = TransmissionTorrentStatus(rawValue: c)
		}
		totalSize = data["totalSize"] as? Int
		eta = data["eta"] as? NSTimeInterval
		rateDownload = data["rateDownload"] as? Int
		rateUpload = data["rateUpload"] as? Int
		if let c = data["addedDate"] as? Double {
			addedDate = NSDate(timeIntervalSince1970: c)
		}
	}
}
