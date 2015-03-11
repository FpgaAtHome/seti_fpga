// Copyright (c) 1999-2013 Regents of the University of California
//
// FFTW: Copyright (c) 2003,2006 Matteo Frigo
//       Copyright (c) 2003,2006 Massachusets Institute of Technology
//
// fft8g.[cpp,h]: Copyright (c) 1995-2001 Takya Ooura
//
// ASMLIB: Copyright (c) 2004 Agner Fog

// This program is free software; you can redistribute it and/or modify it 
// under the terms of the GNU General Public License as published by the 
// Free Software Foundation; either version 2, or (at your option) any later
// version.

// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
// FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
// more details.

// You should have received a copy of the GNU General Public License along
// with this program; see the file COPYING.  If not, write to the Free Software
// Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

// In addition, as a special exception, the Regents of the University of
// California give permission to link the code of this program with libraries
// that provide specific optimized fast Fourier transform (FFT) functions
// as an alternative to FFTW and distribute a linked executable and 
// source code.  You must obey the GNU General Public License in all 
// respects for all of the code used other than the FFT library itself.  
// Any modification required to support these libraries must be distributed 
// under the terms of this license.  If you modify this program, you may extend 
// this exception to your version of the program, but you are not obligated to 
// do so. If you do not wish to do so, delete this exception statement from 
// your version.  Please be aware that FFTW and ASMLIB are not covered by 
// this exception, therefore you may not use FFTW and ASMLIB in any derivative 
// work so modified without permission of the authors of those packages.
//

#if defined(__arm__) && !defined(_RC_CHOP)
#include <signal.h>
#include <setjmp.h>
#include "s_util.h"
#include "sighandler.h"

// Exception masks
#define _EM_INVALID     0x00000100      // Invalid Operation
#define _EM_ZERODIVIDE  0x00000200      // Divide by zero
#define _EM_OVERFLOW    0x00000400      // Overflow
#define _EM_UNDERFLOW   0x00000800      // Underflow
#define _EM_INEXACT     0x00001000      // Inexact result
#define _EM_DENORMAL    0x00008000      // Denormal result
#define _MCW_EM (_EM_INVALID|_EM_ZERODIVIDE|_EM_OVERFLOW|_EM_UNDERFLOW|_EM_INEXACT|_EM_DENORMAL)

// Rounding control
#define _RC_CHOP        0x000c0000      // Truncate
#define _RC_DOWN        0x00080000      // Round down
#define _RC_UP          0x00040000      // Round up
#define _RC_NEAREST     0x00000000      // Round to nearest
#define _MCW_RC (_RC_CHOP|_RC_UP|_RC_DOWN|_RC_NEAREST)

#define _NAN_DEFAULT    0x00200000      // Use default NaN rather than propogating NaN
#define _MCW_NAN _NAN_DEFAULT  

#define _FLUSH_TO_ZERO  0x00100000      // Replaces denormalized numbers with zero
#define _MCW_FLUSH_TO_ZERO _FLUSH_TO_ZERO

#if 0
These VFP vector mode has been deprecated
#define _VECTOR_LEN(x) ((((x)-1)&7)<<16)  // Set length of vectors to x 
#define _MCW_VECTOR_LEN_MASK _VECTOR_LEN(8)

#define _VECTOR_STRIDE(x) (((x)==2)?(3<<20):0)
#define _MCW_VECTOR_STRIDE_MASK (3<<20)
#endif

static unsigned int save_cw;
static unsigned int cw;

inline static unsigned int controlfp(unsigned int flags, unsigned int mask) {
    install_sighandler();
    FORCE_FRAME_POINTER;
    if (sigsetjmp(jb,1))  {
        uninstall_sighandler();
        cw=0;
        save_cw=0;
        fprintf(stderr,"User mode control of fp control register not allowed\n");
    } else {
#if defined(__VFP_FP__) && !defined(__SOFTFP__)
        __asm__ __volatile__ (
          "fmrx %0,fpscr\n"
          : "=r" (cw)
        );
#endif

        save_cw=cw;
        cw=(cw & ~mask) | (flags & mask);

#if defined(__VFP_FP__) && !defined(__SOFTFP__)
        __asm__ __volatile__ (
          "fmxr fpscr,%0\n"
          : : "r" (cw)
        );
#endif
        uninstall_sighandler();
    }
    return cw;
}

inline static unsigned int restorefp() {
    if (save_cw != 0) {
#if defined(__VFP_FP__) && !defined(__SOFTFP__)
        __asm__ __volatile__ (
          "fmxr fpscr,%0\n"
          : : "r" (save_cw)
        );
#else
        cw=save_cw;
#endif
    }
    return save_cw;
}

#if 0
static const uint64_t arm_TWO_TO_52(0x4330000000000000);
static const uint64_t arm_SIGN_BIT(0x8000000000000000);
static const uint32_t arm_TWO_TO_23(0x4b000000);
static const uint32_t arm_FSIGN_BIT(0x80000000);

#if defined(__VFP_FP__) && !defined(__SOFTFP__)

inline static double arm_round(double x) {
    register uint64_t s=*reinterpret_cast<uint64_t *>(&x) & arm_SIGN_BIT;
    uint64_t a=s | arm_TWO_TO_52;
    volatile register double d=*reinterpret_cast<double *>(&a);
    return (x+d)-d;
}

inline static float arm_round(float x) {
    register uint32_t s=*reinterpret_cast<uint32_t *>(&x) & arm_FSIGN_BIT;
    uint32_t a=s | arm_TWO_TO_23;
    volatile register float d=*reinterpret_cast<float *>(&a);
    return (x+d)-d;
}

#define round(x) arm_round(x)

inline static double arm_floor(double x) {
    return round(x-0.5);
}

inline static float arm_floor(float x) {
    return round(x-0.5f);
}

#define floor(x) arm_floor(x)
#endif

#endif
#endif

