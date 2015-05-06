
#include "dumpDataToScreen.h"
#include <iostream>

void DumpDataToScreen ( sah_complex **pDataIn, int *pNumDataPoints, int max )
{
	std::cout << "\nOpened Original Data Points File.";
	std::cout << "\n";
	std::cout << "\nTotal number of original data points: " << *pNumDataPoints;
	std::cout << "\n\nFirst 10 data point pairs:";
	for ( int i=0; i < *pNumDataPoints && i < max ; i++ )
	{
		std::cout << "\n[" << i << "] = (" << (*pDataIn)[i][0] << ", " << (*pDataIn)[i][1] << ")";
	}
}

void DumpChirpFftPairsToScreen ( ChirpFftPair_t **ppChirpFftPairs, int start_cfft, int end_cfft, int max )
{
	ChirpFftPair_t *ChirpFftPairs = *ppChirpFftPairs;
	std::cout << "\n";
	std::cout << "\nOpened Chirp Fft Pairs File";
	std::cout << "\nShowing first 5 pairs:";
	std::cout.width(10);
	std::cout << "\n" << "Pair #" << "\tChirpRate" << "\tChirpRateInd" << "\tFftLen" << "\tGaussFit" << "\tPulseFind";

	for ( int i = start_cfft; i < end_cfft && i < start_cfft + max; i++ )
	{
		std::cout	<< "\n" << (i+1)
					<< "\t" << ChirpFftPairs[i].ChirpRate 
					<< "\t" << ChirpFftPairs[i].ChirpRateInd
					<< "\t" << ChirpFftPairs[i].FftLen
					<< "\t" << ChirpFftPairs[i].GaussFit
					<< "\t" << ChirpFftPairs[i].PulseFind;
	}
}