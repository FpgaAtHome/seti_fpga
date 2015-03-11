#ifndef ICORESIGPROC_H
#define ICORESIGPROC_H

#include <string>
#include <vector>

using namespace std;

#define DEFAULT_SIZE 1024

template <class _Tin, class _Tout>
class ICoreSigProc
{
    public:
        /** Default constructor */
        ICoreSigProc(void); // for performance, avoid the default destructor, which uses new/delete for data arrays
        ICoreSigProc(int n, int batch, _Tin* idata, _Tout* odata);
        ~ICoreSigProc(void);

        virtual void execute()=0;

    // member getters & setters
        string Getname() { return m_name; }
        void Setname(string val) { m_name = val; }
        string Getdescription() { return m_description; }
        void Setdescription(string val) { m_description = val; }
        size_t Getn() { return m_n; }
  //      void Setn(size_t val) { m_n = val; }
        size_t Getbatch() { return m_batch; }
  //      void Setbatch(size_t val) { m_batch = val; }
    protected:
        void Alloc_new(int n, int batch);
        string m_name; //!< Member variable "m_name"
        string m_description;
        size_t m_n;
        size_t m_batch;
        _Tin *m_idata;
        _Tout *m_odata;
    private:
        bool m_self_allocated_arrays;
};

#endif // ICORESIGPROC_H
