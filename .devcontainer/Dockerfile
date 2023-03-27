ARG VERSION
FROM gitlab.adacore-it.com:5050/eng/devops/alire/devenv:${VERSION}

ARG DEBIAN_FRONTEND=noninteractive

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Create the user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd -m --uid $USER_UID --gid $USER_GID -m $USERNAME -s /usr/bin/bash \
    #
    # [Optional] Add sudo support. Omit if you don't need to install software after connecting.
    && apt-get update \
    && apt-get install -y sudo libgmp-dev \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

RUN if [ -e /env ]; then cp /env /home/vscode/env \
    && chown -R $USERNAME:$USERNAME /home/vscode/env \
    && echo source /home/vscode/env >> /home/vscode/.bashrc; fi

RUN if [ -d /root/.config/alire ]; then mkdir -p /home/vscode/.config \
    && mv /root/.config/alire /home/vscode/.config/alire \
    && chown -R $USERNAME:$USERNAME /home/vscode/.config/ \
    && chown -R $USERNAME:$USERNAME /home/vscode/.config/*; fi


# ********************************************************
# * Anything else you want to do like clean up goes here *
# ********************************************************

# [Optional] Set the default user. Omit if you want to keep the default as root.
USER $USERNAME
