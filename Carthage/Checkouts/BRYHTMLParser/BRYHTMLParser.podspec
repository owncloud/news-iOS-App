Pod::Spec.new do |s|
  s.name         = 'BRYHTMLParser'
  s.authors      = 'Bryan Irace'
  s.license      = 'MIT'
  s.platform     = :ios
  s.homepage     = 'https://github.com/irace/BRYHTMLParser'
  s.version      = '2.1.3'
  s.summary      = 'An Objective-C wrapper around libxml for parsing HTML.'
  s.source       = { :git => 'https://github.com/irace/BRYHTMLParser.git', :tag => "#{s.version}" }
  s.source_files = 'BRYHTMLParser/*.{h,m}'
  s.libraries    = 'xml2'
  s.xcconfig     = { 'HEADER_SEARCH_PATHS' => '$(SDKROOT)/usr/include/libxml2' }
  s.frameworks   = 'Foundation'
  s.requires_arc = true
end
