{-# LANGUAGE DeriveGeneric, OverloadedStrings, DuplicateRecordFields #-}

module NLU where
  
import Data.Aeson
import qualified Data.ByteString.Lazy as B (readFile)
import GHC.Generics ( Generic )

data Usage = Usage
  { text_units :: Int
  , text_characters :: Int
  , features :: Int
  } deriving (Show, Generic)

instance FromJSON Usage
instance ToJSON Usage

data Ent = Ent
  { etp :: String
  , txt :: String
  } deriving (Show, Generic)

customEnt :: Options
customEnt = defaultOptions {fieldLabelModifier = aux} where
  aux x | x == "etp" = "type"
        | x == "txt" = "text"
        | otherwise = x

instance FromJSON Ent where
  parseJSON = genericParseJSON customEnt
instance ToJSON Ent where
  toJSON = genericToJSON customEnt
  toEncoding = genericToEncoding customEnt

data Argument = Argument
  { atext :: String
  , aloc :: [Int] 
  , aent :: [Ent]
  } deriving (Show, Generic)

customArgument :: Options
customArgument = defaultOptions {fieldLabelModifier = aux} where
  aux x | x == "atext" = "text"
        | x == "aloc" = "location"
        | x == "aent" = "entities"
        | otherwise = x

instance FromJSON Argument where
  parseJSON = genericParseJSON customArgument
instance ToJSON Argument where
  toJSON = genericToJSON customArgument
  toEncoding = genericToEncoding customArgument

data Relation = Relation
  { rtype :: String
  , sentence :: String
  , score :: Float
  , arguments :: [Argument]
  } deriving (Show, Generic)

customRelation :: Options
customRelation = defaultOptions {fieldLabelModifier = \x -> if x == "rtype" then "type" else x}

instance FromJSON Relation where
  parseJSON = genericParseJSON customRelation
instance ToJSON Relation where
  toJSON = genericToJSON customRelation
  toEncoding = genericToEncoding customRelation

data Mention = Mention
  { mtext :: String 
  , location :: [Int]
  , confidence :: Float
  } deriving (Show, Generic)

customMention :: Options
customMention = defaultOptions {fieldLabelModifier = \x -> if x == "mtext" then "text" else x}

instance FromJSON Mention where
  parseJSON = genericParseJSON customMention
instance ToJSON Mention where
  toJSON = genericToJSON customMention
  toEncoding = genericToEncoding customMention

newtype Disambiguation = Disambiguation
  {subtype :: [String]} deriving (Show, Generic)

instance FromJSON Disambiguation
instance ToJSON Disambiguation


data Entity = Entity
  { etype :: String 
  , etext :: String 
  , mentions :: [Mention]
  , disambiguation :: Disambiguation
  } deriving (Show, Generic)

customEntity :: Options
customEntity = defaultOptions {fieldLabelModifier = aux} where
  aux x | x == "etype" = "type"
        | x == "etext" = "text"
        | otherwise = x

instance FromJSON Entity where
  parseJSON = genericParseJSON customEntity
instance ToJSON Entity where
  toJSON = genericToJSON customEntity
  toEncoding = genericToEncoding customEntity


data CleanMention = CleanMention
  { cmText :: String
  , range_c :: [Int]
  , range_t :: [Int]
  } deriving (Show, Generic)

customCleanMention :: Options
customCleanMention = defaultOptions {fieldLabelModifier = aux} where
  aux x | x == "cmText" = "text"
        | x == "range_t" = "range-t"
        | x == "range_c" = "range-c"
        | otherwise = x

instance FromJSON CleanMention where
  parseJSON = genericParseJSON customCleanMention
instance ToJSON CleanMention where
  toJSON = genericToJSON customCleanMention
  toEncoding = genericToEncoding customCleanMention


data Document = Document
  { usage :: Usage
  , relations ::[Relation]
  , language :: String
  , entities :: [Entity]
  , analyzed_text :: String
  } deriving (Show, Generic)

instance FromJSON Document
instance ToJSON Document


readJSON :: FilePath -> IO (Either String Document)
readJSON path = fmap eitherDecode (B.readFile path) :: IO (Either String Document)
