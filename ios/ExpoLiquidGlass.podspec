require 'json'

package = JSON.parse(File.read(File.join(__dir__, '..', 'package.json')))

Pod::Spec.new do |s|
  s.name           = 'ExpoLiquidGlass'
  s.version        = package['version']
  s.summary        = package['description']
  s.description    = package['description']
  s.license        = package['license']
  s.author         = package['author']
  s.homepage       = package['homepage']
  s.platforms      = {
    :ios => '15.1',
    :tvos => '15.1'
  }
  s.swift_version  = '5.4'
  s.source         = { git: 'https://github.com/rit3zh/expo-liquid-glass' }
  s.static_framework = true

  s.dependency 'ExpoModulesCore'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
  }

  s.source_files = "**/*.{h,m,mm,swift,hpp,cpp,metal}"

  s.resource_bundles = {
    'ExpoLiquidGlassShaders' => ['Shaders/bundle-marker.txt']
  }

  s.script_phases = [
    {
      :name => 'Bundle compiled Metal shaders',
      :execution_position => :after_compile,
      :shell_path => '/bin/sh',
      :script => <<-SCRIPT.gsub(/^ {8}/, '')
        set -e

        METALLIB="${TARGET_BUILD_DIR}/default.metallib"
        BUNDLE="${TARGET_BUILD_DIR}/ExpoLiquidGlassShaders.bundle"

        if [ ! -f "$METALLIB" ]; then
          echo "error: default.metallib not found at $METALLIB - were the .metal files compiled?"
          exit 1
        fi

        if [ ! -d "$BUNDLE" ]; then
          echo "error: ExpoLiquidGlassShaders.bundle not found at $BUNDLE"
          exit 1
        fi

        cp "$METALLIB" "$BUNDLE/default.metallib"
      SCRIPT
    }
  ]
end
