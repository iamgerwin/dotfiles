#!/usr/bin/env zsh
# Zsh options configuration

# Directory navigation
setopt AUTO_CD              # Go to folder path without using cd
setopt AUTO_PUSHD           # Push the current directory visited on the stack
setopt PUSHD_IGNORE_DUPS    # Do not store duplicates in the stack
setopt PUSHD_SILENT         # Do not print the directory stack after pushd or popd

# History configuration
setopt EXTENDED_HISTORY     # Write the history file in the ":start:elapsed;command" format
setopt HIST_EXPIRE_DUPS_FIRST # Expire duplicate entries first when trimming history
setopt HIST_IGNORE_DUPS     # Don't record an entry that was just recorded again
setopt HIST_IGNORE_ALL_DUPS # Delete old recorded entry if new entry is a duplicate
setopt HIST_FIND_NO_DUPS    # Do not display a line previously found
setopt HIST_IGNORE_SPACE    # Don't record an entry starting with a space
setopt HIST_SAVE_NO_DUPS    # Don't write duplicate entries in the history file
setopt HIST_REDUCE_BLANKS   # Remove superfluous blanks before recording entry
setopt HIST_VERIFY          # Don't execute immediately upon history expansion
setopt INC_APPEND_HISTORY   # Write to the history file immediately, not when the shell exits
setopt SHARE_HISTORY        # Share history between all sessions

# Completion
setopt ALWAYS_TO_END        # Move cursor to the end of a completed word
setopt AUTO_MENU            # Show completion menu on a successive tab press
setopt AUTO_LIST            # Automatically list choices on ambiguous completion
setopt AUTO_PARAM_SLASH     # If completed parameter is a directory, add a trailing slash
setopt COMPLETE_IN_WORD     # Complete from both ends of a word
setopt NO_COMPLETE_ALIASES  # Don't complete aliases

# Correction
setopt CORRECT              # Command correction
setopt CORRECT_ALL          # Argument correction

# Globbing and matching
setopt EXTENDED_GLOB        # Use extended globbing syntax
setopt GLOB_DOTS            # Include dotfiles in globbing
setopt NO_CASE_GLOB         # Case insensitive globbing

# Input/Output
setopt NO_CLOBBER           # Don't overwrite existing files with > and >>
setopt INTERACTIVE_COMMENTS # Allow comments in interactive shell
setopt RC_QUOTES            # Allow 'Henry''s Garage' instead of 'Henry'\''s Garage'

# Job Control
setopt NO_BG_NICE           # Don't run all background jobs at a lower priority
setopt NO_CHECK_JOBS        # Don't report on jobs when shell exit
setopt NO_HUP               # Don't kill jobs on shell exit
setopt LONG_LIST_JOBS       # List jobs in the long format by default

# Miscellaneous
setopt PROMPT_SUBST         # Enable parameter expansion, command substitution, and arithmetic expansion in the prompt