#!/usr/bin/env bash

source $(dirname $0)/reader.sh
source $(dirname $0)/printer.sh
source $(dirname $0)/env.sh

# read
READ () {
    [ "${1}" ] && r="${1}" || READLINE
    READ_STR "${r}"
}

# eval
EVAL_AST () {
    local ast="${1}" env="${2}"
    #_pr_str "${ast}"; echo "EVAL_AST '${ast}:${r} / ${env}'"
    _obj_type "${ast}"; local ot="${r}"
    case "${ot}" in
    symbol)
        ENV_GET "${env}" "${ast}"
        return ;;
    list)
        _map_with_type _list EVAL "${ast}" "${env}" ;;
    vector)
        _map_with_type _vector EVAL "${ast}" "${env}" ;;
    hash_map)
        local res="" key= val="" hm="${ANON["${ast}"]}"
        _hash_map; local new_hm="${r}"
        eval local keys="\${!${hm}[@]}"
        for key in ${keys}; do
            eval val="\${${hm}[\"${key}\"]}"
            EVAL "${val}" "${env}"
            _assoc! "${new_hm}" "${key}" "${r}"
        done
        r="${new_hm}" ;;
    *)
        r="${ast}" ;;
    esac
}

EVAL () {
    local ast="${1}" env="${2}"
    r=
    [[ "${__ERROR}" ]] && return 1
    #_pr_str "${ast}"; echo "EVAL '${r} / ${env}'"
    _obj_type "${ast}"; local ot="${r}"
    if [[ "${ot}" != "list" ]]; then
        EVAL_AST "${ast}" "${env}"
        return
    fi
    _empty? "${ast}" && r="${ast}" && return

    # apply list
    _nth "${ast}" 0; local a0="${r}"
    _nth "${ast}" 1; local a1="${r}"
    _nth "${ast}" 2; local a2="${r}"
    case "${ANON["${a0}"]}" in
        def!) EVAL "${a2}" "${env}"
              [[ "${__ERROR}" ]] && return 1
              ENV_SET "${env}" "${a1}" "${r}"
              return ;;
        let*) ENV "${env}"; local let_env="${r}"
              local let_pairs=(${ANON["${a1}"]})
              local idx=0
              #echo "let: [${let_pairs[*]}] for ${a2}"
              while [[ "${let_pairs["${idx}"]}" ]]; do
                  EVAL "${let_pairs[$(( idx + 1))]}" "${let_env}"
                  ENV_SET "${let_env}" "${let_pairs[${idx}]}" "${r}"
                  idx=$(( idx + 2))
              done
              EVAL "${a2}" "${let_env}"
              return ;;
        *)    EVAL_AST "${ast}" "${env}"
              [[ "${__ERROR}" ]] && r= && return 1
              local el="${r}"
              _first "${el}"; local f="${r}"
              _rest "${el}"; local args="${ANON["${r}"]}"
              #echo "invoke: ${f} ${args}"
              eval ${f} ${args}
              return ;;
    esac
}

# print
PRINT () {
    if [[ "${__ERROR}" ]]; then
        _pr_str "${__ERROR}" yes
        r="Error: ${r}"
        __ERROR=
    else
        _pr_str "${1}" yes
    fi
}

# repl
ENV; REPL_ENV="${r}"
REP () {
    r=
    READ "${1}"
    EVAL "${r}" "${REPL_ENV}"
    PRINT "${r}"
}

plus     () { r=$(( ${ANON["${1}"]} + ${ANON["${2}"]} )); _number "${r}"; }
minus    () { r=$(( ${ANON["${1}"]} - ${ANON["${2}"]} )); _number "${r}"; }
multiply () { r=$(( ${ANON["${1}"]} * ${ANON["${2}"]} )); _number "${r}"; }
divide   () { r=$(( ${ANON["${1}"]} / ${ANON["${2}"]} )); _number "${r}"; }

_symbol "+";        ENV_SET "${REPL_ENV}" "${r}" plus
_symbol "-";        ENV_SET "${REPL_ENV}" "${r}" minus
_symbol "__STAR__"; ENV_SET "${REPL_ENV}" "${r}" multiply
_symbol "/";        ENV_SET "${REPL_ENV}" "${r}" divide

# repl loop
while true; do
    READLINE "user> " || exit "$?"
    [[ "${r}" ]] && REP "${r}" && echo "${r}"
done
