# shasm                                                 main
# machine-independant stuff; basic constants, directives...

# although...This is little-endian, which isn't machine independant. Enjoy.


                        # branch resolver state
unset Lname
declare -a Lname                # array of label names
unset there
declare -ia there               # label addresses
unset Lcount
declare -i Lcount               # number of labels
unset here
declare -i here         # the current assembly address 

                        # this is how we do binary output in sh
declare -a octalbyte=(                                          \
000 001 002 003 004 005 006 007 010 011 012 013 014 015 016 017 \
020 021 022 023 024 025 026 027 030 031 032 033 034 035 036 037 \
040 041 042 043 044 045 046 047 050 051 052 053 054 055 056 057 \
060 061 062 063 064 065 066 067 070 071 072 073 074 075 076 077 \
100 101 102 103 104 105 106 107 110 111 112 113 114 115 116 117 \
120 121 122 123 124 125 126 127 130 131 132 133 134 135 136 137 \
140 141 142 143 144 145 146 147 150 151 152 153 154 155 156 157 \
160 161 162 163 164 165 166 167 170 171 172 173 174 175 176 177 \
200 201 202 203 204 205 206 207 210 211 212 213 214 215 216 217 \
220 221 222 223 224 225 226 227 230 231 232 233 234 235 236 237 \
240 241 242 243 244 245 246 247 250 251 252 253 254 255 256 257 \
260 261 262 263 264 265 266 267 270 271 272 273 274 275 276 277 \
300 301 302 303 304 305 306 307 310 311 312 313 314 315 316 317 \
320 321 322 323 324 325 326 327 330 331 332 333 334 335 336 337 \
340 341 342 343 344 345 346 347 350 351 352 353 354 355 356 357 \
360 361 362 363 364 365 366 367 370 371 372 373 374 375 376 377 )

declare -a hex[]=(\
00 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f \
10 11 12 13 14 15 16 17 18 19 1a 1b 1c 1d 1e 1f \
20 21 22 23 24 25 26 27 28 29 2a 2b 2c 2d 2e 2f \
30 31 32 33 34 35 36 37 38 39 3a 3b 3c 3d 3e 3f \
40 41 42 43 44 45 46 47 48 49 4a 4b 4c 4d 4e 4f \
50 51 52 53 54 55 56 57 58 59 5a 5b 5c 5d 5e 5f \
60 61 62 63 64 65 66 67 68 69 6a 6b 6c 6d 6e 6f \
70 71 72 73 74 75 76 77 78 79 7a 7b 7c 7d 7e 7f \
80 81 82 83 84 85 86 87 88 89 8a 8b 8c 8d 8e 8f \
90 91 92 93 94 95 96 97 98 99 9a 9b 9c 9d 9e 9f \
a0 a1 a2 a3 a4 a5 a6 a7 a8 a9 aa ab ac ad ae af \
b0 b1 b2 b3 b4 b5 b6 b7 b8 b9 ba bb bc bd be bf \
c0 c1 c2 c3 c4 c5 c6 c7 c8 c9 ca cb cc cd ce cf \
d0 d1 d2 d3 d4 d5 d6 d7 d8 d9 da db dc dd de df \
e0 e1 e2 e3 e4 e5 e6 e7 e8 e9 ea eb ec ed ee ef \
f0 f1 f2 f3 f4 f5 f6 f7 f8 f9 fa fb fc fd fe ff )

declare -i charcount

opnote () {                             # takes a string
if test "$pass" = "2"           ;then
let charcount=32-$charcount"&"31
while test $charcount -ne 0
do
        let charcount=$charcount-1
        echo -ne " " >> a.list
done
        echo -e "       " $* >> a.list
fi      
}

                
bytes () {                              # Outputs lsByte
let here="$here+$#"
for a in $*     ;do
        echo -en \\${octalbyte[$a&0xff]} >> a.out
        echo -n ${hex[$a]}" "           >> a.list       
        charcount=$charcount+3
done    
}


duals () {
let here="$here+$#*2"
for a in $*     ;do
        echo -en \\${octalbyte[$a&0xff]}        >> a.out
        echo -en ${hex[$a&0xff]}" "             >> a.list
        echo -en \\${octalbyte[$((a>>8))&0xff]} >> a.out
        echo -en ${hex[$((a>>8))&0xff]}" "      >> a.list
        charcount=$charcount+6
done
}


quads () {
let here="$here+$#*4"
for a in $*     ;do
        echo -en \\${octalbyte[$a&0xff]}        >>      a.out
        echo -en ${hex[$a&0xff]}" "             >>      a.list
        echo -en \\${octalbyte[$((a>>8))&0xff]} >>      a.out
        echo -en ${hex[$((a>>8))&0xff]}" "      >>      a.list
        echo -en \\${octalbyte[$((a>>16))&0xff]} >>     a.out
        echo -en ${hex[$((a>>16))&0xff]}" "      >>     a.list
        echo -en \\${octalbyte[$((a>>24))&0xff]} >>     a.out
        echo -en ${hex[$((a>>24))&0xff]}" "      >>     a.list
        charcount=$charcount+12
done
}


hexquad () {    # big-endian non-spaced hex 4-byte int for $here        
        echo -en ${hex[$1>>24&0xff]}            >>      a.list
        echo -en ${hex[$1>>16&0xff]}            >>      a.list
        echo -en ${hex[$1>>8&0xff]}             >>      a.list
        echo -en ${hex[$1&0xff]}"  "            >>      a.list
}


herelist () {                   # assumes beginning of line is now
if test "$pass" = "2"                   ;then
        hexquad $here
fi
}


ascii () {
if test $pass = 2 
then 
        herelist   >> a.list
        echo "ASCII " $1 >> a.list
        echo -e $1 >> a.out
        here=$here+${#1}
else
        here=$here+${#1}
fi
}


L () {                                          # handle a label
if test "$1" = "h" ;then
echo "\n\n\n
L mylabel

is how you do labels in shasm. No colon. No lexer. L is for the usual
jumptarget: type label. You can also assign shell variables using $here.\n"
elif test "$pass" = "1" ;then
        Lname[$Lcount]=$1
        there[$Lcount]=$here
        let  Lcount=$Lcount+1
else
        herelist
        echo "                  (O) "$1 >> a.list
fi
}


branch () {                     #       branch  labelname  branchsize
if test "$1" = "h" ; then  echo "\n\n\n
The branch resolver. Called by branching opers, which pass this the label
name and branch size.\n\n"
elif test "$pass" = "1" 
then                    # on pass 1 just skip the branch byte/dual/quad
        here=$here+$2
else                            # Pass 2 is on us. Pass 1 was L.
        let labcount=0
        for lab in ${Lname[*]}  ;do
                if test $lab = $1       ;then
                        let relative=${there[$labcount]}-$here-$2
                        case $2 in 
                                1)bytes $relative               ;;      
                                2)duals $relative               ;;
                                4)quads $relative               ;;      
                                *) echo "
                                Wow. How did you manage this?" 
                                                                ;;
                        esac
                        break # out of the *LOOP* and thus the routine
                fi
        let labcount=$labcount+1
        done
fi
}


fillthru () {           # takes an integer expression. Does hex too.
if test "$1" = "h" ; then  echo -e "\n\n
this is your .org directive.
\n\n"
else
        herelist
        let tempint=$1 
        if test $pass -eq 1                                     ;then
                let here=$tempint
        else
                echo -e "  fill through "$1" \n...\n..\n." >> a.list
                if test $tempint -gt $here              ;then
                        while test $here -le $tempint   ;do
                                echo -en "\000" >> a.out
                                let here=$here+1
                        done
                else
                        echo -e "fillthru is absolute.
                        You gave a negative, less than current. No good.
                        Do the arithmatic yourself.\n\n"        
                fi
        fi
fi
}


ab () {                         # assemble bytes. pass-sensitive.
if test "$pass" = "2"   ;then
        bytes $*
else
        let here=$here+$#
fi
}



ao () {                         # output one octal char as a byte
if test "$pass" = "2"   ;then
        echo -en \\$1   >> a.out
        echo -en $1" " >> a.list
        let here=$here+1
        charcount=$charcount+4
else
        let here=$here+1
fi
}


ad () {                         # assemble duals. pass-sensitive.
if test "$pass" = "2"   ;then
        duals $*
else
        let here=$here+$#*2
fi
}


aq () {                         # assemble quads. pass-sensitive.
if test "$pass" = "2"   ;then
        quads $*
else
        let here=$here+$#*4
fi
}


ac () {                         # assemble cells. pass-cell-sensitive.
if test "$pass" = "2"    ;then
        if test "$cell" = "2" ;then
                duals $*
        else
                quads $*
        fi
else
        let here=$here+$#*$cell
fi
}


usage () {
echo -e "\n\n\n\n\n\n\n\n\n\n
The shasm command should be followed by the name of one existing file to
assemble. shasm will execute that file as a shell script. This has
security ramifications for root on multi-user systems. You can also 

        . main  

with no args and all the shasm routines will be in your shell state
as shell commands. In that case you'll get this message anyway.
Bash  set  does a nice job of indenting code, by the way.
\n
Output is the files a.out and a.list in the current working directory.
\n\n
"
}


main () {
let here=0
if test  $# -ne 1 || ! test  -f $1      ;then
        usage
else
# could loop over $* here
        . machine               # symlinked to machine/i386
        pass=1
        . $1
        let here=0
        pass=2
        . $1
fi
}


. machine

main $*                         # take a list of files?

# Rick Hohensee   www.clienux.com         address@hidden
# jan/feb  2001



#...............................................................
#...............................................................
#                                                       test

# demo nonsense code, Whitman's sampler of instructions and whatnot
#   that seem to be working currently.

fillthru 0x2ff
L bla


ascii " Oh wow. Oh wowowowowow."


fillthru 0x3ff
                
                testAND A to C
                ifzero  100
                copy  0x400 to SP
                push C
                OR A from BP

                jump bla 
                






#.............................................................
#.............................................................
                        a.list doctored a bit for mailing       

00000000    fill through 0x2ff 
...
..
.
00000300                        (O) bla
00000300  ASCII  Oh wow. Oh wowowowowow.
00000318    fill through 0x3ff 
...
..
.
00000400  85 301                                 testAND A to C
00000402  0f 84                                  ifzero 100
00000404  27 324 00 04 00 00                     copy 0x400 to SP
0000040a  121                                    push C
0000040b  09 30                                  OR A from BP
0000040d  e9 ed fe ff ff                         jump bla
...................................................................
...................................................................
##     80386 support for shasm          see Intel's 386INTEL.TXT et cetera

__=_                                    # cosmetic. modestring divider.

cell="4"                                # global, 4 or 2. 386 or real

#pass=2                                 # debugging thingies
LAAETTR=                                        # Left As An Excercise...
e () {                                          # echo abbreviation for testing 
echo $*
}


size () {                               # sh equivalent of a macro.
size[$side]=$1
}


