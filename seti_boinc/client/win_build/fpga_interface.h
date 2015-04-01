
#ifndef _FPGA_INTERFACE_H_
#define _FPGA_INTERFACE_H_

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
	int initializeFpga(
						unsigned long bitfield
								);

	int setInitialData(
	  					sah_complex* DataIn,
						int NumDataPoints
								  );

	void runAnalysis();
	void compareResults(float *PowerSpectrum);

private:
	fftwf_plan analysis_plans[MAX_NUM_FFTS];
	sah_complex* DataIn_;
};
#endif
