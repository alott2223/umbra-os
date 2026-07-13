# Umbra OS — show the fastfetch splash once per interactive login shell.
if [ -n "${PS1:-}" ] && [ -z "${UMBRA_FETCH_SHOWN:-}" ] && command -v fastfetch >/dev/null 2>&1; then
    export UMBRA_FETCH_SHOWN=1
    fastfetch 2>/dev/null || true
fi
