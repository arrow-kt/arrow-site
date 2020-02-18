---
layout: docs
title: Libraries
permalink: /quickstart/libraries/
---

## Core Libraries

Arrow is a modular set of libraries that build on top of each other to provide increasingly higher level features.

One of our design principles is to keep each library as lean as possible to avoid pulling unnecessary dependencies,
specially to support Android development where app size affects performance. You're free to pick and choose only those libraries that your project needs!

In this doc we'll describe all the modules that form the core, alongside a list of the most important constructs they include.

### arrow-core

{:.beginner}
beginner

The smallest set of [datatypes]({{ '/datatypes/intro/' | relative_url }}) necessary to start in FP, and that other libraries can build upon.
The focus here is on API design and abstracting small code patterns.

Datatypes: [`Either`]({{ '/arrow/core/either/' | relative_url }}), [`Option`]({{ '/arrow/core/option/' | relative_url }}), [`Try`]({{ '/arrow/core/try/' | relative_url }}), [`Eval`]({{ '/arrow/core/eval/' | relative_url }}), [`Id`]({{ '/arrow/core/id/' | relative_url }}), `TupleN`, `Function0`, `Function1`, `FunctionK`

### arrow-syntax

{:.beginner}
beginner

Multiple extensions functions to work better with function objects and collections.

Dependencies: arrow-core

For function objects the library provides composition, currying, partial application, memoization, pipe operator, complement for predicates, and several more helpers.

For collections, arrow-syntax provides `firstOption`, tail, basic list traversal, and tuple addition.

### arrow-typeclasses

{:.intermediate}
intermediate

All the basic [typeclasses]({{ '/typeclasses/intro' | relative_url }}) that can compose into a simple program.

Dependencies: arrow-core

Datatypes: [`Const`]({{ '/typeclasses/const/' | relative_url }})

Typeclasses: [`Alternative`]({{ '/arrow/typeclasses/alternative/' | relative_url }}), [`Bimonad`]({{ '/arrow/typeclasses/bimonad/' | relative_url }}), [`Inject`]({{ '/typeclasses/inject/' | relative_url }}), [`Reducible`]({{ '/arrow/typeclasses/reducible/' | relative_url }}), [`Traverse`]({{ '/arrow/typeclasses/traverse/' | relative_url }}), [`Applicative`]({{ '/arrow/typeclasses/applicative/' | relative_url }}), [`Comonad`]({{ '/arrow/typeclasses/comonad/' | relative_url }}), [`Eq`]({{ '/arrow/typeclasses/eq/' | relative_url }}), [`Monad`]({{ '/arrow/typeclasses/monad/' | relative_url }}), [`Monoid`]({{ '/arrow/typeclasses/monoid/' | relative_url }}), [`Semigroup`]({{ '/arrow/typeclasses/semigroup/' | relative_url }}), [`ApplicativeError`]({{ '/arrow/typeclasses/applicativeerror/' | relative_url }}), [`Foldable`]({{ '/arrow/typeclasses/foldable/' | relative_url }}), [`MonoidK`]({{ '/arrow/typeclasses/monoidk/' | relative_url }}), [`SemigroupK`]({{ '/arrow/typeclasses/semigroupk/' | relative_url }}), [`Bifoldable`]({{ '/arrow/typeclasses/bifoldable/' | relative_url }}), [`Functor`]({{ '/arrow/typeclasses/functor/' | relative_url }}), [`MonadError`]({{ '/arrow/typeclasses/monaderror/' | relative_url }}), [`Order`]({{ '/arrow/typeclasses/order/' | relative_url }}), [`Show`]({{ '/arrow/typeclasses/show/' | relative_url }}), `Composed`

### arrow-data

{:.beginner}
beginner

This library focuses on expanding the helpers provided by typeclasses to existing constructs, like the system collections.
You can also find more advanced constructs for pure functional programming like the `RWS` datatypes, or transformers.

Dependencies: arrow-typeclasses

Datatypes: [`Cokleisli`]({{ '/datatypes/cokleisli/' | relative_url }}), [`Coreader`]({{ '/datatypes/coreader/' | relative_url }}), [`Ior`]({{ '/arrow/data/ior/' | relative_url }}), [`ListK`]({{ '/arrow/data/listk/' | relative_url }}), [`NonEmptyList`]({{ '/arrow/data/nonemptylist/' | relative_url }}), [`SequenceK`]({{ '/arrow/data/sequencek/' | relative_url }}), [`SortedMapK`]({{ '/arrow/data/sortedmapk/' | relative_url }}), [`StateT`]({{ '/arrow/data/statet/' | relative_url }}), [`WriterT`]({{ '/arrow/data/writert/' | relative_url }}), [`Coproduct`]({{ '/arrow/data/coproduct/' | relative_url }}), [`EitherT`]({{ '/arrow/data/eithert/' | relative_url }}), [`Kleisli`]({{ '/arrow/data/kleisli/' | relative_url }}), [`MapK`]({{ '/arrow/data/mapk/' | relative_url }}), [`OptionT`]({{ '/arrow/data/optiont/' | relative_url }}), [`Reader`]({{ '/arrow/data/reader/' | relative_url }}), [`SetK`]({{ '/arrow/data/setk/' | relative_url }}), [`State`]({{ '/arrow/data/state/' | relative_url }}), [`Validated`]({{ '/arrow/data/validated/' | relative_url }})

### arrow-instances-(core, data)

{:.intermediate}
intermediate

These two libraries include the possible [typeclass instances]({{ '/patterns/glossary/#instances' | relative_url }}) that can be implemented for the datatypes in arrow-core and arrow-data, and some basic types.

