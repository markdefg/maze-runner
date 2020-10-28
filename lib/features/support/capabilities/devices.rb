# frozen_string_literal: true

# Provides a source of capabilities used to run tests against specific BrowserStack devices
# noinspection RubyStringKeysInHashInspection
class Devices
  APPIUM_1_6_5 = '1.6.5'
  APPIUM_1_7_2 = '1.7.2'
  APPIUM_1_8_0 = '1.8.0'

  class << self

    def make_android_hash(device, version, appium_version)
      {
        'device' => device,
        'os_version' => version,
        'autoGrantPermissions' => 'true',
        'platformName' => 'Android',
        'os' => 'android',
        'browserstack.appium_version' => appium_version
      }.freeze
    end

    def add_android(device, version, appium_version, hash)
      # Key format is "ANDROID_<version>_<device>", with:
      # - dots in versions and all spaces replaced with underscores
      # - device made upper case
      name = device.upcase.gsub ' ', '_'
      new_version = version.gsub '.', '_'
      key = "ANDROID_#{new_version}_#{name}"
      hash[key] = make_android_hash device, version, appium_version
    end

    def make_ios_hash(device, version)
      {
        'device' => device,
        'os_version' => version,
        'platformName' => 'iOS',
        'os' => 'ios'
      }.freeze
    end

    def create_hash
      hash = {
        # Classic, non-specific devices for each Android version
        'ANDROID_11_0' => make_android_hash('Google Pixel 4', '11.0', APPIUM_1_8_0),
        'ANDROID_10_0' => make_android_hash('Google Pixel 4', '10.0', APPIUM_1_8_0),
        'ANDROID_9_0' => make_android_hash('Google Pixel 3', '9.0', APPIUM_1_8_0),
        'ANDROID_8_1' => make_android_hash('Samsung Galaxy Note 9', '8.1', APPIUM_1_7_2),
        'ANDROID_8_0' => make_android_hash('Google Pixel 2', '8.0', APPIUM_1_7_2),
        'ANDROID_7_1' => make_android_hash('Google Pixel', '7.1', APPIUM_1_6_5),
        'ANDROID_6_0' => make_android_hash('Google Nexus 6', '6.0', APPIUM_1_6_5),
        'ANDROID_5_0' => make_android_hash('Google Nexus 6', '5.0', APPIUM_1_6_5),
        'ANDROID_4_4' => make_android_hash('Google Nexus 5', '4.4', APPIUM_1_6_5),

        # iOS devices
        'IOS_14' => make_ios_hash('iPhone 11', '14'),
        'IOS_13' => make_ios_hash('iPhone 8', '13'),
        'IOS_12' => make_ios_hash('iPhone 8', '12'),
        'IOS_11' => make_ios_hash('iPhone 8', '11'),
        'IOS_10' => make_ios_hash('iPhone 7', '10')
      }
      # Deprecated entries
      hash['ANDROID_9'] = hash['ANDROID_9_0']
      hash['ANDROID_8'] = hash['ANDROID_8_0']
      hash['ANDROID_7'] = hash['ANDROID_7_1']
      hash['ANDROID_6'] = hash['ANDROID_6_0']
      hash['ANDROID_5'] = hash['ANDROID_5_0']
      hash['ANDROID_4'] = hash['ANDROID_4_4']

      # Specific Android devices
      add_android 'Google Pixel 4', '11.0', APPIUM_1_8_0, hash          # ANDROID_11_0_GOOGLE_PIXEL_4
      add_android 'Samsung Galaxy Note 9', '8.1', APPIUM_1_7_2, hash    # ANDROID_8_1_SAMSUNG_GALAXY_NOTE_9
      add_android 'Samsung Galaxy J7 Prime', '8.1', APPIUM_1_7_2, hash  # ANDROID_8_1_SAMSUNG_GALAXY_J7_PRIME
      add_android 'Samsung Galaxy Tab S4', '8.1', APPIUM_1_7_2, hash    # ANDROID_8_1_SAMSUNG_GALAXY_TAB_S4
      add_android 'Google Pixel', '8.0', APPIUM_1_7_2, hash             # ANDROID_8_0_GOOGLE_PIXEL
      add_android 'Google Pixel 2', '8.0', APPIUM_1_7_2, hash           # ANDROID_8_0_GOOGLE_PIXEL_2
      add_android 'Samsung Galaxy S9', '8.0', APPIUM_1_7_2, hash        # ANDROID_8_0_SAMSUNG_GALAXY_S9
      add_android 'Samsung Galaxy S9 Plus', '8.0', APPIUM_1_7_2, hash   # ANDROID_8_0_SAMSUNG_GALAXY_S9_PLUS
      add_android 'Samsung Galaxy Tab S3', '7.0', APPIUM_1_6_5, hash    # ANDROID_7_0_SAMSUNG_GALAXY_TAB_S3
      add_android 'Motorola Moto X 2nd Gen', '6.0', APPIUM_1_6_5, hash  # ANDROID_6_0_MOTOROLA_MOTO_X_2ND_GEN
      add_android 'Google Nexus 6', '6.0', APPIUM_1_6_5, hash           # ANDROID_6_0_GOOGLE_NEXUS_6
      add_android 'Samsung Galaxy S7', '6.0', APPIUM_1_6_5, hash        # ANDROID_6_0_SAMSUNG_GALAXY_S7

      hash
    end
  end

  # The hash of device capabilities, accessible by simple names
  DEVICE_HASH ||= create_hash
end
