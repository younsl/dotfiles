#!/bin/bash

#------------------------------------------------------------------------
#
# 888                     888           888                           
# 888                     888           888                           
# 888                     888           888                           
# 88888b.  .d88b.  .d88b. 888888.d8888b 888888888d888 8888b. 88888b.  
# 888 "88bd88""88bd88""88b888   88K     888   888P"      "88b888 "88b 
# 888  888888  888888  888888   "Y8888b.888   888    .d888888888  888 
# 888 d88PY88..88PY88..88PY88b.      X88Y88b. 888    888  888888 d88P 
# 88888P"  "Y88P"  "Y88P"  "Y888 88888P' "Y888888    "Y88888888888P"  
#                                                            888      
#                                                           888      
#                                                           888  
#
#------------------------------------------------------------------------

dotfiles_dir="$HOME/github/younsl/dotfiles"
target_dir="$HOME/.config"

print_directories() {
  echo "dotfiles_dir: $dotfiles_dir"
  echo "target_dir: $target_dir"
  echo ""
}

create_symbolic_link() {
  local link_name=$1
  local link_path="$target_dir/$link_name"

  if [ -L "$link_path" ]; then
    echo "Symbolic link '$link_name' already exists in '$target_dir'."
    echo "Skipping."
  else
    ln -s "$dotfiles_dir/$link_name" "$target_dir" &&
    echo "Symbolic link '$link_name' created in '$target_dir'."
  fi
}

print_directories

create_symbolic_link "neofetch"
