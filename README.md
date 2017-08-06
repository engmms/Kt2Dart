# Kt2Dart

[![Build status](https://ci.appveyor.com/api/projects/status/38gy6t4offcp39jb?svg=true)](https://ci.appveyor.com/project/ice1000/kt2dart)

This is a transpiler which consumes Kotlin codes and convert them into Dart.

Currently it's completely in progress. But it can do some simple jobs right now.

## Limitations

Kt2Dart supports full-featured Kotlin (because I write this parser according to the strict grammar definition),

but I will not add any support for transpiling:

+ **Extensions**
+ Labels (label break/continue, label return)
+ `import as`
+ **Anonymous Classes**
+ `if` and `when` as expressions
+ Typed closures (dart's closure type `Function` is not generic)
+ Desctructing declaration (`{ (a: Int, b: Int): Pair<Int, Int> -> xxx }`)

While these features are not fully supported:

+ Naming (names like `System.\`in\`` are transpiled into `System.in` directly)
+ Generics (Dart's generics are covariant)

Such (advanced) language features of Kotlin are too complex to transpile
(it needs too much analyzing while Kt2Dart is just a simple tool).

And this tool will raise warnings as comments when these stuffs are detected.

# Why Kt2Dart

Because I want to **Make [Flutter](https://flutter.io) Great Again**.

Flutter, written in Dart, is an awesome mobile developing framework. But Dart is **too** weak, for the dynamic typing and null-unsafety.

Kotlin is much more powerful.
If we can combine the **beautiful** flutter and the **powerful/safe** Kotlin, our world will be peaceful forever.

# Why Haskell

Yeah, as you see, I'm using Haskell in this project.
Because ~~Parser Combinators are easy and convenient~~ I want to practise my Haskell skills.

I'm a beginner to Haskell, so if you find any naive code, feel free to tell me (by issuing or mailing) (I'm using hlint).

# Have a Try

You simply need a ghc to play with this.

```haskell
Prelude> :l Functions.hs
...
*Functions> functionP <||| "fun main(args: Array<String>): Unit { }"
Unit main(Array<String> args){}
*Functions> functionP <||| "fun <T, R> run(block: (T) -> R): R { }"
R run<T,R>(Function/* (T) -> R */ block){}
*Functions> :l Strings
...
*Strings> stringTemplateP <||| "\"boy next door\""
"boy next door"
*Strings> stringTemplateP <||| "\"boy next door with an expression ${ expr } and a var $variable\""
"boy next door with an expression ${expr} and a var $variable"
*Strings> stringTemplateP <||| "\"we also have escape vars: \\n \\r \\t\""
"we also have escape vars: \n \r \t"
```
