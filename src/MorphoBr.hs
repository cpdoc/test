{-# LANGUAGE OverloadedStrings #-}

module MorphoBr where

import Data.Either
import System.IO
import qualified Data.Map as M
import System.Directory
import System.FilePath.Posix
import qualified Data.Text as T
import qualified Data.Text.IO as TO
import Data.List (groupBy, intercalate, sort)
import Data.Maybe ( fromJust, isNothing )

member :: T.Text  -> [T.Text] -> Bool
member x [] = False
member x (y:ys) | x==y = True
                | otherwise = member x ys

lines2pairs :: [T.Text] -> [(T.Text, [T.Text])]
lines2pairs =
  map (\s -> let p = T.splitOn "\t" s in (head p, tail p))

inter :: [T.Text] -> [T.Text] -> [T.Text]
inter (x:xs) (y:ys)
 | x == y = x : inter xs ys
 | otherwise = inter xs ys
inter [] (y:ys) = []
inter (x:xs) [] = []
inter [] [] = []

simplify :: [T.Text] -> [T.Text]
simplify ms =
  map aux $ groupBy (\a b -> (head a) == (head b)) (map (T.splitOn (T.pack "+")) (sort ms))
   where
     aux ls = T.intercalate "+" $ foldl1 inter ls

readF1 :: FilePath -> IO (M.Map T.Text [T.Text])
readF1 fn = do
  content <- TO.readFile fn
  return $ M.fromListWith (++) $ lines2pairs (T.lines content)

check :: M.Map T.Text [T.Text] -> [T.Text] -> T.Text
check m xs
 | member (last xs) (fromJust (M.lookup (head xs) m)) = ""
 | otherwise = T.append (last xs) $ T.append " | " (T.intercalate " " (fromJust (M.lookup (head xs) m)))

createMap :: FilePath -> [FilePath] -> IO (M.Map T.Text [T.Text])
createMap dir paths = do
  dicts <- mapM (readF1 . combine dir) paths
  return (M.map simplify $ foldr M.union M.empty dicts)

clean :: [T.Text] -> [T.Text]
clean (x:xs)
 | x == "" = clean xs
 | otherwise = x : clean xs
clean [] = []

readD :: FilePath -> FilePath -> IO [[T.Text]]
readD mpath epath = do
  mfiles <- listDirectory mpath
  efiles <- listDirectory epath
  m <- createMap mpath mfiles
  mapM (aux m epath) efiles 
   where
     aux m dir path = do
       content <- TO.readFile $ combine dir path
       return (clean $ map (check m . (T.splitOn "\t")) (T.lines content))

