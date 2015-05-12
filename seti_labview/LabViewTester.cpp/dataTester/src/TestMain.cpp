
#include "gtest/gtest.h"
#include "gmock/gmock.h"

#include <complex>
#include <vector>

#pragma comment(lib, "libfftw3-3.lib")
#pragma comment(lib, "libfftw3f-3.lib")

#include "DataAnalysis.h"
#include "ResultsLoader.h"
#include "fftw3.h"

#include "FpgaInterface.h"

class DataLoader;

using ::testing::Eq;
using ::testing::ElementsAre;
using ::testing::ElementsAreArray;
using ::testing::Pair;
using ::testing::FloatEq;
using ::testing::Pointwise;

const char* data_path = "../../TestData/";

MATCHER_P(FloatNearPointwise, tol, "Out of range") {
    return (std::get<0>(arg)>std::get<1>(arg)-tol && std::get<0>(arg)<std::get<1>(arg)+tol) ;
}

// Helpers
std::vector<std::pair<float, float>> LoadTestData(std::string filename)
{
	std::string inDataFilePath(data_path);
	inDataFilePath = inDataFilePath.append(filename);

	std::vector<std::pair<float, float>> loaded_data;

	std::ifstream inDataFile(inDataFilePath);
	std::string line;
	while (std::getline(inDataFile, line))
	{
		std::istringstream iss(line);
		float val_1, val_2;
		if (!(iss >> val_1 >> val_2))
			break;
		loaded_data.push_back(std::make_pair(val_1, val_2));
	}

	return loaded_data;
}

fftwf_complex* ConvertVectorToArray(std::vector<std::pair<float, float>> inVector) {
	fftwf_complex* outComplexArray = new fftwf_complex[inVector.size()];
	for (int i=0; i < inVector.size(); i++){
		outComplexArray[i][0] = inVector.at(i).first;
		outComplexArray[i][1] = inVector.at(i).second;
	}
	return outComplexArray;
}

void DumpResults(fftwf_complex* out_data, int results_len) {
	std::cout.precision(12);
	for (int i=0;i<results_len/2 + 1;i++) {
		std::cout << "\n" << out_data[i][0] << "\t" << out_data[i][1];
	}
}

class TestFft : public ::testing::Test {
protected:
	virtual void SetUp() {
	}

	virtual void TearDown() {
	}
};

// Values calculated using:
// http://calculator.vhex.net/calculator/fast-fourier-transform-calculator-fft/1d-discrete-fourier-transform

TEST(LibFftTest, Simple_RealToComplex_Fft_2) {
	// GIVEN
	int fft_len = 2;
	double in_data[] = {1, 0};
	fftw_complex* out_data = (fftw_complex*)malloc(fft_len*sizeof(fftw_complex));
	fftw_plan analysis_plan = fftw_plan_dft_r2c_1d(fft_len, in_data, out_data, FFTW_ESTIMATE);
	
	// WHEN
	fftw_execute_dft_r2c(analysis_plan, in_data, out_data);

	// THEN
	std::vector<double> out_data_c;
	for (int i=0;i<fft_len/2+1;i++){
		out_data_c.push_back(out_data[i][0]);
		out_data_c.push_back(out_data[i][1]);
	}
	ASSERT_THAT(out_data_c, ElementsAre(1, 0, 1, 0));
	fftw_destroy_plan(analysis_plan);
}

TEST(LibFftTest, Simple_RealToComplex_Fft_4) {
	// GIVEN
	int fft_len = 4;
	double in_data[] = { 0, 1, 0, 0};
	fftw_complex* out_data = (fftw_complex*)malloc(fft_len*sizeof(fftw_complex));
	fftw_plan analysis_plan = fftw_plan_dft_r2c_1d(fft_len, in_data, out_data, FFTW_ESTIMATE);
	
	// WHEN
	fftw_execute_dft_r2c(analysis_plan, in_data, out_data);

	// THEN
	std::vector<double> out_data_c;
	for (int i=0;i<fft_len/2+1;i++){
		out_data_c.push_back(out_data[i][0]);
		out_data_c.push_back(out_data[i][1]);
	}
	ASSERT_THAT(out_data_c, ElementsAre(1, 0, 0, -1, -1, 0));
	fftw_destroy_plan(analysis_plan);
}

