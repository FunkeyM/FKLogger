#
#  FKLogger.podspec
#  FKLogger
#
#  Created by Bobby on 2026/3/24.
#

Pod::Spec.new do |s|
  s.name             = 'FKLogger'
  s.version          = '1.0.0'
  s.summary          = 'A lightweight logging and crash management library for iOS.'
  s.description      = <<-DESC
FKLogger is a lightweight logging library with crash detection and management capabilities.
It supports both Objective-C and Swift, providing easy-to-use logging functions and crash handlers.
                       DESC

  s.homepage         = 'https://github.com/FunkeyM/FKLogger'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Bobby' => 'liyoxing@126.com' }
  s.source           = { :git => 'https://github.com/FunkeyM/FKLogger.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13.0'
  s.swift_version = '5.0'

  s.requires_arc = true

  # 源文件
  s.source_files = 'FKLogger/FKLogger/Logger/**/*.{h,m,swift}',
                    'FKLogger/FKLogger/CrashManager/**/*.{h,m,swift}'

  # 公开头文件
  s.public_header_files = 'FKLogger/FKLogger/Logger/FKLoggerHeader.h',
                          'FKLogger/FKLogger/CrashManager/CrashManager.h'

  # 依赖
  s.dependency 'CocoaLumberjack/Swift', '~> 3.8'
  s.dependency 'SSZipArchive', '~> 2.4'

  # 子模块（可选，便于按需引入）
  s.subspec 'Logger' do |logger|
    logger.source_files = 'FKLogger/FKLogger/Logger/**/*.{h,m,swift}'
    logger.public_header_files = 'FKLogger/FKLogger/Logger/FKLoggerHeader.h'
    logger.dependency 'CocoaLumberjack/Swift', '~> 3.8'
    logger.dependency 'SSZipArchive', '~> 2.4'
  end

  s.subspec 'CrashManager' do |crash|
    crash.source_files = 'FKLogger/FKLogger/CrashManager/**/*.{h,m,swift}'
    crash.public_header_files = 'FKLogger/FKLogger/CrashManager/CrashManager.h'
  end

end
