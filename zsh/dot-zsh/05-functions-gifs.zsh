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

# https://askubuntu.com/a/654305
function gifopt() {
    # args: $input_file ($loss_level)
    if [ -z "$2" ]
    then
        # use default of 30
        local loss_level=30
    elif [[ "$2" =~ ^[0-9]+$ ]] && [ "$2" -ge 30 -a "$2" -le 200 ]
    then
        local loss_level=$2
    else
        echo "${2:-"Loss level parameter must be an integer from 30-200"}" 1>&2
        exit 1
    fi
    local inputgif="${1?'Missing input file parameter'}"
    local gifname="$(basename $inputgif .gif)"
    local basegifname=$(echo "$gifname" | sed 's/_reduced_x[0-9]//g')
    local outputgif="$basegifname-opt.gif"
    gifsicle -O3 --lossy="$loss_level" -o "$outputgif" "$inputgif";
    local oldfilesize=$(du -h $inputgif | cut -f1)
    local newfilesize=$(du -h $outputgif | cut -f1)
    echo "File reduced from $oldfilesize to $newfilesize as $outputgif"
}

function gifspeedchange() {
  # args: $gif_path $frame_delay (1 = 0.1s)
  local orig_gif="${1?'Missing GIF filename parameter'}"
  local frame_delay=${2?'Missing frame delay parameter'}
  gifsicle --batch --delay $frame_delay $orig_gif
  local newframerate=$(echo "$frame_delay*10" | bc)
  echo "new GIF frame rate: $newframerate ms"
}
