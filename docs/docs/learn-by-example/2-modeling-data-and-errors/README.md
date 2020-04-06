---
layout: docs-learn-by-example
title: Modeling data and errors
permalink: /learn-by-example/2-modeling-data-and-errors/
---

# A complete program by example

In [the previous post in the series](/learn-by-example/1-writing-the-initial-program/) we wrote an initial program to create and find users for a Rock Band social network backend. We found out that our approach had some inherent issues since we were not handling errors or keeping side effects under control. We will focus on error modeling and handling first, along with data modeling. We will dive into how to control side effects in further lessons.

## 2. Modeling data and errors

One of the most obvious unhandled errors in our program was the fact that a user could not be found in the database. Let's say we wanted to react differently when the user is not there, and log an error in that case. Probably the most obvious approach would be to use [Kotlin nullable types](https://kotlinlang.org/docs/reference/null-safety.html).

This was our contract and in memory implementation of the database.

```kotlin
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

  private fun generateId(name: String): UserId = 
    UserId("$name${UUID.randomUUID()}")
}
```

We already had our `User` flagged as nullable when returned by the `findUser` function, so we could write our program like this:

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

  private fun generateId(name: String): UserId = 
    UserId("$name${UUID.randomUUID()}")
}

fun main() {
  //sampleStart
  val userId = InMemoryUserDatabase.createUser("SomeUserName")
  println("UserId: $userId")
  val user = InMemoryUserDatabase.findUser(userId)
  println(user ?: "User $userId not found!")
  //sampleEnd
}
```

With this, we would be treating both cases: present (value) vs absent (null). 

If we wanted to lift that concern into a type to enable other behaviors over it like `fold`, `map`, `flatMap` and so on, we could move that to be an [`Option<A>`](https://arrow-kt.io/docs/apidocs/arrow-core-data/arrow.core/-option/) instead:

```kotlin:ank:playground
import java.util.*
import arrow.core.*

class UserId(val id: String)
data class User(val id: UserId, val name: String)

//sampleStart
interface UserDatabase {
  fun createUser(name: String): UserId
  fun findUser(userId: UserId): Option<User>
}

object InMemoryUserDatabase : UserDatabase {
  private var users: List<User> = emptyList()

  override fun createUser(name: String): UserId {
    val userId = generateId(name)
    this.users = users + listOf(User(userId, name))
    return userId
  }

  override fun findUser(userId: UserId): Option<User> =
    users.find { it.id == userId }.toOption()

  private fun generateId(name: String): UserId = UserId("$name${UUID.randomUUID()}")
}

fun main() {
  val userId = InMemoryUserDatabase.createUser("SomeUserName")
  println(userId)
  val user = InMemoryUserDatabase.findUser(userId)
  println(
    user.fold(
      ifEmpty = { "User $userId not found!" },
      ifSome = { user.toString() }
    ))
}
//sampleEnd
``` 

`Option` is the Arrow data type to represent **presence vs absence of a value**. We moved the return type to be `Option<User>` for both the contract and the in memory implementation. We used the `toOption()` extension function over the nullable `find` call result, which creates a `Some(it)` in case the value is present, or `None` otherwise.

The fact that our return type is `Option<User>` now enforces us to handle both cases when we `fold` over it. You can run the previous snippet to check our program's result.

### The bias

Arrow data types are encoded with **a bias towards the happy case**. That means they are prepared to compose computations that work over the happy path, so we can build our program logic seamlessly assuming things will go alright, and then provide an error handling strategy as a single pluggable piece for the whole thing. This removes a lot of thinking overhead from our minds and makes programs highly composable.

In the case of `Option<A>`, it is biased towards the `Some` case, which represents its happy case. Thanks to this, we could also stack more computations on top of it using `flatMap` or `map` before folding to apply our side effects. Let's see an example of this. 

Let's say we also had a `BandService` to retrieve the list of bands followed by a given user. We could make our contract also return an `Option` since the provided `userId` could not be found, and provide a stubbed in-memory implementation like the following one.

```kotlin
interface BandService {
  fun getBandsFollowedByUser(userId: UserId): Option<List<Band>>
}

