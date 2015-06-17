Pod::Spec.new do |s|
  s.name         = "NOAPIController"
  s.version      = "0.0.1"
  s.summary      = "API controller with JSON to Objective-C objects mapping."
  s.homepage     = "https://github.com/noveogroup/NOAPIController"
  s.license      = "MIT"
  s.author       = "Alexander Gorbunov"
  s.platform     = :ios
  s.source       = { :git => "https://github.com/noveogroup/NOAPIController.git", :tag => s.version }
  s.requires_arc = true
  s.source_files  = "NOAPIController/NOAPIController.h"
  s.public_header_files = "NOAPIController/*.h"

end
