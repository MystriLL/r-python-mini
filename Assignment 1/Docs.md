# Assignment 1

## Wstęp
Celem projektu było przetestowanie i zaprezentowanie działania czterech metod pozwalajacych na wykonanie zapytania SQL w jezyku R. Były to:

- sqldf
- Podejście polegające na wykorzystaniu wyłącznie metod wbudowanych w R bez użycia zewnętrznych bibliotek
- dplyr
- data.table

## Konfiguracja i funkcje pomocnicze
Poniżej przedstawiona jest konfiguracja środowiska testowego i funkcje pomocnicze pozwalające na wywoływanie i porównywanie wyników oraz czasu działania wszystkich badanych implementacji.

### Wczytanie danych
```
# Load functions from file
source("Assignment1.r")

# Load files
Posts <- read.csv("./Posts.csv")
Users <- read.csv("./Users.csv")
Comments <- read.csv("./Comments.csv")
PostLinks <- read.csv("./PostLinks.csv")

library(data.table)

# Create tables
PostsDT <- fread("./Posts.csv")
UsersDT <- fread("./Users.csv")
CommentsDT <- fread("./Comments.csv")
PostLinksDT <- fread("./PostLinks.csv")
```

### Funkcja porównująca
```
# Function comparing results of all implementations
compare_results <- function(reference_result, results) {
  n <- length(results)
  for (i in 1:n) {
    differences <- all.equal(reference_result, results[[i]], check.attributes = FALSE)
    
    if (is.logical(differences) && differences == TRUE) {
      cat("Results from implementation 1 and", i + 1, "are identical.\n")
    } else {
      cat("Results from implementation 1 and", i + 1, "differ.\n")
      print(differences)
    }
  }
}
```
### Benchmark
```
# Running functions
library(microbenchmark)

#Set number of repetitions for benchmark functions
repetitionsNumber <- 10

# Call benchmark function
executionTimes <- microbenchmark(
  sqldf = sqldf_1(Posts, Users),
  base = base_1(Posts, Users),
  dplyr = dplyr_1(Posts, Users),
  data.table = data.table_1(PostsDT, UsersDT),
  times = repetitionsNumber
)
```

## Zadanie 1
### Komenda SQL
```
SELECT Location, COUNT(*) AS Count FROM (
            SELECT Posts.OwnerUserId, Users.Id, Users.Location FROM Users
            JOIN Posts ON Users.Id = Posts.OwnerUserId
        )
        WHERE Location NOT IN ('') GROUP BY Location
        ORDER BY Count DESC
        LIMIT 10
```

Komenda zwraca liczbę postów dla każdej lokalizacji użytkowników, wyłączając puste lokalizacje. Wyniki są posortowane malejąco według liczby postów i ograniczone do 10 wyników.

### Wyniki
```
# Task 1

result1 <- sqldf_1(Posts, Users)
result2 <- base_1(Posts, Users)
result3 <- dplyr_1(Posts, Users)
result4 <- data.table_1(PostsDT, UsersDT)

results_to_compare <- list(result2, result3, result4)

# Compare results
compare_results(result1, results_to_compare)
```

```
Results from implementation 1 and 2 are identical.
Results from implementation 1 and 3 are identical.
Results from implementation 1 and 4 are identical.
```

```
Unit: milliseconds
       expr      min       lq     mean   median       uq      max neval
      sqldf 667.0076 737.9661 756.2151 748.4892 751.5169 970.2065    10
       base 309.7957 381.8065 415.2128 415.7762 458.3992 523.9189    10
      dplyr  89.8477  97.1309 129.0201 107.8328 168.4499 218.0121    10
 data.table  36.7423  63.9529 105.4531  70.6276 149.2375 235.2563    10
```

## Zadanie 2

### Komenda SQL
```
SELECT Posts.Title, RelatedTab.NumLinks FROM
        (
            SELECT RelatedPostId AS PostId, COUNT(*) AS NumLinks FROM PostLinks
            GROUP BY RelatedPostId
        ) AS RelatedTab
        JOIN Posts ON RelatedTab.PostId=Posts.Id WHERE Posts.PostTypeId=1
        ORDER BY NumLinks DESC
```

