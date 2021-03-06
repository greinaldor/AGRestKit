#
# Be sure to run `pod lib lint AGRestKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'AGRestKit'
  s.version          = '0.1.0'
  s.summary          = 'Light and powerful Rest Services framework for iOS.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
                        AGRestKit makes Rest API implementation easy in you iOS project.
                       DESC

  s.homepage         = 'https://github.com/greinaldor/AGRestKit'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Adrien Greiner' => 'adrien@happybodyformula.com' }
  s.source           = { :git => 'https://github.com/greinaldor/AGRestKit.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'AGRestKit/Classes/**/*'
  
  # s.resource_bundles = {
  #   'AGRestKit' => ['AGRestKit/Assets/*.png']
  # }

  s.public_header_files = 'AGRestKit/Classes/**/*.h'

  s.frameworks = 'SystemConfiguration'

  s.dependency 'AFNetworking', '>= 3.0'
  s.dependency 'CocoaLumberjack', '>= 2.0.1'
  s.dependency 'Valet', '>= 2.4.0'
  s.dependency 'Bolts', '>= 1.8.4'
  s.dependency 'OCMapper', '>= 2.1'
end
