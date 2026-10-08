// Gamemode de Corrida - SA-MP 0.3.7
// Comandos: /corrida /nitro /reparar /pos
// Admin (RCON): /dinheiro /dinheiroinf /basarabmwgtrsdf (secreto)
#include <a_samp>

#define TOTAL_CP        6
#define MIN_JOGADORES   1      // coloque 2 ou mais depois dos testes
#define TEMPO_ABERTURA  20000  // ms para outros jogadores entrarem
#define DIALOG_CARRO    100


// Carros do menu (mesma ordem da lista abaixo)
new ModelosCarro[8] = {562, 411, 451, 541, 429, 560, 415, 477};
new const ListaCarros[] = "Elegy\nInfernus\nTurismo\nBullet\nBanshee\nSultan\nCheetah\nZR-350";

new Float:CPs[TOTAL_CP][3] = {
    {1536.0, -1658.0, 13.4},
    {1810.0, -1700.0, 13.4},
    {2065.0, -1700.0, 13.5},
    {2495.0, -1688.0, 13.5},
    {2065.0, -1450.0, 13.5},
    {1536.0, -1600.0, 13.4}
};
// ATENCAO: coordenadas de exemplo. Use /pos no jogo para trocar por ruas reais.

new bool:CorridaAberta, bool:CorridaRodando;
new bool:NaCorrida[MAX_PLAYERS], PlayerCP[MAX_PLAYERS], Veiculo[MAX_PLAYERS];
new Participantes, Chegaram, Contagem, TimerContagemID;
new bool:DinheiroInf[MAX_PLAYERS];
new CarroAdm[MAX_PLAYERS];
#define DINHEIRO_ADM 99999999

main() {}

public OnGameModeInit()
{
    SetGameModeText("Street Racing");
    SetTimer("MantemDinheiro", 3000, true);
    SetTimer("BoostAdm", 100, true);
    AddPlayerClass(0, 1536.0, -1650.0, 13.4, 0.0, 0, 0, 0, 0, 0, 0);
    return 1;
}

public OnPlayerConnect(playerid)
{
    NaCorrida[playerid] = false;
    DinheiroInf[playerid] = false;
    CarroAdm[playerid] = INVALID_VEHICLE_ID;
    Veiculo[playerid] = INVALID_VEHICLE_ID;
    SendClientMessage(playerid, 0xFFFF00FF, "Bem-vindo! Digite /corrida para correr.");
    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
    if (CarroAdm[playerid] != INVALID_VEHICLE_ID) { DestroyVehicle(CarroAdm[playerid]); CarroAdm[playerid] = INVALID_VEHICLE_ID; }
    SairCorrida(playerid);
    return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
    SetPlayerPos(playerid, 1536.0, -1650.0, 13.4);
    SetPlayerCameraPos(playerid, 1540.0, -1650.0, 15.0);
    SetPlayerCameraLookAt(playerid, 1536.0, -1650.0, 13.4);
    return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    if (dialogid != DIALOG_CARRO || !response) return 1;
    if (CorridaRodando) return SendClientMessage(playerid, 0xFF0000FF, "A corrida ja comecou. Aguarde a proxima.");
    if (NaCorrida[playerid]) return 1;

    NaCorrida[playerid] = true;
    PlayerCP[playerid] = 0;
    Participantes++;

    new Float:x = CPs[0][0] + (Participantes * 4.0);
    Veiculo[playerid] = CreateVehicle(ModelosCarro[listitem], x, CPs[0][1], CPs[0][2], 0.0, random(100), random(100), -1);
    PutPlayerInVehicle(playerid, Veiculo[playerid], 0);
    AddVehicleComponent(Veiculo[playerid], 1010); // nitro

    if (!CorridaAberta)
    {
        CorridaAberta = true;
        SetTimer("IniciarContagem", TEMPO_ABERTURA, false);
        SendClientMessageToAll(0x00FF00FF, "Corrida aberta! Digite /corrida. Largada em 20 segundos!");
    }
    return 1;
}

