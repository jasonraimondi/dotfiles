function favicon() {
  if [ $# -eq 0 ]
  then
    echo "input required"
    return 1;
  fi

  magick $1 -define icon:auto-resize=16,24,32,48,64 favicon.ico
}

function rcat() {
  if [ $# -eq 0 ]
  then
    echo "src dir required"
    return 1;
  fi

  local directory="$1"

  if [[ $# -eq 0 ]]; then
    echo "Please provide the directory path as an argument."
    return 1
  fi

  for item in "$directory"/**/*(.); do
    if [[ -f "$item" ]]; then
      echo "=== $item ==="
      cat "$item"
      echo
    fi
  done
}

function e() {
  if [ "$1" = "" ] ; then
    exec $EDITOR .
  else
    exec $EDITOR "$1"
  fi
}

function latest() {
  curl -sL "https://api.github.com/repos/$1/releases/latest" | jq -r ".tag_name"
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

function sidebyside() {
  local OUTPUT="${3:-ouput.png}"
  if [ -z "${2}" ]; then
    echo "requires two inputs";
    return 1;
  fi;
  montage "$1" "$2" -tile 2x1 -geometry +20+20 -background none "$OUTPUT"
}

# Run `dig` and display the most useful info
function digga() {
  dig +nocmd "$1" any +multiline +noall +answer;
}

function targz() {
  local tmpFile="${@%/}.tar";
  tar -cvf "${tmpFile}" --exclude=".DS_Store" "${@}" || return 1;

  size=$(
    stat -f"%z" "${tmpFile}" 2> /dev/null; # macOS `stat`
    stat -c"%s" "${tmpFile}" 2> /dev/null;  # GNU `stat`
  );

  local cmd="";
  if (( size < 52428800 )) && hash zopfli 2> /dev/null; then
    # the .tar file is smaller than 50 MB and Zopfli is available; use it
    cmd="zopfli";
  else
    if hash pigz 2> /dev/null; then
      cmd="pigz";
    else
      cmd="gzip";
    fi;
  fi;

  echo "Compressing .tar ($((size / 1000)) kB) using \`${cmd}\`…";
  "${cmd}" -v "${tmpFile}" || return 1;
  [ -f "${tmpFile}" ] && rm "${tmpFile}";

  zippedSize=$(
    stat -f"%z" "${tmpFile}.gz" 2> /dev/null; # macOS `stat`
    stat -c"%s" "${tmpFile}.gz" 2> /dev/null; # GNU `stat`
  );

  echo "${tmpFile}.gz ($((zippedSize / 1000)) kB) created successfully.";
}


function yt-dlmerge() {
  # Check if the playlist URL is provided
  if [ -z "$1" ]; then
    echo "Please provide the YouTube playlist URL as an argument."
    return 1
  fi

  # Set the playlist URL
  local playlist_url="$1"

  # Set the output file name
  local output_file="merged_playlist.mp4"

  # Download the playlist using yt-dlp
  yt-dlp -o "%(playlist_index)s-%(title)s.%(ext)s" --yes-playlist "$playlist_url"

  # Create a temporary file to store the video file paths
  local temp_file="temp_video_list.txt"

  # Find all the downloaded video files and save their paths to the temporary file
  find . -maxdepth 1 -type f -name "*-*.mp4" -print0 | sort -z -V | xargs -0 -I {} echo "file '{}'" > "$temp_file"

  # Merge the video files using ffmpeg
  ffmpeg -f concat -safe 0 -i "$temp_file" -c copy "$output_file"

  # Remove the temporary file
  rm "$temp_file"

  echo "Playlist merged successfully. Output file: $output_file"
}

# download a single directory out of a github repo, by url or by owner/repo + path
function ghdl() {
  local repo dir branch

  if [[ "$1" == *github.com/* ]]; then
    local urlpath="${1#*github.com/}"
    urlpath="${urlpath%/}"
    repo="${urlpath%%/tree/*}"
    local rest="${urlpath#*/tree/}"
    branch="${rest%%/*}"
    dir="${rest#*/}"
    if [[ "$urlpath" != */tree/* || "$dir" == "$branch" ]]; then
      echo "usage: ghdl https://github.com/owner/repo/tree/branch/path/to/dir"
      return 1
    fi
  elif [ -n "${2:-}" ]; then
    repo="$1"
    dir="$2"
    branch="${3:-}"
  else
    echo "usage: ghdl https://github.com/owner/repo/tree/branch/path/to/dir"
    echo "       ghdl owner/repo path/to/dir [branch]"
    return 1
  fi

  local tmp
  tmp=$(mktemp -d) || return 1

  local -a branch_arg
  [ -n "$branch" ] && branch_arg=(--branch "$branch")

  if ! git clone --depth 1 --filter=blob:none --sparse "${branch_arg[@]}" "https://github.com/$repo.git" "$tmp"; then
    rm -rf "$tmp"
    return 1
  fi

  (cd "$tmp" && git sparse-checkout set "$dir")

  if [ ! -d "$tmp/$dir" ]; then
    echo "ERROR: $dir not found in $repo"
    rm -rf "$tmp"
    return 1
  fi

  mv "$tmp/$dir" .
  rm -rf "$tmp"
}
