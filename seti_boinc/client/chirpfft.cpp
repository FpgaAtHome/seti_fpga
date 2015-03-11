// Copyright 2003 Regents of the University of California

// SETI_BOINC is free software; you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free
// Software Foundation; either version 2, or (at your option) any later
// version.

// SETI_BOINC is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
// FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
// more details.

// In addition, as a special exception, the Regents of the University of
// California give permission to link the code of this program with libraries
// that provide specific optimized fast Fourier transform (FFT) functions and
// distribute a linked executable.  You must obey the GNU General Public
// License in all respects for all of the code used other than the FFT library
// itself.  Any modification required to support these libraries must be
// distributed in source code form.  If you modify this file, you may extend
// this exception to your version of the file, but you are not obligated to
// do so. If you do not wish to do so, delete this exception statement from
// your version.

// You should have received a copy of the GNU General Public License along
// with SETI_BOINC; see the file COPYING.  If not, write to the Free Software
// Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.


#include "sah_config.h"

#include <cstdio>
#include <cstdlib>
#include <cmath>
#include <map>

#include "diagnostics.h"
#include "util.h"
#include "s_util.h"
#ifdef BOINC_APP_GRAPHICS
#include "sah_gfx_main.h"
#endif



#include "seti_header.h"
#include "seti.h"
#include "util.h"
#include "filesys.h"
#include "s_util.h"
#include "analyze.h"
#include "worker.h"
#include "lcgamm.h"
#include "chirpfft.h"
#ifdef __arm__
#include "vector/fp_arm.h"
#endif

sh_sint8_t num_gaussian_searches;
sh_sint8_t num_pulse_searches;
sh_sint8_t num_triplet_searches;

char * cfft_file = NULL;

