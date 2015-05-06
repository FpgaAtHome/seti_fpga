
#ifndef TYPES_DEF_H
#define TYPES_DEF_H

// Variable (usually an array of such
// variables) to hold chirp/fft pairs.
typedef struct {
  double  ChirpRate;
  int   ChirpRateInd; // chirprate index (= ChirpRate / MinChirpStep)
  int   FftLen;
  int	GaussFit;
  int 	PulseFind;
}
ChirpFftPair_t;

typedef float sah_complex[2];

#endif