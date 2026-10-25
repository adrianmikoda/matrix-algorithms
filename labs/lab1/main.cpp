#include <iostream>
#include <vector>
#include <cstdlib>
#include <ctime>
#include <cmath>
#include <iomanip>
#include <utility>
#include <algorithm>
#include <initializer_list>
#include <string>
#include <sstream>
#include <type_traits>
#include <chrono>

using namespace std;
using Matrix = vector<vector<double>>;

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

static unsigned long long g_mults = 0;
static unsigned long long g_adds  = 0;

const int MAX_DRAW_SIZE = 10;
const int PRINT_PRECISION = 4;

Matrix generateMatrix(int n) {
    const double LO = 1e-8;
    Matrix M(n, vector<double>(n));
    for (auto &row : M)
        for (auto &x : row) {
            double u = (rand() + 1.0) / (RAND_MAX + 2.0);
            x = LO + (1.0 - LO) * u;
        }
    return M;
}

struct Dense {
    int r = 0, c = 0;
    Matrix d;
    Dense() {}
    Dense(int rows, int cols) : r(rows), c(cols), d(rows, vector<double>(cols, 0.0)) {}
};

struct View {
    const Matrix *m;
    int r0, c0, rows, cols;
    View(const Matrix *mm, int row0, int col0, int nr, int nc) : m(mm), r0(row0), c0(col0), rows(nr), cols(nc) {}
    View(const Matrix &M) : m(&M), r0(0), c0(0), rows(M.size()), cols(M.empty() ? 0 : M[0].size()) {}
    View(const Dense &x) : m(&x.d), r0(0), c0(0), rows(x.r), cols(x.c) {}
    double at(int i, int j) const { return (*m)[r0 + i][c0 + j]; }
};

struct MView {
    Matrix *m;
    int r0, c0, rows, cols;
};

View block(const View &v, int ra, int rb, int ca, int cb) {
    ra = min(ra, v.rows); rb = min(rb, v.rows);
    ca = min(ca, v.cols); cb = min(cb, v.cols);
    return View(v.m, v.r0 + ra, v.c0 + ca, rb - ra, cb - ca);
}

MView block(const MView &v, int ra, int rb, int ca, int cb) {
    return MView{v.m, v.r0 + ra, v.c0 + ca, rb - ra, cb - ca};
}

int nextPower(int x, int base) {
    int p = 1;
    while (p < x) p *= base;
    return p;
}

Dense combination(initializer_list<pair<int, View>> terms) {
    int R = 0, C = 0;
    for (const auto &t : terms) { R = max(R, t.second.rows); C = max(C, t.second.cols); }
    Dense res(R, C);
    vector<int> covered(R, 0);
    unsigned long long ops = 0;
    for (const auto &t : terms) {
        const View &v = t.second;
        for (int i = 0; i < v.rows; i++) {
            for (int j = 0; j < v.cols; j++) {
                double x = t.first * v.at(i, j);
                if (j < covered[i]) { res.d[i][j] += x; ops++; }
                else res.d[i][j] = x;
            }
            covered[i] = max(covered[i], v.cols);
        }
    }
    g_adds += ops;
    return res;
}

void place(Dense &C, const Dense &X, int ro, int co) {
    for (int i = 0; i < X.r && ro + i < C.r; i++)
        for (int j = 0; j < X.c && co + j < C.c; j++) C.d[ro + i][co + j] = X.d[i][j];
}

Dense brutal(const View &a, const View &b) {
    int r = a.rows, c = b.cols, k = min(a.cols, b.rows);
    Dense res(r, c);
    if (k == 0) return res;
    for (int i = 0; i < r; i++)
        for (int j = 0; j < c; j++) {
            double s = a.at(i, 0) * b.at(0, j);
            for (int l = 1; l < k; l++) s += a.at(i, l) * b.at(l, j);
            res.d[i][j] = s;
        }
    g_mults += (unsigned long long)r * k * c;
    g_adds  += (unsigned long long)r * (k - 1) * c;
    return res;
}

Matrix classical(const Matrix &A, const Matrix &B) {
    int n = A.size();
    Matrix C(n, vector<double>(n, 0.0));
    for (int i = 0; i < n; i++)
        for (int k = 0; k < n; k++)
            for (int j = 0; j < n; j++) C[i][j] += A[i][k] * B[k][j];
    unsigned long long N = n;
    g_mults += N * N * N;
    g_adds  += N * N * (N - 1);
    return C;
}

