# Umbra OS — shell opsec hygiene (sourced for interactive shells).

# Restrictive default file creation mask (also set in login.defs).
umask 027

# Keep shell history small and out of disk where practical. To make bash fully
# amnesic (no on-disk history at all), uncomment the next two lines:
# unset HISTFILE
# export HISTSIZE=0
export HISTCONTROL=ignoreboth:erasedups
export HISTSIZE=1000
export HISTFILESIZE=2000

# Don't leak the timezone/locale beyond UTC unless the user sets it.
: "${TZ:=UTC}"; export TZ

# Handy: 'scrub <file>' strips metadata from a document/image before you share it.
scrub() { command -v mat2 >/dev/null && mat2 "$@" || echo "mat2 not installed"; }
