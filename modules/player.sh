#!/usr/bin/env bash

#importing colors
DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DIR/modules/ui.sh"

#pick a browser whose cookies yt-dlp can actually read (empty = no cookies)
cookie_browser() {
    if [ -n "$PHUB_COOKIES_BROWSER" ]; then
        echo "$PHUB_COOKIES_BROWSER"
        return
    fi
    local d
    for d in "$HOME/Library/Application Support/Firefox/Profiles" "$HOME/.mozilla/firefox" \
             "$HOME/snap/firefox/common/.mozilla/firefox"; do
        if [ -d "$d" ] && [ -n "$(find "$d" -maxdepth 2 -name cookies.sqlite -print -quit 2>/dev/null)" ]; then
            echo firefox
            return
        fi
    done
    echo ""
}

#pick a video output: render inside the terminal unless PHUB_VO says otherwise
terminal_vo_args() {
    local vo="$PHUB_VO"
    if [ -z "$vo" ]; then
        case "$TERM" in
            xterm-kitty) vo=kitty ;;
            *)           vo=tct ;;
        esac
    fi
    case "$vo" in
        window|gpu) ;;                        # normal mpv window
        kitty)  printf '%s\n' --vo=kitty ;;
        tct)
            printf '%s\n' --vo=tct
            # Terminal.app and friends are 256-color only
            [ "$COLORTERM" = truecolor ] || [ "$COLORTERM" = 24bit ] || printf '%s\n' --vo-tct-256=yes
            ;;
        *)      printf '%s\n' "--vo=$vo" ;;
    esac
}

#resolve a playable stream url. modules/stream.py reads the mobile page (whose
#CDN tokens cover the segments, unlike the desktop ones) and verifies a real
#segment downloads before handing the url over. yt-dlp stays as a fallback.
PHUB_COOKIE_JAR=""
phub_cookie_jar() {
    if [ -z "$PHUB_COOKIE_JAR" ]; then
        PHUB_COOKIE_JAR="$(mktemp -t phubcookies)"
        {
            printf '# Netscape HTTP Cookie File\n'
            printf '.pornhub.com\tTRUE\t/\tFALSE\t0\tplatform\tmobile\n'
            printf '.pornhub.com\tTRUE\t/\tFALSE\t0\taccessAgeDisclaimerPH\t1\n'
        } > "$PHUB_COOKIE_JAR"
    fi
    echo "$PHUB_COOKIE_JAR"
}

#the CDN ties its tokens to the user agent that fetched the page
phub_user_agent() {
    "$DIR/modules/stream.py" --user-agent 2>/dev/null
}

resolve_stream() {
    local url="$1" fmt="$2" browser="$3" max_h="$4"
    local viewkey="${url##*viewkey=}"
    local attempt candidate args=()

    for attempt in 1 2 3; do
        candidate="$("$DIR/modules/stream.py" "$viewkey" "$max_h" 2>/dev/null | head -1)"
        if [ -n "$candidate" ]; then
            printf '%s' "$candidate"
            return 0
        fi
        sleep 2
    done

    #fallback: let yt-dlp have a go
    args=(-f "$fmt" -g --no-playlist --cookies "$(phub_cookie_jar)")
    [ -n "$browser" ] && args+=(--cookies-from-browser="$browser")
    candidate="$(yt-dlp "${args[@]}" "$url" 2>/dev/null | head -1)"
    [ -z "$candidate" ] && return 1
    printf '%s' "$candidate"
}

#spinner 
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'

    while kill -0 "$pid" 2>/dev/null; do
        for i in $(seq 0 3); do
            printf "\r   ${HOT_PINK}%s${NC} Fetching stream... " "${spinstr:$i:1}" > /dev/tty
            sleep "$delay"
        done
    done
    printf "\r" > /dev/tty
}

