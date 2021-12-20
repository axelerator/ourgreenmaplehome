module Language exposing (..)


type Language
    = English
    | French
    | German


all : List Language
all =
    [ English, German, French ]


otherLanguages : Language -> List Language
otherLanguages language =
    List.filter ((/=) language) all
