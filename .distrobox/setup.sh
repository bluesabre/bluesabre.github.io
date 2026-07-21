#!/usr/bin/env bash
# Provisions the distrobox container with the Ruby/Bundler toolchain used to
# build this site. There's no CI workflow (GitHub Pages builds this repo
# directly), so the Gemfile defers to the `github-pages` gem for versioning
# and this container uses Ruby 3.3 to match GitHub Pages' current production
# versions (see https://pages.github.com/versions.json).
set -euo pipefail

# $HOME/.bashrc is shared (bind-mounted) across every distrobox container on
# this machine, and this machine's other Jekyll site containers prepend
# $HOME/gems/bin (a Ruby 3.1 / Debian 12 toolchain) onto PATH from there.
# That shadows this container's own Ruby/Bundler, so pin PATH back whenever
# a login shell starts inside this specific container.
marker="# bluesabre-github-io PATH fix"
if ! grep -qF "$marker" "$HOME/.bashrc" 2>/dev/null; then
  cat >> "$HOME/.bashrc" <<EOF

$marker: keep this container's own Ruby/Bundler ahead of \$HOME/gems/bin
# from other containers.
if [ -r /run/.containerenv ] && grep -q '^name="bluesabre-github-io"' /run/.containerenv 2>/dev/null; then
  PATH="/usr/local/bin:/usr/bin:/bin:\$PATH"
fi
EOF
fi

# Init hooks run as root, but $HOME still points at /home/bluesabre. Running
# bundle directly here would leave root-owned files under ~/.bundle and
# vendor/bundle that the bluesabre user can't later write to, so do the
# install as that user instead.
runuser -u bluesabre -- bash -c "
  cd '$HOME/Developer/bluesabre.github.io'
  bundle config set --local path 'vendor/bundle'
  bundle install
"

echo "Provisioning complete. Open a new shell (or 'source ~/.bashrc'), then run:"
echo "  cd \$HOME/Developer/bluesabre.github.io && bundle exec jekyll serve"
