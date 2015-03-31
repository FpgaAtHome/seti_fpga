
#ifndef _FPGA_INTERFACE_H_
#define _FPGA_INTERFACE_H_

#define USA_FPGA

class FpgaInterface
{
public:
	FpgaInterface()
	{
	}

	// Load the NI Drivers and make sure a good/valid connection 
	// is made to the FPGA
	int initializeFpga();


};
#endif