type () {                               #
mode[$side]=$1
}

                                        
octacode () {                           # octal register char per occurance
let FR=$side*2
RFR=${registers[$side]}
register[$FR+$RFR]=$1
if test ${registers[$side]} = 0         # arrayed string arithmatic. Ick.
then                                    #  You CAN declare -ia
        registers[$side]=1
else
        registers[$side]=2
fi
}

                        # disambiguate base reg
getbase () {            # takes $source/$dest. gives $base oct
if test -n "$indexi"                    # if *2^ set an index
then                                    
        base=${register[$indexi^1]}     # base is not index
else                                    # otherwise be arbitrary
        base=${register[$1*2]}
        # if registers=2   else (leave) index=4   ???
        index=${register[$1*2+1]}
fi
}

                                # determine hi 2 bits of modR/M byte
                                # set modRM accordingly,
                                # appends to follow (SIBdisp)
modRMhi () {                            # take $source or $dest as per memref
if test "${mode[$1]}" = "dire" -o "${mode[$1]}" = ""
then
        mo=3                    # register-direct, no SIB    =  3
elif ! test -z "${number[$1]}"  
then
        if  test  "${size[$1]}" = 1     
then
                mo=1            # indirect byte displacement =  1, SIB
        else
                mo=2            # indirect cell displacement =  2, SIB
        fi
else

#############################LAAETTR
        mo=0                    # indirect no displacement   =  0, SIB
fi
}


                        # SIB maybe, and a displacement maybe.
                        # This assembles them.
SIBdisp () {                    # takes a $source/dest per memref=source/dest
if test "$mo" != "3"            ;then   # SIB?
        ao $scale${register[$indexi]}$base      # SIB
                                                # displacements 
        if test "$mo" = "1"     ;then                   # byte 
                ab ${number[$1]}                        
        fi
        if test "$mo" = "2"     ;then                   # cell 
                ac ${number[$1]}        
        fi
fi
}

                # modR/M and SIB and displacement and scale encode
modSIBdis () { # takes $source/$dest of memref and the off register/code
getbase $1      # there is no memref in direct-direct. hmmmm.
modRMhi $1
modRM=$mo$2$base                        # mid and low
ao $modRM                               # assemble octal
SIBdisp $1                              # maybe SIB, maybe displacement
}


segment () {                            # more "macro"'s
octacode $1
size 2
type segm
}


specialC () {                           #
octacode $1
type speC
}


specialD () {                           #
octacode $1
type speD
}


specialT () {                           #
octacode $1
type speT
}


small () {                              #
octacode $1
type dire
size 1
}

                # if test $cell = 4
parse () {                              #       
 if test "$1" = "h" ; then  echo -e  "\n HELP STUFF "
 else
                        ## initial oper state
source=0
register[0]=""  register[1]=""  register[2]=""  register[3]=""
mode[0]=""              mode[1]=""
size[0]=$cell           size[1]=$cell
shift="0"               index=""                indexi=""
number[0]=""            number[1]=""
registers[0]=0          registers[1]=0
side=0                  # left=0, right=1.
let sides=1
scale=0

  for arg in $*
  do
   if test "$wasshifter" = "yes"        # preempt the rest if last was *2^
        then
                wasshifter="no"
                let shift=$arg
                scale=$arg
        else
                             # Bash "set" indents nicely. I don't here.
case $arg in

to) sides=2 ; source=0 ; dest=1 ; side=1 ;;

A) octacode "0" ;;      C) octacode "1" ;;
D) octacode "2" ;;      B) octacode "3" ;;
SP) octacode "4" ;;     BP) octacode "5" ;;
SI) octacode "6" ;;     DI) octacode "7" ;;

+|@)    mode[$side]="memo"      ;;

from)   sides=2 ; side=1 ; dest=0 ; source=1    ;;

byte) size "1" ;;       dual) size "2" ;;       quad) size "4" ;;

CS) segment 1   ;;      DS)     segment 3       ;;
SS) segment 2   ;;      ES)     segment 0       ;;
FS) segment 4   ;;      GS)     segment 5       ;;

AL) small 0 ;;  CL) small 1 ;;  DL) small 2 ;;  BL) small 3 ;;
AH) small 4 ;;  CH) small 5 ;;  DH) small 6 ;;  BH) small 7 ;;

CR0) specialC 0 ;;      CR2) specialC 2 ;;      CR3) specialC 3 ;;

DR0) specialD 0 ;;      DR1) specialD 1 ;;      DR2) specialD 2 ;;
DR3) specialD 3 ;;      DR6) specialD 6 ;;      DR7) specialD 7 ;;

TR6) specialT 6 ;;      TR7) specialT 7 ;;

"*2^")  let indexi=$side*2+${registers[$side]}-1
        index=${register[$indexi]}
        wasshifter="yes"
        mode[$side]="memo"              ;;

*)     number[$side]=$arg               ;;

  esac                                  # end tokens case-switch
 fi                             # end *2^ short-circuit
done                    # end args loop, resume reasonable indentation.

        minsize=4                       # default is 4, not $cell
        if      test "${size[0]}" = 1   \
                -o   "${size[1]}" = 1 ;then
                minsize=1
        elif    test "${size[0]}" = 2   \
                -o   "${size[1]}" = 2 ;then
                minsize=2
        fi

                        # accumulate a case switch string
                                # start with sides, minsize and sourcesize
        modestring=$sides$__$minsize$__${size[$source]}

                                        # disambiguate source mode
        if ! test -z "${mode[$source]}" ;then
                modestring=$modestring$__${mode[$source]}
        elif test "${registers[$source]}" = 2   ;then
                modestring=$modestring$__"memo"
        elif ! test -z "${number[$source]}"   ;then
                modestring=$modestring$__"imme"
        else
                modestring=$modestring$__"dire"
        fi

                                        # dest size/mode if it exists
        if test "$sides" = 2 ;then              
                modestring=$modestring$__${size[$dest]}
                if ! test -z "${mode[$dest]}"   ;then
                        modestring=$modestring$__${mode[$dest]}
                elif test "${registers[$dest]}" = 2     ;then
                        modestring=$modestring$__"memo"
                else
                        modestring=$modestring$__"dire"
                fi
        fi
fi                      # end of ~help

}                   ####### end of parse  #######

##############
#####
##      prefixes and other one-zies
#

lock    () {                                            # prefix
if test "$1" = "h" ; then  echo -e  "\n\nIntel LOCK\n
SMP instruction atomicity extender.\n"
else
        herelist
        ab 0xf0
        opnote  lock    $*
fi
}


repeating       ()      {                               # prefix
if test "$1" = "h" ; then  echo -e  "\n\nIntel REP\n
repeat folowing instruction until CL is 0\n"
else
        herelist
        ab 0xf3
        opnote  repeating       $*
fi
}


repeatnon0      ()      {                               # prefix
if test "$1" = "h" ; then  echo -e  "\n\nIntel REPNZ
repeat following instruction while ZF and CL are not 0\n"
else
        herelist
        ab 0xf2
        opnote  repeatnon0      $*
fi
}


otheroperandsize        ()      {                       # prefix
if test "$1" = "h" ; then  echo -e  "\n\n\n\n
The following instruction is to be interpreted at the opposite operand
size from what the current default is, as per this segment\'s
descriptor.\n\n"
else
        herelist
        ab 0x66
        opnote          otheroperandsize $*
fi
}


otheraddresssize        ()      {                       # prefix
if test "$1" = "h" ; then  echo -e  "\n\n\n\n
following instruction is to be interpreted at the opposite address size
from what the current default is, as per this segment\'s descriptor.\n"
else
        herelist
        ab 0x67
        opnote   otheraddresssize       $*
fi
}


CS      ()      {                                       # prefix
if test "$1" = "h" ; then  echo -e  "\n\n
Following instruction is to use segment CS\n"
else
        herelist
        ab 0x2e
        opnote CS       $*
fi
}


SS      ()      {                                       # prefix
if test "$1" = "h" ; then  echo -e  "\n
\nFollowing instruction is to use segment SS\n"
else
        herelist
        ab 0x36
        opnote   SS     $*
fi
}


DS      ()      {                                       # prefix
if test "$1" = "h" ; then  echo -e  "\n
\nFollowing instruction is to use segment DS\n"
else
        herelist
        ab 0x3e
        opnote   DS     $*
fi
}


ES      ()      {                                       # prefix
if test "$1" = "h" ; then  echo -e  "\n
\nFollowing instruction is to use segment ES\n"
else
        herelist
        ab 0x26
        opnote   ES     $*
fi
}


FS      ()      {                                       # prefix
if test "$1" = "h" ; then  echo -e  "\n
\nFollowing instruction is to use segment FS\n"
else
        herelist
        ab 0x64
        opnote   FS     $*
fi
}


GS      ()      {                                       # prefix
if test "$1" = "h" ; then  echo -e  "\n
\nFollowing instruction is to use segment GS\n"
else
        herelist
        ab 0x65
        opnote   GS     $*
fi
}


# ## ## ## ## ## ## ## ## ## edit +330 machine   ## ## ## ## ## ## ##

                        # The first hairy one. Several others are minor
                        #   mods to this one; OR, add...
AND ()  {                                               #
if test "$1" = "h"      ;then  echo -e  "\n\n
Boolean bitwise AND. Result is true only if A AND B are true.

one-bit results (truth table) with input bits A and B

                            B
                        1       0
                  _|_______________
                   |
                 0 |    0       0
             A     |
                 1 |    0       1

\n"
else
        herelist
        parse $*
        case "$modestring" in
                                        # immediate byte to A
                1_1*)   ab 0x24
                        ab ${number[$source]}                   ;;
        
                                        # immediate cell to A
                1*)     ab 0x25
                        ac ${number[$source]}                   ;;
        
                                        #  immediate source byte to byte r/m
                2_1_1_imme_1_dire | 2_1_1_imme_1_memo)
                        ab 0x80
                        modSIBdis $dest 4
                        ab ${number[$source]}                   ;;
        
                                        # immediate cell to r/m cell
                2_[24]_[24]_imme_[24]_dire | 2_[24]_[24]_imme_[24]_memo)
                        ab 0x81
                        modSIBdis $dest 4
                        ac ${number[$source]}                   ;;
        
                                        # immediate source byte to cell r/m
                2_1_1_imme_[24]_dire | 2_1_1_imme_[24]_memo)
                        ab 0x83
                        modSIBdis $dest 4
                        ab ${number[$source]}                   ;;
        
                                        # reg byte source  to byte r/m
                2_1_1_dire_1_dire | 2_1_1_dire_1_memo)
                        ab 0x20
                        modSIBdis $dest ${register[$source]}    ;;
        
                                        # register cell to r/m cell
                2_[24]_[24]_dire_[24]_dire | 2_[24]_[24]_dire_[24]_memo)
                        ab 0x21
                        modSIBdis $dest ${register[$source]}    ;;
        
                                        # byte r/m source to byte reg
                                        # reg-reg already decoded as 0x20.
                                        # I think that's OK.
                2_1_1_memo_1_dire)
                        ab 0x22
                        modSIBdis $source ${register[$dest]}    ;;
        
                                        # source r/m cell to cell reg
                                        # reg-reg already decoded as 0x21.
                                        # I think that's OK.
                2_[24]_[24]_memo_[24]_dire)
                        ab 0x23
                        modSIBdis $source ${register[$dest]}    ;;
        
                *)
                        echo -e "\n\nAND doesn't support 
                                " $modestring  " mode. "                ;;
        esac
        opnote   AND    $*
