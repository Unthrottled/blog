---
layout: post
title: Java Objects to and from a File
headerImage: beans/beans-to-file.png
---

There will come a time when the need arises to have Java objects persist without the use of a relational or NoSQL database.
Simply put, reading and writing an object to a local file.
Let us explore how this can be accomplished and find some reason this is helpful in the first place.

Here is the how.s


Before delving into the why of writing objects to a file, it would be nice to mention some more concrete persistence APIs.

As relation databases go there are many to choose from, here is a small sample:

- [MySQL](https://www.mysql.com/)
- [PostgreSQL](https://www.postgresql.org/about/)
- [SQL Server](https://www.microsoft.com/en-us/sql-server/sql-server-2016)

On the other hand, there are also quite a few NoSQL databases to choose from as well.
The primary difference between SQL and NoSQL databases is that there is no relational setup between objects stored in NoSQL databases.
Items in a NoSQL database are stored as Key-Value pairs. 
Here is a small subset of NoSQL databases:

- [MongoDB](https://www.mongodb.com/what-is-mongodb)
- [Redis](https://redis.io/topics/introduction)
- [Cassandra](http://cassandra.apache.org/)
