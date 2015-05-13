
#ifndef _FPGA_INTERFACE_H
#define _FPGA_INTERFACE_H

#include "Seti_LabView.h"
#include "fftw3.h"
#include <iostream>
#include <exception>
#include <sstream>

class FpgaInterface
{
public:
	FpgaInterface()
	{
		try {
				InitFpga();
		}
		catch (std::exception& ex) {
				int i=9;
		}
	}

	void PerformFft(int fftlen, fftwf_complex* inData, fftwf_complex* outData)
	{
		cmplx64* cIn = new cmplx64[fftlen];
		cmplx64* cOut = new cmplx64[fftlen];
		for (int i=0; i < fftlen; i++)
		{
			cIn[i].re = inData[i][0];
			cIn[i].im = inData[i][1];
		}
		int res = CalcData(cIn, cOut, fftlen, fftlen);
		if (res != 0) {
			std::stringstream exceptionMessage;
			exceptionMessage << "ERROR in CalcFpga().  " << res << "\n";
			throw std::exception(exceptionMessage.str().c_str());
		}
		for (int i=0; i<fftlen; i++)
		{
			outData[i][0] = cOut[i].re;
			outData[i][1] = cOut[i].im;
		}
	}

	void CleanUpFpga()
	{
		int res = CloseFpga();
		if (res != 0) {
			std::stringstream exceptionMessage;
			exceptionMessage << "ERROR in CloseFpga().  " << res << "\n";
			throw std::exception(exceptionMessage.str().c_str());
		}
	}
private:
	void InitFpga()
	{
		NiFpgaViExecutionMode exeModeOut;
		int res = InitializeFpga(&exeModeOut);
		if (res != 0) {
			std::stringstream exceptionMessage;
			exceptionMessage << "ERROR in InitFpga().  " << res << "\n";
			throw std::exception(exceptionMessage.str().c_str());
		}
	}
};

//typedef float sah_complex[2];
//
//class FpgaInterface
//{
//public:
//	FpgaInterface()
//	{
//	}
//
//	// Load the NI Drivers and make sure a good/valid connection 
//	// is made to the FPGA
//	int initializeFft(
//						unsigned long bitfield,
//						unsigned long ac_fft_len
//					);
//
//	int setInitialData(
//	  					sah_complex* ChirpedData,
//						int NumDataPoints,
//						int FftNum,
//						int fftlen
//					  );
//
//	void runAnalysis();
//	void compareResults(float *PowerSpectrum);
//
//private:
//	fftwf_plan analysis_plans[MAX_NUM_FFTS];
//	fftwf_plan autocorr_plan;
//
//	sah_complex* ChirpedData_;
//	sah_complex* WorkData_;
//	float* PowerSpectrum_;
//
//	int analysis_fft_lengths[32];
//
//	int NumDataPoints_;
//	int NumFfts_;
//	int FftNum_;
//	int fftlen_;
//};

#endif
