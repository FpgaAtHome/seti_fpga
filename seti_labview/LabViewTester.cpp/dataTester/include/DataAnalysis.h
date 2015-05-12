
#ifndef DATA_ANALYSIS_H
#define DATA_ANALYSIS_H

// These functions should exist in the SETI project as-is, and are
// meant to be replaced by the LabVIEW-FPGA version

#include "DataLoader.h"

class DataAnalysis
{
public:
	DataAnalysis(DataLoader &dataLoader) : dataLoader(dataLoader)
	{
	}
	bool RunAnalysis();

private:
	void sincos(double angle, double *s, double *c);
	bool AreFloatsEqual(float a, float b);
	int ChirpData(
		sah_complex* cx_DataArray,
		sah_complex* cx_ChirpDataArray,
		int chirp_rate_ind,
		double chirp_rate,
		int  ul_NumDataPoints,
		double sample_rate
	);
	int GetPowerSpectrum(
		sah_complex* FreqData,
		float* PowerSpectrum,
		int NumDataPoints
	);

	DataLoader &dataLoader;
};

#endif