---
layout: docs-learn-by-example
title: Writing the initial program
permalink: /learn-by-example/1-writing-the-initial-program/
---

# A complete program by example

This section provides a list of sequential posts on **how to write a complete program from scratch using Arrow**.

We will cover a set of usual concepts like **asynchrony**, **concurrency**, **controlling effects**, **parallel and sequential computation**, **thread switching**, **domain data and error modeling**, **resource safety**, **dependency injection**, **testing** and much more.

## 1. Writing the initial program

Let's imagine the backend of a rock band social network 🎸🤘 and a `UserDatabase` for it like the following one:

```kotlin
interface UserDatabase {
  fun createUser(name: String): UserId
  fun findUser(userId: UserId): User?
}
```

If our backend was a **Resful API**, we would expect it to offer an endpoint to create new users that would rely on this database.

If we wanted to provide a somehow controlled implementation for this database contract that did not rely on third parties, one option could be to provide an in-memory implementation for it:

```kotlin
object InMemoryUserDatabase : UserDatabase {
  private var users: List<User> = emptyList()

  override fun createUser(name: String): UserId {
    val userId = generateId(name)
    this.users = users + listOf(User(userId, name))
    return userId
  }

  override fun findUser(userId: UserId): User? =
    users.find { it.id == userId }

  private fun generateId(name: String): UserId = UserId("$name${UUID.randomUUID()}")
}
```

This implementation for the `UserDatabase` contains a mutable state that's mutated by the `createUser` function. It also provides functions to `createUser` and `findUser` in the database.

Finally, it provides a function to generate a `UserId` given a `name`.

So we could have a program to rely on this database to create and find users:

```kotlin
fun main() {
  val userId = InMemoryUserDatabase.createUser("SomeUserName")
  println(userId)
  val user = InMemoryUserDatabase.findUser(userId)
  println(user)
}
``` 