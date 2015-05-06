#!/usr/bin/python

import cmath

def omega(p, q):
	return cmath.exp((2.0 * cmath.pi * 1j * q) / p)

def fft(signal):
	n = len(signal)
	if n == 1:
		return signal
	else:
		Feven = fft([signal[i] for i in xrange(0, n, 2)])
		Fodd = fft([signal[i] for i in xrange(1, n, 2)])

		combined = [0] * n
		for m in xrange(n/2):
			combined[m] = Feven[m] + omega(n, -m) * Fodd[m]
			combined[m + n/2] = Feven[m] - omega(n, -m) * Fodd[m]
		return combined

def calc_fft(in_range):
	print "The FFT for: " + str(in_range) + " is:"
	print "\t" + str(fft(in_range))

calc_fft([1,0,0,0])
calc_fft([0,1,0,0])
calc_fft([1, 1, 1, 1, 0, 0, 0, 0])
