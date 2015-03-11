// Copyright 2003 Regents of the University of California

// SETI_BOINC is free software; you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free
// Software Foundation; either version 2, or (at your option) any later
// version.

// SETI_BOINC is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
// FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
// more details.

// You should have received a copy of the GNU General Public License along
// with SETI_BOINC; see the file COPYING.  If not, write to the Free Software
// Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

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

// $Id: analyzeFuncs_sse.cpp,v 1.1.2.10 2007/06/08 03:09:47 korpela Exp $
//

// This file is empty is __i386__ is not defined
#include "sah_config.h"
#include <vector>
#include <cmath>

#if defined(__arm__) && defined(__VFP_FP__) && !defined(__SOFTFP__)


#define INVALID_CHIRP 2e+20

#include "analyzeFuncs.h"
#include "analyzeFuncs_vector.h"
#include "analyzePoT.h"
#include "analyzeReport.h"
#include "gaussfit.h"
#include "s_util.h"
#include "diagnostics.h"
#include "asmlib.h"
#include "pulsefind.h"


// ARM prefetch

inline void pld(void *arg1,const int arg2=0) {
    __asm__ __volatile__ (
      "pld [%0,%1]\n"
      : 
      : "r" (arg1), "Jr" (arg2)
    );
}


    
template <int x>
inline void v_pfsubTranspose(float *in, float *out, int xline, int yline) {
    // Transpose an X by X subsection of a XLINE by YLINE matrix into the
    // appropriate part of a YLINE by XLINE matrix.  "IN" points to the first
    // (lowest address) element of the input submatrix.  "OUT" points to the
    // first (lowest address) element of the output submatrix.
#ifdef USE_MANUAL_CALLSTACK
    static char name[64];
    if (name[0]==0) sprintf(name,"v_pfsubTranspose<%d>()",x);
    call_stack.enter(name);
#endif
    int i,j;
    float *p;
    register float tmp[x*x];
    for (j=0;j<x;j++) {
        p=in+j*xline;
        pld(out+j*yline);
        for (i=0;i<x;i++) {
            tmp[j+i*x]=*(p++);
        }
    }
    for (j=0;j<x;j++) {
        p=out+j*yline;
        for (i=0;i<x;i++) {
            *(p++)=tmp[i+j*x];
        }
        pld(in+j*xline+x);
    }
#ifdef USE_MANUAL_CALLSTACK
    call_stack.exit();
#endif
}

int v_pfTranspose2(int x, int y, float *in, float *out) {
// Attempts to improve cache hit ratio by transposing 4 elements at a time.
#ifdef USE_MANUAL_CALLSTACK
    call_stack.enter("v_pfTranspose2()");
#endif
    int i,j;
    for (j=0;j<y-1;j+=2) {
        for (i=0;i<x-1;i+=2) {
            v_pfsubTranspose<2>(in+j*x+i,out+y*i+j,x,y);
        }
        for (;i<x;i++) {
            out[i*y+j]=in[j*x+i];
        }
    }
    for (;j<y;j++) {
        for (i=0;i<x;i++) {
            out[i*y+j]=in[j*x+i];
        }
    }
#ifdef USE_MANUAL_CALLSTACK
    call_stack.exit();
#endif
    return 0;
}

int v_pfTranspose4(int x, int y, float *in, float *out) {
// Attempts to improve cache hit ratio by transposing 16 elements at a time.
#ifdef USE_MANUAL_CALLSTACK
    call_stack.enter("v_pfTranspose4()");
#endif
    int i,j;
    for (j=0;j<y-3;j+=4) {
        for (i=0;i<x-3;i+=4) {
            v_pfsubTranspose<4>(in+j*x+i,out+y*i+j,x,y);
        }
        for (;i<x-1;i+=2) {
            v_pfsubTranspose<2>(in+j*x+i,out+y*i+j,x,y);
        }
        for (;i<x;i++) {
            out[i*y+j]=in[j*x+i];
        }
    }
    for (;j<y-1;j+=2) {
        for (i=0;i<x-1;i+=2) {
            v_pfsubTranspose<2>(in+j*x+i,out+y*i+j,x,y);
        }
        for (;i<x;i++) {
            out[i*y+j]=in[j*x+i];
        }
    }
    for (;j<y;j++) {
        for (i=0;i<x;i++) {
            out[i*y+j]=in[j*x+i];
        }
    }
#ifdef USE_MANUAL_CALLSTACK
    call_stack.exit();
#endif
    return 0;
}

