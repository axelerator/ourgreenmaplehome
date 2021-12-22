module Page.Language_.Slug_ exposing (Data, Model, Msg, RouteParams, page)

import Article exposing (Article, ArticleContent, ArticleMetaData, articleMetaData, articles, languageFromString, languageToString)
import Browser.Navigation
import DataSource exposing (DataSource)
import Date
import Head
import Head.Seo as Seo
import Html exposing (Html, div, h1, img, li, p, text)
import Html.Attributes as Attr exposing (class, src)
import Html.Events exposing (onClick)
import Language exposing (Language, otherLanguages)
import List
import List.Extra exposing (find)
import Markdown exposing (toHtml)
import Markdown.Block as Block
import Markdown.Html
import Markdown.Parser
import Markdown.Renderer
import Page exposing (Page, StaticPayload)
import Pages.PageUrl exposing (PageUrl)
import Pages.Url
import Path exposing (Path)
import Route exposing (Route(..))
import Shared exposing (link, navigation)
import Url exposing (percentEncode)
import View exposing (View)


type alias Model =
    { zoomables : List Zoomable }


type alias Zoomable =
    { id : String
    , open : Bool
    , src : String
    , alt : String
    , odd : Bool
    }


type Msg
    = ToggleZoomable String


type alias RouteParams =
    { language : String, slug : String }


page : Page.PageWithState RouteParams Data Model Msg
page =
    Page.prerender
        { head = head
        , routes = routes
        , data = data
        }
        |> Page.buildWithLocalState
            { view = view
            , init = init
            , update = update
            , subscriptions = subscriptions
            }


zoombableIdFromTitle : Maybe String -> Maybe String
zoombableIdFromTitle mbTitle =
    case mbTitle of
        Nothing ->
            Nothing

        Just title ->
            case String.split "::" title of
                mbZoomableId :: _ ->
                    case String.split "_" mbZoomableId of
                        "zoomable" :: i :: [] ->
                            Just i

                        _ ->
                            Nothing

                _ ->
                    Nothing


init : Maybe PageUrl -> Shared.Model -> StaticPayload Data RouteParams -> ( Model, Cmd Msg )
init _ _ static =
    let
        article =
            static.data

        requestedLangName =
            static.routeParams.language

        currentLanguage =
            languageFromString requestedLangName

        mbContent =
            findArticleContent currentLanguage article

        zoomables =
            case mbContent of
                Nothing ->
                    []

                Just content ->
                    case Markdown.Parser.parse content.body of
                        Err _ ->
                            []

                        Ok blocks ->
                            let
                                fb inline soFar =
                                    case inline of
                                        Block.Image src mbTitle _ ->
                                            case zoombableIdFromTitle mbTitle of
                                                Just id ->
                                                    { id = id
                                                    , open = False
                                                    , src = absoluteImagePath article.metaData.folderName src
                                                    , alt = "TBD"
                                                    , odd =
                                                        case List.head soFar of
                                                            Just prev ->
                                                                not prev.odd

                                                            Nothing ->
                                                                True
                                                    }
                                                        :: soFar

                                                Nothing ->
                                                    soFar

                                        _ ->
                                            soFar
                            in
                            Block.inlineFoldl fb [] blocks
    in
    ( { zoomables = zoomables }
    , Cmd.none
    )



-- TBD: leave absolute if starts with a slash


absoluteImagePath : String -> String -> String
absoluteImagePath articleFolder filename =
    String.join "/" [ "", "images", "articles", percentEncode articleFolder, "images", filename ]


update : PageUrl -> Maybe Browser.Navigation.Key -> Shared.Model -> StaticPayload Data RouteParams -> Msg -> Model -> ( Model, Cmd Msg )
update _ _ _ _ msg model =
    case msg of
        ToggleZoomable zoomableId ->
            let
                updateZoomable z =
                    if z.id == zoomableId then
                        { z | open = not z.open }

                    else
                        z

                updatedZoomables =
                    List.map updateZoomable model.zoomables
            in
            ( { model | zoomables = updatedZoomables }
            , Cmd.none
            )


