#include "benchmark/benchmark.h"
#include <iostream>

int main() {
  // Try to create a default display reporter
  benchmark::BenchmarkReporter* reporter = benchmark::CreateDefaultDisplayReporter();

  if (reporter == nullptr) {
    std::cerr << "CreateDefaultDisplayReporter() returned nullptr" << std::endl;
    return 1;
  }

  std::cout << "CreateDefaultDisplayReporter() succeeded" << std::endl;
  return 0;
}
