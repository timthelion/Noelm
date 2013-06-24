
module Parse.Foreign (foreignDef) where

import Control.Applicative ((<$>), (<*>))
import Text.Parsec hiding (newline,spaces)

import SourceSyntax.Declaration (Declaration(ExportEvent,ImportEvent))
import Parse.Helpers
import Parse.Expression (term)
import Parse.Type
import Types.Types (signalOf)

foreignDef :: IParser (Declaration t v)
foreignDef = do try (reserved "foreign") ; whitespace
                importEvent <|> exportEvent

exportEvent :: IParser (Declaration t v)
exportEvent = do
  try (reserved "export") >> whitespace >> reserved "jsevent" >> whitespace
  js   <- jsVar    ; whitespace
  elm  <- lowVar   ; whitespace
  hasType          ; whitespace
  tipe <- typeExpr
  case tipe of
    ADTPT "Signal" [pt] ->
        either error (return . ExportEvent js elm . signalOf) (toForeignType pt)
    _ -> error "When exporting events, the exported value must be a Signal."

importEvent :: IParser (Declaration t v)
importEvent = do
  try (reserved "import") >> whitespace >> reserved "jsevent" >> whitespace
  js   <- jsVar ; whitespace
  base <- term <?> "Base case for imported signal (signals cannot be undefined)"
  whitespace
  elm  <- lowVar <?> "Name of imported signal"
  whitespace ; hasType ; whitespace
  tipe <- typeExpr
  case tipe of
    ADTPT "Signal" [pt] ->
       either error (return . ImportEvent js base elm . signalOf) (toForeignType pt)
    _ -> error "When importing events, the imported value must be a Signal."


jsVar :: IParser String
jsVar = betwixt '"' '"' $ do
  v <- (:) <$> (letter <|> char '_') <*> many (alphaNum <|> char '_')
  if v `notElem` jsReserveds then return v else
      error $ "'" ++ v ++
          "' is not a good name for a importing or exporting JS values."

jsReserveds :: [String]
jsReserveds =
    [ "null", "undefined", "Nan", "Infinity", "true", "false", "eval"
    , "arguments", "int", "byte", "char", "goto", "long", "final", "float"
    , "short", "double", "native", "throws", "boolean", "abstract", "volatile"
    , "transient", "synchronized", "function", "break", "case", "catch"
    , "continue", "debugger", "default", "delete", "do", "else", "finally"
    , "for", "function", "if", "in", "instanceof", "new", "return", "switch"
    , "this", "throw", "try", "typeof", "var", "void", "while", "with", "class"
    , "const", "enum", "export", "extends", "import", "super", "implements"
    , "interface", "let", "package", "private", "protected", "public"
    , "static", "yield"
    ]