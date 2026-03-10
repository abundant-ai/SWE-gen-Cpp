#!/bin/bash

cd /app/src

# Copy HEAD test files from /tests (overwrites BASE state)
mkdir -p "modules/core/test"
cp "/tests/modules/core/test/test_logtagmanager.cpp" "modules/core/test/test_logtagmanager.cpp"

checks_passed=0
checks_failed=0

# Check 1: logtag.hpp should NOT have constexpr LogTag constructor (fixed version removes constexpr)
if grep -q 'inline LogTag(const char\* _name, LogLevel _level)' modules/core/include/opencv2/core/utils/logtag.hpp && \
   ! grep -q 'inline constexpr LogTag(const char\* _name, LogLevel _level)' modules/core/include/opencv2/core/utils/logtag.hpp; then
    echo "PASS: logtag.hpp has non-constexpr LogTag constructor (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: logtag.hpp has constexpr LogTag constructor (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 2: logger.cpp should NOT have constexpr m_isDebugBuild (fixed version removes constexpr)
if grep -q 'static const bool m_isDebugBuild' modules/core/src/logger.cpp && \
   ! grep -q 'static constexpr bool m_isDebugBuild' modules/core/src/logger.cpp; then
    echo "PASS: logger.cpp has non-constexpr m_isDebugBuild (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: logger.cpp has constexpr m_isDebugBuild (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 3: logger.cpp should NOT have constexpr m_defaultUnconfiguredGlobalLevel (fixed version)
if ! grep -q 'static constexpr LogLevel m_defaultUnconfiguredGlobalLevel' modules/core/src/logger.cpp; then
    echo "PASS: logger.cpp does not have constexpr m_defaultUnconfiguredGlobalLevel (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: logger.cpp has constexpr m_defaultUnconfiguredGlobalLevel (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 4: logger.cpp should have out-of-class definition of m_defaultUnconfiguredGlobalLevel (fixed version)
if grep -q 'LogLevel GlobalLoggingInitStruct::m_defaultUnconfiguredGlobalLevel' modules/core/src/logger.cpp; then
    echo "PASS: logger.cpp has out-of-class m_defaultUnconfiguredGlobalLevel (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: logger.cpp missing out-of-class m_defaultUnconfiguredGlobalLevel (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 5: logtagconfigparser.cpp should NOT have constexpr npos (fixed version)
if grep -q 'const size_t npos = std::string::npos;' modules/core/src/utils/logtagconfigparser.cpp && \
   ! grep -q 'constexpr size_t npos = std::string::npos;' modules/core/src/utils/logtagconfigparser.cpp; then
    echo "PASS: logtagconfigparser.cpp has non-constexpr npos (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: logtagconfigparser.cpp has constexpr npos (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 6: logtagmanager.cpp should have out-of-class definition of m_globalName (fixed version)
if grep -q 'const char\* LogTagManager::m_globalName' modules/core/src/utils/logtagmanager.cpp; then
    echo "PASS: logtagmanager.cpp has out-of-class m_globalName (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: logtagmanager.cpp missing out-of-class m_globalName (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 7: logtagmanager.hpp should NOT have constexpr m_globalName (fixed version)
if grep -q 'static const char\* m_globalName;' modules/core/src/utils/logtagmanager.hpp && \
   ! grep -q 'static constexpr const char\* m_globalName = "global";' modules/core/src/utils/logtagmanager.hpp; then
    echo "PASS: logtagmanager.hpp has non-constexpr m_globalName (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: logtagmanager.hpp has constexpr m_globalName (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 8: test_logtagmanager.cpp should NOT have constexpr test level constants (fixed version)
if grep -q 'static const LogLevel constTestLevelBegin' modules/core/test/test_logtagmanager.cpp && \
   ! grep -q 'static constexpr const LogLevel constTestLevelBegin' modules/core/test/test_logtagmanager.cpp; then
    echo "PASS: test_logtagmanager.cpp has non-constexpr test level constants (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_logtagmanager.cpp has constexpr test level constants (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 9: test_logtagmanager.cpp should NOT have constexpr m_globalTagName in class (fixed version)
if ! grep -q 'static constexpr const char\* m_globalTagName = "global";' modules/core/test/test_logtagmanager.cpp; then
    echo "PASS: test_logtagmanager.cpp does not have constexpr m_globalTagName (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_logtagmanager.cpp has constexpr m_globalTagName (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

# Check 10: test_logtagmanager.cpp should have out-of-class m_globalTagName definition (fixed version)
if grep -q 'const char\* const LogTagManagerGlobalSmokeTest::m_globalTagName' modules/core/test/test_logtagmanager.cpp; then
    echo "PASS: test_logtagmanager.cpp has out-of-class m_globalTagName (fixed version)"
    checks_passed=$((checks_passed + 1))
else
    echo "FAIL: test_logtagmanager.cpp missing out-of-class m_globalTagName (buggy version)" >&2
    checks_failed=$((checks_failed + 1))
fi

echo "Checks passed: $checks_passed, Checks failed: $checks_failed"

if [ $checks_failed -eq 0 ]; then
    test_status=0
else
    test_status=1
fi

if [ $test_status -eq 0 ]; then
  echo 1 > /logs/verifier/reward.txt
else
  echo 0 > /logs/verifier/reward.txt
fi
exit "$test_status"
