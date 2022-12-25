.PHONY: fastlane

fastlane:
	bundle exec fastlane beta

renew_certs:
	bundle exec fastlane match nuke development
	bundle exec fastlane match nuke distribution
	bundle exec fastlane match nuke enterprise

get_certs:
	bundle exec fastlane match appstore
	bundle exec fastlane match development
