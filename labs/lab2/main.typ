#set page(paper: "a4", margin: 2.5cm, numbering: "1")
#set text(font: "PT Serif", size: 12pt, lang: "pl", hyphenate: false)
#set heading(numbering: "1.")
#set table(stroke: 0.5pt + black, inset: (x: 10pt, y: 4pt))
#show table: set text(size: 10pt)
#show raw.where(block: true): it => block(fill: luma(246), inset: 7pt, radius: 3pt, width: 100%, text(size: 7pt, it))

#align(center)[
  #text(size: 22pt)[*Algorytmy macierzowe*]

  #text(size: 16pt)[*Sprawozdanie z zadania 2*]

  Adrian Mikoda#h(1em)Szymon Płókarz

  21.11.2026 r.
]

#outline()

= Treść zadania

Dla losowych macierzy kwadratowych o dowolnym rozmiarze $n$ i elementach z przedziału $(0.00000001, 1.0)$ należy zaimplementować:

+ rekurencyjne odwracanie macierzy z mnożeniem Binét'a i Strassena,
+ rekurencyjną faktoryzację LU z mnożeniem Binét'a i Strassena,
+ rekurencyjne odwracanie macierzy z mnożeniem Ladermana.

Mnożenie Ladermana (punkt 4) wykonaliśmy już w zadaniu 1. Macierze mnożymy własnymi algorytmami z zadania 1 i zliczamy operacje zmiennoprzecinkowe: dodawania, odejmowania, mnożenia i dzielenia.

= Środowisko

- Procesor: Apple M4 Pro (12 rdzeni), pamięć RAM: 24 GB LPDDR5X, system: macOS 26.6.2
- Język: C++20, kompilator `g++-15` (Homebrew GCC 15.2.0), flagi `-O2 -std=c++20`
- Wykresy: Python 3.13.0, numpy 2.2.4, matplotlib 3.10.1

C++ nie jest językiem interpretowanym. Kompilator `g++` przed uruchomieniem tłumaczy cały kod źródłowy na kod maszynowy procesora i zapisuje go w pliku wykonywalnym `lab2`. Procesor wykonuje ten plik bezpośrednio, bez interpretera ani maszyny wirtualnej.

= Algorytmy

Macierz $A$ dzielimy na bloki: $A_11$ ma rozmiar $k times k$, gdzie $k = floor(n/2)$, a $A_22$ ma rozmiar $(n-k) times (n-k)$. Taki podział działa dla każdego $n >= 2$ bez dopełniania zerami. Bloki są prostokątne, a mnożenia z zadania 1 obsługują macierze prostokątne. Znak $*$ w pseudokodzie oznacza mnożenie wybraną metodą rekurencyjną (Binét, Strassen albo Laderman).

== Odwracanie (punkty 1 i 3)

Odwracanie korzysta z dopełnienia Schura $S = A_22 - A_21 A_11^(-1) A_12$:

$ A^(-1) = mat(A_11^(-1) + A_11^(-1) A_12 S^(-1) A_21 A_11^(-1), -A_11^(-1) A_12 S^(-1); -S^(-1) A_21 A_11^(-1), S^(-1)) $

```
inverse(A):
    if n == 1: return [1 / a11]
    I11 = inverse(A11)
    P = I11 * A12;  Q = A21 * I11
    S = inverse(A22 - A21 * P)        // odwrotność dopełnienia Schura
    B12 = -P * S;   B21 = -S * Q
    B11 = I11 - B12 * Q               // = I11 + P S Q
    return [B11 B12; B21 S]
```

Na każdym poziomie są dwa wywołania rekurencyjne i sześć mnożeń bloków. Punkt 3 to ta sama funkcja z mnożeniem Ladermana.

== Faktoryzacja LU (punkt 2)