subscriptions : Maybe PageUrl -> RouteParams -> Path -> Model -> Sub Msg
subscriptions _ _ _ _ =
    Sub.none


routes : DataSource (List RouteParams)
routes =
    let
        fromMetaData amds =
            DataSource.succeed <| List.concat <| List.map toRouteParams amds
    in
    DataSource.andThen fromMetaData articles


toRouteParams : Article -> List RouteParams
toRouteParams { metaData } =
    let
        toRP l =
            { language = languageToString l
            , slug = metaData.slug
            }
    in
    List.map toRP metaData.languages


data : RouteParams -> DataSource Data
data routeParams =
    let
        withSlug a =
            a.metaData.slug == routeParams.slug

        findArticle ass =
            case List.head <| List.filter withSlug ass of
                Just article ->
                    DataSource.succeed article

                Nothing ->
                    DataSource.fail "Article not found"
    in
    DataSource.andThen findArticle articles


head :
    StaticPayload Data RouteParams
    -> List Head.Tag
head _ =
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = "elm-pages"
        , image =
            { url = Pages.Url.external "TODO"
            , alt = "elm-pages logo"
            , dimensions = Nothing
            , mimeType = Nothing
            }
        , description = "TODO"
        , locale = Nothing
        , title = "TODO title" -- metadata.title -- TODO
        }
        |> Seo.website


type alias Data =
    Article


findArticleContent : Language -> Article -> Maybe ArticleContent
findArticleContent language article =
    List.head
        (List.filter (\c -> c.language == language) article.content)


view :
    Maybe PageUrl
    -> Shared.Model
    -> Model
    -> StaticPayload Data RouteParams
    -> View Msg
view _ _ model static =
    let
        requestedLangName =
            static.routeParams.language

        currentLanguage =
            languageFromString requestedLangName

        mbContent =
            findArticleContent currentLanguage static.data
    in
    { title = "an article"
    , body =
        case mbContent of
            Just c ->
                [ div [ class "articlePage" ] <| body static.data c static currentLanguage model ]

            Nothing ->
                [ text "not found" ]
    }


markdownView : List Zoomable -> String -> String -> Result String (List (Html Msg))
markdownView zoomables localImagesFolder markdown =
    markdown
        |> Markdown.Parser.parse
        |> Result.mapError (\error -> error |> List.map Markdown.Parser.deadEndToString |> String.join "\n")
        |> Result.andThen (Markdown.Renderer.render (customHtmlRenderer zoomables localImagesFolder))


body : Article -> ArticleContent -> StaticPayload Data RouteParams -> Language -> Model -> List (Html Msg)
body article content static currentLanguage model =
    let
        otherLanguages =
            List.map (\l -> ( l, Shared.toArticleRoute l article ))
                (Article.otherLanguagesOf article currentLanguage)

        folderName =
            percentEncode article.metaData.folderName

        localImagesFolder =
            String.join "/" [ "", "images", "articles", folderName, "images" ]
    in
    [ navigation currentLanguage otherLanguages
    , div [ class "content" ]
        [ p [ class "postedOn" ]
            [ text "posted on: "
            , text <| Date.format "EEEE, ddd MMMM y" article.metaData.published
            ]
        , h1 [] [ text content.title ]

        --, img [ src <| Article.teaserImgPath article ] []
        , case markdownView model.zoomables localImagesFolder content.body of
            Err e ->
                text e

            Ok html ->
                div [ class "articleBody" ] html
        ]
    ]


showZoomable zoomables zoomableId =
    case find (\{ id } -> id == zoomableId) zoomables of
        Just zoomable ->
            img
                [ src zoomable.src
                , onClick (ToggleZoomable zoomableId)
                , Attr.classList
                    [ ( "zoomable", True )
                    , ( "open", zoomable.open )
                    , ( "odd", zoomable.odd )
                    ]
                ]
                []

        Nothing ->
            text <| String.join "-" <| List.map .id zoomables


