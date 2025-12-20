#!/bin/bash

source ./helpers.sh

if confirm "Install screen reader and TTS (piper)?"; then
    install_pacman_packages "speech-dispatcher" "orca"
    install_paru_packages "piper-tts-bin" "piper-voices-en-us"
fi