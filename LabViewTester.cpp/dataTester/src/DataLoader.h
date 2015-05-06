
#include <string>
#include <fstream>

#include "type_defs.h"

class DataLoader {
public:
	std::string root_dir_;
	int run_number_;

	int NumDataPoints_;

	// Run Parameters
	int start_icfft_;
	int end_icfft_;

	// Work Unit Data Points
	sah_complex *pDataIn_;

	// Chirp Fft Pairs
	int num_cfft_pairs_;
	ChirpFftPair_t *pChirpFftPairs_;

	// Power Spectrum
	float *pPowerSpectrum_;
	int icfft_;

public:
	DataLoader(std::string root_dir, int run_number);
	void dumpData(void);

private:
	std::string DataLoader::getDataFilePath(std::string source_filename);

	void LoadRunParameters(void);
	void LoadWorkUnitDataPoints(void);
	void LoadChirpFftPairs(void);
	void LoadPowerSpectrum(void);
};
