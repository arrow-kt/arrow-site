---
layout: docs-learn-by-example
title: Writing the initial program
permalink: /learn-by-example/1-writing-the-initial-program/
---

# A complete program by example

This section provides a list of sequential posts on **how to write a complete program from scratch using Arrow**.

We will cover a set of usual concepts like asynchrony, concurrency, controlling effects, parallel and sequential computation, thread switching, domain data and error modeling, resource safety, dependency injection, testing and much more.

## 1. Writing the initial program

Along this series of posts we will gradually build a backend for a Rock Band social network 🎸🤘

<img src="/img/learn-by-example/band_playing.gif" alt="Rock band playing" width="800"/>

Let's start by writing an early simple version of our program to start from there. Let's image a `UserDatabase` for the social network so new users can register:

```kotlin
interface UserDatabase {
  fun createUser(name: String): UserId
  fun findUser(userId: UserId): User?
}
```

If our backend was a **Resful API**, we would expect it to offer an endpoint to create new users that would rely on this database.

If we wanted to provide a somehow controlled implementation for this database contract that **did not rely on third parties**, one option could be to provide an in-memory implementation for it:

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

  private fun generateId(name: String): UserId = 
    UserId("$name${UUID.randomUUID()}")
}
```

This implementation for the `UserDatabase` contains a mutable state that is mutated by the `createUser` function. It provides functions to `createUser` and `findUser` in the database. The `createUser` function relies on a private utility function to generate a unique `UserId` from a given `name`.

So we could have a program to rely on this database to create and find users. Feel free to click on the ▶️ icon to run it and check the result.

```kotlin:ank:playground
import java.util.*

class UserId(val id: String)
data class User(val id: UserId, val name: String)

interface UserDatabase {
  fun createUser(name: String): UserId
  fun findUser(userId: UserId): User?
}

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

//sampleStart
fun main() {
  val userId = InMemoryUserDatabase.createUser("SomeUserName")
  println(userId)
  val user = InMemoryUserDatabase.findUser(userId)
  println(user)
}
//sampleEnd
``` 

As you can see, we could register and find a user in the database. But this program has a few issues.

We are not handling any potential errors, because we assumed it's an in memory implementation that will not fail. But what If it was a real database? **It could potentially throw, making our function calls non deterministic**. Also, what happens when the user we are trying to find is not there? If our backend was a Resful API, we would probably want to handle it by returning a 404 not found response to the client. 

Ultimately we need to account for errors in our domain and handle them properly to make our program resilient, the same way a rock band would need to keep playing if something unexpected happened.

<img src="/img/learn-by-example/band_error_keep_playing.gif" alt="Rock band playing" width="800"/>

On top of that, it's a database, so by definition it represents **a mutable state**. Even if our implementation is in-memory, we are not reflecting this mutability with the public function types in the contract.

Every time we create a user, the database internal state will change. If we keep in mind that the `createUser` function could be **called from multiple places** in our program, this encoding would make it hard for us the developers to track down what the state of our program is at any point in time.

Overall, we are introducing ambiguity in our program provoked by a **"side effect"**, which makes the program non deterministic. That blocks our ability to apply *local reasoning* over pieces of logic relying on it. And if we can't reason about those atomic pieces, we will not be able to reason over bigger logics relying on them, and ultimately over our program as a whole.

Finally, we have a second side effect imposed by the `generateId()` function. That function returns a different value every time we call it, so it is impure by definition.

We will address all the described issues in the lessons to come, starting by handling errors. Have a look to the next post in the series: [Modeling data and errors](/learn-by-example/2-modeling-data-and-errors/).
 