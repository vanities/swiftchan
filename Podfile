source 'https://github.com/CocoaPods/Specs.git'

target 'swiftchan' do
  platform :ios, '14.3'
  pod 'MobileVLCKit', '3.3.16.3'
  pod 'SwiftLint'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
    end
  end
end
