#!/bin/bash

# Ensure script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" 
    exit 1
fi

# Get username to configure
read -p "Enter username to configure with admin privileges: " USERNAME

if ! id "$USERNAME" &>/dev/null; then
    echo "User $USERNAME does not exist!"
    exit 1
fi

# Get Git user information
read -p "Enter Git user name: " GIT_USERNAME
read -p "Enter Git email address: " GIT_EMAIL

# Ask about web management panel
read -p "Install Cockpit web management panel? (y/n): " INSTALL_COCKPIT
INSTALL_COCKPIT=$(echo "$INSTALL_COCKPIT" | tr '[:upper:]' '[:lower:]')

# Ask about firewall setup
read -p "Configure UFW firewall? (y/n): " SETUP_UFW
SETUP_UFW=$(echo "$SETUP_UFW" | tr '[:upper:]' '[:lower:]')

# Ask about monitoring setup
read -p "Install monitoring tools (Netdata)? (y/n): " INSTALL_MONITORING
INSTALL_MONITORING=$(echo "$INSTALL_MONITORING" | tr '[:upper:]' '[:lower:]')

echo "========================================================"
echo "Debian 12 Post-Installation Setup Script"
echo "========================================================"
echo "Setting up system for user: $USERNAME"
echo

if [[ "$INSTALL_COCKPIT" == "y" ]]; then
    echo "Cockpit web management panel will be installed"
fi
if [[ "$SETUP_UFW" == "y" ]]; then
    echo "UFW firewall will be configured"
fi
if [[ "$INSTALL_MONITORING" == "y" ]]; then
    echo "Netdata monitoring will be installed"
fi

# Get user home directory
USER_HOME=$(eval echo ~$USERNAME)

# Create a directory for admin scripts
mkdir -p /usr/local/admin-scripts
mkdir -p $USER_HOME/scripts

# Enable non-free and non-free-firmware repositories
echo "Enabling non-free repositories..."
sed -i 's/main/main contrib non-free non-free-firmware/g' /etc/apt/sources.list
apt update

#Install required packages
echo "Installing base packages..."
apt install -y sudo curl wget git build-essential apt-transport-https ca-certificates \
    gnupg lsb-release unzip fontconfig software-properties-common \
    htop neofetch ncdu tmux screen net-tools dnsutils tree zip \
    iotop nload iftop fail2ban openssh-server mosh rsync \
    ripgrep fd-find bat exa fzf jq python3-pip python3-venv \
    neovim mlocate neofetch zsh zsh-autosuggestions zsh-syntax-highlighting ranger vim\
    xauth x11-apps mesa-utils glances sysstat libgl1-mesa-glx\
    xorg xserver-xorg xauth x11-apps x11-utils x11-xserver-utils \
    mesa-utils libgl1-mesa-glx xdg-utils libxss1 \
    xfonts-base xterm x11-apps xvfb golang-go btop\
    ethtool smartmontools lm-sensors \
    acl attr mc rdiff-backup logrotate molly-guard needrestart pwgen \
    apt-listchanges unattended-upgrades plocate byobu debsums

# Configure unattended-upgrades
cat > /etc/apt/apt.conf.d/50unattended-upgrades << EOF
Unattended-Upgrade::Allowed-Origins {
    "\${distro_id}:\${distro_codename}";
    "\${distro_id}:${distro_codename}-security";
};
Unattended-Upgrade::Automatic-Reboot "true";
EOF
systemctl enable --now unattended-upgrades.service

# Install GitHub CLI
echo "Installing GitHub CLI..."
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share>
chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archiv>
apt update
apt install -y gh git git-lfs

# Setup bat alternative for cat with prettier output
ln -s /usr/bin/batcat /usr/local/bin/bat 2>/dev/null || true

# Setup modern alternatives
echo "Setting up modern command-line tools..."
# exa as alternative to ls
if command -v exa >/dev/null; then
    echo 'alias ls="exa"' >> /etc/bash.bashrc
    echo 'alias ll="exa -l"' >> /etc/bash.bashrc
    echo 'alias la="exa -la"' >> /etc/bash.bashrc
    echo 'alias lt="exa -T"' >> /etc/bash.bashrc
fi