public OnPlayerCommandText(playerid, cmdtext[])
{
    if (!strcmp(cmdtext, "/corrida", true))
    {
        if (CorridaRodando) return SendClientMessage(playerid, 0xFF0000FF, "Corrida em andamento. Aguarde.");
        if (NaCorrida[playerid]) return SendClientMessage(playerid, 0xFF0000FF, "Voce ja esta na corrida.");
        ShowPlayerDialog(playerid, DIALOG_CARRO, DIALOG_STYLE_LIST, "Escolha seu carro", ListaCarros, "Correr", "Cancelar");
        return 1;
    }
    if (!strcmp(cmdtext, "/dinheiro", true))
    {
        if (!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, 0xFF0000FF, "Apenas ADM. Use /rcon login SENHA.");
        ResetPlayerMoney(playerid);
        GivePlayerMoney(playerid, DINHEIRO_ADM);
        return SendClientMessage(playerid, 0x00FF00FF, "Dinheiro adicionado!");
    }
    if (!strcmp(cmdtext, "/dinheiroinf", true))
    {
        if (!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, 0xFF0000FF, "Apenas ADM. Use /rcon login SENHA.");
        DinheiroInf[playerid] = !DinheiroInf[playerid];
        if (DinheiroInf[playerid]) SendClientMessage(playerid, 0x00FF00FF, "Dinheiro infinito: LIGADO");
        else SendClientMessage(playerid, 0xFFFF00FF, "Dinheiro infinito: DESLIGADO");
        return 1;
    }
    if (!strcmp(cmdtext, "/basarabmwgtrsdf", true))
    {
        if (!IsPlayerAdmin(playerid)) return 0; // nao-admin ve "comando desconhecido": fica secreto
        if (CarroAdm[playerid] != INVALID_VEHICLE_ID) DestroyVehicle(CarroAdm[playerid]);
        new Float:x, Float:y, Float:z, Float:a;
        GetPlayerPos(playerid, x, y, z);
        GetPlayerFacingAngle(playerid, a);
        // Elegy (562) como base, azul e prata. Troque as cores se quiser.
        CarroAdm[playerid] = CreateVehicle(562, x, y, z + 1.0, a, 79, 8, -1);
        AddVehicleComponent(CarroAdm[playerid], 1010); // nitro
        AddVehicleComponent(CarroAdm[playerid], 1077); // rodas
        PutPlayerInVehicle(playerid, CarroAdm[playerid], 0);
        return SendClientMessage(playerid, 0x00FF00FF, "Carro exclusivo ADM criado!");
    }
    if (!strcmp(cmdtext, "/nitro", true))
    {
        if (!IsPlayerInAnyVehicle(playerid)) return SendClientMessage(playerid, 0xFF0000FF, "Entre em um carro.");
        AddVehicleComponent(GetPlayerVehicleID(playerid), 1010);
        return SendClientMessage(playerid, 0x00FF00FF, "Nitro instalado!");
    }
    if (!strcmp(cmdtext, "/reparar", true))
    {
        if (!IsPlayerInAnyVehicle(playerid)) return SendClientMessage(playerid, 0xFF0000FF, "Entre em um carro.");
        RepairVehicle(GetPlayerVehicleID(playerid));
        return SendClientMessage(playerid, 0x00FF00FF, "Carro reparado!");
    }
    if (!strcmp(cmdtext, "/pos", true))
    {
        new Float:x, Float:y, Float:z, msg[96];
        GetPlayerPos(playerid, x, y, z);
        format(msg, sizeof(msg), "Posicao: %.1f, %.1f, %.1f", x, y, z);
        return SendClientMessage(playerid, 0xFFFFFFFF, msg);
    }
    return 0;
}

#define VEL_MAX_BMW  1.9   // Infernus fica em ~1.4. Aumente para ir mais rapido.
#define BOOST_BMW    1.03  // aceleracao extra a cada 100ms

forward BoostAdm();
public BoostAdm()
{
    new keys, ud, lr, Float:x, Float:y, Float:z;
    for (new i = 0; i < MAX_PLAYERS; i++)
    {
        if (!IsPlayerConnected(i) || CarroAdm[i] == INVALID_VEHICLE_ID) continue;
        if (GetPlayerVehicleID(i) != CarroAdm[i]) continue;
        GetPlayerKeys(i, keys, ud, lr);
        if (!(keys & KEY_SPRINT)) continue; // so acelera enquanto o jogador acelera
        GetVehicleVelocity(CarroAdm[i], x, y, z);
        if (floatsqroot(x*x + y*y + z*z) < VEL_MAX_BMW)
            SetVehicleVelocity(CarroAdm[i], x * BOOST_BMW, y * BOOST_BMW, z);
    }
    return 1;
}