TEST(LibFftTest, Simple_ComplexToComplex_Fft_4) {
	// GIVEN
	int fft_len = 4;
	fftwf_complex* in_data = new fftwf_complex[fft_len];
	fftwf_complex* out_data = new fftwf_complex[fft_len];
	fftwf_plan analysis_plan = fftwf_plan_dft_1d(fft_len, in_data, out_data, FFTW_BACKWARD, FFTW_MEASURE);
	
	fftwf_complex in_data_tmp[] = { {0, 1}, {0, 0}, {0, 0}, {0, 0} };
	memcpy(in_data, &in_data_tmp, fft_len*sizeof(fftwf_complex));

	// WHEN
	fftwf_execute_dft(analysis_plan, in_data, out_data);

	// THEN
	std::vector<float> out_data_c;
	for (int i=0;i<fft_len/2+1;i++) {		
		out_data_c.push_back(out_data[i][0]);
		out_data_c.push_back(out_data[i][1]);
	}
	ASSERT_THAT(out_data_c, ElementsAre(0, 1, 0, 1, 0, 1));
	fftwf_destroy_plan(analysis_plan);
}

TEST(LibFftTest, Simple_ComplexToComplex_Fft_4_Diff_Data) {
	// GIVEN
	int fft_len = 4;
	fftwf_complex* in_data = new fftwf_complex[fft_len];
	fftwf_complex* out_data = new fftwf_complex[fft_len];
	fftwf_plan analysis_plan = fftwf_plan_dft_1d(fft_len, in_data, out_data, FFTW_FORWARD, FFTW_MEASURE);

	fftwf_complex in_data_tmp[] = { {0, 1}, {1, 2.0}, {3, .55}, {0, 0} };
	memcpy(in_data, &in_data_tmp, fft_len*sizeof(fftwf_complex));

	// WHEN
	fftwf_execute_dft(analysis_plan, in_data, out_data);

	// THEN
	std::vector<float> out_data_c;
	for (int i=0;i<fft_len/2+1;i++) {
		out_data_c.push_back(out_data[i][0]);
		out_data_c.push_back(out_data[i][1]);
	}
	ASSERT_THAT(out_data_c, ElementsAre(4, 3.55, -1, -0.55, 2, -0.45));
	fftwf_destroy_plan(analysis_plan);
	delete[] out_data;
}

// http://rosettacode.org/wiki/Fast_Fourier_transform#C.2B.2B
TEST(LibFftTest2, Simple_ComplexToComplex_Fft_8_Wikipedia_Page_Data) {
	// GIVEN
	int fft_len = 8;
	fftwf_complex* in_data = new fftwf_complex[fft_len];
	fftwf_complex* out_data = new fftwf_complex[fft_len];
	fftwf_plan analysis_plan = fftwf_plan_dft_1d(fft_len, in_data, out_data, FFTW_FORWARD, FFTW_MEASURE);
	
	fftwf_complex* in_data_tmp = ConvertVectorToArray(LoadTestData("data_8.txt"));
	memcpy(in_data, in_data_tmp, fft_len*sizeof(fftwf_complex));

	// WHEN
	fftwf_execute_dft(analysis_plan, in_data, out_data);

	// THEN
	std::vector<float> out_data_c;
	for (int i=0;i<fft_len/2+1;i++) {
		out_data_c.push_back(out_data[i][0]);
		out_data_c.push_back(out_data[i][1]);
	}
	float expected_array[] = {4, 0, 1.0, -2.41421, 0, 0, 1.0, -0.414214, 0, 0};
	EXPECT_THAT(out_data_c, Pointwise( FloatNearPointwise(1e-5), expected_array  ) );
	fftwf_destroy_plan(analysis_plan);
}

