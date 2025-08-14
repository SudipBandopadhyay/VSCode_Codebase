{% macro trip_length(column_name) -%}
    {{ return("CASE WHEN " ~ column_name ~ "<10 THEN 'Short' ELSE 'Long' END") }}
{%- endmacro %}