Komenda zwraca tytuł postów oraz liczbę powiązanych linków dla każdego posta typu 1. Wyniki są posortowane malejąco względem liczby linków.

### Wyniki

```
# Task 2

result1 <- sqldf_2(Posts, PostLinks)
result2 <- base_2(Posts, PostLinks)
result3 <- dplyr_2(Posts, PostLinks)
result4 <- data.table_2(PostsDT, PostLinksDT)

results_to_compare <- list(result2, result3, result4)
```

```
Results from implementation 1 and 2 are identical.
Results from implementation 1 and 3 are identical.
Results from implementation 1 and 4 are identical.
```

```
Unit: milliseconds
       expr      min       lq      mean   median       uq      max neval
      sqldf 509.0512 515.2665 556.74321 555.7006 578.4629 619.4166    10
       base  72.0684  77.5689  90.51099  86.1860  97.3742 137.4174    10
      dplyr  79.8481  82.7960 127.18149 128.0557 150.6801 199.6282    10
 data.table  30.7858  34.2231  35.98279  35.6666  38.3842  39.8751    10
```

## Zadanie 3
### Komenda SQL
```
SELECT Title, CommentCount, ViewCount, CommentsTotalScore, DisplayName, Reputation, Location
        FROM (
          SELECT Posts.OwnerUserId, Posts.Title, Posts.CommentCount, Posts.ViewCount,
          CmtTotScr.CommentsTotalScore FROM (
            SELECT PostId, SUM(Score) AS CommentsTotalScore FROM Comments
            GROUP BY PostId
          ) AS CmtTotScr
          JOIN Posts ON Posts.Id = CmtTotScr.PostId WHERE Posts.PostTypeId=1
        ) AS PostsBestComments
        JOIN Users ON PostsBestComments.OwnerUserId = Users.Id ORDER BY CommentsTotalScore DESC
        LIMIT 10
```
Komenda zwraca tytuł postów, liczbę komentarzy, liczbę wyświetleń, łączny wynik komentarzy, nazwę użytkownika, reputację i lokalizację dla dziesięciu postów typu 1 z największą łączną oceną komentarzy.

### Wyniki
```
# Task 3

result1 <- sqldf_3(Comments, Posts, Users)
result2 <- base_3(Comments, Posts, Users)
result3 <- dplyr_3(Comments, Posts, Users)
result4 <- data.table_3(CommentsDT, PostsDT, UsersDT)

results_to_compare <- list(result2, result3, result4)
```

```
Results from implementation 1 and 2 are identical.
Results from implementation 1 and 3 are identical.
Results from implementation 1 and 4 are identical.
```

```
Unit: milliseconds
       expr       min        lq       mean     median        uq       max neval
      sqldf  902.2246  921.6814 1007.69797  993.62665 1069.3373 1183.8848    10
       base 1108.5748 1135.4902 1205.80720 1173.71170 1269.4005 1398.3254    10
      dplyr  289.5312  367.3183  395.24733  378.18965  397.4756  638.4443    10
 data.table   65.0138   67.1551   85.30105   73.14255   75.6635  206.6073    10
```

## Zadanie 4

### Komenda SQL
```
SELECT DisplayName, QuestionsNumber, AnswersNumber, Location, Reputation, UpVotes, DownVotes
            FROM (
              SELECT *
              FROM (
                SELECT COUNT(*) as AnswersNumber, OwnerUserId FROM Posts
                WHERE PostTypeId = 2
                GROUP BY OwnerUserId
              ) AS Answers JOIN
              (
                SELECT COUNT(*) as QuestionsNumber, OwnerUserId FROM Posts
                WHERE PostTypeId = 1
                GROUP BY OwnerUserId
              ) AS Questions
              ON Answers.OwnerUserId = Questions.OwnerUserId WHERE AnswersNumber > QuestionsNumber
              ORDER BY AnswersNumber DESC
              LIMIT 5
              ) AS PostsCounts
            JOIN Users
            ON PostsCounts.OwnerUserId = Users.Id
```
Komenda zwraca nazwę użytkownika, liczbę pytań, liczbę odpowiedzi, lokalizację, reputację, liczbę pozytywnych głosów oraz liczbę negatywnych głosów dla pięciu użytkowników, u któych liczba udzielonych odpowiedzi była większa niż liczba zadanych przez nich pytań.

