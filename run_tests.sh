#!/bin/bash

xcodebuild test -project "Mimus.xcodeproj" -scheme "Mimus" -destination "name=iPad Air,OS=10.2" | xcpretty --test