size_t GenChirpFftPairs(
  ChirpFftPair_t ** ChirpFftPairs,
  double * MinChirpStep
) {
#ifdef USE_MANUAL_CALLSTACK
  call_stack.enter("GenChirpFftPairs()");
#endif 

  long i, j, max_fft_len;
  double CRate;
  double ChirpRes   = swi.analysis_cfg.chirp_resolution;
  double NumSamples = swi.nsamples;
  double WUDuration = (double)(swi.nsamples/swi.subband_sample_rate);
  double SlewRate=static_cast<double>(swi.angle_range)/WUDuration;
  long MaxGaussFFTLen=swi.nsamples/swi.analysis_cfg.gauss_pot_length;

  double BeamsPerWU = std::max(swi.true_angle_range/swi.beam_width,1.0);
  long MinPulseFFTLen=(long)ceil(swi.nsamples/(swi.analysis_cfg.pulse_max*BeamsPerWU*swi.analysis_cfg.pulse_beams));
  long MaxPulseFFTLen=
    std::min((unsigned long)(swi.nsamples/(swi.analysis_cfg.pulse_min*swi.analysis_cfg.pulse_beams*BeamsPerWU)),
             (unsigned long)swi.analysis_cfg.pulse_fft_max);

  //JWS: Adjustment to avoid Pulse finding for short PoT lengths which cannot
  // produce a reportable signal. The adjustment is not applied until after a
  // chirp/fft table entry has been generated using the original logic, otherwise
  // it could affect Spikes and Triplets too.
  long MaxPulseFFTLenAlt;
  if(MaxPulseFFTLen < swi.analysis_fft_lengths[0]) {
    // If motion is so extreme we already know there will be no pulsefinds, skip.
    MaxPulseFFTLenAlt = MaxPulseFFTLen;
  } else {
    // Find actual longest allowed FFT length
    for (i = swi.num_fft_lengths; i ; i--) {
      MaxPulseFFTLenAlt = swi.analysis_fft_lengths[i - 1];
      if (MaxPulseFFTLenAlt <= MaxPulseFFTLen) break;
    }
    // An ideal folded pulse PoT would have all power in one element, That won't ever
    // happen with real data, but simulation by putting all power into the first or second
    // element of the original PulsePoT makes all folded PoTs ideal. Under those conditions,
    // the shortest period tested at fold by 3 is seen as the best of the folded PoTs. Thus,
    // to check whether a particular PulsePotLen can or cannot produce a reportable pulse
    // the math for that fold level is used to determine if the threshold is low enough
    // that an ideal PoT would be reportable.
    while (MaxPulseFFTLenAlt > 1) {
      int PulsePotLen = (int)(((NumSamples / MaxPulseFFTLenAlt)  / (swi.analysis_cfg.pulse_beams*BeamsPerWU)) + 0.5);
      int di = (PulsePotLen / 2 + 1) / 2;
      float thresh = invert_lcgf((float)(-swi.analysis_cfg.pulse_thresh - log((float)di)), 3.0f, 0.0001f);
      if (thresh <= (float)PulsePotLen) break;
      if (i) MaxPulseFFTLenAlt = swi.analysis_fft_lengths[--i];
      else MaxPulseFFTLenAlt /= 2;
    }
  }

  long  NumLimits = (long)swi.analysis_cfg.chirps.size();
  double * ChirpSteps ;
  ChirpFftPair_t tmp;
  std::map<sh_sint8_t,ChirpFftPair_t> ChirpFftMap;

  // An arrays associated with the FFT length array.
  ChirpSteps      = (double *)calloc(swi.num_fft_lengths, sizeof(double));

  // Each FFT length has a (different) associated chirp step.
  CalcChirpSteps(ChirpSteps, MinChirpStep);

  // Lets simplify the logic for doing chirps by using the STL map
  // container for sorting.
  max_fft_len=swi.analysis_fft_lengths[swi.num_fft_lengths-1];
  for (i=0; i<NumLimits; i++) {
    for (j=0;j<swi.num_fft_lengths;j++) {
      CRate=0.0;
      // do we need to generate entries for this fft length?
      if  (swi.analysis_fft_lengths[j] & swi.analysis_cfg.chirps[i].fft_len_flags) {

        tmp.FftLen=swi.analysis_fft_lengths[j];
        // Are we going to fit gaussians at this chirpfft?
        tmp.GaussFit=((tmp.FftLen   <= MaxGaussFFTLen) &&
                      (SlewRate >= swi.analysis_cfg.pot_min_slew) &&
                      (SlewRate <= swi.analysis_cfg.pot_max_slew));
        tmp.PulseFind=0;
        while (CRate <=  swi.analysis_cfg.chirps[i].chirp_limit) {
          // Pulse find on alternate chirp rates when fitting Gaussians
          if  ((SlewRate >= swi.analysis_cfg.pot_min_slew) &&
               (SlewRate <= swi.analysis_cfg.pot_max_slew)) {
            tmp.PulseFind=!(tmp.PulseFind) && tmp.GaussFit
                          && (tmp.FftLen<=MaxPulseFFTLen)
                          && (tmp.FftLen>=MinPulseFFTLen);
            // else pulse find when our FFT liength is in range...
          } else {
            tmp.PulseFind=(tmp.FftLen<=MaxPulseFFTLen)
                          && (tmp.FftLen>=MinPulseFFTLen);
          }
          // Force all chirp rates to be a multiple of the minimum step.
          tmp.ChirpRate=
            (tmp.ChirpRateInd=(int32_t)floor(CRate/(*MinChirpStep)+0.5))
            *(*MinChirpStep);
          // Generate keys specifying the order of the chirps
          //   chirp_rate,sign,fft_length order...
          sh_sint8_t key=static_cast<sh_sint8_t>(floor(CRate/(*MinChirpStep)+0.5))*2;
          key*=max_fft_len*2;
          key+=tmp.FftLen;
          //JWS: Finally, reset PulseFind if a reportable pulse cannot be found.
          if (tmp.FftLen > MaxPulseFFTLenAlt) tmp.PulseFind=0;
          // Insert the positive chirp overwriting any existing with this
          // key value;
          ChirpFftMap[key]=tmp;
          //fprintf(stderr,"%f %d %f\n",CRate,tmp.ChirpRateInd,tmp.ChirpRate);
          //fflush(stderr);
          // Now the negative chirps for non-zero chirp;
          if (CRate != 0.0) {
            tmp.ChirpRate*=-1;
            tmp.ChirpRateInd*=-1;
            key+=max_fft_len*2; // flip the bit representing the sign in the
            // key
            ChirpFftMap[key]=tmp;
          }
          CRate+=ChirpSteps[j];
        } // end while loop through chirp rates
      } // end if
    } // end for loop through fft lenngths
  } // end for loop through cfft parameter table


  // Copy our ordereds CFFT map into a more standard array
  *ChirpFftPairs = (ChirpFftPair_t *)calloc(ChirpFftMap.size(),sizeof(ChirpFftPair_t));
  std::map<sh_sint8_t,ChirpFftPair_t>::const_iterator p;
  i=0;
  for (p=ChirpFftMap.begin();p!=ChirpFftMap.end();p++) {
    num_gaussian_searches+=(p->second.GaussFit*(p->second.FftLen-1));
    num_pulse_searches+=(sh_sint8_t)(p->second.PulseFind*(p->second.FftLen-1)*(NumSamples/p->second.FftLen)*log((double)NumSamples/p->second.FftLen)/log(2.0));
    num_triplet_searches+=(sh_sint8_t)(p->second.PulseFind*(p->second.FftLen-1)*(NumSamples/p->second.FftLen)*(NumSamples/p->second.FftLen));
    (*ChirpFftPairs)[i++]=p->second;
  }
  /*
  fprintf(
    stderr,"NumCfft=%d\n NumGauss="SINT8_FMT"\n NumPulse="SINT8_FMT"\n NumTriplet="SINT8_FMT"\n",
    static_cast<int>(ChirpFftMap.size()),
    SINT8_FMT_CAST(num_gaussian_searches),
    SINT8_FMT_CAST(num_pulse_searches),
    SINT8_FMT_CAST(num_triplet_searches)
  );
  */
  fflush(stderr);

  if (ChirpSteps) free (ChirpSteps);
#ifdef USE_MANUAL_CALLSTACK
  call_stack.exit();
#endif 
  return(ChirpFftMap.size());
}


