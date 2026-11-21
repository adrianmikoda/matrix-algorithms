#set align(left)

#set page(
  paper: "a4",
  margin: (x: 2.5cm, y: 2.5cm),
  numbering: "1",
  footer: context [
    #set align(right)
    #counter(page).display()
  ]
)

#set text(
  font: "PT Serif",
  size: 12pt,
  lang: "pl",
  hyphenate: false
)
#set heading(numbering: "1.")
#set par(justify: false)
#set table(stroke: 0.5pt + black)
#show figure: set block(breakable: true)

#set table(
  stroke: 0.5pt + black,
  inset: (x: 10pt, y: 2pt),
)
#show table: set text(size: 7pt)
#show figure: set block(breakable: true)
#show figure: set block(above: 6pt, below: 6pt)
#align(center)[
  #text(size: 22pt)[*Algorytmy macierzowe*]

  #text(size: 16pt)[*Sprawozdanie z zadania 1*]

  #text(size: 12pt)[Adrian Mikoda#h(1em)Szymon Płókarz]

  #text(size: 12pt)[25.10.2026 r.]
]

#show raw.where(block: true): it => {
  show raw.line: l => {
    box(width: 1.8em, align(right, text(fill: luma(130), size: 7pt, str(l.number))))
    h(0.8em)
    l.body
  }
  block(fill: luma(246), inset: 7pt, radius: 3pt, width: 100%, align(left, text(size: 8pt, it)))
}

#outline()

#pagebreak()

= Dane techniczne

- System operacyjny: #text(font: "New Computer Modern Mono", "macOS 26.6.2")
- Procesor: #text(font: "New Computer Modern Mono", "Apple M4 Pro (12 rdzeni)")
- Pamięć RAM: #text(font: "New Computer Modern Mono", "24GB LPDDR5X")
- Język programowania: #text(font: "New Computer Modern Mono", "C++ w standardzie C++17")
- Kompilator: #text(font: "New Computer Modern Mono", "g++ (Homebrew GCC 15.2.0_1) 15.2.0")
- Wizualizacja wyników: #text(font: "New Computer Modern Mono", "Python 3.13.0")
- Użyte biblioteki: #text(font: "New Computer Modern Mono", "matplotlib 3.10.1, numpy 2.2.4")

= Treść zadań

== Zadania implementacyjne

W ramach pierwszego zestawu zadań, realizowanego w parach dwuosobowych, należy wybrać dowolny język programowania, który nie jest językiem interpretowanym.

Należy wygenerować losowe macierze kwadratowe o elementach należących do przedziału otwartego $(0.00000001, 1.0)$, a następnie zaimplementować następujące algorytmy:

+ Rekurencyjne mnożenie macierzy metodą Binét’a.
+ Rekurencyjne mnożenie macierzy metodą Strassena.
+ Rekurencyjne mnożenie macierzy metodą Ladermana.

Podczas wykonywania mnożenia macierzy należy zliczać liczbę operacji zmiennoprzecinkowych, tj. dodawania, odejmowania, mnożenia i dzielenia ($+, -, times, div$).

Wszystkie algorytmy należy zaprojektować i zbadać dla macierzy kwadratowych o dowolnym rozmiarze, tj. o jednakowej liczbie wierszy i kolumn.

== Wymagania dotyczące raportu

W ramach sprawozdania należy przygotować następujące elementy:

+ *Opis pseudokodu* rekurencyjnego algorytmu mnożenia macierzy – 1 punkt.

+ *Najważniejsze fragmenty kodu źródłowego* przedstawiające implementację algorytmu – 1 punkt.

+ *Charakterystyka środowiska wykonawczego* – uzasadnienie, dlaczego wybrany język programowania nie jest interpretowany, oraz podanie informacji o procesorze i pamięci komputera, na którym przeprowadzono eksperymenty – 1 punkt.

