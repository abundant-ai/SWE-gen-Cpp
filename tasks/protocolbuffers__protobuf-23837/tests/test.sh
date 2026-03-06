#!/bin/bash

cd /app/src

# Set environment variables for tests
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export DOTNET_SKIP_FIRST_TIME_EXPERIENCE=true
export CI=true

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "csharp/src/Google.Protobuf.Test"
cp "/tests/csharp/src/Google.Protobuf.Test/JsonParserTest.cs" "csharp/src/Google.Protobuf.Test/JsonParserTest.cs"

# Rebuild C# project to pick up the updated test file
cd csharp
dotnet build -c Release src/Google.Protobuf.sln

# Run only the JsonParserTest tests using dotnet test with filter
# Filter by FullyQualifiedName to run only tests in JsonParserTest class
dotnet test -c Release -f net6.0 src/Google.Protobuf.Test/Google.Protobuf.Test.csproj --filter "FullyQualifiedName~Google.Protobuf.JsonParserTest"
test_status=$?

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
