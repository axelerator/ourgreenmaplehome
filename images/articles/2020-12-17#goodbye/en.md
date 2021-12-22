---
{"title": "Logging in English"}
---
Why can't we just write `Debug.log "a is:" a` only? The reason is that the intention of the `let` block is to **give names** to expressions.
`Debug.log` is **the only** function in Elm that's not **pure** and where we don't care about its result.
**All other** we call **only** to get their result. So for our `Debug.log` line to have the same format as the other expressions in a `let` block, we'll just assign it the name `_` (the underscore).
By doing so it can be avoided that the compiler has to implement an extra syntax rule **only** for the `Debug.log` call.

This is not the only use case for the underscore. We use it generally as an identifier for an expression that is not used further down the function body.

I already did that in the [`mkEmptyRow` function](https://github.com/axelerator/elm-tetris/blob/episode5/src/Main.elm#L137):

```Elm
  mkEmptyRow _ =
      Row <| map (\_ -> Empty) (range 1 11)
``` 

I#m using the "looping notion" of the [`map` function](https://package.elm-lang.org/packages/elm/core/latest/List#map) to call another function on every element in a [range](https://package.elm-lang.org/packages/elm/core/latest/List#range) 
But in this function, I'm not really interested in the actual number for each iteration. By using the underscore as the identifier for the parameter we're giving a potential reader of the code an **early** sign that they don't have to care about it.
