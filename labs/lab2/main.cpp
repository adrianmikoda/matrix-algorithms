// Zadanie 2: rekurencyjne odwracanie macierzy i rekurencyjna faktoryzacja LU.
// Mnozenie macierzy (binet, strassen, laderman) i liczniki operacji (g_mults, g_adds) z zadania 1.
#define main lab1_main
#include "../lab1/main.cpp"
#undef main

using Mul = Matrix (*)(const Matrix &, const Matrix &);

Matrix sub(const Matrix &A, int r0, int r1, int c0, int c1) {  // blok A[r0:r1, c0:c1]
    Matrix S;
    for (int i = r0; i < r1; i++) S.emplace_back(A[i].begin() + c0, A[i].begin() + c1);
    return S;
}

Matrix add(Matrix A, const Matrix &B, double s = 1) {  // A + s*B, s = +-1
    for (size_t i = 0; i < A.size(); i++)
        for (size_t j = 0; j < A[i].size(); j++) A[i][j] += s * B[i][j];
    g_adds += A.size() * A[0].size();
    return A;
}

Matrix neg(Matrix A) {  // zmiana znaku - nie jest dzialaniem na dwoch liczbach, nie liczymy
    for (auto &r : A) for (auto &x : r) x = -x;
    return A;
}

Matrix zeros(int r, int c) { return Matrix(r, vector<double>(c, 0.0)); }

Matrix join(const Matrix &A11, const Matrix &A12, const Matrix &A21, const Matrix &A22) {
    Matrix C = A11;
    C.insert(C.end(), A21.begin(), A21.end());
    for (size_t i = 0; i < C.size(); i++) {
        const auto &r = i < A12.size() ? A12[i] : A22[i - A12.size()];
        C[i].insert(C[i].end(), r.begin(), r.end());
    }
    return C;
}

Matrix inverse(const Matrix &A, Mul mul) {
    int n = A.size(), k = n / 2;
    if (n == 1) { g_mults++; return {{1.0 / A[0][0]}}; }  // jedno dzielenie
    Matrix I11 = inverse(sub(A, 0, k, 0, k), mul);
    Matrix A12 = sub(A, 0, k, k, n), A21 = sub(A, k, n, 0, k);
    Matrix P = mul(I11, A12), Q = mul(A21, I11);                        // A11^-1 A12, A21 A11^-1
    Matrix S = inverse(add(sub(A, k, n, k, n), mul(A21, P), -1), mul);  // (A22 - A21 A11^-1 A12)^-1
    Matrix B12 = neg(mul(P, S)), B21 = neg(mul(S, Q));
    Matrix B11 = add(I11, mul(B12, Q), -1);                             // A11^-1 + P S Q
    return join(B11, B12, B21, S);
}

pair<Matrix, Matrix> lu(const Matrix &A, Mul mul) {
    int n = A.size(), k = n / 2;
    if (n == 1) return {Matrix{{1.0}}, A};
    auto [L11, U11] = lu(sub(A, 0, k, 0, k), mul);
    Matrix U12 = mul(inverse(L11, mul), sub(A, 0, k, k, n));                // L11^-1 A12
    Matrix L21 = mul(sub(A, k, n, 0, k), inverse(U11, mul));                // A21 U11^-1
    auto [L22, U22] = lu(add(sub(A, k, n, k, n), mul(L21, U12), -1), mul);  // LU(A22 - L21 U12)
    return {join(L11, zeros(k, n - k), L21, L22), join(U11, U12, zeros(n - k, k), U22)};
}

// mierzy czas i liczbe operacji f(); f zwraca (X, Y), poprawnosc: max |X*Y - target|
template <class F> void measure(const string &name, const Matrix &target, F f) {
    g_mults = g_adds = 0;
    auto t0 = chrono::steady_clock::now();
    auto [X, Y] = f();
    double ms = chrono::duration<double, milli>(chrono::steady_clock::now() - t0).count();
    unsigned long long flops = g_mults + g_adds;
    cout << target.size() << "," << name << "," << ms << "," << flops << ","
         << maxDifference(classical(X, Y), target) << "\n";
}

int main(int argc, char **argv) {
    vector<pair<string, Mul>> muls = {{"Binet", binet}, {"Strassen", strassen}, {"Laderman", laderman}};
    if (argc < 2) {  // przyklad do recznego sprawdzenia
        Matrix A = {{0.5, 0.25, 0.25}, {0.25, 0.5, 0.25}, {0.25, 0.25, 0.5}};
        for (auto &[name, mul] : muls) { cout << name << ": A^-1 =\n"; draw(inverse(A, mul), 4); }
        auto [L, U] = lu(A, binet);
        cout << "L =\n"; draw(L, 4);
        cout << "U =\n"; draw(U, 4);
        return 0;
    }
    int n = atoi(argv[1]);
    srand(n);
    Matrix A = generateMatrix(n), I = zeros(n, n);
    for (int i = 0; i < n; i++) I[i][i] = 1;
    for (auto &[name, mul] : muls) measure(name + " inv", I, [&] { return pair{A, inverse(A, mul)}; });
    for (auto &[name, mul] : muls)
        if (name != "Laderman") measure(name + " LU", A, [&] { return lu(A, mul); });
}