object InMemoryBandService : BandService {
  override fun getBandsFollowedByUser(userId: UserId): Option<List<Band>> =
    listOf(
      Band("Band 1", BandStyle.POP, listOf(
        BandMember("1", "Member 1", "Drums"),
        BandMember("2", "Member 2", "Microphone"),
        BandMember("3", "Member 3", "Guitar")
      )),
      Band("Band 2", BandStyle.POP, listOf(
        BandMember("4", "Member 4", "Drums"),
        BandMember("5", "Member 5", "Microphone"),
        BandMember("6", "Member 6", "Guitar"),
        BandMember("7", "Member 7", "Keyboard")
      ))
    ).some()
}
```

> We are using the `some()` extension function to lift the value into an `Option`, which is equivalent to `Some(value)`.

Let's update our program to stack another computation on top of our initial one so we can fetch the list of bands the found user follows, and do the logging afterwards.

```kotlin:ank:playground
import java.util.*
import arrow.core.*

class UserId(val id: String)
data class User(val id: UserId, val name: String)
data class BandMember(
  val id: String,
  val name: String,
  val instrument: String
)

enum class BandStyle {
  ROCK, POP, REGGAE, RAP, TRAP
}

data class Band(
  val name: String,
  val style: BandStyle,
  val members: List<BandMember>
)

interface UserDatabase {
  fun createUser(name: String): UserId
  fun findUser(userId: UserId): Option<User>
}

object InMemoryUserDatabase : UserDatabase {
  private var users: List<User> = emptyList()

  override fun createUser(name: String): UserId {
    val userId = generateId(name)
    this.users = users + listOf(User(userId, name))
    return userId
  }

  override fun findUser(userId: UserId): Option<User> =
    users.find { it.id == userId }.toOption()

  private fun generateId(name: String): UserId = UserId("$name${UUID.randomUUID()}")
}

interface BandService {
  fun getBandsFollowedByUser(userId: UserId): Option<List<Band>>
}

object InMemoryBandService : BandService {
  override fun getBandsFollowedByUser(userId: UserId): Option<List<Band>> =
    listOf(
      Band("Band 1", BandStyle.POP, listOf(
        BandMember("1", "Member 1", "Drums"),
        BandMember("2", "Member 2", "Microphone"),
        BandMember("3", "Member 3", "Guitar")
      )),
      Band("Band 2", BandStyle.POP, listOf(
        BandMember("4", "Member 4", "Drums"),
        BandMember("5", "Member 5", "Microphone"),
        BandMember("6", "Member 6", "Guitar"),
        BandMember("7", "Member 7", "Keyboard")
      ))
    ).some()
}

fun main() {
  //sampleStart
  val userId = InMemoryUserDatabase.createUser("SomeUserName")
  println("UserId: $userId")
  println(
    InMemoryUserDatabase.findUser(userId)
      .flatMap { InMemoryBandService.getBandsFollowedByUser(it.id) }
      .fold(
        ifEmpty = { "User $userId not found!" },
        ifSome = { bands -> bands.toString() }
      ))
  //sampleEnd
}
```

If we run the program we will find that it finds the user ➡️ fetches the followed bands ➡️ logs the list of bands ✅

That works because `Option` is biased towards the `Some` case, which is the happy path. That means computations like `flatMap` or `map` will just work **when the value is present**. But what happens for errors?

### Failing fast

For the error case, `Option` has **fail fast strategy**. This means in case it failed early and one of the computations returned `None`, the complete call chain would short-circuit the error and return `None`. Let's enforce an error in our initial call to see the result. We only need to remove the call to create the user, so the program can't find it:

```kotlin:ank:playground
import java.util.*
import arrow.core.*

class UserId(val id: String)
data class User(val id: UserId, val name: String)
data class BandMember(
  val id: String,
  val name: String,
  val instrument: String
)

