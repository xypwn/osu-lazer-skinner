# osu-lazer-skinner
An osu!lazer installer and skinner for Linux

## Prerequisites
- Microsoft dotnet SDK
### Packages/resources for some distributions
- Gentoo overlay: <https://github.com/gentoo/dotnet>
- Archlinux package: `pacman -S dotnet-sdk`

## Usage
### Quick start guide
1. Clone the repository and cd into it

`git clone https://github.com/xypwn/osu-lazer-skinner.git && cd osu-lazer-skinner`

2. Download osu! files

`sh osu-lazer-skinner download`

3. (optional) Apply any osu! skin (replace path/to/skin.osk with the osu! skin filename)

`sh osu-lazer-skinner apply_skin path/to/skin.osk`

4. Build osu!

`sh osu-lazer-skinner build`

5. Install osu!

`sudo sh osu-lazer-skinner install`

### Further commands

- Run `sh osu-lazer-skinner help` for a list of further commands
