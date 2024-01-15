# Install in the main application target using: pod 'EarlGreyApp'
Pod::Spec.new do |s|

  s.name = "EarlGreyApp"
  s.version = "2.2.40"
  s.summary = "iOS UI Automation Test Framework"
  s.homepage = "https://github.com/google/EarlGrey"
  s.author = "Google LLC."
  s.summary = 'EarlGrey is a native iOS UI automation test framework that enables you to write clear, concise tests.'
  s.license = { :type => "Apache 2.0", :file => "LICENSE" }

  s.source = { :git => "https://github.com/ivan-delivery/EarlGrey-PoC.git", :tag => "#{s.version}" }
  s.vendored_frameworks = "AppFramework.xcframework"

  s.pod_target_xcconfig = { "FRAMEWORK_SEARCH_PATHS" =>"$(inherited) $(PLATFORM_DIR)/Developer/Library/Frameworks",
                            "ENABLE_BITCODE" => "NO" }

  s.platform = :ios, '13.0'
end
