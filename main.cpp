#include <iostream>
#include <fstream>


using namespace std;

void computeIterations(double *hArray, double *gArray, int &numIterations, int &width);
void computeAverage(double *hArray, double *gArray, int iteration, int &width);

int main(int args, char* argv[]) {

    //TODO: Check user input is in correct format.

    ofstream finalTemperatures;
    finalTemperatures.open("finalTemperatures.csv");




    int width = stoi(argv[1]);
    int numIterations = stoi(argv[2]);

    int exteriorWidth = width + 2;

    int size = (width + 2) * (width + 2) * sizeof(double);

    double *gArray, *hArray;

    hArray = (double*)malloc(size);
    gArray = (double*)malloc(size);

    int hotPlateStart = (exteriorWidth - (exteriorWidth * .4)) / 2;
    int hotPlateEnd = hotPlateStart + (exteriorWidth * .4);
//    cout << hotPlateEnd << endl;

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
        computeAverage(hArray, gArray, iteration, exteriorWidth);
        computeAverage(gArray, hArray, iteration, exteriorWidth);
    }

//    cout << "the value at (3,4) should be 40 and is: " << hArray[3*Width + 4] << endl;
//    // calculate left and right values
//    cout << "the value at (3, 3) should be 39 and is: " << hArray[3*Width + 4 - 1] << endl;
//    cout << "the value at (3, 5) should be 41 and is: " << hArray[3*Width + 4 + 1] << endl;
//
//    // calculate top and bottom values
//    cout << "the value at (2,4) should be 28 and is: " << hArray[(3*Width + 4) - Width] << endl;
//    cout << "the value at (4,4) should be 52 and is: " << hArray[(3*Width + 4) + Width] << endl;



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

}

void computeAverage(double *hArray, double *gArray, int iteration, int &width)
{
    for (int m = 1; m < width - 1; ++m)
    {
        for (int n = 1; n < width - 1; ++n)
        {

            gArray[m*width + n] = 0.25*(hArray[m*width + n - 1] + hArray[m*width + n + 1] + hArray[(m*width + n) + width] + hArray[(m*width + n) - width]);
        }
    }

//    for(int i = 0; i < width; ++i)
//    {
//        for(int j = 0; j < width; ++j)
//        {
//            hArray[i*width + j] = gArray[i*width + j];
//        }
//    }

}
