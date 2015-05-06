
#include "ResultsLoader.h"
#include <fstream>
#include <iostream>
#include <Windows.h>

/*
	LoadPowerSpectrum

		Reads a binary file specified by file_name and returns the icfft-th array of 
		Power Spectrums.  The format of the file is as so:

		<icfft> (int)
		<Number of Data Points> (int)
		<Power Spectrum of icfft data point 1> (float)
		...
		<Power Spectrum of icfft data point N> (float)
		<EOF or start of next Data Set>

*/
//void LoadPowerSpectrum ( const char *file_name, int *pNumDataPoints, float **pPowerSpectrum, int *pIcfft ) {
ResultsLoader::ResultsLoader(const char *base_dir, const char *file_name, int *pNumDataPoints, float **ppPowerSpectrum, int *pIcfft, int runNumber)
{
	std::fstream dataFileIn(GetFileNameAndPath (base_dir, file_name, runNumber), std::ios::in | std::ios::binary);
	if (!dataFileIn.is_open()) {
		std::cout << "\nUnable to open Data File";
		exit (1);
	}

	int icfft = 0;
	do {
		dataFileIn.read(reinterpret_cast<char *> (&icfft), sizeof(int));
		dataFileIn.read(reinterpret_cast<char *> (pNumDataPoints), sizeof(int));

		*ppPowerSpectrum = new float[*pNumDataPoints];
		for(int i=0; i < *pNumDataPoints; i++ ) {
			dataFileIn.read(reinterpret_cast<char *>(&(*ppPowerSpectrum)[i]), sizeof(float));
		}
	} while(*pIcfft != icfft && dataFileIn.is_open());

	dataFileIn.close();
}

/*
	int = 4 bytes
	float = 4 bytes
	double = 8 bytes
*/
char *ResultsLoader::GetFileNameAndPath(const char *base_dir, const char *file_name, int runNumber) {
	char *file_name2 = new char[MAX_PATH];
	memset(file_name2, 0, MAX_PATH);
	sprintf(file_name2, "%s/Run%d/%s", base_dir, runNumber, file_name);
	return(file_name2);
}