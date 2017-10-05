#!/bin/bash

xcodebuild test -project "Mimus.xcodeproj" -scheme "Mimus" -destination "name=iPad Air" | xcpretty --test
