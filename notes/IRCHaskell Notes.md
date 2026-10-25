# 📡 Haskell IRC Client — Study Notes & Code Breakdown

> [!info] Note Purpose
> Created for deep learning (no vibe-coding). Designed to be saved directly into **Obsidian**.
> Focuses on **Pattern Recognition**, **Mental Models**, and **Line-by-Line Breakdown** from absolute zero.

---

## 🧠 Core Patterns & Mental Models

Before reading the code, fix these 4 mental patterns in your head. Once you see the pattern, Haskell code reads like a map.

### Pattern 1: The Blueprint (`::`)
In Haskell, double colons `::` mean **"has the type of"** or **"is a..."**.
- `x :: String` means *"x is a piece of text"*.
- `f :: Int -> String` means *"f is a machine that turns an Integer into Text"*.

> [!tip] Pattern Recognition Rule
> Everything on the **left** of `::` is a name. Everything on the **right** of `::` is its data category (Type).

---

### Pattern 2: The Outer-World Box (`IO`)
Haskell is a **pure** language. Math functions in Haskell cannot secretly touch your hard drive, print to your screen, or talk to the internet. 

When a function needs to talk to the real world, its type is wrapped in an `IO` box:
- `IO ()` = *"Do a real-world action, and return nothing useful when done."*
- `IO Handle` = *"Talk to the real world, and give back a connection Handle."*

---

### Pattern 3: The Assembly Line (`do` and `<-`)
Normal Haskell code is pure calculations. But when you need to do sequential steps in the real world, you open a `do` block:

```haskell
do
  result <- step1   -- "Run step1 in the real world, open the box, name the inside 'result'"
  step2 result      -- "Pass 'result' into step2"
```

> [!warning] Key Distinction: `=` vs `<-`
> - `=` names a pure formula: `myServer = "irc.libera.chat"`
> - `<-` unpacks a real-world `IO` result inside a `do` block: `h <- connectTo server port`

---

### Pattern 4: The Network Phone Call (Sockets & Handles)
Connecting to an IRC server over the internet works like making a phone call:

```
[ Domain Name: irc.libera.chat ] + [ Port: 6667 ]
                       │
                       ▼  N.getAddrInfo (Look up address in phonebook)
[ Address Information (IP Address, Protocol Details) ]
                       │
                       ▼  N.socket (Create raw phone hardware)
[ Raw Socket ]
                       │
                       ▼  N.socketToHandle (Attach a readable/writable pipe)
[ Handle (A file-like pipe you read from and write to) ]
```

---

## 📝 Line-by-Line Code Breakdown (`app/Main.hs`)

Here is the complete breakdown of every single line in your program.

---

### Part 1: Module & Imports

```haskell
module Main (main) where
```
- **`module Main`**: Tells Haskell that this file is named `Main`. The `Main` module is the entry point of an executable program.
- **`(main)`**: The export list. It says *"Only let the outside world see the `main` function from this file."*
- **`where`**: Starts the contents of the module.

```haskell
import System.IO()
```
- **`import`**: Brings pre-made tools from Haskell's standard library into this file.
- **`System.IO`**: The library for handling Input and Output (reading files, printing text, handles).
- **`()`**: Empty import list. This means *"import the library module, but don't automatically import any function names into scope."* 

> [!note] Study Fix
> If you want to use functions like `hGetContents`, `stdout`, `NoBuffering`, or `ReadWriteMode`, you should write `import System.IO` (without `()`) so those function names become usable!

```haskell
import qualified Network.Socket as N
```
- **`import Network.Socket`**: Brings in network communications tools (connecting to servers, managing IP addresses).
- **`qualified ... as N`**: Prevents name collisions. Every function from this module must be written with `N.` in front of it (like `N.getAddrInfo` or `N.socket`). Think of `N.` as a folder prefix.

---

### Part 2: Configuration Settings

```haskell
myServer = "irc.libera.chat":: String 
```
- **`myServer`**: A variable name holding the IRC server address.
- **`"irc.libera.chat"`**: A literal piece of text (URL of Libera Chat IRC network).
- **`:: String`**: Explicitly tells Haskell *"This is a String type"*.

```haskell
myPort = 6667 :: N.PortNumber
```
- **`myPort`**: A variable name holding the port number.
- **`6667`**: The standard TCP port used by IRC servers for unencrypted chat connections.
- **`:: N.PortNumber`**: Tells Haskell to treat the number `6667` specifically as a network port number type defined inside `Network.Socket`.