TEST(LibFftTest, Simple_ComplexToComplex_Fft_8_Simple) {
	// GIVEN
	int fft_len = 8;
	fftwf_complex* in_data = new fftwf_complex[fft_len];
	fftwf_complex* out_data = new fftwf_complex[fft_len];
	fftwf_plan analysis_plan = fftwf_plan_dft_1d(fft_len, in_data, out_data, FFTW_FORWARD, FFTW_MEASURE);
	fftwf_complex in_data_tmp[] = { {0, 1}, {1, 2.0}, {3, .55}, {0, 0},
								{0, 1}, {1, 2.0}, {3, .55}, {0, 0} };
	memcpy(in_data, &in_data_tmp, fft_len*sizeof(fftwf_complex));
	// WHEN
	fftwf_execute_dft(analysis_plan, in_data, out_data);

	// THEN
	std::vector<float> out_data_c;
	for (int i=0;i<fft_len/2+1;i++) {
		out_data_c.push_back(out_data[i][0]);
		out_data_c.push_back(out_data[i][1]);
	}
	ASSERT_THAT(out_data_c, ElementsAre(
							8, 7.1,
							0, 0,
							-2, -1.1,
							0, 0,
							4, -0.9));
	fftwf_destroy_plan(analysis_plan);
}

TEST(LibFftTest, Simple_RealToComplex_Fft_16_Simple) {
	// GIVEN
	int fft_len = 16;
	fftwf_complex* in_data = new fftwf_complex[fft_len];
	fftwf_complex* out_data = new fftwf_complex[fft_len];
	fftwf_plan analysis_plan = fftwf_plan_dft_1d(fft_len, in_data, out_data, FFTW_FORWARD, FFTW_MEASURE);
	fftwf_complex in_data_tmp[] = {
		{1, 0}, {1, 0}, {3, 0}, {0, 0},
		{0, 0}, {1, 0}, {3, 0}, {0, 0},
		{0, 0}, {1, 0}, {3, 0}, {0, 0},
		{0, 0}, {1, 0}, {3, 0}, {0, 0}
	};
	memcpy(in_data, &in_data_tmp, fft_len*sizeof(fftwf_complex));
	// WHEN
	fftwf_execute_dft(analysis_plan, in_data, out_data);

	// THEN
	std::vector<float> out_data_c;
	for (int i=0;i<fft_len/2+1;i++) {
		out_data_c.push_back(out_data[i][0]);
		out_data_c.push_back(out_data[i][1]);
	}

	ASSERT_THAT(out_data_c.at(0), Eq(17));
	ASSERT_THAT(out_data_c.at(1), Eq(0));
	ASSERT_THAT(out_data_c.at(2), Eq(1));
	ASSERT_THAT(out_data_c.at(3), Eq(0));
	ASSERT_THAT(out_data_c.at(4), Eq(1));
	ASSERT_THAT(out_data_c.at(5), Eq(0));
	ASSERT_THAT(out_data_c.at(6), Eq(1));
	ASSERT_THAT(out_data_c.at(7), Eq(0));
	ASSERT_THAT(out_data_c.at(8), Eq(-11));
	ASSERT_THAT(out_data_c.at(9), Eq(-4));
							/*,
							-4, -2.2,
							0, 0,
							0, 0,
							0, 0,
							8, -1.8*/
	fftwf_destroy_plan(analysis_plan);
}

