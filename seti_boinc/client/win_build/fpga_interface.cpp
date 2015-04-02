
#include "fpga_interface.h"

int FpgaInterface::initializeFpga(
				unsigned long bitfield
				)
{
	// Verify the values of the following variables:
	unsigned long FftLen = 1;
	int FftNum = 0;
	int analysis_fft_lengths[32];
//#define FFTW_MEASURE_OR_ESTIMATE ((app_init_data.host_info.m_nbytes >= MIN_TRANSPOSE_MEMORY)?FFTW_MEASURE:FFTW_ESTIMATE)

	sah_complex* WorkData = NULL;

	while (bitfield != 0) {
		if (bitfield & 1) {
			analysis_fft_lengths[FftNum] = FftLen;
			WorkData             = (sah_complex *)malloc_a(FftLen * sizeof(sah_complex), MEM_ALIGN);
			sah_complex *scratch = (sah_complex *)malloc_a(FftLen * sizeof(sah_complex), MEM_ALIGN);
			if ((WorkData == NULL) || (scratch==NULL)) {
				// Trap Error
			}
			fprintf(stderr, "\nplan_dft_1d(Fftlen=%d", FftLen);
			analysis_plans[FftNum] = fftwf_plan_dft_1d(FftLen, scratch, WorkData,
										FFTW_BACKWARD,
										FFTW_MEASURE_OR_ESTIMATE|FFTW_PRESERVE_INPUT);
			FftNum++;
			free_a(scratch);
			free_a(WorkData);
		}
		FftLen * =2;
		bitfield >>= 1;
	}
	
	WorkData = (sah_complex *)malloc_a(FftLen/2 * sizeof(sah_complex),MEM_ALIGN);
	
	return 0;
}

int FpgaInterface::setInitialData(
  				sah_complex* ChirpedData, int NumDataPoints
				  )
{
	ChirpedData_ = (sah_complex *)malloc_a(NumDataPoints * sizeof(sah_complex), MEM_ALIGN);
	memcpy(ChirpedData_, ChirpedData, NumDataPoints * sizeof(sah_complex) );
	
	return 0;
}

void FpgaInterface::runAnalysis(
	int NumFfts,
	int fftlen,
	unsigned long ac_fft_len
	)
{
	float* PowerSpectrum   = (float*) calloc_a(NumDataPoints, sizeof(float), MEM_ALIGN);
	float* AutoCorrelation = (float*) calloc_a(   ac_fft_len, sizeof(float), MEM_ALIGN);

	int CurrentSub;
	for (int ifft = 0; ifft < NumFfts; ifft++) {
		// boinc_worker_timer();
		CurrentSub = fftlen * ifft;
		fprintf(stderr, "\nifft=%d, CurrentSub=%d", ifft, CurrentSub);

		fftwf_execute_dft(analysis_plans[FftNum], &ChirpedData[CurrentSub], WorkData);
		fprintf(stderr, "\nGetPowerSpectrum(&PowerSpectrum[CurrentSub=%d], fftlen=%d", CurrentSub, fftlen);
		GetPowerSpectrum(WorkData,
				 &PowerSpectrum[CurrentSub],
				 fftlen
			);

		if (fftlen==(long)ac_fft_len) {
			//state.FLOP_counter+=((double)fftlen)*5*log((double)fftlen)/log(2.0)+2*fftlen;
			fftwf_execute_r2r(autocorr_plan,&PowerSpectrum[CurrentSub],AutoCorrelation);
		}

		// any ETIs ?!
		// If PoT freq bin is non-negative, we are into PoT analysis
		// for this cfft pair and need not redo spike and autocorr finding.
		if (state.PoT_freq_bin == -1) {
			//JWS: Don't look for Spikes at too short FFT lengths. 
			if (fftlen >= PoTInfo.SpikeMin) {
				//state.FLOP_counter+=(double)fftlen;
				fprintf(stderr, "\nFindSpikes(&PowerSpectrum[CurrentSub=%d], fftlen=%d", CurrentSub, fftlen);
				retval = FindSpikes(
						&PowerSpectrum[CurrentSub],
						fftlen,
						ifft,
						swi
					);
			if (retval) SETIERROR(retval,"from FindSpikes");
			}

			if (fftlen==ac_fft_len) {
				fprintf(stderr, "\nFindAutoCorrelation(fftlen=%d)", fftlen);
				retval = FindAutoCorrelation(
							AutoCorrelation,
							fftlen,
							ifft,
							swi
						);
			//if (retval) SETIERROR(retval,"from FindAutoCorrelation");
			//	progress += 2.0*SpikeProgressUnits(fftlen)*ProgressUnitSize/NumFfts;
			//} else {
			//	progress += SpikeProgressUnits(fftlen)*ProgressUnitSize/NumFfts;
			//}
		}
	//progress = std::min(progress,1.0);
	//remaining = 1.0-(double)(icfft+1)/num_cfft;
	//fraction_done(progress,remaining);
	//fprintf(stderr, "\nprogress=%f, remaining=%f", progress, remaining);
	} // loop through chirped data array	
}

void FpgaInterface::compareResults(float *PowerSpectrum)
{
}
