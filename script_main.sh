#!/bin/bash
botTOKEN=""
offset="0"
pipeline="$1"

default_msg="Ola estou na versao 1.0, sou o "
interaction_type=""
image_type=""

status_id=""
status_resid=""

function set_basic_config (){
        if [[ ${pipeline} != "" ]]; then
                botTOKEN=${pipeline}
        fi

        bot_info=`curl -s https://api.telegram.org/bot${botTOKEN}/getMe`
        name_bot="$(echo $bot_info | jq -r ".result.first_name")"
        default_msg=$default_msg""$name_bot
        
        script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
        if [ ! -f "${script_dir}/next_id.txt" ]; then
                touch "${script_dir}/next_id.txt"
                offset="0"
        else
                offset=`cat ${script_dir}/next_id.txt`
                if [ offset==" " ]; then
                        offset="0"
                fi
        fi
}

function config_usr_dir(){
        user_dir="${script_dir}/$user_id"
        mkdir -p ${user_dir}

        if [ ! -f "${user_dir}/doc_confirm.txt" ]; then
                touch "${user_dir}/doc_confirm.txt"
        fi

        if [ ! -f "${user_dir}/resid_confirm.txt" ]; then
                touch "${user_dir}/resid_confirm.txt"
        fi

        user_json_dir="${user_dir}/jsons"
        mkdir -p $user_json_dir

        user_imgs_dir="${user_dir}/imgs"
        mkdir -p $user_imgs_dir

        user_docs_dir="${user_dir}/docs"
        mkdir -p $user_docs_dir

        user_vid_dir="${user_dir}/vid"
        mkdir -p $user_vid_dir
}

function status_checklist_generate(){
        doc_conf=`cat ${user_dir}/doc_confirm.txt`
        resid_conf=`cat ${user_dir}/resid_confirm.txt`

        if [[ ${doc_conf} != "" ]]; then
                status_id="1"
        fi

        if [[ ${resid_conf} != "" ]]; then
                status_resid="1"
        fi
}

function next_id_update(){
        offset="$((update_id + 1))"
        echo $offset > ${script_dir}/next_id.txt
}

function listen_usr(){
        while true 
        do
        updates="$(curl -s "https://api.telegram.org/bot${botTOKEN}/getupdates?offset=${offset}")"

        result="$(echo $updates | jq -r ".result")"
        error="$(echo $updates | jq -r ".description")"

        if [[ "${result}" == "[]" ]]; then
                exit 0
        elif [[ "${error}" != "null" ]]; then
                echo "${error}" && exit 0
        fi

        timestamp="$(echo $result | jq -r ".[0].message.date")"

        define_msg_type
        next_id_update
        if [[ ${interaction_type} == "photo" ]]; then
                if [[ ${image_type} == 0 ]]; then
                        msg="A imagem enviada é um documento de identidade"
                elif [[ ${image_type} == 1 ]]; then
                        msg="A imagem enviada é um comprovante de residência"
                fi
                interaction_type=""
        fi
        send_message
        #export_csv

        done
}

function define_msg_type(){
        update_id="$(echo $result | jq -r ".[0].update_id")"
        user_id="$(echo $result | jq -r ".[0].message.chat.id")"

        config_usr_dir

        result_user="$(echo $result | jq -r ".[0]")"
        echo $result_user > result_user.json
        jq . result_user.json > ${user_json_dir}/$update_id.json
        rm result_user.json

        document_confirm="$(echo $result | jq -r ".[0].message.document")"
        photo_confirm="$(echo $result | jq -r ".[0].message.photo")"
        video_confirm="$(echo $result | jq -r ".[0].message.video")"
        voice_confirm="$(echo $result | jq -r ".[0].message.voice")"
        
        if [[ ${document_confirm}  != "null" ]]; then
                interaction_type="document"
                process_document
        elif [[ ${photo_confirm} != "null" ]]; then
                interaction_type="photo"
                process_photo
        elif [[ ${video_confirm} != "null" ]]; then
                interaction_type="video"
                process_video
        elif [[ ${voice_confirm} != "null" ]]; then
                interaction_type="voice"
                process_voice
        else
                interaction_type="text"
                process_text
        fi
}

function process_document(){
        file_id="$(echo $result | jq -r ".[0].message.document.file_id")"
        file_json=`curl -s https://api.telegram.org/bot${botTOKEN}/getFile?file_id=${file_id}`
        file_path="$(echo $file_json | jq -r ".result.file_path")"

        application="$(echo $file_path | cut -d "." -f2)"

        curl -s -o "${user_docs_dir}/${update_id}.${application}" "https://api.telegram.org/file/bot${botTOKEN}/${file_path}"

        msg="Recebemos o seu documento!"
}

function process_photo(){
        file_id="$(echo $result | jq -r ".[0].message.photo[-1].file_id")"
        file_json=`curl -s https://api.telegram.org/bot${botTOKEN}/getFile?file_id=${file_id}`
        file_path="$(echo $file_json | jq -r ".result.file_path")"
        
        application="$(echo $file_path | cut -d "." -f2)"

        curl -s -o "${user_imgs_dir}/${update_id}.${application}" "https://api.telegram.org/file/bot${botTOKEN}/${file_path}"
        tesseract $user_imgs_dir/${update_id}.${application} ${user_imgs_dir}/${update_id}

        msg=`cat "$user_imgs_dir/${update_id}.txt"`
        msg=`echo ${msg^^}`

        if [[ $msg == *"NOME"* ]] && [[ $msg == *"CPF"* ]]; then
                image_type="0"
                echo "1" > ${user_dir}/doc_confirm.txt
        fi

        if [[ ${msg} == " \n\ff" ]]; then
                msg="Não conseguimos detectar texto nesta imagem"
        fi
}

function process_video(){
        msg="por enquanto não estou processsando este tipo de mídia"
}

function process_voice(){
        msg="por enquanto não estou processsando este tipo de mídia"
}

function process_text(){
        text_received="$(echo $result | jq -r ".[0].message.text")"

        if [[ "${text_received}" == "/start" ]]; then
                msg="${default_msg}"
        else
                python3 ${script_dir}/cerebro.py $user_id $text_received
                msg=`cat resp${user_id}.txt`
                if [[ "${msg}" == "Checklist" ]]; then
                        status_checklist_generate
                        msg="Este é o seu checklist:\nDocumento de identidade: "
                        if [[ ${status_id} != "" ]]; then
                                msg="${msg} V\n"
                        else
                                msg="${msg} X\n"
                        fi

                        msg="${msg}Comprovante de residência: "
                        if [[ ${status_resid} != "" ]]; then
                                msg="${msg} V"
                        else
                                msg="${msg} X"
                        fi
                fi
                #rm resp${user_id}.txt
        fi
}

function send_message(){
        msg_status=`curl -s -X POST -H 'Content-Type: application/json' \
                -d '{"chat_id": "'"${user_id}"'", "text": "'"${msg}"'"}' \
                https://api.telegram.org/bot${botTOKEN}/sendMessage`
}

function export_csv(){
        if [[ ! -e "${script_dir}/log.csv" ]]; then
                echo "Timestamp,BotName,ChatID,Tipo_Interacao,Mensagem_Do_Usuario,Situacao,JSON" \
                        >> ${script_dir}/log.csv
        fi

        echo $timestamp","$name_bot","$user_id","$interaction_type","$text_received",OK"","${user_json_dir}/${update_id}.json \
                >>  ${script_dir}/log.csv
}

set_basic_config
listen_usr