fi
}


GDT     ()      {                                       #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel SGDT\n
store contents of Global Descriptor Table Register to memory at physical
address. Crucial to protected mode.\n"
else
        herelist
        parse $*
        ab 0x0f 0x01
        ac ${number[$source]}           # physical address
        opnote   GDT    $*
fi
}


IDT     ()      {                                       #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel SIDT\n
store contents of Interrupt Descriptor Table Register to memory at
physical address. Crucial to protected mode.\n"
else
        herelist
        parse $*
        ab 0x0f 1
        ac ${number[$source]}           # physical address
        opnote   IDT    $*
fi
}


LDT     ()      {                                       #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel SLDT\n
store Local Descriptor Table Register to memory physical address.\n\n"
else
        herelist
        parse $*
        ab 0x0f 0
        ac ${number[$source]}           # physical address
        opnote   LDT    $*
fi
}


LS1bit  ()      {                                       #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel BSF\n
Find least significant ON-bit. 10 clocks +. Result is the number
of leading 0 bits.\n\n"
else
        herelist
        parse $*
        ab 0x0f 0xbc
        modSIBdis $source ${register[$dest]}
        opnote   LS1bit $*
fi
}


MS1bit  ()      {                                       #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel BSR\n
0F      r32,r/m32  10+3n     Bit scan reverse on r/m cell
Find most significant ON-bit. 10 + \(3 x offbits\) clocks.
Flags effected:  Zero\n\n"
else
        herelist
        ab 0x0f 0xbd
        parse $*
        modSIBdis $source ${register[$dest]}
        opnote   MS1bit $*
fi
}


XOR     ()      {                                       #
if test "$1" = "h" ; then  echo -e  "\n
Boolean bitwise Exclusive-OR. Result is true if exclusively A OR B is
true.   A XOR 1  toggles A, for example.

one-bit results (truth table) with input bits A and B

                            B
                        1       0
                  _|_______________
                   |
                 0 |    1       0
             A     |
                 1 |    0       1
\n\n"
else
        herelist
        parse $*
        case $modestring in
                                        # immediate byte to A
                1_1*)   ab 0x34
                        ab ${number[$source]}                   ;;
        
                                        # immediate cell to A
                1*)     ab 0x35
                        ac ${number[$source]}                   ;;
        
                                        #  immediate source byte to byte r/m
                2_1_1_imme_1_dire | 2_1_1_imme_1_memo)
                        ab 0x80
                        modSIBdis $dest 6
                        ab ${number[$source]}                   ;;
        
                                        # immediate cell to r/m cell
                2_[24]_[24]_imme_[24]_dire | 2_[24]_[24]_imme_[24]_memo)
                        ab 0x81
                        modSIBdis $dest 6
                        ac ${number[$source]}                   ;;
        
                                        # immediate source byte to cell r/m
                2_1_1_imme_[24]_dire | 2_1_1_imme_[24]_memo)
                        ab 0x83
                        modSIBdis $dest 6
                        ab ${number[$source]}                   ;;
        
                                        # reg byte source  to byte r/m
                2_1_1_dire_1_dire | 2_1_1_dire_1_memo)
                        ab 0x30
                        modSIBdis $dest ${register[$source]}    ;;
        
                                        # register cell to r/m cell
                2_[24]_[24]_dire_[24]_dire | 2_[24]_[24]_dire_[24]_memo)
                        ab 0x31
                        modSIBdis $dest ${register[$source]}    ;;
        
                                        # byte r/m source to byte reg
                                        # reg-reg already decoded as 0x20.
                                        # I think that's OK.
                2_1_1_memo_1_dire)
                        ab 0x32
                        modSIBdis $source ${register[$dest]}    ;;
        
                                        # source r/m cell to cell reg
                                        # reg-reg already decoded as 0x21.
                                        # I think that's OK.
                2_[24]_[24]_memo_[24]_dire)
                        ab 0x33
                        modSIBdis $source ${register[$dest]}    ;;
        
                *)
                        echo -e "\n\nXOR doesn't support 
                        " $modestring " mode. " ;;
        esac
        opnote   XOR    $*
fi
}


OR      ()      {                                       #
if test "$1" = "h" ; then  echo -e  "\n\n
Boolean bitwise OR. AKA "inclusive OR". If either source bit, A OR B, is
1, then result is 1.

one-bit results (truth table) with input bits A and B

                            B
                        1       0
                  _|_______________
                   |
                 0 |    1       0
             A     |
                 1 |    1       1

\n"
else
        herelist
        parse $*
        case $modestring in
                                        # immediate byte to A
                1_1*)   ab 0x0c
                        ab ${number[$source]}                   ;;
        
                                        # immediate cell to A
                1*)     ab 0x0d
                        ac ${number[$source]}                   ;;
        
                                        #  immediate source byte to byte r/m
                2_1_1_imme_1_dire | 2_1_1_imme_1_memo)
                        ab 0x80
                        modSIBdis $dest 1
                        ab ${number[$source]}                   ;;
        
                                        # immediate cell to r/m cell
                2_[24]_[24]_imme_[24]_dire | 2_[24]_[24]_imme_[24]_memo)
                        ab 0x81
                        modSIBdis $dest 1
                        ac ${number[$source]}                   ;;
        
                                        # immediate source byte to cell r/m
                2_1_1_imme_[24]_dire | 2_1_1_imme_[24]_memo)
                        ab 0x83
                        modSIBdis $dest 1
                        ab ${number[$source]}                   ;;
        
                                        # reg byte source  to byte r/m
                2_1_1_dire_1_dire | 2_1_1_dire_1_memo)
                        ab 0x08
                        modSIBdis $dest ${register[$source]}    ;;      
        
                                # register cell to r/m cell
                2_[24]_[24]_dire_[24]_dire | 2_[24]_[24]_dire_[24]_memo)
                        ab 0x09
                        modSIBdis $dest ${register[$source]}    ;;
        
                                        # byte r/m source to byte reg
                                        # reg-reg already decoded as 0x20.
                                        # I think that's OK.
                2_1_1_memo_1_dire)
                        ab 0x0a
                        modSIBdis $source ${register[$dest]}    ;;      
        
                                        # source r/m cell to cell reg
                                        # reg-reg already decoded as 0x21.
                                        # I think that's OK.
                2_[24]_[24]_memo_[24]_dire)
                        ab 0x08
                        modSIBdis $source ${register[$dest]}    ;;
        
                *)
                        echo -e "\n\nOR doesn't support 
                                " $modestring " mode. " ;;
        esac
        opnote   OR     $*
fi
}

add     ()      {                                       #
if test "$1" = "h" ; then  echo -e  "\n\n
add without including the carry (flag) bit. \n  "
else
        herelist
        parse $*
        case $modestring in
                                        # immediate byte to A
                1_1*)   ab 0x04
                        ab ${number[$source]}                   ;;
        
                                        # immediate cell to A
                1*)     ab 0x05
                        ac ${number[$source]}                   ;;
        
                                        #  immediate source byte to byte r/m
                2_1_1_imme_1_dire | 2_1_1_imme_1_memo)
                        ab 0x80
                        modSIBdis $dest 0
                        ab ${number[$source]}                   ;;
        
                                        # immediate cell to r/m cell
                2_[24]_[24]_imme_[24]_dire | 2_[24]_[24]_imme_[24]_memo)
                        ab 0x81
                        modSIBdis $dest 0
                        ac ${number[$source]}                   ;;
        
                                        # immediate source byte to cell r/m
                2_1_1_imme_[24]_dire | 2_1_1_imme_[24]_memo)
                        ab 0x83
                        modSIBdis $dest 0
                        ab ${number[$source]}                   ;;
        
                                        # reg byte source  to byte r/m
                2_1_1_dire_1_dire | 2_1_1_dire_1_memo)
                        ab 0x00
                        modSIBdis $dest ${register[$source]}    ;;
        
                                        # register cell to r/m cell
                2_[24]_[24]_dire_[24]_dire | 2_[24]_[24]_dire_[24]_memo)
                        ab 0x01
                        modSIBdis $dest ${register[$source]}    ;;
        
                                        # byte r/m source to byte reg   
                                        # reg-reg already decoded as 0x20.
                                        # I think that's OK.
                2_1_1_memo_1_dire)
                        ab 0x02
                        modSIBdis $source ${register[$dest]}    ;;
        
                                        # source r/m cell to cell reg
                                        # reg-reg already decoded as 0x21.
                                        # I think that's OK.
                2_[24]_[24]_memo_[24]_dire)
                        ab 0x03
                        modSIBdis $source ${register[$dest]}    ;;
        
                *)
                echo -e "\n\nadd doesn't support 
                        " $modestring " mode. " ;;
        esac
        opnote   add    $*
fi
}


addwithcarry    ()      {                               #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel ADC\n
add including the pre-existing carry (flag) bit.\n\n"
else
        herelist
        parse $*
        case $modestring in
                                        # immediate byte to A
                1_1*)   ab 0x14
                        ab ${number[$source]}                   ;;
        
                                        # immediate cell to A
                1*)     ab 0x15
                        ac ${number[$source]}                   ;;
        
                                        #  immediate source byte to byte r/m
                2_1_1_imme_1_dire | 2_1_1_imme_1_memo)
                        ab 0x80
                        modSIBdis $dest 2
                        ab ${number[$source]}                   ;;
        
                                        # immediate cell to r/m cell
                2_[24]_[24]_imme_[24]_dire | 2_[24]_[24]_imme_[24]_memo)
                        ab 0x81
                        modSIBdis $dest 2
                        ac ${number[$source]}                   ;;
        
                                        # immediate source byte to cell r/m
                2_1_1_imme_[24]_dire | 2_1_1_imme_[24]_memo)
                        ab 0x83
                        modSIBdis $dest 2
                        ab ${number[$source]}                   ;;
        
                                        # reg byte source  to byte r/m
                2_1_1_dire_1_dire | 2_1_1_dire_1_memo)
                        ab 0x10
                        modSIBdis $dest ${register[$source]}    ;;
        
                                        # register cell to r/m cell
                2_[24]_[24]_dire_[24]_dire | 2_[24]_[24]_dire_[24]_memo)
                        ab 0x11
                        modSIBdis $dest ${register[$source]}    ;;
        
                                        # byte r/m source to byte reg
                                        # reg-reg already decoded as ??
                                        # I think that's OK.
                2_1_1_memo_1_dire)
                        ab 0x12
                        modSIBdis $source ${register[$dest]}    ;;
        
                                        # source r/m cell to cell reg
                                        # reg-reg already decoded as ??
                                        # I think that's OK.
                2_[24]_[24]_memo_[24]_dire)
                        ab 0x13
                        modSIBdis $source ${register[$dest]}    ;;
                *)
                        echo -e "\n\n\naddwithcarry doesn't support 
                        " $modestring " mode. " ;;
        esac
        opnote   addwithcarry   $*