Dependencies: arrow-typeclasses, and either arrow-core or arrow-data

### arrow-mtl

{:.advanced}
advanced

Advanced [typeclasses]({{ '/typeclasses/intro' | relative_url }}) to be used in programs using the Tagless-final architecture.

It also includes the instances available for datatypes in both arrow-core and arrow-data

Dependencies: arrow-instances-data

Typeclasses: [`FunctorFilter`]({{ '/arrow/mtl/typeclasses/functorfilter/' | relative_url }}), [`MonadFilter`]({{ '/arrow/mtl/typeclasses/monadfilter/' | relative_url }}), [`MonadReader`]({{ '/arrow/mtl/typeclasses/monadreader/' | relative_url }}), [`MonadWriter`]({{ '/arrow/mtl/typeclasses/monadwriter/' | relative_url }}), [`MonadCombine`]({{ '/arrow/mtl/typeclasses/monadcombine/' | relative_url }}), [`MonadState`]({{ '/arrow/mtl/typeclasses/monadstate' | relative_url }}), [`TraverseFilter`]({{ '/arrow/mtl/typeclasses/traversefilter/' | relative_url }})

## Extension libraries

These libraries are hosted inside the arrow repository building on the core, to provide higher level constructs to deal with concepts rather than code abstraction.

### arrow-optics

{:.beginner}
beginner

Optics is the functional way of handling immutable data and collections in a way that's boilerplate free and efficient.

It can be used alongside annotation processing to generate [simple DSLs]({{ '/optics/dsl/' | relative_url }}) that read like imperative code.

For all the new typeclasses it also includes the instances available for basic types and datatypes in both arrow-core and arrow-data.

Datatypes: [`Fold`]({{ '/optics/fold/' | relative_url }}), [`Getter`]({{ '/optics/getter/' | relative_url }}), [`Iso`]({{ '/optics/iso/' | relative_url }}), [`Lens`]({{ '/optics/lens/' | relative_url }}), [`Optional`]({{ '/optics/optional/' | relative_url }}), [`Prism`]({{ '/optics/prism/' | relative_url }}), [`Setter`]({{ '/optics/setter/' | relative_url }}), [`Traversal`]({{ '/optics/traversal/' | relative_url }})

Typeclasses: [`At`]({{ '/optics/at/' | relative_url }}), [`Each`]({{ '/optics/each/' | relative_url }}), [`FilterIndex`]({{ '/optics/filterIndex/' | relative_url }}), [`Index`]({{ '/optics/index/' | relative_url }})

### arrow-effects

{:.intermediate}
intermediate

The effects library abstracts over concurrency frameworks using typeclasses. Additionally it provides its own concurrency primitive, called IO.

Datatypes: [`IO`]({{ '/effects/io/' | relative_url }})

Typeclasses: [`MonadDefer`]({{ '/effects/monaddefer/' | relative_url }}), [`Async`]({{ '/effects/async/' | relative_url }}), [`Effect`]({{ '/effects/effect/' | relative_url }})


### arrow-effects-(rx2, reactor, kotlinx-coroutines)

{:.intermediate}
intermediate

Each of these modules provides wrappers over the datatypes in each of the libraries that implement all the typeclasses provided by arrow-effects

[Rx]({{ '/integrations/rx2/' | relative_url }}): `Observable`, `Flowable`, `Single`

[Reactor]({{ '/integrations/reactor/' | relative_url }}): `Flux`, `Mono`

[kotlinx.coroutines]({{ '/integrations/kotlinxcoroutines/' | relative_url }}): `Deferred`

### arrow-recursion

{:.advanced}
advanced

Recursion schemes is a construct to work with recursive data structures in a way that decuples structure and data, and allows for ergonomy and performance improvements.

Datatypes: [`Fix`]({{ '/recursion/fix/' | relative_url }}), [`Mu`]({{ '/recursion/mu/' | relative_url }}), [`Nu`]({{ '/recursion/nu/' | relative_url }})

Typeclasses: [`Corecursive`]({{ '/recursion/corecursive/' | relative_url }}), [`Recursive`]({{ '/recursion/recursive/' | relative_url }}), [`Birecursive`]({{ '/recursion/birecursive/' | relative_url }})

### arrow-integration-retrofit-adapter

{:.advanced}
advanced

The [adapter]({{ '/integrations/retrofit/' | relative_url }}) is a library that adds integration with Retrofit, providing extensions functions and/or classes to work with Retrofit by encapsulating the responses in the chosen datatypes, through the use of typeclasses.

### arrow-free

{:.advanced}
advanced

The [Free datatype]({{ '/free/free/' | relative_url }}) is a way of interpreting domain specific languages from inside your program, including a configurable runner and flexible algebras.
This allows optimization of operations like operator fusion or parallelism, while remaining on your business domain.

Datatypes: [`Free`]({{ '/free/free/' | relative_url }}), [`FreeApplicative`]({{ '/free/freeapplicative/' | relative_url }}), [`Cofree`]({{ '/free/cofree/' | relative_url }}), [`Yoneda`]({{ '/free/yoneda/' | relative_url }}), [`Coyoneda`]({{ '/free/coyoneda/' | relative_url }})

## Annotation processors

These libraries focus on meta-programming to generate code that enables other libraries and constructs.

### arrow-generic

{:.advanced}
advanced

It allows anonating data classes with [`@product`]({{ '/generic/product/' | relative_url }}) to enable them to be structurally deconstructed in tuples and heterogeneous lists.
