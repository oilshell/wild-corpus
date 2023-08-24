#!/bin/bash

written_one=0
while read line; do
    if [[ $written_one -eq 1 ]]; then
        echo -n "else "
    fi
    echo -n "if (";
    while read equiv; do
        echo -n "s = \"${equiv}\" or "
    done<<<"$( echo "$line" | sed 's/, */\n/g' )"
    echo " false) then \""$( echo "$line" | sed 's/, */\t/g' | cut -f1 )"\""
    written_one=1
done

#  if s = "char" then "signed char"
#  else if s = "int" or s = "signed" then "signed int"
#  else if s = "unsigned" then "unsigned int"
#  else if s = "long signed int" or s = "signed long" or s = "long" or s = "long int" then "signed long int"
#  else if s = "long unsigned int" or s = "unsigned long" then "unsigned long int"
#  else if s = "long long signed int" or s = "signed long long" or s = "long long int" or s = "long long" then "signed long long int"
#  else if s = "long long unsigned int" or s = "unsigned long long" then "unsigned long long int"