void binetAdd(const View &a, const View &b, const MView &res, bool fresh) {
    int n1 = a.rows, n2 = b.rows, m2 = b.cols;

    if (n1 < 2 || n2 < 2 || m2 < 2) {
        int k = a.cols;
        for (int i = 0; i < n1; i++)
            for (int j = 0; j < m2; j++) {
                double s = a.at(i, 0) * b.at(0, j);
                for (int l = 1; l < k; l++) s += a.at(i, l) * b.at(l, j);
                double &target = (*res.m)[res.r0 + i][res.c0 + j];
                if (fresh) target = s; else target += s;
            }
        g_mults += (unsigned long long)n1 * k * m2;
        g_adds  += (unsigned long long)n1 * (fresh ? k - 1 : k) * m2;
        return;
    }

    int mr = n1 / 2, mk = n2 / 2, mc = m2 / 2;
    View a11 = block(a, 0, mr, 0, mk),  a12 = block(a, 0, mr, mk, a.cols);
    View a21 = block(a, mr, n1, 0, mk), a22 = block(a, mr, n1, mk, a.cols);
    View b11 = block(b, 0, mk, 0, mc),  b12 = block(b, 0, mk, mc, m2);
    View b21 = block(b, mk, n2, 0, mc), b22 = block(b, mk, n2, mc, m2);
    MView r11 = block(res, 0, mr, 0, mc),  r12 = block(res, 0, mr, mc, m2);
    MView r21 = block(res, mr, n1, 0, mc), r22 = block(res, mr, n1, mc, m2);

    binetAdd(a11, b11, r11, fresh); binetAdd(a12, b21, r11, false);
    binetAdd(a11, b12, r12, fresh); binetAdd(a12, b22, r12, false);
    binetAdd(a21, b11, r21, fresh); binetAdd(a22, b21, r21, false);
    binetAdd(a21, b12, r22, fresh); binetAdd(a22, b22, r22, false);
}

Matrix binet(const Matrix &A, const Matrix &B) {
    int n = A.size();
    Matrix C(n, vector<double>(B[0].size(), 0.0));
    binetAdd(View(A), View(B), MView{&C, 0, 0, n, (int)B[0].size()}, true);
    return C;
}


Dense strassen2x2(const View &a, const View &b) {
    double a11 = a.at(0, 0), a12 = a.at(0, 1), a21 = a.at(1, 0), a22 = a.at(1, 1);
    double b11 = b.at(0, 0), b12 = b.at(0, 1), b21 = b.at(1, 0), b22 = b.at(1, 1);
    double m1 = (a11 + a22) * (b11 + b22);
    double m2 = (a21 + a22) * b11;
    double m3 = a11 * (b12 - b22);
    double m4 = a22 * (b21 - b11);
    double m5 = (a11 + a12) * b22;
    double m6 = (a21 - a11) * (b11 + b12);
    double m7 = (a12 - a22) * (b21 + b22);
    Dense C(2, 2);
    C.d[0][0] = m1 + m4 - m5 + m7;
    C.d[0][1] = m3 + m5;
    C.d[1][0] = m2 + m4;
    C.d[1][1] = m1 - m2 + m3 + m6;
    g_mults += 7;
    g_adds  += 18;
    return C;
}

Dense strassenRec(const View &a, const View &b) {
    int r1 = a.rows, c1 = a.cols, r2 = b.rows, c2 = b.cols;
    if (r1 == 2 && c1 == 2 && r2 == 2 && c2 == 2) return strassen2x2(a, b);
    if (r1 <= 2 || c1 <= 2 || r2 <= 2 || c2 <= 2) return brutal(a, b);

    int mx = max(max(r1, c1), max(r2, c2));
    int p = nextPower(mx, 2);
    int h = p / 2;

    View a11 = block(a, 0, h, 0, h),     a12 = block(a, 0, h, h, p);
    View a21 = block(a, h, p, 0, h),     a22 = block(a, h, p, h, p);
    View b11 = block(b, 0, h, 0, h),     b12 = block(b, 0, h, h, p);
    View b21 = block(b, h, p, 0, h),     b22 = block(b, h, p, h, p);

    Dense M1 = strassenRec(combination({{1, a11}, {1, a22}}), combination({{1, b11}, {1, b22}}));
    Dense M2 = strassenRec(combination({{1, a21}, {1, a22}}), b11);
    Dense M3 = strassenRec(a11, combination({{1, b12}, {-1, b22}}));
    Dense M4 = strassenRec(a22, combination({{1, b21}, {-1, b11}}));
    Dense M5 = strassenRec(combination({{1, a11}, {1, a12}}), b22);
    Dense M6 = strassenRec(combination({{1, a21}, {-1, a11}}), combination({{1, b11}, {1, b12}}));
    Dense M7 = strassenRec(combination({{1, a12}, {-1, a22}}), combination({{1, b21}, {1, b22}}));

    Dense C11 = combination({{1, M1}, {1, M4}, {-1, M5}, {1, M7}});
    Dense C12 = combination({{1, M3}, {1, M5}});
    Dense C21 = combination({{1, M2}, {1, M4}});
    Dense C22 = combination({{1, M1}, {-1, M2}, {1, M3}, {1, M6}});

    Dense C(r1, c2);
    place(C, C11, 0, 0); place(C, C12, 0, h);
    place(C, C21, h, 0); place(C, C22, h, h);
    return C;
}

