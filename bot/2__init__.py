import aiml
import os

kernel = aiml.Kernel()

def reset_bot():
    kernel.bootstrap(learnFiles = "bot/std-startup.xml", commands = f"INICIAR TESTE")
    kernel.saveBrain("bot/cerebro.brn")

directory = os.path.dirname(os.path.realpath(__file__))
print(directory)
directoryBootstrap = directory + "/std-startup.xml"
print(directoryBootstrap)
directoryBrain = directory + "/cerebro.brn"
print(directoryBrain)

if os.path.isfile("bot/cerebro.brn"):
    reset_bot()
else:
    reset_bot()

session_id = 1

session_data = kernel.getSessionData(session_id)

kernel.setBotPredicate("name", "rAVA")

def run_bot_terminal(fala, userID):
    #GERANDO ARQUIVO PARA ARMAZENAR AS FALAS DO USUÁRIO
    f_name = "interact" + userID + ".txt"
    f_userInteract = open(f_name, "a")
    fala += "\n"
    f_userInteract.write(fala)
    f_userInteract.close()
    ##

    #GERANDO ARQUVIO PARA O LOG DE CONVERSA
    n = ""
    k = 1
    if os.path.isfile("logs.txt"):
        while True:
            k += 1
            if not os.path.isfile(f'logs{str(k)}.txt'):
                n = str(k)
                break
    ##

    f_userInteract = open(f_name, "r")
    userInteractList = f_userInteract.readlines()
    size = len(userInteractList)
    for i in range(size):
        entrada_usuario = pre_processamento(userInteractList[i])
        tgt = dispatcher(entrada_usuario)
        if tgt == 'aiml':
            resp = kernel.respond(entrada_usuario, session_id)
            if(i == size-1):
                f_name = "resp" + userID + ".txt"
                f_resp = open(f_name,"w")
                f_resp.write(resp)
                f_resp.close()
        elif tgt == 'arit':
            pass    
        elif tgt == 'logic':
            pass
    f_userInteract.close()

def pre_processamento(msg):
    # Essa função vai executar qualquer pré-processamento relevante para a mensagem
    msg = msg.upper()
    
    return msg

def dispatcher(msg):
    # Essa função vai classificar a mensagem e retornar qual é o tipo de processamento alvo
    
    # Por enquanto só usamos o aiml
    if msg:
        tgt = 'aiml'
    
    return tgt

def run_test_from_file(file):
    f = open(file, mode='r', encoding="utf-8")
    test_logs = [['usr',l.strip()] for l in f]
    run_bot_with_logs(test_logs, test_mode=True)
    f.close()

def run_bot_with_logs(logs, test_mode=False):
    #print("RODANDO BOT COM LOGS: "+str(logs))
    for i, msg in enumerate(logs):
        
        entrada_usuario = pre_processamento(msg[1])
        
        tgt = dispatcher(entrada_usuario)

        if tgt == 'aiml':
            resp = kernel.respond(entrada_usuario, session_id)
        elif tgt == 'arit':
            # resp = aritmetica(entrada_usuario)
            pass
        elif tgt == 'logic':
            # resp = logica(entrada_usuario)
            pass
            
        if test_mode:
            print(f'> {entrada_usuario.lower()}')
        if (i+1) == len(logs):
            return resp
     
def log(entrada, resposta, arq):
    arq.write(f'>>> {entrada.lower()}\n')
    arq.write(resposta.upper()+'\n')
    arq.write("\n") 