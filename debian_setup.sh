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

echo "========================================================"
echo "Debian 12 Post-Installation Setup Script"
echo "========================================================"
echo "Setting up system for user: $USERNAME"
echo

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
    neovim mlocate neofetch zsh zsh-autosuggestions zsh-syntax-highlighting ranger vim

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

# Install fastfetch
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

# Install Docker Compose
#echo "Installing Docker Compose..."
#curl -SL https://github.com/docker/compose/releases/download/v2.35.1/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
#chmod +x /usr/local/bin/docker-compose

# Install Portainer (Docker management UI)
#echo "Installing Portainer..."
#docker run -d -p 9000:9000 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/>

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
usermod -aG sudo,adm,docker,dialout,plugdev,netdev "$USERNAME"

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

# Modify .bashrc to add pfetch and set JetBrains Mono
echo "Configuring .bashrc for $USERNAME..."
USER_HOME=$(eval echo ~$USERNAME)
echo -e "\n# Run pfetch on terminal startup\npfetch" >> $USER_HOME/.bashrc
echo -e "\n# Set terminal font to JetBrains Mono Nerd Font\nGSETTINGS_SCHEMA=org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/\nprofile=\$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d \"'\")\ngsettings set \"\$GSETTINGS_SCHEMA\"\"\$profile\"/font 'JetBrainsMono Nerd Font 12'" >> $USER_HOME/.bashrc

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
