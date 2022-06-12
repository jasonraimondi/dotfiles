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

function nname () {
  make --no-print-directory -C $HOME/dotfiles/bin/namer;
}

function fname() { 
  find . -iname "*$@*"; 
}


function lt() { 
  ls -ltrsa "$@" | tail; 
}

function remove_lines_from() {
  # removes lines from $1 if they appear in $2
  grep -F -x -v -f $2 $1; 
}


function circular-deps() {
  if [ $# -eq 0 ]
  then
    echo "src dir required"
    return 1;
  fi

  pnpx madge --circular --extensions ts "$1"
}

# function blast-with-requests() {
#   local NUM_OF_REQUESTS=200
#   if [ test -e $2 ]; then
#       local NUM_OF_REQUESTS=$2
#   fi
#   # seq 1 1000000 | xargs -n1 -P100 curl --silent --output /dev/null "https://hitrecord:staging@staging.hitrecordvr.tv"
#   seq 1 $NUM_OF_REQUESTS | xargs -n1 -P10  curl --silent --output /dev/null "$1"
# }

function slugify() {
  echo "$1" | sed -E s/[^a-zA-Z0-9]+/-/g | sed -E s/^-+\|-+$//g | tr "[:upper:]" "[:lower:]"
}

function mini-img() {
	local RESIZE=""
	if [ test -e $2 ]; then
		local RESIZE="-resize $2x"
	fi
	convert -strip -interlace Plane -gaussian-blur 0.05 "$RESIZE" -quality 85% "$1" "$1.min.jpg"
	exit 0
}

function fluxsync() {
  set -x;

  if [ $# -eq 0 ]
  then
    echo "env required"
    return 1;
  fi

  local PREV_CTX=$(kubectl ctx --current)

  if [[ "$1" == "production" ]]; then
    kubectl ctx hitrecord-production
  else
    kubectl ctx hitrecord-staging
  fi

  flux reconcile image repository "$1" -n flux-system
  flux reconcile source git flux-system -n flux-system

  kubectl ctx $PREV_CTX
}
