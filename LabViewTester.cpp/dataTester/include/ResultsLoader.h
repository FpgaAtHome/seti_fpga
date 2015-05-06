
#ifndef RESULTS_LOADER_H
#define RESULTS_LOADER_H

class ResultsLoader
{
public:
	ResultsLoader(const char *base_dir, const char *file_name, int *pNumDataPoints, float **ppPowerSpectrum, int *pIcfft, int runNumer);
private:
	char *GetFileNameAndPath(const char *base_dir, const char *file_name, int runNumer);
};

#endif