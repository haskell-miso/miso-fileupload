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
module APISpec where
-----------------------------------------------------------------------------
import Data.ByteString.Lazy (ByteString)
import Data.Proxy
import Data.Text (Text)
import Servant.API
-----------------------------------------------------------------------------
-- | API definitions
type UploadAPI text file = "upload" :> QueryParam "filename" text :> ReqBody '[OctetStream] file :> PostNoContent

-- Add Raw API endpoint for serving markdown and the app
type API = (UploadAPI Text ByteString) :<|> Raw

api :: Proxy API
api = Proxy
-----------------------------------------------------------------------------
