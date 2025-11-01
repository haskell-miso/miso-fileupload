-----------------------------------------------------------------------------
{-# LANGUAGE CPP               #-}
{-# LANGUAGE DataKinds         #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE TypeApplications  #-}
{-# LANGUAGE TypeOperators     #-}
{-# LANGUAGE OverloadedStrings #-}
-----------------------------------------------------------------------------
-- |
-- Module      :  Main
-- Copyright   :  (C) 2016-2025 David M. Johnson
--                (C) 2025 Miksu Rankaviita
-- License     :  BSD3-style (see the file LICENSE)
-- Maintainer  :  Miksu Rankaviita
-- Stability   :  experimental
-- Portability :  non-portable
----------------------------------------------------------------------------
module Main where
----------------------------------------------------------------------------
import           Control.Monad (void)
import           Data.Function ((&))
import           Language.Javascript.JSaddle ((!), (!!), (#), JSVal, (<#))
import qualified Language.Javascript.JSaddle as J
import           Prelude hiding ((!!), null, unlines)
----------------------------------------------------------------------------
import           Miso hiding ((<#))
import qualified Miso as M
import qualified Miso.Html.Property as M
import qualified Miso.Html.Element as M
import qualified Miso.Html.Event as M
import           Miso.Lens ((.=), Lens, lens)
import           Miso.String (MisoString, unlines, null, ms)
import qualified Miso.CSS as CSS
----------------------------------------------------------------------------
import           Data.Proxy
import           Servant.Miso.Client
import           Servant.API hiding (contentType)
----------------------------------------------------------------------------
import           APISpec
----------------------------------------------------------------------------
-- | Model
newtype Model
  = Model
  { _info :: MisoString
  } deriving (Eq, Show)
----------------------------------------------------------------------------
-- | info Lens
info :: Lens Model MisoString
info = lens _info $ \r x -> r { _info = x }
----------------------------------------------------------------------------
-- | Action
data Action
  = ReadFile JSVal
  | UploadFile MisoString File
  | SetContent MisoString
  | ClickInput JSVal
  | PrintSuccess
  | PrintFail (Response MisoString)
----------------------------------------------------------------------------
-- | WASM support
#ifdef WASM
foreign export javascript "hs_start" main :: IO ()
#endif
----------------------------------------------------------------------------
-- | Main entry point
main :: IO ()
main = run $ startComponent uploadComponent
----------------------------------------------------------------------------
-- | Custom styling
css :: MisoString
css = unlines
  [ ".content-container {"
  , "  min-height: 300px;"
  , "  display: flex;"
  , "  flex-direction: column;"
  , "  justify-content: center;"
  , "}"
  , ""
  , "#codeDisplay {"
  , "  min-height: 200px;"
  , "  background-color: #f5f5f5;"
  , "  border-radius: 4px;"
  , "  padding: 1rem;"
  , "  white-space: pre-wrap;"
  , "  font-family: monospace;"
  , "}"
  ]
----------------------------------------------------------------------------
-- | Miso component
type UploadComponent = App Model Action

uploadComponent :: UploadComponent
uploadComponent = component (Model mempty) updateModel viewModel
#ifndef WASM
  { styles =
      [ Style css
      , Href "https://cdn.jsdelivr.net/npm/bulma@1.0.2/css/bulma.min.css"
      ]
  }
#endif
----------------------------------------------------------------------------
-- | Servant API client
componentProxy :: Proxy UploadComponent
componentProxy = Proxy

apiProxy :: Proxy (UploadAPI MisoString File)
apiProxy = Proxy

uploadClient
  :: (Maybe MisoString)
  -> File
  -> (Response () -> Action)
  -> (Response MisoString -> Action)
  -> Transition Model Action
uploadClient = toClient "http://localhost:8000" componentProxy apiProxy
----------------------------------------------------------------------------
-- | Update function
updateModel :: Action -> Transition Model Action
updateModel (ReadFile input) = M.withSink $ \sink -> do
  files_ <- files input
  reader <- newFileReader
  (reader <# ("onload" :: MisoString)) =<< do
    M.asyncCallback $ do
      result <- J.fromJSValUnchecked =<< reader ! ("result" :: MisoString)
      sink (SetContent result)
  case files_ of
    [] -> consoleLog "No file specified"
    file : _ -> do
      name <- J.valToStr =<< file ! ("name" :: MisoString)
      sink $ UploadFile (ms name) (File file)
      void $ reader # ("readAsText" :: MisoString) $ [file]
updateModel (UploadFile n f) =
  uploadClient (Just n) f (const PrintSuccess) PrintFail
updateModel (SetContent c) =
  info .= c
updateModel (ClickInput button) = io_ $ do
  input <- nextSibling button
  input & click ()
updateModel PrintSuccess = io_ $ consoleLog "File uploaded successfully!"
updateModel (PrintFail (Response _ _ _ body)) =
  io_ . consoleLog $ "File upload failed: " <> body
----------------------------------------------------------------------------
-- | View function
viewModel :: Model -> View Model Action
viewModel Model{..} =
  M.section_
  [ M.class_ "section"
  ]
  [ M.div_
    [ M.class_ "container"
    ]
    [ M.h1_
      [ M.class_ "title has-text-centered"
      ]
      [ "🍜 Miso File Upload example"
      ]
    , M.div_
      [ M.class_ "columns is-centered mt-5"
      ]
      [ M.div_
        [ M.class_ "column is-narrow content-container"
        ]
        [ M.div_
          [ M.class_ "field"
          ]
          [ M.div_
            [ M.class_ "control"
            ]
            [ M.button_
              [ M.class_ "button is-primary is-large"
              , M.onClickWith ClickInput
              ]
              [ "Select File" ]
            , M.input_
              [ CSS.style_ [ CSS.display "none" ]
              , M.id_ "fileReader"
              , M.type_ "file"
              , M.class_ "button is-large"
              , M.onChangeWith (const ReadFile)
              ]
            ]
          ]
        ]
      ]
    , M.div_
      [ M.class_ "column content-container"
      ]
      [ M.div_
        [ M.id_ "codeDisplay"
        , M.class_ "box"
        ]
        [ M.p_
          [ M.class_ "has-text-grey-light"
          ]
          [ M.pre_
            []
            [ M.text _info
            ]
          | not (null _info)
          ]
        ]
      ]
    ]
  ]
----------------------------------------------------------------------------
