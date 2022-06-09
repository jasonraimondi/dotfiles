alias name="nname"
alias newname="nname"

function nname () {
  make --no-print-directory -C $HOME/dotfiles/bin/namer;
}

function fname() { 
  find . -iname "*$@*"; 
}

function removecontainers() {  
  docker stop $(docker ps -aq)  
  docker rm $(docker ps -aq)  
}  
  
function armaggedon() {  
  removecontainers  
  docker network prune -f  
  docker rmi -f $(docker images --filter dangling=true -qa)  
  docker volume rm $(docker volume ls --filter dangling=true -q)  
  docker rmi -f $(docker images -qa)  
}  

function lt() { 
  ls -ltrsa "$@" | tail; 
}

function remove_lines_from() {
  # removes lines from $1 if they appear in $2
  grep -F -x -v -f $2 $1; 
}

function git-cleanup () {
  echo "\nTHIS CREATES A LIST OF BRANCHES TO DELETE"
  echo "remove ones you'd like to keep from the list"
  echo "waiting 8s..."
  sleep 8
  git branch --merged >/tmp/merged-branches && vim /tmp/merged-branches && xargs git branch -d </tmp/merged-branches
}

function circular-deps() {
  if [ $# -eq 0 ]
  then
    echo "src dir required"
    return 1;
  fi

  pnpx madge --circular --extensions ts "$1"
}


function youtube-gif() {
  set -x

  if [ $# -eq 0 ]
  then
    echo "No arguments supplied"
    return 1;
  fi

  local STAMP=$(date +%Y-%m-%d_%H-%M)

  local YOUTUBE_LINK=$1
  local START=$2
  local DURATION=$3

  youtube-dl -o "$STAMP.input" --merge-output-format mkv "$YOUTUBE_LINK"

  ffmpeg -i "$STAMP.input.mkv" -ss $START -t $DURATION "$STAMP.output.mkv"
  ffmpeg -i "$STAMP.output.mkv" -vf "fps=10,scale=480:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" -loop 0 "$STAMP.output.gif"
  ffmpeg -i "$STAMP.output.gif" -vf "fps=5,scale=480:-1,smartblur=ls=-0.5,crop=iw:ih-2:0:0" "$STAMP.result.gif"
  
  gifsicle -O3 "$STAMP.result.gif" -o "$STAMP.result_optimized.gif"
}

function gifsnip() {
  local STAMP=$(date +%Y-%m-%d_%H-%M)

  local INPUT=$1
  local START=$2
  local DURATION=$3

  ffmpeg -i "$INPUT" -ss $START -t $DURATION "$STAMP.output.mp4"
  ffmpeg -i "$STAMP.output.mp4" -vf "fps=10,scale=480:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" -loop 0 "$STAMP.output.gif"
  ffmpeg -i "$STAMP.output.gif" -vf "fps=5,scale=480:-1,smartblur=ls=-0.5,crop=iw:ih-2:0:0" "$STAMP.result.gif"
  
  gifsicle -O3 "$STAMP.result.gif" -o "$STAMP.result_optimized.gif"
}

function gifit() {
  set -x
  if [ $# -eq 0 ]
  then
    echo "No arguments supplied"
    return 1;
  fi

  local INPUT_PATH=$1
  local STAMP=$(date +%Y-%m-%d_%H-%M)

  ffmpeg -i "$INPUT_PATH" "$STAMP.output.mp4"
  ffmpeg -i "$STAMP.output.mp4" -vf "fps=10,scale=480:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" -loop 0 "$STAMP.output.gif"
  ffmpeg -i "$STAMP.output.gif" -vf "fps=5,scale=480:-1,smartblur=ls=-0.5,crop=iw:ih-2:0:0" result.gif
  gifsicle -O3 "$STAMP.result.gif" -o "$STAMP.result_optimized.gif"
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

function progressify() {
  cat "$1" | gif-progress > "${1%.*}.progress.gif"
}

function squashit () {
  git reset --soft HEAD~$1 &&
  git commit --edit -m"$(git log --format=%B --reverse HEAD..HEAD@{1})"
}

# $1 input file(s)
# $2 output dir
function websiteify() {
  magick mogrify -resize "900x500^^" -gravity center -extent 900x500 -quality 80 -path $2 $1
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