+ *Wykres czasu działania algorytmu* – 2 punkty.
  - Oś pozioma: rozmiar macierzy $n = 1, 2, 3, ..., 1000$ (lub maksymalny rozmiar, dla którego udało się wykonać obliczenia).
  - Oś pionowa: czas działania rekurencyjnego algorytmu mnożenia macierzy.

+ *Wykres liczby operacji zmiennoprzecinkowych* – 3 punkty.
  - Oś pozioma: rozmiar macierzy $n = 1, 2, 3, ..., 1000$ (lub maksymalny rozmiar, dla którego udało się wykonać obliczenia).
  - Oś pionowa: liczba operacji zmiennoprzecinkowych wykonanych przez rekurencyjny algorytm.

+ *Oszacowanie złożoności obliczeniowej* algorytmu na podstawie analizy teoretycznej lub wyników eksperymentalnych – 2 punkty.

== Weryfikacja poprawności wyników

Dla wybranej małej macierzy kwadratowej o rozmiarze co najmniej $4 times 4$ należy:

+ Wykonać mnożenie macierzy w środowisku Octave lub MATLAB.
+ Porównać otrzymany wynik z wynikiem własnej implementacji.
+ Zamieścić w sprawozdaniu wyniki obliczeń oraz raport z porównania.

// #pagebreak()

= Realizacja ćwiczenia

== Środowisko implementacji

Do realizacji ćwiczenia wybrano język C++ w standardzie C++17.

Macierze reprezentowane są za pomocą kontenera `vector<vector<double>>`, przechowującego wartości zmiennoprzecinkowe typu `double`. Program skompilowano z wykorzystaniem kompilatora `g++` oraz flag optymalizacji `-O2` i `-std=c++17`.

== Generowanie macierzy i zliczanie operacji

Zaimplementowano funkcję `generateMatrix(n)`, generującą dwie losowe macierze kwadratowe $A$ i $B$ o rozmiarze $n times n$. Elementy macierzy są liczbami typu `double` należącymi do przedziału otwartego $(0.00000001, 1.0)$.

W celu zliczania operacji zmiennoprzecinkowych zastosowano dwa globalne liczniki:
- `g_mults` -- liczba wykonanych mnożeń,
- `g_adds` -- liczba wykonanych dodawań i odejmowań.

Łączna liczba operacji obliczana jest jako suma `g_mults + g_adds`. Liczniki są zerowane przed uruchomieniem każdego algorytmu.

#pagebreak()
== Punkt 1 -- rekurencyjne mnożenie macierzy metodą Binét'a

Zaimplementowano rekurencyjny algorytm mnożenia macierzy metodą Binét'a w funkcjach `binet()` oraz `binetAdd()`. Algorytm wykorzystuje klasyczny podział macierzy na cztery bloki, a następnie oblicza wynik za pomocą ośmiu rekurencyjnych mnożeń odpowiednich podmacierzy.
Jego schemat działania przedstawiono we #ref(<code:binetpseudocode>, supplement: [fragmencie pseudokodu nr]).

Podział wykonywany jest w połowie każdego wymiaru. Rekurencja kończy działanie, gdy przynajmniej jeden z wymiarów mnożenia jest mniejszy od 2. W takim przypadku stosowany jest klasyczny algorytm mnożenia macierzy.

\

#figure(
  align(center, raw(read("binet_pseudocode.txt"), lang: "c++", block: true)),
  caption: [Schemat działania metody  Binét'a],
  supplement: [Fragment pseudokodu],
) <code:binetpseudocode>

#pagebreak()
== Punkt 2 -- rekurencyjne mnożenie macierzy metodą Strassena

Zaimplementowano algorytm Strassena w funkcjach `strassen()`, `strassenRec()` oraz `strassen2x2()`.
Algorytm dzieli macierze na cztery bloki, a następnie wyznacza siedem iloczynów pośrednich `M1`--`M7`. Na ich podstawie oblicza cztery bloki macierzy wynikowej: $C_11$, $C_12$, $C_21$ oraz $C_22$.
Jego schemat działania przedstawiono we #ref(<code:strassenpseudocode>, supplement: [fragmencie pseudokodu nr]).

