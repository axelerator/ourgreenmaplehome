module Shared exposing (Data, Model, Msg(..), SharedMsg(..), articleTeaser, homeForLanguage, homeInOtherLanguages, link, navigation, template, toArticleRoute)

import Article exposing (Article, ArticleContent, languageToString)
import Browser.Navigation
import DataSource
import Date
import Html exposing (Attribute, Html, a, div, h1, h2, img, li, p, text, ul)
import Html.Attributes exposing (alt, class, classList, href, src, style)
import Language exposing (Language(..))
import Markdown
import Pages.Flags
import Pages.PageUrl exposing (PageUrl)
import Path exposing (Path)
import Route exposing (Route(..))
import SharedTemplate exposing (SharedTemplate)
import View exposing (View)


template : SharedTemplate Msg Model Data msg
template =
    { init = init
    , update = update
    , view = view
    , data = data
    , subscriptions = subscriptions
    , onPageChange = Just OnPageChange
    }


type Msg
    = OnPageChange
        { path : Path
        , query : Maybe String
        , fragment : Maybe String
        }
    | SharedMsg SharedMsg


type alias Data =
    ()


type SharedMsg
    = NoOp


type alias Model =
    { showMobileMenu : Bool
    }


init :
    Maybe Browser.Navigation.Key
    -> Pages.Flags.Flags
    ->
        Maybe
            { path :
                { path : Path
                , query : Maybe String
                , fragment : Maybe String
                }
            , metadata : route
            , pageUrl : Maybe PageUrl
            }
    -> ( Model, Cmd Msg )
init navigationKey flags maybePagePath =
    ( { showMobileMenu = False }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OnPageChange _ ->
            ( { model | showMobileMenu = False }, Cmd.none )

        SharedMsg globalMsg ->
            ( model, Cmd.none )


link : Route.Route -> List (Attribute msg) -> List (Html msg) -> Html msg
link route attrs children =
    Route.toLink
        (\anchorAttrs ->
            a
                (anchorAttrs ++ attrs)
                children
        )
        route


subscriptions : Path -> Model -> Sub Msg
subscriptions _ _ =
    Sub.none


data : DataSource.DataSource Data
data =
    DataSource.succeed ()


view :
    Data
    ->
        { path : Path
        , route : Maybe Route
        }
    -> Model
    -> (Msg -> msg)
    -> View msg
    -> { body : Html msg, title : String }
view sharedData page model toMsg pageView =
    { body = layout pageView.body
    , title = pageView.title
    }


layout : List (Html msg) -> Html msg
layout body =
    div [ class "everything" ]
        [ div [ class "header" ] [ h1 [] [ text "our green maple home" ] ]
        , div [ class "content" ] body
        , footer
        ]


footer : Html msg
footer =
    div [ class "footer" ]
        [ ul []
            [ li [] [ a [ href "https://www.instagram.com/OurGreenMapleHome/" ] [ instagramLogo ] ]
            ]
        ]


instagramLogo : Html msg
instagramLogo =
    img [ src "/images/instagram.svg", alt "OurGreenMapleHome on Instagram" ] []


homeForLanguage : Language -> Route
homeForLanguage language =
    case language of
        English ->
            En

        German ->
            De

        French ->
            Fr


homeInOtherLanguages : Language -> List ( Language, Route )
homeInOtherLanguages language =
    List.map (\l -> ( l, homeForLanguage l ))
        (Language.otherLanguages language)


navigation :
    Language
    -> List ( Language, Route )
    -> Html msg
navigation language otherLangs =
    let
        menuItem ( content, active ) =
            li [ classList [ ( "active", active ) ] ] [ content ]

        items =
            [ ( link (homeForLanguage language) [] [ text "Home" ], True ) ]

        listItems =
            List.map menuItem items ++ [ langSwitcher language otherLangs ]
    in
    div [ class "navigation" ]
        [ ul [] listItems ]


langSwitcher : Language -> List ( Language, Route.Route ) -> Html msg
langSwitcher currentLanguage otherLanguages =
    let
        mkLi ( l, route ) =
            li [] [ link route [] [ text <| languageToString l ] ]
    in
    li [ class "languageSwitcher" ]
        [ text <| languageToString currentLanguage
        , ul [] <| List.map mkLi otherLanguages
        ]


toArticleRoute : Language -> Article -> Route
toArticleRoute language article =
    Language___Slug_
        { slug = article.metaData.slug
        , language = languageToString language
        }


articleTeaser : ( Article, ArticleContent ) -> Html msg
articleTeaser ( article, content ) =
    let
        teaserImgUrl =
            Article.teaserImgPath article

        title =
            content.title

        excerpt =
            Article.excerpt content

        teaserBackground =
            style "background-image" ("url(" ++ teaserImgUrl ++ ")")
    in
    div [ class "articleTeaser" ]
        [ div [ class "teaserImg", teaserBackground ] []
        , div [ class "excerpt" ]
            [ div []
                [ p [ class "postedOn" ]
                    [ text <| Date.format "EEEE, ddd MMMM y" article.metaData.published
                    ]
                , h2 [] [ link (toArticleRoute content.language article) [] [ text title ] ]
                , Markdown.toHtml [] excerpt
                ]
            ]
        ]
