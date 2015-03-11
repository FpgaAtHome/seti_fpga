int read_blocks_dr2(int   tape_fd,
                    long  startblock,  
                    long  num_blocks_to_read,
                    int   beam,
                    int   pol,
                    int   vflag);
int find_start_point_dr2(int tape_fd, int beam, int pol);