---

### Part 3: The Main Entry Point

```haskell
main :: IO ()
main = do
```
- **`main :: IO ()`**: The signature of every runnable program in Haskell. It means: *"main performs real-world I/O actions and finishes without returning a value."*
- **`do`**: Begins a sequence of real-world steps that run one after another from top to bottom.

```haskell
    h <- connectTo myServer myPort
```
- **`connectTo myServer myPort`**: Calls our custom helper function `connectTo` passing the server name and port.
- **`h <-`**: Runs `connectTo`, receives a connected network pipe (`Handle`), unpacks it out of the `IO` wrapper, and names it **`h`**.

```haskell
    t <- hGetContents h
```
- **`hGetContents h`**: Reads all incoming text streamed through the network handle `h`.
- **`t <-`**: Stores that incoming stream of text into variable **`t`**.

```haskell
    hSetBuffering stdout NoBuffering
```
- **`hSetBuffering`**: Controls how output is sent to your terminal screen.
- **`stdout`**: Standard Output (your terminal display).
- **`NoBuffering`**: Prints text immediately character by character as soon as it arrives, instead of waiting for a full line or full buffer.

```haskell
    print t
```
- **`print t`**: Takes the stream of text `t` and outputs it to the console screen.

---

### Part 4: The Helper Function `connectTo`

```haskell
connectTo :: N.HostName -> N.PortNumber -> IO Handle
```
- **`connectTo`**: The function name.
- **`N.HostName ->`**: First input: A server address name (e.g. `"irc.libera.chat"`).
- **`N.PortNumber ->`**: Second input: A port number (e.g. `6667`).
- **`IO Handle`**: Output: A real-world `IO` action that yields an open network connection **`Handle`**.

```haskell
connectTo host port = do
```
- Defines `connectTo` with parameters `host` and `port`, opening a sequential `do` block.

```haskell
    addr : _ <- N.getAddrInfo Nothing (Just host) (Just (show port))
```
- **`show port`**: Converts the number `6667` into text `"6667"`.
- **`N.getAddrInfo`**: Looks up the network address for `host` and `port`. It returns a list of matching addresses.
- **`addr : _`**: Pattern matching on a list! `addr` gets the first address result in the list, and `:` splits it from the rest `_` (which we ignore).
- **`<-`**: Unpacks the address list from the `IO` action.

```haskell
    sock <- N.socket (N.addrFamily addr) (N.addrSocketType addr) (N.addrProtocol addr)
```
- **`N.socket`**: Creates a raw network socket using the protocol details extracted from `addr` (`addrFamily` for IPv4/IPv6, `addrSocketType` for TCP/Stream, `addrProtocol`).
- **`sock <-`**: Unpacks the newly created socket and names it `sock`.

```haskell
    N.socketToHandle sock ReadWriteMode
```
- **`N.socketToHandle`**: Converts the raw network `sock` into a standard Haskell **`Handle`** configured for both reading and writing (`ReadWriteMode`).
- Since this is the **last line** of the `do` block, its result (`IO Handle`) becomes the overall return value of `connectTo`.

---

## 🔍 Syntax Spot Check (Things to watch out for when writing by hand)

When studying or editing this file, keep an eye on these small typos that GHC (the Haskell compiler) will flag:

| Code snippet in file | Typo / Issue | Corrected Version |
| :--- | :--- | :--- |
| `addr : _ < - N.getAddrInfo` | Space in arrow `< -` | `addr : _ <- N.getAddrInfo` |
| `(n.addrFamily addr)` | Lowercase `n.` | `(N.addrFamily addr)` |
| `import System.IO()` | Empty import list `()` hides `Handle`, `hGetContents`, etc. | `import System.IO` |

---

## 🗂️ Quick Vocabulary Reference for Obsidian

- **Module**: A container/file of related code functions.
- **Type**: A label declaring what kind of data something is (`String`, `Int`, `Handle`).
- **IO**: Haskell's marker for any computation that interacts with the outside world.
- **Handle**: A stream pipe connected to a file, terminal, or network socket.
- **Socket**: The low-level operating system endpoint for sending/receiving bytes over a network.
- **Pattern Matching (`addr : _`)**: Deconstructing a data structure (like a list) to grab its first item.
