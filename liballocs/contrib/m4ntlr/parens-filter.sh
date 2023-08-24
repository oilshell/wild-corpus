#!/bin/bash

indent_level="-1"
print_indent () {
	for NUM in `seq 0 $indent_level`; do echo -ne '    '; done
}

while read line; do
	case "$line" in
        ('('*')')
            print_indent
            echo "$line" 
            ;;
        (')') # lone close bracket
            indent_level=$(( $indent_level - 1 ))
            print_indent
            echo "$line"
            ;; 
        (*')') # non-lone 
            print_indent
            echo "$line" | sed 's/)$//'
            indent_level=$(( $indent_level - 1 ))
            print_indent
            echo ')'
            ;;
        ('('*)
            print_indent
            indent_level=$(( $indent_level + 1 ))
            echo "$line"
            ;;
    esac
done <<<"$( sed 's/(/\n(/g' | sed 's/)/)\n/g' )"