Algorytm nie wymaga, aby rozmiar macierzy był potęgą liczby 2, i nie dopełnia macierzy zerami do takiego rozmiaru. Na każdym poziomie rekurencji macierz dzielona jest w połowie: bloki mają rozmiary $ceil(n/2)$ i $floor(n/2)$. Gdy $n$ jest nieparzyste, brakujący wiersz lub kolumnę mniejszego bloku traktuje się jak zera, ale nie są one fizycznie dopisywane ani liczone. Dla macierzy o rozmiarze $2 times 2$ zastosowano bezpośredni wariant algorytmu Strassena, wykonujący 7 mnożeń i 18 dodawań lub odejmowań. W pozostałych przypadkach, gdy co najmniej jeden wymiar jest $<= 2$, wykonywane jest klasyczne mnożenie macierzy.

\

#figure(
  align(center, raw(read("strassen_pseudocode.txt"), lang: "c++", block: true)),
  caption: [Schemat działania metody Strassena],
  supplement: [Fragment pseudokodu],
) <code:strassenpseudocode>

#pagebreak()
== Punkt 3 -- rekurencyjne mnożenie macierzy metodą Ladermana

Zaimplementowano rekurencyjny algorytm Ladermana w funkcjach `laderman()` oraz `ladermanRec()`. Algorytm dzieli macierze na dziewięć bloków, a następnie wyznacza 23 iloczyny pośrednie `m1`--`m23`. Na ich podstawie oblicza dziewięć bloków macierzy wynikowej `c11`--`c33`. Jego schemat działania przedstawiono we #ref(<code:ladermanpseudocode>, supplement: [fragmencie pseudokodu nr]).

Podobnie jak w implementacji Strassena, nie zastosowano wcześniejszego dopełniania całych macierzy zerami. Wielkość bloków wyznaczana jest na podstawie najbliższej większej lub równej potęgi liczby 3.
W pozostałych przypadkach, gdy co najmniej jeden wymiar jest $<3$, wykonywane jest klasyczne mnożenie macierzy.

\

#figure(
  align(center, raw(read("laderman_psudocode.txt"), lang: "c++", block: true)),
  caption: [Schemat działania metody Ladermana],
  supplement: [Fragment pseudokodu],
) <code:ladermanpseudocode>

== Pomiar czasu i weryfikacja poprawności

Funkcja `runTest()` uruchamia wybraną metodę mnożenia macierzy. Pomiar czasu realizowany jest za pomocą `chrono::steady_clock` [ms].
Klasyczne mnożenie macierzy w funkcji `classical()`, służy jako wynik referencyjny.

Dla macierzy o rozmiarze nieprzekraczającym $10 times 10$ program wyświetla macierze wejściowe, wynik oraz statystyki operacji.

Wszystkie cztery metody -- klasyczna, Binét’a, Strassena i Ladermana -- zaimplementowano w pliku `main.cpp`
#ref(<code:matrixmultiplication>, supplement: [fragment kodu])).

\

#figure(
  align(center, raw(read("main.cpp"), lang: "c++", block: true)),
  caption: [ Plik `main.cpp` -- metoda klasyczna, Binet'a, Strassena oraz Ladermana],
  supplement: [Fragment kodu],
) <code:matrixmultiplication>

#pagebreak()
= Wyniki

== Czas działania

Pomiary wykonano dla 67 rozmiarów $n$ od 1 do 1000. Wybrano punkty rozłożone równomiernie w skali logarytmicznej oraz rozmiary tuż przed i tuż za potęgami liczb 2 i 3 ($2^k$, $2^k + 1$, $3^k$, $3^k + 1$). Dla $n <= 100$ przyjęto najkrótszy z trzech pomiarów. Wszystkie wykresy mają obie osie w skali logarytmicznej (log-log). Funkcja $c dot n^alpha$ jest wtedy prostą o nachyleniu $alpha$, więc nachylenie krzywej bezpośrednio pokazuje wykładnik złożoności. Wartości $alpha$ podane w legendach wyznaczono w podrozdziale 5.2.

