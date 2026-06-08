{% macro clean_text(column) %}
    upper(
        regexp_replace(
            {{ column }},
            '[^a-zA-Z0-9\\s\\.!\\?]',
            ' '
        )
    )
{% endmacro %}
