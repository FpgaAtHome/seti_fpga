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

// workunit_resample - a program to read in a workunit and convert it to
// real samples at twice the sampling rate with all frequencies shifted to
// be positive.

#include "sah_config.h"

#include <cstdio>
#ifdef HAVE_SYS_TYPES_H
#include <sys/types.h>
#endif
#ifdef HAVE_SYS_STAT_H
#include <sys/stat.h>
#endif
#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif
#include <ctime>
#include <cstdlib>
#include <cstring>
#include <string>
#include <vector>
#include "export.h"


#ifdef HAVE_IEEEFP_H
#include <ieeefp.h>
#endif

#include "client/timecvt.h"
#include "client/s_util.h"
#include "db/db_table.h"
#include "db/schema_master.h"
#include "seti.h"

#define ARRLEN(arr) (sizeof(arr)/sizeof(arr[0]))

workunit_header header;
extern "C" {
IDL_VPTR readwu(int argc, IDL_VPTR argv[], char *argk);
void readwu_exit_handler(void) { }
int IDL_Load(void);
}

static IDL_SYSFUN_DEF2 readwu_fns[] = {
  {(IDL_VARIABLE *(*)())readwu, "READWU", 1, 1, IDL_SYSFUN_DEF_F_KEYWORDS, 0},
};

static IDL_MSG_DEF msg_arr[] = {
  {"READWU_ERROR", "%NError: %s"},
};

static IDL_MSG_BLOCK readwu_msg_block;

int readwu_startup(void) {
  if (!IDL_SysRtnAdd(readwu_fns,TRUE,ARRLEN(readwu_fns))) {
    return NULL;
  }
  IDL_ExitRegister(readwu_exit_handler);
  return IDL_TRUE;
}

int IDL_Load(void) {
  if (!(readwu_msg_block=IDL_MessageDefineBlock("readwu", ARRLEN(msg_arr),msg_arr))) {
    return NULL;
  }
  if (!readwu_startup()) {
    IDL_MessageFromBlock(readwu_msg_block,0,IDL_MSG_RET,"can't load readwu");
  }
  return IDL_TRUE;
}



IDL_VPTR readwu(int argc, IDL_VPTR argv[], char *argk) {
  IDL_VPTR filename=NULL;
  static IDL_VARIABLE rv;
  rv.type=IDL_TYP_INT;
  rv.flags=IDL_V_CONST|IDL_V_NULL;
  rv.value.i=-1;

  char *outfile=NULL, buf[256];
  struct stat statbuf;
  int nbytes,nread,nsamples;
  std::string tmpbuf("");
  int i=0,j;

  if (argc != 1) {
    fprintf(stderr,"argc=%d\n",argc);
    fprintf(stderr,"array=readwu(wufile_name)\n");
    return &rv;
  }
  IDL_STRING *infile=NULL;
  if (argv[0]->type != IDL_TYP_STRING) {
    IDL_MessageFromBlock(readwu_msg_block,0,IDL_MSG_RET,"Parameter 1 must be type STRING");
  } else {
    infile=(IDL_STRING *)(&argv[0]->value.s);
  }
  FILE *in=fopen(infile->s,"r");
  if (!in) {
    IDL_MessageFromBlock(readwu_msg_block,0,IDL_MSG_RET,"File not found");
    return &rv;
  } 
  stat(infile->s,&statbuf);
  nbytes=statbuf.st_size;
  fseek(in,0,SEEK_SET);
  tmpbuf.reserve(nbytes);
  // read entire file into a buffer.
  while ((nread=(int)fread(buf,1,sizeof(buf),in))) {
    tmpbuf+=std::string(&(buf[0]),nread);
  }
  // parse the header
  header.parse_xml(tmpbuf);
  // decode the data
  std::vector<unsigned char> datav(
    xml_decode_field<unsigned char>(tmpbuf,"data") 
  );
  tmpbuf.clear();
  nsamples=header.group_info->data_desc.nsamples;
  nbytes=nsamples*header.group_info->recorder_cfg->bits_per_sample/8;
  if (datav.size() < nbytes) {
    fprintf(stderr,"Data size does not match number of samples\n");
    return &rv;
  }
  // convert the data to floating point
  sah_complex *fpdata=(sah_complex *)IDL_MemAlloc(nsamples*sizeof(sah_complex),0,IDL_MSG_RET);
  if (!fpdata) {
    fprintf(stderr,"Unable to allocate memory!\r\n");
    return &rv;
  } 
  bits_to_floats(&(datav[0]),fpdata,nsamples);
  datav.clear();
  IDL_MEMINT dims[]={nsamples};
  return IDL_ImportArray(1,dims,IDL_TYP_COMPLEX,(UCHAR *)fpdata,NULL,NULL);
}


