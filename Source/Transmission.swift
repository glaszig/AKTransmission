
//
//  Transmission.swift
//
//  Created by Florian Morello on 30/07/14.
//  Copyright (c) 2014 Arsonik. All rights reserved.
//

import Foundation
import Alamofire

open class Transmission {

	fileprivate let sessionHeader: String = "X-Transmission-Session-Id"

	fileprivate var sessionId: String!
	open let username: String
	open let password: String
    open let host: String
	open let port: UInt
    open var timeout: TimeInterval = 5

	public typealias completionHandler = (Any?, Error?) -> Void

    open lazy var tableviewDataSource: TransmissionTableViewDataSource = {
        return TransmissionTableViewDataSource(client: self)
    }()

	public init(host: String, username: String, password: String, port: UInt! = 9091) {
		self.username = username
		self.password = password
		self.host = host
		self.port = port
	}

	fileprivate func request(_ route: TransmissionRoute) -> URLRequest {
		var request = route.urlRequest!
		var comps = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
		comps.host = host
		comps.port = Int(port)
		request.url = comps.url!
		request.setValue(sessionId, forHTTPHeaderField: sessionHeader)
        request.timeoutInterval = timeout
		return request as URLRequest
	}

	private enum ResponseStatus {
		case retry
		case success([String: AnyObject])
		case error(Error?)
	}

	fileprivate func handleResponse(_ response: DataResponse<Any>) -> ResponseStatus {
		if let sid = response.response?.allHeaderFields[self.sessionHeader] as? String,
            response.response?.statusCode == 409 {
			self.sessionId = sid
			return ResponseStatus.retry
		} else if let res = response.result.value as? [String: AnyObject],
            let result = res["result"] as? String,
            let args = res["arguments"] as? [String: AnyObject],
            result == "success" {
			return .success(args)
		} else {
			return ResponseStatus.error(response.result.error)
		}
	}

	open func loadMagnetLink(_ magnet: String, success: @escaping ((_ success: Bool, _ error: Error?) -> Void)) -> Request {
		let route = TransmissionRoute.magnetLink(magnet)

		return Alamofire.request(request(route))
			.authenticate(user: username, password: password)
			.responseJSON { [weak self] response in
				guard let handled = self?.handleResponse(response) else {
					return
				}
				switch handled {
				case .retry:
					let _ = self?.loadMagnetLink(magnet, success: success)
				case .success:
					success(true, nil)
				case .error(let error):
					success(false, error)
				}
		}
	}

	open func sessionGet(_ completion: @escaping (TransmissionSession?, Error?) -> Void) -> Request {
		return Alamofire.request(request(TransmissionRoute.sessionGet))
			.authenticate(user: username, password: password)
			.responseJSON { [weak self] response in
				guard let handled = self?.handleResponse(response) else {
					return
				}
				switch handled {
				case .retry:
					let _ = self?.sessionGet(completion)
				case .success(let data):
					completion(TransmissionSession(data: data), nil)
				case .error(let error):
					completion(nil, error)
				}
		}
	}

	open func sessionSet(_ arguments: [String: Any], completion: @escaping completionHandler) -> Request {
		return Alamofire.request(request(TransmissionRoute.sessionSet(arguments)))
			.authenticate(user: username, password: password)
			.responseJSON { [weak self] response in
				guard let handled = self?.handleResponse(response) else {
					return
				}
				switch handled {
				case .retry:
					let _ = self?.sessionSet(arguments, completion: completion)
				case .success(let data):
					completion(data, nil)
				case .error(let error):
					completion(nil, error)
				}
		}
	}

	open func pauseTorrent(_ torrents: [TransmissionTorrent], completion: @escaping completionHandler) -> Request {
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
					let _ = self?.pauseTorrent(torrents, completion: completion)
				case .success:
					completion(true, nil)
				case .error(let error):
					completion(nil, error)
				}
		}
	}

	open func resumeTorrent(_ torrents: [TransmissionTorrent], completion: @escaping completionHandler) -> Request {
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
					let _ = self?.resumeTorrent(torrents, completion: completion)
				case .success:
					completion(true, nil)
				case .error(let error):
					completion(nil, error)
				}
		}
	}

	open func removeTorrent(_ torrents: [TransmissionTorrent], trashData: Bool, completion: @escaping completionHandler) -> Request {
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
					let _ = self?.removeTorrent(torrents, trashData: trashData, completion: completion)
				case .success:
					completion(true, nil)
				case .error(let error):
					completion(nil, error)
				}
		}
	}

	open func torrentGet(_ completion: @escaping ([TransmissionTorrent]?, Error?) -> Void) -> Request {
		return Alamofire.request(request(TransmissionRoute.torrentGet))
			.authenticate(user: username, password: password)
			.responseJSON { [weak self] response in
                guard let handled = self?.handleResponse(response) else {
                    return
                }
				switch handled {
				case .retry:
					let _ = self?.torrentGet(completion)
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
