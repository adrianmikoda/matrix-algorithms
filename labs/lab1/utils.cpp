#include "utils.h"

template <typename T>
vector<vector<T>> add(const vector<vector<T>> &A, const vector<vector<T>> &B) {
    if (A.empty() || B.empty()) {
        throw invalid_argument("matrices must be non-empty");
    }

    auto m = A.size(), n = A[0].size();
    auto k = B.size(), l = B[0].size();

    if (m != k || n != l) {
        throw invalid_argument("invalid matrices dimensions");
    }

    vector<vector<T>> result(m, vector<T>(n, 0));

    for (int r = 0; r < m; ++r) {
        for (int c = 0; c < n; ++c) {
            result[r][c] = A[r][c] + B[r][c];
        }
    }
    
    return result;
}

template <typename T>
vector<vector<T>> mult(const vector<vector<T>> &A, const vector<vector<T>> &B) {
    if (A.empty() || B.empty()) {
        throw invalid_argument("matrices must be non-empty");
    }

    auto m = A.size(), n = A[0].size();
    auto k = B.size(), l = B[0].size();

    if (n != k) {
        throw invalid_argument("invalid matrices dimensions");
    }

    vector<vector<T>> result(m, vector<T>(l, 0));

    for (int r = 0; r < m; ++r) {
        for (int c = 0; c < l; ++c) {
            for (int i = 0; i < n; ++i) {
                result[r][c] += A[r][i] * B[i][c];
            }   
        }
    }
    
    return result;
}

template <typename T>
void draw_matrix(const vector<vector<T>> &M) {
    for (auto vec : M) {
        cout << "|";
        for (auto num : vec) {
            cout << num << " ";
        }
        cout << "|\n";
    }
}



int main() {
    vector<vector<int>> A{{1, 2, 3}, {4, 5, 6}};
    vector<vector<int>> B{{7, 8, 5}, {9, 10, 2}};
    vector<vector<int>> result = add<int>(A, B);
    draw_matrix<int>(result);

    return 0;
}