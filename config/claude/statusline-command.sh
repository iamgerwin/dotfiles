#!/usr/bin/env bash
# Claude Code status line mirroring the first line of the fish Tide prompt
# (os | pwd | git), followed by model and context-window usage segments.
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

# context: percent used + tokens left (bg green/yellow/red by usage, fg black)
ctx=$(printf '%s' "$input" | jq -r '
  .context_window as $c
  | if $c == null or ($c.context_window_size // 0) == 0 then empty else
      ($c.context_window_size) as $size
      | ($c.current_usage) as $u
      | (if $u != null then (($u.input_tokens // 0) + ($u.cache_creation_input_tokens // 0) + ($u.cache_read_input_tokens // 0)) else null end) as $used
      | (if $c.used_percentage != null then $c.used_percentage
         elif $used != null then ($used * 100 / $size) else null end) as $pct
      | if $pct == null then empty else
          (if $used != null then ($size - $used)
           elif $c.remaining_percentage != null then ($size * $c.remaining_percentage / 100)
           else ($size * (100 - $pct) / 100) end) as $left
          | "\($pct | floor) \($left | floor)"
        end
    end' 2>/dev/null)
if [ -n "$ctx" ]; then
  pct=${ctx%% *}
  left=${ctx##* }
  case "$pct$left" in
    *[!0-9-]*) ;;
    *)
      [ "$left" -lt 0 ] && left=0
      if [ "$left" -ge 1000000 ]; then
        left_h="$((left / 1000000)).$(( (left % 1000000) / 100000 ))M"
      elif [ "$left" -ge 1000 ]; then
        left_h="$((left / 1000))k"
      else
        left_h="$left"
      fi
      if [ "$pct" -lt 50 ]; then cbg="78;154;6"
      elif [ "$pct" -le 80 ]; then cbg="196;160;0"
      else cbg="204;0;0"; fi
      segment "$cbg" "0;0;0" " ${ctx_icon} ${pct}% used · ${left_h} left "
      ;;
  esac
fi

printf '%s%s%s%s%s' "$out" "$reset" "$(fgc "$prev_bg")" "$sep" "$reset"
