#
# Be sure to run `pod lib lint GTNetworkChecker.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'GTNetworkChecker'
  s.version          = '0.1.0'
  s.summary          = 'Library that helps check internet quality of iOS device.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = 'Library helps check internet speed and quality of iOS device programmatically'

  s.homepage         = 'https://github.com/Ar7Style/GTNetworkChecker'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Ar7Style' => 'g.tareyev@pediatr247.ru' }
  s.source           = { :git => 'https://github.com/Ar7Style/GTNetworkChecker.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'GTNetworkChecker/Classes/**/*'
  
  # s.resource_bundles = {
  #   'GTNetworkChecker' => ['GTNetworkChecker/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