TEST(LibFftTest, Simple_ComplexToComplex_Fft_16_Simple) {
	// GIVEN
	int fft_len = 16;
	fftwf_complex* in_data = new fftwf_complex[fft_len];
	fftwf_complex* out_data = new fftwf_complex[fft_len];
	fftwf_plan analysis_plan = fftwf_plan_dft_1d(fft_len, in_data, out_data, FFTW_FORWARD, FFTW_MEASURE);
	fftwf_complex in_data_tmp[] = {
		{0, 1}, {1, 2.0}, {3, .55}, {0, 0},
		{0, 1}, {1, 2.0}, {3, .55}, {0, 0},
		{0, 1}, {1, 2.0}, {3, .55}, {0, 0},
		{0, 1}, {1, 2.0}, {3, .55}, {0, 0}
	};
	memcpy(in_data, &in_data_tmp, fft_len*sizeof(fftwf_complex));
	// WHEN
	fftwf_execute_dft(analysis_plan, in_data, out_data);

	// THEN
	std::vector<float> out_data_c;
	for (int i=0;i<fft_len/2+1;i++) {
		out_data_c.push_back(out_data[i][0]);
		out_data_c.push_back(out_data[i][1]);
	}

	ASSERT_THAT(out_data_c.at(0), Eq(16));
	ASSERT_THAT(out_data_c.at(1), Eq(14.2f));
	ASSERT_THAT(out_data_c.at(2), Eq(0));
	ASSERT_THAT(out_data_c.at(3), Eq(0));
	ASSERT_THAT(out_data_c.at(4), Eq(0));
	ASSERT_THAT(out_data_c.at(5), Eq(0));
	ASSERT_THAT(out_data_c.at(6), Eq(0));
	ASSERT_THAT(out_data_c.at(7), Eq(0));
	ASSERT_THAT(out_data_c.at(8), Eq(-4));
	ASSERT_THAT(out_data_c.at(9), Eq(-2.2f));
							/*,
							-4, -2.2,
							0, 0,
							0, 0,
							0, 0,
							8, -1.8*/
	fftwf_destroy_plan(analysis_plan);
}

TEST(LibFftTest, LoadFile_16) {
	// GIVEN
	std::string filename("data_16.txt");

	// WHEN
	std::vector<std::pair<float, float>> in_data = LoadTestData(filename);

	// THEN
	ASSERT_THAT(in_data.size(), Eq(16u));

	ASSERT_THAT(in_data.at(0).first, Eq(1));
	ASSERT_THAT(in_data.at(0).second, Eq(1));

	ASSERT_THAT(in_data.at(10).first, Eq(11));
	ASSERT_THAT(in_data.at(10).second, Eq(0.55f));

	ASSERT_THAT(in_data.at(15).first, Eq(16));
	ASSERT_THAT(in_data.at(15).second, Eq(0));
}

TEST(LibFftTest, LoadFile_32) {
	// GIVEN
	std::string filename("data_32.txt");

	// WHEN
	std::vector<std::pair<float, float>> in_data = LoadTestData(filename);

	// THEN
	ASSERT_THAT(in_data.size(), Eq(32u));

	ASSERT_THAT(in_data.at(0).first, Eq(1));
	ASSERT_THAT(in_data.at(0).second, Eq(1));

	ASSERT_THAT(in_data.at(10).first, Eq(11));
	ASSERT_THAT(in_data.at(10).second, Eq(0.55f));

	ASSERT_THAT(in_data.at(15).first, Eq(16));
	ASSERT_THAT(in_data.at(15).second, Eq(0));

	ASSERT_THAT(in_data.at(31).first, Eq(32));
	ASSERT_THAT(in_data.at(31).second, Eq(0.27f));
}

TEST(LibFftTest, ConvertFloatVector_To_FftwfComplexArray) {
	// GIVEN
	std::string filename("data_32.txt");
	std::vector<std::pair<float, float>> in_data = LoadTestData(filename);

	// WHEN
	fftwf_complex* complexArray = ConvertVectorToArray(in_data);

	// THEN
	ASSERT_THAT(complexArray[0][0], Eq(1));
	ASSERT_THAT(complexArray[0][1], Eq(1));
}

