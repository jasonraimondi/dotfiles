function battery() {
  pmset -g batt | egrep "([0-9]+\%).*" -o --colour=auto | cut -f1 -d';'
}

function cpu() {
  iostat -c 2 disk0 | sed '/^\s*$/d' | tail -n 1 | awk -v format="%3.0f%%" '{usage=100-$6} END {printf(format, usage)}'
}

function memory() {
  vm_stat | awk 'BEGIN{FS="[:]+"}{if(NR<7&&NR>1)sum+=$2; if(NR==2||NR==4||NR==5)free+=$2} END{printf "%3dGB\n",(sum - free)*0.00001}'
}

function extract () {
  if [ -f $1 ]; then
    case $1 in
      *.tar.bz2)  tar -jxvf $1                        ;;
      *.tar.gz)   tar -zxvf $1                        ;;
      *.bz2)      bunzip2 $1                          ;;
      *.dmg)      hdiutil mount $1                    ;;
      *.gz)       gunzip $1                           ;;
      *.tar)      tar -xvf $1                         ;;
      *.tbz2)     tar -jxvf $1                        ;;
      *.tgz)      tar -zxvf $1                        ;;
      *.zip)      unzip $1                            ;;
      *.ZIP)      unzip $1                            ;;
      *.pax)      cat $1 | pax -r                     ;;
      *.pax.Z)    uncompress $1 --stdout | pax -r     ;;
      *.Z)        uncompress $1                       ;;
      *)          echo "'$1' cannot be extracted/mounted via extract()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}
