---
{"title": "Le décodage de JSON"}
---
Comme indiqué dans la vidéo, une explication complète du décodage JSON mérite un article à part entière. Il existe une brève introduction dans le guide officiel. Mais d'autres personnes ont déjà créé des articles exhaustifs sur les cas plus complexes qui ne sont pas couverts par le guide. Par exemple, cet article sur elmprogramming.com.

Comparé à d'autres langages comme JavaScript ou Ruby, il semble que le décodage de JSON dans Elm soit inutilement compliqué. Je me suis moi-même battu contre cela pendant un certain temps lorsque j'ai voulu "juste lire du JSON" en Elm pour la première fois. Aujourd'hui, j'aimerais donc vous convaincre que ce n'est pas si compliqué que ça et que cette complexité supplémentaire en vaut la peine.

À la fin de la session de codage, nous nous sommes retrouvés avec un décodeur JSON qui ressemblait à ceci :

Traduit avec www.DeepL.com/Translator (version gratuite)
