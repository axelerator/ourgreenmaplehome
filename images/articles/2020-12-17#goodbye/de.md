---
{"title": "Logging auf Deutsch"}
---
Warum können wir nicht einfach nur `Debug.log "a is:" a` schreiben? Der Grund dafür ist, dass der `let` Block ausschließlich dazu dient lokale Ausdrücke zu benennen.
`Debug.log` ist die **einzige** Funktion in Elm die nicht **pure** ist und für deren Rückggabewert wir uns nicht interessieren.
**Alle anderen** Funktionen rufen wir auf um an den berechneten Wert zu kommen (und ihm im `let` einen lokalen Namen zu geben).
Damit das Format wie wir `Debug.log` aufrufen dasselbe ist wie das der "normalen" Ausdrücke im `let` Block weisen wir den Ausdruck den Namen `_`(Unterstrich) zu.
Mit dieser Konvention wird vermieden, dass der Compiler eine extra Syntax-Regel ausschließlich für die `Debug.log` Anweisung haben muss.

Der Unterstrich kommt nicht nur hier zum Einsatz, sondern wird generell als Bezeichner verwendet wenn wir uns für den Inhalt des Ausdrucks nicht interessieren.  

Zum Beispiel auch in unserer [mkEmptyRow](https://github.com/axelerator/elm-tetris/blob/episode5/src/Main.elm#L137) Funktion:

```Elm
  mkEmptyRow _ =
      Row <| map (\_ -> Empty) (range 1 11)
``` 

Wir nutzen den "Wiederholungscharakter" der [`map` Funktion](https://package.elm-lang.org/packages/elm/core/latest/List#map) um eine Funktion für jedes Element in einer [range](https://package.elm-lang.org/packages/elm/core/latest/List#range) aufzurufen.
Allerdings interessieren wir uns nicht für die tatsächliche Zahl.
Wir geben dem Leser frühzeitig einen Hinweis darauf in dem wir anstatt einen Namen den Unterstrich als Parameternamen verwenden.

