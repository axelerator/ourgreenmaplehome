---
{"title": "JSON Dekodierung"}
---
Und schickt uns in den [offiziellen Guide](https://guide.elm-lang.org/effects/json.html) für mehr Details.
Ich versuche eine alternative Erklärung zu geben die hoffentlich ein paar Fragen beantwortet die Entwickler haben die aus weniger 'funktionalen Umgebungen' kommen.

Ein `Decoder` ist also "Ein Wert der weiß wie JSON Werte zu dekodieren sind". Das erste was auffällt ist, dass unser `keyDecoder` keinen Parameter animmt. Das ist im Sinne der Definition, denn wir berechnen nicht einen Wert aus gegebenen Parametern sondern geben einen konstanten Ausdruck zurück.

Das bringt die Frage auf: "Wie kann ein **konstanter Wert** etwas dekodieren?"
Das bringt uns zu den Grundprinzipien der funktionalen Programmierung zurück: Funktionen **sind** Werte.
In der Dokumentation sehen wir lediglich die 'linke Seite' der Typdefintion. 
Es kann also durchaus sein, dass dieser Typ aus Varianten gebildet die eine Funktion enthalten.

Die [Decoder-Bibliothek](https://package.elm-lang.org/packages/elm/json/latest/Json-Decode) enthält eine handvoll vordefinierter `Decoder` und Funktionen mit denen wir diese zu komplexeren Dekodierern zusammensetzen können.

Ein Typ dessen "rechte" Seite der Definition `type Decoder a = ???` wir nicht kennen wird auch ein **opaquer Typ** genannt.
Das heißt der Entwickler dieses Typs möchte nicht, dass wir die Implementierungsdetails kennen. Auf den ersten Blick mag das unnötig einschränkend wirken.
Richtig eingesetzt sind opaque Typen aber extrem **befreiend**. Es bedeutet, dass ich als Anwedungsentwickler mich nicht unnötig mit Implementierungsdetails auseinanderzusetzen brauch. Und da ich mit diesem Teil des Systems nicht interagieren kann, kann ich es auch nicht 'falsch bedienen' oder kaputt machen.

Anhand unseres `keyDecoder` werden wir sehen wir ein solcher Typ, obwohl wir nichts über seine Interna wissen, dennoch sehr nützlich sein kann.
