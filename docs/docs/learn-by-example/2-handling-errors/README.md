---
layout: docs-learn-by-example
title: Handling errors
permalink: /learn-by-example/2-handling-errors/
---

# A complete program by example

In [the previous post in the series](/learn-by-example/1-writing-the-initial-program/) we wrote an initial program to create and find users for a Rock Band social network backend. We found out that our approach had some inherent issues since we were not handling errors or keeping side effects under control. We will focus on error handling first. We will dive into modelling data and how to control side effects in future posts.

## 2. Handling errors

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

Arrow data types are encoded with **a bias towards the happy case**. That means they are prepared to compose computations that work over the happy path, so we can build our program logic seamlessly assuming things will go alright, and then provide an error handling strategy as a single pluggable piece at some point. This removes a lot of thinking overhead from our minds and makes programs highly composable.

In the case of `Option<A>`, it is biased towards the `Some` case, which represents the happy case. Thanks to this, we could also stack more computations on top of it using `flatMap` or `map` before folding to apply our side effects. Let's see an example of this. 

Let's say we had a `BandService` to retrieve the list of bands that a given user follows in the social network. We could make the contract for it also return an `Option` since the provided `userId` could not be found, and provide a stubbed in-memory implementation like the following one.

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

If we run it we will find that the complete expression result is short-circuited to `None`, so we log our error message prepared for that case.

### Modelling errors

Our program already handles the absence of a user in the database, which is a very specific error. But there are more errors we are not handling yet. Let's say we had real database and service implementations. Both could throw connection errors on each call, timeout errors, and other types of `IOException` errors. Let's represent those scenarios in our program contracts.

```kotlin
object ConnectionError : RuntimeException()
object TimeoutError : RuntimeException()
object IOException : java.io.IOException()

interface UserDatabase {
  @Throws(ConnectionError::class, TimeoutError::class, IOException::class)
  fun createUser(name: String): UserId

  @Throws(ConnectionError::class, TimeoutError::class, IOException::class)
  fun findUser(userId: UserId): Option<User>
}

interface BandService {
  @Throws(ConnectionError::class, TimeoutError::class, IOException::class)
  fun getBandsFollowedByUser(userId: UserId): Option<List<Band>>
}
```

This is a potential way we'd think of for modelling our scenario in a jvm program. But using exceptions has some important cons:

