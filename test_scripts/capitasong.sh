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
    
    'a a an the and but or nor at by for from in into of off on onto out over to up upon down with as along back away un une le la les et mais ou ni à aux par pour de des du dans hors sur sous avec vers en dès sans a'
    'A a an the and but or nor at by for from in into of off on onto out over to up upon down with as along back away un une le la les et mais ou ni à aux par pour de des du dans hors sur sous avec vers en dès sans A'
    
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
)

for ((i = 0;  i < ${#_params[@]} - 1;  i += 2))
do
    : $((i / 2))
    _inp=${_params[i]}
    _out=${_params[i + 1]}
    
    test "$("$THE_SCRIPT" "$_inp")" = "$_out"
done