fi
}


biton   ()      {                                       #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel BTS\n
Save bit in carry flag and set addressed bit to 1 in source value. 6
clocks.\n\n"
else
        herelist
        parse $*
        case $modestring in
                                        # immediate cell to r/m cell
                2_[24]_[24]_imme_[24]_dire | 2_[24]_[24]_imme_[24]_memo)
                        ab 0x0f 0xba
                        modSIBdis $dest 5
                        ac ${number[$source]}                   ;;
        
                                        # register cell to r/m cell
                2_[24]_[24]_dire_[24]_dire | 2_[24]_[24]_dire_[24]_memo)
                        ab 0x0f 0xab
                        modSIBdis $dest ${register[$source]}    ;;
                *)
                        echo -e "\n\nbiton doesn't support 
                                " $modestring " mode. " ;;
        esac
        opnote  biton   $*
fi
}


bitoff  () {                                            #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel BTR\n
Save bit in carry flag and reset to 0.\n\n"
else
        herelist
        parse $*
        case $modestring in
                                        # immediate cell to r/m cell
                2_[24]_[24]_imme_[24]_dire | 2_[24]_[24]_imme_[24]_memo)
                        ab 0x0f 0xba
                        modSIBdis $dest 6
                        ac ${number[$source]}                   ;;
        
                                        # register cell to r/m cell
                2_[24]_[24]_dire_[24]_dire | 2_[24]_[24]_dire_[24]_memo)
                        ab 0x0f 0xb3
                        modSIBdis $dest ${register[$source]}    ;;
                *)
                        echo -e "\n\nbitoff doesn't support 
                                " $modestring " mode. \n" ;;
        esac
        opnote   bitoff $*
fi
}


call    ()      {       # jsr, splice,                  #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel CALL\n\n\n
 Jump to the immediately following address or other value, normally that
of a subroutine, stacking a frame to return to or occurance of the return
(Intel RET) instruction. Frames vary widely by type of call on 386+. There
are intersegment jumps, which are selectors defining gates of various
types in (32 bit) protected mode. call or similar is also known as jsr or
gosub on other machines. The variants of call usually require a FAR
syntactic spamatazoan in other assemblers. shasm syntaxes for the more
mutated forms of call are...

Call intersegment to full pointer given, shasm syntax...         
                  segment       offset
        call dual 0xxxx to quad 0xxxxx

LAAETTR (gas doesn't do segments explicitly either, IIRC. Nor do most
other CPUs, BTW.)\n\n"
 else
        herelist
        parse $*
        case $modestring in
                1_[24]_[24]_imme)               # same segment relative
                        ab 0xe8
                        branch $1 $cell         ;;

                                                # same segment from reg
                1_[24]_[24]_dire)
                        ab 0xff
                        modSIBdis  $source 2    ;;
        
                                                # other segment from mem
                1_[24]_[24]_memo)
                        ab 0xff 
                        modSIBdis $source 3     ;;

                2_[24]_[2]_imme_[24]_imme)      # possible??????        
                        ab 0x9a
                        ad ${number[$source]}
                        ac ${number[$dest]}     ;;

                *)
                        echo -e "\n\ncall doesn't support 
                                        " $modestring " mode. " ;;
        esac
        opnote   call   $*
fi
}


clearswitched   ()      {                               #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel CLTS\n
clear the task-switched flag in EFLAGS. Ha3sm doesn't use the 386
task-switch facilities, BTW. Most 386 unices do, I think.\n\n"
else 
        herelist
        ab 0x0f 6
        opnote   clearswitched  $*
fi
}


copy    () {                                            #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel MOV\n
catch-all.\n\n\n"
else
        herelist
        parse $*
        case $modestring in
                *speC)  ab 0x0f 0x22
                        modSIBdis $source ${register[$dest]}    ;;

                *speD)  ab 0x0f 0x23
                        modSIBdis $source ${register[$dest]}    ;;

                *speT)  ab 0x0f 0x26
                        modSIBdis $source ${register[$dest]}    ;;

                *speC_*)        ab 0x0f 0x20            
                        modSIBdis $dest ${register[$source]}    ;;

                *speD_*)        ab 0x0f 0x21            
                        modSIBdis $dest ${register[$source]}    ;;

                *speT_*)        ab 0x0f 0x24
                        modSIBdis $dest ${register[$source]}    ;;

                2_1_1_memo_1_dire)
                        if test "${registers[$dest]}" = "0";then        
                                ab 0xa0                 
                                ab ${number[$source]}   
                        else
                                ab 0x8a
                                modSIBdis $source ${register[$dest]}    
                        fi                      ;;

                                        # source r/m cell to cell reg
                                        # reg-reg already decoded as ??
                                        # I think that's OK.
                2_[24]_[24]_memo_[24]_dire)
                        if test "${registers[$dest]}" = "0";then        
                                ab 0xa1                 
                                ac ${number[$source]}   
                        else
                                ab 0x8b
                                modSIBdis $source ${register[$dest]}    
                        fi                      ;;

                                        # immediate cell to r/m cell
                2_[24]_[24]_imme_[24]_dire)
                        if test "${registers[$dest]}" = "0";then        
                                ab 0xa1                 
                                ac ${number[$source]}   
                        else
                                ao 27${register[source]}
                                modSIBdis $dest 2
                                ac ${number[$source]}                   
                        fi       ;;

                2_1_1_dire_1_memo)
                        if test "${registers[$dest]}" = "0";then        
                                ab 0xa2                 
                                ab ${number[$dest]}     
                        else
                                ab 0x88
                                modSIBdis $dest ${register[$source]}
                        fi       ;;

        
                                        # register cell to r/m cell
                2_[24]_[24]_dire_[24]_memo)
                        if test "${registers[$dest]}" = "0";then        
                                ab 0xa3                 
                                ac ${number[$dest]}     
                        else
                                ab 0x89
                                modSIBdis $dest ${register[$source]}
                        fi       ;;


                        #  immediate source byte to byte r/m
                2_1_1_imme_1_dire)
                        ao 26${register[source]}
                        modSIBdis $dest 2
                        ab ${number[$source]}                   ;;

                2_1_1_imme_1_memo)
                        ab 0xc6
                        modSIBdis $dest 2      # 2 is a don't care I hope
                        ab ${number[$source]}                   ;;

                                        # immediate cell to r/m cell
                2_[24]_[24]_imme_[24]_memo)
                        ab 0xc7
                        modSIBdis $dest 2
                        ac ${number[$source]}                   ;;

                                        # r/m to segment reg    
                2_?_?_memo_?_segm)
                        ab 0x8d
                        modSIBdis $dest 2
                        ac ${number[$source]}                   ;;
        
                                        # segment reg to r/m
                2_?_?_segm_?_memo)
                        ab 0x8c
                        modSIBdis $dest 2
                        ac ${number[$source]}                   ;;

                *)      
                        echo -e  "\n\ncopy doesn't support " \
                                $modestring     " mode. " ;;
        esac
        opnote   copy   $*
fi
}


copyextend      () {                                    #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel MOVSX\n
copy, sign-extending the destination.\n\n"
 else
        herelist
        parse $*
        case $modestring in
                2_1_1_memo*)    ab 0x0f 0xbe
                        modSIBdis $source ${register[$dest]}    ;;
        
                2_2_2_memo*)    ab 0x0f 0xbf
                        modSIBdis $source ${register[$dest]}    ;;

                *)
                        echo -e  "\n\ncopyextend doesn't support 
                                " $modestring " mode. " ;;
        esac
        opnote   copyextend     $*
fi
}


copy0extend     () {                                    #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel MOVZX\n
copy, filling the high-order bits of the destination with zeros. Much
different than a less-than-whole-register copy.\n\n\n"
 else
        herelist
        parse $*
        case $modestring in
                2_1_1_memo*)    ab 0x0f 0xb6
                        modSIBdis $source ${register[$dest]}    ;;

        2_2_2_memo*)    ab 0x0f 0xb7
                modSIBdis $source ${register[$dest]}            ;;

        *)
                echo -e  "\n\ncopy0extend doesn't support 
                        " $modestring " mode. "                 ;;
        esac
        opnote   copy0extend    $*
fi
}


downroll        ()      {                               #       
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel ROR\n
down-significance roll, rotate. "source register" must be CL, the
roll amount. \n\n\n"
 else
        herelist
        parse $*
        case $modestring in
                2_[24]_[24]_imme_[24]_memo)
                        ab 0xc1
                        modSIBdis $dest 1
                        ab ${number[$source]}   ;;
        
                1_1_1_memo)
                        ab 0xd0 
                        modSIBdis $dest 1       ;;
        
                2_1_1_dire*)    # source is CL  
                        ab 0xd2
                        modSIBdis $dest 1       ;;
        
                2_1_1_imme_1_memo)
                        ab 0xc0         
                        modSIBdis $dest 1
                        ab ${number[$source]}   ;;
        
                1_[24]_[24]_memo)
                        ab 0xd1
                        modSIBdis $dest 1       ;;
        
                2_[24]_[24]_dire*)      # source is CL  
                        ab 0xd3
                        modSIBdis $dest 1       ;;
        
                *)
                        echo -e  "\n\ndownroll doesn't support 
                        " $modestring  "mode. " ;;
        esac
        opnote  downroll        $*
fi
}


downrollcarry   ()      {                               #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel RCR\n

down-significance roll, rotate. The carry bit is part of the roll.\n\n\n"
 else
        herelist
        parse $*
        case $modestring in
                2_[24]_[24]_imme_[24]_memo)
                        ab 0xc1
                        modSIBdis $dest 3
                        ab ${number[$source]}   ;;
        
                1_1_1_memo)
                        ab 0xd0 
                        modSIBdis $dest 3       ;;
        
                2_1_1_dire*)    # source is CL  
                        ab 0xd2
                        modSIBdis $dest 3       ;;
        
                2_1_1_imme_1_memo)
                        ab 0xc0         
                        modSIBdis $dest 3
                        ab ${number[$source]}   ;;
        
                1_[24]_[24]_memo)
                        ab 0xd1
                        modSIBdis $dest 3       ;;
        
                2_[24]_[24]_dire*)      # source is CL  
                        ab 0xd3
                        modSIBdis $dest 3       ;;

                *)
                        echo -e "\n\ndownrollcarry doesn't support 
                        " $modestring " mode. " ;;
        esac
        opnote   downrollcarry  $*
fi
}


