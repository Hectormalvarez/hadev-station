FROM ubuntu:24.04

# 1. Install prerequisites AND Ansible
# We add the PPA and install Ansible here so setup.sh skips it
RUN apt-get update && apt-get install -y \
    sudo \
    curl \
    git \
    software-properties-common \
    vim && \
    add-apt-repository --yes --update ppa:ansible/ansible && \
    apt-get install -y ansible

# 2. Create a non-root test user to simulate 'hadev'
RUN useradd -m -s /bin/bash testuser && \
    echo "testuser ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/testuser

# 3. Switch to the test user
USER testuser
WORKDIR /home/testuser/downloads/hadev-station

# 4. Copy your current project files into the image
COPY --chown=testuser:testuser . .

# 5. Make the script executable
RUN chmod +x setup.sh

# 6. Default command: Drop into a shell
CMD ["/bin/bash"]