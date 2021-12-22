---
{"title": "JSON Decoding"}
---
As already mentioned in the video a complete explanation of JSON decoding warrants its own article. There is a [short introduction in the official guide](https://guide.elm-lang.org/effects/json.html).
But other people have already created exhaustive articles about the more complex cases that are not covered there. For example [this article on elmprogramming.com](https://elmprogramming.com/decoding-json-part-1.html#decoding-json).

Compared to other languages like JavaScript or Ruby it seems like decoding JSON in Elm is unnecessarily complicated. I fought with it for quite a while myself when I *'just wanted to read some JSON'* in Elm for the first time.
So today I'd like to convince you that it's not *that* complicated after all and that the additional complexity is well worth it.

At the end of the coding session we ended up with a JSON decoder that looked like this:

![eine wand](wand.jpg "tags::title")
