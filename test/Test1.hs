{-# LANGUAGE ForeignFunctionInterface #-}
{-# LANGUAGE TemplateHaskell #-}

module Test1 where

import           Data.ByteString (ByteString)
import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as BSL
import           Data.Monoid
import qualified Data.MessagePack as MSG
import           Control.Monad.Identity

import Foreign.C

-- import FFI.Anything.TH (deriveCallable)
import FFI.Anything.TypeUncurry.Msgpack



-- | Example function to be called from Python.
f1 :: Int -> Double -> String
f1 i f = "Called with params: " ++ show i ++ ", " ++ show f


-- To be translated to:
f1' :: ByteString -> ByteString
f1' bs = mconcat . BSL.toChunks $ MSG.pack (uncurry f1 $ msg)
  where
    msg = case MSG.tryUnpack bs of
      Left e  -> error $ "tryUnpack: " ++ e
      Right r -> r


-- TODO check who deallocs - it seems to work magically!
foreign export ccall f1_hs :: CString -> IO CString
f1_hs :: CString -> IO CString
f1_hs cs = do
    cs_bs <- BS.packCString cs
    let res_bs = f1' cs_bs
    res_cs <- BS.useAsCString res_bs return
    return res_cs


f1_identity :: Int -> Double -> Identity String
f1_identity a b = return $ f1 a b


-- Only works in GHC 7.6
-- f1_t :: CString -> IO CString
-- f1_t :: ByteString -> ByteString
-- f1_t = translateCall f1_identity

f1_t :: ByteString -> ByteString
f1_t = uncurryMsgpack f1_identity

foreign export ccall f1_t_export :: CString -> IO CString
f1_t_export :: CString -> IO CString
f1_t_export = byteStringToCStringFun f1_t



fib :: Int -> Int
fib 0 = 1
fib 1 = 1
fib n = fib (n-1) + fib (n-2)


foreign export ccall fib_export :: CString -> IO CString
fib_export :: CString -> IO CString
fib_export = export . returnId2 $ fib

-- $(deriveCallable 'f1 "f1_hs")
