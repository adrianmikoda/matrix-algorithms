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
void draw(const vector<vector<T>> &M, int precision) {
    if (M.empty()) {
        cout << "[ ]\n";
        return;
    }

    size_t rows = M.size();
    size_t cols = 0;
    for (const auto &row : M) cols = max(cols, row.size());

    vector<vector<string>> cells(rows, vector<string>(cols));
    vector<size_t> width(cols, 0);

    for (size_t r = 0; r < rows; ++r) {
        for (size_t c = 0; c < M[r].size(); ++c) {
            ostringstream ss;
            if constexpr (is_floating_point_v<T>)
                ss << fixed << setprecision(precision);
            ss << M[r][c];
            cells[r][c] = ss.str();
            width[c] = max(width[c], cells[r][c].size());
        }
    }

    for (size_t r = 0; r < rows; ++r) {
        string left, right;
        if (rows == 1)          { left = "[";  right = "]"; }
        else if (r == 0)        { left = "┌";  right = "┐"; }
        else if (r == rows - 1) { left = "└";  right = "┘"; }
        else                    { left = "│";  right = "│"; }

        cout << left;
        for (size_t c = 0; c < cols; ++c) {
            cout << " " << setw(width[c]) << cells[r][c];
        }
        cout << " " << right << "\n";
    }
}


int main() {
    vector<vector<int>> A{{1, 2, 3}, {4, 5, 6}};
    vector<vector<int>> B{{7, 8, 5}, {9, 10, 2}};
    vector<vector<int>> result = add<int>(A, B);
    draw<int>(result);

    return 0;
}