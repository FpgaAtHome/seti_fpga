#include "ICoreSigProc.h"

template class ICoreSigProc<float,float>;

template< class _Tin, class _Tout >
ICoreSigProc<_Tin,_Tout>::ICoreSigProc()
: m_name("ICoreSigProc Class"),
m_description("Abstract Signal processor class"),
m_n(DEFAULT_SIZE), m_batch(1), m_self_allocated_arrays(true)
{
  this->Alloc_new(m_n,m_batch);
}

template< class _Tin, class _Tout >
ICoreSigProc<_Tin,_Tout>::ICoreSigProc( int n, int batch, _Tin* idata, _Tout* odata)
: m_name("ICoreSigProc Class"),
m_description("Abstract Signal processor class"),
m_n(n), m_batch(batch), m_self_allocated_arrays(false)
{
    m_idata = idata;
    m_odata = odata;
}

template< class _Tin, class _Tout >
void ICoreSigProc<_Tin,_Tout>::Alloc_new(int n, int batch)
{
    m_self_allocated_arrays = true;
    m_idata = new _Tin[n*batch];
    m_odata = new _Tout[n*batch];
}

template< class _Tin, class _Tout >
ICoreSigProc<_Tin,_Tout>::~ICoreSigProc()
{
    if (m_self_allocated_arrays)
    {
        delete[] m_idata;
        delete[] m_odata;
    }
}

/*
template <class _Tin,class _Tout>
ICoreSigProc<_Tin,_Tout>::ICoreSigProc()
: m_name("ICoreSigProc Class"),
m_description("Abstract Signal processor class"),
m_n(DEFAULT_SIZE), m_batch(1)
{
    FILE_LOG(logDEBUG1) << "ICoreSigProc::ICoreSigProc() called, for " << m_name << endl;
    this->Alloc_new(m_n,m_batch);
}
*/

