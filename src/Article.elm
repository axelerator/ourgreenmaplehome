module Article exposing (..)

import DataSource exposing (DataSource)
import DataSource.File as File
import DataSource.Glob as Glob
import Date exposing (Date, Language)
import Json.Decode exposing (Decoder)
import Language exposing (Language(..), otherLanguages)
import List exposing (drop, member)
import List.Extra exposing (find)
import OptimizedDecoder as Decode exposing (Decoder)
import String exposing (split)
import Url exposing (percentEncode)


type alias ArticleMetaData =
    { slug : String
    , folderName : String
    , languages : List Language
    , published : Date
    }


type alias ArticleContent =
    { language : Language
    , title : String
    , body : String
    }


type alias Article =
    { metaData : ArticleMetaData
    , content : List ArticleContent
    }


type alias SlugAndFolder =
    ( String, String )


type alias SlugAndFolderAndLanguages =
    ( String, String, List Language )


type alias ContentFrontMatter =
    { title : String }


articleFolders : DataSource.DataSource (List SlugAndFolder)
articleFolders =
    let
        extractSlug folderName =
            case List.head <| drop 1 (split "#" folderName) of
                Just slug ->
                    ( slug, folderName )

                Nothing ->
                    ( folderName, folderName )
    in
    Glob.succeed extractSlug
        |> Glob.match (Glob.literal "articles/")
        |> Glob.capture Glob.wildcard
        |> Glob.match (Glob.literal "/meta.json")
        |> Glob.toDataSource


articleMetaData : DataSource (List ArticleMetaData)
articleMetaData =
    let
        f : List SlugAndFolder -> DataSource (List ArticleMetaData)
        f snfs =
            DataSource.combine (List.map articleMetaFromSlugAndFolder snfs)
    in
    DataSource.andThen f articleFolders


hasLanguage : Language -> Article -> Bool
hasLanguage language { metaData } =
    List.member language metaData.languages


articlesIn : Language -> DataSource (List ( Article, ArticleContent ))
articlesIn language =
    let
        collectVariant article variants =
            case find (\v -> v.language == language) article.content of
                Just variant ->
                    ( article, variant ) :: variants

                Nothing ->
                    variants

        englishContent articlesAndContent =
            DataSource.succeed <| List.foldr collectVariant [] articlesAndContent
    in
    DataSource.andThen englishContent articles


articles : DataSource (List Article)
articles =
    DataSource.andThen (DataSource.combine << List.map loadArticle) articleMetaData


otherLanguagesOf : Article -> Language -> List Language
otherLanguagesOf article language =
    List.map .language <|
        List.Extra.filterNot (inLanguage language) article.content


inLanguage : Language -> ArticleContent -> Bool
inLanguage language content =
    content.language == language


excerpt : ArticleContent -> String
excerpt content =
    Maybe.withDefault "" <| List.head <| String.lines content.body


teaserImgPath : Article -> String
teaserImgPath article =
    String.join "/" <|
        List.map percentEncode
            [ ""
            , "images"
            , "articles"
            , article.metaData.folderName
            , "images"
            , "teaser.jpg"
            ]


languageToString : Language -> String
languageToString l =
    case l of
        English ->
            "en"

        German ->
            "de"

        French ->
            "fr"


languageFromString : String -> Language
languageFromString s =
    case s of
        "en" ->
            English

        "de" ->
            German

        "fr" ->
            French

        _ ->
            English


addLanguageTo : SlugAndFolder -> List String -> DataSource SlugAndFolderAndLanguages
addLanguageTo ( slug, folderName ) lang =
    DataSource.succeed
        ( slug
        , folderName
        , List.map languageFromString lang
        )


findLanguages : String -> DataSource.DataSource (List Language)
findLanguages folderName =
    Glob.succeed languageFromString
        |> Glob.match (Glob.literal <| "articles/" ++ folderName ++ "/")
        |> Glob.capture Glob.wildcard
        |> Glob.match (Glob.literal ".md")
        |> Glob.toDataSource


articleMetaFromSlugAndFolder : SlugAndFolder -> DataSource ArticleMetaData
articleMetaFromSlugAndFolder (( slug, folderName ) as snf) =
    DataSource.andThen
        (readArticleMeta snf)
        (findLanguages folderName)


readArticleMeta : SlugAndFolder -> List Language -> DataSource ArticleMetaData
readArticleMeta (( _, folderName ) as snf) languages =
    File.jsonFile (articleMetaDataDecoder snf languages) <|
        String.join "/" [ "articles", folderName, "meta.json" ]


articleMetaDataDecoder : SlugAndFolder -> List Language -> Decoder ArticleMetaData
articleMetaDataDecoder ( slug, folderName ) languages =
    let
        result published =
            { slug = slug
            , folderName = folderName
            , published = published
            , languages = languages
            }
    in
    Decode.map result
        (Decode.field "published" dateDecoder)


dateDecoder : Decoder Date
dateDecoder =
    Decode.string
        |> Decode.andThen
            (\isoString ->
                case Date.fromIsoString isoString of
                    Ok date ->
                        Decode.succeed date

                    Err error ->
                        Decode.fail error
            )


loadArticle : ArticleMetaData -> DataSource Article
loadArticle metaData =
    let
        contentData =
            DataSource.combine <| List.map (loadContent metaData) metaData.languages

        mkArticle content =
            DataSource.succeed
                { metaData = metaData
                , content = content
                }
    in
    DataSource.andThen mkArticle contentData


loadContent : ArticleMetaData -> Language -> DataSource ArticleContent
loadContent adm language =
    let
        path =
            String.join "/" [ "articles", adm.folderName, languageToString language ++ ".md" ]

        mkContent ( body, frontMatter ) =
            DataSource.succeed
                { language = language
                , title = frontMatter.title
                , body = body
                }
    in
    DataSource.andThen mkContent <| File.bodyWithFrontmatter frontMatterDecoder path


frontMatterDecoder : String -> Decoder ( String, ContentFrontMatter )
frontMatterDecoder body =
    let
        result title =
            ( body, { title = title } )
    in
    Decode.map result
        (Decode.field "title" Decode.string)
