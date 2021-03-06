#!/usr/bin/env bash

INSTALLDIR=$(pwd)
dotfiles_dir="$(dirname $0)"

source ${dotfiles_dir}/files/scripts/hubinstall
source ${dotfiles_dir}/files/scripts/hashinstall

path() {
  mkdir -p "$(dirname "$1")"
  echo "$(cd "$(dirname "$1")"; pwd)/$(basename "$1")"
}

link() {
  create_link "$dotfiles_dir/$1" "${HOME}/$1"
}

create_link() {
  real_file="$(path "$1")"
  link_file="$(path "$2")"

  rm -rf $link_file
  ln -s $real_file $link_file

  echo "$real_file <-> $link_file"
}

gem_install_or_update() {
  if gem list "$1" --installed > /dev/null; then
    gem update "${@}"
  else
    gem install "${@}"
    # rbenv rehash
  fi
}

getNerdFont() {
  getFromRawGithub 'ryanoasis/nerd-fonts/' "patched-fonts/${1}" 'latest'
}

installEls() {
  installFromRawGithub 'AnthonyDiGirolamo/els'
}

installAwless() {
  pipeBashFromRawGithub 'wallix/awless/master' 'getawless.sh'
  mv awless ~/.local/bin/
}

installFastPath() {
  # https://github.com/mfornasa/docker-fastpath
  mkdir -p ~/.local/bin/
  version='linux'
  arch='-amb64'
  if [[ "$OSTYPE" == "darwin"* ]]; then
    version='osx'
    arch=''
  fi
  curl https://docker-fastpath.s3-eu-west-1.amazonaws.com/releases/${version}/docker-fastpath-${version}${arch}-latest.zip > fastpath.zip
  unzip fastpath.zip
  chmod +x fastpath && mv fastpath ~/.local/bin/
}

installFission() {
  # http://fission.io/
  mkdir -p ~/.local/bin/
  version='linux'
  if [[ "$OSTYPE" == "darwin"* ]]; then
    version='mac'
  fi
  curl http://fission.io/$version/fission > fission && chmod +x fission && mv fission ~/.local/bin/
}

installMinikube() {
  mkdir -p ~/.local/bin/
  curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-$(uname -s | tr '[:upper:]' '[:lower:]')-amd64
  chmod +x minikube
  mv minikube ~/.local/bin/
}

