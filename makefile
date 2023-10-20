#Script para capturar mensagens do bot no telegram e gerar logs das interações
#Para rodar o script segue o seguinte comando: bash script_main.sh botTOKEN (sendo botTOKEN o valor passado pelo usuário)
all:  download_packages

#Inserir o botTOKEN na variável bot_id
bot_id="" 

me_info:
	curl -s https://api.telegram.org/bot$(bot_id)/getMe	

update_get:
	curl -s https://api.telegram.org/bot$(bot_id)/getUpdates

download_packages: 
	sudo apt update
	sudo apt install jq