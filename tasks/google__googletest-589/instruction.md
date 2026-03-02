Building Google Mock using autotools is currently broken when Google Mock is used from this repository layout (where Google Test is a sibling project rather than being present under a googlemock/gtest directory).

When running the standard autotools bootstrap/configure flow for Google Mock (e.g., invoking aclocal/autoreconf and then ./configure in the Google Mock project), the build fails early with:

aclocal: error: configure.ac:1: file 'gtest/m4/acx_pthread.m4' does not exist

If that missing m4 macro is worked around manually, additional failures occur because the autotools files assume a gtest directory exists under the Google Mock tree. As a result, users can only get autotools to succeed by creating a manual workaround such as symlinking googlemock/gtest to the sibling googletest directory.

Google Mock’s autotools build should work out of the box in this repository without requiring users to create symlinks or copy directories. The autotools configuration must be able to locate the pthread/autoconf macros and the necessary Google Test sources/headers when Google Test is provided in the repository’s intended layout. After the fix, the usual autoreconf/aclocal + ./configure + make flow for Google Mock should complete successfully and produce a working Google Mock library that can compile and run basic Google Mock usage (including code that includes both <gmock/gmock.h> and <gtest/gtest.h> and calls InitGoogleMock).