void CalcChirpSteps(double*  ChirpSteps, double* MinChirpStep) {
#ifdef USE_MANUAL_CALLSTACK
  call_stack.enter("CalcChirpSteps()");
#endif 
  double ChirpRes   = swi.analysis_cfg.chirp_resolution;
  double NumSamples = swi.nsamples;
  double WUDuration = (double)(swi.nsamples/swi.subband_sample_rate);


  int i;
  double SecondsInAnalysis;
  double SlewRate=static_cast<double>(swi.angle_range)/WUDuration;
  long FftLen;
  long MaxGaussFFTLen=swi.nsamples/swi.analysis_cfg.gauss_pot_length;
  double BeamsPerWU = std::max(swi.true_angle_range/swi.beam_width,1.0);
  long MinPulseFFTLen=(long)ceil(swi.nsamples/(swi.analysis_cfg.pulse_max*BeamsPerWU*swi.analysis_cfg.pulse_beams));
  long MaxPulseFFTLen=
    std::min((unsigned long)(swi.nsamples/(swi.analysis_cfg.pulse_min*swi.analysis_cfg.pulse_beams*BeamsPerWU)),
             (unsigned long)swi.analysis_cfg.pulse_fft_max);
  long MaxTripletFFTLen=swi.nsamples/swi.analysis_cfg.triplet_min;
  double SecondsInBeam = WUDuration/swi.true_angle_range*swi.beam_width;

  // For each FFT length, calculate the corresponding chirp
  // step (in Hz/s), given the chirp resolution (in FFT bins).
  // Keep track of the minimum chirp step.

  // The goal here is to have the drift be less than 1 bin over the
  // duration of interest to the analysis.  In the case of gaussians
  // that duration is 2 beam crossings.  In the case of pulses it's
  // one beam crossing.  In the case of spikes it's one fft length.
  *MinChirpStep = 0.0;
  for(i = 0; i < swi.num_fft_lengths; i++) {
    FftLen = swi.analysis_fft_lengths[i];
    double SecondsInFFT =  WUDuration / (NumSamples / FftLen);
    // Are we going to do Gaussians?
    if ((FftLen   <= MaxGaussFFTLen) &&
        (SlewRate >= swi.analysis_cfg.pot_min_slew) &&
        (SlewRate <= swi.analysis_cfg.pot_max_slew)) {
      SecondsInAnalysis = SecondsInBeam*2;
      // In not, are we going to do pulses or triplets?
    } else if ((FftLen<=MaxPulseFFTLen) && (FftLen<= MaxTripletFFTLen)) {
      // Look for pulses over one beam crossing or one beam crossing
      // at the pot_min_slew, whichever is lower.
      SecondsInAnalysis = std::min(SecondsInBeam,swi.beam_width/swi.analysis_cfg.pot_min_slew);
    } else {
      SecondsInAnalysis = SecondsInFFT;
    }
    ChirpSteps[i] = ChirpRes / (SecondsInAnalysis * SecondsInFFT);
    //fprintf(stderr,"%d %f\n",i,ChirpSteps[i]);
    //fflush(stderr);
    if(ChirpSteps[i] < *MinChirpStep || *MinChirpStep == 0.0) {
      *MinChirpStep = ChirpSteps[i];
    }
  }
#ifdef USE_MANUAL_CALLSTACK
  call_stack.exit();
#endif 
}


