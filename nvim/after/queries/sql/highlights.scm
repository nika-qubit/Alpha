;; extends

; Highlight database/project and schema/namespace identifiers in 3-part BigQuery/Spark names
(object_reference
  database: (identifier) @module)

(object_reference
  schema: (identifier) @type.definition)

(object_reference
  name: (identifier) @type)

; Default identifier fallback so identifiers inside fenced markdown blocks don't fall back to @markup.raw.block (Comment)
(identifier) @variable

; BigQuery & Spark SQL spatial functions (ST_*) and built-in functions even inside dialect clauses
((identifier) @function.call
  (#lua-match? @function.call "^[sS][tT]_"))

((identifier) @function.call
  (#any-of? @function.call
    "SAFE" "safe" "HEX" "hex" "UNHEX" "unhex" "LOWER" "lower" "UPPER" "upper"
    "COUNT" "count" "COALESCE" "coalesce" "CONCAT" "concat"))

; BigQuery & Spark SQL dialect keywords (OPTIONS, TBLPROPERTIES, DESCRIBE, EXTENDED, ICEBERG, etc.)
((identifier) @keyword
  (#any-of? @keyword
    "OPTIONS" "options" "TBLPROPERTIES" "tblproperties" "DESCRIBE" "describe"
    "EXTENDED" "extended" "FORMATTED" "formatted" "SHOW" "show" "USING" "using"
    "ICEBERG" "iceberg" "NAMESPACE" "namespace" "NAMESPACES" "namespaces"
    "TABLES" "tables" "IF" "if" "NOT" "not" "EXISTS" "exists"))

; BigQuery & Spark SQL data types (INT64, FLOAT64, GEOGRAPHY, STRING, BYTES, BIGINT, etc.)
((identifier) @type.builtin
  (#any-of? @type.builtin
    "INT64" "int64" "FLOAT64" "float64" "GEOGRAPHY" "geography" "GEOMETRY" "geometry"
    "STRING" "string" "BYTES" "bytes" "BOOL" "bool" "BOOLEAN" "boolean"
    "BIGINT" "bigint" "INT" "int" "DOUBLE" "double" "TIMESTAMP" "timestamp"
    "DATE" "date" "STRUCT" "struct" "ARRAY" "array" "JSON" "json"))