play_video() {
    viewkey="$1"
    page_url="https://www.pornhub.com/view_video.php?viewkey=$viewkey"

    start_time=$(date +%s)

    #pre play
    clear

    messages=(
        "🔥 Preparing your video..."
        "💋 Unwrapping forbidden packets..."
        "💭 Please wait, lust takes time..."
        "😈 Negotiating with the content gods..."
        "📡 Tapping into the pleasure servers..."
        "🧠 Calibrating dopamine receptors..."
        "🍑 Warming up the pixels..."
        "🔓 Bypassing moral firewalls..."
        "💦 Hydrating the stream pipeline..."
        "📦 Extracting premium sensations..."
        "🕯 Lighting candles in the data center..."
        "🎥 Aligning sinful frames..."
    )
    pick1=${messages[RANDOM % ${#messages[@]}]}
    pick2=${messages[RANDOM % ${#messages[@]}]}
    pick3=${messages[RANDOM % ${#messages[@]}]}

    echo "" > /dev/tty
    echo -e "  ${HOT_PINK}$pick1${NC}" > /dev/tty
    sleep 0.3
    echo -e "  ${PINK}$pick2${NC}" > /dev/tty
    sleep 0.3
    echo -e "  ${ROSE}$pick3${NC}" > /dev/tty
    echo "" > /dev/tty

    #final
    echo "" > /dev/tty
    echo -e "  ${GOLD}▶ Launching player...${NC}" > /dev/tty
    sleep 0.6

    #play — resolve the stream ourselves so we can work around dead CDN hosts
    browser="$(cookie_browser)"

    vo_args=()
    while IFS= read -r a; do [ -n "$a" ] && vo_args+=("$a"); done < <(terminal_vo_args)

    if [ ${#vo_args[@]} -gt 0 ]; then
        fmt="best[height<=480]/best"      # terminal cells are tiny; save the CPU
        max_h=480
    else
        fmt="best[height<=1080]/best"
        max_h=1080
    fi

    tmp_url="$(mktemp -t phuburl)"
    resolve_stream "$page_url" "$fmt" "$browser" "$max_h" > "$tmp_url" &
    spinner $!
    wait $!
    stream_url="$(cat "$tmp_url")"
    rm -f "$tmp_url"
    if [ -z "$stream_url" ]; then
        return 1
    fi

    mpv_args=(
        --really-quiet
        --profile=fast
        --cache=yes
        --cache-secs=10
        --no-ytdl
        --referrer="https://www.pornhub.com/"
        --user-agent="$(phub_user_agent)"
        --http-header-fields="Cookie: platform=mobile; accessAgeDisclaimerPH=1"
    )
    [ ${#vo_args[@]} -eq 0 ] && mpv_args+=(--hwdec=auto)

    mpv "${mpv_args[@]}" "${vo_args[@]}" "$stream_url" < /dev/tty > /dev/tty 2>&1
    mpv_status=$?

    end_time=$(date +%s)
    duration=$((end_time - start_time))

    #a clean exit is a success even if the user quit straight away
    [ "$mpv_status" -ne 0 ] && [ "$duration" -lt 5 ] && return 1

    return 0
}

download_spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'

    while kill -0 "$pid" 2>/dev/null; do
        for i in $(seq 0 3); do
            printf "\r   ${GOLD}%s${NC} Downloading... " "${spinstr:$i:1}" > /dev/tty
            sleep "$delay"
        done
    done
    printf "\r" > /dev/tty
}

download_video() {
    viewkey="$1"
    quality="$2"
    page_url="https://www.pornhub.com/view_video.php?viewkey=$viewkey"
    download_dir="$HOME/Videos/phub-cli"

    # Create download directory if it doesn't exist
    mkdir -p "$download_dir"

    # Set format based on quality selection
    case "$quality" in
        1)
            format="bestvideo+bestaudio/best"
            quality_name="best"
            ;;
        2)
            format="bestvideo[height<=720]+bestaudio/best[height<=720]"
            quality_name="720p"
            ;;
        3)
            format="bestvideo[height<=480]+bestaudio/best[height<=480]"
            quality_name="480p"
            ;;
        4)
            format="bestvideo[height<=360]+bestaudio/best[height<=360]"
            quality_name="360p"
            ;;
        *)
            format="bestvideo+bestaudio/best"
            quality_name="best"
            ;;
    esac

    clear

    messages=(
        "📥 Initiating download sequence..."
        "💾 Preparing storage containers..."
        "🔒 Securing the goods..."
        "📦 Packaging premium content..."
        "🚀 Launching download protocol..."
        "💿 Writing to disk with passion..."
    )
    pick1=${messages[RANDOM % ${#messages[@]}]}
    pick2=${messages[RANDOM % ${#messages[@]}]}

    echo "" > /dev/tty
    echo -e "  ${HOT_PINK}$pick1${NC}" > /dev/tty
    sleep 0.3
    echo -e "  ${PINK}$pick2${NC}" > /dev/tty
    echo "" > /dev/tty
    echo -e "  ${GOLD}📺 Quality: $quality_name${NC}" > /dev/tty
    echo -e "  ${DEEP_PINK}📁 Destination: $download_dir${NC}" > /dev/tty
    echo "" > /dev/tty

    # Download with yt-dlp
    browser="$(cookie_browser)"
    ytdlp_args=(
        -f "$format"
        -o "$download_dir/%(title)s.%(ext)s"
        --no-playlist
        --progress
        --cookies "$(phub_cookie_jar)"
    )
    [ -n "$browser" ] && ytdlp_args+=(--cookies-from-browser="$browser")

    yt-dlp "${ytdlp_args[@]}" "$page_url" 2>&1 | tee /tmp/phub_download.$$ > /dev/tty

    download_status=${PIPESTATUS[0]}

    if [ "$download_status" -eq 0 ]; then
        echo "" > /dev/tty
        echo -e "  ${GOLD}✅ Download complete!${NC}" > /dev/tty
        echo -e "  ${DEEP_PINK}📁 Saved to: $download_dir${NC}" > /dev/tty
        sleep 1
        return 0
    else
        echo "" > /dev/tty
        echo -e "  ${RED}❌ Download failed.${NC}" > /dev/tty
        echo -e "  ${ROSE}😞 Video might be unavailable or restricted.${NC}" > /dev/tty
        sleep 2
        return 1
    fi

    rm -f /tmp/phub_download.$$
}

open_in_browser() {
    viewkey="$1"
    page_url="https://www.pornhub.com/view_video.php?viewkey=$viewkey"

    echo "" > /dev/tty
    echo -e "  ${HOT_PINK}🌐 Opening in browser...${NC}" > /dev/tty

    if command -v xdg-open >/dev/null; then
        xdg-open "$page_url" 2>/dev/null &
    elif command -v open >/dev/null; then
        open "$page_url" 2>/dev/null &
    else
        echo -e "  ${RED}❌ No browser opener found${NC}" > /dev/tty
        sleep 2
        return 1
    fi

    sleep 1
    return 0
}