downshift       ()      {                               #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel SAR\n
down-significance bitshift.\n"
else
        herelist
        parse $*
        case $modestring in
                2_[24]_[24]_imme_[24]_memo)
                        ab 0xc1
                        modSIBdis $dest 7
                        ab ${number[$source]}   ;;
        
                1_1_1_memo)
                        ab 0xd0 
                        modSIBdis $dest 7       ;;
        
                2_1_1_dire*)    # source is CL  
                        ab 0xd2
                        modSIBdis $dest 7       ;;
        
                2_1_1_imme_1_memo)
                        ab 0xc0         
                        modSIBdis $dest 7
                        ab ${number[$source]}   ;;
        
                1_[24]_[24]_memo)
                        ab 0xd1
                        modSIBdis $dest 7       ;;
        
                2_[24]_[24]_dire*)      # source is CL  
                        ab 0xd3
                        modSIBdis $dest 7       ;;
                *)
                        echo -e "\n\n\ndownshift doesn't support 
                        " $modestring " mode. " ;;
        esac
        opnote   downshift      $*
fi
}


extendAtoD      () {                                    #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel  CWD\n
Sign-extend A into A:D, i.e. D becomes all the same as the sign bit of
A.\n\n"
else
        herelist
        ab 0x99
        opnote  extendAtoD      $*
fi
}


decreasing      () {                                    #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel  STD\n
Set memory segment loop (string)  operations direction flag to
towards-lower-addresses. Segment ops then will traverse the segments
high-to-low.  \n"
else
        herelist
        ab 0xfd
        opnote   decreasing     $*
fi
}


decrement       () {                                    #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel DEC\n
decrement.      2 clocks.\n\n\n"
else
        herelist
        parse $*
        case $modestring in
                1_1*)
                ab 0xfe
                modSIBdis $source 1                             ;;
        
                1_[24]_memo)
                ab 0xff
                modSIBdis $source 1                             ;;
        
                1_[24]_dire)
                ao 11${register[$source]}                       ;;
        
                *)
                        echo -e "\n\ndecrement doesn't support 
                        " $modestring " mode. " ;;
        esac
        opnote   decrement      $*
fi
}


escape  () {                                            #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel IRET\n
Interrupt return. Various stack effects per system state.\n"
else
        herelist
        ab 0xcf
        opnote   escape $*
fi
}


farSS   ()      {                                       #                       
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel LSS\n
Load SS:r32 with pointer from memory\n"
else 
        herelist
        parse $*
        ab 0x0f 0xb2
        modSIBdis $source $dest         
        opnote   farSS  $*
fi
}


farDS   () {                                            #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel LDS\n
Load DS:r32 with pointer from memory\n\n"
else
        herelist
        parse $*
        ab 0xc5 
        modSIBdis $source $dest
        opnote   farDS  $*
fi
}


farES   () {                                            #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel LES\n
Load ES:register with pointer from memory\n\n"
else
        herelist
        parse $*
        ab 0xc4
        modSIBdis $source $dest
        opnote   farES  $*
fi
}

farFS   ()      {                                       #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel LFS\n
Load FS:register with pointer from memory\n\n"
else
        herelist
        parse $*
        ab 0x0f 0xb4
        modSIBdis $source $dest
        opnote   farFS  $*
fi
}

farGS   ()      {                                       #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel LGS\n
Load GS:r32 with pointer from memory\n\n"
else
        herelist
        parse $*
        ab 0x0f 0xb4
        modSIBdis $source $dest
        opnote   farGS  $*
fi
}


exchange        ()      {                               #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel XCHG\n
exchange 2 values in one, usually 3 clock, instruction.\n\n\n"
else
        herelist
        parse $*
        case $modestring in
                1*)     ao 22${register[$source]}               ;;

                2_1*)   ab 0x86
                        modSIBdis $source $dest                 ;;

                2_[24]*)
                        ab 0x87
                        modSIBdis $source $dest                 ;;

                *)      echo -e "\n\nexchange doesn't support 
                        " $modestring " mode. "                 ;;
        esac
        opnote   exchange       $*
fi
}


ifbit   ()      {                                       #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel BT\n
Save bit in carry flag. Bit position to act on is \"source\" argument
in shasm.\n\n"
else
        herelist
        parse $*
        case $modestring in
                2_?_?_dire*)    
                        ab 0x0f 0xa3
                        modSIBdis $dest ${register[$source]}    ;;
                        
                2_?_?_imme*)    
                        ab 0x0f 
                        modSIBdis $dest 4
                        ab ${number[$source]}                   ;;

                *)
                echo -e "\n\nifbit doesn't support " $modestring " mode. 
                        Supported modes are 2_?_?_imme* and
                        2_?_?_dire*. "                          ;;
        esac
        opnote   ifbit  $*
fi
}


signextend      () {                                    #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel CBW/CWDE\n

If cell = 2, make all bits of DX the same as the most 
significant bit of AX, i.e. sign-extend AX into DX. 

If cell = 4, sign-extend AX within A (EAX).  3 clocks.\n\n\n"
else
        herelist
        ab 0x98
        opnote   signextend     $*
fi
}


clearcarry      ()      {                               #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel CLC\n
unset the carry flag. Make it 0.\n\n\n"
else
        herelist
        ab 0xf8
        opnote   clearcarry     $*
fi
}


enter   ()      {                                       #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel ENTER\n
Enter is a complex instruction for creating a lexical level frame for
lexical block languages like Pascal. See also: leave. 
...................................................................
enter  ( 16bit framesize, 8bit lexical levels)
{
level = level MOD 32            // level is byte 4 of instr encoding  
Push BP 
frame-ptr = SP                  // frame-ptr is a hardware temp var
if level > 0
        {
        for (i =  1 TO (level - 1))
                {
                BP = BP - 4
                Push value _at_ BP
                }
        Push frame-ptr
        }
BP = frame-ptr                          // BP is now old 
SP = SP - ZeroExtend(First operand)
}
...................................................................
 enter can take up to 139 clocks, depending on the levels argument. The
most interesting things I see about enter is that it uses two internal
variables that aren't registers, and that it does a looping dereference
over an array of up to 31 pointers. That is, it collects dispersed values.  
It does all this atomically, which is important when molesting the return
stack. enter/leave is what gives BP it's framepointer designation. They
are the only instructions that use BP implicitly. 
In shasm syntax levels is source, frame size is dest, i.e. source and dest
don't mean what they usually do 
e.g.
        enter 200 to 3 \n\n"
 else
        herelist
        parse $*
        ab 0xc8
        ad ${number[$source]}
        ab ${number[$dest]}
        opnote   enter  $*
fi
}


flags   () {                                            #                       
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel LAHF\n
copy  AH into FLAGS, which is low dual of EFLAGS.\h\h"
else 
        herelist
        ab 0x9f
        opnote   flags  $*
fi
}


testAND         ()      {                               #       
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel TEST\n
Do an AND and set the flags accordingly, but don't actually assert the
result value on either of the arguments.\n\n"
else
        herelist
        parse $*
        case $modestring in
                                        # immediate byte to A
                1_1*)   ab 0xa8
                        ab ${number[$source]}                   ;;
        
                                        # immediate cell to A
                1*)     ab 0xa9
                        ac ${number[$source]}                   ;;
        
                                        #  immediate source byte to byte r/m
                2_1_1_imme_1_dire | 2_1_1_imme_1_memo)
                        ab 0xf6
                        modSIBdis $dest 0
                        ab ${number[$source]}                   ;;
        
                                        # immediate cell to r/m cell
                2_[24]_[24]_imme_[24]_dire | 2_[24]_[24]_imme_[24]_memo)
                        ab 0xf7
                        modSIBdis $dest 0
                        ac ${number[$source]}                   ;;
        
                                        # reg byte source  to byte r/m
                2_1_1_dire_1_dire | 2_1_1_dire_1_memo)
                        ab 0x84
                        modSIBdis $dest ${register[$source]}    ;;
        
                                        # register cell to r/m cell
                2_[24]_[24]_dire_[24]_dire | 2_[24]_[24]_dire_[24]_memo)
                        ab 0x85
                        modSIBdis $dest ${register[$source]}    ;;
        
                *)
                        echo -e "\n\ntestAND doesn't support 
                        " $modestring " mode. " ;;
        esac
        opnote  testAND $*
fi
}


testsubtract    () {                                    #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel CMP\n
Do an AND and set the flags accordingly, but don't actually assert the
result value on either of the arguments.\n\n"
else
        herelist
        parse $*
        case "$modestring" in
                                        # immediate byte to A
                1_1*)   ab 0x3c
                        ab ${number[$source]}                   ;;
        
                                        # immediate cell to A
                1*)     ab 0x3d
                        ac ${number[$source]}                   ;;
        
                                        #  immediate source byte to byte r/m
                2_1_1_imme_1_dire | 2_1_1_imme_1_memo)
                        ab 0x80
                        modSIBdis $dest 7
                        ab ${number[$source]}                   ;;
        
                                        # immediate cell to r/m cell
                2_[24]_[24]_imme_[24]_dire | 2_[24]_[24]_imme_[24]_memo)
                        ab 0x81
                        modSIBdis $dest 7
                        ac ${number[$source]}                   ;;
        
                                        # immediate source byte to cell r/m
                2_1_1_imme_[24]_dire | 2_1_1_imme_[24]_memo)
                        ab 0x83
                        modSIBdis $dest 7
                        ab ${number[$source]}                   ;;
        
                                        # reg byte source  to byte r/m
                2_1_1_dire_1_dire | 2_1_1_dire_1_memo)
                        ab 0x38
                        modSIBdis $dest ${register[$source]}    ;;
        
                                        # register cell to r/m cell
                2_[24]_[24]_dire_[24]_dire | 2_[24]_[24]_dire_[24]_memo)
                        ab 0x39
                        modSIBdis $dest ${register[$source]}    ;;
        
                                        # byte r/m source to byte reg
                                        # reg-reg already decoded as 0x20.
                                        # I think that's OK.
                2_1_1_memo_1_dire)
                        ab 0x3a
                        modSIBdis $source ${register[$dest]}    ;;
        
                                        # source r/m cell to cell reg
                                        # reg-reg already decoded as 0x21.
                                        # I think that's OK.
                2_[24]_[24]_memo_[24]_dire)
                        ab 0x38
                        modSIBdis $source ${register[$dest]}    ;;
        
                *)
                        echo -e "\n\ntestsubtract doesn't support 
                        " $modestring " mode. "                 ;;
        esac
        opnote   testsubtract   $*
fi
}

                                #               Got milk?
storemachinestatusdual  ()      {                       #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel SMSW\n
Store machine status dual to EA   dual

Legacy 286 thing. Can save a byte or two on a bootsector.\n\n"
else
        herelist
        parse $*
        # check possible
        ab 0x0f 1
        modSIBdis   $source 4
        opnote   storemachinestatusdual $*
fi
}


increasing      ()      {                               #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel CLD\n
Setstring operations direction flag to toward-higher-addresses\n\n"
else
        herelist
        ab 0xfc
        opnote   increasing     $*
fi
}


increment       ()      {                               #       
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel INC\n
add 1 to whatever\n\n"
else
        herelist
        parse $*
        case $modestring in
                1_1*)
                        ab 0xfe
                        modSIBdis $source 0                     ;;

                1_[24]_memo)
                        ab 0xff
                        modSIBdis $source 6                     ;;

                1_[24]_dire)
                        ao 10${register[$source]}               ;;

                *)
                        echo -e "\n\nincrement doesn't support 
                        " $modestring " mode. "                 ;;
        esac
        opnote   increment      $*
