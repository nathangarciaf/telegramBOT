all: runScript

bot_id=6194010871:AAHkAo9WW2rhwWhJO9EZfTEkc-Mbl_se1g4

me_info:
	curl -s https://api.telegram.org/bot${bot_id}/getMe	

update_get:
	curl -s https://api.telegram.org/bot${bot_id}/getUpdates

runPy:
	python3 cerebro.py 10 oi

runScript:
	bash script_main.sh ${bot_id}