bool VeryClose(double a, double b, double CloseEnough) {
#ifdef USE_MANUAL_CALLSTACK
  call_stack.enter("VeryClose()");
#endif 
  double Diff;

  Diff = fabs(a - b);
#ifdef USE_MANUAL_CALLSTACK
  call_stack.exit();
#endif 
  if(Diff > CloseEnough)
    return(false);
  else
    return(true);
}


int ReadCFftFile(ChirpFftPair_t ** ChirpFftPairs, double * MinChirpStep) {
#ifdef USE_MANUAL_CALLSTACK
  call_stack.enter("ReadCFftFile()");
#endif 
  //  ChirpFftSet_t ChirpFftSet;
  ChirpFftPair_t * ChirpFftPair;
  int NumChirpFftPairs;
  FILE * cfftfp;
  double ChirpRate;
  int FftLen;

  NumChirpFftPairs = 0;

  cfftfp = boinc_fopen(cfft_file, "r");

  ChirpFftPair = (ChirpFftPair_t*) calloc(1,sizeof(ChirpFftPair_t));

  while(fscanf(cfftfp, "%lf %d", &ChirpRate, &FftLen) == 2) {
    ChirpFftPair = (ChirpFftPair_t *)realloc(
                     (void *)ChirpFftPair, sizeof(ChirpFftPair_t)*(NumChirpFftPairs+1));
    if (ChirpFftPair == NULL) SETIERROR(MALLOC_FAILED, "ChirpFftPair == NULL");
    ChirpFftPair[NumChirpFftPairs].ChirpRate = ChirpRate;
    ChirpFftPair[NumChirpFftPairs].FftLen    = FftLen;
    NumChirpFftPairs++;
  }

  *ChirpFftPairs = ChirpFftPair;
  *MinChirpStep  = (float) TEST_MIN_CHIRP_STEP;

  fclose(cfftfp);

#ifdef USE_MANUAL_CALLSTACK
  call_stack.exit();
#endif 
  return(NumChirpFftPairs);
}

