-- Singular test: validate the clean_text macro by running it against known input
-- values and asserting exact expected outputs.
--
-- Test cases cover:
--   1. Special characters replaced with spaces  (e.g. #, @, -, _, /)
--   2. Lowercase letters uppercased
--   3. Allowed punctuation preserved            (. ! ?)
--   4. Mixed scenarios matching real silver field patterns
--   5. Strings that are already clean pass through unchanged
--
-- The test FAILS (returns rows) when macro output does not match expected output.

with test_cases as (

    -- ── special characters stripped and replaced with a space ─────────────────
    select 'Manufacturer#3'                         as input, 'MANUFACTURER 3'                        as expected, 'hash replaced'                  as scenario
    union all select 'Brand#34',                               'BRAND 34',                              'hash in brand code'
    union all select 'cream steel-purple',                     'CREAM STEEL PURPLE',                    'hyphen replaced'
    union all select 'economy_polished_tin',                   'ECONOMY POLISHED TIN',                  'underscores replaced'
    union all select 'large/burnished@steel',                  'LARGE BURNISHED STEEL',                 'slash and at-sign replaced'
    union all select 'nickel(brushed)',                        'NICKEL BRUSHED ',                       'parentheses replaced'
    union all select 'part[one]',                              'PART ONE ',                             'square brackets replaced'
    union all select 'value=high',                             'VALUE HIGH',                            'equals sign replaced'
    union all select 'foo&bar',                                'FOO BAR',                               'ampersand replaced'
    union all select 'hello%world',                            'HELLO WORLD',                           'percent replaced'

    -- ── lowercase uppercased ──────────────────────────────────────────────────
    union all select 'automobile',                             'AUTOMOBILE',                            'all lowercase'
    union all select 'Mixed Case String',                      'MIXED CASE STRING',                     'mixed case'
    union all select 'Already Upper',                          'ALREADY UPPER',                         'already uppercase passthrough'

    -- ── allowed punctuation preserved ────────────────────────────────────────
    union all select 'hello world.',                           'HELLO WORLD.',                          'period preserved'
    union all select 'great!',                                 'GREAT!',                                'exclamation mark preserved'
    union all select 'is this real?',                          'IS THIS REAL?',                         'question mark preserved'
    union all select 'end. Really!',                           'END. REALLY!',                          'period and exclamation preserved'

    -- ── real silver field patterns from the dataset ───────────────────────────
    union all select 'cream steel purple royal goldenrod',     'CREAM STEEL PURPLE ROYAL GOLDENROD',    'part_name no special chars'
    union all select 'MEDIUM BURNISHED COPPER',                'MEDIUM BURNISHED COPPER',               'part_type already clean'
    union all select 'Customer#000000001',                     'CUSTOMER 000000001',                    'customer name with hash'
    union all select '1-URGENT',                               '1 URGENT',                              'order priority with hyphen'
    union all select '5-LOW',                                  '5 LOW',                                 'order priority low'
    union all select 'AUTOMOBILE',                             'AUTOMOBILE',                            'market segment passthrough'

    -- ── consecutive special characters collapse into spaces ──────────────────
    union all select 'foo##bar',                               'FOO  BAR',                              'consecutive hashes become spaces'
    union all select 'a--b',                                   'A  B',                                  'consecutive hyphens become spaces'

),

results as (
    select
        input,
        expected,
        scenario,
        {{ clean_text('input') }} as actual
    from test_cases
)

select
    input,
    expected,
    actual,
    scenario
from results
where actual != expected