Matrix strassen(const Matrix &A, const Matrix &B) {
    return strassenRec(View(A), View(B)).d;
}

Dense ladermanRec(const View &A, const View &B) {
    int r1 = A.rows, c1 = A.cols, r2 = B.rows, c2 = B.cols;
    if (r1 <= 2 || c1 <= 2 || r2 <= 2 || c2 <= 2) return brutal(A, B);

    int mx = max(max(r1, c1), max(r2, c2));
    int p = nextPower(mx, 3);
    int t = p / 3;

    View a[3][3] = {{block(A, 0, t, 0, t),     block(A, 0, t, t, 2 * t),     block(A, 0, t, 2 * t, p)},
                    {block(A, t, 2 * t, 0, t), block(A, t, 2 * t, t, 2 * t), block(A, t, 2 * t, 2 * t, p)},
                    {block(A, 2 * t, p, 0, t), block(A, 2 * t, p, t, 2 * t), block(A, 2 * t, p, 2 * t, p)}};
    View b[3][3] = {{block(B, 0, t, 0, t),     block(B, 0, t, t, 2 * t),     block(B, 0, t, 2 * t, p)},
                    {block(B, t, 2 * t, 0, t), block(B, t, 2 * t, t, 2 * t), block(B, t, 2 * t, 2 * t, p)},
                    {block(B, 2 * t, p, 0, t), block(B, 2 * t, p, t, 2 * t), block(B, 2 * t, p, 2 * t, p)}};
    const View &a11 = a[0][0], &a12 = a[0][1], &a13 = a[0][2];
    const View &a21 = a[1][0], &a22 = a[1][1], &a23 = a[1][2];
    const View &a31 = a[2][0], &a32 = a[2][1], &a33 = a[2][2];
    const View &b11 = b[0][0], &b12 = b[0][1], &b13 = b[0][2];
    const View &b21 = b[1][0], &b22 = b[1][1], &b23 = b[1][2];
    const View &b31 = b[2][0], &b32 = b[2][1], &b33 = b[2][2];

    auto mul = ladermanRec;
    Dense m1  = mul(combination({{1,a11},{1,a12},{1,a13},{-1,a21},{-1,a22},{-1,a32},{-1,a33}}), b22);
    Dense m2  = mul(combination({{1,a11},{-1,a21}}), combination({{1,b22},{-1,b12}}));
    Dense m3  = mul(a22, combination({{1,b12},{1,b21},{-1,b11},{-1,b22},{-1,b23},{-1,b31},{1,b33}}));
    Dense m4  = mul(combination({{1,a21},{1,a22},{-1,a11}}), combination({{1,b11},{-1,b12},{1,b22}}));
    Dense m5  = mul(combination({{1,a21},{1,a22}}), combination({{1,b12},{-1,b11}}));
    Dense m6  = mul(a11, b11);
    Dense m7  = mul(combination({{1,a31},{1,a32},{-1,a11}}), combination({{1,b11},{-1,b13},{1,b23}}));
    Dense m8  = mul(combination({{1,a31},{-1,a11}}), combination({{1,b13},{-1,b23}}));
    Dense m9  = mul(combination({{1,a31},{1,a32}}), combination({{1,b13},{-1,b11}}));
    Dense m10 = mul(combination({{1,a11},{1,a12},{1,a13},{-1,a22},{-1,a23},{-1,a31},{-1,a32}}), b23);
    Dense m11 = mul(a32, combination({{1,b13},{1,b21},{-1,b11},{-1,b22},{-1,b23},{-1,b31},{1,b32}}));
    Dense m12 = mul(combination({{1,a32},{1,a33},{-1,a13}}), combination({{1,b22},{1,b31},{-1,b32}}));
    Dense m13 = mul(combination({{1,a13},{-1,a33}}), combination({{1,b22},{-1,b32}}));
    Dense m14 = mul(a13, b31);
    Dense m15 = mul(combination({{1,a32},{1,a33}}), combination({{1,b32},{-1,b31}}));
    Dense m16 = mul(combination({{1,a22},{1,a23},{-1,a13}}), combination({{1,b23},{1,b31},{-1,b33}}));
    Dense m17 = mul(combination({{1,a13},{-1,a23}}), combination({{1,b23},{-1,b33}}));
    Dense m18 = mul(combination({{1,a22},{1,a23}}), combination({{1,b33},{-1,b31}}));
    Dense m19 = mul(a12, b21);
    Dense m20 = mul(a23, b32);
    Dense m21 = mul(a21, b13);
    Dense m22 = mul(a31, b12);
    Dense m23 = mul(a33, b33);

    Dense c11 = combination({{1,m6},{1,m14},{1,m19}});
    Dense c12 = combination({{1,m1},{1,m4},{1,m5},{1,m6},{1,m12},{1,m14},{1,m15}});
    Dense c13 = combination({{1,m6},{1,m7},{1,m9},{1,m10},{1,m14},{1,m16},{1,m18}});
    Dense c21 = combination({{1,m2},{1,m3},{1,m4},{1,m6},{1,m14},{1,m16},{1,m17}});
    Dense c22 = combination({{1,m2},{1,m4},{1,m5},{1,m6},{1,m20}});
    Dense c23 = combination({{1,m14},{1,m16},{1,m17},{1,m18},{1,m21}});
    Dense c31 = combination({{1,m6},{1,m7},{1,m8},{1,m11},{1,m12},{1,m13},{1,m14}});
    Dense c32 = combination({{1,m12},{1,m13},{1,m14},{1,m15},{1,m22}});
    Dense c33 = combination({{1,m6},{1,m7},{1,m8},{1,m9},{1,m23}});

    Dense C(r1, c2);
    place(C, c11, 0, 0);      place(C, c12, 0, t);      place(C, c13, 0, 2 * t);
    place(C, c21, t, 0);      place(C, c22, t, t);      place(C, c23, t, 2 * t);
    place(C, c31, 2 * t, 0);  place(C, c32, 2 * t, t);  place(C, c33, 2 * t, 2 * t);
    return C;
}