# fd-find as alternative to find
if command -v fdfind >/dev/null; then
    ln -s $(which fdfind) /usr/local/bin/fd 2>/dev/null || true
fi

# Install pfetch
echo "Installing pfetch..."
wget -q https://raw.githubusercontent.com/dylanaraps/pfetch/master/pfetch -O /usr/local/bin/pfetch
chmod +x /usr/local/bin/pfetch

# Install fastfetch FAILS CURRENTLY
#echo "Installing fastfetch..."
#apt install -y fastfetch || {
#    echo "Fastfetch not available in default repos, trying from GitHub..."
#    FASTFETCH_VERSION="1.12.2"
#    wget -q https://github.com/fastfetch-cli/fastfetch/releases/download/${FASTFETCH_VERSION}/fastfetch-linux-amd64.deb -O /tmp/fastfetch.deb
#    apt install -y /tmp/fastfetch.deb
#    rm /tmp/fastfetch.deb
#}

#Configure vim with sensible defaults
cat > /etc/vim/vimrc.local << 'EOF'
syntax on
set background=dark
set number
set tabstop=4
set shiftwidth=4
set expandtab
set autoindent
set smartindent
set ruler
set ignorecase
set smartcase
set hlsearch
set incsearch
set showmatch
set showcmd
set wrap
set linebreak
set scrolloff=3
set history=1000
set wildmenu
set wildmode=longest:full,full
set backspace=indent,eol,start
set laststatus=2
set statusline=%<%f\ %h%m%r%=%-14.(%l,%c%V%)\ %P
set mouse=a
EOF

# Install Docker
echo "Installing Docker..."
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do apt remove $pkg; done
# Add Docker's official GPG key:
apt update
apt install ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update
#curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.asc
#sudo chmod a+r /etc/apt/keyrings/docker.asc
#echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
#apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-buildx-plugin

# Install Docker Compose - Installed via docker plugins above
#echo "Installing Docker Compose..."
#curl -SL https://github.com/docker/compose/releases/download/v2.35.1/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
#chmod +x /usr/local/bin/docker-compose

# Install Portainer (Docker management UI) FAILS with syntax error
#echo "Installing Portainer..."
#docker run -d -p 9000:9000 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/>

# Install LazyDocker
echo "Installing LazyDocker..."
if command -v go &>/dev/null; then
    GO111MODULE=on go install github.com/jesseduffield/lazydocker@latest
    # Check if installation was successful via Go
    if [ ! -f "/root/go/bin/lazydocker" ]; then
        echo "Go installation of LazyDocker failed, trying direct download..."
        LAZYDOCKER_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazydocker>
        curl -Lo /tmp/lazydocker.tar.gz "https://github.com/jesseduffield/lazydocker/releas>
        mkdir -p /tmp/lazydocker
        tar xf /tmp/lazydocker.tar.gz -C /tmp/lazydocker
        mv /tmp/lazydocker/lazydocker /usr/local/bin/
        chmod +x /usr/local/bin/lazydocker
        rm -rf /tmp/lazydocker /tmp/lazydocker.tar.gz
    else
        # Move from Go bin to /usr/local/bin
        mv /root/go/bin/lazydocker /usr/local/bin/
    fi
else
    echo "Go not found, downloading LazyDocker binary directly..."
    LAZYDOCKER_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazydocker/rel>
    curl -Lo /tmp/lazydocker.tar.gz "https://github.com/jesseduffield/lazydocker/releases/l>
    mkdir -p /tmp/lazydocker
    tar xf /tmp/lazydocker.tar.gz -C /tmp/lazydocker
    mv /tmp/lazydocker/lazydocker /usr/local/bin/
    chmod +x /usr/local/bin/lazydocker
    rm -rf /tmp/lazydocker /tmp/lazydocker.tar.gz
fi

# Install Tailscale
echo "Installing Tailscale..."
curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.noarmor.gpg | tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
curl -fsSL https://pkgs.tailscale.com/stable/debian/bookworm.tailscale-keyring.list | tee /etc/apt/sources.list.d/tailscale.list
apt update
apt install -y tailscale

# Create fonts directory
echo "Installing Nerd Fonts..."
mkdir -p /usr/local/share/fonts/nerd-fonts
mkdir -p /tmp/fonts

