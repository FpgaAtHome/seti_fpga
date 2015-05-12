import numpy
import os
import random
import cmath
import unittest


def main():
	aux = raw_input("Do you wish to generate random input files? Y/N\n")
	if aux == "Y" or aux == "y":
		os.chdir("Testing")
		for filee in os.listdir("."):
			os.remove(filee)
		os.chdir("..") # delete all existing files from the testing directory
		generateAllInputFiles()
		
	aux = raw_input("Do you wish to run unit testing? Y/N\n")
	if aux == "Y" or aux == "y":
		generateAllOutputFiles()
		unittest.main(verbosity = 2)
	
	


class MyTest(unittest.TestCase):


	def test_compare_ffts_calculations(self):
		os.chdir("Testing")
		for filee in os.listdir("."):
			index = filee.find("input")
			if index != -1:
				print("Unit testing for file = {}".format(filee))
				if filee.find("split") != -1:
					res = myFFTCalculation(filee, 1)
				else:
					res = myFFTCalculation(filee)
				fileOutName = filee.replace("input", "output")
				fileCheckResult = open(fileOutName, "r")
				line = fileCheckResult.readline()
				listOutput = line.split(", ")
				self.assertEqual(len(listOutput), len(res))
				for i, elem in enumerate(listOutput):
					a1 = complex(elem)
					a2 = complex(res[i])
					re1 = a1.real 
					re2 = a2.real
					im1 = a1.imag
					im2 = a2.imag
					maxRe = max(re1, re2)
					minRe = min(re1, re2)
					maxIm = max(im1, im2)
					minIm = min(im1, im2)
					fail = 0
					if maxRe - minRe > 0.0001:
						fail = 1
					if maxIm - minIm > 0.0001:
						fail = 1
					self.assertEqual(fail, 0)
				fileCheckResult.close()
				print("\tUnit testing for file = {} - ALL OK".format(filee))
		os.chdir("..")
		


"""for a input file returns the list with the output
if split != 0, the FFT will be calculated via a split method"""
def myFFTCalculation(inFileName, split = 0):
	fileIn = open(inFileName, "r")

	line = fileIn.readline()
	listInput = line.split(", ")
	listInputFloats = []
	for i, elem in enumerate(listInput): # convert the list to floats
		listInputFloats.append(float(elem))	
	if split != 0:
		res = FFT_split(listInputFloats)
	else:
		res = FFT(listInputFloats)

	fileIn.close()
	return res
	


"""generate all the output files required for the problem"""
def generateAllOutputFiles():
	os.chdir("Testing")

	fileList = os.listdir(".") # get all the files in the current directeory
	for filee in fileList:
		generateOutputFile(filee)

	os.chdir("..")

"""generate the correspinding output file(for example "output_data-16-1.csv" for the file "input_data-16-1.csv")"""
def generateOutputFile(inputFileName):
	fileIn = open(inputFileName, "r")
	fileOutName = "output" + inputFileName[inputFileName.find("_"):]
	fileOut = open(fileOutName, "w")
	
	line = fileIn.readline()
	listInput = line.split(", ")
	listInputFloats = []
	for i, elem in enumerate(listInput): # convert the list to floats
		listInputFloats.append(float(elem))
	fftResult = numpy.fft.fft(listInputFloats)
	for i, elem in enumerate(fftResult):
		if i == (len(fftResult) - 1): # do not print a ',' after the last randomly generated nubmer
			fileOut.write("{}".format(elem))
		else:
			fileOut.write("{}, ".format(elem))

	fileIn.close()
	fileOut.close()

"""generate all the input files required for the problem"""
def generateAllInputFiles():
	os.chdir("Testing")
	generateInputFile(8)
	generateInputFile(16)
	generateInputFile(32)
	generateInputFile(64)
	generateInputFile(128)
	generateInputFile(16, 1)
	generateInputFile(32, 1)
	generateInputFile(64, 1)
	generateInputFile(128, 1)
	os.chdir("..")

"""generate 2 input files with random numbers with the specified length"""
def generateInputFile(length, split = 0):
	if split != 0:
		fileName1 = "input_data-" + str(length) + "-split-1.csv"
		fileName2 = "input_data-" + str(length) + "-split-2.csv"
	else:
		fileName1 = "input_data-" + str(length) + "-1.csv"
		fileName2 = "input_data-" + str(length) + "-2.csv"
	file1 = open(fileName1, "w")
	file2 = open(fileName2, "w")

	array1 = numpy.random.random(length)
	array2 = numpy.random.random(length)
	for i, elem in enumerate(array1):
		if i == (len(array1) - 1): # do not print a ',' after the last randomly generated nubmer
			file1.write("{}".format(elem))
		else:
			file1.write("{}, ".format(elem))
	for i, elem in enumerate(array2):
		if i == (len(array2) - 1): # do not print a ',' after the last randomly generated nubmer
			file2.write("{}".format(elem))
		else:
			file2.write("{}, ".format(elem))

	file1.close()
	file2.close()
	




"""
Discrete Fourier transform(matrix-vector multiplication)
"""
def DFT(dataIn):

    x = numpy.asarray(dataIn, dtype=float)
    N = x.shape[0]
    n = numpy.arange(N)
    k = n.reshape((N, 1))
    M = numpy.exp(-2j * numpy.pi * k * n / N)
    result = numpy.dot(M, x)
    return result

"""A recursive implementation of the 1D Cooley-Tukey FFT"""
def FFT(x):
    x = numpy.asarray(x, dtype=float)
    N = x.shape[0]
    if N % 2 > 0:
        raise ValueError("size of x must be a power of 2")
    elif N <= 16:
        return DFT(x)
    else:
        X_even = FFT(x[::2])
        X_odd = FFT(x[1::2])
        factor = numpy.exp(-2j * numpy.pi * numpy.arange(N) / N)
        return numpy.concatenate([X_even + factor[:N / 2] * X_odd,
                               X_even + factor[N / 2:] * X_odd])
							   
def omega(p, q):
    return cmath.exp((2.0 * cmath.pi * 1j * q) / p)

def FFT_split(dataIn):
    n = len(dataIn)
    if n == 1:
        return dataIn
    else:
        Feven = FFT([dataIn[i] for i in xrange(0, n, 2)])
        Fodd = FFT([dataIn[i] for i in xrange(1, n, 2)])
        
        combined = [0] * n
        for m in xrange(n/2):
            combined[m] = Feven[m] + omega(n, -m) * Fodd[m]
            combined[m + n/2] = Feven[m] - omega(n, -m) * Fodd[m]
            
        return combined


if __name__ == "__main__":
	main()