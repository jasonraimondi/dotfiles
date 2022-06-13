
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
