from solutions import *

import pandas as pd
import numpy as np
import os, os.path
import sqlite3

Posts = pd.read_csv("travel_stackexchange_com/Posts.csv.gz", compression = 'gzip')
Comments = pd.read_csv("travel_stackexchange_com/Comments.csv.gz", compression = 'gzip')
PostLinks = pd.read_csv("travel_stackexchange_com/PostLinks.csv.gz", compression = 'gzip')
Users = pd.read_csv("travel_stackexchange_com/Users.csv.gz", compression = 'gzip')


db = os.path.join('Assigment2.db')
if os.path.isfile(db):
    os.remove(db)
    
db_connection = sqlite3.connect(db)

Posts.to_sql("Posts", db_connection)
Comments.to_sql("Comments", db_connection)
PostLinks.to_sql("PostLinks", db_connection)
Users.to_sql("Users", db_connection)

result1 = pd.read_sql_query("""
    SELECT Location, COUNT(*) AS Count
    FROM (
        SELECT Posts.OwnerUserId, Users.Id, Users.Location 
        FROM Users
        JOIN Posts ON Users.Id = Posts.OwnerUserId
    )
    WHERE Location NOT IN ('') 
    GROUP BY Location
    ORDER BY Count DESC
    LIMIT 10
""", db_connection)

result2 = pd.read_sql_query("""
    SELECT Posts.Title, RelatedTab.NumLinks 
    FROM (
        SELECT RelatedPostId AS PostId, COUNT(*) AS NumLinks 
        FROM PostLinks
        GROUP BY RelatedPostId
    ) AS RelatedTab
    JOIN Posts ON RelatedTab.PostId=Posts.Id 
    WHERE Posts.PostTypeId=1
    ORDER BY NumLinks DESC
""", db_connection)

result3 = pd.read_sql_query("""
    SELECT Title, CommentCount, ViewCount, CommentsTotalScore, DisplayName, Reputation, Location
    FROM (
        SELECT Posts.OwnerUserId, Posts.Title, Posts.CommentCount, Posts.ViewCount,
        CmtTotScr.CommentsTotalScore 
        FROM (
            SELECT PostId, SUM(Score) AS CommentsTotalScore 
            FROM Comments
            GROUP BY PostId
        ) AS CmtTotScr
        JOIN Posts ON Posts.Id = CmtTotScr.PostId 
        WHERE Posts.PostTypeId=1
    ) AS PostsBestComments
    JOIN Users ON PostsBestComments.OwnerUserId = Users.Id 
    ORDER BY CommentsTotalScore DESC
    LIMIT 10
""", db_connection)

result4 = pd.read_sql_query("""
    SELECT DisplayName, QuestionsNumber, AnswersNumber, Location, Reputation, UpVotes, DownVotes
    FROM (
        SELECT *
        FROM (
            SELECT COUNT(*) as AnswersNumber, OwnerUserId 
            FROM Posts
            WHERE PostTypeId = 2
            GROUP BY OwnerUserId
        ) AS Answers JOIN
        (
            SELECT COUNT(*) as QuestionsNumber, OwnerUserId 
            FROM Posts
            WHERE PostTypeId = 1
            GROUP BY OwnerUserId
        ) AS Questions
        ON Answers.OwnerUserId = Questions.OwnerUserId 
        WHERE AnswersNumber > QuestionsNumber
        ORDER BY AnswersNumber DESC
        LIMIT 5
    ) AS PostsCounts
    JOIN Users ON PostsCounts.OwnerUserId = Users.Id
""", db_connection)

result5 = pd.read_sql_query("""
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
            SELECT Posts.ParentId, COUNT(*) AS AnswersCount 
            FROM Posts
            WHERE Posts.PostTypeId = 2
            GROUP BY Posts.ParentId
        ) AS AnsCount
        JOIN Posts ON Posts.Id = AnsCount.ParentId
    ) AS PostAuth
    JOIN Users ON Users.AccountId=PostAuth.OwnerUserId 
    GROUP BY OwnerUserId
    ORDER BY AverageAnswersCount DESC
    LIMIT 10
""", db_connection)