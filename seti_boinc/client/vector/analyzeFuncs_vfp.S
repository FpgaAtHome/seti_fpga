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
 
                .arch armv6
                .fpu vfp
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
.Linc8d:
                .double 0,1,2,3,4,5,6,7
.Lsincosapprox:
                .float 1.5707963268,-0.6466386396,0.0679105987,-0.0011573807   // sine
                .float 1.0,-1.2341299769,0.2465220241,-0.0123926179     // cosine
                
                .align  2
                .global _Z13vfp_ChirpDataPA2_fS0_idid
                .type   _Z13vfp_ChirpDataPA2_fS0_idid, %function
_Z13vfp_ChirpDataPA2_fS0_idid:
                push {r4,r5,r6,r7,r8,lr}
                vpush {d8,d9,d10,d11,d12,d13,d14,d15}
#define stargidx (24+64)
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
                sub r3,r3,#8*7
                
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
                
                sub sp,sp,#24+32+8
                add r7,sp,#24
                fstmiad sp,{d9,d10}
                
                mov r4,#0       // i
                
                adr r5,.Linc8d
                adr r6,.Lsincosapprox
                adr r8,.Lsincosapprox+4*4
                
                cmp r0,r3
                bhs .Lendmainloop
.Lmainloop:
                fmsr s24,r4
                fuitod d8,s24
                fldmiad r5,{d0,d1,d2,d3,d4,d5,d6,d7}
                fldmiad sp,{d9,d10}
                faddd d0,d0,d8
                faddd d1,d1,d8
                faddd d2,d2,d8
                faddd d3,d3,d8
                faddd d4,d4,d8
                faddd d5,d5,d8
                faddd d6,d6,d8
                faddd d7,d7,d8
                // square of i
                fmuld d0,d0,d0
                fmuld d1,d1,d1
                fmuld d2,d2,d2
                fmuld d3,d3,d3
                fmuld d4,d4,d4
                fmuld d5,d5,d5
                fmuld d6,d6,d6
                fmuld d7,d7,d7
                // multiply by srate
                fmuld d0,d0,d9
                fmuld d1,d1,d9
                fmuld d2,d2,d9
                fmuld d3,d3,d9
                fmuld d4,d4,d9
                fmuld d5,d5,d9
                fmuld d6,d6,d9
                fmuld d7,d7,d9
                
                // rounding to -0.5/+0.5
                faddd d12,d0,d10
                faddd d13,d1,d10
                faddd d14,d2,d10
                faddd d15,d3,d10
                fsubd d12,d12,d10
                fsubd d13,d13,d10
                fsubd d14,d14,d10
                fsubd d15,d15,d10
                fsubd d0,d0,d12
                fsubd d1,d1,d13
                fsubd d2,d2,d14
                fsubd d3,d3,d15
                // second half of xxxx
                faddd d12,d4,d10
                faddd d13,d5,d10
                faddd d14,d6,d10
                faddd d15,d7,d10
                fsubd d12,d12,d10
                fsubd d13,d13,d10
                fsubd d14,d14,d10
                fsubd d15,d15,d10
                fsubd d4,d4,d12
                fsubd d5,d5,d13
                fsubd d6,d6,d14
                fsubd d7,d7,d15
                // to single precision
                fcvtsd s24,d0
                fcvtsd s25,d1
                fcvtsd s26,d2
                fcvtsd s27,d3
                fcvtsd s28,d4
                fcvtsd s29,d5
                fcvtsd s30,d6
                fcvtsd s31,d7
                
                fldmias r6,{s16,s17,s18,s19}
                // square of y
                fmuls s0,s24,s24
                fmuls s1,s25,s25
                fmuls s2,s26,s26
                fmuls s3,s27,s27
                fmuls s4,s28,s28
                fmuls s5,s29,s29
                fmuls s6,s30,s30
                fmuls s7,s31,s31
                // sine
                fmuls s8,s0,s19
                fmuls s9,s1,s19
                fmuls s10,s2,s19
                fmuls s11,s3,s19
                fmuls s12,s4,s19
                fmuls s13,s5,s19
                fmuls s14,s6,s19
                fmuls s15,s7,s19
                fadds s8,s8,s18
                fadds s9,s9,s18
                fadds s10,s10,s18
                fadds s11,s11,s18
                fadds s12,s12,s18
                fadds s13,s13,s18
                fadds s14,s14,s18
                fadds s15,s15,s18
                fmuls s8,s8,s0
                fmuls s9,s9,s1
                fmuls s10,s10,s2
                fmuls s11,s11,s3
                fmuls s12,s12,s4
                fmuls s13,s13,s5
                fmuls s14,s14,s6
                fmuls s15,s15,s7
                fadds s8,s8,s17
                fadds s9,s9,s17
                fadds s10,s10,s17
                fadds s11,s11,s17
                fadds s12,s12,s17
                fadds s13,s13,s17
                fadds s14,s14,s17
                fadds s15,s15,s17
                fmuls s8,s8,s0
                fmuls s9,s9,s1
                fmuls s10,s10,s2
                fmuls s11,s11,s3
                fmuls s12,s12,s4
                fmuls s13,s13,s5
                fmuls s14,s14,s6
                fmuls s15,s15,s7
                fadds s8,s8,s16
                fadds s9,s9,s16
                fadds s10,s10,s16
                fadds s11,s11,s16
                fadds s12,s12,s16
                fadds s13,s13,s16
                fadds s14,s14,s16
                fadds s15,s15,s16
                fmuls s8,s8,s24
                fmuls s9,s9,s25
                fmuls s10,s10,s26
                fmuls s11,s11,s27
                fmuls s12,s12,s28
                fmuls s13,s13,s29
                fmuls s14,s14,s30
                fmuls s15,s15,s31
                fldmias r8,{s24,s25,s26,s27}
                // cosine
                fmuls s16,s0,s27
                fmuls s17,s1,s27
                fmuls s18,s2,s27
                fmuls s19,s3,s27
                fmuls s20,s4,s27
                fmuls s21,s5,s27
                fmuls s22,s6,s27
                fmuls s23,s7,s27
                fadds s16,s16,s26
                fadds s17,s17,s26
                fadds s18,s18,s26
                fadds s19,s19,s26
                fadds s20,s20,s26
                fadds s21,s21,s26
                fadds s22,s22,s26
                fadds s23,s23,s26
                fmuls s16,s16,s0
                fmuls s17,s17,s1
                fmuls s18,s18,s2
                fmuls s19,s19,s3
                fmuls s20,s20,s4
                fmuls s21,s21,s5
                fmuls s22,s22,s6
                fmuls s23,s23,s7
                fadds s16,s16,s25
                fadds s17,s17,s25
                fadds s18,s18,s25
                fadds s19,s19,s25
                fadds s20,s20,s25
                fadds s21,s21,s25
                fadds s22,s22,s25
                fadds s23,s23,s25
                fmuls s16,s16,s0
                fmuls s17,s17,s1
                fmuls s18,s18,s2
                fmuls s19,s19,s3
                fmuls s20,s20,s4
                fmuls s21,s21,s5
                fmuls s22,s22,s6
                fmuls s23,s23,s7
                fadds s16,s16,s24
                fadds s17,s17,s24
                fadds s18,s18,s24
                fadds s19,s19,s24
                fadds s20,s20,s24
                fadds s21,s21,s24
                fadds s22,s22,s24
                fadds s23,s23,s24
                // load sine
                // doubling cosine/sine
                fmuls s0,s8,s16 // c*s
                fmuls s1,s9,s17
                fmuls s2,s10,s18
                fmuls s3,s11,s19
                fmuls s4,s12,s20
                fmuls s5,s13,s21
                fmuls s6,s14,s22
                fmuls s7,s15,s23
                fmuls s16,s16,s16 // c*c
                fmuls s17,s17,s17
                fmuls s18,s18,s18
                fmuls s19,s19,s19
                fmuls s20,s20,s20
                fmuls s21,s21,s21
                fmuls s22,s22,s22
                fmuls s23,s23,s23
                fnmacs s16,s8,s8  // c*c-s*s = x
                fnmacs s17,s9,s9
                fnmacs s18,s10,s10
                fnmacs s19,s11,s11
                fnmacs s20,s12,s12
                fnmacs s21,s13,s13
                fnmacs s22,s14,s14
                fnmacs s23,s15,s15
                fadds s0,s0,s0  // 2*s*c = y
                fadds s1,s1,s1
                fadds s2,s2,s2
                fadds s3,s3,s3
                fadds s4,s4,s4
                fadds s5,s5,s5
                fadds s6,s6,s6
                fadds s7,s7,s7
                fmuls s8,s0,s16 // cd1 = x*y
                fmuls s9,s1,s17
                fmuls s10,s2,s18
                fmuls s11,s3,s19
                fmuls s12,s4,s20
                fmuls s13,s5,s21
                fmuls s14,s6,s22
                fmuls s15,s7,s23
                fmuls s0,s0,s0 // cd3 = y*y
                fmuls s1,s1,s1
                fmuls s2,s2,s2
                fmuls s3,s3,s3
                fmuls s4,s4,s4
                fmuls s5,s5,s5
                fmuls s6,s6,s6
                fmuls s7,s7,s7
                fmuls s24,s16,s16 // cd2 = x*x
                fmuls s25,s17,s17
                fmuls s26,s18,s18
                fmuls s27,s19,s19
                fmuls s28,s20,s20
                fmuls s29,s21,s21
                fmuls s30,s22,s22
                fmuls s31,s23,s23
                fadds s24,s24,s0  // norm = x*x+y*y
                fadds s25,s25,s1
                fadds s26,s26,s2
                fadds s27,s27,s3
                fadds s28,s28,s4
                fadds s29,s29,s5
                fadds s30,s30,s6
                fadds s31,s31,s7
                fmscs s0,s16,s16   // c = x*x-y*y
                fmscs s1,s17,s17
                fmscs s2,s18,s18
                fmscs s3,s19,s19
                fmscs s4,s20,s20
                fmscs s5,s21,s21
                fmscs s6,s22,s22
                fmscs s7,s23,s23
                fadds s16,s8,s8     // s = 2*x*y
                fadds s17,s9,s9
                fadds s18,s10,s10
                fadds s19,s11,s11
                fadds s20,s12,s12
                fadds s21,s13,s13
                fadds s22,s14,s14
                fadds s23,s15,s15
                fsts s7,[sp,#24+64]
                flds s7,.Ltwos
                fstmias r7,{s16,s17,s18,s19,s20,s21,s22,s23}
                // reciprocal of magnitude
                // iter 1: invmag = 2.0-mag
                fsubs s8,s7,s24
                fsubs s9,s7,s25
                fsubs s10,s7,s26
                fsubs s11,s7,s27
                fsubs s12,s7,s28
                fsubs s13,s7,s29
                fsubs s14,s7,s30
                fsubs s15,s7,s31
                // iter 2: invmag = invmag*(2.0-mag*invmag)
                fmuls s16,s8,s24
                fmuls s17,s9,s25
                fmuls s18,s10,s26
                fmuls s19,s11,s27
                fmuls s20,s12,s28
                fmuls s21,s13,s29
                fmuls s22,s14,s30
                fmuls s23,s15,s31
                fsubs s16,s7,s16
                fsubs s17,s7,s17
                fsubs s18,s7,s18
                fsubs s19,s7,s19
                fsubs s20,s7,s20
                fsubs s21,s7,s21
                fsubs s22,s7,s22
                fsubs s23,s7,s23
                fmuls s8,s16,s8
                fmuls s9,s17,s9
                fmuls s10,s18,s10
                fmuls s11,s19,s11
                fmuls s12,s20,s12
                fmuls s13,s21,s13
                fmuls s14,s22,s14
                fmuls s15,s23,s15
                // iter 3: invmag = invmag*(2.0-mag*invmag)
                fmuls s16,s8,s24
                fmuls s17,s9,s25
                fmuls s18,s10,s26
                fmuls s19,s11,s27
                fmuls s20,s12,s28
                fmuls s21,s13,s29
                fmuls s22,s14,s30
                fmuls s23,s15,s31
                fsubs s16,s7,s16
                fsubs s17,s7,s17
                fsubs s18,s7,s18
                fsubs s19,s7,s19
                fsubs s20,s7,s20
                fsubs s21,s7,s21
                fsubs s22,s7,s22
                fsubs s23,s7,s23
                fmuls s8,s16,s8
                fmuls s9,s17,s9
                fmuls s10,s18,s10
                fmuls s11,s19,s11
                fmuls s12,s20,s12
                fmuls s13,s21,s13
                fmuls s14,s22,s14
                fmuls s15,s23,s15
                // restore sine values
                fldmias r7,{s16,s17,s18,s19,s20,s21,s22,s23}
                // correct cosine/sine
                flds s7,[sp,#24+64]
                fmuls s0,s0,s8
                fmuls s1,s1,s9
                fmuls s2,s2,s10
                fmuls s3,s3,s11
                fmuls s4,s4,s12
                fmuls s5,s5,s13
                fmuls s6,s6,s14
                fmuls s7,s7,s15
                fmuls s16,s16,s8
                fmuls s17,s17,s9
                fmuls s18,s18,s10
                fmuls s19,s19,s11
                fmuls s20,s20,s12
                fmuls s21,s21,s13
                fmuls s22,s22,s14
                fmuls s23,s23,s15
                pld [r0,#128]
                // multiply by data
                fldmias r0!,{s8,s9,s10,s11,s12,s13,s14,s15}
                fmuls s24,s8,s0
                fmuls s25,s9,s0
                fmuls s26,s10,s1
                fmuls s27,s11,s1
                fmuls s28,s12,s2
                fmuls s29,s13,s2
                fmuls s30,s14,s3
                fmuls s31,s15,s3
                fnmacs s24,s9,s16
                fmacs s25,s8,s16
                fnmacs s26,s11,s17
                fmacs s27,s10,s17
                fnmacs s28,s13,s18
                fmacs s29,s12,s18
                fnmacs s30,s15,s19
                fmacs s31,s14,s19
                fstmias r1!,{s24,s25,s26,s27,s28,s29,s30,s31}
                pld [r0,#128]
                fldmias r0!,{s8,s9,s10,s11,s12,s13,s14,s15}
                fmuls s24,s8,s4
                fmuls s25,s9,s4
                fmuls s26,s10,s5
                fmuls s27,s11,s5
                fmuls s28,s12,s6
                fmuls s29,s13,s6
                fmuls s30,s14,s7
                fmuls s31,s15,s7
                fnmacs s24,s9,s20
                fmacs s25,s8,s20
                fnmacs s26,s11,s21
                fmacs s27,s10,s21
                fnmacs s28,s13,s22
                fmacs s29,s12,s22
                fnmacs s30,s15,s23
                fmacs s31,s14,s23
                fstmias r1!,{s24,s25,s26,s27,s28,s29,s30,s31}
                
                add r4,r4,#8
                cmp r0,r3
                blo .Lmainloop
.Lendmainloop:
                add r3,r3,#8*7
                cmp r0,r3
                bhs .Lendsmallloop
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
                add sp,sp,#24+32+8
.Lendoffunc:
                mov r0,#0
                vpop {d8,d9,d10,d11,d12,d13,d14,d15}
                pop {r4,r5,r6,r7,r8,lr}
                bx lr
                
                .align  2
.LGOT1:
                .word _GLOBAL_OFFSET_TABLE_-(.LPIC1+8)
                .word analysis_state(GOT)
.Ltwos:
                .float 2.0
/*
 * vfp_FoldSubs.S
 * Author: Mateusz Szpakowski
 */
 
                .arch armv6
                .fpu vfp
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
.Lzeros:
                .float 0.0,0.0
                
                .global vfp_foldArrayBy3_ll31
                .type vfp_foldArrayBy3_ll31, %function
vfp_foldArrayBy3_ll31:
                push {r4,r5,r6,lr}
                vpush {d8,d9,d10,d11,d12}
                
                ldr r0,[r0] // ss0
                ldrd r2,[r1,#8] // tmp0
                add r2,r0,r2,lsl #2
                add r3,r0,r3,lsl #2
                ldrd r4,[r1]  // di,dest
                add r6,r0,r4,lsl #2 // end
                
                fldd d12,.Lzeros
                sub r6,r6,#4*7
                cmp r0,r6
                bhs .Lendf3loop2
.Lf3loop2:
.macro FOLDBY3_CORE
                fldmias r0!,{s0,s1,s2,s3,s4,s5,s6,s7}
                fldmias r2!,{s8,s9,s10,s11,s12,s13,s14,s15}
                fldmias r3!,{s16,s17,s18,s19,s20,s21,s22,s23}
                
                fadds s0,s0,s8
                fadds s1,s1,s9
                fadds s2,s2,s10
                fadds s3,s3,s11
                fadds s4,s4,s12
                fadds s5,s5,s13
                fadds s6,s6,s14
                fadds s7,s7,s15
                fadds s0,s0,s16
                fadds s1,s1,s17
                fadds s2,s2,s18
                fadds s3,s3,s19
                fadds s4,s4,s20
                fadds s5,s5,s21
                fadds s6,s6,s22
                fadds s7,s7,s23
                fstmias r5!,{s0,s1,s2,s3,s4,s5,s6,s7}
                
                fcmpes s24,s0
                fmstat
                fcmpes s25,s1
                fcpysmi s24,s0
                fmstat
                fcmpes s24,s2
                fcpysmi s25,s1
                fmstat
                fcmpes s25,s3
                fcpysmi s24,s2
                fmstat
                fcmpes s24,s4
                fcpysmi s25,s3
                fmstat
                fcmpes s25,s5
                fcpysmi s24,s4
                fmstat
                fcmpes s24,s6
                fcpysmi s25,s5
                fmstat
                fcmpes s25,s7
                fcpysmi s24,s6
                fmstat
                fcpysmi s25,s7
.endm
                FOLDBY3_CORE

                cmp r0,r6
                blo .Lf3loop2
.Lendf3loop2:
                and r4,r4,#7
                cmp r4,#4
                blo .Lf3lt4
                beq .Lf3eq4

                cmp r4,#6
                blo .Lf3lt6                
                beq .Lf3eq6
                
                fldmias r0!,{s0,s1,s2,s3,s4,s5,s6}
                fldmias r2!,{s8,s9,s10,s11,s12,s13,s14}
                fldmias r3!,{s16,s17,s18,s19,s20,s21,s22}
                
                fadds s0,s0,s8
                fadds s1,s1,s9
                fadds s2,s2,s10
                fadds s3,s3,s11
                fadds s4,s4,s12
                fadds s5,s5,s13
                fadds s6,s6,s14
                fadds s0,s0,s16
                fadds s1,s1,s17
                fadds s2,s2,s18
                fadds s3,s3,s19
                fadds s4,s4,s20
                fadds s5,s5,s21
                fadds s6,s6,s22
                fstmias r5!,{s0,s1,s2,s3,s4,s5,s6}
                
                fcmpes s24,s0
                fmstat
                fcmpes s25,s1
                fcpysmi s24,s0
                fmstat
                fcmpes s24,s2
                fcpysmi s25,s1
                fmstat
                fcmpes s25,s3
                fcpysmi s24,s2
                fmstat
                fcmpes s24,s4
                fcpysmi s25,s3
                fmstat
                fcmpes s25,s5
                fcpysmi s24,s4
                fmstat
                fcmpes s24,s6
                fcpysmi s25,s5
                fmstat
                fcpysmi s24,s6
                b .Lf3end
.Lf3eq6:
                fldmias r0!,{s0,s1,s2,s3,s4,s5}
                fldmias r2!,{s8,s9,s10,s11,s12,s13}
                fldmias r3!,{s16,s17,s18,s19,s20,s21}
                
                fadds s0,s0,s8
                fadds s1,s1,s9
                fadds s2,s2,s10
                fadds s3,s3,s11
                fadds s4,s4,s12
                fadds s5,s5,s13
                fadds s0,s0,s16
                fadds s1,s1,s17
                fadds s2,s2,s18
                fadds s3,s3,s19
                fadds s4,s4,s20
                fadds s5,s5,s21
                fstmias r5!,{s0,s1,s2,s3,s4,s5}
                
                fcmpes s24,s0
                fmstat
                fcmpes s25,s1
                fcpysmi s24,s0
                fmstat
                fcmpes s24,s2
                fcpysmi s25,s1
                fmstat
                fcmpes s25,s3
                fcpysmi s24,s2
                fmstat
                fcmpes s24,s4
                fcpysmi s25,s3
                fmstat
                fcmpes s25,s5
                fcpysmi s24,s4
                fmstat
                fcpysmi s25,s5
                b .Lf3end
.Lf3lt6:
                fldmias r0!,{s0,s1,s2,s3,s4}
                fldmias r2!,{s8,s9,s10,s11,s12}
                fldmias r3!,{s16,s17,s18,s19,s20}
                
                fadds s0,s0,s8
                fadds s1,s1,s9
                fadds s2,s2,s10
                fadds s3,s3,s11
                fadds s4,s4,s12
                fadds s0,s0,s16
                fadds s1,s1,s17
                fadds s2,s2,s18
                fadds s3,s3,s19
                fadds s4,s4,s20
                fstmias r5!,{s0,s1,s2,s3,s4}
                
                fcmpes s24,s0
                fmstat
                fcmpes s25,s1
                fcpysmi s24,s0
                fmstat
                fcmpes s24,s2
                fcpysmi s25,s1
                fmstat
                fcmpes s25,s3
                fcpysmi s24,s2
                fmstat
                fcmpes s24,s4
                fcpysmi s25,s3
                fmstat
                fcpysmi s24,s4
                b .Lf3end
.Lf3eq4:
                fldmias r0!,{s0,s1,s2,s3}
                fldmias r2!,{s8,s9,s10,s11}
                fldmias r3!,{s16,s17,s18,s19}
                
                fadds s0,s0,s8
                fadds s1,s1,s9
                fadds s2,s2,s10
                fadds s3,s3,s11
                fadds s0,s0,s16
                fadds s1,s1,s17
                fadds s2,s2,s18
                fadds s3,s3,s19
                fstmias r5!,{s0,s1,s2,s3}
                
                fcmpes s24,s0
                fmstat
                fcmpes s25,s1
                fcpysmi s24,s0
                fmstat
                fcmpes s24,s2
                fcpysmi s25,s1
                fmstat
                fcmpes s25,s3
                fcpysmi s24,s2
                fmstat
                fcpysmi s25,s3
                b .Lf3end
.Lf3lt4:
                cmp r4,#2
                blo .Lf3lt2
                beq .Lf3eq2
                
                fldmias r0!,{s0,s1,s2}
                fldmias r2!,{s8,s9,s10}
                fldmias r3!,{s16,s17,s18}
                
                fadds s0,s0,s8
                fadds s1,s1,s9
                fadds s2,s2,s10
                fadds s0,s0,s16
                fadds s1,s1,s17
                fadds s2,s2,s18
                fstmias r5!,{s0,s1,s2}
                
                fcmpes s24,s0
                fmstat
                fcmpes s25,s1
                fcpysmi s24,s0
                fmstat
                fcmpes s24,s2
                fcpysmi s25,s1
                fmstat
                fcpysmi s24,s2
                b .Lf3end
.Lf3eq2:
                fldmias r0!,{s0,s1}
                fldmias r2!,{s8,s9}
                fldmias r3!,{s16,s17}
                
                fadds s0,s0,s8
                fadds s1,s1,s9
                fadds s0,s0,s16
                fadds s1,s1,s17
                fstmias r5!,{s0,s1}
                
                fcmpes s24,s0
                fmstat
                fcmpes s25,s1
                fcpysmi s24,s0
                fmstat
                fcpysmi s25,s1
                b .Lf3end
.Lf3lt2:
                cmp r4,#0
                beq .Lf3eq0
                fldmias r0!,{s0}
                fldmias r2!,{s1}
                fldmias r3!,{s2}
                
                fadds s0,s0,s1
                fadds s0,s0,s2
                fstmias r5!,{s0}
                
                fcmpes s24,s0
                fmstat
                fcpysmi s24,s0
.Lf3eq0:

.Lf3end:
                fcmpes s24,s25
                fmstat
                fcpysmi s24,s25
                
                fmrs r0,s24
                vpop {d8,d9,d10,d11,d12}
                pop {r4,r5,r6,lr}
                bx lr
                
.Lzeros1:
                .float 0.0,0.0
                
                .global vfp_foldArrayBy3_lge31
                .type vfp_foldArrayBy3_lge31, %function
vfp_foldArrayBy3_lge31:
                push {r4,r5,r6,lr}
                vpush {d8,d9,d10,d11,d12}
                
                ldr r0,[r0] // ss0
                ldrd r2,[r1,#8] // tmp0
                add r2,r0,r2,lsl #2
                add r3,r0,r3,lsl #2
                ldrd r4,[r1]  // di,dest
                add r6,r0,r4,lsl #2 // end
                
                fldd d12,.Lzeros1
                sub r6,r6,#4*31
                cmp r0,r6
                bhs .Lendf3loop4
.Lf3loop4:
                FOLDBY3_CORE
                FOLDBY3_CORE
                FOLDBY3_CORE
                FOLDBY3_CORE
                
                cmp r0,r6
                blo .Lf3loop4
.Lendf3loop4:
                add r6,r6,#4*24
                cmp r0,r6
                bhs .Lendf3loop2
.Lf3loop5:
                FOLDBY3_CORE
                
                cmp r0,r6
                blo .Lf3loop5
.Lendf3loop5:
                b .Lendf3loop2                
                
.Lfoldby3sel:
.rept 31
                .word vfp_foldArrayBy3_ll31
.endr
                .word vfp_foldArrayBy3_lge31
                
.Lzeros2:
                .float 0.0,0.0
                /*****
                 * fold array by 4
                 ******/
                .global vfp_foldArrayBy4_ll31
                .type vfp_foldArrayBy4_ll31, %function
vfp_foldArrayBy4_ll31:
                push {r4,r5,r6,r7,r8,lr}
                vpush {d8,d9,d10,d11,d12}
                
                ldr r0,[r0] // ss0
                ldrd r2,[r1,#8] // tmp0
                ldr r6,[r1,#16] // tmp2
                add r2,r0,r2,lsl #2
                add r3,r0,r3,lsl #2
                add r6,r0,r6,lsl #2
                ldrd r4,[r1]  // di,dest
                add r7,r0,r4,lsl #2 // end
                
                fldd d12,.Lzeros2
                sub r7,r7,#4*7
                cmp r0,r7
                bhs .Lendf4loop2
.Lf4loop2:
.macro FOLDBY4_CORE
                fldmias r0!,{s0,s1,s2,s3,s4,s5,s6,s7}
                fldmias r2!,{s8,s9,s10,s11,s12,s13,s14,s15}
                fldmias r3!,{s16,s17,s18,s19,s20,s21,s22,s23}
                
                fadds s0,s0,s8
                fadds s1,s1,s9
                fadds s2,s2,s10
                fadds s3,s3,s11
                fadds s4,s4,s12
                fadds s5,s5,s13
                fadds s6,s6,s14
                fadds s7,s7,s15
                fadds s0,s0,s16
                fadds s1,s1,s17
                fadds s2,s2,s18
                fadds s3,s3,s19
                fldmias r6!,{s8,s9,s10,s11,s12,s13,s14,s15}
                fadds s4,s4,s20
                fadds s5,s5,s21
                fadds s6,s6,s22
                fadds s7,s7,s23
                fadds s0,s0,s8
                fadds s1,s1,s9
                fadds s2,s2,s10
                fadds s3,s3,s11
                fadds s4,s4,s12
                fadds s5,s5,s13
                fadds s6,s6,s14
                fadds s7,s7,s15
                
                fstmias r5!,{s0,s1,s2,s3,s4,s5,s6,s7}
                
                fcmpes s24,s0
                fmstat
                fcmpes s25,s1
                fcpysmi s24,s0
                fmstat
                fcmpes s24,s2
                fcpysmi s25,s1
                fmstat
                fcmpes s25,s3
                fcpysmi s24,s2
                fmstat
                fcmpes s24,s4
                fcpysmi s25,s3
                fmstat
                fcmpes s25,s5
                fcpysmi s24,s4
                fmstat
                fcmpes s24,s6
                fcpysmi s25,s5
                fmstat
                fcmpes s25,s7
                fcpysmi s24,s6
                fmstat
                fcpysmi s25,s7
.endm
                FOLDBY4_CORE

                cmp r0,r7
                blo .Lf4loop2
.Lendf4loop2:
                and r4,r4,#7
                cmp r4,#4
                blo .Lf4lt4
                beq .Lf4eq4

                cmp r4,#6
                blo .Lf4lt6                
                beq .Lf4eq6
                
                fldmias r0!,{s0,s1,s2,s3,s4,s5,s6}
                fldmias r2!,{s8,s9,s10,s11,s12,s13,s14}
                fldmias r3!,{s16,s17,s18,s19,s20,s21,s22}
                
                fadds s0,s0,s8
                fadds s1,s1,s9
                fadds s2,s2,s10
                fadds s3,s3,s11
                fadds s4,s4,s12
                fadds s5,s5,s13
                fadds s6,s6,s14
                fadds s0,s0,s16
                fadds s1,s1,s17
                fadds s2,s2,s18
                fadds s3,s3,s19
                fadds s4,s4,s20
                fadds s5,s5,s21
                fadds s6,s6,s22
                fldmias r6!,{s16,s17,s18,s19,s20,s21,s22}
                fadds s0,s0,s16
                fadds s1,s1,s17
                fadds s2,s2,s18
                fadds s3,s3,s19
                fadds s4,s4,s20
                fadds s5,s5,s21
                fadds s6,s6,s22
                fstmias r5!,{s0,s1,s2,s3,s4,s5,s6}
                
                fcmpes s24,s0
                fmstat
                fcmpes s25,s1
                fcpysmi s24,s0
                fmstat
                fcmpes s24,s2
                fcpysmi s25,s1
                fmstat
                fcmpes s25,s3
                fcpysmi s24,s2
                fmstat
                fcmpes s24,s4
                fcpysmi s25,s3
                fmstat
                fcmpes s25,s5
                fcpysmi s24,s4
                fmstat
                fcmpes s24,s6
                fcpysmi s25,s5
                fmstat
                fcpysmi s24,s6
                b .Lf4end
.Lf4eq6:
                fldmias r0!,{s0,s1,s2,s3,s4,s5}
                fldmias r2!,{s6,s7,s8,s9,s10,s11}
                fldmias r3!,{s12,s13,s14,s15,s16,s17}
                fldmias r6!,{s18,s19,s20,s21,s22,s23}
                
                fadds s0,s0,s6
                fadds s1,s1,s7
                fadds s2,s2,s8
                fadds s3,s3,s9
                fadds s4,s4,s10
                fadds s5,s5,s11
                fadds s0,s0,s12
                fadds s1,s1,s13
                fadds s2,s2,s14
                fadds s3,s3,s15
                fadds s4,s4,s16
                fadds s5,s5,s17
                fadds s0,s0,s18
                fadds s1,s1,s19
                fadds s2,s2,s20
                fadds s3,s3,s21
                fadds s4,s4,s22
                fadds s5,s5,s23
                fstmias r5!,{s0,s1,s2,s3,s4,s5}
                
                fcmpes s24,s0
                fmstat
                fcmpes s25,s1
                fcpysmi s24,s0
                fmstat
                fcmpes s24,s2
                fcpysmi s25,s1
                fmstat
                fcmpes s25,s3
                fcpysmi s24,s2
                fmstat
                fcmpes s24,s4
                fcpysmi s25,s3
                fmstat
                fcmpes s25,s5
                fcpysmi s24,s4
                fmstat
                fcpysmi s25,s5
                b .Lf4end
.Lf4lt6:
                fldmias r0!,{s0,s1,s2,s3,s4}
                fldmias r2!,{s6,s7,s8,s9,s10}
                fldmias r3!,{s12,s13,s14,s15,s16}
                fldmias r6!,{s18,s19,s20,s21,s22}
                
                fadds s0,s0,s6
                fadds s1,s1,s7
                fadds s2,s2,s8
                fadds s3,s3,s9
                fadds s4,s4,s10
                fadds s0,s0,s12
                fadds s1,s1,s13
                fadds s2,s2,s14
                fadds s3,s3,s15
                fadds s4,s4,s16
                fadds s0,s0,s18
                fadds s1,s1,s19
                fadds s2,s2,s20
                fadds s3,s3,s21
                fadds s4,s4,s22
                fstmias r5!,{s0,s1,s2,s3,s4}
                
                fcmpes s24,s0
                fmstat
                fcmpes s25,s1
                fcpysmi s24,s0
                fmstat
                fcmpes s24,s2
                fcpysmi s25,s1
                fmstat
                fcmpes s25,s3
                fcpysmi s24,s2
                fmstat
                fcmpes s24,s4
                fcpysmi s25,s3
                fmstat
                fcpysmi s24,s4
                b .Lf4end
.Lf4eq4:
                fldmias r0!,{s0,s1,s2,s3}
                fldmias r2!,{s6,s7,s8,s9}
                fldmias r3!,{s12,s13,s14,s15}
                fldmias r6!,{s18,s19,s20,s21}
                
                fadds s0,s0,s6
                fadds s1,s1,s7
                fadds s2,s2,s8
                fadds s3,s3,s9
                fadds s0,s0,s12
                fadds s1,s1,s13
                fadds s2,s2,s14
                fadds s3,s3,s15
                fadds s0,s0,s18
                fadds s1,s1,s19
                fadds s2,s2,s20
                fadds s3,s3,s21
                fstmias r5!,{s0,s1,s2,s3}
                
                fcmpes s24,s0
                fmstat
                fcmpes s25,s1
                fcpysmi s24,s0
                fmstat
                fcmpes s24,s2
                fcpysmi s25,s1
                fmstat
                fcmpes s25,s3
                fcpysmi s24,s2
                fmstat
                fcpysmi s25,s3
                b .Lf4end
.Lf4lt4:
                cmp r4,#2
                blo .Lf4lt2
                beq .Lf4eq2
                
                fldmias r0!,{s0,s1,s2}
                fldmias r2!,{s6,s7,s8}
                fldmias r3!,{s12,s13,s14}
                fldmias r6!,{s18,s19,s20}
                
                fadds s0,s0,s6
                fadds s1,s1,s7
                fadds s2,s2,s8
                fadds s0,s0,s12
                fadds s1,s1,s13
                fadds s2,s2,s14
                fadds s0,s0,s18
                fadds s1,s1,s19
                fadds s2,s2,s20
                fstmias r5!,{s0,s1,s2}
                
                fcmpes s24,s0
                fmstat
                fcmpes s25,s1
                fcpysmi s24,s0
                fmstat
                fcmpes s24,s2
                fcpysmi s25,s1
                fmstat
                fcpysmi s24,s2
                b .Lf4end
.Lf4eq2:
                fldmias r0!,{s0,s1}
                fldmias r2!,{s6,s7}
                fldmias r3!,{s12,s13}
                fldmias r6!,{s18,s19}
                
                fadds s0,s0,s6
                fadds s1,s1,s7
                fadds s0,s0,s12
                fadds s1,s1,s13
                fadds s0,s0,s18
                fadds s1,s1,s19
                fstmias r5!,{s0,s1}
                
                fcmpes s24,s0
                fmstat
                fcmpes s25,s1
                fcpysmi s24,s0
                fmstat
                fcpysmi s25,s1
                b .Lf4end
.Lf4lt2:
                cmp r4,#0
                beq .Lf4eq0
                fldmias r0!,{s0}
                fldmias r2!,{s1}
                fldmias r3!,{s2}
                fldmias r6!,{s3}
                
                fadds s0,s0,s1
                fadds s0,s0,s2
                fadds s0,s0,s3
                fstmias r5!,{s0}
                
                fcmpes s24,s0
                fmstat
                fcpysmi s24,s0
.Lf4eq0:
                
.Lf4end:
                fcmpes s24,s25
                fmstat
                fcpysmi s24,s25
                
                fmrs r0,s24
                vpop {d8,d9,d10,d11,d12}
                pop {r4,r5,r6,r7,r8,lr}
                bx lr
                
.Lzeros2_1:
                .float 0.0,0.0
                .global vfp_foldArrayBy4_lge31
                .type vfp_foldArrayBy4_lge31, %function
vfp_foldArrayBy4_lge31:
                push {r4,r5,r6,r7,r8,lr}
                vpush {d8,d9,d10,d11,d12}
                
                ldr r0,[r0] // ss0
                ldrd r2,[r1,#8] // tmp0
                ldr r6,[r1,#16] // tmp2
                add r2,r0,r2,lsl #2
                add r3,r0,r3,lsl #2
                add r6,r0,r6,lsl #2
                ldrd r4,[r1]  // di,dest
                add r7,r0,r4,lsl #2 // end
               
                fldd d12,.Lzeros2_1
                sub r7,r7,#4*31
                cmp r0,r7
                bhs .Lendf4loop4
.Lf4loop4:
                FOLDBY4_CORE
                FOLDBY4_CORE
                FOLDBY4_CORE
                FOLDBY4_CORE

                cmp r0,r7
                blo .Lf4loop4
.Lendf4loop4:
                add r7,r7,#4*24
                cmp r0,r7
                bhs .Lendf4loop2
.Lf4loop5:
                FOLDBY4_CORE
                
                cmp r0,r7
                blo .Lf4loop5
.Lendf4loop5:
                b .Lendf4loop2
                
.Lfoldby4sel:
.rept 31
                .word vfp_foldArrayBy4_ll31
.endr
                .word vfp_foldArrayBy4_lge31

.Lzeros3:
                .float 0.0,0.0
                /*****
                 * fold array by 5 
                 ******/
                .global vfp_foldArrayBy5_ll31
                .type vfp_foldArrayBy5_ll31, %function
vfp_foldArrayBy5_ll31:
                push {r4,r5,r6,r7,r8,lr}
                vpush {d8,d9,d10,d11,d12}
                
                ldr r0,[r0] // ss0
                ldrd r2,[r1,#8] // tmp0
                ldrd r6,[r1,#16] // tmp2,tmp3
                add r2,r0,r2,lsl #2
                add r3,r0,r3,lsl #2
                add r6,r0,r6,lsl #2
                add r7,r0,r7,lsl #2
                ldrd r4,[r1]  // di,dest
                add r8,r0,r4,lsl #2 // end
                
                fldd d12,.Lzeros3
                sub r8,r8,#4*7
                cmp r0,r8
                bhs .Lendf5loop2
.Lf5loop2:
.macro FOLDBY5_CORE
                fldmias r0!,{s0,s1,s2,s3,s4,s5,s6,s7}
                fldmias r2!,{s8,s9,s10,s11,s12,s13,s14,s15}
                fldmias r3!,{s16,s17,s18,s19,s20,s21,s22,s23}
                
                fadds s0,s0,s8
                fadds s1,s1,s9
                fadds s2,s2,s10
                fadds s3,s3,s11
                fadds s4,s4,s12
                fadds s5,s5,s13
                fadds s6,s6,s14
                fadds s7,s7,s15
                fadds s0,s0,s16
                fadds s1,s1,s17
                fadds s2,s2,s18
                fadds s3,s3,s19
                fldmias r6!,{s8,s9,s10,s11,s12,s13,s14,s15}
                fadds s4,s4,s20
                fadds s5,s5,s21
                fadds s6,s6,s22
                fadds s7,s7,s23
                fadds s0,s0,s8
                fadds s1,s1,s9
                fadds s2,s2,s10
                fadds s3,s3,s11
                fadds s4,s4,s12
                fldmias r7!,{s16,s17,s18,s19,s20,s21,s22,s23}
                fadds s5,s5,s13
                fadds s6,s6,s14
                fadds s7,s7,s15
                fadds s0,s0,s16
                fadds s1,s1,s17
                fadds s2,s2,s18
                fadds s3,s3,s19
                fadds s4,s4,s20
                fadds s5,s5,s21
                fadds s6,s6,s22
                fadds s7,s7,s23
                
                fstmias r5!,{s0,s1,s2,s3,s4,s5,s6,s7}
                
                fcmpes s24,s0
                fmstat
                fcmpes s25,s1
                fcpysmi s24,s0
                fmstat
                fcmpes s24,s2
                fcpysmi s25,s1
                fmstat
                fcmpes s25,s3
                fcpysmi s24,s2
                fmstat
                fcmpes s24,s4
                fcpysmi s25,s3
                fmstat
                fcmpes s25,s5
                fcpysmi s24,s4
                fmstat
                fcmpes s24,s6
                fcpysmi s25,s5
                fmstat
                fcmpes s25,s7
                fcpysmi s24,s6
                fmstat
                fcpysmi s25,s7
.endm
                FOLDBY5_CORE
                
                cmp r0,r8
                blo .Lf5loop2
.Lendf5loop2:
                and r4,r4,#7
                cmp r4,#4
                blo .Lf5lt4
                beq .Lf5eq4

                cmp r4,#6
                blo .Lf5lt6                
                beq .Lf5eq6
                
                fldmias r0!,{s0,s1,s2,s3,s4,s5,s6}
                fldmias r2!,{s8,s9,s10,s11,s12,s13,s14}
                fldmias r3!,{s16,s17,s18,s19,s20,s21,s22}
                
                fadds s0,s0,s8
                fadds s1,s1,s9
                fadds s2,s2,s10
                fadds s3,s3,s11
                fadds s4,s4,s12
                fadds s5,s5,s13
                fadds s6,s6,s14
                fadds s0,s0,s16
                fadds s1,s1,s17
                fadds s2,s2,s18
                fadds s3,s3,s19
                fadds s4,s4,s20
                fadds s5,s5,s21
                fadds s6,s6,s22
                fldmias r6!,{s16,s17,s18,s19,s20,s21,s22}
                fadds s0,s0,s16
                fadds s1,s1,s17
                fadds s2,s2,s18
                fadds s3,s3,s19
                fadds s4,s4,s20
                fadds s5,s5,s21
                fadds s6,s6,s22
                fldmias r7!,{s16,s17,s18,s19,s20,s21,s22}
                fadds s0,s0,s16
                fadds s1,s1,s17
                fadds s2,s2,s18
                fadds s3,s3,s19
                fadds s4,s4,s20
                fadds s5,s5,s21
                fadds s6,s6,s22
                fstmias r5!,{s0,s1,s2,s3,s4,s5,s6}
                
                fcmpes s24,s0
                fmstat
                fcmpes s25,s1
                fcpysmi s24,s0
                fmstat
                fcmpes s24,s2
                fcpysmi s25,s1
                fmstat
                fcmpes s25,s3
                fcpysmi s24,s2
                fmstat
                fcmpes s24,s4
                fcpysmi s25,s3
                fmstat
                fcmpes s25,s5
                fcpysmi s24,s4
                fmstat
                fcmpes s24,s6
                fcpysmi s25,s5
                fmstat
                fcpysmi s24,s6
                b .Lf5end
.Lf5eq6:
                fldmias r0!,{s0,s1,s2,s3,s4,s5}
                fldmias r2!,{s6,s7,s8,s9,s10,s11}
                fldmias r3!,{s12,s13,s14,s15,s16,s17}
                fldmias r6!,{s18,s19,s20,s21,s22,s23}
                
                fadds s0,s0,s6
                fadds s1,s1,s7
                fadds s2,s2,s8
                fadds s3,s3,s9
                fadds s4,s4,s10
                fadds s5,s5,s11
                fadds s0,s0,s12
                fadds s1,s1,s13
                fadds s2,s2,s14
                fadds s3,s3,s15
                fadds s4,s4,s16
                fadds s5,s5,s17
                fadds s0,s0,s18
                fadds s1,s1,s19
                fadds s2,s2,s20
                fadds s3,s3,s21
                fadds s4,s4,s22
                fadds s5,s5,s23
                fldmias r7!,{s18,s19,s20,s21,s22,s23}
                fadds s0,s0,s18
                fadds s1,s1,s19
                fadds s2,s2,s20
                fadds s3,s3,s21
                fadds s4,s4,s22
                fadds s5,s5,s23
                fstmias r5!,{s0,s1,s2,s3,s4,s5}
                
                fcmpes s24,s0
                fmstat
                fcmpes s25,s1
                fcpysmi s24,s0
                fmstat
                fcmpes s24,s2
                fcpysmi s25,s1
                fmstat
                fcmpes s25,s3
                fcpysmi s24,s2
                fmstat
                fcmpes s24,s4
                fcpysmi s25,s3
                fmstat
                fcmpes s25,s5
                fcpysmi s24,s4
                fmstat
                fcpysmi s25,s5
                b .Lf5end
.Lf5lt6:
                fldmias r0!,{s0,s1,s2,s3,s4}
                fldmias r2!,{s6,s7,s8,s9,s10}
                fldmias r3!,{s12,s13,s14,s15,s16}
                fldmias r6!,{s18,s19,s20,s21,s22}
                
                fadds s0,s0,s6
                fadds s1,s1,s7
                fadds s2,s2,s8
                fadds s3,s3,s9
                fadds s4,s4,s10
                fadds s0,s0,s12
                fadds s1,s1,s13
                fadds s2,s2,s14
                fadds s3,s3,s15
                fadds s4,s4,s16
                fadds s0,s0,s18
                fadds s1,s1,s19
                fadds s2,s2,s20
                fadds s3,s3,s21
                fadds s4,s4,s22
                fldmias r7!,{s18,s19,s20,s21,s22}
                fadds s0,s0,s18
                fadds s1,s1,s19
                fadds s2,s2,s20
                fadds s3,s3,s21
                fadds s4,s4,s22
                fstmias r5!,{s0,s1,s2,s3,s4}
                
                fcmpes s24,s0
                fmstat
                fcmpes s25,s1
                fcpysmi s24,s0
                fmstat
                fcmpes s24,s2
                fcpysmi s25,s1
                fmstat
                fcmpes s25,s3
                fcpysmi s24,s2
                fmstat
                fcmpes s24,s4
                fcpysmi s25,s3
                fmstat
                fcpysmi s24,s4
                b .Lf5end
.Lf5eq4:
                fldmias r0!,{s0,s1,s2,s3}
                fldmias r2!,{s4,s5,s6,s7}
                fldmias r3!,{s8,s9,s10,s11}
                fldmias r6!,{s12,s13,s14,s15}
                fldmias r7!,{s16,s17,s18,s19}
                
                fadds s0,s0,s4
                fadds s1,s1,s5
                fadds s2,s2,s6
                fadds s3,s3,s7
                fadds s0,s0,s8
                fadds s1,s1,s9
                fadds s2,s2,s10
                fadds s3,s3,s11
                fadds s0,s0,s12
                fadds s1,s1,s13
                fadds s2,s2,s14
                fadds s3,s3,s15
                fadds s0,s0,s16
                fadds s1,s1,s17
                fadds s2,s2,s18
                fadds s3,s3,s19
                fstmias r5!,{s0,s1,s2,s3}
                
                fcmpes s24,s0
                fmstat
                fcmpes s25,s1
                fcpysmi s24,s0
                fmstat
                fcmpes s24,s2
                fcpysmi s25,s1
                fmstat
                fcmpes s25,s3
                fcpysmi s24,s2
                fmstat
                fcpysmi s25,s3
                b .Lf5end
.Lf5lt4:
                cmp r4,#2
                blo .Lf5lt2
                beq .Lf5eq2
                
                fldmias r0!,{s0,s1,s2}
                fldmias r2!,{s4,s5,s6}
                fldmias r3!,{s8,s9,s10}
                fldmias r6!,{s12,s13,s14}
                fldmias r7!,{s16,s17,s18}
                
                fadds s0,s0,s4
                fadds s1,s1,s5
                fadds s2,s2,s6
                fadds s0,s0,s8
                fadds s1,s1,s9
                fadds s2,s2,s10
                fadds s0,s0,s12
                fadds s1,s1,s13
                fadds s2,s2,s14
                fadds s0,s0,s16
                fadds s1,s1,s17
                fadds s2,s2,s18
                fstmias r5!,{s0,s1,s2}
                
                fcmpes s24,s0
                fmstat
                fcmpes s25,s1
                fcpysmi s24,s0
                fmstat
                fcmpes s24,s2
                fcpysmi s25,s1
                fmstat
                fcpysmi s24,s2
                b .Lf5end
.Lf5eq2:
                fldmias r0!,{s0,s1}
                fldmias r2!,{s4,s5}
                fldmias r3!,{s8,s9}
                fldmias r6!,{s12,s13}
                fldmias r7!,{s16,s17}
                
                fadds s0,s0,s4
                fadds s1,s1,s5
                fadds s0,s0,s8
                fadds s1,s1,s9
                fadds s0,s0,s12
                fadds s1,s1,s13
                fadds s0,s0,s16
                fadds s1,s1,s17
                fstmias r5!,{s0,s1}
                
                fcmpes s24,s0
                fmstat
                fcmpes s25,s1
                fcpysmi s24,s0
                fmstat
                fcpysmi s25,s1
                b .Lf5end
.Lf5lt2:
                cmp r4,#0
                beq .Lf5eq0
                fldmias r0!,{s0}
                fldmias r2!,{s1}
                fldmias r3!,{s2}
                fldmias r6!,{s3}
                fldmias r7!,{s4}
                
                fadds s0,s0,s1
                fadds s0,s0,s2
                fadds s0,s0,s3
                fadds s0,s0,s4
                fstmias r5!,{s0}
                
                fcmpes s24,s0
                fmstat
                fcpysmi s24,s0
.Lf5eq0:

.Lf5end:        
                fcmpes s24,s25
                fmstat
                fcpysmi s24,s25
                
                fmrs r0,s24
                vpop {d8,d9,d10,d11,d12}
                pop {r4,r5,r6,r7,r8,lr}
                bx lr

.Lzeros3_1:
                .float 0.0,0.0
                
                .global vfp_foldArrayBy5_lge31
                .type vfp_foldArrayBy5_lge31, %function
vfp_foldArrayBy5_lge31:
                push {r4,r5,r6,r7,r8,lr}
                vpush {d8,d9,d10,d11,d12}
                
                ldr r0,[r0] // ss0
                ldrd r2,[r1,#8] // tmp0
                ldrd r6,[r1,#16] // tmp2,tmp3
                add r2,r0,r2,lsl #2
                add r3,r0,r3,lsl #2
                add r6,r0,r6,lsl #2
                add r7,r0,r7,lsl #2
                ldrd r4,[r1]  // di,dest
                add r8,r0,r4,lsl #2 // end
                
                fldd d12,.Lzeros3_1
                sub r8,r8,#4*31
                cmp r0,r8
                bhs .Lendf5loop4
.Lf5loop4:
                FOLDBY5_CORE
                FOLDBY5_CORE
                FOLDBY5_CORE
                FOLDBY5_CORE
                
                cmp r0,r8
                blo .Lf5loop4
.Lendf5loop4:
                add r8,r8,#4*24
                cmp r0,r8
                bhs .Lendf5loop2
.Lf5loop5:
                FOLDBY5_CORE
                
                cmp r0,r8
                blo .Lf5loop5
.Lendf5loop5:
                b .Lendf5loop2

.Lfoldby5sel:
.rept 31
                .word vfp_foldArrayBy5_ll31
.endr
                .word vfp_foldArrayBy5_lge31
                
.Lzeros4:
                .float 0.0,0.0
                /*****
                 * fold array by 2
                 ******/
                .global vfp_foldArrayBy2_ll31
                .type vfp_foldArrayBy2_ll31, %function
vfp_foldArrayBy2_ll31:
                push {r4,r5,r6,lr}
                vpush {d8,d9,d10,d11,d12}
                
                ldr r0,[r0,#4] // ss1
                ldrd r2,[r1,#8] // tmp0
                add r2,r0,r2,lsl #2
                add r3,r0,r3,lsl #2
                ldrd r4,[r1]  // di,dest
                add r6,r2,r4,lsl #2 // end
                
                fldd d12,.Lzeros4
                sub r6,r6,#4*7
                cmp r2,r6
                bhs .Lendf2loop2
.Lf2loop2:
.macro FOLDBY2_CORE
                fldmias r2!,{s0,s1,s2,s3,s4,s5,s6,s7}
                fldmias r3!,{s8,s9,s10,s11,s12,s13,s14,s15}
                
                fadds s0,s0,s8
                fadds s1,s1,s9
                fadds s2,s2,s10
                fadds s3,s3,s11
                fadds s4,s4,s12
                fadds s5,s5,s13
                fadds s6,s6,s14
                fadds s7,s7,s15
                fstmias r5!,{s0,s1,s2,s3,s4,s5,s6,s7}
                
                fcmpes s24,s0
                fmstat
                fcmpes s25,s1
                fcpysmi s24,s0
                fmstat
                fcmpes s24,s2
                fcpysmi s25,s1
                fmstat
                fcmpes s25,s3
                fcpysmi s24,s2
                fmstat
                fcmpes s24,s4
                fcpysmi s25,s3
                fmstat
                fcmpes s25,s5
                fcpysmi s24,s4
                fmstat
                fcmpes s24,s6
                fcpysmi s25,s5
                fmstat
                fcmpes s25,s7
                fcpysmi s24,s6
                fmstat
                fcpysmi s25,s7
.endm
                FOLDBY2_CORE

                cmp r2,r6
                blo .Lf2loop2
.Lendf2loop2:
                and r4,r4,#7
                cmp r4,#4
                blo .Lf2lt4
                beq .Lf2eq4

                cmp r4,#6
                blo .Lf2lt6                
                beq .Lf2eq6
                
                fldmias r2!,{s0,s1,s2,s3,s4,s5,s6}
                fldmias r3!,{s8,s9,s10,s11,s12,s13,s14}
                
                fadds s0,s0,s8
                fadds s1,s1,s9
                fadds s2,s2,s10
                fadds s3,s3,s11
                fadds s4,s4,s12
                fadds s5,s5,s13
                fadds s6,s6,s14
                fstmias r5!,{s0,s1,s2,s3,s4,s5,s6}
                
                fcmpes s24,s0
                fmstat
                fcmpes s25,s1
                fcpysmi s24,s0
                fmstat
                fcmpes s24,s2
                fcpysmi s25,s1
                fmstat
                fcmpes s25,s3
                fcpysmi s24,s2
                fmstat
                fcmpes s24,s4
                fcpysmi s25,s3
                fmstat
                fcmpes s25,s5
                fcpysmi s24,s4
                fmstat
                fcmpes s24,s6
                fcpysmi s25,s5
                fmstat
                fcpysmi s24,s6
                b .Lf2end
.Lf2eq6:
                fldmias r2!,{s0,s1,s2,s3,s4,s5}
                fldmias r3!,{s8,s9,s10,s11,s12,s13}
                
                fadds s0,s0,s8
                fadds s1,s1,s9
                fadds s2,s2,s10
                fadds s3,s3,s11
                fadds s4,s4,s12
                fadds s5,s5,s13
                fstmias r5!,{s0,s1,s2,s3,s4,s5}
                
                fcmpes s24,s0
                fmstat
                fcmpes s25,s1
                fcpysmi s24,s0
                fmstat
                fcmpes s24,s2
                fcpysmi s25,s1
                fmstat
                fcmpes s25,s3
                fcpysmi s24,s2
                fmstat
                fcmpes s24,s4
                fcpysmi s25,s3
                fmstat
                fcmpes s25,s5
                fcpysmi s24,s4
                fmstat
                fcpysmi s25,s5
                b .Lf2end
.Lf2lt6:
                fldmias r2!,{s0,s1,s2,s3,s4}
                fldmias r3!,{s8,s9,s10,s11,s12}
                
                fadds s0,s0,s8
                fadds s1,s1,s9
                fadds s2,s2,s10
                fadds s3,s3,s11
                fadds s4,s4,s12
                
                fstmias r5!,{s0,s1,s2,s3,s4}
                
                fcmpes s24,s0
                fmstat
                fcmpes s25,s1
                fcpysmi s24,s0
                fmstat
                fcmpes s24,s2
                fcpysmi s25,s1
                fmstat
                fcmpes s25,s3
                fcpysmi s24,s2
                fmstat
                fcmpes s24,s4
                fcpysmi s25,s3
                fmstat
                fcpysmi s24,s4
                b .Lf2end
.Lf2eq4:
                fldmias r2!,{s0,s1,s2,s3}
                fldmias r3!,{s8,s9,s10,s11}
                
                fadds s0,s0,s8
                fadds s1,s1,s9
                fadds s2,s2,s10
                fadds s3,s3,s11
                
                fstmias r5!,{s0,s1,s2,s3}
                
                fcmpes s24,s0
                fmstat
                fcmpes s25,s1
                fcpysmi s24,s0
                fmstat
                fcmpes s24,s2
                fcpysmi s25,s1
                fmstat
                fcmpes s25,s3
                fcpysmi s24,s2
                fmstat
                fcpysmi s25,s3
                b .Lf2end
.Lf2lt4:
                cmp r4,#2
                blo .Lf2lt2
                beq .Lf2eq2
                
                fldmias r2!,{s0,s1,s2}
                fldmias r3!,{s8,s9,s10}
                
                fadds s0,s0,s8
                fadds s1,s1,s9
                fadds s2,s2,s10
                
                fstmias r5!,{s0,s1,s2}
                
                fcmpes s24,s0
                fmstat
                fcmpes s25,s1
                fcpysmi s24,s0
                fmstat
                fcmpes s24,s2
                fcpysmi s25,s1
                fmstat
                fcpysmi s24,s2
                b .Lf2end
.Lf2eq2:
                fldmias r2!,{s0,s1}
                fldmias r3!,{s8,s9}
                
                fadds s0,s0,s8
                fadds s1,s1,s9
                
                fstmias r5!,{s0,s1}
                
                fcmpes s24,s0
                fmstat
                fcmpes s25,s1
                fcpysmi s24,s0
                fmstat
                fcpysmi s25,s1
                b .Lf2end
.Lf2lt2:
                cmp r4,#0
                beq .Lf2eq0
                fldmias r2!,{s0}
                fldmias r3!,{s1}
                
                fadds s0,s0,s1
                fstmias r5!,{s0}
                
                fcmpes s24,s0
                fmstat
                fcpysmi s24,s0
.Lf2eq0:

.Lf2end:
                fcmpes s24,s25
                fmstat
                fcpysmi s24,s25
                
                fmrs r0,s24
                vpop {d8,d9,d10,d11,d12}
                pop {r4,r5,r6,lr}
                bx lr
                
                .global vfp_foldArrayBy2_lge31
                .type vfp_foldArrayBy2_lge31, %function
vfp_foldArrayBy2_lge31:
                push {r4,r5,r6,lr}
                vpush {d8,d9,d10,d11,d12}
                
                ldr r0,[r0,#4] // ss1
                ldrd r2,[r1,#8] // tmp0
                add r2,r0,r2,lsl #2
                add r3,r0,r3,lsl #2
                ldrd r4,[r1]  // di,dest
                add r6,r2,r4,lsl #2 // end
                
                fldd d12,.Lzeros4
                sub r6,r6,#4*31
                cmp r2,r6
                bhs .Lendf2loop4
.Lf2loop4:
                FOLDBY2_CORE
                FOLDBY2_CORE
                FOLDBY2_CORE
                FOLDBY2_CORE

                cmp r2,r6
                blo .Lf2loop4
.Lendf2loop4:
                add r6,r6,#4*24
                cmp r2,r6
                bhs .Lendf2loop2
.Lf2loop5:
                FOLDBY2_CORE
                
                cmp r2,r6
                blo .Lf2loop5
                b .Lendf2loop2
                
.Lfoldby2sel:
.rept 31
                .word vfp_foldArrayBy2_ll31
.endr
                .word vfp_foldArrayBy2_lge31
                
                .align 2
.Lname:
                .string "opt VFP"
                
                .align 2
                .global vfpFoldMain
vfpFoldMain:
                .word .Lfoldby3sel
                .word .Lfoldby4sel
                .word .Lfoldby5sel
                .word .Lfoldby2sel
                .word .Lfoldby2sel
                .word .Lname
                /*
 * vfp_GetPowerSpectrum.S
 * Author: Mateusz Szpakowski
 */
 
                .arch armv6
                .fpu vfp
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
                .global _Z20vfp_GetPowerSpectrumPA2_fPfi
                .type   _Z20vfp_GetPowerSpectrumPA2_fPfi, %function
_Z20vfp_GetPowerSpectrumPA2_fPfi:
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
                
                add r2,r0,r2,lsl #3
                sub r2,r2,#15*8
                /* r0 - freqData
                 * r1 - PowerSpectrum
                 * r2 - end of freqData
                 */
                cmp r0,r2
                bhs .Lendmainloopa
.Lmainloopa:
                pld [r0,#64]
                fldmias r0!,{s0,s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11,s12,s13,s14,s15}
                fmuls s16,s0,s0
                fmuls s17,s2,s2
                fmuls s18,s4,s4
                fmuls s19,s6,s6
                fmuls s20,s8,s8
                fmuls s21,s10,s10
                fmuls s22,s12,s12
                fmuls s23,s14,s14
                fmacs s16,s1,s1
                fmacs s17,s3,s3
                fmacs s18,s5,s5
                fmacs s19,s7,s7
                fmacs s20,s9,s9
                fmacs s21,s11,s11
                fmacs s22,s13,s13
                fmacs s23,s15,s15
                
                pld [r0,#64]
                fldmias r0!,{s0,s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11,s12,s13,s14,s15}
                fstmias r1!,{s16,s17,s18,s19,s20,s21,s22,s23}
                
                fmuls s24,s0,s0
                fmuls s25,s2,s2
                fmuls s26,s4,s4
                fmuls s27,s6,s6
                fmuls s28,s8,s8
                fmuls s29,s10,s10
                fmuls s30,s12,s12
                fmuls s31,s14,s14
                fmacs s24,s1,s1
                fmacs s25,s3,s3
                fmacs s26,s5,s5
                fmacs s27,s7,s7
                fmacs s28,s9,s9
                fmacs s29,s11,s11
                fmacs s30,s13,s13
                fmacs s31,s15,s15
                fstmias r1!,{s24,s25,s26,s27,s28,s29,s30,s31}
                
                cmp r0,r2
                blo .Lmainloopa
.Lendmainloopa:
                add r2,r2,#8*12
                bhs .Lendsmallloopa
.Lsmallloopa:
                fldmias r0!,{s0,s1,s2,s3,s4,s5,s6,s7}
                fmuls s16,s0,s0
                fmuls s17,s2,s2
                fmuls s18,s4,s4
                fmuls s19,s6,s6
                fmacs s16,s1,s1
                fmacs s17,s3,s3
                fmacs s18,s5,s5
                fmacs s19,s7,s7
                fstmias r1!,{s16,s17,s18,s19}
                cmp r0,r2
                blo .Lsmallloopa
.Lendsmallloopa:
                add r2,r2,#8*3
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
                
                .align  2
.LGOTa:
                .word _GLOBAL_OFFSET_TABLE_-(.LPICa+8)
                .word analysis_state(GOT)
                
#endif // __arm__
