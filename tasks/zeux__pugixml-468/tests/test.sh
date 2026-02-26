#!/bin/bash

cd /app/src

# Verify VS2022 support was added to build configuration files
echo "Verifying VS2022 support in configuration files..."

# Check appveyor.yml has VS2022 test configuration
if grep -q "autotest-appveyor.ps1 22" appveyor.yml; then
    echo "✓ appveyor.yml has VS2022 test configuration"
    test_status=0
else
    echo "✗ appveyor.yml missing VS2022 test configuration"
    test_status=1
fi

# Check nuget_build.ps1 has VS2022 build logic
if [ $test_status -eq 0 ]; then
    if grep -q "if (\$args\[0\] -eq 2022)" scripts/nuget_build.ps1; then
        echo "✓ nuget_build.ps1 has VS2022 build logic"
    else
        echo "✗ nuget_build.ps1 missing VS2022 build logic"
        test_status=1
    fi
fi

# Check VS2022 project file exists
if [ $test_status -eq 0 ]; then
    if [ -f "scripts/pugixml_vs2022.vcxproj" ]; then
        echo "✓ VS2022 project file exists"
    else
        echo "✗ VS2022 project file missing"
        test_status=1
    fi
fi

if [ $test_status -eq 0 ]; then
    echo "All VS2022 support checks passed!"
else
    echo "VS2022 support verification failed"
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
