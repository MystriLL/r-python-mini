### Przetwarzanie danych w językach R i Python 2024L
### Praca domowa nr. 1 / Homework Assignment no. 1
###
### WAŻNE
### Ten plik powinien zawierać tylko rozwiązania zadań w postaci
### definicji funkcji, załączenia niezbędnych bibliotek
### i komentarzy do kodu.
###
### Raport powinien zawierać:
### * source() tego pliku,
### * odczytanie danych,
### * dołączenie bibliotek,
### * pomiary czasu wykonania (z mikrobenchmarkiem),
### * porównanie równoważności wyników,
### * interpretację zapytań.

# -----------------------------------------------------------------------------#
# Task 1
# -----------------------------------------------------------------------------#

library(dplyr)


sqldf_1 <- function(Posts, Users){
  query <- "
        SELECT Location, COUNT(*) AS Count FROM (
            SELECT Posts.OwnerUserId, Users.Id, Users.Location FROM Users
            JOIN Posts ON Users.Id = Posts.OwnerUserId
        )
        WHERE Location NOT IN ('') GROUP BY Location
        ORDER BY Count DESC
        LIMIT 10
        "
  
  # Execute SQL query 
  result <- sqldf::sqldf(query)
}

base_1 <- function(Posts, Users) {
  # Merge Posts and Users data
  merged_data <- merge(Posts, Users, by.x = "OwnerUserId", by.y = "Id")
  
  # Filter out rows with empty Location field
  merged_data <- merged_data[merged_data$Location != "", ]
  
  # Count occurrences of each Location
  location_counts <- table(merged_data$Location)
  
  # Sort the locations by count in descending order
  sorted_locations <- sort(location_counts, decreasing = TRUE)
  
  # Select top 10 locations
  top_10_locations <- head(sorted_locations, 10)
  
  # Convert to data frame with location and count
  result <- data.frame(Location = names(top_10_locations), Count = as.vector(top_10_locations))
}

dplyr_1 <- function(Posts, Users) {
  
  # Join tables, filter out empty locations and count occurences. Return top10 
  result <- Users %>%
    inner_join(Posts, by = c("Id" = "OwnerUserId")) %>%
    filter(Location != "") %>%
    group_by(Location) %>%
    summarise(Count = n()) %>%
    arrange(desc(Count)) %>%
    slice_head(n = 10)
}

data.table_1 <- function(Posts, Users){
  merged_data <- merge(Users, Posts, by.x = "Id", by.y = "OwnerUserId")
  
  # Convert data to data.table
  merged_data <- as.data.table(merged_data)
  
  # Filter out empty locations, count occurences of each location and return top10
  result <- merged_data[Location != "", .(Count = .N), by = Location][order(-Count)][1:10]
  }

# -----------------------------------------------------------------------------#
# Task 2
# -----------------------------------------------------------------------------#

sqldf_2 <- function(Posts, PostLinks){
  query <- "
        SELECT Posts.Title, RelatedTab.NumLinks FROM
        (
            SELECT RelatedPostId AS PostId, COUNT(*) AS NumLinks FROM PostLinks
            GROUP BY RelatedPostId
        ) AS RelatedTab
        JOIN Posts ON RelatedTab.PostId=Posts.Id WHERE Posts.PostTypeId=1
        ORDER BY NumLinks DESC
        "
  
  # Execute SQL query
  result <- sqldf::sqldf(query)
}

base_2 <- function(Posts, PostLinks){
  
  links_count <- as.data.frame(table(PostLinks$RelatedPostId))
  
  names(links_count) <- c("PostId", "NumLinks")
  
  # Filter posts
  filtered_posts <- subset(Posts, PostTypeId == 1)
  
  # Join posts and links count
  merged_data <- merge(filtered_posts, links_count, by.x = "Id", by.y = "PostId")
  
  # Order by count in descending order
  ordered_data <- merged_data[order(merged_data$NumLinks, decreasing = TRUE), ]
  
  # Select required columns
  result <- ordered_data[, c("Title", "NumLinks")]
}

dplyr_2 <- function(Posts, PostLinks){
  
  
  result <- PostLinks %>%
    group_by(RelatedPostId) %>%
    summarise(NumLinks = n()) %>%
    rename(PostId = RelatedPostId) %>%
    inner_join(Posts, by = c("PostId" = "Id")) %>%
    filter(PostTypeId == 1) %>%
    select(Title, NumLinks) %>%
    arrange(desc(NumLinks))
}

