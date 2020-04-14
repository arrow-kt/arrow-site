---
layout: docs-learn-by-example
title: Modelling data
permalink: /learn-by-example/3-modelling-data/
---

# A complete program by example

Any program needs to model both **errors** and **data** to compose its domain. Program's logic has to be prepared to handle all the scenarios described by the two. In [the previous post in the series](/learn-by-example/2-handling-errors/), we learned how to model and handle error scenarios, but we didn't dive much into how to model data. We learned about data types as a way to raise concerns over our data, but that was pretty much it.

In this post, we will learn how both the Kotlin type system and the functional data types can help to model a safe domain for our programs.

## 3. Modelling data

Let me rewind ⏪ a bit to rescue our latest "fail fast" version of our program. For that one, we were using `Either<L, R>` to model both paths in our program: errors vs successful data.

Here we have our contracts for the `UserDatabase` and the `BandService`. We call those *algebras*, since they define **an abstract set of operations each one of those dependencies provides**.

> In Functional programming, programs are defined by a clear separation between algebras (abstract contracts that model the operations in our program) and runtime (interpreters or implementations for those algebras). Programs are usually defined in terms of the algebras so you can later come in and swap the runtime at will (implementation details). We will cover this topic in more extent and make good use of it in further posts like the Dependency Injection one. 

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

//sampleStart
interface UserDatabase {
  fun createUser(name: String): Either<DomainError, UserId>
  fun findUser(userId: UserId): Either<DomainError, User>
}

interface BandService {
  fun getBandsFollowedByUser(userId: UserId): Either<DomainError, List<Band>>
}
//sampleEnd
```

These were the stubbed implementations we had for those.

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

And finally, our program.

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

interface BandService {
  fun getBandsFollowedByUser(userId: UserId): Either<DomainError, List<Band>>
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
fun main() {
  println(
    InMemoryUserDatabase.createUser("SomeUserName")
      .flatMap { InMemoryUserDatabase.findUser(it) }
      .flatMap { InMemoryBandService.getBandsFollowedByUser(it.id) }
      .fold(
        ifLeft = { "User not found!" },
        ifRight = { bands -> bands.toString() }
      ))
}
//sampleEnd
```

One thing we could notice is how we are calling `println()` to log the result of our program to console. That operation is actually part of our program also, it represents how we display results to the final user. So we could model it after an algebra like the other parts of the program:

```kotlin:ank
import java.util.*
import arrow.core.*

//sampleStart
interface Console {
  fun log(message: String): Unit
}

object StdOutConsole : Console {
  override fun log(message: String): Unit {
    println(message)
  }
}
//sampleEnd
```

The Kotlin type system offers `Unit` as a way to model an operation that will not return a value expected to be used. That makes it perfect to model side effects like this one, since by returning `Unit` you are assuming the function will need to do something within its scope that is not providing a result: printing to console, rendering to screen, mutating a external shared state, or similar.

Let's update our program to use the `Console` algebra, and let's also use the chance to move our program to target the algebra abstractions.

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

interface BandService {
  fun getBandsFollowedByUser(userId: UserId): Either<DomainError, List<Band>>
}

