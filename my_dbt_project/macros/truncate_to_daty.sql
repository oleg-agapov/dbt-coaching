{% macro truncate_to_day(col) -%}
    
date_trunc('day', {{ col }})

{%- endmacro %}
