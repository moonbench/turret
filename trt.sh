#!/bin/bash
#============================================================
# Turret - Workshop deployment tool
#============================================================

# Workspace options
PROJECT_NAME='.project'

HIGHLIGHT_COLOR='\e[36m'
DONE_COLOR='\e[1;32m'
NO_COLOR='\e[0m'

ROOT_DIR="$(dirname $(readlink -f $0))"

VERSION="0.1.0"


# Shared functions
debug(){
  echo -e "\n${HIGHLIGHT_COLOR}${1}${NO_COLOR}"
}
say_done(){
  echo -e "${DONE_COLOR}Done.${NO_COLOR}"
}
running_from(){
  echo -e "${HIGHLIGHT_COLOR}Running script from:${NO_COLOR} $ROOT_DIR"
}
usage(){
  echo "usage: $(basename "$0") [-i][-s][-u][-f][-h]

These are the turret commands:

Create a new workshop
   -i     Initialize      Create a workshop in the current directory

Synchronize environments
   -s     Synchronize     Clone the current committed dev environment into the stable one

Upgrade source code from dependencies
   -u     Upgrade         Upgrade dependencies in the dev environment while skipping ignored files 
   -f     Full upgrade    Upgrade all dependencies in the dev environment

Other commands
   -h     Help            Show this usage information
   -v     Version         Print the current version of this tool


Sources to download from can be added to: '.trt/repos'.
Files to not be overwritten during normal updgrades can be specified in: '.trt/ignores'." >&2
}


# Initialization functions
create_config_folder(){
  debug "Creating config folder"
  mkdir .trt
}

create_parent_repo(){
  debug "Creating project repository"
  cd "$ROOT_DIR"
  git init --bare ${PROJECT_NAME}.git
  say_done
}

create_repo(){
  git init
  git remote add origin ../${PROJECT_NAME}.git
}

create_stable_folder(){
  debug "Creating stable folder..."
  cd "$ROOT_DIR"
  mkdir stable
  cd "$ROOT_DIR/stable"
  create_repo
  say_done
}

create_dev_folder(){
  debug "Creating dev folder..."
  cd "$ROOT_DIR"
  mkdir dev
  cd "$ROOT_DIR/dev"
  create_repo
  say_done
}

create_standard_config_files(){
  debug "Creating config files..."
  cd "$ROOT_DIR/.trt/"
  touch repos
  touch ignores
  say_done
}


# Synchronization functions
push(){
  debug "Pushing to parent"
  git push origin master
}

pull(){
  debug "Pulling from parent"
  git pull origin master
}

# Upgrade functions
commit_dev_folder(){
  debug "Saving working state prior to upgrade..."
  cd "$ROOT_DIR/dev"
  git commit -a -m "Commit prior to upgrade"
  say_done
}

download_dependencies_with_overwrite(){
  debug "Downloading dependencies into development environment... (no ignores)"
  while read repo
  do
    if [ -n "$repo" ]; then
      echo -e "\t${HIGHLIGHT_COLOR}Repo:${NO_COLOR} ${repo}"
      rsync -rltvSzhc --delay-updates --progress --exclude=".*" "$repo/" .
    fi
  done < "$ROOT_DIR/.trt/repos"
  say_done
}

download_dependencies(){
  debug "Downloading dependencies into development environment..."
  while read repo
  do
    if [ -n "$repo" ]; then
      echo -e "\t${HIGHC}Repo:${NC} ${repo}"
      rsync -rltvSzhc --delay-updates --progress --exclude-from "$ROOT_DIR/.trt/ignores" --exclude=".*" "$repo/" .
    fi
  done < "$ROOT_DIR/.trt/repos"
  say_done
}



# Mode methods
init(){
  running_from
  debug "Initializing new workspace..."
  create_config_folder
  create_parent_repo
  create_dev_folder
  create_stable_folder
  create_standard_config_files
  debug "Workspace ready."
}

synchronize(){
  running_from
  debug "Synchronizing /dev with /stable"
  cd "$ROOT_DIR/dev"
  push
  cd "$ROOT_DIR/stable"
  pull
}

soft_upgrade(){
  running_from
  debug "Running a soft upgrade..."
  commit_dev_folder
  download_dependencies
  debug "Soft upgrade finished."
}

hard_upgrade(){
  running_from
  debug "Running a hard upgrade..."
  commit_dev_folder
  download_dependencies_with_overwrite
  debug "Hard upgrade finished."
}

print_version(){
  echo "Turret version ${VERSION}"
}



# Run script
if [ $# -eq 0 ]; then
  usage
  exit 1
fi

while getopts ':isfuhv' flag; do
  case "${flag}" in
    i) init ;;
    s) synchronize ;;
    u) soft_upgrade ;;
    f) hard_upgrade ;;
    h) usage ;;
    v) print_version ;;
    *) printf "Unknown option: -%s\n" "$OPTARG" >&2
       usage 
       exit 1;;
  esac
done

exit 0
