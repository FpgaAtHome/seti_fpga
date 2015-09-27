
#include "DataAnalysis.h"
#include "ResultsLoader.h"

#include <iostream>
#include <fstream>
#include <cmath>

#include "type_defs.h"
#include "fftw3.h"

// Plan
// wherever you see a USE_FFTW
// add a USE_FPGA
// USE_FPGA will call a special function
#define M_PI 3.14159265358979323846

bool DataAnalysis::RunAnalysis()
{
	double subband_sample_rate = 9765.6200000000008;
	sah_complex *ChirpedData = (sah_complex *)malloc(dataLoader.NumDataPoints_ * sizeof(sah_complex));

	bool all_values_equal = true;

	for(int j = dataLoader.start_icfft_; j < dataLoader.end_icfft_; j++)
	{
		// Step 1 - ChirpData		
		int retval = ChirpData(
				dataLoader.pDataIn_,
				ChirpedData,
				dataLoader.pChirpFftPairs_[j].ChirpRateInd,
				dataLoader.pChirpFftPairs_[j].ChirpRate,
				dataLoader.NumDataPoints_,
				subband_sample_rate
			);

		// Step 2a - FFT prep
		sah_complex *WorkData =(sah_complex *)malloc(dataLoader.pChirpFftPairs_[j].FftLen * sizeof(sah_complex));
		sah_complex *scratch=(sah_complex *)malloc(dataLoader.pChirpFftPairs_[j].FftLen * sizeof(sah_complex));
		fftwf_plan analysis_plan =
				fftwf_plan_dft_1d(
					dataLoader.pChirpFftPairs_[j].FftLen, 
					scratch, 
					WorkData,
					FFTW_BACKWARD, FFTW_MEASURE|FFTW_PRESERVE_INPUT);

		int NumFfts = dataLoader.NumDataPoints_ / dataLoader.pChirpFftPairs_[j].FftLen;
		int CurrentSub = 0;
		float* PowerSpectrum = (float *)malloc(dataLoader.NumDataPoints_ *sizeof(float));
		for(int ifft = 0; ifft < NumFfts; ifft++)
		{
			CurrentSub = dataLoader.pChirpFftPairs_[j].FftLen * ifft;
			// Step 2b - FFT
			fftwf_execute_dft(analysis_plan, &ChirpedData[CurrentSub], WorkData);
			// Step 3 - GetPowerSpectrum
			 GetPowerSpectrum(WorkData,
                              &PowerSpectrum[CurrentSub],
                              dataLoader.pChirpFftPairs_[j].FftLen
                            );
		}
		// Read results from file and compare
		int NumDataPoints2 = 0;
		float **ppPowerSpectrum = new float *;
		ResultsLoader results(dataLoader.root_dir_.c_str(), "binPowerSpectrum.bin", &NumDataPoints2, ppPowerSpectrum, &j, dataLoader.run_number_);

		for(int i = 0; i < NumDataPoints2; i++) {
			all_values_equal &= AreFloatsEqual((*ppPowerSpectrum)[i], PowerSpectrum[i]);
		}
	}
	return all_values_equal;
}

void DataAnalysis::sincos(double angle, double *s, double *c)
{
  *s = sin(angle);
  *c = cos(angle);
}

bool DataAnalysis::AreFloatsEqual(float a, float b)
{
	if ( fabs(a - b) < 0.0001 ) {
		return true;
	}
	return false;
}


int DataAnalysis::ChirpData(
    sah_complex* cx_DataArray, // DataIn - never changes
    sah_complex* cx_ChirpDataArray, // ChirpedData - takes results
    int chirp_rate_ind, // chirprateind
    double chirp_rate, // chirp_rate
    int  ul_NumDataPoints, // NumDataPoints always stays the same
    double sample_rate // swi.subband_sample_rate
)
{
    double recip_sample_rate=1.0/sample_rate;


    if (chirp_rate_ind == 0) {
        memcpy(cx_ChirpDataArray,
               cx_DataArray,
               (int)ul_NumDataPoints * sizeof(sah_complex)
              );    // NOTE INT CAST
	} else {

        // calculate trigonometric array
        // this function returns w/o doing nothing when sign of chirp_rate_ind
        // reverses.  so we have to take care of it.

        for (int i = 0; i < ul_NumDataPoints; i++) {
            float c, d, real, imag;

                double dd,cc;
                double time=static_cast<double>(i)*recip_sample_rate;
                // since ang is getting moded by 2pi, we calculate "ang mod 2pi"
                // before the call to sincos() inorder to reduce roundoff error.
                // (Bug submitted by Tetsuji "Maverick" Rai)
                double ang  = 0.5*chirp_rate*time*time;
                ang -= floor(ang);
                ang *= M_PI*2;
								// sin cos
                sincos(ang,&dd,&cc);
                c=cc;
                d=dd;
            // Sometimes chirping is done in place.
            // We don't want to overwrite data prematurely.
            real = cx_DataArray[i][0] * c - cx_DataArray[i][1] * d;
            imag = cx_DataArray[i][0] * d + cx_DataArray[i][1] * c;
            cx_ChirpDataArray[i][0] = real;
            cx_ChirpDataArray[i][1] = imag;
        }
	}

    return 0;
}
int DataAnalysis::GetPowerSpectrum(
    sah_complex* FreqData,
    float* PowerSpectrum,
    int NumDataPoints
) {
    int i;

    for (i = 0; i < NumDataPoints; i++) {
        PowerSpectrum[i] = FreqData[i][0] * FreqData[i][0]
                           + FreqData[i][1] * FreqData[i][1];
    }
    return 0;
}