### Wyniki
```
# Task 4

result1 <- sqldf_4(Posts, Users)
result2 <- base_4(Posts, Users)
result3 <- dplyr_4(Posts, Users)
result4 <- data.table_4(PostsDT, UsersDT)

results_to_compare <- list(result2, result3, result4)
```

```
Results from implementation 1 and 2 are identical.
Results from implementation 1 and 3 are identical.
Results from implementation 1 and 4 are identical.
```

```
Unit: milliseconds
       expr      min       lq      mean   median       uq      max neval
      sqldf 581.1668 589.1523 608.51763 603.4115 623.2019 676.3318    10
       base 579.0884 628.2530 663.79099 660.0151 684.5555 792.6553    10
      dplyr 274.4313 304.1839 379.27892 368.6452 408.0360 599.4149    10
 data.table  22.8056  24.7187  28.50045  25.5403  29.7175  40.5819    10
```

## Zadanie 5

### Komenda SQL

```
SELECT
        Users.AccountId,
        Users.DisplayName,
        Users.Location,
        AVG(PostAuth.AnswersCount) as AverageAnswersCount
        FROM
        (
          SELECT
          AnsCount.AnswersCount, Posts.Id, Posts.OwnerUserId
          FROM (
            SELECT Posts.ParentId, COUNT(*) AS AnswersCount FROM Posts
            WHERE Posts.PostTypeId = 2
            GROUP BY Posts.ParentId
          ) AS AnsCount
          JOIN Posts ON Posts.Id = AnsCount.ParentId
        ) AS PostAuth
        JOIN Users ON Users.AccountId=PostAuth.OwnerUserId GROUP BY OwnerUserId
        ORDER BY AverageAnswersCount DESC
        LIMIT 10
```

Komenda zwraca identyfikator konta użytkownika, nazwę użytkownika, lokalizację oraz średnią liczbę odpowiedzi na pytania dla dziesięciu użytkowników z najwyższą średnią liczbą odpowiedzi na pytania.

### Wyniki

```
# Task 5

result1 <- sqldf_5(Posts, Users)
result2 <- base_5(Posts, Users)
result3 <- dplyr_5(Posts, Users)
result4 <- data.table_5(PostsDT, UsersDT)

results_to_compare <- list(result2, result3, result4)
```

```
Results from implementation 1 and 2 are identical.
Results from implementation 1 and 3 are identical.
Results from implementation 1 and 4 are identical.
```

```
Unit: milliseconds
       expr      min       lq       mean    median        uq       max neval
      sqldf 659.7617 780.1131 1209.66291 1128.9771 1592.0789 2092.5718    10
       base 510.9984 701.7544 1077.77595 1141.3173 1172.3025 1707.8293    10
      dplyr 518.2148 696.2737  787.22255  824.3541  840.6739  998.3864    10
 data.table  52.6656  70.3130   83.86051   78.1103   91.5607  138.4527    10
```

## Wnioski
Niezależnie od rodzaju zapytania, metoda wykorzystująca ``data.table`` sprawdziła się zdecydowanie najlepiej. Jej wydajność jest znacząco (nawet 10-krotnie) wyższa niż w przypadku pozostałych metod. Na wyróżnienie zasługuje również implementacja korzystająca z biblioteki ``dplyr``. W każdym z zadań osiągnęła czasy lepsze niż ``sqldf`` oraz implementacja przy pomocy metod bazowych. Dla większości problemów ``sqldf`` cechował się najgorszą wydajnością.