# Install Hack Nerd Font
echo "Downloading Hack Nerd Font..."
wget -q https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/Hack.zip -O /tmp/fonts/Hack.zip
unzip -q /tmp/fonts/Hack.zip -d /usr/local/share/fonts/nerd-fonts/Hack

# Install JetBrains Mono Nerd Font
echo "Downloading JetBrains Mono Nerd Font..."
wget -q https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/JetBrainsMono.zip -O /tmp/fonts/JetBrainsMono.zip
unzip -q /tmp/fonts/JetBrainsMono.zip -d /usr/local/share/fonts/nerd-fonts/JetBrainsMono

# Install Fira Code Nerd Font
echo "Downloading Fira Code Nerd Font..."
wget -q https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/FiraCode.zip -O /tmp/fonts/FiraCode.zip
unzip -q /tmp/fonts/FiraCode.zip -d /usr/local/share/fonts/nerd-fonts/FiraCode

# Update font cache
fc-cache -fv

# Add user to sudo and other groups
echo "Adding $USERNAME to necessary groups..."
usermod -aG sudo,adm,docker,dialout,plugdev,netdev,audio,video "$USERNAME"

# Configure sudo with insults
echo "Configuring sudo with insults..."
echo 'Defaults insults' > /etc/sudoers.d/insults
echo 'Defaults timestamp_timeout=30' >> /etc/sudoers.d/insults
chmod 440 /etc/sudoers.d/insults


# Configure SSH server for security
echo "Configuring SSH server..."
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
cat >> /etc/ssh/sshd_config << EOF

# Enhanced security settings
PermitRootLogin no
PasswordAuthentication yes
PubkeyAuthentication yes
PermitEmptyPasswords no
X11Forwarding yes
X11DisplayOffset 10
X11UseLocalhost yes
AllowTcpForwarding yes
MaxAuthTries 3
LoginGraceTime 30
ClientAliveInterval 300
ClientAliveCountMax 2
EOF

# Setup fail2ban for SSH
echo "Configuring fail2ban for SSH..."
systemctl enable fail2ban
systemctl start fail2ban
cat > /etc/fail2ban/jail.local << EOF
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = %(sshd_log)s
maxretry = 3
bantime = 600
EOF

# User HOME directory
USER_HOME=$(eval echo ~$USERNAME)

# Set up Xresources for better X11 appearance
cat > $USER_HOME/.Xresources << 'EOF'
! Terminal settings
XTerm*faceName: JetBrainsMono Nerd Font
XTerm*faceSize: 11
XTerm*background: black
XTerm*foreground: lightgray
XTerm*saveLines: 2000
XTerm*scrollBar: true
XTerm*rightScrollBar: true
XTerm*selectToClipboard: true
XTerm*VT100.translations: #override \
    Shift <KeyPress> Insert: insert-selection(CLIPBOARD) \n\
    Ctrl Shift <Key>V: insert-selection(CLIPBOARD) \n\
    Ctrl Shift <Key>C: copy-selection(CLIPBOARD) \n\
    Ctrl <Key> minus: smaller-vt-font() \n\
    Ctrl <Key> plus: larger-vt-font()
EOF

# Make user own their Xresources file
chown $USERNAME:$USERNAME $USER_HOME/.Xresources

# Configure Git for the user
echo "Configuring Git for $USERNAME..."
su - $USERNAME -c "git config --global user.name \"$GIT_USERNAME\""
su - $USERNAME -c "git config --global user.email \"$GIT_EMAIL\""
su - $USERNAME -c "git config --global core.editor \"vim\""
su - $USERNAME -c "git config --global init.defaultBranch \"main\""
su - $USERNAME -c "git config --global color.ui auto"
su - $USERNAME -c "git config --global pull.rebase false"

# Modify .bashrc to add pfetch and set JetBrains Mono
echo "Configuring .bashrc for $USERNAME..."
USER_HOME=$(eval echo ~$USERNAME)
echo -e "\n# Run pfetch on terminal startup\npfetch" >> $USER_HOME/.bashrc
echo -e "\n# Set terminal font to JetBrains Mono Nerd Font\nGSETTINGS_SCHEMA=org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/\nprofile=\$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d \"'\")\ngsettings set \"\$GSETTINGS_SCHEMA\"\"\$profile\"/font 'JetBrainsMono Nerd Font 12'" >> $USER_HOME/.bashrc

