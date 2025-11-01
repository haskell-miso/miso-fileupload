-----------------------------------------------------------------------------
{-# LANGUAGE DataKinds     #-}
{-# LANGUAGE TypeOperators #-}
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
-----------------------------------------------------------------------------
import Control.Monad.IO.Class
import qualified Data.ByteString.Char8 as C
import qualified Data.ByteString.Lazy as BL
import Data.CaseInsensitive (mk)
import Data.Proxy
import qualified Data.Text as T
import Network.Wai
import Network.Wai.Handler.Warp
import Network.Wai.Middleware.Cors
import Servant
import Servant.API
import System.Directory

import APISpec
-----------------------------------------------------------------------------
-- | Server definitions
uploadServer :: Server (UploadAPI T.Text BL.ByteString)
uploadServer fileName fileBytes = do
  case fileName of
    Nothing -> return NoContent
    Just n -> liftIO $ do
      createDirectoryIfMissing False "./uploads"
      BL.writeFile ("uploads/" ++ (T.unpack n)) fileBytes
      return NoContent
  return NoContent

staticServer :: Server Raw
staticServer = serveDirectoryWebApp "public"

server :: Server API
server = uploadServer :<|> staticServer
-----------------------------------------------------------------------------
-- | Define and run app
app :: Application
app = mw $ serve api server
  where
    mw = cors . const . Just $ 
        simpleCorsResourcePolicy {
          corsRequestHeaders = [ mk $ C.pack "Content-Type" ]
        }

main :: IO ()
main = putStrLn "Serving at http://localhost:8000/index.html" >> run 8000 app
-----------------------------------------------------------------------------