fi
}


interrupts      ()      {                               #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel STI\n
Allow external hardware to interrupt the CPU.\n\n"
else 
        herelist
        ab 0xf3
        opnote   interrupts     $*
fi
}


subtract        ()      {                               #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel SUB\n
Subtract without including borrow (carry) bit.\n\n"
else
        herelist
        parse $*
        case $modestring in
                                        # immediate byte to A
                1_1*)   ab 0x2c
                        ab ${number[$source]}                   ;;

                                        # immediate cell to A
                1*)     ab 0x2d
                        ac ${number[$source]}                   ;;

                                        # immediate source byte to byte r/m
                2_1_1_imme_1_dire | 2_1_1_imme_1_memo)
                        ab 0x80
                        modSIBdis $dest 5
                        ab ${number[$source]}                   ;;

                                        # immediate cell to r/m cell
                2_[24]_[24]_imme_[24]_dire | 2_[24]_[24]_imme_[24]_memo)
                        ab 0x81
                        modSIBdis $dest 5
                        ac ${number[$source]}                   ;;

                                        # immediate source byte to cell r/m
                2_1_1_imme_[24]_dire | 2_1_1_imme_[24]_memo)
                        ab 0x83
                        modSIBdis $dest 5
                        ab ${number[$source]}                   ;;

                                        # reg byte source  to byte r/m
                2_1_1_dire_1_dire | 2_1_1_dire_1_memo)
                        ab 0x28
                        modSIBdis $dest ${register[$source]}    ;;

                                        # register cell to r/m cell
                2_[24]_[24]_dire_[24]_dire | 2_[24]_[24]_dire_[24]_memo)
                        ab 0x29
                        modSIBdis $dest ${register[$source]}    ;;

                                        # byte r/m source to byte reg
                                        # reg-reg already decoded as 0x28.
                                        # I think that's OK.
                2_1_1_memo_1_dire)
                        ab 0x2a
                        modSIBdis $source ${register[$dest]}    ;;

                                        # source r/m cell to cell reg
                                        # reg-reg already decoded as 0x29.
                                        # I think that's OK.
                2_[24]_[24]_memo_[24]_dire)
                        ab 0x28
                        modSIBdis $source ${register[$dest]}    ;;

                *)
                        echo -e "\n\nsubtract doesn't support 
                        " $modestring " mode. " ;;
        esac
        opnote   subtract       $*
fi
}


jump ()  {                                              #               
if test "$1" = "h" ; then echo -e "\n\t\t\t\t\tIntel JMP\n 
Partial support here. 
Unconditional branch. Various modes.\n\n\n"
else
        herelist
        parse $*
        case $modestring in
                1_1*) 
                        ab 0xeb
                        branch $1 1                             ;;

                1_[24]_[24]_imme)
                        ab 0xe9
                        branch $1 $cell                         ;;

                1_[24]_[24]_dire)
                        ab 0xff
                        modSIBdis $source 4                     ;;

                *)
                        echo -e "\n\njump doesn't support 
                        " $modestring " mode. "                 ;;
        esac
        opnote jump $*
fi
}


ifzero  ()      {                                       #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel JZ\n
Branch if 0. Very frequently occuring instruction.\n\n  "
else
        herelist
        parse $*
        case $modestring in
                1_1*)   
                        ab 0x74
                        branch $1 1                             ;;

                1_[24]*)        
                        ab 0x0f 0x84 
                        branch $1 $cell                         ;;

                *)
                        echo -e "\n\nifzero doesn't support 
                        " $modestring " mode. "         ;;
        esac
        opnote   ifzero $*
fi
}


ifnonzero       ()      {                               #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel JNE/JNZ\n
branch if zero flag contains zero, meaning that a recent operation did not
result in a zero.\n\n"
else
        herelist
        parse $*
        case $modestring in
                
                1_1*)
                        ab 0x75
                        branch $1 1                             ;;
        
                1_[24]*)        
                        ab 0x0f 0x85 
                        branch $1 $cell                         ;;

                *)
                        echo -e "\n\nifnonzero doesn't support 
                        " $modestring " mode. "         ;;
        esac
        opnote   ifnonzero      $*
fi
}


linear  ()      {                                       #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel LEA\n
Store effective address for memory reference in register. This does the
address arithmatic and leaves the result of that, and doesn't fetch the
referenced object.\n\n"
else 
        herelist
        ab 0x8d
        modSIBdis $source ${register[$dest]}
        opnote  linear  $*
fi
}


leave   ()      {                                       #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\tIntel LEAVE\n
exuent a Pascal-style module frame. see also: enter\n\n"
else
        herelist
        ab 0xc9
        opnote   leave  $*
fi
}


limit   ()      {                                       #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\tIntel LSL\n
load the limit value from a segment descriptor.\n"
else 
        herelist
        ab 0x0f 3 
        modSIBdis $source ${register[$dest]}
        opnote   limit  $*
fi
}


lookup  ()      {                                       #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\tIntel XLATB\n
Set AL to memory byte DS:[BX + unsigned AL]. One-byte instruction.\n"
else
        herelist
        ab 0xd7
        opnote   lookup $*
fi
}


loop    ()      {                                       #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\tIntel LOOP\n
branch short if CL is not 0. I don't know if forward branches are
possble.\n\n"
else 
        herelist
        ab 0xe2
        ab ${number[$source]}
        opnote   loop   $*
fi
}


loopz   ()      {                                       #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel LOOPZ\n
branch short if CL is not 0 AND zero flag is true.\n\n"
else
        herelist
        ab 0xe1
        ab ${number[$source]}
        opnote   loopz  $*
fi
}


loopnz  ()      {                                       #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel LOOPNZ\n
branch short if CL is not 0 AND zero flag is false.\n\n"
else
        herelist
        ab 0xe0
        ab ${number[$source]}
        opnote   loopnz $*
fi
}


loadmachinestatusdual ()        {                       #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel LMSW\n
286 control register shortcut\n\n"
else
        herelist
        ab 0x0f 1 
        madSIBdis $source 6
        opnote   loadmachinestatusdual  $*
fi
}


multiply        ()      {
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel IMUL\n
F6 /5 r/m8              9-14/12-17  AX^[ AL * r/m byte
F7 /5 r/m32               9     -38/12-41  EDX:A ^[ A * r/m cell
0F/r  r32,r/m32         9-38/12-41  cell register ^[ cell
                                        register * r/m cell
6B /r ib        r16,r/m16,imm8  9-14/12-17  dual register ^[ r/m16 *
                                        sign-extended immediate byte
6B /r ib        r32,r/m32,imm8  9-14/12-17  cell register ^[ r/m32 *
                                        sign-extended immediate byte
6B /r ib        r16,imm8                9-14/12-17  dual register ^[ dual
                                        register * sign-extended
                                        immediate byte
6B /r ib        r32,imm8        9-14/12-17  cell register ^[ cell
                                        register * sign-extended
                                        immediate byte
69 /r iw r16,r/m16,imm16        9-22/12-25  dual register ^[ r/m16 *
                                        immediate dual
69 /r immcell   r32,r/m32,imm329-38/12-41  cell register ^[ r/m32 *
                                        immediate cell
69 /r iw r16,imm16   9-22/12-25  dual register ^[ r/m16 *
                                        immediate dual
69 /r immcellr32,imm32   9-38/12-41  cell register ^[ r/m32 *
                                        immediate cell

9 to 41 clocks.

                "
else
        herelist
        parse $*
        case $modestring in
        *)
        echo -e "\n\nmultiply doesn't support " $modestring " mode. " ;;
esac
        opnote   multiply       $*
fi
}


negate  ()      {                                       #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel NEG\n
F6 /3r/m82/6       Two's complement negate r/m byte
F7 /3r/m32  2/6

Two's complement negate, 2 or 6 clocks. simple NOT, then increment.
                "
else
        herelist
        parse $*
        case $modestring in

                1*)
                        ab 0xf6
                        modSIBdis $source 3                     ;;

                2*)
                        ab 0xf7
                        modSIBdis $source 3                     ;;

                *)
                        echo -e "\n\nnegate  doesn't support 
                        " $modestring " mode. "                 ;;
        esac
        opnote   negate $*
fi
}


nocarry         ()      {                               #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel CLC\n
unset carry flag. To 0.\n\n"
else 
        herelist
        ab 0xf8
        opnote   nocarry        $*
fi
}


nop     ()      {                                       #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel NOP\n
Do nothing. This actually is the OR A with A version of OR.\n\n"
else
        herelist
        ab 0x90
        opnote   nop    $*
fi
}


NOT     ()      {                                       #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel NOT\n
Boolean bitwise not. Invert all the bits. All zeros become ones and
vice-versa.\n\n"
else
        herelist
        parse $*
        case $modestring in
                
                1_1_1_memo)
                        ab 0xf6 
                        modSIBdis $source 2                     ;;
        
                1_[24]_[24]_memo)               
                        ab 0xf7
                        modSIBdis $source 2                     ;;

                *)
                        echo -e "\n\nNOT doesn't support 
                        " $modestring " mode. "                 ;;
        esac
        opnote   NOT    $*
fi
}


nointerrupts    ()      {                               # 
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel CLI\n
disable external hardware interrupts to the CPU.
seful at boot time maybe and for profound state-changes like
process-switches.\n\n"
else 
        herelist
        ab 0xfa
        opnote   nointerrupts   $*
fi
}


overflowtrap () {                                       #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel INTO\n
cause invocation of a trap handler IF overflow bit is set.\n\n"
else 
        herelist
        ab 0xce
        opnote   overflowtrap   $*
fi
}


priviledge ()   {                                       #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel ARPL\n
Adjust requested priviledge level  of r/m16 to not less than RPL of r16
\n\n"
else 
        herelist
        ab 0x63
        modSIBdis $dest ${register[$source]}    
        opnote  priviledge      $*
fi
}


pullcore        ()      {                               #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel POPA\n
copy (pop) DI, SI, BP, SP, B, D, C, and A off the stack.
adjusting stack pointer SP accordingly.\n\n"
else
        herelist
        ab 0x61
        opnote   pullcore       $*
fi
}

pull    ()              {       partial # unstack       #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel POP\n
Copy top of stack into operand, adjusting stack pointer SP accordingly.
\n\n"
else
        herelist
        parse $*
        case $modestring in
                1_[24]_[24]_dire)
                        ab 0x8f 
                        modSIBdis $source 0  ;; # must be DI

                1_1_1_imme)
                        ab 0x6a ${number[$source]}              ;;

                1_[24]_[24]_dire)
                        ao 13${register[$source]}               ;;

                *segm)
                        if test ${register[$source]} = "0" ;then # ES
                                ab 0x07                                 
        
                        elif test ${register[$source]} = "2" ;then      # SS
                                ab 0x17
        
                        elif test ${register[$source]} = "3" ;then      # DS
                                ab 0x1f 
        
                        elif test ${register[$source]} = "4" ;then      # FS
                                ab 0x0f 0xa1
        
                        elif test ${register[$source]} = "5" ;then      # GS
                                ab 0x0f 0xa9
                        else
                                echo -e "\n\npush doesn't support 
                                " $modestring " mode. " 
                        fi                                              ;;
                *)
                        echo -e "\n\npull doesn't support 
                        " $modestring " mode. "                         ;;
        esac
        opnote   pull   $*
