#!/usr/bin/env ruby
# Programmatically adds the ThicketWidgetExtension target to Runner.xcodeproj.
#
# This exists because creating a Widget Extension target is normally done via
# Xcode's "New Target" GUI wizard - there's no Mac in this project's dev loop
# to do that by hand, so this runs as a Codemagic build step instead (using
# the `xcodeproj` gem, which ships alongside CocoaPods and is what CocoaPods
# itself uses internally to edit Xcode projects). Idempotent: safe to run on
# every build - skips target creation if it already exists.

require 'xcodeproj'

project_path = File.expand_path('../Runner.xcodeproj', __dir__)
project = Xcodeproj::Project.open(project_path)

WIDGET_TARGET_NAME = 'ThicketWidgetExtension'
WIDGET_BUNDLE_ID = 'com.austinphillips.thicket.widget'
APP_GROUP_ID = 'group.com.austinphillips.thicket'
WIDGET_DEPLOYMENT_TARGET = '17.0'

runner_target = project.targets.find { |t| t.name == 'Runner' }
raise "Runner target not found in #{project_path}" if runner_target.nil?

# --- Give Runner its entitlements file (App Group) ---
runner_target.build_configurations.each do |config|
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
end

if project.targets.any? { |t| t.name == WIDGET_TARGET_NAME }
  puts "#{WIDGET_TARGET_NAME} already exists - skipping creation, entitlements updated."
  project.save
  exit 0
end

# --- Create the widget extension target ---
widget_target = project.new_target(
  :app_extension,
  WIDGET_TARGET_NAME,
  :ios,
  WIDGET_DEPLOYMENT_TARGET
)

widget_group = project.main_group.new_group('ThicketWidget', 'ThicketWidget')

swift_file_ref = widget_group.new_file('ThicketWidget.swift')
widget_target.source_build_phase.add_file_reference(swift_file_ref)

info_plist_ref = widget_group.new_file('Info.plist')
entitlements_ref = widget_group.new_file('ThicketWidgetExtension.entitlements')

widget_target.frameworks_build_phase.add_file_reference(
  project.frameworks_group.new_file('System/Library/Frameworks/WidgetKit.framework')
)
widget_target.frameworks_build_phase.add_file_reference(
  project.frameworks_group.new_file('System/Library/Frameworks/SwiftUI.framework')
)

widget_target.build_configurations.each do |config|
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = WIDGET_BUNDLE_ID
  config.build_settings['INFOPLIST_FILE'] = 'ThicketWidget/Info.plist'
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'ThicketWidget/ThicketWidgetExtension.entitlements'
  config.build_settings['SWIFT_VERSION'] = '5.0'
  config.build_settings['TARGETED_DEVICE_FAMILY'] = '1,2'
  config.build_settings['SKIP_INSTALL'] = 'YES'
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = WIDGET_DEPLOYMENT_TARGET
  config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
end

# --- Embed the widget extension into Runner ---
embed_phase = runner_target.new_copy_files_build_phase('Embed Foundation Extensions')
embed_phase.symbol_dst_subfolder_spec = :plug_ins
embed_phase.add_file_reference(widget_target.product_reference)
runner_target.add_dependency(widget_target)

project.save
puts "Added #{WIDGET_TARGET_NAME} (bundle id #{WIDGET_BUNDLE_ID}) and embedded it into Runner."
