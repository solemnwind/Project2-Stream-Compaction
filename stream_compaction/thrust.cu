#include <cuda.h>
#include <cuda_runtime.h>
#include <thrust/device_vector.h>
#include <thrust/host_vector.h>
#include <thrust/scan.h>
#include <thrust/remove.h>
#include <thrust/execution_policy.h>
#include "common.h"
#include "thrust.h"

namespace StreamCompaction {
    namespace Thrust {
        using StreamCompaction::Common::PerformanceTimer;
        PerformanceTimer& timer()
        {
            static PerformanceTimer timer;
            return timer;
        }
        /**
         * Performs prefix-sum (aka scan) on idata, storing the result into odata.
         */
        void scan(int n, int *odata, const int *idata) {
            thrust::device_vector<int> dv_idata(idata, idata + n);
            thrust::device_vector<int> dv_odata(n);

            timer().startGpuTimer();
            // TODO use `thrust::exclusive_scan`
            // example: for device_vectors dv_in and dv_out:
            // thrust::exclusive_scan(dv_in.begin(), dv_in.end(), dv_out.begin());
            thrust::exclusive_scan(dv_idata.begin(), dv_idata.end(), dv_odata.begin());
            timer().endGpuTimer();

            cudaMemcpy(odata, dv_odata.data().get(), n * sizeof(int), cudaMemcpyDeviceToHost);
            checkCUDAError("cudaMemcpy dv_odata->odata failed!");
        }

        int compact(int n, int *odata, const int *idata)
        {
            memcpy(odata, idata, n * sizeof(int));

            struct is_zero
            {
                __host__ __device__
                bool operator() (const int x) const
                {
                    return x == 0;
                }
            };

            timer().startGpuTimer();
            int* new_end = thrust::remove_if(odata, odata + n, is_zero());
            timer().endGpuTimer();

            return new_end - odata;
        }
    }
}
