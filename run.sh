#!/usr/bin/env bash
set -euo pipefail

project_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
local_dir="$project_dir/.local"
build_only=false

case "${1:-}" in
    "") ;;
    --build-only) build_only=true ;;
    -h|--help)
        echo "Usage: ./run.sh [--build-only]"
        echo "Build and launch YoutubeDownloader using project-local tools and settings."
        exit 0
        ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
esac
if [ "$#" -gt 1 ]; then
    echo "Usage: ./run.sh [--build-only]" >&2
    exit 2
fi

mkdir -p "$local_dir"
chmod 700 "$local_dir"

export DOTNET_ROOT="$local_dir/dotnet"
export DOTNET_CLI_HOME="$local_dir/dotnet-home"
export NUGET_PACKAGES="$local_dir/nuget"
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
export DOTNET_GENERATE_ASPNET_CERTIFICATE=false
export DOTNET_CLI_WORKLOAD_UPDATE_NOTIFY_DISABLE=true
export DOTNET_NOLOGO=1
export PATH="$DOTNET_ROOT:$PATH"

# Keep this customized build and its settings separate from upstream releases.
export YOUTUBEDOWNLOADER_SETTINGS_PATH="$local_dir/Settings.dat"
export YOUTUBEDOWNLOADER_ALLOW_AUTO_UPDATE=false

cd "$project_dir"

if [ ! -x "$DOTNET_ROOT/dotnet" ]; then
    echo "Installing the .NET SDK into $DOTNET_ROOT..."
    curl --fail --location --retry 3 --connect-timeout 15 \
        https://dot.net/v1/dotnet-install.sh \
        --output "$local_dir/dotnet-install.sh"
    bash "$local_dir/dotnet-install.sh" \
        --jsonfile "$project_dir/global.json" \
        --install-dir "$DOTNET_ROOT" \
        --no-path
fi

"$DOTNET_ROOT/dotnet" build "$project_dir/YoutubeDownloader.slnx" \
    --configuration Release \
    --artifacts-path "$local_dir/artifacts" \
    --disable-build-servers \
    -p:CSharpier_Bypass=true \
    --nologo

if [ "$build_only" = true ]; then
    exit 0
fi

exec "$DOTNET_ROOT/dotnet" \
    "$local_dir/artifacts/bin/YoutubeDownloader/release/YoutubeDownloader.dll"
