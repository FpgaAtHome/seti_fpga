#include "boinc_db.h"
#include "backend_lib.h"
#include "setilib.h"
#include "mb_splitter.h"
#include "mb_validrun.h"

//-------------------------------------------------------------------------
int read_blocks_dr2(int   tape_fd,
                    long  startblock,  
                    long  num_blocks_to_read,
                    int   beam,
                    int   pol,
                    int   vflag) {
//-------------------------------------------------------------------------

    static bool first_time = true;
    blanking_filter<complex<signed char> > blanker_filter;
    int num_blocks_read;
    int good_read = 0;      // assume bad read until proven otherwise

    if(first_time) {
        first_time = false;
        // set up blanking filter
        if (strcmp(splitter_settings.splitter_cfg->blanker_filter, "randomize") == 0) {
            log_messages.printf(SCHED_MSG_LOG::MSG_DEBUG,"Setting blanker filter to randomize\n" );
            blanker_filter = randomize;
        } else {
            log_messages.printf(SCHED_MSG_LOG::MSG_DEBUG,"Setting blanker filter to null\n" );
            blanker_filter = NULLC;      // no blanking
        }
    }

    num_blocks_read = seti_StructureDr2Data(tape_fd, beam, pol,
                                            num_blocks_to_read,       
                                            tapebuffer, blanker_filter);
    if(num_blocks_read == num_blocks_to_read) {
        //check for an uninterrupted run
        if (valid_run(tapebuffer,splitter_settings.receiver_cfg->min_vgc)) {
            std::vector<dr2_compact_block_t>::iterator i=tapebuffer.begin();
            // insert telescope coordinates into the coordinate history.
            // this should be converted to a more accurate routine.
            for (;i!=tapebuffer.end();i++) {
                coord_history[i->header.coord_time].ra   = i->header.ra;
                coord_history[i->header.coord_time].dec  = i->header.dec;
                coord_history[i->header.coord_time].time = i->header.coord_time.jd().uval();
            }
            good_read = 1;
        }
    } 
    return(good_read);
}

//-------------------------------------------------------------------------
int find_start_point_dr2(int tape_fd, int beam, int pol) {
//-------------------------------------------------------------------------
  char buf[1024];

  // In early tapes there was a bug where the first N blocks would be duplicates
  // of data from previous files.  So we do a preemptive fast forward until we see a
  // frame sequence number of 1.
  int i,readbytes=HeaderSize;
  dataheader_t header;
  header.frameseq=100000;

  while ((readbytes==HeaderSize) && (header.frameseq>10)) {
    char buffer[HeaderSize];
    int nread;
    readbytes=0;
    while ((readbytes!=HeaderSize) && (nread = read(tape_fd,buffer,HeaderSize-readbytes))) { 
	    readbytes+=nread;
    }
    if (nread < 0) {
	log_messages.printf(SCHED_MSG_LOG::MSG_CRITICAL,"File error %d.\n", errno);
	exit(1);
    }
    if (readbytes == HeaderSize) {
      header.populate_from_data(buffer);
      if (header.frameseq>10) {
        lseek64(tape_fd,DataSize,SEEK_CUR);
      } else {
        lseek64(tape_fd,-1*(off64_t)HeaderSize,SEEK_CUR);
      }
    }
  }

  if (readbytes != HeaderSize) {
    // we fast forwarded through the entire tape without finding the first frame
    // maybe this is one of the really early tapes that was split into chunks.
    lseek64(tape_fd,0,SEEK_SET);
    log_messages.printf(SCHED_MSG_LOG::MSG_NORMAL,"Warning: First block not found\n");
  }
  // End preemptive fast forward

  // Optionally fast forward to the point of resumption
  if (resumetape) {
    tape thistape;
    thistape.id=0; 
    readbytes=HeaderSize;
    sprintf(buf,"%d",rcvr.s4_id-AO_ALFA_0_0);
    if (thistape.fetch(std::string("where name=\'")+header.name+"\' and beam="+buf)) {
      log_messages.printf(SCHED_MSG_LOG::MSG_DEBUG,"Resuming tape %s beam %d pol %d\n",thistape.name,beam,pol );
      while ((readbytes==HeaderSize) && (header.dataseq!=thistape.last_block_done)) {
        int nread=0;
        char buffer[HeaderSize];
        readbytes=0;
        while ((readbytes!=HeaderSize) &&
	      ((nread = read(tape_fd,buffer,HeaderSize-readbytes)) > 0 )) {
	    readbytes+=nread;
        }
        if (readbytes == HeaderSize) {
          header.populate_from_data(buffer);
          if (header.dataseq!=thistape.last_block_done) {
            lseek64(tape_fd,(off64_t)(DataSize+HeaderSize)*(thistape.last_block_done-header.dataseq)-HeaderSize,SEEK_CUR);
          } else {
            lseek64(tape_fd,-1*(off_t)HeaderSize,SEEK_CUR);
            log_messages.printf(SCHED_MSG_LOG::MSG_NORMAL,"Found starting point");
          }
	}
	if (nread == 0) {
	  log_messages.printf(SCHED_MSG_LOG::MSG_CRITICAL,"End of file.\n");
	  exit(0);
        }
        if (nread < 0) {
	  log_messages.printf(SCHED_MSG_LOG::MSG_CRITICAL,"File error %d.\n",errno);
	  exit(1);
	}
      }
    }
  }
  // End fast forward to the point of resumption
 
  return 0;
}