fi
}


pullflags       ()      {                               #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel POPF\n
copy top of stack into flags reg, adjusting stack pointer SP
accordingly.\n\n"
else
        herelist
        ab 0x9d
        opnote   pullflags      $*
fi
}


pushcore        ()      {                               #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel PUSHA\n
copy the eight main regs onto the stack, adjusting stack pointer SP
accordingly.\n\n"
else
        herelist
        ab 0x60
        opnote   pushcore       $*
fi
}


pushflags       ()      {                               #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel PUSHF\n
copy FLAGS onto the top of stack, adjusting stack pointer SP
accordingly.\n\n"
else
        herelist
        ab 0x9c
        opnote   pushflags      $*
fi
}


push    ()      {                                       #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel PUSH\n
copy operand onto top of stack, adjusting stack pointer SP
accordingly.\n\n"
else
        herelist
        parse $*
        case $modestring in
                1_[24]_[24]_imme)
                        ab 0x68 
                        ac ${number[$source]}                   ;;

                1_1_1_imme)
                        ab 0x6a ${number[$source]}              ;;

                1_[24]_[24]_dire)
                        ao 12${register[$source]}               ;;

                *segm)
                        if test ${register[$source]} = "0" ;then        # ES
                                ab 0x06                                 
        
                        elif test ${register[$source]} = "1" ;then      # CS
                                ab 0x0e                         
        
                        elif test ${register[$source]} = "2" ;then      # SS
                                ab 0x16 
        
                        elif test ${register[$source]} = "3" ;then      # DS
                                ab 0x1e 
        
                        elif test ${register[$source]} = "4" ;then      # FS
                                ab 0x0f 0xa0
        
                        elif test ${register[$source]} = "5" ;then      # GS
                                ab 0x0f 0xa8
                        else
                                echo -e "\n\npush doesn't support 
                                " $modestring " mode. " 
                        fi                                      ;;
                *)
                        echo -e "\n\npush doesn't support 
                        " $modestring " mode. "                 ;;
        esac
        opnote push     $*
fi
}


quadextend      () {                                    #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel CDQ\n
sign-extend A to D:A    
\n\n"
else
        herelist
        ab 0x99
        opnote   quadextend     $*
fi
}


readable        ()      {
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel VERR\n
0F 00 /4  r/m16 pm=10/11 Set ZF=1 if segment can be read,
                                selector in r/m16
0F 00 /5  r/m16 pm=15/16 Set ZF=1 if segment can be written,
                                selector in r/m16

Set zero flag to true if segment of given selector can be written.\n\n"
else
        herelist
        parse $*
        case $modestring in
                
                *)
                echo -e "\n\nreadable doesn't support 
                " $modestring " mode. "                         ;;
        esac 
        opnote   readable       $*
fi
}


recieve         ()      {
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel IN\n
E4 ib   AL,imm8 12,pm=6*/26**  Input byte from immediate port
                                   into AL
E5 ib   A,imm812,pm=6*/26**  Input cell from immediate port
                                   into A
EC      AL,DX   13,pm=7*/27**     Input byte from port DX into AL
ED      A,DX  13,pm=7*/27**     Input cell from port DX into A

Input from port\n\n"
else
        herelist
        parse $*
        case $modestring in

                *)      
                        echo -e "\n\nrecieve doesn't support 
                        " $modestring " mode. "                 ;;
        esac
        opnote   recieve        $*
fi
}


return  ()      { partial support, near                 #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel RET\n
C3                 10+m           Return (near) to caller
CB                 18+m,pm=32+m   Return (far) to caller, same
                                privilege
CB                 pm=68          Return (far), lesser privilege,

                               ------->  switch stacks

C2 iw   imm16      10+m           Return (near), pop imm16 bytes of
                                parameters
CA iw   imm16       18+m,pm=32+m   Return (far), same privilege, pop
                                imm16 bytes

Return from a call. Various stack frames by call type.\n\n"
else
        herelist
        parse $*
        case $modestring in
                1*)     
                        ab 0xc2 
                        ad ${number[$source]}           ;;
                
                *)
                        ab 0xc3                         ;;
        esac
        opnote   return $*
fi
}


rights  ()      {                                       #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel LAR\n

MORE TEXT HERE
r16 becomes r/m16 masked by FF00        \n\n"
else 
        herelist
        ab 0x0f 2 
        modSIBdis $source ${register[$dest]}
        opnote   rights $*
fi
}


setGDT  ()      {                                       #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel LGDT\n
Load pointer at memory operand into Global Descriptor Table Register. This
and setIDT are the only instructions that always interpret an address as
physical, since they set up the memory protection scheme.\n\n"
else
        herelist
        ab 0x0f 0x01
        modSIBdis $source 2
        opnote   setGDT $*
fi
}


setIDT  ()      {                                       #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel LIDT\n
Load pointer at memory operand into Interrupt Descriptor Table Register.
This and setGDT are the only instructions that always interpret an address
as physical, since they set up the memory protection scheme.\n\n"
else 
        herelist
        ab 0x0f 0x01
        modSIBdis $source 3
        opnote   setIDT $*
fi
}


setLDT  ()      {                                       #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel LLDT\n
Load pointer at memory operand into Local Descriptor Table Register.\n\n"
else
        herelist
        ab 0x0f 0x00
        modSIBdis $source 2
        opnote   setLDT $*
fi
}


savetask        ()      {                               #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel STR\n
Load EA dual into task register. Ha3sm doesn't use the 386+ task handling
facilities. Most 386 unices do I think.\n\n"
else 
        herelist
        ab 0x0f 0x00
        modSIBdis $source 1
        opnote   savetask       $*
fi
}


send    ()      {                                       HORKED
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel OUT\n
HORKED
EE  DX,AL    11,pm=5*/25**   Output byte AL to port number in
DX
EF  DX,A   11,pm=5*/25**   Output cell AL to port number
                                   in DX
Output to a port number\n\n"
else
        herelist
        parse $*
        case $modestring in
                                # immediate byte to A
                1_1*)   ab 0xe6
                        ab ${number[$source]}                   ;;

                                # immediate cell to A
                1*)     ab 0xe7
                        ac ${number[$source]}                   ;;

                *)
                        echo -e "\n\nsend doesn't support 
                        " $modestring " mode. " ;;
        esac
        opnote   send   $*
fi
}


setcarry        ()      {                               #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel STC\n
assert carry=true, 1.\n\n"
else
        herelist
        ab 0xf9
        opnote   setcarry       $*
fi
}


setflags        ()      {                               #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel SAHF\n
copy AH to the FLAGS register-half.\n\n"
else
        herelist
        ab 0x9e
        opnote   setflags       $*
fi
}


sleep   ()      {                                       #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel HLT\n
halt processor until next hardware interrupt. Be nice to your CPU.\n\n"
else
        herelist
        ab 0xf4
        opnote   sleep  $*
fi
}


subtractborrow  ()      {                               #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel SBB\n
Subtract with borrow\n\n"
else
        herelist
        parse $*
        case $modestring in
                                        # immediate byte to A
                1_1*)   ab 0x1c
                        ab ${number[$source]}                   ;;
        
                                        # immediate cell to A
                1*)     ab 0x1d
                        ac ${number[$source]}                   ;;
        
                                        #  immediate source byte to byte r/m
                2_1_1_imme_1_dire | 2_1_1_imme_1_memo)
                        ab 0x80
                        modSIBdis $dest 3
                        ab ${number[$source]}                   ;;
        
                                        # immediate cell to r/m cell
                2_[24]_[24]_imme_[24]_dire | 2_[24]_[24]_imme_[24]_memo)
                        ab 0x81
                        modSIBdis $dest 3
                        ac ${number[$source]}                   ;;
        
                                        # immediate source byte to cell r/m
                2_1_1_imme_[24]_dire | 2_1_1_imme_[24]_memo)
                        ab 0x83
                        modSIBdis $dest 3
                        ab ${number[$source]}                   ;;
        
                                        # reg byte source  to byte r/m
                2_1_1_dire_1_dire | 2_1_1_dire_1_memo)
                        ab 0x18
                        modSIBdis $dest ${register[$source]}    ;;
        
                                        # register cell to r/m cell
                2_[24]_[24]_dire_[24]_dire | 2_[24]_[24]_dire_[24]_memo)
                        ab 0x19
                        modSIBdis $dest ${register[$source]}    ;;
        
                                        # byte r/m source to byte reg
                                        # reg-reg already decoded as
                                        # I think that's OK.
                2_1_1_memo_1_dire)
                        ab 0x1a
                        modSIBdis $source ${register[$dest]}    ;;
        
                                        # source r/m cell to cell reg
                                        # reg-reg already decoded as ?
                                        # I think that's OK.
                2_[24]_[24]_memo_[24]_dire)
                        ab 0x18
                        modSIBdis $source ${register[$dest]}    ;;
        
                *)
                        echo -e "\n\nsubtractborrow doesn't support 
                        " $modestring " mode. " ;;
        esac
        opnote   subtractborrow $*
fi
}


task    ()      {
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel LTR\n
Load EA dual into task register\n\n"
else 
        herelist
        ab 0x0f 0
        modSIBdis $source 3
        opnote   task   $*
fi
}


#     ###### this REALLY _IS_ 3 distinct instructions
# well, all distinct opcodes are, but these three are pretty different.
trap    () {
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel INT\n
CC  3     33              Interrupt 3--trap to debugger
CDibimm8  37              Interrupt numbered by immediate
CE       Fail:3,pm=3;
        "
else
        herelist
        parse $*
        case $modestring in
        *)
        echo -e "\n\ntrap  doesn't support " $modestring " mode. " ;;
esac
        opnote   trap   $*
fi
}


multiply        ()      {
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel MUL\n
F6 /4AL,r/m8  9-14/12-17Unsigned multiply (AX ^[ AL * r/m byte)
F7 /4A,r/m329-38/12-41Unsigned multiply (EDX:A ^[ A * r/m
                              cell)
                "
else 
        herelist
        parse $*
case $modestring in

        *)
        echo -e "\n\nmultiply doesn't support " $modestring " mode. " ;;
esac
        opnote   multiply       $*
fi
}


unbit   ()      {                                       #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel BTC\n
Save specified bit of operand into carry flag and complement it in operand.
\n\n"
else
        herelist
        parse $*
        case $modestring in
                2_[24]_[24]_dire*)
                        ab 0x0f 0xbb 
                        modSIBdis $dest ${register[$source]}    ;; 
        
                2_1_1_imme*)
                        ab 0x0f 0xba
                        modSIBdis $dest 7                       ;;

                *)
                        echo -e "\n\nunbit doesn't support 
                        " $modestring " mode. "                 ;;
        esac
        opnote   unbit  $*