customHtmlRenderer : List Zoomable -> String -> Markdown.Renderer.Renderer (Html Msg)
customHtmlRenderer zoomables localImagesFolder =
    { heading =
        \{ level, children } ->
            case level of
                Block.H1 ->
                    Html.h1 [] children

                Block.H2 ->
                    Html.h2 [] children

                Block.H3 ->
                    Html.h3 [] children

                Block.H4 ->
                    Html.h4 [] children

                Block.H5 ->
                    Html.h5 [] children

                Block.H6 ->
                    Html.h6 [] children
    , paragraph = Html.p []
    , hardLineBreak = Html.br [] []
    , blockQuote = Html.blockquote []
    , strong =
        \children -> Html.strong [] children
    , emphasis =
        \children -> Html.em [] children
    , codeSpan =
        \content -> Html.code [] [ Html.text content ]
    , link =
        \link content ->
            case link.title of
                Just title ->
                    Html.a
                        [ Attr.href link.destination
                        , Attr.title title
                        ]
                        content

                Nothing ->
                    Html.a [ Attr.href link.destination ] content
    , image =
        renderImage zoomables localImagesFolder
    , text =
        Html.text
    , unorderedList =
        \items ->
            Html.ul []
                (items
                    |> List.map
                        (\item ->
                            case item of
                                Block.ListItem task children ->
                                    let
                                        checkbox =
                                            case task of
                                                Block.NoTask ->
                                                    Html.text ""

                                                Block.IncompleteTask ->
                                                    Html.input
                                                        [ Attr.disabled True
                                                        , Attr.checked False
                                                        , Attr.type_ "checkbox"
                                                        ]
                                                        []

                                                Block.CompletedTask ->
                                                    Html.input
                                                        [ Attr.disabled True
                                                        , Attr.checked True
                                                        , Attr.type_ "checkbox"
                                                        ]
                                                        []
                                    in
                                    Html.li [] (checkbox :: children)
                        )
                )
    , orderedList =
        \startingIndex items ->
            Html.ol
                (case startingIndex of
                    1 ->
                        [ Attr.start startingIndex ]

                    _ ->
                        []
                )
                (items
                    |> List.map
                        (\itemBlocks ->
                            Html.li []
                                itemBlocks
                        )
                )
    , html = Markdown.Html.oneOf []
    , codeBlock =
        \block ->
            Html.pre []
                [ Html.code []
                    [ Html.text block.body
                    ]
                ]
    , thematicBreak = Html.hr [] []
    , table = Html.table []
    , tableHeader = Html.thead []
    , tableBody = Html.tbody []
    , tableRow = Html.tr []
    , tableHeaderCell =
        \maybeAlignment ->
            let
                attrs =
                    maybeAlignment
                        |> Maybe.map
                            (\alignment ->
                                case alignment of
                                    Block.AlignLeft ->
                                        "left"

                                    Block.AlignCenter ->
                                        "center"

                                    Block.AlignRight ->
                                        "right"
                            )
                        |> Maybe.map Attr.align
                        |> Maybe.map List.singleton
                        |> Maybe.withDefault []
            in
            Html.th attrs
    , tableCell = \_ children -> Html.td [] children
    , strikethrough = Html.span [ Attr.style "text-decoration-line" "line-through" ]
    }


renderImage : List Zoomable -> String -> { b | src : String, title : Maybe String, alt : String } -> Html Msg
renderImage zoomables localImagesFolder imageInfo =
    let
        src =
            String.join "/" [ localImagesFolder, imageInfo.src ]
    in
    case imageInfo.title of
        Just title ->
            case zoombableIdFromTitle imageInfo.title of
                Just zoomableId ->
                    showZoomable zoomables zoomableId

                _ ->
                    Html.img
                        [ Attr.src src
                        , Attr.alt imageInfo.alt
                        , Attr.title title
                        ]
                        []

        Nothing ->
            Html.img
                [ Attr.src src
                , Attr.alt imageInfo.alt
                ]
                []
