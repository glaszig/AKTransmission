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
	
    private let baseURL:NSURL!

	private let username:String
	private let password:String
    private let host:String
	private let port:UInt

	public init(host:String, username:String, password:String, port:UInt! = 9091){
		self.username = username
		self.password = password
		self.host = host
		self.port = port

		self.baseURL = NSURL(string: "http://\(host):\(port)")
	}

	public func loadMagnetLink(magnet: String, success: ((success: Bool, error: NSError!) -> Void)) -> Request {
		let params = [
			"method": "torrent-add",
			"arguments": [
				"paused": 0,
				"filename": magnet
			]
		]
		let request = NSMutableURLRequest(URL: baseURL.URLByAppendingPathComponent("/transmission/rpc"))
		request.HTTPMethod = Alamofire.Method.POST.rawValue
		request.setValue(sessionId, forHTTPHeaderField: sessionHeader)

		return Alamofire.request(Alamofire.ParameterEncoding.JSON.encode(request, parameters: params).0)
			.authenticate(user: username, password: password)
			.responseJSON { (response) -> Void in
				if response.response?.statusCode == 409 {
					self.sessionId = response.response?.allHeaderFields[self.sessionHeader] as? String
					self.loadMagnetLink(magnet, success: success)
					return ()
				}
				else if let x = response.result.value as? [String:AnyObject] {
					return success(success: x["result"] as? String == "success", error: nil)
				}
				// oops
				success(success: false, error: response.result.error)
		}
	}
}