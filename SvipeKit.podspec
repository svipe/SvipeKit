Pod::Spec.new do |s|
  s.name     = 'SvipeKit'
  s.version  = '0.0.1'
  s.license  = 'All Rights Reserved'
  s.summary  = 'Svipe ID Kit'
  s.homepage = 'https://gitlab.com/svipe/frontend-ios/SvipeKit'
  s.author   = 'Svipe AB'
  s.source   = { :git => 'https://gitlab.com/svipe/frontend-ios/SvipeKit.git', :tag => s.version }
  s.requires_arc = true
  s.source_files = 'SvipeKit/**/*.{h,m,swift,mlmodel}'
  s.resources = "SvipeKit/**/*.{storyboard,xib,xcassets,strings,json,xml,pem,traineddata}"
  s.ios.deployment_target = '13.0'
  s.dependency 'DeepLinkKit'
  s.dependency 'FaceVerifier'
  s.dependency 'SvipeMRZ'
  s.dependency 'SvipeReader'
  s.dependency 'SvipeStore'
  s.dependency 'SvipeCommon'
  s.dependency 'PromiseKit'
  s.dependency 'SvipeCA'
end
