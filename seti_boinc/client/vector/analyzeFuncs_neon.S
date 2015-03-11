// Copyright (c) 1999-2011 Regents of the University of California
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

#ifdef __arm__
/*
 * vfp_ChirpData.S
 * Author: Mateusz Szpakowski
 */
 
                .arch armv7-a
                .fpu neon
                .eabi_attribute 20, 1
                .eabi_attribute 21, 1
                .eabi_attribute 23, 3
                .eabi_attribute 24, 1
                .eabi_attribute 25, 1
                .eabi_attribute 26, 2
                .eabi_attribute 30, 2
                .eabi_attribute 18, 4
                .text
                .align  2
.Lhalfd:
                .double 0.5
.LroundVal:
                .double 4503599627370496.0
                .align 4
.Linc8d:
                .double 0,1,2,3,4,5,6,7
.Lsinapprox:
                .float 1.5707963268,1.5707963268,1.5707963268,1.5707963268
                .float -0.6466386396,-0.6466386396,-0.6466386396,-0.6466386396
                .float 0.0679105987,0.0679105987,0.0679105987,0.0679105987
                .float -0.0011573807,-0.0011573807,-0.0011573807,-0.0011573807
.Lcosapprox:
                .float 1.0,1.0,1.0,1.0
                .float -1.2341299769,-1.2341299769,-1.2341299769,-1.2341299769
                .float 0.2465220241,0.2465220241,0.2465220241,0.2465220241
                .float -0.0123926179,-0.0123926179,-0.0123926179,-0.0123926179
.Ltwosq:
                .float 2.0,2.0,2.0,2.0
                .float 2.0,2.0,2.0,2.0
                .float 2.0,2.0,2.0,2.0
                .float 2.0,2.0,2.0,2.0
                
                .align  2
                .global _Z14neon_ChirpDataPA2_fS0_idid
                .type   _Z14neon_ChirpDataPA2_fS0_idid, %function
_Z14neon_ChirpDataPA2_fS0_idid:
                push {r4,r5,r6,r7,r8,r9,r10,r11,r12,lr}
                vpush {d8,d9,d10,d11,d12,d13,d14,d15}
