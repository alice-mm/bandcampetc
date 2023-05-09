#! /usr/bin/env bash

set -evx

readonly THE_SCRIPT=bin/capitasong

unset -v _params
# Input Output
# Input Output
# …
_params=(
    a   A
    ab  Ab
    Ab  Ab
    aB  AB
    AB  AB
    
    'a a a' 'A a A'
    'a b a' 'A B A'
    
    # “A” at the beginning and at the end
    # to dodge the “first or last word” rule.
    'a a an the and but or nor at by for from in into of off on onto out over to up upon down with as along back away un une le la les et mais ou ni à aux par pour de des du dans hors sur sous avec vers en dès sans der dem den ein eines einem einen eine einer das ein kein keine a'
    'A a an the and but or nor at by for from in into of off on onto out over to up upon down with as along back away un une le la les et mais ou ni à aux par pour de des du dans hors sur sous avec vers en dès sans der dem den ein eines einem einen eine einer das ein kein keine A'
    
    'hey come on, wake up, pack up, dude'
    'Hey Come On, Wake Up, Pack Up, Dude'
    
    "a dude's business" "A Dude's Business"
    "a dude´s business" "A Dude's Business"
    "a dude’s business" "A Dude's Business"
    
    # Hyphen.
    'a-a a'           'A-a A'
    'a- a a'          'A – A A'
    'a -a a'          'A – A A'
    'a - a a'         'A – A A'
    $'a \t - \t a a'  'A – A A'
    # En dash.
    'a–a a'           'A–a A'
    'a– a a'          'A – A A'
    'a –a a'          'A – A A'
    'a – a a'         'A – A A'
    $'a \t – \t a a'  'A – A A'
    # Em dash.
    'a—a a'           'A—a A'
    'a— a a'          'A – A A'
    'a —a a'          'A – A A'
    'a — a a'         'A – A A'
    $'a \t — \t a a'  'A – A A'
    # Minus.
    'a−a a'           'A−a A'
    'a− a a'          'A – A A'
    'a −a a'          'A – A A'
    'a − a a'         'A – A A'
    $'a \t − \t a a'  'A – A A'
    
    'Tim Bowness - the Warm-up Man Forever'
    'Tim Bowness – The Warm-Up Man Forever'
    
    'a tree tries out a dog' 'A Tree Tries Out a Dog'
    'a tree tried out a dog' 'A Tree Tried Out a Dog'
    
    'He talked back to me'          'He Talked Back to Me'
    'We were back and so were you'  'We Were back and So Were You'
    
    'This is a hold-up, yo' 'This Is a Hold-Up, Yo'
    
    'foo: the foo'  'Foo: The Foo'
    'foo - 4-3 foo' 'Foo – 4-3 Foo'
    
    ..      ..
    ...     …
    ....    …
    .....   …
    ......  …
    
    'foo...'        'Foo…'
    'foo   ...bar'  'Foo… Bar'
    'foo... a bar'  'Foo… A Bar'
    '...foo a bar'  '… Foo a Bar'
    '...a bar'      '… A Bar'
    
    'foo (a bar) plop'  'Foo (A Bar) Plop'
    'foo [a bar] plop'  'Foo [A Bar] Plop'
    'foo / a bar'       'Foo / A Bar'
    'foo/a bar'         'Foo / A Bar'
    
    'foo/bar'               'Foo / Bar'
    'foo        /   bar'    'Foo / Bar'
    'foo/bar/plop'          'Foo / Bar / Plop'
    
    '1. a tree'     '1. A Tree'
    'XIV. a tree'   'XIV. A Tree'
    
    'your mom; a dad' 'Your Mom; A Dad'
    
    'WOLVES IN THE THRONE ROOM' 'Wolves in the Throne Room'
    WOLOLOLOLO Wololololo
    SHORT SHORT
    
    'foo (bar)(plop) yo'    'Foo (Bar) (Plop) Yo'
    'foo (bar)   (plop) yo' 'Foo (Bar) (Plop) Yo'
    'foo//bar'              'Foo // Bar'
    'foo/   /bar'           'Foo // Bar'
    
    'foo bar – part mmmcmxcix' 'Foo Bar – Part MMMCMXCIX'
    # Only “mix” really causes issues; the others are not strictly
    # legal-ish Roman numerals, and dodge the regex anyway.
    'Mill Mid Mix Lid Dim Mic' 'Mill Mid Mix Lid Dim Mic'
    # Conflicts with French contractions.
    "a l'est, m'avertir d'avance, merci" "A l'Est, m'Avertir d'Avance, Merci"
    
    # Honestly not 100% sure what would be best with those, but I like this:
    "c'est l'ombre d'énormes arbres" "C'Est l'Ombre d'Énormes Arbres"
    
    'A infidèle(s) A'   'A Infidèle(s) A'
    'infidèle(s)'       'Infidèle(s)'
    'A (de)bunk A'      'A (De)bunk A'
    '(de)bunk'          '(De)bunk'
)

for ((i = 0;  i < ${#_params[@]} - 1;  i += 2))
do
    : $((i / 2))
    _inp=${_params[i]}
    _out=${_params[i + 1]}
    
    test "$("$THE_SCRIPT" "$_inp")" = "$_out"
done