Matrix laderman(const Matrix &A, const Matrix &B) {
    return ladermanRec(View(A), View(B)).d;
}

double maxDifference(const Matrix &A, const Matrix &B) {
    double m = 0;
    for (size_t i = 0; i < A.size(); i++)
        for (size_t j = 0; j < A[i].size(); j++) m = max(m, fabs(A[i][j] - B[i][j]));
    return m;
}

void runTest(const string &name, Matrix (*f)(const Matrix &, const Matrix &),
             const Matrix &A, const Matrix &B, const Matrix &ref, bool verbose) {
    int n = A.size();
    g_mults = 0;
    g_adds = 0;

    auto start = chrono::steady_clock::now();
    Matrix C = f(A, B);
    auto stop = chrono::steady_clock::now();
    double ms = chrono::duration<double, milli>(stop - start).count();

    cout << left << setw(10) << name << " | time: " << fixed << setprecision(3)
         << setw(12) << ms << " ms";

    if (!verbose) {
        cout << "\n";
        return;
    }

    cout << " | mults: " << setw(10) << g_mults
         << " | adds: " << setw(10) << g_adds
         << " | total: " << setw(10) << g_mults + g_adds
         << " | max |error|: " << scientific << setprecision(3) << maxDifference(C, ref)
         << fixed << "\n";
    if (n <= MAX_DRAW_SIZE) {
        draw(C, PRINT_PRECISION);
        cout << "\n";
    }
}

int main() {
    const bool verbose = true;

    srand(time(nullptr));
    cout << "Enter matrix size n: ";
    int n;
    if (!(cin >> n) || n < 1) { cout << "Invalid size\n"; return 1; }

    Matrix A = generateMatrix(n);
    Matrix B = generateMatrix(n);
    Matrix ref;
    if (verbose) {
        ref = classical(A, B);
        if (n <= MAX_DRAW_SIZE) {
            cout << "\nA =\n";   draw(A, PRINT_PRECISION);
            cout << "\nB =\n";   draw(B, PRINT_PRECISION);
            cout << "\nA * B (classical) =\n"; draw(ref, PRINT_PRECISION);
        }
    }

    cout << "\nn = " << n << "\n\n";
    runTest("Classical", classical, A, B, ref, verbose);
    runTest("Binet",    binet,    A, B, ref, verbose);
    runTest("Strassen", strassen, A, B, ref, verbose);
    runTest("Laderman", laderman, A, B, ref, verbose);

    return 0;
}