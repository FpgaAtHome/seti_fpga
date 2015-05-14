#include "extcode.h"
#pragma pack(push)
#pragma pack(1)

#ifdef __cplusplus
extern "C" {
#endif
typedef uint16_t  NiFpgaViExecutionMode;
#define NiFpgaViExecutionMode_FPGATarget 0
#define NiFpgaViExecutionMode_SimulationSimulatedIO 1
#define NiFpgaViExecutionMode_SimulationRealIO 2
#define NiFpgaViExecutionMode_ThirdPartySimulation 3

/*!
 * InitializeFpga
 */
int32_t __cdecl InitializeFpga(NiFpgaViExecutionMode *FPGAVIExecutionMode);
/*!
 * CalcData
 */
int32_t __cdecl CalcData(cmplx64 ComplexDataIn[], cmplx64 ArrayOut[], 
	int32_t len, int32_t len2);
/*!
 * CloseFpga
 */
int32_t __cdecl CloseFpga(void);

MgErr __cdecl LVDLLStatus(char *errStr, int errStrLen, void *module);

#ifdef __cplusplus
} // extern "C"
#endif

#pragma pack(pop)