#figure(
  image("execution_time.png", width: 100%),
  caption: [Czas działania metod w zależności od rozmiaru macierzy $n$ (skala log-log)],
) <fig:czas>

\

Najszybsza jest nierekurencyjna metoda klasyczna, która służy jako punkt odniesienia. Spośród metod rekurencyjnych najszybsza okazała się metoda Binét'a (#ref(<fig:czas>, supplement: [rysunek])). Liczy ona wynik w miejscu, na „widokach” podmacierzy, bez alokowania nowej pamięci. Metody Strassena i Ladermana są wielokrotnie wolniejsze: każda suma bloków tworzy nową macierz, a rekurencja schodzi do bloków $2 times 2$, więc czas zdominowany jest przez alokacje pamięci i dodawania. Najwolniejsza jest metoda Ladermana (23 wywołania rekurencyjne i 98 dodawań bloków na poziom, wobec 7 i 18 u Strassena). Dla $n = 1000$ Laderman liczy ok. 205 s, Strassen ok. 15,5 s, Binét ok. 3,9 s, a metoda klasyczna ok. 0,12 s. Skoki czasu tuż za potęgami liczby 3 (Laderman, $n = 243 -> 244$ i $729 -> 730$) oraz liczby 2 (Strassen, np. $n = 512 -> 513$) wyjaśniono w kolejnym podrozdziale.

== Liczba operacji zmiennoprzecinkowych

Liczbę operacji odczytano z liczników `g_mults` i `g_adds` w tych samych przebiegach programu co pomiar czasu. Liczone są tylko działania na dwóch rzeczywistych liczbach.

#figure(
  image("flops.png", width: 100%),
  caption: [Liczba operacji zmiennoprzecinkowych (skala log-log); linia przerywana -- metoda klasyczna, $2n^3 - n^2$],
) <fig:flops>

#figure(
  grid(
    columns: 2,
    gutter: 6pt,
    image("multiplications.png", width: 100%),
    image("additions_and_subtractions.png", width: 100%),
  ),
  caption: [Liczba mnożeń (po lewej) oraz dodawań i odejmowań (po prawej), skala log-log],
) <fig:mulsadds>

#figure(
  image("flops_ratio.png", width: 100%),
  caption: [Liczba operacji względem metody klasycznej $2n^3 - n^2$ (oś $n$ w skali logarytmicznej)],
) <fig:flopsratio>

- *Binét* wykonuje dokładnie $2n^3 - n^2$ operacji, czyli tyle co metoda klasyczna -- rekurencja zmienia tylko kolejność obliczania tych samych iloczynów, dlatego krzywe na #ref(<fig:flops>, supplement: [rysunku]) się pokrywają.
- *Strassen* wykonuje najmniej mnożeń (dla $n = 1000$ -- 28% mnożeń metody klasycznej), ale dodawania stanowią ok. 86% jego operacji. Dlatego łącznie wykonuje mniej operacji niż metoda klasyczna tylko dla niektórych $n$ bliskich 1000 (spośród zmierzonych: $n = 626$ i $n = 1000$, ok. 0,97 operacji metody klasycznej).
- *Laderman* dla każdego $n >= 3$ wykonuje więcej operacji niż metoda klasyczna (np. 1,52 razy więcej dla $n = 729$ i 3,78 razy dla $n = 1000$). Dodawania stanowią ok. 87% jego operacji.

W metodzie Ladermana skoki tuż za potęgami liczby 3 ($n = 244, 730$, ok. 3 razy) wynikają z podziału według najbliższej potęgi 3. Dla $n = 730$ bloki mają rozmiary 729, 1 i 0, a pełny rozmiar mają tylko 3 z 23 iloczynów ($m_4$, $m_6$, $m_7$).

