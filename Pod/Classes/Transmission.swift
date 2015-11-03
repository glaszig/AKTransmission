//
//  Transmission.swift
//  iRemote
//
//  Created by Florian Morello on 30/07/14.
//  Copyright (c) 2014 Arsonik. All rights reserved.
//

import Foundation
import Alamofire

class Transmission {
	let sessionHeader:String = "X-Transmission-Session-Id"
	var sessionId:String!
	
    var baseURL:NSURL {
        return NSURL(string: "http://\(host):\(port)")!
    }
	var username:String
	var password:String
    var host:String
	var port:UInt
	
	init(host:String, username:String! = "", password:String! = "", port:UInt! = 9091){
		self.username = username
		self.password = password
		self.host = host
		self.port = port
	}

	func loadMagnetLink(magnet: String, success: ((success: Bool, error: NSError!) -> Void)) {
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

        print("Url \(request.URL) auth: \(username):\(password)")

		Alamofire.request(Alamofire.ParameterEncoding.JSON.encode(request, parameters: params).0)
			.authenticate(user: username, password: password)
			.responseJSON { (response) -> Void in
				if response.response?.statusCode == 409 {
					self.sessionId = response.response?.allHeaderFields[self.sessionHeader] as? String
					return self.loadMagnetLink(magnet, success: success)
				}
				else if let x = response.result.value as? [String:AnyObject] {
					return success(success: x["result"] as? String == "success", error: nil)
				}
				// huh ?
				success(success: false, error: response.result.error)
		}
	}
}