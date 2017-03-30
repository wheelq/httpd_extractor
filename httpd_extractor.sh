#!/usr/bin/env bash
#Author: Michael Wiczynski
#Date: 2017-03-24
#Description:
#
#Script lists all, currently running, httpd instances including their httpd.conf files that are in use
#(both: standard httpd.conf as well as specific conf names) including cluster property filenames httpd configs.
#
###############################################
while read i; do
  _webserver=""
  _config="$((awk -F '-f' '{print $2}'|awk '{print $1}') < <(echo "${i}")|egrep -v "^$"|sort -u|awk '{$1=$1};1')"
  #Default httpd.conf to look for
  _config_filename="httpd.conf"
  _webserver_bin="$(awk '{print $1}' < <(echo "${i}")|egrep -v "^$"|sort -u|awk '{$1=$1};1')"
  #Adjust your webserver installation path
  _webserver_config_path="/opt/${_webserver_bin%/*}/../conf"
  if [[ ! -z "${_config}" ]]; then
    _config_filename="${_config##*/}"
    #Dirty hack ;)
    _webserver_config_path="/opt/${_webserver_bin%/*}/../${_config%/*}"
    if [ "${_config:0:1}" = "/" ];then
      _webserver_config_path="${_config%/*}"
    fi
  fi
  #TODO: Move find into separate function, use set -e to catch stderr (in situations when we dont have sufficient permissions for some directories)
  while read _cluster; do
    _cluster="${_cluster/Include }"
    #TODO: Currently we assume httpd config files are inside the /conf/ folder. Add support for relative path
    if [ ! -z "${_cluster##*\.conf*}" ]; then
      echo
      echo "\"${_webserver_config_path/bin\/..\/}/${_config_filename}\" is set to include all config files inside: \"${_cluster}\". List of config files included:"
      if [ "${_cluster:0:1}" = "/" ];then
        while read _cluster_1; do
          echo "\"${_webserver_config_path/bin\/..\/}/${_config_filename}\" \"${_cluster_1}\""
        done < <(find "${_cluster}" -maxdepth 1 -type f)
        echo
      else
        while read _cluster_1; do
          echo "\"${_webserver_config_path/bin\/..\/}/${_config_filename}\" \"${_cluster_1}\""
        done < <(find "${_webserver_config_path}"  -type f)
      fi
    else
      echo "\"${_webserver_config_path/bin\/..\/}/${_config_filename}\" \"${_cluster}\""
    fi
  done < <(find "${_webserver_config_path}" -maxdepth 1 -type f -name "${_config_filename}" -exec grep -i ^include {} \;)
done < <(ps -ef|grep [h]ttpd|egrep -v "defunct"|awk -F '[0-9] /opt/' '{print $2}'|sort -u)
