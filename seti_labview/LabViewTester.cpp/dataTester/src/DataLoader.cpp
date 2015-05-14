
#include "DataLoader.h"

#include <iostream>
#include <sstream>

DataLoader::DataLoader(std::string root_dir, int run_number)
{
	root_dir_ = root_dir;
	run_number_ = run_number;

	LoadRunParameters();
	LoadWorkUnitDataPoints();
	LoadChirpFftPairs();
	LoadPowerSpectrum();
}

std::string DataLoader::getDataFilePath(std::string source_filename)
{
	std::stringstream filename_str;
	filename_str << root_dir_ << "/Run" << run_number_ << "/" << source_filename;
	return filename_str.str();
}

void DataLoader::LoadRunParameters(void)
{
	std::string source_file = getDataFilePath("binRunParameters.bin");
	std::fstream dataFileIn ( source_file.c_str(), std::ios::in | std::ios::binary );
	if(!dataFileIn.is_open()) {
		std::cout << "\nUnable to open Data File";
		exit (1);
	}

	dataFileIn.read ( reinterpret_cast<char *> (&start_icfft_), sizeof(int));
	dataFileIn.read ( reinterpret_cast<char *> (&end_icfft_), sizeof(int) );
	
	dataFileIn.close();
}

/*
	LoadWorkUnitDataPoints

		Reads a binary file specified by file_name and parses the original Work Unit 
		Data points, in the following format:

		<NumDataPoints> (int)
		<DataPoint 1 - Real Component> (float)
		<DataPoint 1 - Imaginary Component> (float)
		...
		<DataPoint N - Real Component> (float)
		<DataPoint N - Imaginary Component> (float)
		<EOF>
*/
void DataLoader::LoadWorkUnitDataPoints ( ) {
	std::string source_file = getDataFilePath("binWorkUnitDataPoints.bin");
	std::fstream dataFileIn ( source_file.c_str(), std::ios::in | std::ios::binary );
	if ( ! dataFileIn.is_open() ) {
		std::cout << "\nUnable to open Data File";
		exit (1);
	}

	dataFileIn.read ( reinterpret_cast<char *> (&NumDataPoints_), sizeof(int) );

	pDataIn_ = new sah_complex [ NumDataPoints_ ];
	for ( int i=0; i < NumDataPoints_; i++ ) {
		int s = sizeof (float);
		dataFileIn.read ( reinterpret_cast<char *> ( &(pDataIn_)[i][0] ), sizeof ( float ) );
		dataFileIn.read ( reinterpret_cast<char *> ( &(pDataIn_)[i][1] ), sizeof ( float ) );
	}

	dataFileIn.close();
}

/*
	LoadChirpFftPairs

		Reads a binary file specified by file_name and parses the original set of
		Chirp/Fft pairs in the following format:

		<Number of Chirp/Fft Pairs> (int)
		<Chirp/Fft Pair 1 - Chirp Rate> (double)
		<Chirp/Fft Pair 1 - Chirp Rate Ind> (int)
		<Chirp/Fft Pair 1 - Fft Length> (int)
		<Chirp/Fft Pair 1 - Gauss Fit> (int)
		<Chirp/Fft Pair 1 - Pulse Find> (int)
		...
		<Chirp/Fft Pair N - All Components> (float)
		<EOF>
*/
void DataLoader::LoadChirpFftPairs(void) {
	std::string source_file = getDataFilePath("binChirpfftPairs.bin");
	std::fstream chirpFftFileIn (  ( source_file.c_str() ), std::ios::in | std::ios::binary );
	if ( ! chirpFftFileIn.is_open() ) {
		std::cout << "\nunable to open file: " << source_file;
		exit(1);
	}
	chirpFftFileIn.read ( reinterpret_cast<char *> ( &num_cfft_pairs_ ), sizeof(int) );

	pChirpFftPairs_ = new ChirpFftPair_t [ num_cfft_pairs_ ] ;
	for ( int i=0; i < num_cfft_pairs_; i++ ) {
		chirpFftFileIn.read ( reinterpret_cast<char *> ( &pChirpFftPairs_[i].ChirpRate ), sizeof ( double ) );
		chirpFftFileIn.read ( reinterpret_cast<char *> ( &pChirpFftPairs_[i].ChirpRateInd ), sizeof ( int ) );
		chirpFftFileIn.read ( reinterpret_cast<char *> ( &pChirpFftPairs_[i].FftLen ), sizeof ( int ) );
		chirpFftFileIn.read ( reinterpret_cast<char *> ( &pChirpFftPairs_[i].GaussFit), sizeof ( int ) );
		chirpFftFileIn.read ( reinterpret_cast<char *> ( &pChirpFftPairs_[i].PulseFind ), sizeof ( int ) );
	}

	chirpFftFileIn.close();
}

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
void DataLoader::LoadPowerSpectrum(void) {
	std::string source_file = getDataFilePath("binPowerSpectrum.bin");
	std::fstream dataFileIn ( source_file.c_str(), std::ios::in | std::ios::binary );
	if ( ! dataFileIn.is_open() ) {
		std::cout << "\nUnable to open Data File: " << source_file;
		exit (1);
	}

	int icfft = 0;
	do {
		dataFileIn.read ( reinterpret_cast<char *> (&icfft), sizeof(int) );
		dataFileIn.read ( reinterpret_cast<char *> (&NumDataPoints_), sizeof(int) );
		std::cout << "\nRead icfft in as " << icfft;
		pPowerSpectrum_ = new float [ NumDataPoints_ ];
		for ( int i=0; i < NumDataPoints_; i++ ) {
			dataFileIn.read ( reinterpret_cast<char *> ( &pPowerSpectrum_[i] ), sizeof ( float ) );
		}
	} while ( icfft != icfft && dataFileIn.is_open() ) ;

	dataFileIn.close();
}
void DataLoader::dumpData(void) {
	std::cout << "\nNumDataPoints_ = " << NumDataPoints_;
	std::cout << "\nDumping first 6 data points: ";
	for ( int i=0; i < 6; i++ ) {
		std::cout << "\n[" << i << "], real = " << pDataIn_[i][0] << ", imaginary = " << pDataIn_[i][1];
	}

	std::cout << "\nstart_icfft_ = " << start_icfft_;
	std::cout << "\nend_icfft_ = " << end_icfft_;

	std::cout << "\nnum_cfft_pairs_ = " << num_cfft_pairs_;
	std::cout << "\nDumping first 6 Chirp Fft Pairs";
	for ( int i=0; i < 6; i++ ) {
		std::cout << "\n[" << i << "].ChirpRate = " << pChirpFftPairs_[i].ChirpRate;
		std::cout << "\n[" << i << "].ChirpRateInd = " << pChirpFftPairs_[i].ChirpRateInd;
		std::cout << "\n[" << i << "].FftLen = " << pChirpFftPairs_[i].FftLen;
		std::cout << "\n[" << i << "].GaussFit = " << pChirpFftPairs_[i].GaussFit;
		std::cout << "\n[" << i << "].PulseFind = " << pChirpFftPairs_[i].PulseFind;
	}

	std::cout << "\nDumping first 6 PowerSpectrum values: ";
	for ( int i=0; i < 6; i++ ) {
		std::cout << "\n[" << i << "] = " << pPowerSpectrum_[i];
	}
}