```
lu(A):
    if n == 1: return L = [1], U = [a11]
    L11, U11 = lu(A11)
    U12 = inverse(L11) * A12
    L21 = A21 * inverse(U11)
    L22, U22 = lu(A22 - L21 * U12)
    return L = [L11 0; L21 L22],  U = [U11 U12; 0 U22]
```

== Zliczanie operacji

Korzystamy z liczników `g_mults` i `g_adds` z zadania 1. Mnożenia macierzy zliczają się same. Dodatkowo liczymy dodawania i odejmowania bloków (`add`) oraz dzielenie $1 \/ a$ w przypadku bazowym. Zmiana znaku ($-P S$) nie jest działaniem na dwóch liczbach, więc jej nie liczymy. Wykresy pokazują sumę `g_mults + g_adds`.

= Kod

Plik `main.cpp` dołącza `../lab1/main.cpp`, w którym są funkcje `binet`, `strassen` i `laderman` oraz liczniki. Funkcję `main` z zadania 1 przemianowujemy makrem `#define main lab1_main`. Program uruchomiony z argumentem `n` dla losowej macierzy $n times n$ wypisuje czas, liczbę operacji i błąd. Bez argumentu liczy przykład z rozdziału 6.

#raw(read("main.cpp"), lang: "cpp", block: true)

= Wyniki

Pomiary wykonano dla 42 rozmiarów $n$ od 1 do 1000, rozłożonych równomiernie w skali logarytmicznej (`plots.py`). Obie osie wykresów są w skali logarytmicznej.

#figure(image("time.png", width: 100%), caption: [Czas działania])

#figure(image("flops.png", width: 100%), caption: [Liczba operacji zmiennoprzecinkowych])

