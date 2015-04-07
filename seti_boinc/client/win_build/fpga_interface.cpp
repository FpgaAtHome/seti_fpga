
#include "fpga_interface.h"

#include "malloc_a.h"
#define FFTW_MEASURE_OR_ESTIMATE ((app_init_data.host_info.m_nbytes >= MIN_TRANSPOSE_MEMORY)?FFTW_MEASURE:FFTW_ESTIMATE)


int GetPowerSpectrum(
    sah_complex* FreqData,
    float* PowerSpectrum,
    int NumDataPoints) 
{
    int i;

    //analysis_state.FLOP_counter+=3.0*NumDataPoints;
    for (i = 0; i < NumDataPoints; i++) {
        PowerSpectrum[i] = FreqData[i][0] * FreqData[i][0]
                           + FreqData[i][1] * FreqData[i][1];
    }
    return 0;
}


int FpgaInterface::initializeFft(
				unsigned long bitfield,
				unsigned long ac_fft_len
				)
{
	int analysis_fft_lengths[32];
	// These two variables always have the following values
	// at this point
	unsigned long FftLen = 1;
	int FftNum = 0;

//#define FFTW_MEASURE_OR_ESTIMATE ((app_init_data.host_info.m_nbytes >= MIN_TRANSPOSE_MEMORY)?FFTW_MEASURE:FFTW_ESTIMATE)

	sah_complex* WorkData = NULL;

	// Set up DFFT plans
	while (bitfield != 0) {
		if (bitfield & 1) {
			analysis_fft_lengths[FftNum] = FftLen;
			WorkData             = (sah_complex *)malloc_a(FftLen * sizeof(sah_complex), MEM_ALIGN);
			sah_complex *scratch = (sah_complex *)malloc_a(FftLen * sizeof(sah_complex), MEM_ALIGN);
			if ((WorkData == NULL) || (scratch==NULL)) {
				// Trap this error - not enough memory
			}

			fprintf(stderr, "\nFpgaInterface::initializeFpga \t plan_dft_1d(Fftlen=%d", FftLen);
			analysis_plans[FftNum] = fftwf_plan_dft_1d(FftLen, scratch, WorkData,
										FFTW_BACKWARD,
										FFTW_MEASURE|FFTW_PRESERVE_INPUT);
//										FFTW_MEASURE_OR_ESTIMATE|FFTW_PRESERVE_INPUT);
/*
			fprintf(stderr, "\nplan_dft_1d(Fftlen=%d", FftLen);
			analysis_plans[FftNum] = fftwf_plan_dft_1d(
									FftLen,
									scratch, 
									WorkData, 
									FFTW_BACKWARD, 
									FFTW_MEASURE_OR_ESTIMATE|FFTW_PRESERVE_INPUT);
*/
			FftNum++;
			free_a(scratch);
			free_a(WorkData);
		}
		FftLen = FftLen * 2;
		bitfield >>= 1;
	}

	// Allocate memory in WorkData to be used by libfft
//	float *out= (float *)malloc_a(ac_fft_len*sizeof(float),MEM_ALIGN);
//	float *scratch=(float *)malloc_a(ac_fft_len*sizeof(float),MEM_ALIGN);
	WorkData_ = (sah_complex *)malloc_a(FftLen/2 * sizeof(sah_complex),MEM_ALIGN);

	
	WorkData = (sah_complex *)malloc_a(FftLen/2 * sizeof(sah_complex),MEM_ALIGN);
	return 0;
}

int FpgaInterface::setInitialData(
  				sah_complex* ChirpedData, int NumDataPoints,
				int FftNum, int fftlen
			  )
{
	FftNum_ = FftNum;
	fftlen_ = fftlen;
	NumDataPoints_ = NumDataPoints;
	NumFfts_   = NumDataPoints / fftlen;

	ChirpedData_ = (sah_complex *)malloc_a(NumDataPoints * sizeof(sah_complex), MEM_ALIGN);
	memcpy(ChirpedData_, ChirpedData, NumDataPoints * sizeof(sah_complex) );

	return 0;
}

