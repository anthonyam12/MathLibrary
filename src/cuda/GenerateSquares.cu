#include "../GenerateSquares.h"

#include <stdio.h>

using namespace std;

#define gpuErrchk(ans) { gpuAssert((ans), __FILE__, __LINE__); }
inline void gpuAssert(cudaError_t code, char *file, int line, bool abort=true)
{
   if (code != cudaSuccess)
   {
      fprintf(stderr,"GPUassert: %s %s %d\n", cudaGetErrorString(code), file, line);
      if (abort) exit(code);
   }
}


__device__ void permute_rows(short* new_rows, short* values, short* newSquares,
        int order, int rowOffset, int myOffset)
{
    for(short i = 0; i < order; i++)
    {
        for(short j = 0; j < order; j++)
        {
            newSquares[(i * order) + myOffset + rowOffset + j] = values[new_rows[i] * order + j];
        }
    }
}

__device__ void permute_cols(short* new_cols, short* values, short* newSquares,
        int order, int colOffset, int myOffset)
{
    for(short i = 0; i < order; i++)
    {
        for(short j = 0; j < order; j++)
        {
            newSquares[(i + myOffset + colOffset) + (j * order)] = values[j * order + new_cols[i]];
        }
    }
}

__device__ void permute_symbols(short* syms, short* values, short* newSquares,
        int order, int symOffset, int myOffset)
{
    short osq = order*order;
    for(short i = 0; i < osq; i++)
    {
        newSquares[i + myOffset + symOffset] = syms[values[i]];
    }
}

__global__ void generate_squares(short* squareList, int order, short* newSquares,
        short* perms, int batchSize, int totalPerms)
{
    int idx = threadIdx.x + blockIdx.x * blockDim.x;
    if(idx < batchSize)
    {
        int osq = order*order;
        int myOffset = idx * totalPerms * osq * 3; // where in the new square list is this thread's data?
        int squareOffset = idx * osq; // where in the squares list is this thread's data?

        // where after the offset to we start storing the data in the new square list
        int rowOffset = 0;
        int colOffset = osq;
        int symOffset = 2*(osq);
        short* my_square = (short*)malloc(sizeof(short) * osq);	// add squareOffset to function calls
        short* perm = (short*)malloc(sizeof(short)*order);

        for(int i = 0; i < osq; i++)
        {
            my_square[i] = squareList[i + squareOffset];
        }

        for(int pCount = 0; pCount < totalPerms; pCount++)
        {
            for(int i = 0; i < order; i++)
            {
                perm[i] = perms[(pCount*order) + i];
            }
            permute_cols(perm, my_square, newSquares, order, colOffset, myOffset);
            permute_rows(perm, my_square, newSquares, order, rowOffset, myOffset);
            permute_symbols(perm, my_square, newSquares, order, symOffset, myOffset);
            myOffset += (osq*3);
        }
        delete[] my_square;			//!!!! ALWAYS FREE YOUR MEMORY !!!!!
        delete[] perm;
    }
}

void run_on_gpu(short* squaresToRun, int order, short* newSquares, short* perm,
        int squareArraySize, int permArraySize, int newSquareArraySize,
        int squaresToCheck, int totalPerms, short *dev_squares, short* dev_perm, short* dev_new_squares)
{
    cudaMemcpy(dev_squares, squaresToRun, squareArraySize, cudaMemcpyHostToDevice);
    cudaMemcpy(dev_perm, perm, permArraySize, cudaMemcpyHostToDevice);
    cudaMemcpy(dev_new_squares, newSquares, newSquareArraySize, cudaMemcpyHostToDevice);

    // how many blocks do we need if we use nThreads threads?
    int nThreads = 128;
    int nBlocks = (squareArraySize + nThreads - 1) / nThreads;
    generate_squares<<<nBlocks, nThreads>>>(dev_squares, order, dev_new_squares, dev_perm, squaresToCheck, totalPerms);

    cudaMemcpy(newSquares, dev_new_squares, newSquareArraySize, cudaMemcpyDeviceToHost);
    //gpuErrchk(cudaPeekAtLastError());
    //gpuErrchk(cudaMemcpy(newSquares, dev_new_squares, newSquareArraySize, cudaMemcpyDeviceToHost));
    //gpuErrchk(cudaPeekAtLastError());
    //gpuErrchk(cudaDeviceSynchronize());

}

void copy_to_vectors(short* newSquares, unordered_set<string> &appendToSquares,
        int numberSquares, int order, int totalPerms)
{
    int osq = order*order;
    long iterRange =  numberSquares*totalPerms*3*osq;
    for(long i = 0; i < iterRange; i+=osq)
    {
        short* values = new short[osq];
        memcpy(values, &newSquares[i], osq*sizeof(short));
        /*for(int j = 0; j < osq; j++)
        {
            cout << values[j] << " ";
            if(j % order == 0 && j > 0)
                cout << endl;
        }*/

        LatinSquare sq = LatinSquare(order, values);
        sq.reduce();
        //sq.normalize();
        appendToSquares.insert(sq.flatstring_no_space());

        // NOTES! adding only the normalized or reduced squares produces the
        // 		    correct results (order 5 = 56 normalized and 1344 reduced)
        //delete[] values;
    }
}

