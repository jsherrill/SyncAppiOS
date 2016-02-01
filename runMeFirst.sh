#!/bin/bash

echo "Installing CocoaPods."
sudo gem install cocoapods -V

echo "Initializing Pods."
pod init

echo "Creating Pods."
pod install

echo "Done. Use the .xcworkspace file to open your project from now on."