#figure(
  table(
    columns: 5,
    align: (left, right, right, right, right),
    table.header([*Metoda*], [*Czas [s]*], [*Operacje*], [*Operacje / $n^3$*], [*$alpha$ (operacje)*]),
    [Binét -- odwracanie], [3,63], [2,00 · 10#super[9]], [2,00], [3,00],
    [Strassen -- odwracanie], [18,97], [2,33 · 10#super[9]], [2,33], [2,83],
    [Laderman -- odwracanie], [172,44], [6,37 · 10#super[9]], [6,37], [2,98],
    [Binét -- LU], [2,98], [1,66 · 10#super[9]], [1,66], [3,01],
    [Strassen -- LU], [17,14], [2,08 · 10#super[9]], [2,08], [2,85],
  ),
  caption: [Wyniki dla $n = 1000$. $alpha$ to nachylenie prostej dopasowanej do punktów $(ln n, ln "operacje")$ dla $n >= 100$.],
) <tab:wyniki>

- *Binét* jest najszybszy: dla $n = 1000$ odwracanie trwa 3,6 s, a LU 3,0 s. Odwracanie wykonuje ok. $2n^3$ operacji, tyle co eliminacja Gaussa--Jordana. LU wykonuje ok. $"1,66" n^3$ operacji, czyli więcej niż klasyczne $2/3 n^3$, bo $L_11$ i $U_11$ odwracamy ogólnym algorytmem, który nie korzysta z zer w macierzach trójkątnych.
- *Strassen* wykonuje 1,16 (odwracanie) i 1,25 (LU) razy więcej operacji niż Binét i działa 5--6 razy dłużej. Jego wykładnik ($alpha approx "2,83"$--$"2,85"$) jest jednak mniejszy niż 3, więc krzywe się zbliżają. Mnożenia w odwracaniu i LU mają rozmiar co najwyżej $n\/2 <= 500$, a w zadaniu 1 Strassen wyprzedzał metodę klasyczną dopiero przy $n approx 1000$.
- *Laderman* jest najwolniejszy (172 s, 3,2 razy więcej operacji niż Binét). Liczba operacji rośnie skokowo tuż za potęgami liczby 3 (jak w zadaniu 1), dlatego dopasowany wykładnik wynosi 2,98, a nie teoretyczne $log_3 23 approx "2,85"$.

Złożoność odwracania i LU jest taka sama jak złożoność użytego mnożenia. Dla odwracania $T(n) = 2T(n\/2) + 6M(n\/2) + O(n^2)$. Jeśli $M(n) = Theta(n^omega)$ i $omega > 1$, to z twierdzenia o rekurencji uniwersalnej $T(n) = Theta(n^omega)$. To samo zachodzi dla LU.

#figure(
  table(
    columns: 3,
    align: (left, right, right),
    table.header([*Metoda*], [*mediana błędu*], [*maks. błąd*]),
    [Binét -- odwracanie], [7,3 · 10#super[-10]], [2,1 · 10#super[-7]],
    [Strassen -- odwracanie], [6,6 · 10#super[-9]], [2,3 · 10#super[-6]],
    [Laderman -- odwracanie], [6,1 · 10#super[-9]], [1,4 · 10#super[-5]],
    [Binét -- LU], [1,8 · 10#super[-12]], [2,7 · 10#super[-8]],
    [Strassen -- LU], [1,3 · 10#super[-8]], [8,6 · 10#super[-3]],
  ),
  caption: [Błąd $max_(i j) |(X Y)_(i j) - "cel"_(i j)|$ dla wszystkich zmierzonych $n$: $A dot A^(-1)$ względem $I$ oraz $L dot U$ względem $A$],
) <tab:bledy>

Błędy są małe, co potwierdza poprawność wszystkich wariantów. Największy błąd ma Strassen LU dla $n = 754$ ($"8,6" dot 10^(-3)$). Dla tej samej macierzy błąd Binét LU też jest największy ($"2,7" dot 10^(-8)$, mediana $10^(-12)$), więc to cecha tej macierzy, a nie błąd w kodzie. LU bez wyboru elementu głównego trafia tu na mały element przekątnej $|u_(i i)| approx 3 dot 10^(-4)$, przez co elementy rozkładu rosną: $max|L| approx "1,5" dot 10^5$ i $max|U| approx "1,3" dot 10^6$, podczas gdy dla $n = 655, 869, 1000$ oba maksima nie przekraczają $"1,7" dot 10^4$. Błąd zaokrągleń jest proporcjonalny do tych wielkości. Strassen dodatkowo wzmacnia go bardziej niż mnożenie klasyczne, bo jego oszacowanie błędu jest normowe, a nie elementowe. Względem $max|L| dot max|U|$ błąd wynosi ok. $10^(-13)$, czyli jest na poziomie zaokrągleń.

= Poprawność

== Dowód

Dowód przez indukcję po $n$. Dla $n = 1$ wynik jest oczywisty. Załóżmy, że wywołania dla bloków $A_11$ i $S$ zwracają poprawne odwrotności. Oznaczmy $P = A_11^(-1) A_12$ i $Q = A_21 A_11^(-1)$. Mnożąc blokowo $A dot B$, dostajemy:

- $A_11 B_11 + A_12 B_21 = (I + A_12 S^(-1) Q) - A_12 S^(-1) Q = I$,
- $A_11 B_12 + A_12 S^(-1) = -A_12 S^(-1) + A_12 S^(-1) = 0$,
- $A_21 B_11 + A_22 B_21 = Q + A_21 P S^(-1) Q - A_22 S^(-1) Q = Q - (A_22 - A_21 P) S^(-1) Q = Q - S S^(-1) Q = 0$,
- $A_21 B_12 + A_22 S^(-1) = (A_22 - A_21 P) S^(-1) = S S^(-1) = I$.

Zatem $A B = I$. Dla LU z założenia indukcyjnego $L_11 U_11 = A_11$ i $L_22 U_22 = A_22 - L_21 U_12$, więc

$ L U = mat(L_11 U_11, L_11 U_12; L_21 U_11, L_21 U_12 + L_22 U_22) = mat(A_11, A_12; A_21, A_22) = A. $

Macierze $L_11$ i $L_22$ są dolnotrójkątne z jedynkami na przekątnej, a $U_11$ i $U_22$ -- górnotrójkątne, więc $L$ i $U$ też. Algorytmy nie wybierają elementu głównego, więc wymagają, aby wszystkie wiodące minory główne $A$ były niezerowe. Dla macierzy losowych zachodzi to z prawdopodobieństwem 1.

== Przykład ręczny

$ A = mat(0.5, 0.25, 0.25; 0.25, 0.5, 0.25; 0.25, 0.25, 0.5), quad k = 1 $

*Odwracanie.* $A_11^(-1) = 1 \/ 0.5 = 2$, $P = 2 dot mat(0.25, 0.25) = mat(0.5, 0.5)$, $Q = mat(0.5; 0.5)$,

$ S = A_22 - A_21 P = mat(0.5, 0.25; 0.25, 0.5) - mat(0.125, 0.125; 0.125, 0.125) = mat(0.375, 0.125; 0.125, 0.375). $

Rekurencyjnie dla $S$: $s_11^(-1) = 8\/3$, $p = q = 8\/3 dot 0.125 = 1\/3$, $s = 0.375 - 0.125 dot 1\/3 = 1\/3$, czyli $s^(-1) = 3$. Dalej $b_12 = b_21 = -1\/3 dot 3 = -1$ oraz $b_11 = 8\/3 + 1\/3 dot 3 dot 1\/3 = 3$, więc $S^(-1) = mat(3, -1; -1, 3)$.

$ B_12 = -P S^(-1) = mat(-1, -1), quad B_21 = mat(-1; -1), quad B_11 = 2 + P S^(-1) Q = 2 + 1 = 3 $

$ A^(-1) = mat(3, -1, -1; -1, 3, -1; -1, -1, 3) $

*LU.* $L_11 = 1$, $U_11 = 0.5$, $U_12 = mat(0.25, 0.25)$, $L_21 = mat(0.25; 0.25) dot 2 = mat(0.5; 0.5)$, $A_22 - L_21 U_12 = S$ (to samo $S$ co wyżej). Rekurencyjnie: $L_S = mat(1, 0; 1\/3, 1)$, $U_S = mat(0.375, 0.125; 0, 1\/3)$.

$ L = mat(1, 0, 0; 0.5, 1, 0; 0.5, 1\/3, 1), quad U = mat(0.5, 0.25, 0.25; 0, 0.375, 0.125; 0, 0, 1\/3) $

*Wynik programu* (`./lab2` bez argumentów) jest taki sam jak wynik obliczeń ręcznych dla wszystkich trzech metod mnożenia:

#raw(read("example.txt"), block: true)

= Wnioski

- Rekurencyjne odwracanie (dopełnienie Schura) i rekurencyjna faktoryzacja LU działają dla macierzy o dowolnym rozmiarze. Wystarcza podział na bloki $floor(n/2)$ i $ceil(n/2)$, bez dopełniania zerami. Poprawność potwierdza dowód indukcyjny, przykład ręczny $3 times 3$ zgodny z programem oraz mały błąd $A A^(-1) - I$ i $L U - A$ dla losowych macierzy.
- Odwracanie i LU mają taką samą złożoność jak użyte mnożenie macierzy. Cały koszt leży w mnożeniach bloków.
- W badanym zakresie $n <= 1000$ najszybszy i najdokładniejszy jest wariant z mnożeniem Binét'a. Strassen i Laderman zmniejszają liczbę mnożeń, ale dodają tyle dodawań i alokacji pamięci, że są wolniejsze i wykonują więcej operacji. Mnożenia w rekurencji mają rozmiar najwyżej $n\/2$, a przy takich rozmiarach Strassen i Laderman jeszcze się nie opłacają.
- Brak wyboru elementu głównego sprawia, że dokładność zależy od macierzy. Najbardziej widać to w LU ze Strassenem: dla jednej z macierzy błąd sięgnął $10^(-2)$.