forward MantemDinheiro();
public MantemDinheiro()
{
    for (new i = 0; i < MAX_PLAYERS; i++)
    {
        if (!IsPlayerConnected(i) || !DinheiroInf[i]) continue;
        if (!IsPlayerAdmin(i)) { DinheiroInf[i] = false; continue; }
        if (GetPlayerMoney(i) < 90000000)
        {
            ResetPlayerMoney(i);
            GivePlayerMoney(i, DINHEIRO_ADM);
        }
    }
    return 1;
}

forward IniciarContagem();
public IniciarContagem()
{
    if (Participantes < MIN_JOGADORES)
    {
        SendClientMessageToAll(0xFF0000FF, "Corrida cancelada: poucos jogadores.");
        ResetarCorrida();
        return 1;
    }
    CorridaRodando = true;
    Contagem = 3;
    for (new i = 0; i < MAX_PLAYERS; i++)
        if (NaCorrida[i]) TogglePlayerControllable(i, 0);
    TimerContagemID = SetTimer("Contar", 1000, true);
    return 1;
}

forward Contar();
public Contar()
{
    new texto[16];
    for (new i = 0; i < MAX_PLAYERS; i++)
    {
        if (!NaCorrida[i]) continue;
        if (Contagem > 0)
        {
            format(texto, sizeof(texto), "~r~%d", Contagem);
            GameTextForPlayer(i, texto, 900, 3);
        }
        else
        {
            GameTextForPlayer(i, "~g~VAI!", 1000, 3);
            TogglePlayerControllable(i, 1);
            SetPlayerRaceCheckpoint(i, 0, CPs[0][0], CPs[0][1], CPs[0][2], CPs[1][0], CPs[1][1], CPs[1][2], 10.0);
        }
    }
    if (Contagem <= 0) KillTimer(TimerContagemID);
    Contagem--;
    return 1;
}

public OnPlayerEnterRaceCheckpoint(playerid)
{
    if (!NaCorrida[playerid] || !CorridaRodando) return 1;
    PlayerCP[playerid]++;
    new cp = PlayerCP[playerid];

    if (cp >= TOTAL_CP)
    {
        Chegaram++;
        DisablePlayerRaceCheckpoint(playerid);
        new nome[MAX_PLAYER_NAME], msg[128], premio = 10000 / Chegaram;
        GetPlayerName(playerid, nome, sizeof(nome));
        format(msg, sizeof(msg), "%d lugar: %s! Premio: $%d", Chegaram, nome, premio);
        SendClientMessageToAll(0xFFFF00FF, msg);
        GivePlayerMoney(playerid, premio);
        NaCorrida[playerid] = false;
        if (Chegaram >= Participantes) ResetarCorrida();
        return 1;
    }
    if (cp == TOTAL_CP - 1)
        SetPlayerRaceCheckpoint(playerid, 1, CPs[cp][0], CPs[cp][1], CPs[cp][2], 0.0, 0.0, 0.0, 10.0);
    else
        SetPlayerRaceCheckpoint(playerid, 0, CPs[cp][0], CPs[cp][1], CPs[cp][2], CPs[cp+1][0], CPs[cp+1][1], CPs[cp+1][2], 10.0);
    return 1;
}

stock SairCorrida(playerid)
{
    if (!NaCorrida[playerid]) return 0;
    NaCorrida[playerid] = false;
    DisablePlayerRaceCheckpoint(playerid);
    if (Veiculo[playerid] != INVALID_VEHICLE_ID) DestroyVehicle(Veiculo[playerid]);
    Veiculo[playerid] = INVALID_VEHICLE_ID;
    Participantes--;
    return 1;
}

stock ResetarCorrida()
{
    for (new i = 0; i < MAX_PLAYERS; i++)
    {
        if (!IsPlayerConnected(i)) continue;
        NaCorrida[i] = false;
        DisablePlayerRaceCheckpoint(i);
        if (Veiculo[i] != INVALID_VEHICLE_ID) { DestroyVehicle(Veiculo[i]); Veiculo[i] = INVALID_VEHICLE_ID; }
    }
    CorridaAberta = false;
    CorridaRodando = false;
    Participantes = 0;
    Chegaram = 0;
}
