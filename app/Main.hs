module Main (main) where

import Control.Exception (bracket, onException)
import qualified Data.ByteString as BS
import qualified Data.ByteString.Char8 as B8
import Data.List ()
import Network.Socket
import qualified Network.Socket.ByteString as NSB
import System.IO ( stdout,hSetBuffering, BufferMode(NoBuffering))

myServer :: HostName
myServer = "irc.libera.chat":: HostName
myPort :: ServiceName
myPort = "6667" :: ServiceName


main :: IO ()
main = withSocketsDo $ do
    hSetBuffering stdout NoBuffering

    addresses <- getAddrInfo
        (Just defaultHints { addrSocketType = Stream })
        (Just myServer)
        (Just myPort)

    case addresses of
        [] -> ioError (userError "No server addresses found")

        addr : _ ->
            bracket (openConnection addr) close $ \sock -> do
                putStrLn ("Connected to " ++ myServer ++ ":" ++ myPort)
                readServer sock

openConnection :: AddrInfo -> IO Socket
openConnection addr = do
    sock <- socket
        (addrFamily addr)
        (addrSocketType addr)
        (addrProtocol addr)

    connect sock (addrAddress addr)
        `onException` close sock

    pure sock

readServer :: Socket -> IO ()
readServer sock = do
    chunk <- NSB.recv sock 4096

    if BS.null chunk
        then putStrLn "\nServer closed the connection."
        else do
            putStr (B8.unpack chunk)
            readServer sock