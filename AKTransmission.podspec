#
# Be sure to run `pod lib lint AKTransmission.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "AKTransmission"
  s.version          = "0.1.1"
  s.summary          = "A Swift class to request Transmission web interface."

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!  
  s.description      = <<-DESC
	Easy access to Tranmission web interface
	http://www.transmissionbt.com
                       DESC

  s.homepage         = "https://github.com/arsonik/AKTransmission"
  s.license          = 'MIT'
  s.author           = { "Florian Morello" => "arsonik@me.com" }
  s.source           = { :git => "https://github.com/arsonik/AKTransmission.git", :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'
  s.tvos.deployment_target = '9.0'
  s.requires_arc = true

  s.source_files = 'Source/**/*'

  s.dependency 'Alamofire'
end
