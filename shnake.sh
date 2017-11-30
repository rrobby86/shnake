#!/bin/bash

usage() {
cat <<___
rrobby86's Snake, version 1.0
Guide green snake to red Xs, don't crash into tail or walls.
Use arrow keys or WASD to change direction, Q to quit, P to pause.
Command-line options:
 -s N   set speed as frames per second (def.: 10)
 -d N   set speed as seconds between frames (def.: 0.1)
 -w N   set field width (def.: maximum available)
 -h N   set field height (def.: maximum available)
  (for both -w and -h: if N not positive or too high, max. available is used)
 -t N   set initial tail length (def.: 5)
 -i     set infinite tail
 -o     enable wrap-around (no walls, when border reached jump to opposite)
___
exit
}

[ $# -eq 1 ] && [ $1 = "-h" -o $1 = "--help" ] && usage

# defaults
DELAY=0.1
LENGTH=5
WIDTH=0
HEIGHT=0
WRAP=

read_opts() {
  while getopts s:d:w:h:t:io OPT; do
    case $OPT in
      s) DELAY=`echo "scale=3;1/$OPTARG" | bc`;;
      d) DELAY=$OPTARG;;
      w) WIDTH=$OPTARG;;
      h) HEIGHT=$OPTARG;;
      t) LENGTH=$OPTARG;;
      i) LENGTH=-1;;
      o) WRAP=y;;
    esac
  done
}

read_opts $*

# graphics
C_HEAD="\033[42mO\033[m"
C_TAIL="\033[42m·\033[m"
C_FOOD="\033[41mX\033[m"

# set terminal (no cursor, no keys echoing)
tput civis
stty -echo

ESC=$(printf "\033")

LINES=$(tput lines)
COLUMNS=$(tput cols)

MAXWIDTH=$(($COLUMNS-4))
MAXHEIGHT=$(($LINES-5))

if [ $WIDTH -le 0 -o $WIDTH -gt $MAXWIDTH ]; then
  FW=$MAXWIDTH
else
  FW=$WIDTH
fi
if [ $HEIGHT -le 0 -o $HEIGHT -gt $MAXHEIGHT ]; then
  FH=$MAXHEIGHT
else
  FH=$HEIGHT
fi

FT=$((($LINES-$FH)/2+2))
FB=$(($FT+$FH-1))
FL=$((($COLUMNS-$FW)/2+1))
FR=$(($FL+$FW-1))

printc() {
  printf "\033[$1;${2}H$3"
}

printc_game() {
  c=$1
  printc $(($FT+${c#*,})) $(($FL+${c%,*})) $2
}

init_game() {
  SCORE=0
  HEADX=$(($FW/2))
  HEADY=$(($FH/2))
  GROW=$LENGTH
  LASTDIR=99
  DIR=0
  replace_food
}

init_screen() {
  clear
  printc 2 3 Snake
  printf "\033[44m"
  printc $(($FT-1)) $(($FL-1)) +
  for i in $(seq $FL $FR); do printf "-"; done
  printf +
  for i in $(seq $FT $FB); do
    printc $i $(($FL-1)) "|"
    printc $i $(($FR+1)) "|"
  done
  printc $(($FB+1)) $(($FL-1)) +
  for i in $(seq $FL $FR); do printf "-"; done
  printf "+\033[m"
  print_score
}

print_score() {
  printc 2 $(($COLUMNS-1-${#SCORE})) $SCORE
}

draw_game() {
  for c in $CLEAR; do
    printc_game $c "\040"
  done
  CLEAR=
  for t in $TAIL; do
    printc_game $t $C_TAIL
  done
  printc_game $HEADX,$HEADY $C_HEAD
  printc_game $FOODX,$FOODY $C_FOOD
}

replace_food() {
  while true; do
    FOODX=$(shuf -i 0-$(($FW-1)) -n 1)
    FOODY=$(shuf -i 0-$(($FH-1)) -n 1)
    [ $FOODX -eq $HEADX -a $FOODY -eq $HEADY ] && continue
    for t in $TAIL; do
      [ $t = "$FOODX,$FOODY" ] && continue 2
    done
    break
  done
}

update_game() {
  [ $PAUSE ] && return
  DX=0
  DY=0
  [ $(($DIR-$LASTDIR)) -eq 2 -o $(($DIR-$LASTDIR)) -eq -2 ] && DIR=$LASTDIR
  LASTDIR=$DIR
  case $DIR in
    0) DX=1;;
    1) DY=-1;;
    2) DX=-1;;
    3) DY=1;;
  esac
  TAIL="$TAIL$HEADX,$HEADY "
  HEADX=$(($HEADX+$DX))
  HEADY=$(($HEADY+$DY))
  [ $WRAP ] &&
    if [ $HEADX -lt 0 ]; then
      HEADX=$(($FW-1))
    elif [ $HEADX -ge $FW ]; then
      HEADX=0
    elif [ $HEADY -lt 0 ]; then
      HEADY=$(($FH-1))
    elif [ $HEADY -ge $FH ]; then
      HEADY=0
    fi
  if [ $HEADX -eq $FOODX -a $HEADY -eq $FOODY ]; then
    replace_food
    inc_score
    [ $GROW -ge 0 ] && : $((GROW++))
  fi
  if [ $GROW -gt 0 ]; then
    : $((GROW--))
  elif [ $GROW -eq 0 ]; then
    shorten_tail
  fi
  draw_game
  if check_collision; then
    quit
    exit
  fi
}

shorten_tail() {
  CLEAR=${TAIL%% *}
  TAIL=${TAIL#* }
}

check_collision() {
  [ ! $WRAP ]
    [ $HEADX -lt 0 -o $HEADX -ge $FW -o $HEADY -lt 0 -o $HEADY -ge $FH ] &&
    return 0
  for t in $TAIL; do
    [ "$HEADX,$HEADY" = $t ] && return 0
  done
  return 1
}

inc_score() {
  if [ $# -eq 0 ]; then
    INC=1
  else
    INC=$1
  fi
  SCORE=$(($SCORE+$INC))
  print_score
}

get_key() {
  read -s -n 1 k
  case "$k" in
    $ESC)
      read -s -n 1 k
      case "$k" in
        "[")
          read -s -n 1 k
          case "$k" in
            A) r=up;;
            B) r=down;;
            C) r=right;;
            D) r=left;;
          esac;;
        O)
          read -s -n 1 k
          case "$k" in
            H) r=home;;
            F) r=end;;
          esac;;
      esac;;
    *) r="$k";;
  esac
  eval $1=$r
}

do_step() {
  (sleep $DELAY && kill -ALRM $$) &
  update_game
}

quit() {
  tput cvvis
  stty echo
  printc $LINES 1
  trap exit ALRM
  sleep $DELAY
}

trap do_step ALRM
init_screen
init_game
draw_game
sleep 1
do_step
while :
do
  get_key K
  if [ $PAUSE ]; then
    printc 2 3 "Snake                             "
    PAUSE=
  else
    case "$K" in
     w|up) DIR=1;;
     a|left) DIR=2;;
     s|down) DIR=3;;
     d|right) DIR=0;;
     p)
      printc 2 3 "Pause (press any key to continue)"
      PAUSE=y;;
     q)
      quit
      exit;;
    esac
  fi
done