fi
}


invertcarry     ()      {                               #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel CMC\n
flip the carry bit\n\n"
else
        herelist
        ab 0xf5
        opnote   invertcarry    $*
fi
}


signeddivide    ()      {                               #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel IDIV\n
19 to 43 clocks. 
                "
else
        herelist
        parse $*
        case $modestring in
                1_1*)
                        ab 0xf6 
                        modSIBdis $source 7                     ;;
        
                1_[24]*)
                        ab 0xf7 
                        modSIBdis $source 7                     ;;
         
                *)
                        echo -e "\n\nsigneddivide doesn't support 
                        " $modestring " mode. " ;;
        esac
        opnote   signeddivide   $*
fi
}


unsigneddivide  ()      {                               #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel DIV\n
                        "
else
        herelist
        parse $*
        case $modestring in     
                                        # immediate byte to A
                1_1*)   ab 0x3c
                        ab ${number[$source]}                   ;;

                                        # immediate cell to A
                1*)     ab 0x3d
                        ac ${number[$source]}                   ;;
        
                                #  immediate source byte to byte r/m
                2_1_1_imme_1_dire | 2_1_1_imme_1_memo)
                        ab 0x80
                        modSIBdis $dest 7
                        ab ${number[$source]}                   ;;

                                        # immediate cell to r/m cell
                2_[24]_[24]_imme_[24]_dire | 2_[24]_[24]_imme_[24]_memo)
                        ab 0x81
                        modSIBdis $dest 7
                        ac ${number[$source]}                   ;;

                                        # immediate source byte to cell r/m
                2_1_1_imme_[24]_dire | 2_1_1_imme_[24]_memo)
                        ab 0x83
                        modSIBdis $dest 7
                        ab ${number[$source]}                   ;;
        
                                        # reg byte source  to byte r/m
                2_1_1_dire_1_dire | 2_1_1_dire_1_memo)
                        ab 0x38
                        modSIBdis $dest ${register[$source]}    ;;
        
                                        # register cell to r/m cell
                2_[24]_[24]_dire_[24]_dire | 2_[24]_[24]_dire_[24]_memo)
                        ab 0x39
                        modSIBdis $dest ${register[$source]}    ;;

                                        # byte r/m source to byte reg
                                        # reg-reg already decoded as 0x20.
                                        # I think that's OK.
                2_1_1_memo_1_dire)
                        ab 0x3a
                        modSIBdis $source ${register[$dest]}    ;;

                                        # source r/m cell to cell reg
                                        # reg-reg already decoded as 0x21.
                                        # I think that's OK.
                2_[24]_[24]_memo_[24]_dire)
                        ab 0x38
                        modSIBdis $source ${register[$dest]}    ;;
                *)
                echo "BONK"                     ;;
        esac    
        opnote   unsigneddivide $*
fi
}


uprollcarry     ()      {                               #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel RCL\n

up-significance bit roll including carry in the ring of bits rolled
                "
else
        herelist
        parse $*
        case $modestring in

                2_[24]_[24]_imme_[24]_memo)
                        ab 0xc1
                        modSIBdis $dest 2
                        ab ${number[$source]}   ;;

                1_1_1_memo)
                        ab 0xd0 
                        modSIBdis $dest 2       ;;

                2_1_1_dire*)    # source is CL  
                        ab 0xd2
                        modSIBdis $dest 2       ;;

                2_1_1_imme_1_memo)
                        ab 0xc0         
                        modSIBdis $dest 2
                        ab ${number[$source]}   ;;

                1_[24]_[24]_memo)
                        ab 0xd1
                        modSIBdis $dest 2       ;;

                2_[24]_[24]_dire*)      # source is CL  
                        ab 0xd3
                        modSIBdis $dest 2       ;;

                *)
                        echo -e "\n\nuprollcarry doesn't support 
                        " $modestring " mode. " ;;
        esac
        opnote   uprollcarry    $*
fi
}


uproll  ()      {                                       #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel ROL\n
                "
else
        herelist
        parse $*
        case $modestring in
        
                2_[24]_[24]_imme_[24]_memo)
                        ab 0xc1
                        modSIBdis $dest 0
                        ab ${number[$source]}                   ;;

                1_1_1_memo)
                        ab 0xd0 
                        modSIBdis $dest 0                       ;;

                2_1_1_dire*)    # source is CL  
                        ab 0xd2
                        modSIBdis $dest 0                       ;;

                2_1_1_imme_1_memo)
                        ab 0xc0         
                        modSIBdis $dest 0
                        ab ${number[$source]}                   ;;

                1_[24]_[24]_memo)
                        ab 0xd1
                        modSIBdis $dest 0                       ;;

                2_[24]_[24]_dire*)      # source is CL  
                        ab 0xd3
                        modSIBdis $dest 0                       ;;

                *)
                        echo -e "\n\nuproll doesn't support 
                        " $modestring " mode. "                 ;;
        esac
        opnote   uproll $*
fi
}


upshift         ()      {                               #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel SAL\n
up-significance bitshift. zeros roll in on low-significance end, bits are lost
on the high-significance end.\n\n"
else
        herelist
        parse $*
        case $modestring in

                2_[24]_[24]_imme_[24]_memo)
                        ab 0xc1
                        modSIBdis $dest 1
                        ab ${number[$source]}                   ;;

                1_1_1_memo)
                        ab 0xd0 
                        modSIBdis $dest 1                       ;;

                2_1_1_dire*)    # source is CL  
                        ab 0xd2
                        modSIBdis $dest 1                       ;;

                2_1_1_imme_1_memo)
                        ab 0xc0         
                        modSIBdis $dest 1
                        ab ${number[$source]}                   ;;

                1_[24]_[24]_memo)
                        ab 0xd1
                        modSIBdis $dest 1                       ;;
        
                2_[24]_[24]_dire*)      # source is CL  
                        ab 0xd3
                        modSIBdis $dest 1                       ;;

                *)
                        echo -e "\n\nupshift doesn't support 
                        " $modestring " mode. "                 ;;
        esac
        opnote   upshift        $*
fi
}


widedownshift   ()      {
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel SHRD\n
0Fr/m32,r32,imm8  3/7  r/m32 gets SHR of r/m32 concatenated  with r32
0Fr/m32,r32,CL 3/7  r/m32 gets SHR of r/m32 concatenated with r32

down-significance bitshift of a composite operand made of ??????????
        "
else
        herelist
        parse $*
        case $modestring in

                *)
                        echo -e "\n\nwidedownshift doesn't support 
                        " $modestring " mode. " ;;
        esac
fi
        opnote   widedownshift  $*
}

wideupshift     ()      {
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel SHLD\n

composite up-significance bitshift.
                "
else
        herelist
        parse $*
        case $modestring in

                *)
                        echo -e "\n\nwideupshift doesn't support 
                        " $modestring " mode. " ;;
        esac
        opnote  wideupshift     $*
fi
}


within  ()      {                                       #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel BOUND\n
62/r  BOUND r32,m32&32  10
Check if r32 is within bounds, (passes test). Bounds are adjacent
32 bit values in memory.\n\n"
else
        herelist
        parse $*
        ab 0x62
        modSIBdis $source  ${register[$dest]}
        opnote   within $*
fi
}


writeable       ()      {
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel VERW\n
Test if current process is allowed to write to given ???????
"
else
        herelist
        opnote   writeable      $*
fi
}


####################
#### segment (string) ops want very badly to be macros. Enjoy.


fill    ()      {
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel STOSD\n
AAm8   4        Store AL in byte ES:[DI], update DI
AB  STOSD     4

Store A in cell ES:[DI], update DI\n\n"
else 
        herelist

        opnote   fill   $*
fi
}


recieves        ()      {
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel INSB\n
6Cr/m8,DX 15,pm=9*/29**  Input byte from port DX into ES:DI
6Dr/m32,DX15,pm=9*/29**  Input cell from port DX into ES:DI
                "
else 
        herelist

        opnote   recieves       $*
fi
}


segmentcopy     ()      {
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel MOVSD\n
                "
else 
        herelist

        opnote   segmentcopy    $*
fi
}


segmentcompare  ()      {
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel SCASB\n
AEm8   7       Compare bytes AL-ES:[DI], update DI
AFm32  7       Compare cells A-ES:[DI], update DI
                        "
else 
        herelist

        opnote  segmentcompare  $*
fi
}


segmentcopy     ()      {
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel MOVSB\n
                "
else 
        herelist

        opnote   segmentcopy    $*
fi
}


segmentifsubtract       ()      {
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel CMPS\n
A6  m8,m8      10       Compare bytes ES:[DI] (second
                               operand) with   [SI] (first
                               operand)
A7  m32,m32    10       Compare cells ES:[DI]
                               (second operand) with [SI]
                               (first operand)
                        "
else 
        herelist

        opnote   segmentifsubtract      $*
fi
}


segmentifsubtractbytes  ()      {
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel CMPSB\n
                        "
else
        herelist

        opnote   segmentifsubtractbytes $*
fi
}


sendsegment     ()      {
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel OUTS\n
6E      DX,r/m8         14,pm=8*/28**   Output byte [SI] to port in DX
6F      DX,r/m32        14,pm=8*/28**   Output cell [SI] to port in DX
                "
else
        herelist
        parse $*
        case $modestring in
        *)
        echo -e "\n\nsendsegment doesn't support " $modestring " mode. " ;;
esac
        opnote   sendsegment    $*
fi
}

                        #               Note to self: BLINK STUPID!
ifnocarry       ()      {                               #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel JAE\n
                "
else
        herelist
        parse $*
        case $modestring in

                1_1*)
                        ab 0x73
                        branch $1 1                             ;;

                1_[24]*)        
                        ab 0x0f 0x83 
                        branch $1 $cell                         ;;

                *)
                        echo -e "\n\nifzero doesn't support 
                        " $modestring " mode. "                 ;;
        esac
        opnote  ifnocarry       $*
fi
}


ifcarry                         ()      {               #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel JB\n
jump if the carry bitflag is set, 1.\n\n"
else
        herelist
        parse $*
        case $modestring in
        
                1*)     
                        ab 0x72
                        branch $1 1                             ;;

                1_[24]*)        
                        ab 0x0f 0x82 
                        branch $1 $cell                         ;;
                *)
                        echo -e "\n\nifcarry doesn't support 
                        " $modestring " mode."                  ;;
        esac
        opnote   ifcarry        $*
fi
}


ifC0                    ()      {                       #
if test "$1" = "h" ; then  echo -e  "\n\t\t\t\t\tIntel JCXZ\n
jump if C register is zero.\n\n"
else
        herelist
        parse $*
        case $modestring in

                1*)
                        ab 0xe3
                        branch $1 1                             ;;

                *)
                        echo -e "\n\nifC0 doesn't support 
                        " $modestring " mode."                  ;;
        esac
        opnote   ifC0   $*
fi
}

                # --# x86 too-ugly-to-live stuff. AAA and friends
# ."CPU'/386_de-emphasized"

