{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE ViewPatterns #-}

module Parsers where

import Data.Char
import Data.List
import Control.Monad
import Control.Applicative

---------------------------------------------------------
----------------- my parser combinator ------------------
---------------------------------------------------------

newtype Parser a = Parser { parse :: String -> [(a, String)]  }

parseCode :: Parser a -> String -> Either String a
parseCode m (parse m -> [(res, [])]) = Right res
parseCode _ _                        = Left "Hugh?"

instance Functor Parser where
  fmap f (Parser ps) = Parser $ \p -> [ (f a, b) | (a, b) <- ps p ]
--

instance Applicative Parser where
  pure = return
  (Parser p1) <*> (Parser p2) = Parser $ \p ->
    [ (f a, s2) | (f, s1) <- p1 p, (a, s2) <- p2 s1 ]
--

instance Monad Parser where
  return a = Parser $ \s -> [(a, s)]
  p >>= f  = Parser $ concatMap (\(a, s1) -> f a <!-- s1) . parse p
--

instance MonadPlus Parser where
  mzero     = Parser $ const []
  mplus p q = Parser $ \s -> parse p s ++ parse q s
--

instance Alternative Parser where
  empty   = mzero
  p <|> q = Parser $ \s -> case parse p s of
    [] -> parse q s
    rs -> rs
--

(<~>) :: Alternative a => a b -> a b -> a b
(<~>) = flip (<|>)

item :: Parser Char
item = Parser $ \case
  [     ] -> [      ]
  (h : t) -> [(h, t)]
--

satisfy :: (Char -> Bool) -> Parser Char
satisfy p = item >>= \c -> if p c then return c else empty

disatisfy :: (Char -> Bool) -> Parser Char
disatisfy p = satisfy $ not . p

chainl1 :: Parser a -> Parser (a -> a -> a) -> Parser a
chainl1 p op = do
  a <- p
  restOf p op a
--

restOf :: Parser a -> Parser (b -> a -> b) -> b -> Parser b
restOf p op a = return a <~> do
  f <- op
  b <- p
  restOf p op $ f a b
--

chainl2 :: Parser a -> Parser (a -> a -> a) -> Parser a
chainl2 p op = do
  a <- p
  f <- op
  b <- p
  restOf p op $ f a b
--

chainr1 :: Parser a -> Parser (a -> a -> a) -> Parser a
chainr1 p op = scan
  where
    scan = do
      a <- p
      rest a
    rest a = return a <~> do
      f <- op
      b <- scan
      rest $ f a b
--

option1 :: Parser a -> Parser (a -> a -> a) -> Parser a
option1 p op = do
  a <- p
  return a <~> do
      f <- op
      b <- p
      return $ f a b
--

option0 :: b -> Parser b -> Parser b
option0 d p = p <|> return d

chainl :: Parser a -> Parser (a -> a -> a) -> a -> Parser a
chainl p op = (chainl1 p op <|>) . return

chainr :: Parser a -> Parser (a -> a -> a) -> a -> Parser a
chainr p op = (chainr1 p op <|>) . return

bracketsHelper :: String -> [String] -> String
bracketsHelper c e
  | e  /=  [] = '(' : c ++ join e ++ ")"
  | otherwise = c ++ join e
--

bracketsHelper_ :: String -> String -> String
bracketsHelper_ c e
  | e  /=  [] = '(' : c ++ e ++ ")"
  | otherwise = c ++ e
--

-- | something similar to chainl1
chainlConnect :: Parser String -> Parser String -> Parser String
chainlConnect ep op = do
  e <- ep
  m <- many $ do
    o <- op
    e <- ep
    return $ o ++ e
  return $ e ++ join m
--

-- | something similar to chainl1
chainlWithBrackets :: Parser String -> Parser String -> Parser String
chainlWithBrackets ep op = do
  e <- ep
  m <- many $ op <++> ep
  return $ bracketsHelper e m
--

convertStringP :: String -> a -> Parser a
convertStringP = convertParserP . stringP

convertParserP :: Parser a -> b -> Parser b
convertParserP s = (s >>) . return

bracketsP :: Parser b -> Parser b
bracketsP m = do
  reservedLP "("
  n <- m
  reservedLP ")"
  return n
--

oneOf :: String -> Parser Char
oneOf = satisfy . flip elem

noneOf :: String -> Parser Char
noneOf = disatisfy . flip elem

charP :: Char -> Parser Char
charP = satisfy . (==)

oneCharP :: Parser Char
oneCharP = satisfy $ const True

oneCharPS :: Parser String
oneCharPS = do
  c <- oneCharP
  return [c]
--

exceptCharP :: Char -> Parser Char
exceptCharP = disatisfy . (==)

reservedP :: String -> Parser String
reservedP = tokenP . stringP

reservedLP :: String -> Parser String
reservedLP = tokenLP . stringP

reservedWordsLP :: [String] -> Parser String
reservedWordsLP = foldr1 (<|>) . (reservedLP <$>)

reservedWordsP :: [String] -> Parser String
reservedWordsP = foldr1 (<|>) . (reservedP <$>)

convertReservedP :: String -> String -> Parser String
convertReservedP a = tokenP . convertStringP a

convertReservedLP :: String -> String -> Parser String
convertReservedLP a = tokenLP . convertStringP a

spacesP :: Parser String
spacesP = do
  some $ oneOf " \r\t"
  return []
--

spaces0P :: Parser String
spaces0P = do
  a <- many $ oneOf " \t\r"
  return [] --- $ if null a then [] else [ head a ]
--

newLinesP :: Parser String
newLinesP = do
  some $ oneOf " \t\r\n"
  return []
--

newLines0P :: Parser String
newLines0P = do
  a <- many $ oneOf " \t\r\n"
  return [] --- $ if null a then [] else [ head a ]
--

stringP :: String -> Parser String
stringP [      ] = return []
stringP (c : cs) = do
  charP c
  stringP cs
  return $ c : cs
--

tokenP :: Parser String -> Parser String
tokenP p = do
  s <- spaces0P
  a <- p
  return $ s ++ a
--

tokenLP :: Parser String -> Parser String
tokenLP = (newLines0P <++>)

seperateP :: Parser String -> Parser String -> Parser [String]
seperateP ns ss = do
  n <- ns
  return [n] <~> do
    s <- ss
    r <- seperateP ns ss
    return $ n : s : r
--

-- | fuck ghc 8.0.1
fromRight :: b -> Either a b -> b
fromRight r (Left  _) = r
fromRight _ (Right r) = r

optionalPrefix :: String -> String
optionalPrefix [] = []
optionalPrefix ls = ls ++ " "

optionalSuffix :: String -> String
optionalSuffix [] = []
optionalSuffix ls = ' ' : ls

-- | useful aliases
(\|/) = flip seperateP
(=>>) = convertReservedP
(->>) = convertReservedLP
(<||) = parseCode
(~>)  = chainl1
(~~>) = chainl2
(<=>) = chainlConnect
(</>) = chainlWithBrackets

(<++>) :: Parser String -> Parser String -> Parser String
a <++> b = do
  x <- a
  y <- b
  return $ x ++ y
--

(<!--) :: Parser a -> String -> [(a, String)]
(<!--) = parse

(<|||) :: Parser String -> String -> IO ()
(<|||) a = putStrLn . fromRight "Parse Error" . parseCode a

digitP :: Parser Char
digitP = satisfy isDigit

infixl 2 \|/
infixl 8 </>
infixl 8 <=>
infixl 8 ~>
infixl 8 ~~>
infixl 9 ->>

-- | because <|> has 3
-- infixl 4 <++>
