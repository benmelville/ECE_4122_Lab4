#include <iostream>
#include <fstream>
#include <iomanip>
#include <assert.h>
#include <unistd.h>



using namespace std;

inline cudaError_t HANDLE_ERROR(cudaError_t result)
{
#if defined(DEBUG) || defined(_DEBUG)
    if (result != cudaSuccess)
  {
    fprintf(stderr, "CUDA Runtime Error: %s\n", cudaGetErrorString(result));
    assert(result == cudaSuccess);
  }
#endif
    return result;
}



__global__ void computeAverageGPU(double *hArray, double *gArray, int iteration, int width)
{

    // Calculate the column index of the Pd element, denote by x
    int m = threadIdx.x + blockIdx.x * blockDim.x;
    // Calculate the row index of the Pd element, denote by y
    int n = threadIdx.y + blockIdx.y * blockDim.y;

    if (m > 0 && m < (width-1) && n > 0 && n < (width-1))
    {
        gArray[m*width + n] = 0.25*(hArray[m*width + n - 1] + hArray[m*width + n + 1] + hArray[(m*width + n) + width] + hArray[(m*width + n) - width]);
    }

}



int main(int argc, char* argv[]) {

    //TODO: Check user input is in correct format.
    int nFlags, iFlags, opt;
    int iNumber, nNumber;

    nFlags = 0;
    iFlags = 0;

    string tempOptArg;
    while ((opt = getopt(argc, argv, "n:I:")) != -1)
    {
        switch (opt)
        {
            case 'n':
                // Do something
                tempOptArg = optarg;
                for (int i = 0; i < tempOptArg.length(); ++i)
                {
                    if (!isdigit(tempOptArg[i]))
                    {
                        printf("Invalid Input!\n");
                        return 0;
                    }
                }
                if (tempOptArg[0] == '0' && tempOptArg.length() > 1)
                {
                    printf("Invalid Input!\n");
                    return 0;
                }
                nFlags = 1;
                nNumber = atoi(optarg);
                break;
            case 'I':
                // Do something
                tempOptArg = optarg;
                for (int i = 0; i < tempOptArg.length(); ++i)
                {
                    if (!isdigit(tempOptArg[i]))
                    {
                        printf("Invalid Input!\n");
                        return 0;
                    }
                }

                if (tempOptArg[0] == '0' && tempOptArg.length() > 1)
                {
                    printf("Invalid Input!\n");
                    return 0;
                }
                iFlags = 1;
                iNumber = atoi(optarg);
                break;

            default: /* '?' */
                printf("Invalid Input!\n");
                return 0;
        }
    }

    if(argc != 5)
    {
        printf("Invalid Input!\n");
        return 0;
    }
    if (iNumber <= 0 || nNumber <= 0)
    {
        printf("Invalid Input!\n");
        return 0;
    }

    if (iFlags == 0 || nFlags == 0)
    {
        printf("Invalid Input!\n");
        return 0;
    }


    ofstream finalTemperatures;
    finalTemperatures.open("finalTemperatures.csv");




    int width = nNumber;
    int numIterations = iNumber / 2;

    int exteriorWidth = width + 2;

    int size = (width + 2) * (width + 2) * sizeof(double);

    double *gArray, *hArray;


    // capture start time
    cudaEvent_t     start, stop;
    HANDLE_ERROR( cudaEventCreate( &start ) );
    HANDLE_ERROR( cudaEventCreate( &stop ) );
    HANDLE_ERROR( cudaEventRecord( start, 0 ) );

    cudaMallocManaged(&hArray, size*sizeof(double));
    cudaMallocManaged(&gArray, size*sizeof(double));

    cudaDeviceProp prop;
    cudaGetDeviceProperties(&prop, 0);

    int blockSize = sqrt(prop.maxThreadsPerBlock);
//    int numBlocks = (exteriorWidth + 32 - 1) / 32;
    dim3 dimBlock(blockSize, blockSize);
    dim3 dimGrid((width/blockSize) + 1, (width/blockSize) + 1);

//

    int hotPlateStart = (exteriorWidth - (exteriorWidth * .4)) / 2;
    int hotPlateEnd = hotPlateStart + (exteriorWidth * .4);

    for(int i = 0; i < size; ++i)
    {
        hArray[i] = 0;
        gArray[i] = 0;
    }


    for (int i = 0; i < exteriorWidth; ++i)
    {
        hArray[i * exteriorWidth] = 20;
        hArray[(i * exteriorWidth + exteriorWidth) - 1] = 20;
        hArray[(exteriorWidth * exteriorWidth) - exteriorWidth + i] = 20;
        hArray[i] = 20;

        gArray[i * exteriorWidth] = 20;
        gArray[(i * exteriorWidth + exteriorWidth) - 1] = 20;
        gArray[(exteriorWidth * exteriorWidth) - exteriorWidth + i] = 20;
        gArray[i] = 20;



        if (i >= hotPlateStart && i < hotPlateEnd)
        {
            gArray[i] = 100;
            hArray[i] = 100;
        }

    }

    for (int iteration = 0; iteration < numIterations; ++iteration)
    {
        computeAverageGPU<<<dimGrid, dimBlock>>>(hArray, gArray, iteration, exteriorWidth);
        cudaDeviceSynchronize();
        computeAverageGPU<<<dimGrid, dimBlock>>>(gArray, hArray, iteration, exteriorWidth);
    }


    cudaDeviceSynchronize();

    // get stop time, and display the timing results
    HANDLE_ERROR( cudaEventRecord( stop, 0 ) );
    HANDLE_ERROR( cudaEventSynchronize( stop ) );
    float   elapsedTime;
    HANDLE_ERROR( cudaEventElapsedTime( &elapsedTime, start, stop ) );
    printf( "Thin plate calculation took %3.3f milliseconds.\n", elapsedTime );



    for(int m = 0; m < exteriorWidth; ++m)
    {
        for(int n = 0; n < exteriorWidth; ++n)
        {
            if (n == exteriorWidth - 1)
            {
                finalTemperatures << setprecision(15) << hArray[m*exteriorWidth + n];
                continue;
            }
            finalTemperatures << setprecision(15) << hArray[m*exteriorWidth + n] << ",";
        }
        finalTemperatures << "\n";
    }

    finalTemperatures.close();

    cudaFree(gArray);
    cudaFree(hArray);

    // destroy events to free memory
    HANDLE_ERROR( cudaEventDestroy( start ) );
    HANDLE_ERROR( cudaEventDestroy( stop ) );

    return 0;
}