data.table_2 <- function(Posts, PostLinks){
  
  # Calculate the number of links for each RelatedPostId
  related_links <- PostLinks[, .N, by = RelatedPostId][, .(PostId = RelatedPostId, NumLinks = N)]
  
  # Filter posts with Id == 1
  filtered_posts <- Posts[PostTypeId == 1]
  
  # Join Posts and related_counts
  merged_data <- merge(filtered_posts, related_links, by.x = "Id", by.y = "PostId")
  
  # Order by NumLinks descending
  setorder(merged_data, -NumLinks)
  
  # Select relevant columns
  result <- merged_data[, .(Title, NumLinks)]
  
  result$Title <- gsub('""', '"', result$Title)
  
  return(result)
}

# -----------------------------------------------------------------------------#
# Task 3
# -----------------------------------------------------------------------------#

sqldf_3 <- function(Comments, Posts, Users){

  query <- "
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
        "
  
  # Execute SQL query
  result <- sqldf::sqldf(query)
}

base_3 <- function(Comments, Posts, Users){
  
  # Calculate total score of comments for each post
  comments_score <- aggregate(Score ~ PostId, data = Comments, sum)
  colnames(comments_score) <- c("PostId", "CommentsTotalScore")
  
  # Filter posts of type 1 and join with scores
  posts_with_scores <- merge(subset(Posts, PostTypeId == 1), comments_score, by.x="Id", by.y="PostId")
  
  # Join with Users table
  merged_data <- merge(posts_with_scores, Users, by.x="OwnerUserId", by.y="Id")
  
  # Select relevant columns
  merged_data <- merged_data[, c("Title", "CommentCount", "ViewCount", "CommentsTotalScore", "DisplayName", "Reputation", "Location")]
  
  # Order by total score and limit to 10 rows
  ordered_data <- merged_data[order(merged_data$CommentsTotalScore, decreasing=TRUE), ]
  result <- head(ordered_data, 10)
}

dplyr_3 <- function(Comments, Posts, Users){
  
  result <- Comments %>%
    group_by(PostId) %>%
    summarise(CommentsTotalScore = sum(Score)) %>%
    inner_join(Posts %>%
                 filter(PostTypeId == 1), by = c("PostId" = "Id")) %>%
    inner_join(Users, by = c("OwnerUserId" = "Id")) %>%
    select(Title, CommentCount, ViewCount, CommentsTotalScore, DisplayName, Reputation, Location) %>%
    arrange(desc(CommentsTotalScore)) %>%
    slice_head(n = 10)
}

data.table_3 <- function(Comments, Posts, Users){
  
  # Calculate total score for each post
  comments_total_score <- Comments[, .(CommentsTotalScore = sum(Score)), by = .(PostId)]
  
  # Join Posts with scores
  posts_with_comments <- merge(Posts[PostTypeId == 1], comments_total_score, by.x = "Id", by.y = "PostId", all.x = TRUE)
  
  # Join with Users
  posts_users <- merge(posts_with_comments, Users, by.x = "OwnerUserId", by.y = "Id")
  
  # Select relevant columns
  result <- posts_users[, .(Title, CommentCount, ViewCount, CommentsTotalScore, DisplayName, Reputation, Location)]
  
  # Order by total score and limit to 10 rows
  result <- result[order(-CommentsTotalScore)][1:10]
}

# -----------------------------------------------------------------------------#
# Task 4
# -----------------------------------------------------------------------------#

sqldf_4 <- function(Posts, Users){
  
  query <- "
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
        "
  
  # Execute SQL query
  result <- sqldf::sqldf(query)
}

base_4 <- function(Posts, Users){
  
  # Calculate the number of answers per user
  answers <- aggregate(PostTypeId ~ OwnerUserId, data = Posts[Posts$PostTypeId == 2, ], FUN = length)
  
  # Calculate the number of questions per user
  questions <- aggregate(PostTypeId ~ OwnerUserId, data = Posts[Posts$PostTypeId == 1, ], FUN = length)
  
  # Merge answers and questions
  questions_with_answers <- merge(answers, questions, by = "OwnerUserId", all = TRUE, suffixes = c("_Answers", "_Questions"))
  
  # Filter users where AnswersNumber > QuestionsNumber
  filtered_data <- questions_with_answers[questions_with_answers$PostTypeId_Answers > questions_with_answers$PostTypeId_Questions, ]
  
  # Merge with Users data frame to get additional user information
  merged_data <- merge(filtered_data, Users, by.x = "OwnerUserId", by.y = "Id")[, c("DisplayName", "PostTypeId_Questions", "PostTypeId_Answers", "Location", "Reputation", "UpVotes", "DownVotes")]
  
  # Select top 5 users based on AnswersNumber
  result <- merged_data[order(merged_data$PostTypeId_Answers, decreasing = TRUE), ][1:5, ]
}

