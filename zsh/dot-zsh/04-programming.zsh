export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
    *":$PNPM_HOME:"*) ;;
    *) export PATH="$PNPM_HOME:$PATH" ;;
esac

if command -v podman &> /dev/null; then
    prepend_path "$HOME/.local/share/containers/podman-desktop/extensions-storage/podman-desktop.compose/bin"
fi
