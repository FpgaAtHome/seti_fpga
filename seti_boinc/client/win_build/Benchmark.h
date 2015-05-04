
#ifndef _BENCHMARK_H_
#define _BENCHMARK_H_

#include <windows.h>

class Benchmark
{
public:
	Benchmark()
	{
		LARGE_INTEGER liFrequency;
		QueryPerformanceFrequency(&liFrequency);
		frequency = double(liFrequency.QuadPart)/1000.0;

		LARGE_INTEGER liStartTime;
		QueryPerformanceCounter(&liStartTime);
		startTime = liStartTime.QuadPart;
	}

	void stopTimer()
	{
		QueryPerformanceCounter(&stopTime);
	}

	double getTimeMs()
	{
		return double(stopTime.QuadPart - startTime) / frequency;
	}

private:
	double frequency;
	__int64 startTime;
	LARGE_INTEGER stopTime;
};

#endif