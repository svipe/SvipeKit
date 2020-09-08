# Uncomment the next line to define a global platform for your project
platform :ios, '13.0'

# Disable use of input/output files here so that when we build it includes any changes to the development pod
# rather than having to manually clean and rebuuild each time
install! 'cocoapods', :disable_input_output_paths => true

target 'SvipeKit' do
  
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # private
  
  #pod 'SvipeCA', :git => 'https://gitlab.com/svipe/frontend-ios/SvipeCA.git', :branch => :master
  pod 'SvipeCA',  :path => '../SvipeCA'
  
  #pod 'SvipeReader', :git => 'https://gitlab.com/svipe/frontend-ios/SvipeReader.git', :branch => :master
  pod 'SvipeReader',:path => '../SvipeReader'
   
  pod 'FaceVerifier',  :path => '../FaceVerifier'
  #pod 'FaceVerifier', :git => 'https://gitlab.com/svipe/frontend-ios/FaceVerifier.git', :branch => :master
  
  #pod 'SvipeCommon', :git => 'https://gitlab.com/svipe/frontend-ios/SvipeCommon.git', :branch => :master
  pod 'SvipeCommon',  :path => '../SvipeCommon'
   
  #pod 'SvipeMRZ', :git => 'https://gitlab.com/svipe/frontend-ios/SvipeMRZ.git', :branch => :master
  pod 'SvipeMRZ',  :path => '../SvipeMRZ'
  
  pod 'SvipeStore',  :path => '../SvipeStore'#
  #pod 'SvipeStore', :git => 'https://gitlab.com/svipe/frontend-ios/SvipeStore.git', :branch => :master

  # public
  
  #pod 'ASN1Decoder',  :path => '../ASN1Decoder'
  pod 'ASN1Decoder', :git => 'https://github.com/filom/ASN1Decoder', :branch => :master

  #pod 'PotentCodables',  :path => '../PotentCodables/'
  pod 'PotentCodables', :git => 'https://gitlab.com/svipe/frontend-ios/PotentCodables.git', :branch => :master
  #pod 'PotentASN1',  :path => '../PotentCodables/'
  pod 'PotentASN1', :git => 'https://gitlab.com/svipe/frontend-ios/PotentCodables.git', :branch => :master
  #pod 'PotentCBOR',  :path => '../PotentCodables/'
  pod 'PotentCBOR', :git => 'https://gitlab.com/svipe/frontend-ios/PotentCodables.git', :branch => :master
  #pod 'PotentJSON',  :path => '../PotentCodables/'
  pod 'PotentJSON', :git => 'https://gitlab.com/svipe/frontend-ios/PotentCodables.git', :branch => :master
   
  #pod 'Shield',  :path => '../Shield'
  pod 'Shield', :git => 'https://gitlab.com/svipe/frontend-ios/Shield.git', :branch => :master
  #pod 'ShieldCrypto',  :path => '../Shield'
  pod 'ShieldCrypto', :git => 'https://gitlab.com/svipe/frontend-ios/Shield.git', :branch => :master
  #pod 'ShieldSecurity',  :path => '../Shield'
  pod 'ShieldSecurity', :git => 'https://gitlab.com/svipe/frontend-ios/Shield.git', :branch => :master
  #pod 'ShieldPKCS',  :path => '../Shield'
  pod 'ShieldPKCS', :git => 'https://gitlab.com/svipe/frontend-ios/Shield.git', :branch => :master
  #pod 'ShieldX500',  :path => '../Shield'
  pod 'ShieldX500', :git => 'https://gitlab.com/svipe/frontend-ios/Shield.git', :branch => :master
  #pod 'ShieldX509',  :path => '../Shield'
  pod 'ShieldX509', :git => 'https://gitlab.com/svipe/frontend-ios/Shield.git', :branch => :master
  #pod 'ShieldOID',  :path => '../Shield'
  pod 'ShieldOID', :git => 'https://gitlab.com/svipe/frontend-ios/Shield.git', :branch => :master
  #pod 'OrderedDictionary',  :path => '../OrderedDictionary'
  pod 'OrderedDictionary', :git => 'https://gitlab.com/svipe/frontend-ios/OrderedDictionary.git', :branch => :master

  #pod 'SwiftyTesseract' , :path => 'SwiftyTesseract'
  pod 'SwiftyTesseract', :git => 'https://gitlab.com/svipe/frontend-ios/SwiftyTesseract.git', :branch => :master
  
  #pod 'BluetoothKit', :path => '../BluetoothKit'
  pod 'BluetoothKit', :git => 'https://gitlab.com/svipe/frontend-ios/BluetoothKit.git', :branch => :master
  
  # original

  target 'SvipeKitTests' do
    # Pods for testing
  end

  target 'Example' do
    pod 'SvipeKit', :path => '.'
  end

end
