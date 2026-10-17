#!/usr/bin/env bash
# Claude Code status line mirroring the first line of the fish Tide prompt
# (os | pwd | git), followed by model, effort, 5-hour and weekly plan usage,
# and context-window usage segments.
# Reads the status line JSON from stdin. Requires jq and a Nerd Font.
input=$(cat)
cwd=$(printf '%s' "$input" | jq -r '.workspace.current_dir // .cwd // empty')
[ -z "$cwd" ] && cwd=$PWD

esc=$'\033'
fgc() { printf '%s[38;2;%sm' "$esc" "$1"; }
bgc() { printf '%s[48;2;%sm' "$esc" "$1"; }
reset="${esc}[0m"
sep=$'\xee\x82\xb0'        # U+E0B0 powerline separator
case "$(uname -s)" in
  Darwin) os_icon=$'\xef\x85\xb9' ;;  # U+F179 apple
  *)      os_icon=$'\xef\x8c\x9b' ;;  # U+F31B ubuntu
esac
home_icon=$'\xef\x80\x95'  # U+F015
dir_icon=$'\xef\x81\xbc'   # U+F07C
lock_icon=$'\xef\x80\xa3'  # U+F023
git_icon=$'\xef\x87\x93'   # U+F1D3
model_icon=$'\xef\x92\x84' # U+F484 robot-ish (nf-oct-hubot)
ctx_icon=$'\xef\x83\xa4'   # U+F0E4 gauge (nf-fa-dashboard)
effort_icon=$'\xef\x83\xa7' # U+F0E7 bolt (nf-fa-bolt)
clock_icon=$'\xef\x80\x97'  # U+F017 clock (nf-fa-clock_o)
cal_icon=$'\xef\x81\xb3'    # U+F073 calendar (nf-fa-calendar)

# usage bar with eighth-block precision: $1=percent (0-100), $2=width in cells
bar() {
  local pct=$1 width=$2 eighths full rem i b=""
  local parts=("" "▏" "▎" "▍" "▌" "▋" "▊" "▉")
  [ "$pct" -gt 100 ] && pct=100
  [ "$pct" -lt 0 ] && pct=0
  eighths=$(( pct * width * 8 / 100 ))
  full=$(( eighths / 8 )); rem=$(( eighths % 8 ))
  for ((i = 0; i < full; i++)); do b+="█"; done
  if [ "$full" -lt "$width" ]; then
    if [ "$rem" -gt 0 ]; then b+="${parts[$rem]}"; else b+="░"; fi
    for ((i = full + 1; i < width; i++)); do b+="░"; done
  fi
  printf '%s' "$b"
}

usage_bg() { # green < 50%, yellow <= 80%, red above
  if [ "$1" -lt 50 ]; then echo "78;154;6"
  elif [ "$1" -le 80 ]; then echo "196;160;0"
  else echo "204;0;0"; fi
}

out=""
prev_bg=""
segment() { # $1=bg rgb, $2=fg rgb, $3=text
  if [ -n "$prev_bg" ]; then
    out+="$(fgc "$prev_bg")$(bgc "$1")${sep}"
  fi
  out+="$(bgc "$1")$(fgc "$2")$3"
  prev_bg="$1"
}

# os (bg D4D4D4, fg E95420)
segment "212;212;212" "233;84;32" " ${os_icon} "

# pwd (bg 3465A4, fg E4E4E4)
case "$cwd" in
  "$HOME") disp="~"; icon=$home_icon ;;
  "$HOME"/*) disp="~${cwd#"$HOME"}"; icon=$dir_icon ;;
  *) disp=$cwd; icon=$dir_icon ;;
esac
[ -w "$cwd" ] || icon=$lock_icon
segment "52;101;164" "228;228;228" " ${icon} ${disp} "

# git (bg 4E9A06, or C4A000 when dirty; fg black)
if git -C "$cwd" --no-optional-locks rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null \
    || git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
  branch=${branch:0:24}
  counts=$(git -C "$cwd" --no-optional-locks status --porcelain=v1 2>/dev/null | awk '
    /^\?\?/ { u++; next }
    { x = substr($0,1,1); y = substr($0,2,1)
      if (x != " ") s++
      if (y != " ") d++ }
    END { r = ""
      if (s) r = r " +" s
      if (d) r = r " !" d
      if (u) r = r " ?" u
      print r }')
  if [ -n "$counts" ]; then gbg="196;160;0"; else gbg="78;154;6"; fi
  segment "$gbg" "0;0;0" " ${git_icon} ${branch}${counts} "
fi

# model (bg 5C3566, fg E4E4E4)
model=$(printf '%s' "$input" | jq -r '.model.display_name // empty' 2>/dev/null)
if [ -n "$model" ]; then
  segment "92;53;102" "228;228;228" " ${model_icon} ${model} "
fi

# effort (bg 75507B, fg E4E4E4)
effort=$(printf '%s' "$input" | jq -r '.effort.level // empty' 2>/dev/null)
if [ -n "$effort" ]; then
  segment "117;80;123" "228;228;228" " ${effort_icon} ${effort} "
fi

# plan usage limits: 5-hour session and weekly (bg green/yellow/red by usage, fg black)
limits=$(printf '%s' "$input" | jq -r '
  [.rate_limits.five_hour.used_percentage, .rate_limits.seven_day.used_percentage]
  | map(if . == null then "-" else floor end) | join(" ")' 2>/dev/null)
five=${limits%% *}
week=${limits##* }
case "$five" in
  ''|*[!0-9]*) ;;
  *) segment "$(usage_bg "$five")" "0;0;0" " ${clock_icon} 5h $(bar "$five" 10) ${five}% " ;;
esac
case "$week" in
  ''|*[!0-9]*) ;;
  *) segment "$(usage_bg "$week")" "0;0;0" " ${cal_icon} week $(bar "$week" 10) ${week}% " ;;
esac

# context window of this conversation, percent used (bg green/yellow/red by usage, fg black)
pct=$(printf '%s' "$input" | jq -r '
  .context_window as $c
  | if $c == null or ($c.context_window_size // 0) == 0 then empty else
      ($c.current_usage) as $u
      | (if $c.used_percentage != null then $c.used_percentage
         elif $u != null then ((($u.input_tokens // 0) + ($u.cache_creation_input_tokens // 0) + ($u.cache_read_input_tokens // 0)) * 100 / $c.context_window_size)
         else empty end)
      | floor
    end' 2>/dev/null)
case "$pct" in
  ''|*[!0-9]*) ;;
  *) segment "$(usage_bg "$pct")" "0;0;0" " ${ctx_icon} ctx ${pct}% " ;;
esac

printf '%s%s%s%s%s' "$out" "$reset" "$(fgc "$prev_bg")" "$sep" "$reset"
