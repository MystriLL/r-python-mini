# Load functions from file
source("Jakub_Borek_PD1.r")

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

# Running functions
library(microbenchmark)

#Set number of repetitions for benchmark functions
repetitionsNumber <- 10

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

# Task 1

result1 <- sqldf_1(Posts, Users)
result2 <- base_1(Posts, Users)
result3 <- dplyr_1(Posts, Users)
result4 <- data.table_1(PostsDT, UsersDT)

results_to_compare <- list(result2, result3, result4)

# Compare results
compare_results(result1, results_to_compare)


# Call benchmark function
executionTimes <- microbenchmark(
  sqldf = sqldf_1(Posts, Users),
  base = base_1(Posts, Users),
  dplyr = dplyr_1(Posts, Users),
  data.table = data.table_1(PostsDT, UsersDT),
  times = repetitionsNumber
)

# Print execution times
print(executionTimes)

# Task 2

result1 <- sqldf_2(Posts, PostLinks)
result2 <- base_2(Posts, PostLinks)
result3 <- dplyr_2(Posts, PostLinks)
result4 <- data.table_2(PostsDT, PostLinksDT)

results_to_compare <- list(result2, result3, result4)

# Compare results
compare_results(result1, results_to_compare)

# Call benchmark function
executionTimes <- microbenchmark(
  sqldf = sqldf_2(Posts, PostLinks),
  base = base_2(Posts, PostLinks),
  dplyr = dplyr_2(Posts, PostLinks),
  data.table = data.table_2(PostsDT, PostLinksDT),
  times = repetitionsNumber
)

# Print execution times
print(executionTimes)

# Task 3

result1 <- sqldf_3(Comments, Posts, Users)
result2 <- base_3(Comments, Posts, Users)
result3 <- dplyr_3(Comments, Posts, Users)
result4 <- data.table_3(CommentsDT, PostsDT, UsersDT)

results_to_compare <- list(result2, result3, result4)

# Compare results
compare_results(result1, results_to_compare)


# Call benchmark function
executionTimes <- microbenchmark(
  sqldf = sqldf_3(Comments, Posts, Users),
  base = base_3(Comments, Posts, Users),
  dplyr = dplyr_3(Comments, Posts, Users),
  data.table = data.table_3(CommentsDT, PostsDT, UsersDT),
  times = repetitionsNumber
)

# Print execution times
print(executionTimes)

# Task 4

result1 <- sqldf_4(Posts, Users)
result2 <- base_4(Posts, Users)
result3 <- dplyr_4(Posts, Users)
result4 <- data.table_4(PostsDT, UsersDT)

results_to_compare <- list(result2, result3, result4)

# Compare results
compare_results(result1, results_to_compare)


# Call benchmark function
executionTimes <- microbenchmark(
  sqldf = sqldf_4(Posts, Users),
  base = base_4(Posts, Users),
  dplyr = dplyr_4(Posts, Users),
  data.table = data.table_4(PostsDT, UsersDT),
  times = repetitionsNumber
)

# Print execution times
print(executionTimes)

# Task 5

result1 <- sqldf_5(Posts, Users)
result2 <- base_5(Posts, Users)
result3 <- dplyr_5(Posts, Users)
result4 <- data.table_5(PostsDT, UsersDT)

results_to_compare <- list(result2, result3, result4)

# Compare results
compare_results(result1, results_to_compare)


# Call benchmark function
executionTimes <- microbenchmark(
  sqldf = sqldf_5(Posts, Users),
  base = base_5(Posts, Users),
  dplyr = dplyr_5(Posts, Users),
  data.table = data.table_5(PostsDT, UsersDT),
  times = repetitionsNumber
)

# Print execution times
print(executionTimes)