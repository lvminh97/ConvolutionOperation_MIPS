#include <iostream>
#include <fstream>
#include <vector>
#include <sstream>

using namespace std;

// Hàm để thực hiện zero-padding
vector<vector<float>> zeroPadding(const vector<vector<float>>& input, int pad)
{
    int rows = input.size();
    int cols = input[0].size();
    int newRows = rows + 2 * pad;
    int newCols = cols + 2 * pad;

    vector<vector<float>> padded(newRows, vector<float>(newCols, 0));

    for (int i = 0; i < rows; ++i)
    {
        for (int j = 0; j < cols; ++j)
        {
            padded[i + pad][j + pad] = input[i][j];
        }
    }

    return padded;
}

vector<vector<float>> convolution(const vector<vector<float>>& input, const vector<vector<float>>& kernel, int stride) {
    int inputRows = input.size();
    int inputCols = input[0].size();
    int kernelRows = kernel.size();
    int kernelCols = kernel[0].size();
    int outputRows = (inputRows - kernelRows) / stride + 1;
    int outputCols = (inputCols - kernelCols) / stride + 1;

    vector<vector<float>> output(outputRows, vector<float>(outputCols, 0));

    for (int i = 0; i < outputRows; ++i)
    {
        for (int j = 0; j < outputCols; ++j)
        {
            float sum = 0;
            for (int m = 0; m < kernelRows; ++m)
            {
                for (int n = 0; n < kernelCols; ++n)
                {
                    sum += input[i * stride + m][j * stride + n] * kernel[m][n];
                }
            }
            output[i][j] = sum;
            // cout << sum << " ";
        }
    }

    return output;
}

int main()
{
    int N = 3;
    int M = 4;
    int p = 1;
    int s = 2;

    freopen("input_matrix.txt", "r", stdin);

    cin >> N >> M >> p >> s;

    vector<vector<float>> kernelMatrix;
    vector<vector<float>> imageMatrix;

    for(int i = 0; i < N; i++)
    {
        float x;
        vector<float> tmp;
        for(int j = 0; j < N; j++) 
        {
            cin >> x;
            tmp.push_back(x);
        }
        imageMatrix.push_back(tmp);
    }

    for(int i = 0; i < M; i++)
    {
        float x;
        vector<float> tmp;
        for(int j = 0; j < M; j++) 
        {
            cin >> x;
            tmp.push_back(x);
        }
        kernelMatrix.push_back(tmp);
    }

    vector<vector<float>> paddedInput = zeroPadding(imageMatrix, p);
    vector<vector<float>> outputMatrix = convolution(paddedInput, kernelMatrix, s);

    cout << "--------------------------\n";
    for(int i = 0; i < outputMatrix.size(); i++)
    {
        for(int j = 0; j < outputMatrix[0].size(); j++)
        {
            cout << outputMatrix[i][j] << " ";
        }
        cout << endl;
    }

    return 0;
}