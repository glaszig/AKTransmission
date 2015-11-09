//
//  TransmissionRoute.swift
//  Pods
//
//  Created by Florian Morello on 09/11/15.
//
//

import Foundation
import Alamofire

enum TransmissionRoute : URLRequestConvertible {

	case MagnetLink(String)
	case SessionGet
	case SessionStats
	case TorrentGet
	case TorrentStop([Int])
	case TorrentStart([Int])
	case TorrentRemove(ids: [Int], trashData: Bool) // from list

	var HTTPMethod: Alamofire.Method {
		return Alamofire.Method.POST
	}

	var params: [String: AnyObject] {

		switch self {
		case .SessionGet:
			return [
				"method": "session-get",
			]

		case .SessionStats:
			return [
				"method": "session-stats",
			]

		case .TorrentStart(let ids):
			return [
				"method": "torrent-start",
				"arguments" : [
					"ids": ids
				]
			]

		case .TorrentRemove(let ids, let trashData):
			return [
				"method": "torrent-remove",
				"arguments" : [
					"delete-local-data": trashData,
					"ids": ids
				]
			]

		case .TorrentStop(let ids):
			return [
				"method": "torrent-stop",
				"arguments" : [
					"ids": ids
				]
			]

		case .TorrentGet:
			return [
				"method": "torrent-get",
				"arguments": [
					"fields": ["id","addedDate","name","totalSize","error","errorString","eta","isFinished","isStalled","leftUntilDone","metadataPercentComplete","peersConnected","peersGettingFromUs","peersSendingToUs","percentDone","queuePosition","rateDownload","rateUpload","recheckProgress","seedRatioMode","seedRatioLimit","sizeWhenDone","status","trackers","downloadDir","uploadedEver","uploadRatio","webseedsSendingToUs"]
				]
			]

		case .MagnetLink(let link):
			return [
				"method": "torrent-add",
				"arguments": [
					"paused": 0,
					"filename": link
				]
			]
		}
	}

	var URLRequest: NSMutableURLRequest {
		let request = NSMutableURLRequest(URL: NSURL(string: "http://dummyhost.com/transmission/rpc")!)
		request.HTTPMethod = HTTPMethod.rawValue
		return Alamofire.ParameterEncoding.JSON.encode(request, parameters: params).0
	}

}