#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "tests"
cp "/tests/autotest-appveyor.ps1" "tests/autotest-appveyor.ps1"

# This PR is about adding VS2019 support to the NuGet build process
# The test verifies that VS2019 project files exist and the build scripts reference VS2019

# Check that VS2019 project files exist
if [ ! -f "scripts/pugixml_vs2019.vcxproj" ]; then
  echo "FAIL: VS2019 project file (pugixml_vs2019.vcxproj) does not exist"
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

if [ ! -f "scripts/pugixml_vs2019_static.vcxproj" ]; then
  echo "FAIL: VS2019 static project file (pugixml_vs2019_static.vcxproj) does not exist"
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

# Check that appveyor.yml references VS2019
if ! grep -q "Visual Studio 2019" appveyor.yml; then
  echo "FAIL: appveyor.yml does not reference Visual Studio 2019"
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

# Check that nuget_build.ps1 supports 2019 argument
if ! grep -q '2019' scripts/nuget_build.ps1; then
  echo "FAIL: nuget_build.ps1 does not support 2019"
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

# Check that autotest-appveyor.ps1 supports VS 19
if ! grep -q 'vs -eq 19' tests/autotest-appveyor.ps1; then
  echo "FAIL: autotest-appveyor.ps1 does not test VS 19"
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

# Check that nuspec mentions VS2019
if ! grep -q 'VS2019' scripts/nuget/pugixml.nuspec; then
  echo "FAIL: pugixml.nuspec does not mention VS2019"
  echo 0 > /logs/verifier/reward.txt
  exit 1
fi

echo "PASS: All VS2019 support checks passed"
echo 1 > /logs/verifier/reward.txt
exit 0
