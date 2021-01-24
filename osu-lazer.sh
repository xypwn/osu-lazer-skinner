#! /usr/bin/env sh
export DOTNET_CLI_TELEMETRY_OPTOUT=1
dotnet /usr/lib/osu-lazer/osu!.dll "$@"
