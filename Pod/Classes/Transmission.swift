
//
//  Transmission.swift
//
//  Created by Florian Morello on 30/07/14.
//  Copyright (c) 2014 Arsonik. All rights reserved.
//

import Foundation
import Alamofire

public class Transmission {

	private let sessionHeader:String = "X-Transmission-Session-Id"

	private var sessionId:String!

	public let username: String
	public let password: String
    public let host: String
	public let port: UInt
    public var timeout: NSTimeInterval = 10

	public typealias completionHandler = (AnyObject?, NSError?) -> Void


	public init(host:String, username:String, password:String, port:UInt! = 9091){
		self.username = username
		self.password = password
		self.host = host
		self.port = port
	}


	private func request(route: TransmissionRoute) -> NSMutableURLRequest {
		let request = route.URLRequest
		let comps = NSURLComponents(URL: request.URL!, resolvingAgainstBaseURL: false)!
		comps.host = host
		comps.port = port
		request.URL = comps.URL!
		request.setValue(sessionId, forHTTPHeaderField: sessionHeader)
        request.timeoutInterval = timeout
		return request
	}


	private enum ResponseStatus {
		case Retry
		case Success([String: AnyObject])
		case Error(NSError?)
	}

	private func handleResponse(response: Response<AnyObject, NSError>) -> ResponseStatus {
		if let sid = response.response?.allHeaderFields[self.sessionHeader] as? String where response.response?.statusCode == 409 {
			self.sessionId = sid
			return .Retry
		}
		else if let res = response.result.value as? [String: AnyObject], result = res["result"] as? String, args = res["arguments"] as? [String: AnyObject] where result == "success" {
			// ok
			return .Success(args)
		}
		else {
			return .Error(response.result.error)
		}
	}

	public func loadMagnetLink(magnet: String, success: ((success: Bool, error: NSError?) -> Void)) -> Request {

		let route = TransmissionRoute.MagnetLink(magnet)

		return Alamofire.request(request(route))
			.authenticate(user: username, password: password)
			.responseJSON { (response) -> Void in
				switch self.handleResponse(response) {
				case .Retry:
					self.loadMagnetLink(magnet, success: success)
				case .Success:
					success(success: true, error: nil)
				case .Error(let error):
					success(success: false, error: error)
				}
		}
	}

	public func sessionGet(completion: completionHandler) -> Request {
		return Alamofire.request(request(TransmissionRoute.SessionGet))
			.authenticate(user: username, password: password)
			.responseJSON { (response) -> Void in
				switch self.handleResponse(response) {
				case .Retry:
					self.sessionGet(completion)
				case .Success(let data):
					completion(data, nil)
				case .Error(let error):
					completion(nil, error)
				}
		}
	}

	public func pauseTorrent(torrents:[TransmissionTorrent], completion: completionHandler) -> Request {
		var ids:[Int] = []
		for torrent in torrents {
			ids.append(torrent.id)
		}
		return Alamofire.request(request(TransmissionRoute.TorrentStop(ids)))
			.authenticate(user: username, password: password)
			.responseJSON { (response) -> Void in
				switch self.handleResponse(response) {
				case .Retry:
					self.pauseTorrent(torrents, completion: completion)
				case .Success:
					completion(true, nil)
				case .Error(let error):
					completion(nil, error)
				}
		}
	}

	public func resumeTorrent(torrents:[TransmissionTorrent], completion: completionHandler) -> Request {
		var ids:[Int] = []
		for torrent in torrents {
			ids.append(torrent.id)
		}
		return Alamofire.request(request(TransmissionRoute.TorrentStart(ids)))
			.authenticate(user: username, password: password)
			.responseJSON { (response) -> Void in
				switch self.handleResponse(response) {
				case .Retry:
					self.resumeTorrent(torrents, completion: completion)
				case .Success:
					completion(true, nil)
				case .Error(let error):
					completion(nil, error)
				}
		}
	}

	public func removeTorrent(torrents:[TransmissionTorrent], trashData: Bool, completion: completionHandler) -> Request {
		var ids:[Int] = []
		for torrent in torrents {
			ids.append(torrent.id)
		}
		return Alamofire.request(request(TransmissionRoute.TorrentRemove(ids: ids, trashData: trashData)))
			.authenticate(user: username, password: password)
			.responseJSON { (response) -> Void in
				switch self.handleResponse(response) {
				case .Retry:
					self.removeTorrent(torrents, trashData: trashData, completion: completion)
				case .Success:
					completion(true, nil)
				case .Error(let error):
					completion(nil, error)
				}
		}
	}

	public func torrentGet(completion: completionHandler) -> Request {
		return Alamofire.request(request(TransmissionRoute.TorrentGet))
			.authenticate(user: username, password: password)
			.responseJSON { [weak self] response -> Void in
                guard let handled = self?.handleResponse(response) else {
                    return
                }
				switch handled {
				case .Retry:
					self?.torrentGet(completion)
				case .Success(let data):
					if let torrents = data["torrents"] as? [[String: AnyObject]] {
                        let list = torrents.flatMap({
                            TransmissionTorrent(data: $0)
                        })
						completion(list, nil)
					}
				case .Error(let error):
					completion(nil, error)
				}
		}
	}
}