//
//  TransmissionSession.swift
//  Pods
//
//  Created by Florian Morello on 11/04/16.
//
//

import Foundation

open class TransmissionSession {

	open let version: String

	open let altSpeedDown: Int
	open let altSpeedUp: Int
	open let altSpeedEnabled: Bool

	open let speedLimitDown: Int
	open let speedLimitUp: Int
	open let speedLimitUpEnabled: Bool
	open let speedLimitDownEnabled: Bool

	init?(data: [String: AnyObject]!) {
		guard let ver = data["version"] as? String else {
			return nil
		}
		version = ver
		altSpeedUp = data["alt-speed-up"] as! Int
		altSpeedDown = data["alt-speed-down"] as! Int
		altSpeedEnabled = data["alt-speed-enabled"] as! Bool
		speedLimitDown = data["speed-limit-down"] as! Int
		speedLimitUp = data["speed-limit-up"] as! Int
		speedLimitUpEnabled = data["speed-limit-up-enabled"] as! Bool
		speedLimitDownEnabled = data["speed-limit-down-enabled"] as! Bool
	}

}
