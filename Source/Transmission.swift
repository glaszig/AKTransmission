
//
//  Transmission.swift
//
//  Created by Florian Morello on 30/07/14.
//  Copyright (c) 2014 Arsonik. All rights reserved.
//

import Foundation
import Alamofire

public class Transmission {

	private let sessionHeader: String = "X-Transmission-Session-Id"

	private var sessionId: String!
	public let username: String
	public let password: String
    public let host: String
	public let port: UInt
    public var timeout: TimeInterval = 5

	public typealias completionHandler = (AnyObject?, NSError?) -> Void

	public init(host: String, username: String, password: String, port: UInt! = 9091){
		self.username = username
		self.password = password
		self.host = host
		self.port = port
	}

	private func request(_ route: TransmissionRoute) -> URLRequest {
		var request = route.urlRequest
		var comps = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
		comps.host = host
		comps.port = Int(port)
		request.url = comps.url!
		request.setValue(sessionId, forHTTPHeaderField: sessionHeader)
        request.timeoutInterval = timeout
		return request
	}

	private enum ResponseStatus {
		case retry
		case success([String: AnyObject])
		case error(NSError?)
	}

	private func handleResponse(_ response: Response<AnyObject, NSError>) -> ResponseStatus {
		if let sid = response.response?.allHeaderFields[self.sessionHeader] as? String, response.response?.statusCode == 409 {
			self.sessionId = sid
			return .retry
		}
		else if let res = response.result.value as? [String: AnyObject], let result = res["result"] as? String, let args = res["arguments"] as? [String: AnyObject], result == "success" {
			return .success(args)
		}
		else {
			return .error(response.result.error)
		}
	}

	public func loadMagnetLink(_ magnet: String, success: ((success: Bool, error: NSError?) -> Void)) -> Request {
		let route = TransmissionRoute.magnetLink(magnet)

		return Alamofire.request(request(route))
			.authenticate(user: username, password: password)
			.responseJSON { [weak self] response in
				guard let handled = self?.handleResponse(response) else {
					return
				}
				switch handled {
				case .retry:
					self?.loadMagnetLink(magnet, success: success)
				case .success:
					success(success: true, error: nil)
				case .error(let error):
					success(success: false, error: error)
				}
		}
	}

	public func sessionGet(_ completion: (TransmissionSession?, NSError?) -> Void) -> Request {
		return Alamofire.request(request(TransmissionRoute.sessionGet))
			.authenticate(user: username, password: password)
			.responseJSON { [weak self] response in
				guard let handled = self?.handleResponse(response) else {
					return
				}
				switch handled {
				case .retry:
					self?.sessionGet(completion)
				case .success(let data):
					completion(TransmissionSession(data: data), nil)
				case .error(let error):
					completion(nil, error)
				}
		}
	}

	public func sessionSet(_ arguments: [String: AnyObject], completion: completionHandler) -> Request {
		return Alamofire.request(request(TransmissionRoute.sessionSet(arguments)))
			.authenticate(user: username, password: password)
			.responseJSON { [weak self] response in
				guard let handled = self?.handleResponse(response) else {
					return
				}
				switch handled {
				case .retry:
					self?.sessionSet(arguments, completion: completion)
				case .success(let data):
					completion(data, nil)
				case .error(let error):
					completion(nil, error)
				}
		}
	}

	public func pauseTorrent(_ torrents:[TransmissionTorrent], completion: completionHandler) -> Request {
		let ids = torrents.flatMap {
			$0.id
		}
		return Alamofire.request(request(TransmissionRoute.torrentStop(ids)))
			.authenticate(user: username, password: password)
			.responseJSON { [weak self] response in
				guard let handled = self?.handleResponse(response) else {
					return
				}
				switch handled {
				case .retry:
					self?.pauseTorrent(torrents, completion: completion)
				case .success:
					completion(true, nil)
				case .error(let error):
					completion(nil, error)
				}
		}
	}

	public func resumeTorrent(_ torrents:[TransmissionTorrent], completion: completionHandler) -> Request {
		let ids = torrents.flatMap {
			$0.id
		}
		return Alamofire.request(request(TransmissionRoute.torrentStart(ids)))
			.authenticate(user: username, password: password)
			.responseJSON { [weak self] response in
				guard let handled = self?.handleResponse(response) else {
					return
				}
				switch handled {
				case .retry:
					self?.resumeTorrent(torrents, completion: completion)
				case .success:
					completion(true, nil)
				case .error(let error):
					completion(nil, error)
				}
		}
	}

	public func removeTorrent(_ torrents:[TransmissionTorrent], trashData: Bool, completion: completionHandler) -> Request {
		let ids = torrents.flatMap {
			$0.id
		}
		return Alamofire.request(request(TransmissionRoute.torrentRemove(ids: ids, trashData: trashData)))
			.authenticate(user: username, password: password)
			.responseJSON { [weak self] response in
				guard let handled = self?.handleResponse(response) else {
					return
				}
				switch handled {
				case .retry:
					self?.removeTorrent(torrents, trashData: trashData, completion: completion)
				case .success:
					completion(true, nil)
				case .error(let error):
					completion(nil, error)
				}
		}
	}

	public func torrentGet(_ completion: ([TransmissionTorrent]?, NSError?) -> Void) -> Request {
		return Alamofire.request(request(TransmissionRoute.torrentGet))
			.authenticate(user: username, password: password)
			.responseJSON { [weak self] response in
                guard let handled = self?.handleResponse(response) else {
                    return
                }
				switch handled {
				case .retry:
					self?.torrentGet(completion)
				case .success(let data):
					if let torrents = data["torrents"] as? [[String: AnyObject]] {
						completion(torrents.flatMap({
							TransmissionTorrent(data: $0)
						}), nil)
					} else {
						completion(nil, NSError(domain: "cannot find any torrents", code: 404, userInfo: nil))
					}
				case .error(let error):
					completion(nil, error)
				}
		}
	}
}
