/*
 * Generated with the FPGA Interface C API Generator 14.0.0
 * for NI-RIO 14.0.0 or later.
 */

#ifndef __NiFpga_Fft16_h__
#define __NiFpga_Fft16_h__

#ifndef NiFpga_Version
   #define NiFpga_Version 1400
#endif

#include "NiFpga.h"

/**
 * The filename of the FPGA bitfile.
 *
 * This is a #define to allow for string literal concatenation. For example:
 *
 *    static const char* const Bitfile = "C:\\" NiFpga_Fft16_Bitfile;
 */
#define NiFpga_Fft16_Bitfile "NiFpga_Fft16.lvbitx"

/**
 * The signature of the FPGA bitfile.
 */
static const char* const NiFpga_Fft16_Signature = "3D349A2E0DE6486EE11C682663682B9B";

typedef enum
{
   NiFpga_Fft16_IndicatorBool_outputvalid = 0x8002,
} NiFpga_Fft16_IndicatorBool;

typedef enum
{
   NiFpga_Fft16_TargetToHostFifoU64_FPGAtoHost = 1,
} NiFpga_Fft16_TargetToHostFifoU64;

typedef enum
{
   NiFpga_Fft16_HostToTargetFifoU64_HosttoFPGA = 0,
} NiFpga_Fft16_HostToTargetFifoU64;

#endif
