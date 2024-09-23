FROM ubuntu:22.04

# Update the package registry
RUN apt-get update

RUN apt-get install -y \
    curl \
    wget \
    sudo \
    apt-transport-https \
    software-properties-common \
    ca-certificates \
    gnupg2

# Download and install Microsoft GPG key - This allows you to install PowerShell from Microsoft's package repository.
RUN wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | apt-key add -

# Add Microsoft repository for PowerShell
RUN wget -q https://packages.microsoft.com/config/ubuntu/20.04/prod.list -O /etc/apt/sources.list.d/microsoft-prod.list

RUN wget -q https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb

RUN sudo dpkg -i packages-microsoft-prod.deb

RUN sudo apt-get update

RUN sudo apt-get install -y powershell

# Install the PnP.PowerShell module in PowerShell
RUN pwsh -Command "Install-Module -Name PnP.PowerShell -Force -AllowClobber -SkipPublisherCheck"

# (Optional) Verify that PnP.PowerShell is installed
RUN pwsh -Command "Get-Module -ListAvailable PnP.PowerShell"

# Setup app area and start the PowerShell
RUN mkdir -p /app

COPY main.ps1 /app/main.ps1

RUN chmod +x /app/main.ps1

CMD ["pwsh", "-File", "/app/main.ps1"]