int v_pfTranspose8(int x, int y, float *in, float *out) {
// Attempts to improve cache hit ratio by transposing 64 elements at a time.
#ifdef USE_MANUAL_CALLSTACK
    call_stack.enter("v_pfTranspose8()");
#endif
    int i,j;
    for (j=0;j<y-7;j+=8) {
        for (i=0;i<x-7;i+=8) {
            v_pfsubTranspose<8>(in+j*x+i,out+y*i+j,x,y);
        }
        for (;i<x-3;i+=4) {
            v_pfsubTranspose<4>(in+j*x+i,out+y*i+j,x,y);
        }
        for (;i<x-1;i+=2) {
            v_pfsubTranspose<2>(in+j*x+i,out+y*i+j,x,y);
        }
        for (;i<x;i++) {
            out[i*y+j]=in[j*x+i];
        }
    }
    for (j=0;j<y-3;j+=4) {
        for (i=0;i<x-3;i+=4) {
            v_pfsubTranspose<4>(in+j*x+i,out+y*i+j,x,y);
        }
        for (;i<x-1;i+=2) {
            v_pfsubTranspose<2>(in+j*x+i,out+y*i+j,x,y);
        }
        for (;i<x;i++) {
            out[i*y+j]=in[j*x+i];
        }
    }
    for (;j<y-1;j+=2) {
        for (i=0;i<x-1;i+=2) {
            v_pfsubTranspose<2>(in+j*x+i,out+y*i+j,x,y);
        }
        for (;i<x;i++) {
            out[i*y+j]=in[j*x+i];
        }
    }
    for (;j<y;j++) {
        for (i=0;i<x;i++) {
            out[i*y+j]=in[j*x+i];
        }
    }
#ifdef USE_MANUAL_CALLSTACK
    call_stack.exit();
#endif
    return 0;
}

static inline int vfp_subTranspose2(int x, int y, float *in, float *out) {
// Attempts to improve cache hit ratio by transposing 4 elements at a time.
#ifdef USE_MANUAL_CALLSTACK
    call_stack.enter("vfp_subTranspose2()");
#endif
    __asm__ __volatile__ (
        "fldmias  %2, {s4, s5}\n"
        "fldmias  %3, {s6, s7}\n"
        "vmov.f32 s3,s6\n"
        "vmov.f32 s6,s5\n"
        "vmov.f32 s5,s3\n"
        "fstmias  %0, {s4, s5}\n"
        "fstmias  %1, {s6, s7}\n"
    :  
    : "r" (out), "r" (out+y), "r" (in), "r" (in+x)
    : "s3", "s4", "s5", "s6", "s7" );
#ifdef USE_MANUAL_CALLSTACK
    call_stack.exit();
#endif
    return 0;
}
        
int v_vfpTranspose2(int x, int y, float *in, float *out) {
// Attempts to improve cache hit ratio by transposing 4 elements at a time.
#ifdef USE_MANUAL_CALLSTACK
    call_stack.enter("vfp_Transpose2()");
#endif
    int i,j;
    for (j=0;j<y-1;j+=2) {
        for (i=0;i<x-1;i+=2) {
            vfp_subTranspose2(x,y,in+j*x+i,out+y*i+j);
        }
        for (;i<x;i++) {
            out[i*y+j]=in[j*x+i];
        }
    }
    for (;j<y;j++) {
        for (i=0;i<x;i++) {
            out[i*y+j]=in[j*x+i];
        }
    }
#ifdef USE_MANUAL_CALLSTACK
    call_stack.exit();
#endif
    return 0;
}





#endif // (__arm__) 