enum class BandStyle {
  ROCK, POP, REGGAE, RAP, TRAP
}

data class Band(
  val name: String,
  val style: BandStyle,
  val members: List<BandMember>
)

interface UserDatabase {
  fun createUser(name: String): UserId
  fun findUser(userId: UserId): Option<User>
}

object InMemoryUserDatabase : UserDatabase {
  private var users: List<User> = emptyList()

  override fun createUser(name: String): UserId {
    val userId = generateId(name)
    this.users = users + listOf(User(userId, name))
    return userId
  }

  override fun findUser(userId: UserId): Option<User> =
    users.find { it.id == userId }.toOption()

  private fun generateId(name: String): UserId = UserId("$name${UUID.randomUUID()}")
}

interface BandService {
  fun getBandsFollowedByUser(userId: UserId): Option<List<Band>>
}

object InMemoryBandService : BandService {
  override fun getBandsFollowedByUser(userId: UserId): Option<List<Band>> =
    listOf(
      Band("Band 1", BandStyle.POP, listOf(
        BandMember("1", "Member 1", "Drums"),
        BandMember("2", "Member 2", "Microphone"),
        BandMember("3", "Member 3", "Guitar")
      )),
      Band("Band 2", BandStyle.POP, listOf(
        BandMember("4", "Member 4", "Drums"),
        BandMember("5", "Member 5", "Microphone"),
        BandMember("6", "Member 6", "Guitar"),
        BandMember("7", "Member 7", "Keyboard")
      ))
    ).some()
}

fun main() {
  //sampleStart
  // val userId = InMemoryUserDatabase.createUser("SomeUserName")
  // println(userId)
  println(
    InMemoryUserDatabase.findUser(UserId("SomeId"))
      .flatMap { InMemoryBandService.getBandsFollowedByUser(it.id) }
      .fold(
        ifEmpty = { "User not found!" },
        ifSome = { bands -> bands.toString() }
      ))
  //sampleEnd
}
```

Let's run it to find that the complete expression result is short-circuited to `None`, so we log our error message prepared for that case.

### Modelling errors

Our program already handles the absence of a user in the database, which is a very specific error. But there are more errors we are not handling yet. Let's say we had real database and service implementations. Our database connection could fail on each access, and our network could timeout. Both of them could also throw other types of `IOException`. Let's represent those scenarios in our program contracts.

```kotlin
object DatabaseConnectionError : RuntimeException()
object TimeoutError : RuntimeException()

interface UserDatabase {
  @Throws(IOException::class, DatabaseConnectionError::class)
  fun createUser(name: String): UserId

  @Throws(IOException::class, DatabaseConnectionError::class)
  fun findUser(userId: UserId): Option<User>
}

interface BandService {
  @Throws(IOException::class, TimeoutError::class)
  fun getBandsFollowedByUser(userId: UserId): Option<List<Band>>
}
```

This is a potential way we'd think of for modelling our scenario in a jvm program. But using exceptions has some important cons:

* **Exceptions are heavy and slow**. Here you have more literature about this.
* **Exceptions can jump many layers in the call stack**, so you cannot think locally about your functions, but need to keep the complete program flow in mind, all the time. That's a big overhead to have. Note that one of the big benefits of Functional Programming is the ability to apply local reasoning over highly composable pieces which are the functions.
* **Exceptions encode an alternative error path**, so you have two completely different paths to follow for your flow control: success result and exceptions. Exceptions were created to model exceptional scenarios, not for control flow. Most of our errors should be handled by the program, hence they are part of our expected domain.


As stated above, we would rather aim to model our program errors as part of our domain data. Errors are also data.

Arrow provides the [Either](https://arrow-kt.io/docs/apidocs/arrow-core-data/arrow.core/-either/) data type to model a duality in our control flow. It can be used to model any scenarios where you have a happy path to follow and an alternative via that is frequently used to represent failure.