installKrew() {
  mkdir -p ${HOME}/.krew/bin
  cd "$(mktemp -d)" &&
  curl -fsSLO "https://storage.googleapis.com/krew/latest/krew.{tar.gz,yaml}" &&
  tar zxvf krew.tar.gz &&
  ./krew-"$(uname | tr '[:upper:]' '[:lower:]')_amd64" install --manifest=krew.yaml --archive=krew.tar.gz
  cd ${INSTALLDIR}

  # install krew packages
  kubectl krew update
  while read -r PKG; do
    [[ "${PKG}" =~ ^#.*$ ]] && continue
    [[ "${PKG}" =~ ^\\s*$ ]] && continue
    kubectl krew install "${PKG}"
  done < files/pkgs/krew.lst
}

installKubeScripts() {
  installFromGithub 'Praqma/helmsman' "${1}" "${2}"
  installFromGithub 'shyiko/kubesec' "${1}" "${2}"
  installFromGithub 'kubernetes-sigs/kubebuilder' "${1}" "${2}"
  installFromGithub 'kubernetes-sigs/kustomize' "${1}" "${2}"
  installFromGithub 'operator-framework/operator-sdk' "${1}" "${2}"
  installFromRawGithub 'johanhaleby/kubetail'
  installFromRawGithub 'ctron/kill-kube-ns'
  installKrew

  if [ ! -d  ${HOME}/.kube-fzf ]; then
    git clone https://github.com/arunvelsriram/kube-fzf.git ${HOME}/.kube-fzf
  else
    cd ${HOME}/.kube-fzf/
    git pull
    cd ${INSTALLDIR}
  fi

  if [ ! -d  ${HOME}/.kbenv ]; then
    git clone https://github.com/alexppg/kbenv.git ${HOME}/.kbenv
  else
    cd ${HOME}/.kbenv/
    git pull
    cd ${INSTALLDIR}
  fi

  if [ ! -d  ${HOME}/.helmenv ]; then
    git clone https://github.com/alexppg/helmenv.git ${HOME}/.helmenv
  else
    cd ${HOME}/.helmenv/
    git pull
    cd ${INSTALLDIR}
  fi
}

installDCOScli() {
  mkdir -p ~/.local/bin/
  curl -Lo dcos https://downloads.dcos.io/binaries/cli/$(uname -s | tr '[:upper:]' '[:lower:]')/x86-64/latest/dcos
  chmod +x dcos
  mv dcos ~/.local/bin/
}

installGoss() {
  mkdir -p ~/.local/bin/
  curl -fsSL https://goss.rocks/install | GOSS_DST=~/.local/bin sh
}

installDepcon() {
  installFromGithub 'ContainX/depcon' ${1} ${2}
}

installCargo() {
  while read -r PKG; do
    [[ "${PKG}" =~ ^#.*$ ]] && continue
    [[ "${PKG}" =~ ^\\s*$ ]] && continue
    cargo install "${PKG}"
  done < files/pkgs/cargo.lst
}

installGems() {
  while read -r PKG; do
    [[ "${PKG}" =~ ^#.*$ ]] && continue
    [[ "${PKG}" =~ ^\\s*$ ]] && continue
    gem_install_or_update "${PKG}"
  done < files/pkgs/gem.lst
}

installChefGems() {
  while read -r PKG; do
    [[ "${PKG}" =~ ^#.*$ ]] && continue
    [[ "${PKG}" =~ ^\\s*$ ]] && continue
    chef gem install "${PKG}"
  done < files/pkgs/chef_gem.lst
}

installPips() {
  while read -r PKG; do
    [[ "${PKG}" =~ ^#.*$ ]] && continue
    [[ "${PKG}" =~ ^\\s*$ ]] && continue
    pip install -U "${PKG}"
  done < files/pkgs/pip.lst
}

installNpms() {
  while read -r PKG; do
    [[ "${PKG}" =~ ^#.*$ ]] && continue
    [[ "${PKG}" =~ ^\\s*$ ]] && continue
    npm install -g "${PKG}"
  done < files/pkgs/npm.lst
}

cleanGoPkgs() {
  rm -rf ${HOME}/.glide/*
  rm -rf ${GOPATH/:*}/src/*
  rm -rf ${GOPATH/:*}/pkg/*
  rm -rf ${GOPATH/:*}/.cache
  rm -rf ${HOME}/.cache/go-build/
}

installGoPkgs() {
  cleanGoPkgs
  while read -r PKG; do
    [[ "${PKG}" =~ ^#.*$ ]] && continue
    [[ "${PKG}" =~ ^\\s*$ ]] && continue
    echo ">>> ${PKG}"
    go get -u "${PKG}"
  done < files/pkgs/go.lst
  cd ${INSTALLDIR}
  cleanGoPkgs
  echo ">>> helm"
  go get -d -u k8s.io/helm/cmd/helm
  cd ${GOPATH/:*}/src/k8s.io/helm/
  make bootstrap build
  mv bin/* ${GOPATH/:*}/bin/
  echo ">>> Cleanup go sources"
  cd ${INSTALLDIR}
  cleanGoPkgs
}

installhelmPlugins() {
  if ! [ -x "$(command -v helm)" ]; then
    if [[ "$OSTYPE" != "darwin"* ]]; then
      sudo apt-get install helm
    else
      brew install kubernetes-helm
    fi
  fi
  helm init --client-only
  while read -r PKG; do
    [[ "${PKG}" =~ ^#.*$ ]] && continue
    [[ "${PKG}" =~ ^\\s*$ ]] && continue
    helm plugin install "${PKG}"
  done < files/pkgs/helm.lst
}

installScripts() {
  mkdir -p ${HOME}/.local/bin/
  cp -r files/scripts/* ${HOME}/.local/bin/
  curl -sLo testssl testssl.sh
  chmod +x testssl
  mv testssl ${HOME}/.local/bin/
  installFromRawGithub 'huyng/bashmarks' 'bashmarks.sh'
  installFromRawGithub 'ahmetb/goclone'
  installFromRawGithub 'mykeels/slack-theme-cli' 'slack-theme'
  if [[ "$OSTYPE" == *"android"* ]]; then
    termux-fix-shebang ${HOME}/.local/bin/*
  fi
}

installChefVM() {
  git clone https://github.com/trobrock/chefvm.git ~/.chefvm
  ~/.chefvm/bin/chefvm init
}

installAtomPackages() {
  mkdir -p ${HOME}/.atom/
  cd ${INSTALLDIR}
  # Backup package list with:
  #   apm list --installed --bare | cut -d'@' -f1 | grep -vE '^$' > atom-packages.lst
  cp files/atom/* ${HOME}/.atom/
  # apm install --packages-file files/pkgs/atom-packages.lst
  cat files/pkgs/atom-packages.lst | grep -Ev '\s*#' | xargs -L1 apm install
}

installVscodePackages() {
  settings="$HOME/.config/Code/User"
  if [[ "$OSTYPE" == "darwin"* ]]; then
    settings="$HOME/Library/Application Support/Code/User"
  fi
  mkdir -p $settings
  cp -r files/vscode/* $settings/
  while read -r PKG; do
    [[ "${PKG}" =~ ^#.*$ ]] && continue
    [[ "${PKG}" =~ ^\\s*$ ]] && continue
    code --install-extension "${PKG}"
  done < files/pkgs/vscode-packages.lst
}

installTmuxConf() {
  cp files/tmux.conf.local ${HOME}/.tmux.conf.local
  if [ ! -d  ${HOME}/.tmux ]; then
    git clone https://github.com/gpakosz/.tmux.git ${HOME}/.tmux
  else
    cd ${HOME}/.tmux/
    git pull
    cd ${INSTALLDIR}
  fi
  if [ ! -s ${HOME}/.tmux.conf ]; then
    ln -s ${HOME}/.tmux/.tmux.conf ${HOME}/.tmux.conf
  fi
}

installVimPlugins() {
  mkdir -p ${HOME}/.vim/config/
  mkdir -p ${HOME}/.vim/ftdetect/
  mkdir -p ${HOME}/.vim/ftplugin/
  mkdir -p ${HOME}/.vim/autoload/
  mkdir -p ${HOME}/.vim/bundle/
  mkdir -p ${HOME}/.config/nvim/

  cd ${INSTALLDIR}

  cp files/vim/vimrc ${HOME}/.vimrc
  cp files/vim/vimrc.local ${HOME}/.vimrc.local
  cp -r files/vim/config/* ${HOME}/.vim/config/
  cp -r files/vim/ft* ${HOME}/.vim/
  if [ ! -s ~/.config/nvim/init.vim ]; then
    ln -s ${HOME}/.vimrc ${HOME}/.config/nvim/init.vim
    ln -s ${HOME}/.vim/autoload/ ${HOME}/.config/nvim/autoload
    ln -s ${HOME}/.vim/ftdetect/ ${HOME}/.config/nvim/ftdetect
    ln -s ${HOME}/.vim/ftplugin/ ${HOME}/.config/nvim/ftplugin
  fi

  # Using vim Vundle
  # if [ ! -d  ${HOME}/.vim/bundle/Vundle.vim ]; then
  #   git clone https://github.com/VundleVim/Vundle.vim.git ${HOME}/.vim/bundle/Vundle.vim
  # fi
  #
  # vim +PluginInstall +qall
  # cd ${HOME}/.vim/bundle/YouCompleteMe
  # ./install.py
  # cd ${INSTALLDIR}

  # Using vim-plug
  if [ ! -f ~/.vim/autoload/plug.vim ]; then
    curl -sLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  fi
  vim +PlugInstall +qall
}

installGitConf() {
  source config.sh
  #read -p "Please enter your name (for gitconfig):" NAME
  #read -p "Please enter your email address (for gitconfig):" EMAIL

  # cp files/git/gitconfig ${HOME}/.gitconfig
  sedcmd=''
  for var in NAME EMAIL; do
    printf -v sc 's|${%s}|%s|;' ${var} "${!var//\//\\/}"
    sedcmd+="${sc}"
  done
  cat files/git/gitconfig | sed -e "${sedcmd}" > ${HOME}/.gitconfig
  cp files/git/gitexcludes ${HOME}/.gitexcludes
}

installBashConf() {
  if [[ -z "${SHELLVARS}" ]]; then
    SHELLVARS=$(comm -3 <(compgen -v | sort) <(compgen -e | sort) | grep -v '^_')
    source config.sh
    CONF=$(comm -3 <(compgen -v | sort) <(compgen -e | sort) | grep -v '^_')
    CONF=$(comm -3 <(echo ${CONF} | tr ' ' '\n' | sort -u ) <(echo ${SHELLVARS} | tr ' ' '\n' | sort -u) | grep -v 'SHELLVARS')
  fi

  mkdir -p ${HOME}/.bash/

  cd ${INSTALLDIR}

  cp files/bash/git_prompt.sh ${HOME}/.bash/
  cp files/bash/git-prompt-colors.sh ${HOME}/.git-prompt-colors.sh
  cp files/bash/shell_prompt.sh ${HOME}/.bash/
  cp files/bash/bashrc ${HOME}/.bashrc
  cp files/bash/bash_variables ${HOME}/.bash_variables
  cp files/bash/bash_profile ${HOME}/.bash_profile
  cp files/bash/profile ${HOME}/.profile

  #cp files/bash/bash_aliases ${HOME}/.bash_aliases
  sedcmd=''
  for var in $(echo ${CONF}); do
    printf -v sc 's|${%s}|%s|;' ${var} "${!var//\//\\/}"
    sedcmd+="${sc}"
  done
  cat files/bash/bash_aliases | sed -e "${sedcmd}" > ${HOME}/.bash_aliases

  if [ ! -d  ${HOME}/.bash/complete-alias ]; then
    git clone https://github.com/cykerway/complete-alias.git ${HOME}/.bash/complete-alias
  else
    cd ${HOME}/.bash/complete-alias
    git pull
    cd ${INSTALLDIR}
  fi

  if [ ! -d  ${HOME}/.bash/bash-git-prompt ]; then
    git clone https://github.com/magicmonty/bash-git-prompt.git ${HOME}/.bash/bash-git-prompt
  else
    cd ${HOME}/.bash/bash-git-prompt
    git pull
    cd ${INSTALLDIR}
  fi

  if [ ! -d  ${HOME}/.bash/kube-ps1 ]; then
    git clone https://github.com/jonmosco/kube-ps1.git ${HOME}/.bash/kube-ps1
  else
    cd ${HOME}/.bash/kube-ps1
    git pull
    cd ${INSTALLDIR}
  fi

  if [ ! -d  ${HOME}/.bash/powerline-shell ]; then
    git clone https://github.com/milkbikis/powerline-shell ${HOME}/.bash/powerline-shell
  else
    cd ${HOME}/.bash/powerline-shell
    git pull
    cd ${INSTALLDIR}
  fi
}

installFish() {
  if [[ "$OSTYPE" != "darwin"* ]]; then
    sudo apt-add-repository ppa:fish-shell/release-2
    sudo apt-get update
    sudo apt-get install fish
  else
    brew install fish
  fi
  curl -sfL https://git.io/fundle-install | fish
  curl -Lo ~/.config/fish/functions/fisher.fish --create-dirs git.io/fisher
  curl -L https://github.com/oh-my-fish/oh-my-fish/raw/master/bin/install | fish
  fisher fzf edc/bass omf/thefuck omf/wttr omf/vundle ansible-completion docker-completion
  omf install chain
  fisher teapot
}

createSkeleton() {
  dirs=$(cat config.sh | awk -F\' '{print $2}' | grep 'HOME')
  for d in $(envsubst <<< "${dirs}"); do
    mkdir -p "${d}"
  done

  [ -d ${HOME}/workingCopies/code ] || ln -s ${HOME}/workingCopies/src ${HOME}/workingCopies/code

  mkdir -p ${HOME}/.local/bin/
  mkdir -p ${HOME}/.local/share/bash-completion
  [ -d ${HOME}/.bin ] || ln -s ${HOME}/.local/bin ${HOME}/.bin
}

installDotFiles() {
  if ! [ -x "$(command -v git)" ]; then
    echo 'You need to install git!' >&2
    exit 1
  fi

  createSkeleton
  installVimPlugins
  installTmuxConf
  installBashConf
  installGitConf
  installScripts

  mkdir -p ${HOME}/.ptpython
  cp files/ptpython.py ${HOME}/.ptpython/config.py

  rm -f ~/.config/ranger/*.{sh,py}
  ranger --copy-config=all
  mkdir -p ${HOME}/.ranger_plugins/
  cd ${HOME}/.ranger_plugins/
  if [ ! -d ${HOME}/.ranger_plugins/ranger_devicons ]; then
    git clone https://github.com/alexanderjeurissen/ranger_devicons.git
  fi
  cd ranger_devicons
  git pull
  make install
  cd ${INSTALLDIR}

  if [[ "$OSTYPE" == "darwin"* ]]; then
    ./osx.sh dotfiles
  elif [[ "$OSTYPE" == *"android"* ]]; then
    ./android.sh dotfiles
  else
    ./linux.sh dotfiles
  fi

  if [ -x "$(command -v bat)" ] && [ ! -d "${HOME}/.config/bat/themes/sublime-tomorrow-theme" ]; then
    mkdir -p "${HOME}/.config/bat/themes"
    git clone https://github.com/theymaybecoders/sublime-tomorrow-theme.git "${HOME}/.config/bat/themes/sublime-tomorrow-theme"
    bat cache --build
  fi
}

installWebApps() {
  npm install -g nativefier
  nativefier --name 'Whatsapp Web' 'https://web.whatsapp.com/'
  nativefier --name 'Evernote Web' 'https://www.evernote.com/Home.action?login=true&prompt=none&authuser=0#n=66f8e46f-8a98-4294-b42f-8abf8cb9774a&s=s14&ses=4&sh=2&sds=5&'
}

installAll() {
  if [[ "$OSTYPE" != *"android"* ]]; then
    if [[ "$OSTYPE" == "linux-gnu" ]]; then
      sudo installGems
      sudo installPips
      sudo installNpms
    else
      installGems
      installPips
      installNpms
    fi
    installChefGems
    installChefVM
    installVagrantPlugins
    installAtomPackages
    installVscodePackages
    installGoss
    installEls
    if [[ "$OSTYPE" == "darwin"* ]]; then
      installKubeScripts 'darwin' '64'
    else
      installKubeScripts 'linux' '64'
    fi
    installhelmPlugins
  fi
  # installWebApps
  installDotFiles
}

case "$1" in
  "gems" | "gem")
    installGems
    ;;
  "chef_gems" | "chefgems")
    installChefGems
    ;;
  "pip" | "pips")
    installPips
    ;;
  "npm" | "npms")
    installNpms
    ;;
  "go" | "gopkgs")
    installGoPkgs
    ;;
  "dotfiles")
    installDotFiles
    ;;
  "scripts")
    installScripts
    ;;
  "vimplugins" | "vim")
    installVimPlugins
    ;;
  "atompackages" | "apkgs" | "atom" | "apm")
    installAtomPackages
    ;;
  "vscodepackages" | "vscode" | "vspkgs")
    installVscodePackages
    ;;
  "vagrant" | "VagrantPlugins")
    installVagrantPlugins
    ;;
  "goss")
    installGoss
    ;;
  "awless")
    installAwless
    ;;
  "dcos"|"dcos-cli"|"dcoscli")
    installDCOScli
    ;;
  "depcon")
    if [[ "$OSTYPE" == "darwin"* ]]; then
      installDepcon 'osx' '64'
    else
      installDepcon 'linux' '64'
    fi
    ;;
  "minikube")
    installMinikube
    ;;
  "fission")
    installFission
    ;;
  "fish")
   installFish
    ;;
  "all")
    if [[ "$OSTYPE" == "darwin"* ]]; then
      ./osx.sh
    elif [[ "$OSTYPE" == *"android"* ]]; then
      ./android.sh
    else
      ./linux.sh
    fi
    installAll
    ;;
  *)
    if [[ "$OSTYPE" == "darwin"* ]]; then
      ./osx.sh "${@}"
    elif [[ "$OSTYPE" == *"android"* ]]; then
      ./android.sh "${@}"
    else
      ./linux.sh "${@}"
    fi
    if [ -z "${1}" ]; then
      installAll
    fi
    ;;
esac