dplyr_4 <- function(Posts, Users){
  
  result <- Posts %>%
    filter(PostTypeId == 2) %>%
    group_by(OwnerUserId) %>%
    summarise(AnswersNumber = n()) %>%
    inner_join(
      Posts %>%
        filter(PostTypeId == 1) %>%
        group_by(OwnerUserId) %>%
        summarise(QuestionsNumber = n()),
      by = "OwnerUserId"
    ) %>%
    filter(AnswersNumber > QuestionsNumber) %>%
    arrange(desc(AnswersNumber)) %>%
    slice(1:6) %>%
    inner_join(
      Users,
      by = c("OwnerUserId" = "Id")
    ) %>%
    select(DisplayName, QuestionsNumber, AnswersNumber, Location, Reputation, UpVotes, DownVotes)
}

data.table_4 <- function(Posts, Users){
  
  # Calculate number of answers per user
  answers <- Posts[PostTypeId == 2, .(AnswersNumber = .N), by = OwnerUserId]
  
  # Calculate number of questions per user
  questions <- Posts[PostTypeId == 1, .(QuestionsNumber = .N), by = OwnerUserId]
  
  # Join answers and questions tables
  joined_data <- merge(answers, questions, by = "OwnerUserId")
  
  # Filter users where AnswersNumber > QuestionsNumber
  filtered_data <- joined_data[AnswersNumber > QuestionsNumber]
  
  # Order by AnswersNumber and limit to top 5
  top_users <- filtered_data[order(-AnswersNumber)][1:6]
  
  # Join with Users table ordered by reputation
  result <- merge(top_users, Users, by.x = "OwnerUserId", by.y = "Id")[order(-Reputation)]
  
  # Select relevant columns
  result = result[, .(DisplayName, QuestionsNumber, AnswersNumber, Location, Reputation, UpVotes, DownVotes)]
}

# -----------------------------------------------------------------------------#
# Task 5
# -----------------------------------------------------------------------------#

sqldf_5 <- function(Posts, Users){

  query <- "
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
        "
  
  # Execute SQL query
  result <- sqldf::sqldf(query)
}

base_5 <- function(Posts, Users){
  
  # Filter posts with TypeId = 2
  filtered_posts <- Posts[Posts$PostTypeId == 2, ]
  
  # Aggregate answer count by id of parent
  answers_count <- aggregate(Id ~ ParentId, data = filtered_posts, FUN = length)
  colnames(answers_count) <- c("ParentId", "AnswersCount")
  
  # Merge answers count with posts
  posts_answers <- merge(answers_count, Posts, by.x = "ParentId", by.y = "Id")
  posts_answers <- posts_answers[c("AnswersCount", "ParentId", "OwnerUserId")]
  colnames(posts_answers) <- c("AnswersCount", "Id", "OwnerUserId")
  
  # Merge users
  merged_data <- merge(posts_answers, Users, by.x = "OwnerUserId", by.y = "AccountId")
  
  # Aggregate answers by user and choose relevant columns
  result <- aggregate(AnswersCount ~ OwnerUserId + DisplayName + Location, data = merged_data, FUN = mean)
  colnames(result) <- c("AccountId", "DisplayName", "Location", "AverageAnswersCount")
  
  # Order rows by AverageAnswersCount and return top10
  result <- result[order(result$AverageAnswersCount, result$AccountId, decreasing = TRUE), ]
  result <- head(result, 10)
}

dplyr_5 <- function(Posts, Users){

  result <- Posts %>%
    filter(PostTypeId == 2) %>%
    group_by(ParentId) %>%
    summarise(AnswersCount = n()) %>%
    inner_join(Posts, by = c("ParentId" = "Id")) %>%
    inner_join(Users, by = c("OwnerUserId" = "AccountId"), relationship = "many-to-many") %>%
    group_by(OwnerUserId, DisplayName, Location) %>%
    summarise(AverageAnswersCount = mean(AnswersCount)) %>%
    arrange(desc(AverageAnswersCount), desc(OwnerUserId)) %>%
    head(10)
}

data.table_5 <- function(Posts, Users){
  
  # Count answers for each post
  answer_count <- Posts[PostTypeId == 2, .(AnswersCount = .N), by = ParentId]
  
  # Join with posts
  posts_answers <- merge(answer_count, Posts, by.x = "ParentId", by.y = "Id")[,
                                                                     .(AnswersCount, Id = ParentId, OwnerUserId)]
  # Merge posts and users
  merged_data <- merge(posts_answers, Users, by.x = "OwnerUserId", by.y = "AccountId")
  
  # Calculate the mean answer count and group by relevant columns
  average_answers <- merged_data[, .(AverageAnswersCount = mean(AnswersCount)), by = .(OwnerUserId, DisplayName, Location)]
  
  # Select relevant columns
  result <- average_answers[, .(AccountId = OwnerUserId, DisplayName, Location, AverageAnswersCount)]
  
  # Order the data by average answers count and take top10
  result <- result[order(-AverageAnswersCount, -AccountId)][1:10]
}

