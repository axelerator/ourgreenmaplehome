module Page.Index exposing (Data, Model, Msg, page)

import Article exposing (Article, ArticleContent, ArticleMetaData, languageToString)
import Browser.Navigation
import DataSource exposing (DataSource)
import Head
import Head.Seo as Seo
import Html exposing (Html, div, span, text)
import Html.Attributes exposing (class)
import Language exposing (Language(..))
import List exposing (map)
import Page exposing (Page, StaticPayload)
import Pages.PageUrl exposing (PageUrl)
import Pages.Url
import Path exposing (Path)
import Shared exposing (navigation)
import View exposing (View)


type alias Model =
    ()


type alias Msg =
    Never


type alias RouteParams =
    {}


page : Page RouteParams Data
page =
    Page.single
        { head = head
        , data = data
        }
        |> Page.buildWithLocalState
            { view = view
            , init = init
            , update = update
            , subscriptions = subscriptions
            }


init : Maybe PageUrl -> Shared.Model -> StaticPayload Data RouteParams -> ( Model, Cmd Msg )
init _ _ _ =
    ( (), Cmd.none )


update : PageUrl -> Maybe Browser.Navigation.Key -> Shared.Model -> StaticPayload Data RouteParams -> Msg -> Model -> ( Model, Cmd Msg )
update _ _ _ _ _ model =
    ( model, Cmd.none )


subscriptions : Maybe PageUrl -> RouteParams -> Path -> Model -> Sub Msg
subscriptions _ _ _ _ =
    Sub.none


type alias Data =
    List ( Article, ArticleContent )


data : DataSource Data
data =
    Article.articlesIn English


head :
    StaticPayload Data RouteParams
    -> List Head.Tag
head static =
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


view :
    Maybe PageUrl
    -> Shared.Model
    -> Model
    -> StaticPayload Data RouteParams
    -> View Msg
view maybeUrl sharedModel model static =
    { title = "BlogArticles in English"
    , body = body static
    }


body : StaticPayload Data RouteParams -> List (Html Msg)
body static =
    let
        otherLanguages =
            List.map (\l -> ( l, Shared.homeForLanguage l ))
                (Language.otherLanguages English)
    in
    [ navigation English otherLanguages
    , div [ class "articleIndex" ] <| List.map Shared.articleTeaser static.data
    ]