# Set better history control
HISTCONTROL=ignoreboth
HISTSIZE=10000
HISTFILESIZE=20000
shopt -s histappend
shopt -s checkwinsize

# Improved prompt with git branch display
parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[01;33m\] $(parse_git_branch)\[\033[00m\]\$ '

# Useful aliases
alias update='sudo apt update && sudo apt upgrade -y'
alias install='sudo apt install -y'
alias remove='sudo apt remove'
alias cls='clear'
alias ports='ss -tuln'
alias myip='curl http://ipecho.net/plain; echo'
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias grep='grep --color=auto'
alias mkdir='mkdir -p'
alias dc='docker-compose'
alias dps='docker ps'
alias dimg='docker images'
alias vim='nvim'
alias glxinfo='glxinfo | grep -i "direct rendering"'
alias xeyes='DISPLAY=:0 xeyes'
alias xclock='DISPLAY=:0 xclock'
alias xterm='DISPLAY=:0 xterm'

# X11 test commands
alias xeyes='xeyes &'
alias xclock='xclock &'
alias xterm='xterm &'
alias testx11='xeyes & xclock &'

# Enable terminal colors
export TERM=xterm-256color

# Enable X11 forwarding settings
export DISPLAY=:0
export LIBGL_ALWAYS_INDIRECT=1

# Set proper permissions for user's home directory
chown -R $USERNAME:$USERNAME $USER_HOME

  {

  typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
    status                  # exit code of the last command
    background_jobs         # presence of background jobs
    direnv                  # direnv status
    asdf                    # asdf version manager
    virtualenv              # python virtual environment
    anaconda                # conda environment
    nodenv                  # node.js version
    node_version            # node.js version
    go_version              # go version
    rust_version            # rustc version
    dotnet_version          # .NET version
    php_version             # php version
    laravel_version         # laravel php framework version
    java_version            # java version
    package                 # name@version from package.json
    load                    # CPU load
    disk_usage              # disk usage
    ram                     # free RAM
    time                    # current time
  )

  # OS identifier
  typeset -g POWERLEVEL9K_OS_ICON_CONTENT_EXPANSION='%B🐧%b'

  # Directory truncation
  typeset -g POWERLEVEL9K_SHORTEN_STRATEGY=truncate_to_last
  typeset -g POWERLEVEL9K_SHORTEN_DIR_LENGTH=3

  # VCS config
  typeset -g POWERLEVEL9K_VCS_BRANCH_ICON='\uF126 '
  typeset -g POWERLEVEL9K_VCS_UNTRACKED_ICON='?'

  # Time format
  typeset -g POWERLEVEL9K_TIME_FORMAT='%D{%H:%M:%S}'

  # Set colors
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_VIINS_FOREGROUND=76
  typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_VIINS_FOREGROUND=196
}

(( ${#p10k_config_opts} )) && setopt ${p10k_config_opts[@]}
'builtin' 'unset' 'p10k_config_opts'
EOF

# Set up basic tmux configuration
echo "Configuring tmux..."
cat > $USER_HOME/.tmux.conf << 'EOF'
# Improve colors
set -g default-terminal "screen-256color"

# Enable and start services
echo "Enabling and starting services..."
systemctl enable docker
systemctl start docker
systemctl enable tailscaled
systemctl start tailscaled

# Clean up
echo "Cleaning up..."
rm -rf /tmp/fonts
# Restart SSH for X11 forwarding to take effect
echo "Restarting SSH service..."
systemctl restart ssh

# Final update & cleanup
echo "Running final update and cleanup..."
apt update
apt upgrade -y
apt autoremove -y
apt autoclean

echo "========================================================"
echo "Installation complete!"
echo "========================================================"
echo "You can log in to Tailscale by running: sudo tailscale up"
echo "You may need to log out and log back in for all changes to take effect."
echo "Reboot is recommended."

# Prompt user to login to Tailscale
read -p "Would you like to login to Tailscale now? (y/n): " TAILSCALE_LOGIN
if [[ $TAILSCALE_LOGIN =~ ^[Yy]$ ]]; then
    echo "Running Tailscale login..."
    tailscale up
fi

echo "Script completed successfully!"
EOF