#define stargidx (40+64)
                /* r0 - input data
                 * r1 - output data
                 * r2 - chirprateind
                 * sp[0-1] - chirp_rate
                 * sp[2] - numDataPoints
                 * sp[4-5] - sample_rate
                 */
                tst r2,r2
                bne .Lrealfunc
                mov r3,r0   // swap addresses
                mov r0,r1
                mov r1,r3
                ldr r2,[sp,#stargidx+8]     // numDataPoints
                lsl r2,r2,#3
                bl memcpy(PLT)
                b .Lendoffunc
                /*
                 * real functions
                 */
.Lrealfunc:
                ldr r4,.LGOT1
.LPIC1:
                add r4,pc,r4
                ldr r5,.LGOT1+4
                ldr r5,[r4,r5]
                
                ldr r3,[sp,#stargidx+8]     // numDataPoints
                
                add r6,r3,r3,lsl #1
                lsl r6,r6,#2
                fldd d0,[r5,#32]
                fmsr s4,r6
                fuitod d1,s4
                faddd d0,d0,d1
                fstd d0,[r5,#32]
                
                add r3,r0,r3,lsl #3
                sub r3,r3,#8*15
                
                fldd d11,.Lhalfd
                fldd d9,[sp,#stargidx]        // chirp_rate
                fldd d10,[sp,#stargidx+16]   // sample_rate
                fmuld d10,d10,d10
                fmuld d9,d9,d11
                fdivd d9,d9,d10
                
                fldd d10,.LroundVal
                fsubd d11,d11,d11   // zero
                fcmpd d9,d11
                fmstat
                fnegdmi d10,d10     // negate is negative srate
                
                sub sp,sp,#16+64
                add r7,sp,#16
                add r11,sp,#16+32
                fstmiad sp,{d9,d10}
                
                mov r4,#0       // i
                
                adr r5,.Linc8d
                adr r6,.Lsinapprox
                adr r10,.Lcosapprox
                adr r9,.Ltwosq
                
                cmp r0,r3
                bhs .Lendmainloop
.Lmainloop:
                add r8,r4,#8
                fmsr s8,r4
                fmsr s9,r8
                fuitod d0,s8
                fuitod d1,s9
                fldmiad r5,{d8,d9,d10,d11,d12,d13,d14,d15}
                fldmiad sp,{d2,d3}
                faddd d16,d8,d0
                faddd d17,d9,d0
                faddd d18,d10,d0
                faddd d19,d11,d0
                faddd d20,d12,d0
                faddd d21,d13,d0
                faddd d22,d14,d0
                faddd d23,d15,d0
                faddd d24,d8,d1
                faddd d25,d9,d1
                faddd d26,d10,d1
                faddd d27,d11,d1
                faddd d28,d12,d1
                faddd d29,d13,d1
                faddd d30,d14,d1
                faddd d31,d15,d1
                // square of i
                fmuld d16,d16,d16
                fmuld d17,d17,d17
                fmuld d18,d18,d18
                fmuld d19,d19,d19
                fmuld d20,d20,d20
                fmuld d21,d21,d21
                fmuld d22,d22,d22
                fmuld d23,d23,d23
                fmuld d24,d24,d24
                fmuld d25,d25,d25
                fmuld d26,d26,d26
                fmuld d27,d27,d27
                fmuld d28,d28,d28
                fmuld d29,d29,d29
                fmuld d30,d30,d30
                fmuld d31,d31,d31
                // multiply by srate
                fmuld d16,d16,d2
                fmuld d17,d17,d2
                fmuld d18,d18,d2
                fmuld d19,d19,d2
                fmuld d20,d20,d2
                fmuld d21,d21,d2
                fmuld d22,d22,d2
                fmuld d23,d23,d2
                fmuld d24,d24,d2
                fmuld d25,d25,d2
                fmuld d26,d26,d2
                fmuld d27,d27,d2
                fmuld d28,d28,d2
                fmuld d29,d29,d2
                fmuld d30,d30,d2
                fmuld d31,d31,d2
                
                // rounding to -0.5/+0.5
                faddd d8,d16,d3
                faddd d9,d17,d3
                faddd d10,d18,d3
                faddd d11,d19,d3
                faddd d12,d20,d3
                faddd d13,d21,d3
                faddd d14,d22,d3
                faddd d15,d23,d3
                fsubd d8,d8,d3
                fsubd d9,d9,d3
                fsubd d10,d10,d3
                fsubd d11,d11,d3
                fsubd d12,d12,d3
                fsubd d13,d13,d3
                fsubd d14,d14,d3
                fsubd d15,d15,d3
                fsubd d16,d16,d8
                fsubd d17,d17,d9
                fsubd d18,d18,d10
                fsubd d19,d19,d11
                fsubd d20,d20,d12
                fsubd d21,d21,d13
                fsubd d22,d22,d14
                fsubd d23,d23,d15
                
                faddd d8,d24,d3
                faddd d9,d25,d3
                faddd d10,d26,d3
                faddd d11,d27,d3
                faddd d12,d28,d3
                faddd d13,d29,d3
                faddd d14,d30,d3
                faddd d15,d31,d3
                fsubd d8,d8,d3
                fsubd d9,d9,d3
                fsubd d10,d10,d3
                fsubd d11,d11,d3
                fsubd d12,d12,d3
                fsubd d13,d13,d3
                fsubd d14,d14,d3
                fsubd d15,d15,d3
                fsubd d24,d24,d8
                fsubd d25,d25,d9
                fsubd d26,d26,d10
                fsubd d27,d27,d11
                fsubd d28,d28,d12
                fsubd d29,d29,d13
                fsubd d30,d30,d14
                fsubd d31,d31,d15
                // to single precision
                fcvtsd s0,d16
                fcvtsd s1,d17
                fcvtsd s2,d18
                fcvtsd s3,d19
                fcvtsd s4,d20
                fcvtsd s5,d21
                fcvtsd s6,d22
                fcvtsd s7,d23
                fcvtsd s8,d24
                fcvtsd s9,d25
                fcvtsd s10,d26
                fcvtsd s11,d27
                fcvtsd s12,d28
                fcvtsd s13,d29
                fcvtsd s14,d30
                fcvtsd s15,d31
                
                //fldmias r6,{s8,s9,s10,s11,s12,s13,s14,s15}
                vldmia r6,{q8,q9,q10,q11}
                // square of y
                vmul.f32 q4,q0,q0
                vmul.f32 q5,q1,q1
                vmul.f32 q6,q2,q2
                vmul.f32 q7,q3,q3
                // sine
                vmul.f32 q12,q4,q11
                vmul.f32 q13,q5,q11
                vmul.f32 q14,q6,q11
                vmul.f32 q15,q7,q11
                vadd.f32 q12,q12,q10
                vadd.f32 q13,q13,q10
                vadd.f32 q14,q14,q10
                vadd.f32 q15,q15,q10
                vmul.f32 q12,q12,q4
                vmul.f32 q13,q13,q5
                vmul.f32 q14,q14,q6
                vmul.f32 q15,q15,q7
                vadd.f32 q12,q12,q9
                vadd.f32 q13,q13,q9
                vadd.f32 q14,q14,q9
                vadd.f32 q15,q15,q9
                vmul.f32 q12,q12,q4
                vmul.f32 q13,q13,q5
                vmul.f32 q14,q14,q6
                vmul.f32 q15,q15,q7
                vadd.f32 q12,q12,q8
                vadd.f32 q13,q13,q8
                vadd.f32 q14,q14,q8
                vadd.f32 q15,q15,q8
                vmul.f32 q12,q12,q0
                vmul.f32 q13,q13,q1
                vmul.f32 q14,q14,q2
                vmul.f32 q15,q15,q3
                vldmia r10,{q0,q1,q2,q3}
                // cosine
                vmul.f32 q8,q4,q3
                vmul.f32 q9,q5,q3
                vmul.f32 q10,q6,q3
                vmul.f32 q11,q7,q3
                vadd.f32 q8,q8,q2
                vadd.f32 q9,q9,q2
                vadd.f32 q10,q10,q2
                vadd.f32 q11,q11,q2
                vmul.f32 q8,q8,q4
                vmul.f32 q9,q9,q5
                vmul.f32 q10,q10,q6
                vmul.f32 q11,q11,q7
                vadd.f32 q8,q8,q1
                vadd.f32 q9,q9,q1
                vadd.f32 q10,q10,q1
                vadd.f32 q11,q11,q1
                vmul.f32 q8,q8,q4
                vmul.f32 q9,q9,q5
                vmul.f32 q10,q10,q6
                vmul.f32 q11,q11,q7
                vadd.f32 q8,q8,q0
                vadd.f32 q9,q9,q0
                vadd.f32 q10,q10,q0
                vadd.f32 q11,q11,q0
                // q8-q11 - cosine, q12-q15 - sine
                // doubling cosine/sine
                vmul.f32 q4,q8,q12      // c*s
                vmul.f32 q5,q9,q13
                vmul.f32 q6,q10,q14
                vmul.f32 q7,q11,q15
                vmul.f32 q0,q8,q8       // c*c
                vmul.f32 q1,q9,q9
                vmul.f32 q2,q10,q10
                vmul.f32 q3,q11,q11
                vmls.f32 q0,q12,q12    // c*c-s*s
                vmls.f32 q1,q13,q13
                vmls.f32 q2,q14,q14
                vmls.f32 q3,q15,q15
                vadd.f32 q4,q4,q4   // 2*c*s
                vadd.f32 q5,q5,q5
                vadd.f32 q6,q6,q6
                vadd.f32 q7,q7,q7
                // next doubling cosine/sine
                vmul.f32 q8,q0,q4      // cd1 = x*y
                vmul.f32 q9,q1,q5
                vmul.f32 q10,q2,q6
                vmul.f32 q11,q3,q7
                vmul.f32 q4,q4,q4    // cd3 = y*y
                vmul.f32 q5,q5,q5
                vmul.f32 q6,q6,q6
                vmul.f32 q7,q7,q7
                vmul.f32 q0,q0,q0    // cd2 = x*x
                vmul.f32 q1,q1,q1
                vmul.f32 q2,q2,q2
                vmul.f32 q3,q3,q3
                vadd.f32 q12,q0,q4  // norm = cd2+cd3
                vadd.f32 q13,q1,q5
                vadd.f32 q14,q2,q6
                vadd.f32 q15,q3,q7
                vadd.f32 q8,q8,q8   // s = cd1*2
                vadd.f32 q9,q9,q9
                vadd.f32 q10,q10,q10
                vadd.f32 q11,q11,q11
                vsub.f32 q0,q0,q4     // c = cd2-cd3
                vsub.f32 q1,q1,q5
                vsub.f32 q2,q2,q6
                vsub.f32 q3,q3,q7
                // c - q0-q3, s - q8-q11, norm - q12-q15
                vstmia r7,{q8,q9,q10,q11}
                vldmia r9,{q4,q5,q6,q7}
                // reciprocal of magnitude
                // iter 1: invmag = 2.0-mag
                vsub.f32 q4,q4,q12
                vsub.f32 q5,q5,q13
                vsub.f32 q6,q6,q14
                vsub.f32 q7,q7,q15
                // iter 2: invmag = invmag*(2.0-mag*invmag)
                vrecps.f32 q8,q4,q12
                vrecps.f32 q9,q5,q13
                vrecps.f32 q10,q6,q14
                vrecps.f32 q11,q7,q15
                vmul.f32 q4,q4,q8
                vmul.f32 q5,q5,q9
                vmul.f32 q6,q6,q10
                vmul.f32 q7,q7,q11
                vldmia r7,{q8,q9,q10,q11}
                // invnorm - q4-q7
                // correct cosine/sine
                vmul.f32 q0,q0,q4
                vmul.f32 q1,q1,q5
                vmul.f32 q2,q2,q6
                vmul.f32 q3,q3,q7
                vmul.f32 q8,q8,q4
                vmul.f32 q9,q9,q5
                vmul.f32 q10,q10,q6
                vmul.f32 q11,q11,q7
                vzip.32 q0,q8
                vzip.32 q1,q9
                vzip.32 q2,q10
                vzip.32 q3,q11
                vstmia r7,{q2,q3}
                vstmia r11,{q10,q11}
                // multiply by data
                pld [r0,#256]
                vldmia r0!,{q12,q13,q14,q15}
                vmul.f32 q4,q12,q0
                vmul.f32 q5,q13,q8
                vmul.f32 q6,q14,q1
                vmul.f32 q7,q15,q9
                vrev64.32 q2,q0
                vrev64.32 q10,q8
                vrev64.32 q3,q1
                vrev64.32 q11,q9
                vmul.f32 q2,q2,q12
                vmul.f32 q10,q10,q13
                vmul.f32 q3,q3,q14
                vmul.f32 q11,q11,q15
                fnegs s17,s17
                fnegs s19,s19
                fnegs s21,s21
                fnegs s23,s23
                fnegs s25,s25
                fnegs s27,s27
                fnegs s29,s29
                fnegs s31,s31
                vtrn.32 q4,q2
                vtrn.32 q5,q10
                vtrn.32 q6,q3
                vtrn.32 q7,q11
                vadd.f32 q4,q4,q2
                vadd.f32 q5,q5,q10
                vadd.f32 q6,q6,q3
                vadd.f32 q7,q7,q11
                vstmia r1!,{q4,q5,q6,q7}
                vldmia r7,{q0,q1}
                vldmia r11,{q8,q9}
                pld [r0,#256]
                vldmia r0!,{q12,q13,q14,q15}
                vmul.f32 q4,q12,q0
                vmul.f32 q5,q13,q8
                vmul.f32 q6,q14,q1
                vmul.f32 q7,q15,q9
                vrev64.32 q2,q0
                vrev64.32 q10,q8
                vrev64.32 q3,q1
                vrev64.32 q11,q9
                vmul.f32 q2,q2,q12
                vmul.f32 q10,q10,q13
                vmul.f32 q3,q3,q14
                vmul.f32 q11,q11,q15
                fnegs s17,s17
                fnegs s19,s19
                fnegs s21,s21
                fnegs s23,s23
                fnegs s25,s25
                fnegs s27,s27
                fnegs s29,s29
                fnegs s31,s31
                vtrn.32 q4,q2
                vtrn.32 q5,q10
                vtrn.32 q6,q3
                vtrn.32 q7,q11
                vadd.f32 q4,q4,q2
                vadd.f32 q5,q5,q10
                vadd.f32 q6,q6,q3
                vadd.f32 q7,q7,q11
                vstmia r1!,{q4,q5,q6,q7}
                
                add r4,r4,#16
                cmp r0,r3
                blo .Lmainloop
.Lendmainloop:
                add r3,r3,#8*15
                cmp r0,r3
                bhs .Lendsmallloop
                adr r6,.Lsincosapprox
.Lsmallloop:
                fmsr s24,r4
                fldmiad sp,{d9,d10}
                fuitod d0,s24
                // square of i
                fmuld d0,d0,d0
                // multiply by srate
                fmuld d0,d0,d9
                // rounding to -0.5/+0.5
                faddd d12,d0,d10
                fsubd d12,d12,d10
                fsubd d0,d0,d12
                fcvtsd s24,d0
                
                fldmias r6,{s8,s9,s10,s11,s12,s13,s14,s15}
                // square of y
                fmuls s0,s24,s24
                // sine/cosine
                fmuls s16,s0,s11
                fmuls s17,s0,s15
                fadds s16,s16,s10
                fadds s17,s17,s14
                fmuls s16,s16,s0
                fmuls s17,s17,s0
                fadds s16,s16,s9
                fadds s17,s17,s13
                fmuls s16,s16,s0
                fmuls s17,s17,s0
                fadds s16,s16,s8
                fadds s17,s17,s12   // s16 - sine
                fmuls s16,s16,s24   // s17 - cosine
                // doubling cosine/sine
                fmuls s18,s16,s17
                fmuls s19,s16,s16
                fmuls s20,s17,s17
                fadds s18,s18,s18  // y=2*s*c
                fsubs s19,s20,s19  // x=c*c-s*s
                fmuls s21,s18,s19  // cd1
                fmuls s22,s19,s19  // cd2
                fmuls s23,s18,s18  // cd3
                fsubs s8,s22,s23  // c
                fadds s9,s21,s21  // s
                // compute 1.0/norm
                fadds s10,s22,s23 // mag
                // reciprocal
                flds s11,.Ltwos
                // iter1: invmag = 2.0-mag
                fsubs s12,s11,s10
                // iter2: invmag = invmag*(2.0-invmag*mag)
                fmuls s13,s12,s10
                fsubs s13,s11,s13
                fmuls s12,s12,s13
                // iter3: invmag = invmag*(2.0-invmag*mag)
                fmuls s13,s12,s10
                fsubs s13,s11,s13
                fmuls s12,s12,s13
                // correct cosine/sine
                fmuls s8,s8,s12
                fmuls s9,s9,s12
                // multiply data
                fldmias r0!,{s14,s15}
                fmuls s6,s14,s8
                fmuls s7,s14,s9
                fnmacs s6,s15,s9
                fmacs s7,s15,s8
                fstmias r1!,{s6,s7}
                
                add r4,r4,#1
                cmp r0,r3
                blo .Lsmallloop
.Lendsmallloop:
                add sp,sp,#16+64
.Lendoffunc:
                mov r0,#0
                vpop {d8,d9,d10,d11,d12,d13,d14,d15}
                pop {r4,r5,r6,r7,r8,r9,r10,r11,r12,lr}
                bx lr
                
                .align  2
.LGOT1:
                .word _GLOBAL_OFFSET_TABLE_-(.LPIC1+8)
                .word analysis_state(GOT)
                .align 2
.Ltwos:
                .float 2.0
.Lsincosapprox:
                .float 1.5707963268,-0.6466386396,0.0679105987,-0.0011573807   // sine
                .float 1.0,-1.2341299769,0.2465220241,-0.0123926179     // cosine
/*
 * neon_FoldSubs.S
 * Author: Mateusz Szpakowski
 */
 
                .arch armv7-a
                .fpu neon
                .eabi_attribute 20, 1
                .eabi_attribute 21, 1
                .eabi_attribute 23, 3
                .eabi_attribute 24, 1
                .eabi_attribute 25, 1
                .eabi_attribute 26, 2
                .eabi_attribute 30, 2
                .eabi_attribute 18, 4
                .text
                .align  2
                /*****
                 * fold array by 3
                 ******/
                .global neon_foldArrayBy3_ll31
                .type neon_foldArrayBy3_ll31, %function
neon_foldArrayBy3_ll31:
                push {r4,r5,r6,lr}
                vpush {d8,d9,d10,d11,d12,d13,d14,d15}
                
                ldr r0,[r0] // ss0
                ldrd r2,[r1,#8] // tmp0
                add r2,r0,r2,lsl #2
                add r3,r0,r3,lsl #2
                ldrd r4,[r1]  // di,dest
                add r6,r0,r4,lsl #2 // end
                
                veor.i32 q12,q12,q12
                sub r6,r6,#4*15
                cmp r0,r6
                bhs .Lendf3loop1
.Lf3loop1:
.macro FOLDBY3_CORE
                vldmia r0!,{q0,q1,q2,q3}
                vldmia r2!,{q4,q5,q6,q7}
                vldmia r3!,{q8,q9,q10,q11}
                
                vadd.f32 q0,q0,q4
                vadd.f32 q1,q1,q5
                vadd.f32 q2,q2,q6
                vadd.f32 q3,q3,q7
                vadd.f32 q0,q0,q8
                vadd.f32 q1,q1,q9
                vadd.f32 q2,q2,q10
                vadd.f32 q3,q3,q11
                vstmia r5!,{q0,q1,q2,q3}
                
                vmax.f32 q13,q0,q1
                vmax.f32 q14,q2,q3
                vmax.f32 q12,q12,q13
                vmax.f32 q12,q12,q14
.endm
                FOLDBY3_CORE

                cmp r0,r6
                blo .Lf3loop1
.Lendf3loop1:
                and r4,r4,#15
                cmp r4,#8
                blo .Lf3lt8
                beq .Lf3eq8
                
                cmp r4,#12
                blo .Lf3lt12
                beq .Lf3eq12
                
                cmp r4,#14
                blo .Lf3lt14
                beq .Lf3eq14
                // 15 elems
                vldmia r0!,{q0,q1,q2}
                vldmia r0!,{s12,s13,s14}
                vldmia r2!,{q4,q5,q6}
                vldmia r2!,{s28,s29,s30}
                vldmia r3!,{q8,q9,q10}
                vldmia r3!,{d22}
                vldmia r3!, {s15}
                
                vadd.f32 q0,q0,q4
                vadd.f32 q1,q1,q5
                vadd.f32 q2,q2,q6
                vadd.f32 d6,d6,d14
                vadd.f32 s14,s14,s30
                vadd.f32 q0,q0,q8
                vadd.f32 q1,q1,q9
                vadd.f32 q2,q2,q10
                vadd.f32 d6,d6,d22
                vadd.f32 s14,s14,s15
                
                vstmia r5!,{q0,q1,q2}
                vstmia r5!,{s12,s13,s14}
                
                vmax.f32 q12,q12,q0
                vmax.f32 q12,q12,q1
                vmax.f32 q12,q12,q2
                vmax.f32 q12,q12,q3
                
                b .Lf3end
.Lf3eq14:
                // 14 elems
                vldmia r0!,{q0,q1,q2}
                vldmia r0!,{d6}
                vldmia r2!,{q4,q5,q6}
                vldmia r2!,{d14}
                vldmia r3!,{q8,q9,q10}
                vldmia r3!,{d22}
                
                vadd.f32 q0,q0,q4
                vadd.f32 q1,q1,q5
                vadd.f32 q2,q2,q6
                vadd.f32 d6,d6,d14
                vadd.f32 q0,q0,q8
                vadd.f32 q1,q1,q9
                vadd.f32 q2,q2,q10
                vadd.f32 d6,d6,d22
                vstmia r5!,{q0,q1,q2}
                vstmia r5!,{d6}
                
                vmax.f32 q12,q12,q0
                vmax.f32 q12,q12,q1
                vmax.f32 q12,q12,q2
                vmax.f32 d24,d24,d6
                
                b .Lf3end
.Lf3lt14:
                // 13 elems
                vldmia r0!,{q0,q1,q2}
                vldmia r0!,{s12}
                vldmia r2!,{q4,q5,q6}
                vldmia r2!,{s13}
                vldmia r3!,{q8,q9,q10}
                vldmia r3!,{s14}
                
                vadd.f32 q0,q0,q4
                vadd.f32 q1,q1,q5
                vadd.f32 q2,q2,q6
                fadds s12,s12,s13
                vadd.f32 q0,q0,q8
                vadd.f32 q1,q1,q9
                vadd.f32 q2,q2,q10
                fadds s12,s12,s14
                vstmia r5!,{q0,q1,q2}
                vstmia r5!,{s12}
                
                vmax.f32 q12,q12,q0
                vmax.f32 q12,q12,q1
                vmax.f32 q12,q12,q2
                vmax.f32 d24,d24,d6
                
                b .Lf3end
.Lf3eq12:
                // 12 elems
                vldmia r0!,{q0,q1,q2}
                vldmia r2!,{q4,q5,q6}
                vldmia r3!,{q8,q9,q10}
                
                vadd.f32 q0,q0,q4
                vadd.f32 q1,q1,q5
                vadd.f32 q2,q2,q6
                vadd.f32 q0,q0,q8
                vadd.f32 q1,q1,q9
                vadd.f32 q2,q2,q10
                vstmia r5!,{q0,q1,q2}
                
                vmax.f32 q12,q12,q0
                vmax.f32 q12,q12,q1
                vmax.f32 q12,q12,q2
                
                b .Lf3end
.Lf3lt12:
                cmp r4,#10
                blo .Lf3lt10
                beq .Lf3eq10
                // 11 elems
                vldmia r0!,{q0,q1}
                vldmia r0!,{s8,s9,s10}
                vldmia r2!,{q4,q5}
                vldmia r2!,{s24,s25,s26}
                vldmia r3!,{q8,q9}
                vldmia r3!,{d20}
                vldmia r3!,{s11}
                
                vadd.f32 q0,q0,q4
                vadd.f32 q1,q1,q5
                vadd.f32 d4,d4,d12
                vadd.f32 s10,s10,s26
                vadd.f32 q0,q0,q8
                vadd.f32 q1,q1,q9
                vadd.f32 d4,d4,d20
                vadd.f32 s10,s10,s11
                vstmia r5!,{q0,q1}
                vstmia r5!,{s8,s9,s10}
                
                vmax.f32 q12,q12,q0
                vmax.f32 q12,q12,q1
                vmax.f32 q12,q12,q2
                
                b .Lf3end
.Lf3eq10:
                // 10 elems
                vldmia r0!,{q0,q1}
                vldmia r0!,{d4}
                vldmia r2!,{q4,q5}
                vldmia r2!,{d12}
                vldmia r3!,{q8,q9}
                vldmia r3!,{d20}
                
                vadd.f32 q0,q0,q4
                vadd.f32 q1,q1,q5
                vadd.f32 d4,d4,d12
                vadd.f32 q0,q0,q8
                vadd.f32 q1,q1,q9
                vadd.f32 d4,d4,d20
                vstmia r5!,{q0,q1}
                vstmia r5!,{d4}
                
                vmax.f32 q12,q12,q0
                vmax.f32 q12,q12,q1
                vmax.f32 d24,d24,d4
                
                b .Lf3end
.Lf3lt10:
                // 9 elems
                vldmia r0!,{q0,q1}
                vldmia r0!,{s8}
                vldmia r2!,{q4,q5}
                vldmia r2!,{s9}
                vldmia r3!,{q8,q9}
                vldmia r3!,{s10}
                
                vadd.f32 q0,q0,q4
                vadd.f32 q1,q1,q5
                fadds s8,s8,s9
                vadd.f32 q0,q0,q8
                vadd.f32 q1,q1,q9
                fadds s8,s8,s10
                vstmia r5!,{q0,q1}
                vstmia r5!,{s8}
                
                vmax.f32 q12,q12,q0
                vmax.f32 q12,q12,q1
                vmax.f32 d24,d24,d4

                b .Lf3end
.Lf3eq8:
                // 8 elems
                vldmia r0!,{q0,q1}
                vldmia r2!,{q4,q5}
                vldmia r3!,{q8,q9}
                
                vadd.f32 q0,q0,q4
                vadd.f32 q1,q1,q5
                vadd.f32 q0,q0,q8
                vadd.f32 q1,q1,q9
                vstmia r5!,{q0,q1}
                
                vmax.f32 q12,q12,q0
                vmax.f32 q12,q12,q1
                
                b .Lf3end
.Lf3lt8:
                cmp r4,#4
                blo .Lf3lt4
                beq .Lf3eq4
                
                cmp r4,#6
                blo .Lf3lt6
                beq .Lf3eq6
                // 7 elems
                vldmia r0!,{q0}
                vldmia r0!,{s4,s5,s6}
                vldmia r2!,{q4}
                vldmia r2!,{s20,s21,s22}
                vldmia r3!,{q8}
                vldmia r3!,{d18}
                vldmia r3!,{s7}
                
                vadd.f32 q0,q0,q4
                vadd.f32 d2,d2,d10
                vadd.f32 s6,s6,s22
                vadd.f32 q0,q0,q8
                vadd.f32 d2,d2,d18
                vadd.f32 s6,s6,s7
                vstmia r5!,{q0}
                vstmia r5!,{s4,s5,s6}
                
                vmax.f32 q12,q12,q0
                vmax.f32 q12,q12,q1
                
                b .Lf3end
.Lf3eq6:
                // 6 elems
                vldmia r0!,{q0}
                vldmia r0!,{d2}
                vldmia r2!,{q4}
                vldmia r2!,{d10}
                vldmia r3!,{q8}
                vldmia r3!,{d18}
                
                vadd.f32 q0,q0,q4
                vadd.f32 d2,d2,d10
                vadd.f32 q0,q0,q8
                vadd.f32 d2,d2,d18
                vstmia r5!,{q0}
                vstmia r5!,{d2}
                
                vmax.f32 q12,q12,q0
                vmax.f32 d24,d24,d2
                
                b .Lf3end
.Lf3lt6:
                // 5 elems
                vldmia r0!,{q0}
                vldmia r0!,{s4}
                vldmia r2!,{q4}
                vldmia r2!,{s20}
                vldmia r3!,{q8}
                vldmia r3!,{s5}
                
                vadd.f32 q0,q0,q4
                fadds s4,s4,s20
                vadd.f32 q0,q0,q8
                fadds s4,s4,s5
                vstmia r5!,{q0}
                vstmia r5!,{s4}
                
                vmax.f32 q12,q12,q0
                vmax.f32 d24,d24,d2
                
                b .Lf3end
.Lf3eq4:
                // 4 elems
                vldmia r0!,{q0}
                vldmia r2!,{q4}
                vldmia r3!,{q8}
                
                vadd.f32 q0,q0,q4
                vadd.f32 q0,q0,q8
                vstmia r5!,{q0}
                
                vmax.f32 q12,q12,q0
                
                b .Lf3end
.Lf3lt4:
                cmp r4,#2
                blo .Lf3lt2
                beq .Lf3eq2
                // 3 elems
                vldmia r0!,{s0,s1,s2}
                vldmia r2!,{s16,s17,s18}
                vldmia r3!,{d16}
                vldmia r3!,{s3}
                
                vadd.f32 d0,d0,d8
                vadd.f32 s2,s2,s18
                vadd.f32 d0,d0,d16
                vadd.f32 s2,s2,s3
                vstmia r5!,{s0,s1,s2}
                
                vmax.f32 q12,q12,q0
                
                b .Lf3end
.Lf3eq2:
                // 2 elems
                vldmia r0!,{d0}
                vldmia r2!,{d4}
                vldmia r3!,{d8}
                
                vadd.f32 d0,d0,d4
                vadd.f32 d0,d0,d8
                vstmia r5!,{d0}
                
                vmax.f32 d24,d24,d0
                
                b .Lf3end
.Lf3lt2:
                cmp r4,#0
                beq .Lf3eq0
                
                vldmia r0!,{s0}
                vldmia r2!,{s1}
                vldmia r3!,{s2}
                
                vadd.f32 s0,s0,s1
                vadd.f32 s0,s0,s2
                vstmia r5!,{s0}
                
                vmax.f32 d24,d24,d0
.Lf3eq0:
.Lf3end:
                vpmax.f32 d24,d24,d25
                vpmax.f32 d0,d24,d24

                fmrs r0,s0
                vpop {d8,d9,d10,d11,d12,d13,d14,d15}
                pop {r4,r5,r6,lr}
                bx lr
                
                
                .global neon_foldArrayBy3_lge31
                .type neon_foldArrayBy3_lge31, %function
neon_foldArrayBy3_lge31:
                push {r4,r5,r6,lr}
                vpush {d8,d9,d10,d11,d12,d13,d14,d15}
                
                ldr r0,[r0] // ss0
                ldrd r2,[r1,#8] // tmp0
                add r2,r0,r2,lsl #2
                add r3,r0,r3,lsl #2
                ldrd r4,[r1]  // di,dest
                add r6,r0,r4,lsl #2 // end
                
                veor.i32 q12,q12,q12
                sub r6,r6,#4*31
                cmp r0,r6
                bhs .Lendf3loop2
.Lf3loop2:
                FOLDBY3_CORE
                FOLDBY3_CORE
                
                cmp r0,r6
                blo .Lf3loop2
.Lendf3loop2:                
                add r6,r6,#4*16
                cmp r0,r6
                bhs .Lendf3loop1
.Lf3loop3:
                FOLDBY3_CORE

                cmp r0,r6
                blo .Lf3loop3
.Lendf3loop3:
                b .Lendf3loop1
               
.Lfoldby3sel:
.rept 31
                .word neon_foldArrayBy3_ll31
.endr
                .word neon_foldArrayBy3_lge31
               
                /******
                 * fold array by 4
                 ******/
                .global neon_foldArrayBy4_ll31
                .type neon_foldArrayBy4_ll31, %function
neon_foldArrayBy4_ll31:
                push {r4,r5,r6,r7,r8,lr}
                vpush {d8,d9,d10,d11,d12,d13,d14,d15}
                
                ldr r0,[r0] // ss0
                ldrd r2,[r1,#8] // tmp0
                ldr r6,[r1,#16] // tmp2
                add r2,r0,r2,lsl #2
                add r3,r0,r3,lsl #2
                add r6,r0,r6,lsl #2
                ldrd r4,[r1]  // di,dest
                add r7,r0,r4,lsl #2 // end
                
                veor.i32 q12,q12,q12
                sub r7,r7,#4*15
                cmp r0,r7
                bhs .Lendf4loop1
.Lf4loop1:
.macro FOLDBY4_CORE
                vldmia r0!,{q0,q1,q2,q3}
                vldmia r2!,{q4,q5,q6,q7}
                vldmia r3!,{q8,q9,q10,q11}
                
                vadd.f32 q0,q0,q4
                vadd.f32 q1,q1,q5
                vadd.f32 q2,q2,q6
                vadd.f32 q3,q3,q7
                vadd.f32 q0,q0,q8
                vadd.f32 q1,q1,q9
                vadd.f32 q2,q2,q10
                vadd.f32 q3,q3,q11
                vldmia r6!,{q8,q9,q10,q11}
                vadd.f32 q0,q0,q8
                vadd.f32 q1,q1,q9
                vadd.f32 q2,q2,q10
                vadd.f32 q3,q3,q11
                vstmia r5!,{q0,q1,q2,q3}
                
                vmax.f32 q13,q0,q1
                vmax.f32 q14,q2,q3
                vmax.f32 q12,q12,q13
                vmax.f32 q12,q12,q14
.endm
                FOLDBY4_CORE

                cmp r0,r7
                blo .Lf4loop1
.Lendf4loop1:
                and r4,r4,#15
                cmp r4,#8
                blo .Lf4lt8
                beq .Lf4eq8
                
                cmp r4,#12
                blo .Lf4lt12
                beq .Lf4eq12
                
                cmp r4,#14
                blo .Lf4lt14
                beq .Lf4eq14
                // 15 elems
                vldmia r0!,{q0,q1,q2}
                vldmia r0!,{s12,s13,s14}
                vldmia r2!,{q4,q5,q6}
                vldmia r2!,{s28,s29,s30}
                vldmia r3!,{q8,q9,q10}
                vldmia r3!,{d22}
                vldmia r3, {s15}
                vldmia r6!,{q13,q14,q15}
                
                vadd.f32 q0,q0,q4
                vadd.f32 q1,q1,q5
                vadd.f32 q2,q2,q6
                vadd.f32 d6,d6,d14
                vadd.f32 s14,s14,s30
                vadd.f32 q0,q0,q8
                vadd.f32 q1,q1,q9
                vadd.f32 q2,q2,q10
                vadd.f32 d6,d6,d22
                vadd.f32 s14,s14,s15
                vldmia r6!,{s16,s17,s18}
                vadd.f32 q0,q0,q13
                vadd.f32 q1,q1,q14
                vadd.f32 q2,q2,q15
                vadd.f32 d6,d6,d8
                vadd.f32 s14,s14,s18
                
                vstmia r5!,{q0,q1,q2}
                vstmia r5!,{s12,s13,s14}
                
                vmax.f32 q12,q12,q0
                vmax.f32 q12,q12,q1
                vmax.f32 q12,q12,q2
                vmax.f32 q12,q12,q3
                
                b .Lf4end
.Lf4eq14:
                // 14 elems
                vldmia r0!,{q0,q1,q2}
                vldmia r0!,{d6}
                vldmia r2!,{q4,q5,q6}
                vldmia r2!,{d14}
                vldmia r3!,{q8,q9,q10}
                vldmia r3!,{d22}
                vldmia r6!,{q13,q14,q15}
                vldmia r6!,{d7}
                
                vadd.f32 q0,q0,q4
                vadd.f32 q1,q1,q5
                vadd.f32 q2,q2,q6
                vadd.f32 d6,d6,d14
                vadd.f32 q0,q0,q8
                vadd.f32 q1,q1,q9
                vadd.f32 q2,q2,q10
                vadd.f32 d6,d6,d22
                vadd.f32 q0,q0,q13
                vadd.f32 q1,q1,q14
                vadd.f32 q2,q2,q15
                vadd.f32 d6,d6,d7
                vstmia r5!,{q0,q1,q2}
                vstmia r5!,{d6}
                
                vmax.f32 q12,q12,q0
                vmax.f32 q12,q12,q1
                vmax.f32 q12,q12,q2
                vmax.f32 d24,d24,d6
                
                b .Lf4end
.Lf4lt14:
                // 13 elems
                vldmia r0!,{q0,q1,q2}
                vldmia r0!,{s12}
                vldmia r2!,{q4,q5,q6}
                vldmia r2!,{s13}
                vldmia r3!,{q8,q9,q10}
                vldmia r3!,{s14}
                vldmia r6!,{q13,q14,q15}
                vldmia r6!,{s15}
                
                vadd.f32 q0,q0,q4
                vadd.f32 q1,q1,q5
                vadd.f32 q2,q2,q6
                fadds s12,s12,s13
                vadd.f32 q0,q0,q8
                vadd.f32 q1,q1,q9
                vadd.f32 q2,q2,q10
                fadds s12,s12,s14
                vadd.f32 q0,q0,q13
                vadd.f32 q1,q1,q14
                vadd.f32 q2,q2,q15
                fadds s12,s12,s15
                vstmia r5!,{q0,q1,q2}
                vstmia r5!,{s12}
                
                vmax.f32 q12,q12,q0
                vmax.f32 q12,q12,q1
                vmax.f32 q12,q12,q2
                vmax.f32 d24,d24,d6
                
                b .Lf4end
.Lf4eq12:
                // 12 elems
                vldmia r0!,{q0,q1,q2}
                vldmia r2!,{q4,q5,q6}
                vldmia r3!,{q8,q9,q10}
                vldmia r6!,{q13,q14,q15}
                
                vadd.f32 q0,q0,q4
                vadd.f32 q1,q1,q5
                vadd.f32 q2,q2,q6
                vadd.f32 q0,q0,q8
                vadd.f32 q1,q1,q9
                vadd.f32 q2,q2,q10
                vadd.f32 q0,q0,q13
                vadd.f32 q1,q1,q14
                vadd.f32 q2,q2,q15
                vstmia r5!,{q0,q1,q2}
                
                vmax.f32 q12,q12,q0
                vmax.f32 q12,q12,q1
                vmax.f32 q12,q12,q2
                
                b .Lf4end
.Lf4lt12:
                cmp r4,#10
                blo .Lf4lt10
                beq .Lf4eq10
                // 11 elems
                vldmia r0!,{q0,q1}
                vldmia r0!,{s8,s9,s10}
                vldmia r2!,{q4,q5}
                vldmia r2!,{s24,s25,s26}
                vldmia r3!,{q8,q9}
                vldmia r3!,{d20}
                vldmia r3!,{s11}
                vldmia r6!,{q13,q14}
                vldmia r6!,{s12,s13,s14}
                
                vadd.f32 q0,q0,q4
                vadd.f32 q1,q1,q5
                vadd.f32 d4,d4,d12
                vadd.f32 s10,s10,s26
                vadd.f32 q0,q0,q8
                vadd.f32 q1,q1,q9
                vadd.f32 d4,d4,d20
                vadd.f32 s10,s10,s11
                vadd.f32 q0,q0,q13
                vadd.f32 q1,q1,q14
                vadd.f32 d4,d4,d6
                vadd.f32 s10,s10,s14
                vstmia r5!,{q0,q1}
                vstmia r5!,{s8,s9,s10}
                
                vmax.f32 q12,q12,q0
                vmax.f32 q12,q12,q1
                vmax.f32 q12,q12,q2
                
                b .Lf4end
.Lf4eq10:
                // 10 elems
                vldmia r0!,{q0,q1}
                vldmia r0!,{d4}
                vldmia r2!,{q4,q5}
                vldmia r2!,{d12}
                vldmia r3!,{q8,q9}
                vldmia r3!,{d20}
                vldmia r6!,{q13,q14}
                vldmia r6!,{d5}
                
                vadd.f32 q0,q0,q4
                vadd.f32 q1,q1,q5
                vadd.f32 d4,d4,d12
                vadd.f32 q0,q0,q8
                vadd.f32 q1,q1,q9
                vadd.f32 d4,d4,d20
                vadd.f32 q0,q0,q13
                vadd.f32 q1,q1,q14
                vadd.f32 d4,d4,d5
                vstmia r5!,{q0,q1}
                vstmia r5!,{d4}
                
                vmax.f32 q12,q12,q0
                vmax.f32 q12,q12,q1
                vmax.f32 d24,d24,d4
                
                b .Lf4end
.Lf4lt10:
                // 9 elems
                vldmia r0!,{q0,q1}
                vldmia r0!,{s8}
                vldmia r2!,{q4,q5}
                vldmia r2!,{s9}
                vldmia r3!,{q8,q9}
                vldmia r3!,{s10}
                vldmia r6!,{q13,q14}
                vldmia r6!,{s11}
                
                vadd.f32 q0,q0,q4
                vadd.f32 q1,q1,q5
                fadds s8,s8,s9
                vadd.f32 q0,q0,q8
                vadd.f32 q1,q1,q9
                fadds s8,s8,s10
                vadd.f32 q0,q0,q13
                vadd.f32 q1,q1,q14
                fadds s8,s8,s11
                vstmia r5!,{q0,q1}
                vstmia r5!,{s8}
                
                vmax.f32 q12,q12,q0
                vmax.f32 q12,q12,q1
                vmax.f32 d24,d24,d4

                b .Lf4end
.Lf4eq8:
                // 8 elems
                vldmia r0!,{q0,q1}
                vldmia r2!,{q4,q5}
                vldmia r3!,{q8,q9}
                vldmia r6!,{q13,q14}
                
                vadd.f32 q0,q0,q4
                vadd.f32 q1,q1,q5
                vadd.f32 q0,q0,q8
                vadd.f32 q1,q1,q9
                vadd.f32 q0,q0,q13
                vadd.f32 q1,q1,q14
                vstmia r5!,{q0,q1}
                
                vmax.f32 q12,q12,q0
                vmax.f32 q12,q12,q1
                
                b .Lf4end
.Lf4lt8:
                cmp r4,#4
                blo .Lf4lt4
                beq .Lf4eq4
                
                cmp r4,#6
                blo .Lf4lt6
                beq .Lf4eq6
                // 7 elems
                vldmia r0!,{q0}
                vldmia r0!,{s4,s5,s6}
                vldmia r2!,{q4}
                vldmia r2!,{s20,s21,s22}
                vldmia r3!,{q8}
                vldmia r3!,{d18}
                vldmia r3!,{s7}
                vldmia r6!,{q13}
                vldmia r6!,{s8,s9,s10}
                
                vadd.f32 q0,q0,q4
                vadd.f32 d2,d2,d10
                vadd.f32 s6,s6,s22
                vadd.f32 q0,q0,q8
                vadd.f32 d2,d2,d18
                vadd.f32 s6,s6,s7
                vadd.f32 q0,q0,q13
                vadd.f32 d2,d2,d4
                vadd.f32 s6,s6,s10
                vstmia r5!,{q0}
                vstmia r5!,{s4,s5,s6}
                
                vmax.f32 q12,q12,q0
                vmax.f32 q12,q12,q1
                
                b .Lf4end
.Lf4eq6:
                // 6 elems
                vldmia r0!,{q0}
                vldmia r0!,{d2}
                vldmia r2!,{q4}
                vldmia r2!,{d10}
                vldmia r3!,{q8}
                vldmia r3!,{d18}
                vldmia r6!,{q13}
                vldmia r6!,{d3}
                
                vadd.f32 q0,q0,q4
                vadd.f32 d2,d2,d10
                vadd.f32 q0,q0,q8
                vadd.f32 d2,d2,d18
                vadd.f32 q0,q0,q13
                vadd.f32 d2,d2,d3
                vstmia r5!,{q0}
                vstmia r5!,{d2}
                
                vmax.f32 q12,q12,q0
                vmax.f32 d24,d24,d2
                
                b .Lf4end
.Lf4lt6:
                // 5 elems
                vldmia r0!,{q0}
                vldmia r0!,{s4}
                vldmia r2!,{q4}
                vldmia r2!,{s20}
                vldmia r3!,{q8}
                vldmia r3!,{s5}
                vldmia r6!,{q13}
                vldmia r6!,{s6}
                
                vadd.f32 q0,q0,q4
                fadds s4,s4,s20
                vadd.f32 q0,q0,q8
                fadds s4,s4,s5
                vadd.f32 q0,q0,q13
                fadds s4,s4,s6
                vstmia r5!,{q0}
                vstmia r5!,{s4}
                
                vmax.f32 q12,q12,q0
                vmax.f32 d24,d24,d2
                
                b .Lf4end
.Lf4eq4:
                // 4 elems
                vldmia r0!,{q0}
                vldmia r2!,{q4}
                vldmia r3!,{q8}
                vldmia r6!,{q13}
                
                vadd.f32 q0,q0,q4
                vadd.f32 q0,q0,q8
                vadd.f32 q0,q0,q13
                vstmia r5!,{q0}
                
                vmax.f32 q12,q12,q0
                
                b .Lf4end
.Lf4lt4:
                cmp r4,#2
                blo .Lf4lt2
                beq .Lf4eq2
                // 3 elems
                vldmia r0!,{s0,s1,s2}
                vldmia r2!,{s16,s17,s18}
                vldmia r3!,{d16}
                vldmia r3!,{s3}
                vldmia r6!,{s4,s5,s6}
                
                vadd.f32 d0,d0,d8
                vadd.f32 s2,s2,s18
                vadd.f32 d0,d0,d16
                vadd.f32 s2,s2,s3
                vadd.f32 d0,d0,d2
                vadd.f32 s2,s2,s6
                vstmia r5!,{s0,s1,s2}
                
                vmax.f32 q12,q12,q0
                
                b .Lf4end
.Lf4eq2:
                // 2 elems
                vldmia r0!,{d0}
                vldmia r2!,{d4}
                vldmia r3!,{d8}
                vldmia r6!,{d12}
                
                vadd.f32 d0,d0,d4
                vadd.f32 d0,d0,d8
                vadd.f32 d0,d0,d12
                vstmia r5!,{d0}
                
                vmax.f32 d24,d24,d0
                
                b .Lf4end
.Lf4lt2:
                cmp r4,#0
                beq .Lf4eq0
                
                vldmia r0!,{s0}
                vldmia r2!,{s1}
                vldmia r3!,{s2}
                vldmia r6!,{s3}
                
                vadd.f32 s0,s0,s1
                vadd.f32 s0,s0,s2
                vadd.f32 s0,s0,s3
                vstmia r5!,{s0}
                
                vmax.f32 d24,d24,d0
.Lf4eq0:
.Lf4end:
                vpmax.f32 d24,d24,d25
                vpmax.f32 d0,d24,d24

                fmrs r0,s0
                vpop {d8,d9,d10,d11,d12,d13,d14,d15}
                pop {r4,r5,r6,r7,r8,lr}
                bx lr
                
                
                .global neon_foldArrayBy4_lge31
                .type neon_foldArrayBy4_lge31, %function
neon_foldArrayBy4_lge31:
                push {r4,r5,r6,r7,r8,lr}
                vpush {d8,d9,d10,d11,d12,d13,d14,d15}
                
                ldr r0,[r0] // ss0
                ldrd r2,[r1,#8] // tmp0
                ldr r6,[r1,#16] // tmp2
                add r2,r0,r2,lsl #2
                add r3,r0,r3,lsl #2
                add r6,r0,r6,lsl #2
                ldrd r4,[r1]  // di,dest
                add r7,r0,r4,lsl #2 // end
                
                veor.i32 q12,q12,q12
                sub r7,r7,#4*31
                cmp r0,r7
                bhs .Lendf4loop2
.Lf4loop2:
                FOLDBY4_CORE
                FOLDBY4_CORE
                
                cmp r0,r7
                blo .Lf4loop2
.Lendf4loop2:
                add r7,r7,#4*16
                cmp r0,r7
                bhs .Lendf4loop1
.Lf4loop3:
                FOLDBY4_CORE

                cmp r0,r7
                blo .Lf4loop3
.Lendf4loop3:
                b .Lendf4loop1
                
.Lfoldby4sel:
.rept 31
                .word neon_foldArrayBy4_ll31
.endr
                .word neon_foldArrayBy4_lge31

                /******
                 * fold array by 5
                 ******/
                .global neon_foldArrayBy5_ll31
                .type neon_foldArrayBy5_ll31, %function
neon_foldArrayBy5_ll31:
                push {r4,r5,r6,r7,r8,lr}
                vpush {d8,d9,d10,d11,d12,d13,d14,d15}
                
                ldr r0,[r0] // ss0
                ldrd r2,[r1,#8] // tmp0
                ldrd r6,[r1,#16] // tmp2
                add r2,r0,r2,lsl #2
                add r3,r0,r3,lsl #2
                add r6,r0,r6,lsl #2
                add r7,r0,r7,lsl #2
                ldrd r4,[r1]  // di,dest
                add r8,r0,r4,lsl #2 // end
                
                veor.i32 q12,q12,q12
                sub r8,r8,#4*15
                cmp r0,r8
                bhs .Lendf5loop1
.Lf5loop1:
.macro FOLDBY5_CORE
                vldmia r0!,{q0,q1,q2,q3}
                vldmia r2!,{q4,q5,q6,q7}
                vldmia r3!,{q8,q9,q10,q11}
                
                vadd.f32 q0,q0,q4
                vadd.f32 q1,q1,q5
                vadd.f32 q2,q2,q6
                vadd.f32 q3,q3,q7
                vadd.f32 q0,q0,q8
                vadd.f32 q1,q1,q9
                vadd.f32 q2,q2,q10
                vadd.f32 q3,q3,q11
                vldmia r6!,{q8,q9,q10,q11}
                vadd.f32 q0,q0,q8
                vadd.f32 q1,q1,q9
                vadd.f32 q2,q2,q10
                vadd.f32 q3,q3,q11
                vldmia r7!,{q8,q9,q10,q11}
                vadd.f32 q0,q0,q8
                vadd.f32 q1,q1,q9
                vadd.f32 q2,q2,q10
                vadd.f32 q3,q3,q11
                vstmia r5!,{q0,q1,q2,q3}
                
                vmax.f32 q13,q0,q1
                vmax.f32 q14,q2,q3
                vmax.f32 q12,q12,q13
                vmax.f32 q12,q12,q14
.endm
                FOLDBY5_CORE

                cmp r0,r8
                blo .Lf5loop1
.Lendf5loop1:
                and r4,r4,#15
                cmp r4,#8
                blo .Lf5lt8
                beq .Lf5eq8
                
                cmp r4,#12
                blo .Lf5lt12
                beq .Lf5eq12
                
                cmp r4,#14
                blo .Lf5lt14
                beq .Lf5eq14
                // 15 elems
                vldmia r0!,{q0,q1,q2}
                vldmia r0!,{s12,s13,s14}
                vldmia r2!,{q4,q5,q6}
                vldmia r2!,{s28,s29,s30}
                vldmia r3!,{q8,q9,q10}
                vldmia r3!,{d22}
                vldmia r3, {s15}
                vldmia r6!,{q13,q14,q15}
                
                vadd.f32 q0,q0,q4
                vadd.f32 q1,q1,q5
                vadd.f32 q2,q2,q6
                vadd.f32 d6,d6,d14
                vadd.f32 s14,s14,s30
                vadd.f32 q0,q0,q8
                vadd.f32 q1,q1,q9
                vadd.f32 q2,q2,q10
                vadd.f32 d6,d6,d22
                vadd.f32 s14,s14,s15
                vldmia r6!,{s16,s17,s18}
                vadd.f32 q0,q0,q13
                vadd.f32 q1,q1,q14
                vadd.f32 q2,q2,q15
                vadd.f32 d6,d6,d8
                vadd.f32 s14,s14,s18
                vldmia r7!,{q13,q14,q15}
                vldmia r7!,{s16,s17,s18}
                vadd.f32 q0,q0,q13
                vadd.f32 q1,q1,q14
                vadd.f32 q2,q2,q15
                vadd.f32 d6,d6,d8
                vadd.f32 s14,s14,s18
                
                vstmia r5!,{q0,q1,q2}
                vstmia r5!,{s12,s13,s14}
                
                vmax.f32 q12,q12,q0
                vmax.f32 q12,q12,q1
                vmax.f32 q12,q12,q2
                vmax.f32 q12,q12,q3
                
                b .Lf5end
.Lf5eq14:
                // 14 elems
                vldmia r0!,{q0,q1,q2}
                vldmia r0!,{d6}
                vldmia r2!,{q4,q5,q6}
                vldmia r2!,{d14}
                vldmia r3!,{q8,q9,q10}
                vldmia r3!,{d22}
                vldmia r6!,{q13,q14,q15}
                vldmia r6!,{d7}
                
                vadd.f32 q0,q0,q4
                vadd.f32 q1,q1,q5
                vadd.f32 q2,q2,q6
                vadd.f32 d6,d6,d14
                vadd.f32 q0,q0,q8
                vadd.f32 q1,q1,q9
                vadd.f32 q2,q2,q10
                vadd.f32 d6,d6,d22
                vadd.f32 q0,q0,q13
                vadd.f32 q1,q1,q14
                vadd.f32 q2,q2,q15
                vadd.f32 d6,d6,d7
                vldmia r7!,{q13,q14,q15}
                vldmia r7!,{d7}
                vadd.f32 q0,q0,q13
                vadd.f32 q1,q1,q14
                vadd.f32 q2,q2,q15
                vadd.f32 d6,d6,d7
                vstmia r5!,{q0,q1,q2}
                vstmia r5!,{d6}
                
                vmax.f32 q12,q12,q0
                vmax.f32 q12,q12,q1
                vmax.f32 q12,q12,q2
                vmax.f32 d24,d24,d6
                
                b .Lf5end
.Lf5lt14:
                // 13 elems
                vldmia r0!,{q0,q1,q2}
                vldmia r0!,{s12}
                vldmia r2!,{q4,q5,q6}
                vldmia r2!,{s13}
                vldmia r3!,{q8,q9,q10}
                vldmia r3!,{s14}
                vldmia r6!,{q13,q14,q15}
                vldmia r6!,{s15}
                
                vadd.f32 q0,q0,q4
                vadd.f32 q1,q1,q5
                vadd.f32 q2,q2,q6
                fadds s12,s12,s13
                vadd.f32 q0,q0,q8
                vadd.f32 q1,q1,q9
                vadd.f32 q2,q2,q10
                fadds s12,s12,s14
                vadd.f32 q0,q0,q13
                vadd.f32 q1,q1,q14
                vadd.f32 q2,q2,q15
                fadds s12,s12,s15
                vldmia r7!,{q13,q14,q15}
                vldmia r7!,{s15}
                vadd.f32 q0,q0,q13
                vadd.f32 q1,q1,q14
                vadd.f32 q2,q2,q15
                fadds s12,s12,s15
                vstmia r5!,{q0,q1,q2}
                vstmia r5!,{s12}
                
                vmax.f32 q12,q12,q0
                vmax.f32 q12,q12,q1
                vmax.f32 q12,q12,q2
                vmax.f32 d24,d24,d6
                
                b .Lf5end
.Lf5eq12:
                // 12 elems
                vldmia r0!,{q0,q1,q2}
                vldmia r2!,{q3,q4,q5}
                vldmia r3!,{q6,q7,q8}
                vldmia r6!,{q9,q10,q11}
                vldmia r7!,{q13,q14,q15}
                
                vadd.f32 q0,q0,q3
                vadd.f32 q1,q1,q4
                vadd.f32 q2,q2,q5
                vadd.f32 q0,q0,q6
                vadd.f32 q1,q1,q7
                vadd.f32 q2,q2,q8
                vadd.f32 q0,q0,q9
                vadd.f32 q1,q1,q10
                vadd.f32 q2,q2,q11
                vadd.f32 q0,q0,q13
                vadd.f32 q1,q1,q14
                vadd.f32 q2,q2,q15
                vstmia r5!,{q0,q1,q2}
                
                vmax.f32 q12,q12,q0
                vmax.f32 q12,q12,q1
                vmax.f32 q12,q12,q2
                
                b .Lf5end
.Lf5lt12:
                cmp r4,#10
                blo .Lf5lt10
                beq .Lf5eq10
                // 11 elems
                vldmia r0!,{q0,q1}
                vldmia r0!,{s8,s9,s10}
                vldmia r2!,{q7,q8}
                vldmia r2!,{d6}
                vldmia r2!,{s11}
                vldmia r3!,{q9,q10}
                vldmia r3!,{s14,s15,s16}
                vldmia r6!,{q11}
                vldmia r6!,{q13}
                vldmia r6!,{s18,s19,s20}
                vldmia r7!,{q14}
                vldmia r7!,{q15}
                vldmia r7!,{s22,s23,s24}

                vadd.f32 q0,q0,q7
                vadd.f32 q1,q1,q8
                vadd.f32 d4,d4,d6
                vadd.f32 s10,s10,s11
                vadd.f32 q0,q0,q9
                vadd.f32 q1,q1,q10
                vadd.f32 d4,d4,d7
                vadd.f32 s10,s10,s16
                vadd.f32 q0,q0,q11
                vadd.f32 q1,q1,q13
                vadd.f32 d4,d4,d9
                vadd.f32 s10,s10,s20
                vadd.f32 q0,q0,q14
                vadd.f32 q1,q1,q15
                vadd.f32 d4,d4,d11
                vadd.f32 s10,s10,s24
                vstmia r5!,{q0,q1}
                vstmia r5!,{s8,s9,s10}
                
                vmax.f32 q12,q12,q0
                vmax.f32 q12,q12,q1
                vmax.f32 q12,q12,q2
                
                b .Lf5end
.Lf5eq10:
                // 10 elems
                vldmia r0!,{q0,q1}
                vldmia r0!,{d4}
                vldmia r2!,{q3,q4}
                vldmia r2!,{d5}
                vldmia r3!,{q5,q6}
                vldmia r3!,{d14}
                vldmia r6!,{q8,q9}
                vldmia r6!,{d15}
                vldmia r7!,{q10,q11}
                vldmia r7!,{d26}
                
                vadd.f32 q0,q0,q3
                vadd.f32 q1,q1,q4
                vadd.f32 d4,d4,d5
                vadd.f32 q0,q0,q5
                vadd.f32 q1,q1,q6
                vadd.f32 d4,d4,d14
                vadd.f32 q0,q0,q8
                vadd.f32 q1,q1,q9
                vadd.f32 d4,d4,d15
                vadd.f32 q0,q0,q10
                vadd.f32 q1,q1,q11
                vadd.f32 d4,d4,d26
                vstmia r5!,{q0,q1}
                vstmia r5!,{d4}
                
                vmax.f32 q12,q12,q0
                vmax.f32 q12,q12,q1
                vmax.f32 d24,d24,d4
                
                b .Lf5end
.Lf5lt10:
                // 9 elems
                vldmia r0!,{q0,q1}
                vldmia r0!,{s8}
                vldmia r2!,{q4,q5}
                vldmia r2!,{s9}
                vldmia r3!,{q6,q7}
                vldmia r3!,{s10}
                vldmia r6!,{q8,q9}
                vldmia r6!,{s11}
                vldmia r7!,{q10,q11}
                vldmia r7!,{s12}
                
                vadd.f32 q0,q0,q4
                vadd.f32 q1,q1,q5
                fadds s8,s8,s9
                vadd.f32 q0,q0,q6
                vadd.f32 q1,q1,q7
                fadds s8,s8,s10
                vadd.f32 q0,q0,q8
                vadd.f32 q1,q1,q9
                fadds s8,s8,s11
                vadd.f32 q0,q0,q10
                vadd.f32 q1,q1,q11
                fadds s8,s8,s12
                vstmia r5!,{q0,q1}
                vstmia r5!,{s8}
                
                vmax.f32 q12,q12,q0
                vmax.f32 q12,q12,q1
                vmax.f32 d24,d24,d4

                b .Lf5end
.Lf5eq8:
                // 8 elems
                vldmia r0!,{q0,q1}
                vldmia r2!,{q2,q3}
                vldmia r3!,{q4,q5}
                vldmia r6!,{q8,q9}
                vldmia r7!,{q10,q11}
                
                vadd.f32 q0,q0,q2
                vadd.f32 q1,q1,q3
                vadd.f32 q0,q0,q4
                vadd.f32 q1,q1,q5
                vadd.f32 q0,q0,q8
                vadd.f32 q1,q1,q9
                vadd.f32 q0,q0,q10
                vadd.f32 q1,q1,q11
                vstmia r5!,{q0,q1}
                
                vmax.f32 q12,q12,q0
                vmax.f32 q12,q12,q1
                
                b .Lf5end
.Lf5lt8:
                cmp r4,#4
                blo .Lf5lt4
                beq .Lf5eq4
                
                cmp r4,#6
                blo .Lf5lt6
                beq .Lf5eq6
                // 7 elems
                vldmia r0!,{q0}
                vldmia r0!,{s4,s5,s6}
                vldmia r2!,{q2}
                vldmia r2!,{d6}
                vldmia r2!,{s7}
                vldmia r3!,{q4}
                vldmia r3!,{s20,s21,s22}
                vldmia r6!,{q6}
                vldmia r6!,{s28,s29,s30}
                vldmia r7!,{q8}
                vldmia r7!,{d7}
                vldmia r7!,{s31}
                
                vadd.f32 q0,q0,q2
                vadd.f32 d2,d2,d6
                vadd.f32 s6,s6,s7
                vadd.f32 q0,q0,q4
                vadd.f32 d2,d2,d10
                vadd.f32 s6,s6,s22
                vadd.f32 q0,q0,q6
                vadd.f32 d2,d2,d14
                vadd.f32 s6,s6,s30
                vadd.f32 q0,q0,q8
                vadd.f32 d2,d2,d7
                vadd.f32 s6,s6,s31
                vstmia r5!,{q0}
                vstmia r5!,{s4,s5,s6}
                
                vmax.f32 q12,q12,q0
                vmax.f32 q12,q12,q1
                
                b .Lf5end
.Lf5eq6:
                // 6 elems
                vldmia r0!,{q0}
                vldmia r0!,{d2}
                vldmia r2!,{q2}
                vldmia r2!,{d6}
                vldmia r3!,{q4}
                vldmia r3!,{d10}
                vldmia r6!,{q6}
                vldmia r6!,{d14}
                vldmia r7!,{q8}
                vldmia r7!,{d15}
                
                vadd.f32 q0,q0,q2
                vadd.f32 d2,d2,d6
                vadd.f32 q0,q0,q4
                vadd.f32 d2,d2,d10
                vadd.f32 q0,q0,q6
                vadd.f32 d2,d2,d14
                vadd.f32 q0,q0,q8
                vadd.f32 d2,d2,d15
                vstmia r5!,{q0}
                vstmia r5!,{d2}
                
                vmax.f32 q12,q12,q0
                vmax.f32 d24,d24,d2
                
                b .Lf5end
.Lf5lt6:
                // 5 elems
                vldmia r0!,{q0}
                vldmia r0!,{s4}
                vldmia r2!,{q2}
                vldmia r2!,{s5}
                vldmia r3!,{q4}
                vldmia r3!,{s6}
                vldmia r6!,{q6}
                vldmia r6!,{s7}
                vldmia r7!,{q8}
                vldmia r7!,{s12}
                
                vadd.f32 q0,q0,q2
                fadds s4,s4,s5
                vadd.f32 q0,q0,q4
                fadds s4,s4,s6
                vadd.f32 q0,q0,q6
                fadds s4,s4,s7
                vadd.f32 q0,q0,q8
                fadds s4,s4,s12
                vstmia r5!,{q0}
                vstmia r5!,{s4}
                
                vmax.f32 q12,q12,q0
                vmax.f32 d24,d24,d2
                
                b .Lf5end
.Lf5eq4:
                // 4 elems
                vldmia r0!,{q0}
                vldmia r2!,{q4}
                vldmia r3!,{q8}
                vldmia r6!,{q13}
                vldmia r7!,{q14}
                
                vadd.f32 q0,q0,q4
                vadd.f32 q0,q0,q8
                vadd.f32 q0,q0,q13
                vadd.f32 q0,q0,q14
                vstmia r5!,{q0}
                
                vmax.f32 q12,q12,q0
                
                b .Lf5end
.Lf5lt4:
                cmp r4,#2
                blo .Lf5lt2
                beq .Lf5eq2
                // 3 elems
                vldmia r0!,{s0,s1,s2}
                vldmia r2!,{d2}
                vldmia r2!,{s3}
                vldmia r3!,{s6,s7,s8}
                vldmia r6!,{s10,s11,s12}
                vldmia r7!,{s14,s15,s16}
                
                vadd.f32 d0,d0,d2
                vadd.f32 s2,s2,s3
                vadd.f32 d0,d0,d3
                vadd.f32 s2,s2,s8
                vadd.f32 d0,d0,d5
                vadd.f32 s2,s2,s12
                vadd.f32 d0,d0,d7
                vadd.f32 s2,s2,s16
                vstmia r5!,{s0,s1,s2}
                
                vmax.f32 q12,q12,q0
                
                b .Lf5end
.Lf5eq2:
                // 2 elems
                vldmia r0!,{d0}
                vldmia r2!,{d4}
                vldmia r3!,{d8}
                vldmia r6!,{d12}
                vldmia r7!,{d13}
                
                vadd.f32 d0,d0,d4
                vadd.f32 d0,d0,d8
                vadd.f32 d0,d0,d12
                vadd.f32 d0,d0,d13
                vstmia r5!,{d0}
                
                vmax.f32 d24,d24,d0
                
                b .Lf5end
.Lf5lt2:
                cmp r4,#0
                beq .Lf5eq0
                
                vldmia r0!,{s0}
                vldmia r2!,{s1}
                vldmia r3!,{s2}
                vldmia r6!,{s3}
                vldmia r7!,{s4}
                
                vadd.f32 s0,s0,s1
                vadd.f32 s0,s0,s2
                vadd.f32 s0,s0,s3
                vadd.f32 s0,s0,s4
                vstmia r5!,{s0}
                
                vmax.f32 d24,d24,d0
.Lf5eq0:
.Lf5end:
                vpmax.f32 d24,d24,d25
                vpmax.f32 d0,d24,d24

                fmrs r0,s0
                vpop {d8,d9,d10,d11,d12,d13,d14,d15}
                pop {r4,r5,r6,r7,r8,lr}
                bx lr
                
.Lfoldby5sel:
.rept 31
                .word neon_foldArrayBy5_ll31
.endr
                .word neon_foldArrayBy5_lge31

                
                .global neon_foldArrayBy5_lge31
                .type neon_foldArrayBy5_lge31, %function
neon_foldArrayBy5_lge31:
                push {r4,r5,r6,r7,r8,lr}
                vpush {d8,d9,d10,d11,d12,d13,d14,d15}
                
                ldr r0,[r0] // ss0
                ldrd r2,[r1,#8] // tmp0
                ldrd r6,[r1,#16] // tmp2
                add r2,r0,r2,lsl #2
                add r3,r0,r3,lsl #2
                add r6,r0,r6,lsl #2
                add r7,r0,r7,lsl #2
                ldrd r4,[r1]  // di,dest
                add r8,r0,r4,lsl #2 // end
                
                veor.i32 q12,q12,q12
                sub r8,r8,#4*31
                cmp r0,r8
                bhs .Lendf5loop2
.Lf5loop2:
                FOLDBY5_CORE
                FOLDBY5_CORE
                
                cmp r0,r8
                blo .Lf5loop2
.Lendf5loop2:
                add r8,r8,#4*16
                cmp r0,r8
                bhs .Lendf5loop1
.Lf5loop3:
                FOLDBY5_CORE

                cmp r0,r8
                blo .Lf5loop3
.Lendf5loop3:
                b .Lendf5loop1
                

                /*****
                 * fold array by 2
                 ******/
                .global neon_foldArrayBy2_ll31
                .type neon_foldArrayBy2_ll31, %function
neon_foldArrayBy2_ll31:
                push {r4,r5,r6,lr}
                vpush {d8,d9,d10,d11,d12,d13,d14,d15}
                
                ldr r0,[r0,#4] // ss1
                ldrd r2,[r1,#8] // tmp0
                add r2,r0,r2,lsl #2
                add r3,r0,r3,lsl #2
                ldrd r4,[r1]  // di,dest
                add r6,r2,r4,lsl #2 // end
                
                veor.i32 q12,q12,q12
                sub r6,r6,#4*15
                cmp r2,r6
                bhs .Lendf2loop1
.Lf2loop1:
.macro FOLDBY2_CORE
                vldmia r2!,{q0,q1,q2,q3}
                vldmia r3!,{q4,q5,q6,q7}
                
                vadd.f32 q0,q0,q4
                vadd.f32 q1,q1,q5
                vadd.f32 q2,q2,q6
                vadd.f32 q3,q3,q7
                vstmia r5!,{q0,q1,q2,q3}
                
                vmax.f32 q13,q0,q1
                vmax.f32 q14,q2,q3
                vmax.f32 q12,q12,q13
                vmax.f32 q12,q12,q14
.endm
                FOLDBY2_CORE

                cmp r2,r6
                blo .Lf2loop1
.Lendf2loop1:
                and r4,r4,#15
                cmp r4,#8
                blo .Lf2lt8
                beq .Lf2eq8
                
                cmp r4,#12
                blo .Lf2lt12
                beq .Lf2eq12
                
                cmp r4,#14
                blo .Lf2lt14
                beq .Lf2eq14
                // 15 elems
                vldmia r2!,{q0,q1,q2}
                vldmia r2!,{s12,s13,s14}
                vldmia r3!,{q4,q5,q6}
                vldmia r3!,{s28,s29}
                vldmia r3!,{s15}
                
                vadd.f32 q0,q0,q4
                vadd.f32 q1,q1,q5
                vadd.f32 q2,q2,q6
                vadd.f32 d6,d6,d14
                vadd.f32 s14,s14,s15
                vstmia r5!,{q0,q1,q2}
                vstmia r5!,{s12,s13,s14}
                
                vmax.f32 q12,q12,q0
                vmax.f32 q12,q12,q1
                vmax.f32 q12,q12,q2
                vmax.f32 q12,q12,q3
                
                b .Lf2end
.Lf2eq14:
                // 14 elems
                vldmia r2!,{q0,q1,q2}
                vldmia r2!,{d6}
                vldmia r3!,{q4,q5,q6}
                vldmia r3!,{d14}
                
                vadd.f32 q0,q0,q4
                vadd.f32 q1,q1,q5
                vadd.f32 q2,q2,q6
                vadd.f32 d6,d6,d14
                vstmia r5!,{q0,q1,q2}
                vstmia r5!,{d6}
                
                vmax.f32 q12,q12,q0
                vmax.f32 q12,q12,q1
                vmax.f32 q12,q12,q2
                vmax.f32 d24,d24,d6
                
                b .Lf2end
.Lf2lt14:
                // 13 elems
                vldmia r2!,{q0,q1,q2}
                vldmia r2!,{s12}
                vldmia r3!,{q4,q5,q6}
                vldmia r3!,{s13}
                
                vadd.f32 q0,q0,q4
                vadd.f32 q1,q1,q5
                vadd.f32 q2,q2,q6
                fadds s12,s12,s13
                vstmia r5!,{q0,q1,q2}
                vstmia r5!,{s12}
                
                vmax.f32 q12,q12,q0
                vmax.f32 q12,q12,q1
                vmax.f32 q12,q12,q2
                vmax.f32 d24,d24,d6
                
                b .Lf2end
.Lf2eq12:
                // 12 elems
                vldmia r2!,{q0,q1,q2}
                vldmia r3!,{q4,q5,q6}
                
                vadd.f32 q0,q0,q4
                vadd.f32 q1,q1,q5
                vadd.f32 q2,q2,q6
                vstmia r5!,{q0,q1,q2}
                
                vmax.f32 q12,q12,q0
                vmax.f32 q12,q12,q1
                vmax.f32 q12,q12,q2
                
                b .Lf2end
.Lf2lt12:
                cmp r4,#10
                blo .Lf2lt10
                beq .Lf2eq10
                // 11 elems
                vldmia r2!,{q0,q1}
                vldmia r2!,{s8,s9,s10}
                vldmia r3!,{q4,q5}
                vldmia r3!,{s24,s25}
                vldmia r3!,{s11}
                
                vadd.f32 q0,q0,q4
                vadd.f32 q1,q1,q5
                vadd.f32 d4,d4,d12
                vadd.f32 s10,s10,s11
                vstmia r5!,{q0,q1}
                vstmia r5!,{s8,s9,s10}
                
                vmax.f32 q12,q12,q0
                vmax.f32 q12,q12,q1
                vmax.f32 q12,q12,q2
                
                b .Lf2end
.Lf2eq10:
                // 10 elems
                vldmia r2!,{q0,q1}
                vldmia r2!,{d4}
                vldmia r3!,{q4,q5}
                vldmia r3!,{d12}
                
                vadd.f32 q0,q0,q4
                vadd.f32 q1,q1,q5
                vadd.f32 d4,d4,d12
                vstmia r5!,{q0,q1}
                vstmia r5!,{d4}
                
                vmax.f32 q12,q12,q0
                vmax.f32 q12,q12,q1
                vmax.f32 d24,d24,d4
                
                b .Lf2end
.Lf2lt10:
                // 9 elems
                vldmia r2!,{q0,q1}
                vldmia r2!,{s8}
                vldmia r3!,{q4,q5}
                vldmia r3!,{s9}
                
                vadd.f32 q0,q0,q4
                vadd.f32 q1,q1,q5
                fadds s8,s8,s9
                vstmia r5!,{q0,q1}
                vstmia r5!,{s8}
                
                vmax.f32 q12,q12,q0
                vmax.f32 q12,q12,q1
                vmax.f32 d24,d24,d4

                b .Lf2end
.Lf2eq8:
                // 8 elems
                vldmia r2!,{q0,q1}
                vldmia r3!,{q4,q5}
                
                vadd.f32 q0,q0,q4
                vadd.f32 q1,q1,q5
                vstmia r5!,{q0,q1}
                
                vmax.f32 q12,q12,q0
                vmax.f32 q12,q12,q1
                
                b .Lf2end
.Lf2lt8:
                cmp r4,#4
                blo .Lf2lt4
                beq .Lf2eq4
                
                cmp r4,#6
                blo .Lf2lt6
                beq .Lf2eq6
                // 7 elems
                vldmia r2!,{q0}
                vldmia r2!,{s4,s5,s6}
                vldmia r3!,{q4}
                vldmia r3!,{s20,s21}
                vldmia r3!,{s7}
                
                vadd.f32 q0,q0,q4
                vadd.f32 d2,d2,d10
                vadd.f32 s6,s6,s7
                vstmia r5!,{q0}
                vstmia r5!,{s4,s5,s6}
                
                vmax.f32 q12,q12,q0
                vmax.f32 q12,q12,q1
                
                b .Lf2end
.Lf2eq6:
                // 6 elems
                vldmia r2!,{q0}
                vldmia r2!,{d2}
                vldmia r3!,{q4}
                vldmia r3!,{d10}
                
                vadd.f32 q0,q0,q4
                vadd.f32 d2,d2,d10
                vstmia r5!,{q0}
                vstmia r5!,{d2}
                
                vmax.f32 q12,q12,q0
                vmax.f32 d24,d24,d2
                
                b .Lf2end
.Lf2lt6:
                // 5 elems
                vldmia r2!,{q0}
                vldmia r2!,{s4}
                vldmia r3!,{q4}
                vldmia r3!,{s5}
                
                vadd.f32 q0,q0,q4
                fadds s4,s4,s5
                vstmia r5!,{q0}
                vstmia r5!,{s4}
                
                vmax.f32 q12,q12,q0
                vmax.f32 d24,d24,d2
                
                b .Lf2end
.Lf2eq4:
                // 4 elems
                vldmia r2!,{q0}
                vldmia r3!,{q4}
                
                vadd.f32 q0,q0,q4
                vstmia r5!,{q0}
                
                vmax.f32 q12,q12,q0
                
                b .Lf2end
.Lf2lt4:
                cmp r4,#2
                blo .Lf2lt2
                beq .Lf2eq2
                // 3 elems
                vldmia r2!,{s0,s1,s2}
                vldmia r3!,{s16,s17}
                vldmia r3!,{s3}
                
                vadd.f32 d0,d0,d8
                vadd.f32 s2,s2,s3
                vstmia r5!,{s0,s1,s2}
                
                vmax.f32 q12,q12,q0
                
                b .Lf2end
.Lf2eq2:
                // 2 elems
                vldmia r2!,{d0}
                vldmia r3!,{d4}
                
                vadd.f32 d0,d0,d4
                vstmia r5!,{d0}
                
                vmax.f32 d24,d24,d0
                
                b .Lf2end
.Lf2lt2:
                cmp r4,#0
                beq .Lf2eq0
                
                vldmia r2!,{s0}
                vldmia r3!,{s1}
                
                vadd.f32 s0,s0,s1
                vstmia r5!,{s0}
                
                vmax.f32 d24,d24,d0
.Lf2eq0:
.Lf2end:
                vpmax.f32 d24,d24,d25
                vpmax.f32 d0,d24,d24

                fmrs r0,s0
                vpop {d8,d9,d10,d11,d12,d13,d14,d15}
                pop {r4,r5,r6,lr}
                bx lr
                
                
                .global neon_foldArrayBy2_lge31
                .type neon_foldArrayBy2_lge31, %function
neon_foldArrayBy2_lge31:
                push {r4,r5,r6,lr}
                vpush {d8,d9,d10,d11,d12,d13,d14,d15}
                
                ldr r0,[r0,#4] // ss1
                ldrd r2,[r1,#8] // tmp0
                add r2,r0,r2,lsl #2
                add r3,r0,r3,lsl #2
                ldrd r4,[r1]  // di,dest
                add r6,r2,r4,lsl #2 // end
                
                veor.i32 q12,q12,q12
                sub r6,r6,#4*31
                cmp r2,r6
                bhs .Lendf2loop2
.Lf2loop2:
                FOLDBY2_CORE
                FOLDBY2_CORE
                
                cmp r2,r6
                blo .Lf2loop2
.Lendf2loop2:
                add r6,r6,#4*16
                cmp r2,r6
                bhs .Lendf2loop1
.Lf2loop3:
                FOLDBY2_CORE

                cmp r2,r6
                blo .Lf2loop3
.Lendf2loop3:
                b .Lendf2loop1
                
.Lfoldby2sel:
.rept 31
                .word neon_foldArrayBy2_ll31
.endr
                .word neon_foldArrayBy2_lge31
                
                .align 2
.Lname:
                .string "opt NEON"
                
                .align 2
                .global neonFoldMain
neonFoldMain:
                .word .Lfoldby3sel
                .word .Lfoldby4sel
                .word .Lfoldby5sel
                .word .Lfoldby2sel
                .word .Lfoldby2sel
                .word .Lname
                /*


 * _Z21neon_GetPowerSpectrumPA2_fPfi.S
 * Author: Mateusz Szpakowski
 */
 
                .arch armv7-a
                .fpu neon
                .eabi_attribute 20, 1
                .eabi_attribute 21, 1
                .eabi_attribute 23, 3
                .eabi_attribute 24, 1
                .eabi_attribute 25, 1
                .eabi_attribute 26, 2
                .eabi_attribute 30, 2
                .eabi_attribute 18, 4
                .text
                .align  2
                .global _Z21neon_GetPowerSpectrumPA2_fPfi
                .type   _Z21neon_GetPowerSpectrumPA2_fPfi, %function
_Z21neon_GetPowerSpectrumPA2_fPfi:
                push {r4,r5}
                vpush {d8,d9,d10,d11,d12,d13,d14,d15}
                ldr r3,.LGOTa
.LPICa:
                add r3,pc,r3
                ldr r4,.LGOTa+4
                ldr r4,[r3,r4]
                add r5,r2,r2,lsl #1
                fldd d0,[r4,#32]
                fmsr s4,r5
                fuitod d1,s4
                faddd d0,d0,d1
                fstd d0,[r4,#32]
                
                cmp r2,#4096
                blo .Lsecondversion
                
                add r2,r0,r2, lsl #3
                sub r2,r2,#31*8
                /* r0 - freqData
                 * r1 - PowerSpectrum
                 * r2 - end of freqData
                 */
                cmp r0,r2
                bhs .Lendmainloopa
.Lmainloopa:
                pld [r0,#128]
                vldmia r0!,{q0,q1,q2,q3,q4,q5,q6,q7}
                vmul.f32 q0,q0,q0
                vmul.f32 q1,q1,q1
                vmul.f32 q2,q2,q2
                vmul.f32 q3,q3,q3
                vmul.f32 q4,q4,q4
                vmul.f32 q5,q5,q5
                vmul.f32 q6,q6,q6
                vmul.f32 q7,q7,q7
                vpadd.f32 d16,d0,d1
                vpadd.f32 d17,d2,d3
                vpadd.f32 d18,d4,d5
                vpadd.f32 d19,d6,d7
                vpadd.f32 d20,d8,d9
                vpadd.f32 d21,d10,d11
                vpadd.f32 d22,d12,d13
                vpadd.f32 d23,d14,d15
                
                pld [r0,#128]
                vldmia r0!,{q0,q1,q2,q3,q4,q5,q6,q7}
                vstmia r1!,{q8,q9,q10,q11}
                vmul.f32 q0,q0,q0
                vmul.f32 q1,q1,q1
                vmul.f32 q2,q2,q2
                vmul.f32 q3,q3,q3
                vmul.f32 q4,q4,q4
                vmul.f32 q5,q5,q5
                vmul.f32 q6,q6,q6
                vmul.f32 q7,q7,q7
                vpadd.f32 d16,d0,d1
                vpadd.f32 d17,d2,d3
                vpadd.f32 d18,d4,d5
                vpadd.f32 d19,d6,d7
                vpadd.f32 d20,d8,d9
                vpadd.f32 d21,d10,d11
                vpadd.f32 d22,d12,d13
                vpadd.f32 d23,d14,d15
                vstmia r1!,{q8,q9,q10,q11}
                
                cmp r0,r2
                blo .Lmainloopa

.Lendmainloopa:
                add r2,r2,#8*24
                bhs .Lendsmallloopa
.Lsmallloopa:
                vldmia r0!,{q0,q1,q2,q3}
                vmul.f32 q0,q0,q0
                vmul.f32 q1,q1,q1
                vmul.f32 q2,q2,q2
                vmul.f32 q3,q3,q3
                vpadd.f32 d16,d0,d1
                vpadd.f32 d17,d2,d3
                vpadd.f32 d18,d4,d5
                vpadd.f32 d19,d6,d7
                vstmia r1!,{q8,q9,q10,q11}
                cmp r0,r2
                blo .Lsmallloopa
.Lendsmallloopa:
                add r2,r2,#8*7
                cmp r0,r2                
                beq .Lendmicroloop
.Lmicroloop:
                fldmias r0!,{s0,s1}
                fmuls s2,s0,s0
                fmacs s2,s1,s1
                fstmias r1!,{s2}
                
                cmp r0,r2
                blo .Lmicroloop
.Lendmicroloop:
                mov r0,#0
                vpop {d8,d9,d10,d11,d12,d13,d14,d15}
                pop {r4,r5}
                bx lr
                

                /*
                 * second version
                 */
.Lsecondversion:
                add r2,r0,r2, lsl #3
                sub r2,r2,#31*8
                /* r0 - freqData
                 * r1 - PowerSpectrum
                 * r2 - end of freqData
                 */
                cmp r0,r2
                bhs .Lendmainloop2
.Lmainloop2:
                vldmia r0!,{q0,q1,q2,q3,q4,q5,q6,q7}
                vldmia r0!,{q8,q9,q10,q11,q12,q13,q14,q15}
                vuzp.32 q0,q1
                vuzp.32 q2,q3
                vuzp.32 q4,q5
                vuzp.32 q6,q7
                vuzp.32 q8,q9
                vuzp.32 q10,q11
                vuzp.32 q12,q13
                vuzp.32 q14,q15
                vmul.f32 q0,q0,q0
                vmul.f32 q2,q2,q2
                vmul.f32 q4,q4,q4
                vmul.f32 q6,q6,q6
                vmul.f32 q8,q8,q8
                vmul.f32 q10,q10,q10
                vmul.f32 q12,q12,q12
                vmul.f32 q14,q14,q14
                vmla.f32 q0,q1,q1
                vmla.f32 q2,q3,q3
                vmla.f32 q4,q5,q5
                vmla.f32 q6,q7,q7
                vmla.f32 q8,q9,q9
                vmla.f32 q10,q11,q11
                vmla.f32 q12,q13,q13
                vmla.f32 q14,q15,q15
                vstmia r1!,{q0}
                vstmia r1!,{q2}
                vstmia r1!,{q4}
                vstmia r1!,{q6}
                vstmia r1!,{q8}
                vstmia r1!,{q10}
                vstmia r1!,{q12}
                vstmia r1!,{q14}
                
                cmp r0,r2
                blo .Lmainloop2

.Lendmainloop2:
                add r2,r2,#8*24
                bhs .Lendsmallloop2
.Lsmallloop2:
                vldmia r0!,{q0,q1,q2,q3}
                vmul.f32 q0,q0,q0
                vmul.f32 q1,q1,q1
                vmul.f32 q2,q2,q2
                vmul.f32 q3,q3,q3
                vpadd.f32 d16,d0,d1
                vpadd.f32 d17,d2,d3
                vpadd.f32 d18,d4,d5
                vpadd.f32 d19,d6,d7
                vstmia r1!,{q8,q9,q10,q11}
                cmp r0,r2
                blo .Lsmallloop2
.Lendsmallloop2:
                add r2,r2,#8*7
                cmp r0,r2                
                beq .Lendmicroloop
.Lmicroloop2:
                fldmias r0!,{s0,s1}
                fmuls s2,s0,s0
                fmacs s2,s1,s1
                fstmias r1!,{s2}
                
                cmp r0,r2
                blo .Lmicroloop2
                b .Lendmicroloop
                
                .align  2
.LGOTa:
                .word _GLOBAL_OFFSET_TABLE_-(.LPICa+8)
                .word analysis_state(GOT)

#endif // __arm__
