# 📡 Haskell IRC Client — Study Notes & Code Breakdown

> [!info] Note Purpose
> Created for deep learning (no vibe-coding). Designed to be saved directly into **Obsidian**.
> Focuses on **Pattern Recognition**, **Mental Models**, and **Line-by-Line Breakdown** from absolute zero.

---

## 🧠 Core Patterns & Mental Models

### Pattern 1: Why Lazy Strings Fail on Networks
Standard Haskell `String` and `hGetContents` are **lazy**. They wait until data is requested before pulling it. Over a network, this causes connections to hang.
- **Old Way (Lazy)**: `hGetContents` → Hangs / doesn't stream in real time.
- **New Way (Strict ByteStrings)**: `NSB.recv sock 4096` → Directly reads available raw bytes immediately.

---

### Pattern 2: Resource Safety (`bracket`)
In languages like Python or C#, you use `try ... finally` or `using` blocks to close sockets. In Haskell, we use **`bracket`**:

```haskell
bracket acquire release use
```

```
[ 1. Acquire Resource ] ──> openConnection addr
          │
          ▼
[ 2. Use Resource ]     ──> readServer sock
          │
          ▼
[ 3. Release Resource ] ──> close sock  (Runs ALWAYS, even if crashed!)
```

---

### Pattern 3: Infinite Reading Loop (Tail Recursion)
Haskell has no `while (true)` loops. Instead, we use **recursion** (a function calling itself):

```haskell
readServer sock = do
    chunk <- NSB.recv sock 4096
    if BS.null chunk
        then putStrLn "Server closed."
        else do
            putStr (B8.unpack chunk)
            readServer sock  -- <── LOOP AGAIN!
```

---

### Pattern 4: Lambda Functions (`\x -> ...`)
A lambda is an unnamed function created on the fly.
- Syntax: `\param -> body`
- Example: `\sock -> readServer sock` means *"take `sock` and pass it to `readServer`"*.

---

## 📝 Line-by-Line Code Breakdown (`app/Main.hs`)

### Part 1: Imports & Setup

```haskell
module Main (main) where

import Control.Exception (bracket, onException)
import qualified Data.ByteString as BS
import qualified Data.ByteString.Char8 as B8
import Data.List ()
import Network.Socket
import qualified Network.Socket.ByteString as NSB
import System.IO (stdout, hSetBuffering, BufferMode(NoBuffering))
```

- **`Control.Exception`**: Gives us `bracket` (safe resource management) and `onException` (cleanup on error).
- **`Data.ByteString`**: Fast binary data arrays instead of slow linked-list `String`.
- **`Data.ByteString.Char8`**: Utilities to convert between `ByteString` bytes and ASCII text (`B8.unpack`).
- **`Network.Socket`**: Core networking library (sockets, `getAddrInfo`, `connect`, `close`).
- **`Network.Socket.ByteString`**: Sending/receiving `ByteString`s directly through sockets (`NSB.recv`).
- **`System.IO`**: Configures console buffering (`NoBuffering`).

---

### Part 2: Configuration Constants

```haskell
myServer :: HostName
myServer = "irc.libera.chat" :: HostName

myPort :: ServiceName
myPort = "6667" :: ServiceName
```

- **`HostName`**: Type alias for `String` representing a domain name.
- **`ServiceName`**: Type alias for `String` representing a port number or protocol name (e.g., `"6667"`).

---

### Part 3: `main` Program Execution

```haskell
main :: IO ()
main = withSocketsDo $ do
```
- **`withSocketsDo`**: Initializes Windows Winsock network API. Required for cross-platform network code to work on Windows.

```haskell
    hSetBuffering stdout NoBuffering
```
- Forces console output to display characters instantly as they arrive.

```haskell
    addresses <- getAddrInfo
        (Just defaultHints { addrSocketType = Stream })
        (Just myServer)
        (Just myPort)
```
- Performs DNS lookup for `irc.libera.chat:6667`.
- **`defaultHints { addrSocketType = Stream }`**: Configures the lookup specifically for **TCP** (`Stream`) connections rather than UDP (`Datagram`).

```haskell
    case addresses of
        [] -> ioError (userError "No server addresses found")

        addr : _ ->
            bracket (openConnection addr) close $ \sock -> do
                putStrLn ("Connected to " ++ myServer ++ ":" ++ myPort)
                readServer sock
```
- **`case addresses of`**: Pattern matches on the address list returned by DNS.
- **`[]`**: If no addresses found, throws an error.
- **`addr : _`**: Picks the first address.
- **`bracket (openConnection addr) close $ \sock -> ...`**:
  1. Opens socket via `openConnection addr`.
  2. Guarantees socket will be `close`d when finished.
  3. Executes `readServer sock` while connected.

---

### Part 4: Connecting the Socket (`openConnection`)

```haskell
openConnection :: AddrInfo -> IO Socket
openConnection addr = do
    sock <- socket
        (addrFamily addr)
        (addrSocketType addr)
        (addrProtocol addr)

    connect sock (addrAddress addr)
        `onException` close sock

    pure sock
```

1. **`sock <- socket ...`**: Allocates an OS network socket.
2. **`connect sock (addrAddress addr)`**: Performs the TCP handshake to establish the connection over the internet.
3. **`` `onException` close sock ``**: If the connection fails or times out, immediately closes the socket handle to prevent resource leaks.
4. **`pure sock`**: Wraps `sock` back into `IO` and returns it. (`pure` is the modern name for `return`).

---

### Part 5: The Read Loop (`readServer`)

```haskell
readServer :: Socket -> IO ()
readServer sock = do
    chunk <- NSB.recv sock 4096

    if BS.null chunk
        then putStrLn "\nServer closed the connection."
        else do
            putStr (B8.unpack chunk)
            readServer sock
```

1. **`NSB.recv sock 4096`**: Waits for up to 4096 bytes of incoming TCP data.
2. **`BS.null chunk`**: Checks if 0 bytes were received (signifies the server disconnected).
3. **`B8.unpack chunk`**: Converts raw bytes to printable text and prints to screen.
4. **`readServer sock`**: Recursively loops to wait for the next batch of server messages.

---

## 🗂️ Quick Vocabulary Reference for Obsidian

| Term | Meaning |
| :--- | :--- |
| **`ByteString`** | High-performance binary data array (replaces slow `String` for I/O). |
| **`bracket`** | Safe resource manager (`acquire -> release -> use`). |
| **`withSocketsDo`** | Windows network initialization wrapper. |
| **`NSB.recv`** | Reads raw bytes directly from a socket. |
| **`pure`** | Puts a pure value inside a monadic box (same as `return`). |
| **`\x -> ...`** | Lambda function (anonymous function). |
| **`onException`** | Runs a cleanup action if an exception occurs. |
