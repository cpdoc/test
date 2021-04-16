
module Mini where

import Data.Char (toLower)
import Data.Maybe ( catMaybes, isNothing, mapMaybe, fromJust )
import Data.Either ( lefts, rights )
import Data.List 
import Control.Applicative ( Applicative(liftA2) )
import System.Environment ( getArgs ) 
import System.Exit ( exitFailure, exitSuccess )
import Conllu.IO ( readConlluFile, writeConlluFile )
import Conllu.Type
import JsonConlluTools
import qualified Data.Trie as T
import qualified MorphoBr as M
import qualified Conllu.UposTagset as U
import qualified Conllu.DeprelTagset as D

-- map _word sents
-- colocar as classificaçoes no deps
-- pegar a palavra no form
-- comparar com feats 
search :: Maybe [String] -> String
search ls  = if isNothing ls 
              then "not found"
              else intercalate "|"  $ fromJust ls

--maybe (return "") (intercalate "|") ls

addClass :: T.Trie [String] -> CW AW -> CW AW
addClass trie word = word{_deps = [Rel{_head = SID 1 
                                      ,_deprel = D.ACL
                                      ,_subdep = Just (aux word)
                                      ,_rest= Just [""]}]}
 where 
  aux word = search $ T.lookup (M.packStr $ map toLower ( fromJust $_form word)) trie

featCheck :: T.Trie [String] -> CW AW -> CW AW
featCheck trie word
  | isNothing(_upos word)  = word
  | fromJust (_upos word) == U.VERB  = addClass trie word
  | fromJust (_upos word) == U.NOUN  = addClass trie word
  | fromJust (_upos word) == U.ADJ   = addClass trie word
  | fromJust (_upos word) == U.ADV   = addClass trie word 
  | otherwise = word

addMorphoInfo :: T.Trie [String] -> Doc -> Doc
addMorphoInfo trie = map aux
 where 
   aux :: Sent -> Sent
   aux sent =  sent { _words = map (featCheck trie) (_words sent)}

merge :: [FilePath] -> IO()
merge [clpath,jspath,outpath] = do 
  cl <- readConlluFile clpath
  tl <- M.readJSON jspath
  writeConlluFile outpath $ addMorphoInfo (T.fromList $ M.getList tl) cl 


--mapM readFile

help = putStrLn "Usage: \n\
                \ -c [classes de palavras, onde escrever] :: [filePath] \n\
                \ -r path JSON "

parse ["-h"]    = help >> exitSuccess
parse ("-c":ls) = M.createTrieList ls >> exitSuccess
parse ("-o":ls) = merge ls >> exitSuccess
parse ls        = help >> exitFailure

    
main :: IO ()
main = getArgs >>= parse
