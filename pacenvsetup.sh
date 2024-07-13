#!/bin/bash

function pachelp() {
cat <<EOF
Invoke pacenvsetup.sh from your shell to add the following functions to your environment:
- pac:   lunch <pacname>.
- makepac: package project
EOF
}
# Clear the variable

function setpactitle()
{
  local modemtype=$TARGET_MODEM_TYPE
  export PROMPT_COMMAND="echo -ne \"\033]0;[$modemtype] ${USER}@${HOSTNAME}: ${PWD}\007\""
}
function setpacpaths()
{
 
  unset TARGET_PAC_OUT
  export TARGET_PAC_OUT=./out/target/product/${TARGET_PROJECT}
  

  unset PAC_ENV_SCRIPT
  export PAC_ENV_SCRIPT=./build/        
  
  unset BOARD_ROOT_PATH
  export BOARD_ROOT_PATH=`pwd`
  echo "BOARD_ROOT_PATH is $BOARD_ROOT_PATH"
}





function get_board_name()
{
	unset BOARD_NAME
	if [ ! -z "$PROJECT_PATH" ];then
		BOARD_NAME=${PROJECT_PATH##*/}		
		echo "PROJECT_PATH is $PROJECT_PATH"
        fi
}
function set_pac_for_environment()
{
  setpactitle
  setpacpaths 
  

}
function pac()
{
  ## print_pac_menu
  chooseboardtype $1
  set_pac_for_environment
  echo
  
}
function get_pac_command()
{

 
	command="/usr/bin/perl $PAC_ENV_SCRIPT/pac_via_conf.pl $TARGET_PAC_OUT/${BUILD_PROJECT}-${PROJ_TYPE}.pac $PACVER  ${PROJECT_PATH}/pac.ini"
 
  export PAC_COMMAND=$command
}



function get_pac_version()
{
	unset PACVER
        V=`date +%V`

	if  [ -z "$JOB_NAME" ];then
	    PACVER=MorcorDroid_`date +W%g.$V.%u-%H%M%S`
	else
	    PACVER=${JOB_NAME}_`date +W%g.$V.%u-%H%M%S`	
	fi
}
function makepac()
{
  local start_time=$(date +"%s")

  unset PROJ_TYPE
  export PROJ_TYPE=$1
  if [ -z $PROJ_TYPE ]; then
    PROJ_TYPE="default"          
  fi



  get_pac_version
  get_board_name
  check_build_result
  get_pac_command
  
 ${PAC_COMMAND} "${PROJ_TYPE}"
  local ret=$?
  local end_time=$(date +"%s")
  local tdiff=$(($end_time-$start_time))
  local hours=$(($tdiff / 3600 ))
  local mins=$((($tdiff % 3600) / 60))
  local secs=$(($tdiff % 60))
  local ncolors=$(tput colors 2>/dev/null)
  if [ -n "$ncolors" ] && [ $ncolors -ge 8 ]; then
    color_failed=$'\E'"[0;31m"
    color_success=$'\E'"[0;32m"
    color_reset=$'\E'"[00m"
  else
    color_failed=""
    color_success=""
    color_reset=""
  fi
  echo
  if [ $ret -eq 0 ] ; then
      echo -n "${color_success}#### make pac completed successfully "
  else
      echo -n "${color_failed}#### make pac failed to package some targets "
  fi
  if [ $hours -gt 0 ] ; then
      printf "(%02g:%02g:%02g (hh:mm:ss))" $hours $mins $secs
  elif [ $mins -gt 0 ] ; then
      printf "(%02g:%02g (mm:ss))" $mins $secs
  elif [ $secs -gt 0 ] ; then
      printf "(%s seconds)" $secs
  fi
  echo " ####${color_reset}"
  echo
  return $ret
}
#Parse INI file
function check_board_have_ini()
{

  platform=scx35l
  echo "platform is $platform"
  PROJECT_PATH=./device/sprd/$platform/${TARGET_PROJECT}

  #PROJECT_PATH=./device/sprd/scx35l/$default_value
  echo "PROJECT_PATH is $PROJECT_PATH"
	
  if [ -f "${PROJECT_PATH}/pac.ini" ]; then                      
    return 0
  else
    echo "${PROJECT_PATH}/pac.ini does not exist !!!"
    return 1
  fi
}

function chooseboardtype()
{

  BUILD_PROJECT=$1
  export TARGET_PROJECT=$1
  local  default_value=sp9820a_refh10                     
  ##print_lunch_menu
  while [ -z "$TARGET_PROJECT" ];do
	# echo  -n "which board would you like ? [$default_value]"
	if [ -z  "$BUILD_PROJECT" ];then
		# read  ANSWER
		# BUILD_PROJECT=$ANSWER
    BUILD_PROJECT='sp9820a_refh10'
	else
 		ANSWER=$BUILD_PROJECT
	fi
	if  [ !  -z  "$ANSWER" ];then
	TARGET_PROJECT=${ANSWER%-*}
	fi
 done
 # echo "ANSWER is $ANSWER"
 # echo "TARGET_PROJECT is $TARGET_PROJECT"
 check_board_have_ini  $TARGET_PROJECT



}
function choosepac()
{
  #choosemodemtype $1
  chooseboardtype $1
  set_pac_for_environment
  echo
  echo
  makepac $2
  echo
}

pac $1
makepac
