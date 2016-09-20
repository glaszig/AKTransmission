//
//  TransmissionRoute.swift
//  Pods
//
//  Created by Florian Morello on 09/11/15.
//
//

import Foundation
import Alamofire

enum TransmissionRoute: URLRequestConvertible {
    public func asURLRequest() throws -> URLRequest {
        return urlRequest
    }

	case magnetLink(String)
	case sessionGet
	case sessionSet([String: Any])
	case sessionStats
	case torrentGet
	case torrentStop([Int])
	case torrentStart([Int])
	case torrentRemove(ids: [Int], trashData: Bool) // from list

	var params: [String: Any] {

		switch self {
		case .sessionGet:
			return [
				"method": "session-get",
			]

		case .sessionSet(let arguments):
			return [
				"method": "session-set",
				"arguments" : arguments
			]

		case .sessionStats:
			return [
				"method": "session-stats",
			]

		case .torrentStart(let ids):
			return [
				"method": "torrent-start",
				"arguments" : [
					"ids": ids
				]
			]

		case .torrentRemove(let ids, let trashData):
			return [
				"method": "torrent-remove",
				"arguments" : [
					"delete-local-data": trashData,
					"ids": ids
				]
			]

		case .torrentStop(let ids):
			return [
				"method": "torrent-stop",
				"arguments" : [
					"ids": ids
				]
			]

		case .torrentGet:
			return [
				"method": "torrent-get",
				"arguments": [
					"fields": ["id", "addedDate", "name", "totalSize", "error", "errorString", "eta", "isFinished", "isStalled", "leftUntilDone", "metadataPercentComplete", "peersConnected", "peersGettingFromUs", "peersSendingToUs", "percentDone", "queuePosition", "rateDownload", "rateUpload", "recheckProgress", "seedRatioMode", "seedRatioLimit", "sizeWhenDone", "status", "trackers", "downloadDir", "uploadedEver", "uploadRatio", "webseedsSendingToUs"] // swiftlint:disable:this line_length
				]
			]

		case .magnetLink(let link):
			return [
				"method": "torrent-add",
				"arguments": [
					"paused": 0,
					"filename": link
				]
			]
		}
	}

    var urlRequest: URLRequest {
		let request = URLRequest(url: URL(string: "http://dummyhost.com/transmission/rpc")!)
        do {
            return try JSONEncoding.default.encode(request, with: params)
        } catch {
            return request
        }
	}

}