TEST(LibFftTest, Simple_ComplexToComplex_Fft_16_Simple_2) {
	// GIVEN
	int fft_len = 16;
	fftwf_complex* in_data = new fftwf_complex[fft_len];
	fftwf_complex* out_data = new fftwf_complex[fft_len];
	fftwf_plan analysis_plan = fftwf_plan_dft_1d(fft_len, in_data, out_data, FFTW_FORWARD, FFTW_MEASURE);
	fftwf_complex* in_data_tmp = ConvertVectorToArray(LoadTestData("data_16_1.txt"));
	memcpy(in_data, in_data_tmp, fft_len*sizeof(fftwf_complex));

	// WHEN
	fftwf_execute_dft(analysis_plan, in_data, out_data);

	//DumpResults(out_data, fft_len);
	// THEN
	fftwf_complex* results = ConvertVectorToArray(LoadTestData("data_16_1-results.txt"));

	ASSERT_THAT(results[0][0], Eq(136));
	ASSERT_THAT(results[0][1], Eq(13.97f));
	ASSERT_THAT(results[1][0], Eq(-7.98601f));
	ASSERT_THAT(results[1][1], Eq(39.5443f));
	ASSERT_THAT(results[2][0], Eq(-8.89803f));
	ASSERT_THAT(results[2][1], Eq(18.2975f));
	ASSERT_THAT(results[3][0], Eq(-9.67333f));
	ASSERT_THAT(results[3][1], Eq(11.6935f));

	ASSERT_THAT(results[5][0], Eq(-8.67333f));
	ASSERT_THAT(results[5][1], Eq(5.62479f));

	ASSERT_THAT(results[8][0], Eq(-8));
	ASSERT_THAT(results[8][1], Eq(-0.57f));

	fftwf_destroy_plan(analysis_plan);
}

TEST(LibFftTest, UseLabViewFpga_ComplexToComplex_Fft_16_Simple_1)
{
	try {

	// GIVEN
	int fft_len = 16;
	fftwf_complex* out_data = new fftwf_complex[fft_len];

	// WHEN
	FpgaInterface fpgaInterface;
	
	fftwf_complex* inData = new fftwf_complex[fft_len];
	fftwf_complex* outData = new fftwf_complex[fft_len];
	fftwf_complex* inDataTmp = ConvertVectorToArray(
													LoadTestData("data_16_1.txt")
													);
	fpgaInterface.PerformFft(16, inDataTmp, outData);
	fpgaInterface.CleanUpFpga();

	// THEN
	fftwf_complex* results = ConvertVectorToArray(
												LoadTestData("data_16_1-results.txt")
												);
	ASSERT_THAT(outData[0][0], FloatEq(136));
	ASSERT_THAT(outData[0][1], FloatEq(13.970009f));
	ASSERT_THAT(outData[1][0], FloatEq(-7.98601f));
	ASSERT_THAT(outData[1][1], FloatEq(39.5443f));
	ASSERT_THAT(outData[2][0], FloatEq(-8.89803f));
	ASSERT_THAT(outData[2][1], FloatEq(18.2975f));
	ASSERT_THAT(outData[3][0], FloatEq(-9.67333f));
	ASSERT_THAT(outData[3][1], FloatEq(11.6935f));

	ASSERT_THAT(outData[5][0], FloatEq(-8.67333f));
	ASSERT_THAT(outData[5][1], FloatEq(5.62479f));

	ASSERT_THAT(outData[8][0], FloatEq(-8));
	ASSERT_THAT(outData[8][1], FloatEq(-0.57f));
	}catch(std::exception& ex) {
		std::cout << "\nException: " << ex.what();
	}

}

/*
TEST_CASE("Run #1", "[test-run-1]") {
	// GIVEN
	int runNumber = 1;
	std::string base_dir = "../../Runs";

	DataLoader dataLoader(base_dir.c_str(), runNumber);
	DataAnalysis dataAnalysis(dataLoader);

	// WHEN
	bool all_values_equal = dataAnalysis.RunAnalysis();

	// THEN
	CHECK(all_values_equal);
}
*/

int main(int argc, char** argv) {
  // The following line must be executed to initialize Google Mock
  // (and Google Test) before running the tests.
  ::testing::InitGoogleMock(&argc, argv);
  return RUN_ALL_TESTS();
}