* **Exceptions are heavy and slow**. [Here](http://normanmaurer.me/blog/2013/11/09/The-hidden-performance-costs-of-instantiating-Throwables/) you have more literature about this. Also [from this slide forward](https://speakerdeck.com/raulraja/functional-error-handling?slide=6). Instantiating a `Throwable` computes the stack-trace and that is such heavy that is usually considered a side effect. 
* **Exceptions can jump many layers in the call stack**, so you cannot think locally about your functions, but need to keep the complete program flow in mind, all the time. That's a big overhead to have. Note that one of the big benefits of Functional Programming is the ability to apply local reasoning over highly composable pieces which are the functions. Exceptions break that.
* **Exceptions don't jump async boundaries or threads**. They can blow up a thread or a unit of logic, but caller code does not notice unless you do manual mapping to an error result, notify using a continuation (callback) or similar.
* **Exceptions encode an alternative error path**, so you have two completely different paths to follow for your flow control: success result and exceptions. Exceptions were created to model exceptional scenarios, not for control flow. Most of our errors should be handled by the program, since they are part of our expected domain.

As stated above, we would rather aim to model our program errors as part of our domain data. Errors are also data.

Arrow provides the [`Either<L, R>`](https://arrow-kt.io/docs/apidocs/arrow-core-data/arrow.core/-either/) data type to model a duality in our control flow. It can be used to model any scenarios where you have a happy path to follow and an alternative via that is frequently used to represent failure.

```kotlin:ank
sealed class DomainError : RuntimeException() {
  object ConnectionError : DomainError()
  object TimeoutError : DomainError()
  object NotFoundError : DomainError()
  object FallbackError : DomainError()
}

interface UserDatabase {
  fun createUser(name: String): Either<DomainError, UserId>
  fun findUser(userId: UserId): Either<DomainError, User>
}

interface BandService {
  fun getBandsFollowedByUser(userId: UserId): Either<DomainError, List<Band>>
}
```

For convenience, we are adding up all the expected domain error cases to a single hierarchy so we can simplify our return types everywhere. Usually, we would want to segregate our errors a bit more, and have different hierarchies for our different domains. That is something we can definitely do and will explain in further sections.

Note how we always put our errors on the `left` side, and our successful results on the `right` side. That is a convention in Functional Programming.

Some stubbed implementations for this encoding could be:

```kotlin:ank
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

sealed class DomainError : RuntimeException() {
  object ConnectionError : DomainError()
  object TimeoutError : DomainError()
  object NotFoundError : DomainError()
  object FallbackError : DomainError()
}

interface UserDatabase {
  fun createUser(name: String): Either<DomainError, UserId>
  fun findUser(userId: UserId): Either<DomainError, User>
}

interface BandService {
  fun getBandsFollowedByUser(userId: UserId): Either<DomainError, List<Band>>
}

//sampleStart
object InMemoryUserDatabase : UserDatabase {
  private var users: List<User> = emptyList()

  override fun createUser(name: String): Either<DomainError, UserId> {
    val userId = generateId(name)
    this.users = users + listOf(User(userId, name))
    return userId.right()
  }

  override fun findUser(userId: UserId): Either<DomainError, User> =
    users.find { it.id == userId }.toOption().toEither { DomainError.NotFoundError }

  private fun generateId(name: String): UserId = UserId("$name${UUID.randomUUID()}")
}

object InMemoryBandService : BandService {

  override fun getBandsFollowedByUser(userId: UserId): Either<DomainError, List<Band>> =
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
    ).right()
}
//sampleEnd
```

We are doing the same than before, but this time we lift our results into the `Either<L, R>` context using the `value.right()` extension function. If we wanted to lift an error we would use `error.left()`.

This is how we could encode our program now:

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

sealed class DomainError : RuntimeException() {
  object ConnectionError : DomainError()
  object TimeoutError : DomainError()
  object NotFoundError : DomainError()
  object FallbackError : DomainError()
}

interface UserDatabase {
  fun createUser(name: String): Either<DomainError, UserId>
  fun findUser(userId: UserId): Either<DomainError, User>
}

object InMemoryUserDatabase : UserDatabase {
  private var users: List<User> = emptyList()

  override fun createUser(name: String): Either<DomainError, UserId> {
    val userId = generateId(name)
    this.users = users + listOf(User(userId, name))
    return userId.right()
  }

  override fun findUser(userId: UserId): Either<DomainError, User> =
    users.find { it.id == userId }.toOption().toEither { DomainError.NotFoundError }

  private fun generateId(name: String): UserId = UserId("$name${UUID.randomUUID()}")
}

interface BandService {
  fun getBandsFollowedByUser(userId: UserId): Either<DomainError, List<Band>>
}

object InMemoryBandService : BandService {

  override fun getBandsFollowedByUser(userId: UserId): Either<DomainError, List<Band>> =
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
    ).right()
}

fun main() {
  //sampleStart
  println(
    InMemoryUserDatabase.createUser("SomeUserName")
      .flatMap { InMemoryUserDatabase.findUser(it) }
      .flatMap { InMemoryBandService.getBandsFollowedByUser(it.id) }
      .fold(
        ifLeft = { "User not found!" },
        ifRight = { bands -> bands.toString() }
      ))
  //sampleEnd
}
```

`Either<L, R>` is also **biased towards the happy case**, which in this case would be its `Right` implementation. That is why we can keep stacking computations the same way we did with `Option<A>`, and they will keep working meanwhile all computations return `Right`.

We will see an example of how to use the power of *Monad Comprehensions* to improve this syntax a lot in the [6. Running sequential computations](/learn-by-example/6-running-sequential-computations/) section.

If a single computation in the chain returned `Left` (an error) then the complete call stack would get short-circuited to return that error. Once again, let's see an example of this:

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

sealed class DomainError : RuntimeException() {
  object ConnectionError : DomainError()
  object TimeoutError : DomainError()
  object NotFoundError : DomainError()
  object FallbackError : DomainError()
}

interface UserDatabase {
  fun createUser(name: String): Either<DomainError, UserId>
  fun findUser(userId: UserId): Either<DomainError, User>
}

object InMemoryUserDatabase : UserDatabase {
  private var users: List<User> = emptyList()

  override fun createUser(name: String): Either<DomainError, UserId> {
    val userId = generateId(name)
    this.users = users + listOf(User(userId, name))
    return userId.right()
  }

  override fun findUser(userId: UserId): Either<DomainError, User> =
    users.find { it.id == userId }.toOption().toEither { DomainError.NotFoundError }

  private fun generateId(name: String): UserId = UserId("$name${UUID.randomUUID()}")
}

interface BandService {
  fun getBandsFollowedByUser(userId: UserId): Either<DomainError, List<Band>>
}

object InMemoryBandService : BandService {

  override fun getBandsFollowedByUser(userId: UserId): Either<DomainError, List<Band>> =
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
    ).right()
}

fun main() {
  //sampleStart
  println(
    InMemoryUserDatabase.findUser(UserId("SomeUserId"))
      .flatMap { InMemoryBandService.getBandsFollowedByUser(it.id) }
      .fold(
        ifLeft = { "User not found!" },
        ifRight = { bands -> bands.toString() }
      ))
  //sampleEnd
}
```

Since we have removed the line to create the user, the `findUser` computation will fail and return `Left(NotFoundError)`, and therefore short-circuit the program. Feel free to run it to check by yourself.

### Error accumulation

Sometimes we don't want to fail fast but accumulate errors instead, so we can process all of them together. Arrow provides [`Validated<E, A>`](https://arrow-kt.io/docs/apidocs/arrow-core-data/arrow.core/-validated/) for this that you can use in combination with [`NonEmptyList<A>`](https://arrow-kt.io/docs/arrow/core/nonemptylist/) as the mean to combine errors. Let's see how to do it over an example.

Let's say we had a service to validate our username for registering to the social network.

```kotlin:ank
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

sealed class DomainError : RuntimeException() {
  object ConnectionError : DomainError()
  object TimeoutError : DomainError()
  object NotFoundError : DomainError()
  object FallbackError : DomainError()
}

interface UserDatabase {
  fun createUser(name: String): Either<DomainError, UserId>
  fun findUser(userId: UserId): Either<DomainError, User>
}

object InMemoryUserDatabase : UserDatabase {
  private var users: List<User> = emptyList()

  override fun createUser(name: String): Either<DomainError, UserId> {
    val userId = generateId(name)
    this.users = users + listOf(User(userId, name))
    return userId.right()
  }

  override fun findUser(userId: UserId): Either<DomainError, User> =
    users.find { it.id == userId }.toOption().toEither { DomainError.NotFoundError }

  private fun generateId(name: String): UserId = UserId("$name${UUID.randomUUID()}")
}

interface BandService {
  fun getBandsFollowedByUser(userId: UserId): Either<DomainError, List<Band>>
}

object InMemoryBandService : BandService {

  override fun getBandsFollowedByUser(userId: UserId): Either<DomainError, List<Band>> =
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
    ).right()
}

//sampleStart
sealed class UsernameError {
  object Empty : UsernameError()
  object NonAlphaNumeric : UsernameError()
  object ShortLength : UsernameError()
}

object ValidationService {
  private fun isAlphaNumeric(value: String) = "^[a-zA-Z0-9_]*$".toRegex().matches(value)

  fun validateNotEmpty(name: String): ValidatedNel<UsernameError, String> =
    if (name.isEmpty()) {
      UsernameError.Empty.invalidNel()
    } else {
      name.validNel()
    }

  fun validateLength(name: String): ValidatedNel<UsernameError, String> =
    if (name.length <= 3) {
      UsernameError.ShortLength.invalidNel()
    } else {
      name.validNel()
    }

  fun validateAlphaNumeric(name: String): ValidatedNel<UsernameError, String> =
    if (!isAlphaNumeric(name)) {
      UsernameError.NonAlphaNumeric.invalidNel()
    } else {
      name.validNel()
    }
}
//sampleEnd
```

This service is able to validate our inserted username by checking that it is not empty, it is not too short, and it is alphanumeric.

We could use this syntax to run all validations and accumulate the errors:

```kotlin:ank:playground
import java.util.*
import arrow.core.*
import arrow.core.extensions.nonemptylist.semigroup.semigroup
import arrow.core.extensions.validated.applicative.applicative

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

sealed class DomainError : RuntimeException() {
  object ConnectionError : DomainError()
  object TimeoutError : DomainError()
  object NotFoundError : DomainError()
  object FallbackError : DomainError()
}

interface UserDatabase {
  fun createUser(name: String): Either<DomainError, UserId>
  fun findUser(userId: UserId): Either<DomainError, User>
}

object InMemoryUserDatabase : UserDatabase {
  private var users: List<User> = emptyList()

  override fun createUser(name: String): Either<DomainError, UserId> {
    val userId = generateId(name)
    this.users = users + listOf(User(userId, name))
    return userId.right()
  }

  override fun findUser(userId: UserId): Either<DomainError, User> =
    users.find { it.id == userId }.toOption().toEither { DomainError.NotFoundError }

  private fun generateId(name: String): UserId = UserId("$name${UUID.randomUUID()}")
}

interface BandService {
  fun getBandsFollowedByUser(userId: UserId): Either<DomainError, List<Band>>
}

object InMemoryBandService : BandService {

  override fun getBandsFollowedByUser(userId: UserId): Either<DomainError, List<Band>> =
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
    ).right()
}

sealed class UsernameError {
  object Empty : UsernameError()
  object NonAlphaNumeric : UsernameError()
  object ShortLength : UsernameError()
}

object ValidationService {
  private fun isAlphaNumeric(value: String) = "^[a-zA-Z0-9_]*$".toRegex().matches(value)

  fun validateNotEmpty(name: String): ValidatedNel<UsernameError, String> =
    if (name.isEmpty()) {
      UsernameError.Empty.invalidNel()
    } else {
      name.validNel()
    }

  fun validateLength(name: String): ValidatedNel<UsernameError, String> =
    if (name.length <= 3) {
      UsernameError.ShortLength.invalidNel()
    } else {
      name.validNel()
    }

  fun validateAlphaNumeric(name: String): ValidatedNel<UsernameError, String> =
    if (!isAlphaNumeric(name)) {
      UsernameError.NonAlphaNumeric.invalidNel()
    } else {
      name.validNel()
    }
}

fun main() {
  //sampleStart
  val service = ValidationService
  val username = "N}l"
  val res1 = service.validateNotEmpty(username)
  val res2 = service.validateLength(username)
  val res3 = service.validateAlphaNumeric(username)

  val res = Validated.applicative(NonEmptyList.semigroup<UsernameError>()).tupledN(res1, res2, res3)
  //sampleEnd
  println(res)
}
```

You probably got a bit lost on [`Applicative<F>`](https://arrow-kt.io/docs/arrow/typeclasses/applicative/) here. It is a *Typeclass*. [Here](https://arrow-kt.io/docs/typeclasses/intro/) you have a brief intro to understand what *Typeclasses* are. For having a rapid mental mapping, we could say that:

#### Data types

Context for our data. `Option<A>`, `Either<L, R>`, `Validated<E, A>`... etc. They raise a concern over our data to a type level. "Is it there or not?", "Is it an error?", "Is it valid?".

#### Type classes

They define **generic** behaviors (syntax) for our program (Concurrency, asynchrony, deferring execution, dependent operations, independent operations... etc). They define what your program is able to do with the data.

Back to our snippet, `Applicative<F>` provides syntax to run **independent computations**. Here we are creating an instance of it for `Validated`, and we are using this machinery to run our independent validations by `Applicative#tupledN()`. We use it in combination with the [`Semigroup<A>`](https://arrow-kt.io/docs/arrow/typeclasses/semigroup/), another Typeclass. This one represents a **strategy to combine errors** that we are supplying. In this case it's the `Semigroup` for `NonEmptyList<A>`, which means it will combine the elements into a `NonEmptyList`.

Run the snippet to check how a `NonEmptyList<UsernameError>` containing the required accumulated errors is returned.

In following posts in the series we will showcase further error handling strategies linked to more advanced patterns like *Monad comprehensions* and concurrent operations among others. But let's move first into [Modelling data](/learn-by-example/3-modelling-data/), the next post in the series that shows **how to use the Kotlin type system and the functional types to model data in our programs**.