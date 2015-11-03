# AKTransmission

[![CI Status](http://img.shields.io/travis/Florian Morello/AKTransmission.svg?style=flat)](https://travis-ci.org/Florian Morello/AKTransmission)
[![Version](https://img.shields.io/cocoapods/v/AKTransmission.svg?style=flat)](http://cocoapods.org/pods/AKTransmission)
[![License](https://img.shields.io/cocoapods/l/AKTransmission.svg?style=flat)](http://cocoapods.org/pods/AKTransmission)
[![Platform](https://img.shields.io/cocoapods/p/AKTransmission.svg?style=flat)](http://cocoapods.org/pods/AKTransmission)

## Usage

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

AKTransmission is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "AKTransmission"
```

Edit your Info.plist to allow insecure http loads according to your domain
as transmission web interface isn't on https.
```
<dict>
<key>NSExceptionDomains</key>
<dict>
<key>localhost</key>
<dict>
<key>NSExceptionAllowsInsecureHTTPLoads</key>
<true/>
</dict>
</dict>
</dict>
```


## Author

Florian Morello, arsonik@me.com

## License

AKTransmission is available under the MIT license. See the LICENSE file for more info.
