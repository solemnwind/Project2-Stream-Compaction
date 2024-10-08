#include <cstdio>
#include "cpu.h"

#include "common.h"

namespace StreamCompaction {
    namespace CPU {
        using StreamCompaction::Common::PerformanceTimer;
        PerformanceTimer& timer()
        {
            static PerformanceTimer timer;
            return timer;
        }

        /**
         * CPU scan (prefix sum).
         * For performance analysis, this is supposed to be a simple for loop.
         * (Optional) For better understanding before starting moving to GPU, you can simulate your GPU scan in this function first.
         */
        void scan(int n, int *odata, const int *idata) {
            timer().startCpuTimer();
            // TODO
            // Exclusive Prefix Sum
            odata[0] = 0;
            for (int i = 0; i < n - 1; ++i)
            {
                odata[i + 1] = odata[i] + idata[i];
            }
            timer().endCpuTimer();
        }

        /**
         * CPU stream compaction without using the scan function.
         *
         * @returns the number of elements remaining after compaction.
         */
        int compactWithoutScan(int n, int *odata, const int *idata) {
            timer().startCpuTimer();
            // TODO
            int j = 0;
            for (int i = 0; i < n; ++i)
            {
                if (idata[i] != 0)
                {
                    odata[j++] = idata[i];
                }
            }
            timer().endCpuTimer();
            return j;
        }

        /**
         * CPU stream compaction using scan and scatter, like the parallel version.
         *
         * @returns the number of elements remaining after compaction.
         */
        int compactWithScan(int n, int *odata, const int *idata) {
            // TODO
            // Temporary arrays
            int* mask = new int[n];
            int* indices = new int[n];

            timer().startCpuTimer();

            for (int i = 0; i < n; ++i)
            {
                mask[i] = idata[i] != 0;
            }

            // scan(n, indices, mask);
            indices[0] = 0;
            for (int i = 0; i < n - 1; ++i)
            {
                indices[i + 1] = indices[i] + mask[i];
            }

            // Scatter
            for (int i = 0; i < n; ++i)
            {
                if (mask[i])
                {
                    odata[indices[i]] = idata[i];
                }
            }

            timer().endCpuTimer();

            // Retrieve the number of elements remaining
            int elementCount = indices[n - 1] + mask[n - 1];

            // Clean up
            delete[] mask;
            delete[] indices;

            return elementCount;
        }

        void sort(int n, int *odata, const int *idata)
        {
            memcpy(odata, idata, n * sizeof(int));

            timer().startCpuTimer();

            std::stable_sort(odata, odata + n);

            timer().endCpuTimer();
        }
    }
}
