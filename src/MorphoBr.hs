{-# LANGUAGE DeriveGeneric #-}
module MorphoBr where

import Data.Either
import System.Environment 
import System.Exit 
import qualified Data.ByteString.Lazy as B
--import qualified Data.ByteString.Lazy.Char8 as LC
import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy.Char8 as C
import qualified Data.Text as T
import Data.Text.Encoding (encodeUtf8)
import Data.Char (ord)
import Data.Trie
import Data.List
import Data.Bifunctor (first)
import Data.Aeson 
import GHC.Generics
import System.Exit
import System.Environment
import Control.Applicative

data Document = 
  Document
  {classes :: [String]
  , trieList :: [(String,[String])]
  } deriving(Show, Generic)

instance FromJSON Document
instance ToJSON Document where
  toEncoding = genericToEncoding defaultOptions

packStr, packStr'' :: String -> BS.ByteString
packStr   = BS.pack . map (fromIntegral . ord)
--packStr'  = C.pack
packStr'' = encodeUtf8 . T.pack

getKey :: [(String,String)] -> [(String,[String ])]
getKey l = map aux (groupBy (\la lb -> fst la == fst lb) l) 
 where aux (x:xs) 
        | length (x:xs) == 1 = (fst x, [snd x])
        | otherwise = (fst x, map snd (x:xs))

getPairs :: String -> [(String,String )] 
getPairs xs = map (aux . words) (lines xs)
 where aux l = (head l, last l)

merge :: [(String,String )] -> [(String,String )] -> [(String,String )] 
merge (x:xs) (y:ys) = if fst x < fst y
                        then x: merge xs (y:ys)
                        else y: merge (x:xs) ys
merge [] xs = xs
merge xs [] = xs

createList :: [String] -> [(String,String)]
createList words = aux (map getPairs words)
 where aux xs = foldl merge [] xs

toDoc :: [(String,[String])] -> Document
toDoc ls = Document {classes = [], trieList = ls}


-- Recebe os arquivos (concatenados) adjectives, adverbs, nouns, verbs e uma path onde 
-- onde será escrito o JSON que contem a lista usada para criar a Trie
createTrieList :: [String] -> IO ()
createTrieList [adj,adv,noun,verb,saida] = do
    adjectives <- readFile adj
    adverbs <- readFile adv
    nouns <- readFile noun
    verbs <- readFile verb    
    encodeFile saida $ toDoc $ getKey $ createList [adjectives,adverbs,nouns,verbs]
--createTreeList _ = MorphoBr.help >> exitFailure

readJSON :: FilePath -> IO (Either String Document)
readJSON path = (eitherDecode <$> B.readFile path) :: IO (Either String Document)

getList :: Either String Document -> [(BS.ByteString,[String])]
getList (Right doc) = map (first  packStr) (trieList doc)


-- Recebe o path do JSON que contem a lista usada para criar a Trie e retorna a Trie
createTrie :: String -> IO (Trie [String])
createTrie path = do
    doc <- readJSON path
    return (fromList $  getList doc)




-- main interface 

{-
help :: IO ()
help = putStrLn "morpho-br -c [classes de palavras, onde escrever] :: [filePath]"

parse ["-h"]    = MorphoBr.help >> exitSuccess
parse ("-c":ls) = createTreeList ls >> exitSuccess

parse ls        = MorphoBr.help >> exitFailure
    
main :: IO ()
main = getArgs >>= MorphoBr.parse
-}

-- para pesquisar na arvore: lookup

