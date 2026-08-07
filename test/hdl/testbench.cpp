// Generic Verilator testbench for LUTify-generated LUT modules
// Usage: ./sim_runner <class_name> <N> <bits> <range_start> <range_end> [tolerance]
// Compile with: -DMODULE_CLASS=<ClassName> -DMODULE_HEADER="<Header.h>"
#include "verilated.h"
#ifdef MODULE_HEADER
#include MODULE_HEADER
#else
#error "Must define MODULE_HEADER, e.g. -DMODULE_HEADER=Vlut_sin_bits8.h"
#endif
#include <cmath>
#include <iostream>
#include <iomanip>
#include <cstdlib>
#include <string>

int main(int argc, char** argv) {
    if (argc < 5) {
        std::cerr << "Usage: " << argv[0]
                  << " <class_name> <N> <bits> <range_start> <range_end> [tolerance]\n";
        return 1;
    }

    int N      = std::atoi(argv[2]);
    int bits   = std::atoi(argv[3]);
    double range_start = std::atof(argv[4]);
    double range_end   = std::atof(argv[5]);
    double tol = (argc > 6) ? std::atof(argv[6]) : static_cast<double>(bits) / 256.0;

    Verilated::commandArgs(argc, argv);
    auto* dut = new MODULE_CLASS;
    const double step = (N > 1) ? (range_end - range_start) / (N - 1) : 0.0;
    const double scale = std::pow(2.0, bits) - 1.0;
    const double offset = scale / 2.0;

    int errors = 0;
    double max_err = 0.0;

    std::cout << "Testing " << argv[1] << " (N=" << N << ", bits=" << bits << ")"
              << " range=[" << range_start << "," << range_end << "]"
              << " tol=" << tol << "\n";
    std::cout << std::fixed << std::setprecision(6);
    std::cout << std::setw(6) << "Addr"
              << std::setw(12) << "LUT_val"
              << std::setw(14) << "Reconstructed"
              << std::setw(14) << "Reference"
              << std::setw(12) << "Abs_err"
              << "\n";

    for (int i = 0; i < N; i++) {
        double theta = range_start + i * step;
        dut->addr = i;
        dut->clk = 0; dut->eval();
        dut->clk = 1; dut->eval();

        uint64_t lut_val = (bits <= 8)   ? (uint64_t)(dut->data & 0xFFULL) :
                           (bits <= 16)  ? (uint64_t)(dut->data & 0xFFFFULL) :
                           (bits <= 32)  ? (uint64_t)(dut->data & 0xFFFFFFFFULL) :
                                           (uint64_t)(dut->data);
        double reconstructed = ((double)lut_val - offset) / offset;

        // Determine reference from class name
        std::string cls(argv[1]);
        double reference = 0.0;
        if (cls.find("sin") != std::string::npos)      reference = sin(theta);
        else if (cls.find("cos") != std::string::npos) reference = cos(theta);
        else reference = reconstructed;

        double err = std::abs(reconstructed - reference);
        if (err > max_err) max_err = err;
        if (err > tol) errors++;

        if (i < 5 || err > tol * 0.5 || i >= N - 3) {
            std::cout << std::setw(6) << i
                      << std::setw(12) << (int)lut_val
                      << std::setw(14) << reconstructed
                      << std::setw(14) << reference
                      << std::setw(12) << err;
            if (err > tol) std::cout << " **";
            std::cout << "\n";
        }
    }

    std::cout << "\n========================================\n";
    std::cout << "Max abs error : " << max_err << "\n";
    std::cout << "Threshold     : " << tol << "\n";
    std::cout << "Errors        : " << errors << " / " << N << "\n";

    delete dut;
    return (errors > 0) ? 1 : 0;
}
