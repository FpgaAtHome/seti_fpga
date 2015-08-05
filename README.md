# seti_fpga
Port of SETI@Home to an FPGA Platform

Use Visual Studio 2005 to open and build the following 2 solutions:

boinc-old/win_build/boinc.sln
seti_boinc/client/win_build/seti_boinc.sln

## Things to Do:

[1] Change all references from seti_boinc.sln related projects to boinc-old from boinc.
[2] Update all configurations to mirror the Debug configuration, so they all work.
[3] Convert LabViewTester.cpp project into a Visual Studio 2005 project. (Or add support for both)

## How to Run the Code

	This Visual Studio 2005 Solution has 2 configurations for 2 platforms for a total of 4
	possible ways to run the application:
		+ Win32->Debug
		+ Win32->Release
		+ x64->Debug
		+ x64->Release
 
	I have not yet tested out the 64-bit builds.  But both 32-bit configurations work.

	At the start of each work unit calculation, the following files are read and a "soft link" is
	resolved:
		work_unit.sah => resolves to a file named as such:
						 28my12ac.28765.12080.438086664195.12.177.vlar
		result.sah => resolves to a file named as such:
						 28my12ac.28765.12080.438086664195.12.177.vlar_result

	So to quickly reset your work unit calculation, to get back to the original state of your
	application to be as if you just downloaded a new work unit:
	(from the <git_root>/client/projects/setiathome.berkeley.edu directory)
	(1) Copy:
		28my12ac.28765.12080.438086664195.12.177.vlar_original
			to
		28my12ac.28765.12080.438086664195.12.177.vlar
	(2) Delete:
		28my12ac.28765.12080.438086664195.12.177.vlar_result
	(from the <git_root>/client/slots/0 directory)
	(1) Delete: state.sah
	(2) Delete: boinc_lockfile

## Running the Test Code:

There are 3 ways of testing the input and output Fft data.  One is with pure Labview, the other is
with C++, and the last is with Pyhon 2.7.

	Open the Visual Studio 2010 Solution from the following location:
		seti_labview/LabViewTester.cpp/set_fpga.sln
	Build the Solution (Preferably the Debug Configuration)
	Open a windows command prompt and go to the following directory:
		seti_labview/LabViewTester.cpp\dataTester\Debug
	Execute the following command:
		.\dataTester.exe
	
## Quick Analysis of the code:

The main function of interest, where all the heavy lifting occurs is in the "analyzeFuncs.cpp" file
in the "seti_analyze" function.  This function starts at around line 178.

	worker.cpp::worker()
		read_wu_state()
			Opens the work_unit.sah file

	analyzeFuncs.cpp::seti_analyze()
		Look for #ifdef USE_FPGA.  If this #define is not set, the regular code will run,
		if this is set, the Fpga will be used only for FFT's of length 16.

		Go to around line #507, and you will see an #ifdef for USE_FPGA.  This will print
		some benchmarking information and initialize the connection to the Fpga.

		Then at around line 515, the main loop begins, which loops from 0 to num_cffts.
		num_cffts is usually around 100,000, and for each iteration, the loop does:
			- ChirpData
				input:
					DataIn
					chirprateind
					chirprate
					NumDataPoints
					swi.subband_sample_rate
				output:
					ChirpedData
			- Loops from 0 to # of Ffts to perform, the # of Ffts is NumDataPoints / fftlen
				(typically 1,000,000 / 16)
			- Performs a Fft on portions of the ChirpedData in increments of Fftlen
			- Calls GetPowerSpectrum on those results
			- Does a quick analysis
			- This loop (the inner loop) can be done in one large step inside the Fpga

	Note:
		Between Debug and Release modes, a different set of functions are selected because
		SETI@Home tests out each function at the start of the run to determine which is the
		fastest function, and in Debug mode no performance enchancement is detected due to the
		lack of optimizations.
		
		Looks like I found the bug - it was calling a function that is for a 64-bit platform
		when running on a 32-bit build.  Of course there was going to be an error!

## The Main "Loop"

A SETI@Home "Work Unit" contains roughly 1 million Complex Single-Precision Floating Point numbers.

The processing of this Work Unit occurs in the "seti_analyze" function, which starts at line 178 of analyzeFuncs.cpp.
   https://github.com/FpgaAtHome/seti_fpga/blob/master/seti_boinc/client/analyzeFuncs.cpp

This function has a loop that starts at around line 515 which does the following:
 * Generate or load Chirp Fft Pairs - The number of "Chirp Fft" pairs is different depending on the work unit, but it typically numbers in the 140 thousands.  Each Chirp Fft pair contains an Fft length, and a Chirp Rate.
 * Iterate from 0 to the total number of Chirp Fft Pairs.
  * Take the 1 million Complex Data points and "Chirp" the data. See the function named
	"v_ChirpData" in analyzeFuncs.cpp.

	Use the Fft Length specified in the current Chirp Fft pair, and iterate over the input datapoints one Fft Length at a time.

	NumFfts = NumDataPoints / fftlen
	for ifft=0; i < NumFfts; i++
		Calculate Fft
		GetPowerSpectrum
		FindSpikes
		FindAutoCorrelation
		
		GetPulsePoTLen
		Transpose
		analyze_pot

## Roadmap

Next steps:
[ ] Modify the FPGA Code to:
  [ ] Store the 1 million Complex Data Points into the FPGA RAM when the program loads
  [ ] Read the data from FPGA RAM before calculating the FFT. (It currently passes in the 1 million Complex Data Points in to the FPGA for each call)
[ ] Add support for multiple FFT lengths.  We should start with the longer FFT lengths, as an FPGA will probably do much better than a CPU for long data sets that do not fit in a small L1 or L2 cache
[ ] Implement the "GetPowerSpectrum" function in the FPGA so that the C++ code can skip over the "GetPowerSpectrum" function
[ ] Implement the "ChirpData" function inside the FPGA.