int main(int argc, char* argv[])
{
    // timers
    clock_t start, end;
    start = clock();

    // TODO: make some things globals (e.g. order, osq) to stop passing it around
    if (argc < 3)
    {
        print_usage();
        return 0;
    }

    short order = stoi(string(argv[1]));
    short osq = order*order;
    string filename_iso = string(argv[2]);
    string filename_3 = "3_perm.dat";
    string filename_n = to_string(order) + "_perm.dat";
    bool cont = true;

    if (!file_exists(filename_n))
    {
        cout << filename_n << " does not exist. Please use the utilites to generate the file." << endl;
        cont = false;
    }
    if(!file_exists(filename_iso))
    {
        cout << filename_iso << " does not exist." << endl;
        cont = false;
    }

    if (!cont)
        return 0;

    ifstream isofile; isofile.open(filename_iso);

    string line;
    // unordered_map<string, LatinSquare> allSqs;
    unordered_set<string> allSqs;      // TODO: hash function to take this from strings -> doubles
    vector<short*> checkSqs;		// squares to permute, do not permute all squares everytime
    while(getline(isofile, line))
    {
        LatinSquare isoSq(order, get_array_from_line(line, osq));
        // allSqs.insert(make_pair(isoSq.flatstring_no_space(), isoSq));
        allSqs.insert(isoSq.flatstring_no_space());
        checkSqs.push_back(isoSq.get_values());
    }
    isofile.close();

    long totalPerms = my_factorial(order);
    short* perms = (short*)malloc(sizeof(short) * totalPerms * order);
    vector<short*> permVec;
    ifstream permfile; permfile.open(filename_n);
    string permline;
    int count = 0;
    while(getline(permfile, permline))
    {
        short* permArr = get_array_from_line(permline, order);
        permVec.push_back(permArr);
        for(int i = 0; i < order; i++)
        {
            perms[(count*order) + i] = permArr[i];
        }
        count++;
    }
    permfile.close();

    start = clock();
    // some random value (maybe keep it divisible by nThreads which should be a multiple of 32)
    int maxBatchSize = 4096;
    // 4352; // number of cores? (sure, although it might eat ram)
    long unsigned int numSqs;
    int permArraySize = order * sizeof(short) * totalPerms;
    int lastSquaresToCheck = 0;
    short* dev_squares; short* dev_perm; short* dev_new_squares;
    do {
        numSqs = allSqs.size();
        unordered_set<string> newSqMap;

        // TODO: add a permutation batch


        /* START: Process each batch of 'maxBatchSize' squares */
        int checkedSquares = 0;
        int reportCount = 0;
        while(checkedSquares < checkSqs.size())
        {
            if(checkedSquares / (SQ_CHECK_REPORT) > reportCount && checkedSquares > 0)
            {
                printf("Checked %d out of %ld squares\n", checkedSquares, checkSqs.size());
                reportCount++;
            }
            // only process up to maxBatchSize, in batches, to conserve RAM
            int squaresToCheck = (checkSqs.size() - checkedSquares) > maxBatchSize
                ? maxBatchSize : (checkSqs.size() - checkedSquares);
            int squareArraySize = squaresToCheck * osq * sizeof(short);
            int newSquareArraySize = squareArraySize * totalPerms * 3;

            short* squares = (short*)malloc(squareArraySize);
            short* newSquares = (short*)malloc(newSquareArraySize);

            /* START: flatten out the checkSqs set */
            for(int i = 0; i < squaresToCheck; i++) 	// each square
            {
                // start at the last index (ignore first squares that have been checked)
                short* values = checkSqs.at(checkedSquares + i);
                for(int j = 0; j < osq; j++)
                {
                    squares[(i*osq) + j] = values[j];
                }
            }
            /* END: flatten out the checkSqs set */

            if(lastSquaresToCheck != squaresToCheck)
            {
                if(lastSquaresToCheck > 0)
                {
                    cudaFree(dev_squares);
                    cudaFree(dev_perm);
                    cudaFree(dev_new_squares);
                }
                cudaMalloc((void**)&dev_squares, squareArraySize);
                cudaMalloc((void**)&dev_perm, permArraySize);
                cudaMalloc((void**)&dev_new_squares, newSquareArraySize);
            }

            run_on_gpu(squares, order, newSquares, perms, squareArraySize,
                    permArraySize, newSquareArraySize, squaresToCheck, totalPerms,
                    dev_squares, dev_perm, dev_new_squares);

            // need to store newSqMap here instead so that we can only add
            // new unique squares to the checkSqs vector

            //cout << "BEFORE copy_to_vectors: " << allSqs.size() << " " << checkSqs.size() << " " << newSqMap.size() << endl;
            copy_to_vectors(newSquares, newSqMap, squaresToCheck, order, totalPerms);
            //cout << "AFTER copy_to_vectors: " << allSqs.size() << " " << checkSqs.size() << " " << newSqMap.size() << endl;

            checkedSquares += squaresToCheck;
            lastSquaresToCheck = squaresToCheck;

            delete[] squares;
            delete[] newSquares;
        }
        /* END: Process each batch of 'maxBatchSize' squares */

        checkSqs.clear();
        pair<unordered_set<string>::iterator, bool> returnValue;
        for(auto it = newSqMap.begin(); it != newSqMap.end(); it++)
        {
            string lsString = (*it);
            returnValue = allSqs.insert(lsString);
            if(returnValue.second)	// the LS was added to the set so add it to the checksqs vector
            {
                short* values = get_array_from_line(lsString, osq);
                checkSqs.push_back(values);
            }
        }
        newSqMap.clear();

        cout << "Start Count: " << numSqs << ", End Count: " << allSqs.size() << endl;
    } while(numSqs < allSqs.size());

    end = clock();
    double timeTaken = double(end-start) / double(CLOCKS_PER_SEC);
    cout << "CUDA Time Taken: " << timeTaken << " seconds" << endl;

    ofstream sqfile; sqfile.open(to_string(order) + "_squares.dat");
    for(auto it = allSqs.begin(); it != allSqs.end(); it++)
    {
        sqfile << (*it) << endl;
    }

    sqfile.close();
    return 0;
}
