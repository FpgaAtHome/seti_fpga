
#ifndef _FPGA_INTERFACE_H_
#define _FPGA_INTERFACE_H_

#include "fftw3.h"

#define MAX_NUM_FFTS 64
#define USA_FPGA

typedef float sah_complex[2];

class FpgaInterface
{
public:
	FpgaInterface()
	{
	}

	// Load the NI Drivers and make sure a good/valid connection 
	// is made to the FPGA
	int initializeFft(
						unsigned long bitfield,
						unsigned long ac_fft_len
					);

	int setInitialData(
	  					sah_complex* ChirpedData,
						int NumDataPoints,
						int FftNum,
						int fftlen
					  );

	void runAnalysis();
	void compareResults(float *PowerSpectrum);

private:
	fftwf_plan analysis_plans[MAX_NUM_FFTS];
	fftwf_plan autocorr_plan;

	sah_complex* ChirpedData_;
	sah_complex* WorkData_;
	float* PowerSpectrum_;

	int analysis_fft_lengths[32];

	int NumDataPoints_;
	int NumFfts_;
	int FftNum_;
	int fftlen_;
};
#endif
