module Main where

import Prelude

import Affjax as AX
import Affjax.ResponseFormat as ResponseFormat
import Data.Array ((!!))
import Data.Array.NonEmpty (NonEmptyArray, head, mapWithIndex)
import Data.Either (Either(..), hush)
import Data.HTTP.Method (Method(..))
import Data.Maybe (Maybe(..))
import Data.String (Pattern(..), split, trim)
import Data.String.Regex (match, regex)
import Data.String.Regex.Flags (global)
import Data.Traversable (sequence)
import Effect (Effect)
import Effect.Aff (launchAff_)
import Effect.Class (liftEffect)
import Effect.Class.Console (logShow)
import Node.FS.Stream (createWriteStream)
import Node.HTTP.Client (Response, requestAsStream, requestFromURI, responseAsStream)
import Node.ReadLine (createConsoleInterface, noCompletion, question, close)
import Node.Stream (Stream, Write, end, pipe)

type TrackData = {
  name :: String,
  link :: String
}

main :: Effect Unit
main = do
  interface <- createConsoleInterface noCompletion
  interface # question "Write bandcamp link: " \url -> do
    close interface

    launchAff_ do
      result <- AX.request (AX.defaultRequest { url = url, method = Left GET, responseFormat = ResponseFormat.string })
      case result of
        Left _ -> logShow "Error!"
        Right response -> 
          case getContent response.body of
            Just s -> do
              _ <- liftEffect $ sequence $ mapWithIndex downloadFile $ getRecord $ trim s
              logShow "Downloads started!"
            Nothing -> logShow "Error!"

foreign import getRecord :: String -> NonEmptyArray TrackData

downloadFile :: Int -> TrackData -> Effect Unit
downloadFile index { link, name } = do
    stream  <- createWriteStream $ "./downloads/" <> show index <> ". " <> name <> ".mp3"
    req     <- requestFromURI link $ writeStream stream
    end (requestAsStream req) (pure unit)

writeStream :: Stream ( write ∷ Write ) -> Response -> Effect Unit
writeStream ws rs = do
  _ <- pipe (responseAsStream rs) ws
  pure unit

getContent :: String -> Maybe String
getContent body = do
  r   <- hush $ regex "ld\\+json\">\\s*(.*?)\\s*<\\/script>" global
  m   <- match r body
  s   <- head m
  split (Pattern "\n") s !! 1