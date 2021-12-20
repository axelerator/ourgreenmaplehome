module Page.Language_.Slug_ exposing (Data, Model, Msg, RouteParams, page)

import Article exposing (Article, ArticleContent, ArticleMetaData, articleMetaData, articles, languageFromString, languageToString)
import DataSource exposing (DataSource)
import Date
import Head
import Head.Seo as Seo
import Html exposing (Html, div, h1, img, li, p, text, ul)
import Html.Attributes exposing (class, classList, src)
import Language exposing (Language, otherLanguages)
import List
import Markdown exposing (toHtml)
import Page exposing (Page, StaticPayload)
import Pages.PageUrl exposing (PageUrl)
import Pages.Url
import Route exposing (Route(..))
import Shared exposing (link, navigation)
import View exposing (View)


type alias Model =
    ()


type alias Msg =
    Never


type alias RouteParams =
    { language : String, slug : String }


page : Page RouteParams Data
page =
    Page.prerender
        { head = head
        , routes = routes
        , data = data
        }
        |> Page.buildNoState { view = view }


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


view :
    Maybe PageUrl
    -> Shared.Model
    -> StaticPayload Data RouteParams
    -> View Msg
view _ _ static =
    let
        requestedLangName =
            static.routeParams.language

        currentLanguage =
            languageFromString requestedLangName

        mbContent =
            List.head
                (List.filter (\c -> c.language == currentLanguage) static.data.content)
    in
    { title = "an article"
    , body =
        case mbContent of
            Just c ->
                [ div [ class "articlePage" ] <| body static.data c static currentLanguage ]

            Nothing ->
                [ text "not found" ]
    }


body : Article -> ArticleContent -> StaticPayload Data RouteParams -> Language -> List (Html Msg)
body article content static currentLanguage =
    let
        otherLanguages =
            List.map (\l -> ( l, Shared.toArticleRoute l article ))
                (Article.otherLanguagesOf article currentLanguage)
    in
    [ navigation currentLanguage otherLanguages
    , div [ class "content" ]
        [ p [ class "postedOn" ]
            [ text "posted on: "
            , text <| Date.format "EEEE, ddd MMMM y" article.metaData.published
            ]
        , h1 [] [ text content.title ]
        , img [ src <| Article.teaserImgPath article ] []
        , toHtml [ class "articleBody" ] content.body
        ]
    ]
