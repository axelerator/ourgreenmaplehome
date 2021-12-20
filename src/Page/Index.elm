module Page.Index exposing (Data, Model, Msg, page)

import Article exposing (ArticleMetaData, languageToString)
import DataSource exposing (DataSource)
import Head
import Head.Seo as Seo
import Html exposing (Html, div, span, text)
import Language exposing (Language)
import List exposing (map)
import Page exposing (Page, StaticPayload)
import Pages.PageUrl exposing (PageUrl)
import Pages.Url
import Shared
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
        |> Page.buildNoState { view = view }


data : DataSource Data
data =
    Article.articleMetaData


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


type alias Data =
    List ArticleMetaData


view :
    Maybe PageUrl
    -> Shared.Model
    -> StaticPayload Data RouteParams
    -> View Msg
view maybeUrl sharedModel static =
    { title = "Index"
    , body = body static
    }


body : StaticPayload Data RouteParams -> List (Html Msg)
body static =
    let
        tt : String -> Language -> Html Msg
        tt slug l =
            span [] <| map text [ languageToString l, "/", slug ]

        ttt amd =
            div [] (map (tt amd.slug) amd.languages)
    in
    map ttt static.data
