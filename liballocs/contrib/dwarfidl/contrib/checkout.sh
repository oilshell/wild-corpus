#!/bin/bash

# What I'm going to assume you have:
# 
# bash + other GNU basics
# mercurial + Hg-git
# g++ 4.8 or later
# boost 1.52 or later
# libdwarf (a recent version)
# libelf1
# antlr-3.4, including libantlr3c built & installed
# -- antlr is a never-ending nightmare. 
#    The best way seems to be
#    -- install the antlr-3.4-complete jar binary (also requires stringtemplate)
#    -- then also grab the sources, extract, and build+install just libantlr3c
#    -- I have also been applying the following patch 
#--- C/src/antlr3commontree.c    2011-07-20 19:45:03.000000000 +0100
#+++ C-modified/src/antlr3commontree.c   2012-01-11 15:18:32.000000000 +0000
#@@ -503,7 +503,9 @@
# static pANTLR3_BASE_TREE
# getParent                              (pANTLR3_BASE_TREE tree)
# {
#-	return & (((pANTLR3_COMMON_TREE)(tree->super))->parent->baseTree);
#+       if (((pANTLR3_COMMON_TREE)(tree->super))->parent)
#+               return & (((pANTLR3_COMMON_TREE)(tree->super))->parent->baseTree);
#+       else return NULL;
# }
# 
# static void

ANTLR34_PREFIX=/usr/local
STRINGTEMPLATE_PREFIX=/usr

MAKE=${MAKE:-make}

gen_makefile () {
    for basepath in "$@"; do
        echo "CXXFLAGS += -I${basepath}/include"
    done
    for basepath in "$@"; do
        echo "LDFLAGS += -L${basepath}/lib -Wl,-rpath,${basepath}/lib"
    done
    echo "include Makefile"
}

checkout () {
    hg clone git+https://github.com/stephenrkell/$1.git $1 || \
    git clone https://github.com/stephenrkell/$1.git $1
}

([ -d libcxxfileno ] || checkout libcxxfileno) && ${MAKE} -C libcxxfileno && \
([ -d libsrk31cxx  ] || checkout libsrk31cxx) && gen_makefile "$( readlink -f libcxxfileno )" > libsrk31cxx/src/makefile && ${MAKE} -C libsrk31cxx && \
([ -d libdwarfpp ] || checkout libdwarfpp) && \
  gen_makefile "$( readlink -f libcxxfileno )" "$( readlink -f libsrk31cxx )"> libdwarfpp/src/makefile && \
  gen_makefile "$( readlink -f libcxxfileno )" "$( readlink -f libsrk31cxx )"> libdwarfpp/examples/makefile && \
   ${MAKE} -C libdwarfpp && \
([ -d libcxxgen ] || checkout libcxxgen) && gen_makefile "$( readlink -f libcxxfileno )" "$( readlink -f libsrk31cxx )" "$( readlink -f libdwarfpp )"> libcxxgen/src/makefile && ${MAKE} -C libcxxgen && \
([ -d libantlr3cxx ] || checkout libantlr3cxx) && \
([ -d m4ntlr ] || checkout m4ntlr) && \
gen_makefile \
"$( readlink -f libcxxfileno )" \
"$( readlink -f libsrk31cxx )" \
"$( readlink -f libdwarfpp )" \
"$( readlink -f libcxxgen )" \
"$( readlink -f libantlr3cxx )" \
> $(dirname $0)/../src/makefile && \
echo "CLASSPATH=.:${ANTLR34_PREFIX}/share/java/antlr-3.4-complete.jar:${STRINGTEMPLATE_PREFIX}/share/java/stringtemplate.jar:
ANTLR_M4_PATH := $( readlink -f m4ntlr )

CFLAGS += -I${ANTLR34_PREFIX}
LDFLAGS += -L${ANTLR34_PREFIX}/lib -Wl,-rpath,${ANTLR34_PREFIX}/lib

include Makefile" > $(dirname $0)/../parser/makefile && \
cp $(dirname $0)/../src/makefile $(dirname $0)/../printer/makefile
