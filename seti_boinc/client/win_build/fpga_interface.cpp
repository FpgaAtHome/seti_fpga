
#include "fpga_interface.h"

#define MAX_NUM_FFTS 64


int FpgaInterface::initializeFpga(
				unsigned long bitfield
				)
{
	while (bitfield != 0) {
		if (bitfield & 1) {
			swi.analysis_fft_lengths[FftNum]=FftLen;

			WorkData = (sah_complex *)malloc_a(FftLen * sizeof(sah_complex),MEM_ALIGN);
			sah_complex *scratch=(sah_complex *)malloc_a(FftLen*sizeof(sah_complex),MEM_ALIGN);
			if ((WorkData == NULL) || (scratch==NULL)) {
				SETIERROR(MALLOC_FAILED, "WorkData == NULL || scratch == NULL");
			}

			fprintf(stderr, "\nplan_dft_1d(Fftlen=%d", FftLen);
			analysis_plans[FftNum] = fftwf_plan_dft_1d(FftLen, scratch, WorkData, FFTW_BACKWARD, FFTW_MEASURE_OR_ESTIMATE|FFTW_PRESERVE_INPUT);

			FftNum++;
			free_a(scratch);
			free_a(WorkData);
		}
		FftLen*=2;
		bitfield>>=1;
	}

//	fftwf_plan analysis_plans[MAX_NUM_FFTS];
//   fftwf_plan autocorr_plan;

	// use bitfield to generate all plans
	// lines 299-341

	// Allocate WorkData
	return 0;
}

int FpgaInterface::setInitialData(
	  				sah_complex* DataIn, int NumDataPoints
								  )
{
	return 0;
}

void FpgaInterface::runAnalysis()
{
}
void FpgaInterface::compareResults(float *PowerSpectrum)
{
}