void FpgaInterface::runAnalysis()
{
	//float* AutoCorrelation = (float*)calloc_a(ac_fft_len, sizeof(float), MEM_ALIGN);
	PowerSpectrum_   = (float*) calloc_a(NumDataPoints_, sizeof(float), MEM_ALIGN);
	int CurrentSub;
	int retval;

	for (int ifft = 0; ifft < NumFfts_; ifft++) {
		// boinc_worker_timer();
		CurrentSub = fftlen_ * ifft;
		fprintf(stderr, "\nifft=%d, CurrentSub=%d", ifft, CurrentSub);

		fftwf_execute_dft(analysis_plans[FftNum], &ChirpedData[CurrentSub], WorkData);
		fprintf(stderr, "\nGetPowerSpectrum(&PowerSpectrum[CurrentSub=%d], fftlen=%d", CurrentSub, fftlen);
		GetPowerSpectrum(WorkData,
				 &PowerSpectrum[CurrentSub],
				 fftlen
		// this can be pulled out of this for loop
		fftwf_execute_dft(analysis_plans[FftNum_], &ChirpedData_[CurrentSub], WorkData_);

		// this can be pulled out of this for loop
		fprintf(stderr, "\nGetPowerSpectrum(&PowerSpectrum[CurrentSub=%d], fftlen=%d", CurrentSub, fftlen_);
		GetPowerSpectrum(WorkData_,
				 &PowerSpectrum_[CurrentSub],
				 fftlen_
			);

		// this can be pulled out of this for loop
/*
		if (fftlen==(long)ac_fft_len) {
			//state.FLOP_counter+=((double)fftlen)*5*log((double)fftlen)/log(2.0)+2*fftlen;
			fftwf_execute_r2r(
						autocorr_plan,
						&PowerSpectrum[CurrentSub],
						AutoCorrelation);
		}
*/
		// any ETIs ?!
		// If PoT freq bin is non-negative, we are into PoT analysis
		// for this cfft pair and need not redo spike and autocorr finding.
//		if (PoT_freq_bin == -1) {
		//	//JWS: Don't look for Spikes at too short FFT lengths. 
//			if (fftlen >= SpikeMin) {
		//		//state.FLOP_counter+=(double)fftlen;
		//		fprintf(stderr, "\nFindSpikes(&PowerSpectrum[CurrentSub=%d], fftlen=%d", CurrentSub, fftlen);
		//		retval = FindSpikes(
		//				&PowerSpectrum[CurrentSub],
		//				fftlen,
		//				ifft,
		//				swi
		//			);
//			}

		//	// this executes only when the auto correct plan is executed
		//	if (fftlen==ac_fft_len) {
		//		fprintf(stderr, "\nFindAutoCorrelation(fftlen=%d)", fftlen);
		//		retval = FindAutoCorrelation(
		//					AutoCorrelation,
		//					fftlen,
		//					ifft,
		//					swi
		//				);
		//	//if (retval) SETIERROR(retval,"from FindAutoCorrelation");
		//	//	progress += 2.0*SpikeProgressUnits(fftlen)*ProgressUnitSize/NumFfts;
		//	//} else {
		//	//	progress += SpikeProgressUnits(fftlen)*ProgressUnitSize/NumFfts;
		//	//}
//		}
	//progress = std::min(progress,1.0);
	//remaining = 1.0-(double)(icfft+1)/num_cfft;
	//fraction_done(progress,remaining);
	//fprintf(stderr, "\nprogress=%f, remaining=%f", progress, remaining);
	} // loop through chirped data array	

}

void FpgaInterface::compareResults(float *PowerSpectrum)
{
	for (int i=0; i<NumDataPoints_; i++) {
		if (PowerSpectrum[i] != PowerSpectrum_[i])
			fprintf(stderr, "\nPowerSpectrum[i] != PowerSpectrum_[i], %f != %f", PowerSpectrum[i], PowerSpectrum_[i]);
	}

}