W metodzie Strassena podział w połowie ($ceil(n/2)$ i $floor(n/2)$) usunął skoki ok. 2 razy, które występowały przy podziale według potęgi 2 (wcześniej dla $n = 513$ bloki miały rozmiary 512 i 1). Pozostały mniejsze skoki tuż za potęgami liczby 2 ($n = 129, 257, 513$): ok. 1,34 razy w liczbie operacji i ok. 2,5 razy w czasie. Rekurencja ma $ceil(log_2 n)$ poziomów, więc za potęgą 2 dochodzi jeden poziom. Liczba operacji rośnie przez to nieznacznie, ale liczba wywołań rekurencyjnych na małych blokach rośnie ok. 2,5 razy (dla $n = 512$: $"6,7" dot 10^6$, dla $n = 513$: $"16,8" dot 10^6$), a z nią liczba alokacji -- stąd większy skok czasu.

#figure(
  table(
    columns: 6,
    align: right,
    table.header(
      [*$n$*], [*Binét = klasyczna*], [*Strassen*], [*Strassen / klasyczna*], [*Laderman*], [*Laderman / klasyczna*],
    ),
    [100], [1,99 · 10#super[6]], [3,63 · 10#super[6]], [1,82], [1,15 · 10#super[7]], [5,76],
    [512], [2,68 · 10#super[8]], [2,81 · 10#super[8]], [1,05], [6,54 · 10#super[8]], [2,44],
    [513], [2,70 · 10#super[8]], [3,76 · 10#super[8]], [1,39], [6,58 · 10#super[8]], [2,44],
    [729], [7,74 · 10#super[8]], [8,51 · 10#super[8]], [1,10], [1,18 · 10#super[9]], [1,52],
    [730], [7,78 · 10#super[8]], [8,52 · 10#super[8]], [1,10], [3,56 · 10#super[9]], [4,57],
    [1000], [2,00 · 10#super[9]], [1,95 · 10#super[9]], [0,97], [7,55 · 10#super[9]], [3,78],
  ),
  caption: [Liczba operacji zmiennoprzecinkowych dla wybranych rozmiarów macierzy],
) <tab:flops>

#pagebreak()
= Złożoność obliczeniowa

== Analiza teoretyczna

Każda metoda dzieli macierz na bloki o boku $n / b$ i wykonuje $a$ rekurencyjnych mnożeń oraz $c$ dodawań bloków, więc

$ T(n) = a dot T(n / b) + c dot (n / b)^2. $

Ponieważ $log_b a > 2$, z twierdzenia o rekurencji uniwersalnej (_master theorem_) $T(n) = Theta(n^(log_b a))$ -- złożoność wyznacza liczba mnożeń rekurencyjnych.

#figure(
  table(
    columns: 5,
    align: center,
    table.header([*Metoda*], [*$a$*], [*$b$*], [*$c$*], [*Złożoność*]),
    [Binét], [8], [2], [4], [$Theta(n^3)$],
    [Strassen], [7], [2], [18], [$Theta(n^(log_2 7)) approx Theta(n^"2,807")$],
    [Laderman], [23], [3], [98], [$Theta(n^(log_3 23)) approx Theta(n^"2,854")$],
  ),
  caption: [Parametry równań rekurencyjnych i wynikająca z nich złożoność],
) <tab:rekurencje>

W metodzie Strassena podział na bloki $ceil(n/2)$ i $floor(n/2)$ sprawia, że rekurencja $T(n) = 7 T(ceil(n/2)) + 18 ceil(n/2)^2$ obowiązuje dla każdego $n$, a nie tylko dla potęg 2. Oszacowanie $Theta(n^(log_2 7))$ dotyczy więc dowolnego rozmiaru macierzy.

Dla potęg podziału rekurencję można rozwiązać dokładnie (wzory zgadzają się z licznikami programu dla wszystkich takich $n <= 1000$):

- Binét (dowolne $n$): $T(n) = 2 n^3 - n^2$,
- Strassen ($n = 2^k$): $T(n) = 7 n^(log_2 7) - 6 n^2$,
- Laderman ($n = 3^k$): $T(n) = 8 n^(log_3 23) - 7 n^2$.

Dla pozostałych $n$ liczba operacji leży między wartościami dla sąsiednich potęg, więc zmienia się tylko stała, a nie klasa złożoności. Z wzorów wynika też, że dla potęg podziału metoda Strassena wykonuje mniej operacji niż klasyczna dopiero od $n = 2^10 = 1024$, a metoda Ladermana od $n = 3^9 = 19683$ -- stąd wyniki w badanym zakresie $n <= 1000$.

== Weryfikacja eksperymentalna

Wykładnik złożoności oszacowano na podstawie wszystkich zmierzonych rozmiarów $n >= 100$, a nie tylko potęg podziału. Metodą najmniejszych kwadratów dopasowano prostą do punktów $(ln n, ln T(n))$:

$ ln T(n) approx alpha dot ln n + ln c. $

Współczynnik $alpha$ to nachylenie prostej na wykresie log-log. Oszacowanie wykonano osobno dla liczby operacji i dla czasu działania. Pominięto $n < 100$, bo tam wynik zaburza składnik z $n^2$ oraz stały narzut pomiaru czasu.

#figure(
  table(
    columns: 4,
    align: center,
    table.header([*Metoda*], [*$alpha$ (liczba operacji)*], [*$alpha$ (czas)*], [*Teoria*]),
    [klasyczna], [3,002], [3,050], [3],
    [Binét], [3,002], [2,945], [3],
    [Strassen], [2,803], [2,831], [2,807],
    [Laderman], [2,825], [2,837], [2,854],
  ),
  caption: [Eksperymentalny wykładnik złożoności $alpha$ (regresja dla wszystkich zmierzonych $n in [100, 1000]$)],
) <tab:wykladniki>

Wykładniki wyznaczone z liczby operacji są bliskie teoretycznym: 3,002 dla metody Binét'a i 2,803 dla metody Strassena (teoria 2,807). Dla metody Ladermana wynik zależy od wybranego przedziału, bo liczba operacji rośnie skokowo (ok. 3 razy) tuż za potęgami liczby 3. Dla $n >= 100$ otrzymano 2,825, a dla $n >= 50$ -- 2,92. Wykładniki wyznaczone z czasu potwierdzają ten sam porządek metod, choć czas jest dodatkowo zaburzony narzutem alokacji i pamięcią podręczną. Wyniki potwierdzają złożoność $Theta(n^3)$ dla metody Binét'a, $Theta(n^"2,807")$ dla metody Strassena i $Theta(n^"2,854")$ dla metody Ladermana.

#pagebreak()

= Wnioski
Wszystkie trzy algorytmy dają poprawne wyniki, a ich złożoność obliczeniowa została potwierdzona eksperymentalnie. Wykładniki wyznaczone regresją na wykresach log-log, z liczby operacji i z czasu, dla wszystkich zmierzonych $n >= 100$, są bliskie wartościom teoretycznym: $Theta(n^3)$ dla metody Binét’a, $Theta(n^"2,807")$ dla metody Strassena i $Theta(n^"2,854")$ dla metody Ladermana.

Dzięki podziałowi na bloki $ceil(n/2)$ i $floor(n/2)$ metoda Strassena działa dla dowolnego $n$ bez odwoływania się do potęg liczby 2. Zniknęły skoki liczby operacji ok. 2 razy, a dla części $n$ bliskich 1000 Strassen wykonuje już mniej operacji niż metoda klasyczna.

Metoda Binét’a wykonuje dokładnie tyle samo operacji co metoda klasyczna, ponieważ rekurencja zmienia jedynie kolejność obliczania tych samych iloczynów. Strassen i Laderman zmniejszają liczbę mnożeń, ale kosztem znacznie większej liczby dodawań.

W praktyce najszybsza okazała się metoda Binét’a, ze względu na wykonywanie obliczeń w miejscu. Metody Strassena i Ladermana są dużo wolniejsze. Ich czas wykonania jest zwiększony przez rekurencyjną alokację pamięci dla nowych podmacierzy. Zastosowanie tych algorytmów ma sens po optymalizacji lub dla dużo większych macierzy.