#!/usr/bin/env zsh

 #    ___     ___     ___      ___       ___   
 #   /\__\   /\  \   /\  \    /\  \     /\  \  
 #  /:/__/_  \:\  \  \:\  \  /::\  \   _\:\  \ 
 # /::\/\__\ /::\__\ /::\__\/::\:\__\ /::::\__\
 # \/\::/  //:/\/__//:/\/__/\/\::/  / \::;;/__/
 #   /:/  / \/__/   \/__/      \/__/   \:\__\  
 #   \/__/                              \/__/  

zmodload zsh/net/tcp
zmodload -F zsh/stat b:zstat

# ztcp -vcf

zparseopts -D -E -F - \
    s=serv_type -static=serv_type \
    h=serv_type -html=serv_type \
    f=serv_type -file=serv_type \
    v=verbose_flag -verbose=verbose_flag \
    p:=port_value -port:=port_value

if [[ ${#port_value} -gt 1 && ${port_value[1]} != -p ]]; then
    print "Error: Invalid port option."
    exit 1
fi

case "${port_value[1]}" in
-p | --port)
    readonly PORT="${port_value[-1]}"
    ;;
*)
    readonly PORT=1234
    ;;
esac

if [[ -n $PORT && ! $PORT =~ ^[0-9]+$ ]]; then
    print "Error: Port must be a number."
    exit 1
fi

if [[ -z $serv_type ]]; then
    print "Error: Server type required (-s|--static, -h|--html, or -f|--file)."
    exit 1
fi

serv_type=${serv_type[1]}

typeset -r verbose=${#verbose_flag}

typeset -A conf=(
    PORT $PORT 
    HOST localhost 
    CHUNK_SIZE 1024
)

typeset -A SERVER_TYPE=(
    -s static
    --static static
    -h html
    --html html
    -f file
    --file file
)

typeset -A CONTENT_TYPES=(
    html text/html
    css text/css
    png image/png
    gif image/gif
    jpeg image/jpeg
    jpg image/jpg
    webp image/webp
    js application/javascript
    yml application/yaml
    yaml application/yaml
    json application/json
)

echo '
      ___     ___     ___      ___    \e[1;31m   ___    \e[0m
     /\__\   /\  \   /\  \    /\  \   \e[1;31m  /\  \   \e[0m
    /:/__/_  \:\  \  \:\  \  /::\  \  \e[1;31m _\:\  \  \e[0m
   /::\/\__\ /::\__\ /::\__\/::\:\__\ \e[1;31m/::::\__\ \e[0m
   \/\::/  //:/\/__//:/\/__/\/\::/  / \e[1;31m\::;;/__/ \e[0m
     /:/  / \/__/   \/__/      \/__/  \e[1;31m \:\__\   \e[0m
     \/__/                            \e[1;31m  \/__/   \e[0m
\e[0m'

print "   port: $conf[PORT]"
print "   host: $conf[HOST]"
print "    url: http://$conf[HOST]:$conf[PORT]/"
print "   type: $SERVER_TYPE[$serv_type] server"

typeset -r BR="\r\n"

#######################################
# Print a http response for differnt content types
# Arguments:
#   status_code
#   status_message
#   BODY_PATH
#   HEADER_CUSTOM
#   BODY
# Outputs:
#   HTTP Response
#######################################
http_response_neue() {
    local status_code="$1"
    local status_message="$2"
    local STATUS=" $status_code $status_message$BR"

    local BODY_PATH="$3"
    local HEADER_TYPE=""

    local BODY_CONTENT="$5"
    local body_len

    if [[ -n $BODY_PATH ]]; then
        local FILE_EXTENSION="${BODY_PATH##*.}"
        HEADER_TYPE="content-type: $CONTENT_TYPES[$FILE_EXTENSION]$BR"
        body_len=$(zstat +size "$BODY_PATH" || print -n 0)
    else
        body_len="${#BODY_CONTENT}"
    fi

    local HEADER_CUSTOM="$4" # TODO
    local HEADER_CONTENT_LEN=""

    if [[ $body_len -gt 0 ]]; then
        local HEADER_CONTENT_LEN="content-length: $body_len$BR"
    fi

    local HEADERS
    if [[ -n $HEADER_CUSTOM ]]; then
        HEADERS="$HEADER_CUSTOM$BR"
    else
        HEADERS="accept-ranges: bytes${BR}$HEADER_TYPE$HEADER_CONTENT_LEN$BR"
    fi

    local STATIC_RESP="HTTP/1.1$STATUS$HEADERS$BODY_CONTENT"

    print -n "$STATIC_RESP"
    if [[ -n $BODY_PATH ]]; then
        cat "$BODY_PATH"
    fi
}


directory_listing() {
    local dir_path="$1"
    local request_path="${dir_path#.}"

    local html="<html><head><title>Directory listing</title></head><body><h1>Directory: $request_path</h1><ul>"
    for file in "$dir_path"*; do
        if [[ -e "$file" ]]; then
            local name="${file##*/}"
            local href="$request_path$name"
            if [[ -d "$file" ]]; then
                href="$href/"
            fi
            html+="<li><a href=\"$href\">$name</a></li>"
        fi
    done
    html+="</ul></body></html>"
    print -n "$html"
}

serve_file_or_404() {
    local file_path="$1"
    if [[ -f "$file_path" ]]; then
        http_response_neue 200 Ok "$file_path"
    else
        http_response_neue 404 "Not found" "" "" "<p>File not found.</p>"
    fi
}

serve_index_or_dir_or_404() {
    local dir_path="$1"
    local index_file="$dir_path/index.html"
    if [[ -f "$index_file" ]]; then
        http_response_neue 200 Ok "$index_file"
    elif [[ -d "$dir_path" ]]; then
        local listing=$(directory_listing "$dir_path")
        http_response_neue 200 Ok "" "" "$listing"
    else
        http_response_neue 404 "Not found" "" "" "<p>Directory not found.</p>"
    fi
}

typeset -r DEFAULT_BODY="<h1>Hello, world!</h1>"
typeset -r DEFAULT_RESPONSE=$(http_response_neue 200 Ok "" "" "$DEFAULT_BODY")

typeset -r CHUNK_SIZE=1024

#######################################
# Router HTTP request and respond based on the method and path.
# Only GET get is support all other methods will trigger a 500.
# IF path "/"
#    IF "./index.html" exist return as response body
#    ELSE return a default 200 HTML response body
# ELSE path "*"
#    IF ".(path)index.html" exist return as response body
#    ELSE return 404
# Arguments:
#   route
# Outputs:
#   HTTP Response (text/html)
#######################################
html_router() {
    ROUTE_PATH="$1"

    case "$ROUTE_PATH" in
    *.html)
        if [ -e ".$ROUTE_PATH" ]; then
            http_response_neue 200 Ok ".$ROUTE_PATH"
        else
            http_response_neue 404 "Not found" "" "" "<p>Page not found.</p>"
        fi
        ;;
    "/")
        if [[ -f ./index.html ]]; then
            http_response_neue 200 Ok "./index.html"
        else
            http_response_neue 404 "Not found" "" "" "<p>Page not found.</p>"
        fi
        ;;
    *)
        ROUTE_FILE="./$ROUTE_PATH/index.html"
        if [ -e "$ROUTE_FILE" ]; then
            http_response_neue 200 Ok "$ROUTE_FILE"
        else
            http_response_neue 404 "Not found" "" "" "<p>Page not found.</p>"
        fi
        ;;
    esac
}

html-handler() {
    local HANDLER_METHOD=$1
    local HANDLER_PATH=$2

    case $HANDLER_METHOD in
    "GET")
        html_router "$HANDLER_PATH"
        ;;
    "HEAD")
        http_response_neue 501 "Not Implemented" "" ""
        ;;
    *)
        http_response_neue 501 "Not Implemented" "" "" "<p>Unsupported method ($HANDLER_METHOD)</p>"
        ;;
    esac
}

file_router() {
    local ROUTE_PATH="$1"
  
    setopt EXTENDED_GLOB

    case "$ROUTE_PATH" in
    *.js | *.css | *.yml | *.yaml | *.json | *.png | *.gif | *.jpeg | *.jpg | *.webp | *.html)
        serve_file_or_404 ".$ROUTE_PATH"
        ;;
    "/")
        serve_index_or_dir_or_404 "./"
        ;;
    */)
        serve_index_or_dir_or_404 "./${ROUTE_PATH%/}"
        ;;
    */[a-zA-Z0-9_]##)
        ROUTE_FILE="./$ROUTE_PATH/index.html"
        if [[ -f "$ROUTE_FILE" ]]; then
            http_response_neue 301 "Move Permanently" "" "LOCATION: http://localhost:$conf[PORT]$ROUTE_PATH/$BR" ""
        else
            http_response_neue 404 "Not found" "" "" "<p>Page not found.</p>"
        fi
        ;;
    *)
        serve_index_or_dir_or_404 "./$ROUTE_PATH"
        ;;
    esac
}

file-handler() {
    local HANDLER_METHOD=$1
    local HANDLER_PATH=$2

    case $HANDLER_METHOD in
    "GET")
        file_router "$HANDLER_PATH"
        ;;
    "HEAD")
        http_response_neue 501 "Not Implemented" "" ""
        ;;
    *)
        http_response_neue 501 "Not Implemented" "" "" "<p>Unsupported method ($HANDLER_METHOD)</p>"
        ;;
    esac
}

http-listen() {
    local PORT=$conf[PORT]

    if [[ "$verbose" > 0 ]]; then
        ztcp -v -l $PORT && print "listening on $PORT...\n"
        local listenfd=$REPLY
    else
        ztcp -l $PORT
        local listenfd=$REPLY
    fi

    while true; do

        if [[ "$verbose" > 0 ]]; then
            ztcp -v -a $listenfd && [[ "$verbose" > 0 ]] && print "\n\naccept request...\n"
        else
            ztcp -a $listenfd
        fi

        fd=$REPLY

        typeset req_method req_path req_version
        typeset -A req_headers
        typeset header_key header_value

        if [[ "static" != "$SERVER_TYPE[$serv_type]" ]]; then
            if [[ "$verbose" > 0 ]]; then
                read -r -u $fd req_method req_path req_version || print "no header returned"
            else
                read -r -u $fd req_method req_path req_version
            fi


            while read -r -u $fd header_key header_value && [[ $header_key != $'\r' ]] && [[ -n $header_value ]]; do
                header_key="${header_key:0:-1}"
                header_value="${header_value:0:-1}"
                req_headers[$header_key]="${header_value//\"/\\\\\"}"
            done

            typeset req_headers_json='"headers": {\n'
            for key in "${(@k)req_headers}"; do
                req_headers_json+="\"$key\": \"${req_headers[$key]}\",\n"
            done

            req_headers_json="\{${req_headers_json:0:-3}\}\}" # close the json object

            if [[ "$verbose" > 0 ]]; then
                print "method:$req_method\npath: $req_path\nversion: $req_version\n\n"
                print "$req_headers_json\n\n"
            fi

            if [[ "${req_headers[Content-Length]}" > 0 ]]; then
                typeset req_body=""

                case $req_method in
                    ('GET'| 'HEAD'| 'TRACE')
                        # do nothing
                        unset  req_body req_body_json
                    ;;
                    (*)
                        while true; do
                            chunk=$(timeout 0.01 dd bs=$CHUNK_SIZE count=1 <&$fd 2>/dev/null)

                            if [[ $? -ne 0 || -z "$chunk" ]]; then
                                break
                            fi

                            req_body+=$chunk
                        done

                        typeset req_body_json="\"body\": \"$req_body\""
                        print $req_body_json
                    ;;
                esac
            fi
        fi

        case "$serv_type" in
        -s | --static)
            print $DEFAULT_RESPONSE >&$fd
            ;;
        -h | --html)
            HTML_RESPONSE=$(html-handler "$req_method" "$req_path")
            print $HTML_RESPONSE >&$fd
            ;;
        -f | --file)
            if [[ "$verbose" > 0 ]]; then
                (file-handler "$req_method" "$req_path") >&1 >&$fd
            else
                (file-handler "$req_method" "$req_path") >&$fd
            fi
            ;;
        esac

        unset req_headers req_headers_json req_body req_body_json
        unset req_method req_path req_version
        unset header_key header_value

        if [[ "$verbose" > 0 ]]; then
            ztcp -v -c $fd && print "\n\nclose...\n"
        else
            ztcp -c $fd
        fi
    done

    if [[ "$verbose" > 0 ]]; then
        ztcp -vc $listenfd
        ztcp -vc $fd
    else
        ztcp -c $listenfd
        ztcp -c $fd
    fi
}

http-listen