interface Console {
  fun log(message: String): Unit
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

object StdOutConsole : Console {
  override fun log(message: String): Unit {
    println(message)
  }
}

//sampleStart
fun main() {
  program(StdOutConsole, InMemoryUserDatabase, InMemoryBandService)
}

fun program(console: Console, userDatabase: UserDatabase, bandService: BandService): Unit {
  console.log(
    userDatabase.createUser("SomeUserName")
      .flatMap { userDatabase.findUser(it) }
      .flatMap { bandService.getBandsFollowedByUser(it.id) }
      .fold(
        ifLeft = { "User not found!" },
        ifRight = { bands -> bands.toString() }
      ))
}
//sampleEnd
```

Check how the program is completely abstract at this moment. It only cares about what operations are performed but not how they are implemented. Implementation details are passed as dependencies to the program.

Once we have learned how `Unit` can be used to indicate side effects, we can also take a look at `Nothing`, within the Kotlin type system.

`Nothing` as a return type indicates an `absurd` function. It's a function that literally can't return from the Kotlin compiler perspective. **It is enforced to throw.** You can take a look to the `TODO()` function declaration in Kotlin:

```kotlin:ank
//sampleStart
inline fun TODO(): Nothing = throw NotImplementedError()
//sampleEnd 
``` 

`Nothing` is used as the **bottom type** by the Kotlin compiler. The compiler knows how to go from `Nothing` to any other type, so it can be used to **leverage type inference**, so it does not get affected by non possible variants represented with `Nothing`. This approach is widely used when defining [algebraic data types](https://en.wikipedia.org/wiki/Algebraic_data_type), so let's learn a bit about those over our program example.

We refer as algebraic data types to a composition of **product types** and **sum types**. You can dive into very detailed explanations, but with the intention to stay closer to the example, we'll give you two brief definitions:

#### Product type

In algebra, it's represented by the "AND" operator. 

A product type is comprised of **all its properties**. *"This property, AND this one, AND this other one..."*, all of them are expected to **conform the structure of the type**. Based on this concept, additional behaviors can be derived (at compile time) based on the type structure. A good example of a product type would be `data class` in Kotlin, that the compiler derives operations like `equals`, `hashcode`, `components` (destructuring) or the `copy` constructor for.

#### Sum type

In algebra, it's represented by the "OR" operator. 

It can be one of a given set of elements. *"This implementation, OR this one, OR this other one..."*, it's **exclusive**. Good examples of these in Kotlin would be `enum class`, or `sealed class`, used to define a sealed hierarchy of possible implementations for a type.

**As you can imagine, both Product types and Sum types are used to model data in our programs.**

In Arrow, both concepts are really used, but specially sum types. All Arrow data types are defined as sum types that provide an algebra of possible representations for the type. Some rapid examples:

**Option**

```kotlin:ank
//sampleStart
sealed class Option<out A> : OptionOf<A> {
  object None : Option<Nothing>()
  data class Some<out T>(val t: T) : Option<T>()
}
//sampleEnd
```

Note how the `A` type has `out` variance, and how we declare `None` as `Option<Nothing>()`. With this encoding, we make sure that any code dealing with an optional value will match it as an `Option<A>` no matter whether it's a `None` or a `Some`, by keeping the information about the generic type `A`. The goal is to use the power of `Nothing` as the bottom type so code doesn't fall into inference problems. If we didn't code it like this, both implementations would be considered different types and the upper bound for both would be `Any`, instead of `Option<A>`.

Another example of how we are leveraging this pattern could be `Either<A, B>`.

**Either**

```kotlin:ank
//sampleStart
sealed class Either<out A, out B> {
  data class Left<out A>(val a: A) : Either<A, Nothing>()
  data class Right<out B>(val b: B) : Either<Nothing, B>()
}
//sampleEnd
```

Once again, check how we make use of `out` variance for both generic types, so we can do `Left : Either<A, Nothing>` and `Right : Either<Nothing, B>`. That way we can let the compiler ignore the non relevant side for each case.

You can find more details on this [in this interesting article](https://www.freecodecamp.org/news/the-nature-of-nothing-in-kotlin-9b1c78f27da7/).

##### Back to the program

<img src="/img/learn-by-example/band_data_model.gif" alt="Rock band playing" width="800"/>

We are already using some of those data types like `Either` to model the concerns over our data, and we are actually already using the concept of algebraic data types to model our errors. Note how our `DomainError` definition **is already a sum type**:

```kotlin:ank
//sampleStart
sealed class DomainError : RuntimeException() {
  object ConnectionError : DomainError()
  object TimeoutError : DomainError()
  object NotFoundError : DomainError()
  object FallbackError : DomainError()
}
//sampleEnd
```

At a given time, it can be **one of many**. We can use the same idea to model the instruments for our rock band 🎸🤘

```kotlin:ank
//sampleStart
data class GuitarString(val broken: Boolean = false)

sealed class Instrument {
  abstract val model: String

  data class Guitar(override val model: String, val strings: List<GuitarString>) : Instrument()
  data class Microphone(override val model: String) : Instrument()
  data class Drums(override val model: String) : Instrument()
}

data class BandMember(
  val id: String,
  val name: String,
  val instrument: Instrument
)
//sampleEnd
```

Here we have the combination of both product types and sum types to compose a nice part of our data domain.