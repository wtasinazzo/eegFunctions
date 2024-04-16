clear
close all
clc

%% Caricamento dei dati
disp('Loading data ...')
cartella = '\5(Camilla)'; % cartella che contiene i file per il soggetto
ritorno = pwd; % cartella su cui sono ora
cd(fullfile(pwd,cartella)); % apro la cartella coi file

% carico i file in EEGs una variabile struct contenente 6 campi, ciascun 
% campo contiene una variabile struct EEG organizzata come sono
% tipicamente organizzate le variabili EEG di EEGLAB
% (funziona avendo chiamato i file exo1, ... , exo4, noExo1, noExo2)
for i=1:2
    EEGs(i) = load(sprintf('noExo%d.mat', i)).EEG;
end
for i=1:4
    EEGs(i+2) = load(sprintf('exo%d.mat', i)).EEG;
end

cd(ritorno);
load('settings.mat'); % carica la variabile settings (costruita in impostazioni.m)
disp('  Done.')

%% Preprocessing
for i=1:6 % pre-processing di ciascunp dei 6 file EEG di questo soggetto 
    preProcessedEEGs(i)=pre_processing(EEGs(i),settings); 
end
disp('  Done.')

%% Unione dei dataset
% Questa section unisce tutti gli EEG contenuti in EEGs in unica variabile EEG

% Prende info generali
EEG = preProcessedEEGs(1);

% Modifica info specifiche
EEG.trials=0; % n° di epoche
for i=1:6
    EEG.trials=EEG.trials+preProcessedEEGs(i).trials;
end

% uso la funzione cat per concatenare tutti i preProcessedEEGs.data in
% unico EEG.data. Il 3 perchè concatena lungo la terza dimensione 
% che è trial, perche preProcessedEEGs.data è 3D (canale x tempo x trial)
EEG.data = cat(3,preProcessedEEGs(1).data,preProcessedEEGs(2).data,preProcessedEEGs(3).data,preProcessedEEGs(4).data,preProcessedEEGs(5).data,preProcessedEEGs(6).data);

% uguale a EEG.data, ma preProcessedEEGs.condizione è vettore righe, quindi
% voglio concatenare lungo la riga che è la dimensione 2
EEG.condizione=cat(2,preProcessedEEGs(1).condizione,preProcessedEEGs(2).condizione,preProcessedEEGs(3).condizione,preProcessedEEGs(4).condizione,preProcessedEEGs(5).condizione,preProcessedEEGs(6).condizione);

%% ICA
if settings.ICA.doICA
EEG=eeg_ica(EEG,settings); % esce popup più volte, premere sempre "Cancel" (sarebbe da sistemare facendo in modo che non esca)
end

%% divisione in condizioni
% prendo info generali
selfWO=EEG; % self WithOut exo
extWO=EEG; % ext WithOut exo
selfW=EEG; % self With exo
extW=EEG; % ext With exo
expExoW=EEG; % exp controls exo


% Voglio trovare gli indici di trial con condizione "self without exo"

% creo un vettore che contiene 1 dove la condizione è 1 (self con o senza exo), 0 altrove
idxEpocsSelfWO = EEG.condizione==1; % tutti i self (con e senza exo)

% preProcessedEEGs(1) e preProcessedEEGs(2) sono i due EEG senza exo, porto
% a 0 tutti i valori di idxEpocsSelfWO che non fanno parte di preProcessedEEGs(1)
% o preProcessedEEGs(2) perchè saranno condizione "self with exo"
idxEpocsSelfWO(preProcessedEEGs(1).trials+preProcessedEEGs(2).trials+1:end) = 0; % elimino quelli exo

% Con la stessa procedura trovo indici delle altre condizioni
idxEpocsExtWO = EEG.condizione==2; % tutti gli ext (con e senza exo)
idxEpocsExtWO(preProcessedEEGs(1).trials+preProcessedEEGs(2).trials+1:end) = 0; % elimino quelli exo
idxEpocsSelfW = EEG.condizione==1; % tutti i self (con e senza exo)
idxEpocsSelfW(1:preProcessedEEGs(1).trials+preProcessedEEGs(2).trials) = 0; % elimino quelli senza exo
idxEpocsExtW = EEG.condizione==2; % tutti i self (con e senza exo)
idxEpocsExtW(1:preProcessedEEGs(1).trials+preProcessedEEGs(2).trials) = 0; % elimino senza exo
idxEpocsExpExoW = EEG.condizione==3; % indici cond. expExo

% modifico info specifiche
selfWO.trials=length(find(idxEpocsSelfWO==1));
extWO.trials=length(find(idxEpocsExtWO==1));
selfW.trials=length(find(idxEpocsSelfW==1));
extW.trials=length(find(idxEpocsExtW==1));
expExoW.trials=length(find(idxEpocsExpExoW==1));

selfWO.data=EEG.data(:,:,idxEpocsSelfWO);
extWO.data=EEG.data(:,:,idxEpocsExtWO);
selfW.data=EEG.data(:,:,idxEpocsSelfW);
extW.data=EEG.data(:,:,idxEpocsExtW);
expExoW.data=EEG.data(:,:,idxEpocsExpExoW);


%% Butterfly plot nelle varie condizione in un canale scelto

chan = 20; % canale scelto
figure()
subplot(211)
sgtitle('Channel ' +selfWO.channels(chan))
plot(selfWO.times,squeeze(selfWO.data(chan,:,:)))
xlim([-50, 200])
ylim([-70, 200])
title('self noExo')
ylabel('\muV')        
xlabel('Time from stimulus (ms)')
subplot(212)
plot(extWO.times,squeeze(extWO.data(chan,:,:)))
title('20 trials butterfly plot ')
ylabel('\muV')        
xlabel('Time from stimulus (ms)')
xlim([-50, 150])
% ylim([-70, 200])

figure()
sgtitle('Channel ' +selfWO.channels(chan))
subplot(311)
plot(selfW.times,squeeze(selfW.data(chan,:,:)))
title('self exo')
ylabel('\muV')        
xlabel('Time from stimulus (ms)')
xlim([-100,300])
% ylim([-30, 30])
subplot(312)
plot(extW.times,squeeze(extW.data(chan,:,:)))
title('ext exo')
ylabel('\muV')        
xlabel('Time from stimulus (ms)')
xlim([-100,300])
% ylim([-30, 30])
subplot(313)
plot(expExoW.times,squeeze(expExoW.data(chan,:,:)))
title('extExo')
ylabel('\muV')        
xlabel('Time from stimulus (ms)')
xlim([-100,300])
% ylim([-30, 30])

%% Butterfly plot nelle varie condizione in più canali scelti

canali_interessanti=[10,12,14,18,20]; % canali scelti
figure()
for chan = canali_interessanti
    subplot(231)
    sgtitle('Channel ' +selfWO.channels(chan))
    plot(selfWO.times,squeeze(selfWO.data(chan,:,:)))
    xlim([-100, 300])
    ylim([-50, 50])
    title('self noExo')
    ylabel('\muV')        
    xlabel('Time (ms)')
    subplot(232)
    plot(extWO.times,squeeze(extWO.data(chan,:,:)))
    title('ext noExo')
    ylabel('\muV')        
    xlabel('Time (ms)')
    xlim([-100, 300])
    ylim([-50, 50])
    subplot(234)
    plot(selfW.times,squeeze(selfW.data(chan,:,:)))
    title('self exo')
    ylabel('\muV')        
    xlabel('Time (ms)')
    xlim([-100, 300])
    ylim([-50, 50])
    subplot(235)
    plot(extW.times,squeeze(extW.data(chan,:,:)))
    title('ext exo')
    ylabel('\muV')        
    xlabel('Time (ms)')
    xlim([-100, 300])
    ylim([-50, 50])
    subplot(236)
    plot(expExoW.times,squeeze(expExoW.data(chan,:,:)))
    title('ext noExo')
    ylabel('\muV')        
    xlabel('Time (ms)')
    xlim([-100, 300])
    ylim([-50, 50])
    pause()
end

%% Salvare dati?, se vuoi non dover ripetere la procedura di preprocessing ogni volta
% dati_pul.without.self = selfWO;
% dati_pul.without.ext = extWO;
% dati_pul.with.self = selfW;
% dati_pul.with.ext = extW;
% dati_pul.with.exp_exo = expExoW;
% cd(fullfile(pwd,cartella)); % N.B. Li salva dentro la cartella dello specifico soggetto
% save('dati_puliti.mat','dati_pul')
% cd(ritorno);

%% load dati, se ho i dati salvati e voglio caricarli direttamente senza ripetere preprocessing
% cd(fullfile(pwd,cartella));
% load('dati_puliti.mat')
% selfWO = dati_pul.without.self;
% extWO = dati_pul.without.ext;
% selfW = dati_pul.with.self;
% extW = dati_pul.with.ext;
% expExoW = dati_pul.with.exp_exo;
% cd(ritorno);

%% Allineamento segnale nell'intervallo di interesse
disp('   Allineamento ...')
time_start = -5; % inizio intervallo di interesse
time_end = 250; % fine intervallo di interesse
ordine_polinomio = 4; % ordine polinomio fittato, visto il piccolo num di partecipanti scelto manualmente per ciascuno
selfWO=allineamento_EEG(selfWO,time_start,time_end,ordine_polinomio); 
extWO=allineamento_EEG(extWO,time_start,time_end,ordine_polinomio); 
selfW=allineamento_EEG(selfW,time_start,time_end,ordine_polinomio); 
extW=allineamento_EEG(extW,time_start,time_end,ordine_polinomio); 
expExoW=allineamento_EEG(expExoW,time_start,time_end,ordine_polinomio);
disp('  Done.')

%% Salvare dati allineati?
% dati_all.without.self = selfWO;
% dati_all.without.ext = extWO;
% dati_all.with.self = selfW;
% dati_all.with.ext = extW;
% dati_all.with.exp_exo = expExoW;
% cd(fullfile(pwd,cartella));
% save('dati_allineati.mat','dati_all')
% cd(ritorno);

%% load dati allineati
% cd(fullfile(pwd,cartella));
% load('dati_allineati.mat')
% selfWO = dati_all.without.self;
% extWO = dati_all.without.ext;
% selfW = dati_all.with.self;
% extW = dati_all.with.ext;
% expExoW = dati_all.with.exp_exo;
% cd(ritorno);

%% Averaging
% ssi aggiunge alle struct EEG una matrice che contiene le average delle epoche per ciascun canale e la std delle stime.
selfWO = average_EEG(selfWO,settings);
extWO = average_EEG(extWO,settings);
selfW = average_EEG(selfW,settings);
extW = average_EEG(extW,settings);
expExoW = average_EEG(expExoW,settings);


%% PLOT condizioni SENZA Exo, canale a scelta ************************************************************
% canali_interessanti=[10,7,14,20];
canali_interessanti=20; % canali scelti

cont=0;
figure()

% commentando le cose giuste posso plottare solo stime dei potenziali o
% anche con intervalli di confidenza
for i=canali_interessanti
    cont=cont+1;
    % subplot(2,2,cont)
    % plot(selfWO.times,selfWO.average.stima(i,:),'b',extWO.times,extWO.average.stima(i,:),'r',...
    %     selfWO.times,selfWO.average.stima(i,:)+selfWO.average.std(i,:),':b',...
    %     extWO.times,extWO.average.stima(i,:)+extWO.average.std(i,:),':r',...
    %     selfWO.times,selfWO.average.stima(i,:)-selfWO.average.std(i,:),':b',...
    %     extWO.times,extWO.average.stima(i,:)-extWO.average.std(i,:),':r',...
    %     [0,0],[-100,100],'LineWidth',1)
    % legend('Self ± SD','Ext ± SD')
    % sgtitle('Averaging ')
    plot(selfWO.times,selfWO.average.stima(i,:),'b',extWO.times,extWO.average.stima(i,:),'r',...
        [0,0],[-100,100],'LineWidth',1)
    legend('Self','Ext')
    title('Averaging, Canale: '+ selfWO.channels(i))
    % ylabel('(\muV)') 
    ylabel('Deviation from slow trend (\muV)')        
    xlabel('Time from stimulus (ms)')
    xlim([-5 150])
    ylim([-10 10])
end

%% Senza exo, plot di tutti i canali
figure()
for i=1:selfW.nbchan
plot(selfWO.times,selfWO.average.stima(i,:),'b',extWO.times,extWO.average.stima(i,:),'r',...
        selfWO.times,selfWO.average.stima(i,:)+selfWO.average.std(i,:),':b',...
        extWO.times,extWO.average.stima(i,:)+extWO.average.std(i,:),':r',...
        selfWO.times,selfWO.average.stima(i,:)-selfWO.average.std(i,:),':b',...
        extWO.times,extWO.average.stima(i,:)-extWO.average.std(i,:),':r',...
        [0,0],[-100,100],'LineWidth',1)
    legend('Self ± SD','Ext ± SD')
    % plot(selfWO.times,selfWO.average.stima(i,:),'b',extWO.times,extWO.average.stima(i,:),'r',...
    %     [0,0],[-100,100],'LineWidth',1)
    % legend('Self','Ext')
    title('AVERAGING, Canale: '+ selfWO.channels(i))
    ylabel('\muV')        
    xlabel('Time (ms)')
    xlim([-100 400])
    ylim([-15 12])
    pause()
end

%% Grafico con topoplot
chan = 14;
figure()
sgtitle('Canale: '+ selfWO.channels(chan));
step=30;
start=0;
fine=120;
idx_times = find(selfWO.times>=start & selfWO.times<=fine);
num_topop = floor((fine-start)/step) +1;
idx_topop = idx_times(1:floor(length(idx_times)/(num_topop-1))-1:length(idx_times));
subplot(6,num_topop,num_topop+1:num_topop*5)
plot(selfWO.times(idx_times),selfWO.average.stima(chan,idx_times),'b',extWO.times(idx_times),extWO.average.stima(chan,idx_times),'r',...
    selfWO.times(idx_times),selfWO.average.stima(chan,idx_times)+selfWO.average.std(chan,idx_times),':b',...
    extWO.times(idx_times),extWO.average.stima(chan,idx_times)+extWO.average.std(chan,idx_times),':r',...
    selfWO.times(idx_times),selfWO.average.stima(chan,idx_times)-selfWO.average.std(chan,idx_times),':b',...
    extWO.times(idx_times),extWO.average.stima(chan,idx_times)-extWO.average.std(chan,idx_times),':r',...
    [0,0],[-100,100],'LineWidth',1)
legend('Self ± SD','Ext ± SD')
ylabel('\muV')        
% xlabel('Time (ms)')
ylim([-6 6])
xlim([start, fine])

for i = 1:num_topop
    % Aggiunta del topoplot ogni 25 ms
    subplot(6, num_topop, i); % crea una seconda subplot per il topoplot
    topoplot(selfWO.average.stima(:,idx_topop(i)),extWO.chanlocs, 'electrodes','off');
    title(['Self @', num2str(round(selfWO.times(idx_topop(i)))), ' ms']);
    subplot(6, num_topop, num_topop*5+i); % crea una seconda subplot per il topoplot
    topoplot(extWO.average.stima(:,idx_topop(i)),extWO.chanlocs, 'electrodes','off');
    title(['Ext @', num2str(round(selfWO.times(idx_topop(i)))), ' ms']);
end

%% Topoplot, Distribuzione del potenziale a tempo a scelta
EEG.times = selfW.times;

figure()
time=97;
sgtitle(['@ time: ',num2str(time),'ms'])
subplot(211)
topoplot(selfWO.average.stima(:,abs(EEG.times-time)<0.25),selfW.chanlocs,'electrodes','labelpoint');
title('Self (cond.1B)')
subplot(212)
topoplot(extWO.average.stima(:,abs(EEG.times-time)<0.25),extW.chanlocs,'electrodes','labelpoint');
title('External (cond.2B)')




%% PLOT CON EXO, canali a scelta **********************************************
% canali_interessanti=20;
cont=0;
figure()
for i=canali_interessanti
    cont=cont+1;
    % subplot(2,2,cont)
    % plot(selfW.times,selfW.average.stima(i,:),'b',extW.times,extW.average.stima(i,:),'r',...
    %     expExoW.times,expExoW.average.stima(i,:),'k',...
    %     selfW.times,selfW.average.stima(i,:)+selfW.average.std(i,:),':b',...
    %     extW.times,extW.average.stima(i,:)+extW.average.std(i,:),':r',...
    %     expExoW.times,expExoW.average.stima(i,:)+expExoW.average.std(i,:),':k',...
    %     selfW.times,selfW.average.stima(i,:)-selfW.average.std(i,:),':b',...
    %     extW.times,extW.average.stima(i,:)-extW.average.std(i,:),':r',...
    %     expExoW.times,expExoW.average.stima(i,:)-expExoW.average.std(i,:),':k',...
    %     [0,0],[-100,100],'LineWidth',1)
    % legend('SelfExo ± SD','Ext ± SD','ExtExo ± SD')
    % sgtitle('Averaging ')
    plot(selfW.times,selfW.average.stima(i,:),'b',extW.times,extW.average.stima(i,:),'r',...
        expExoW.times,expExoW.average.stima(i,:),'k',[0,0],[-100,100],'LineWidth',1)
    legend('SelfExo','Ext','ExtExo')
    title('Averaging, Canale: '+ selfWO.channels(i))
    ylabel('Deviation from slow trend (\muV)') 
    % ylabel('(\muV)')
    xlabel('Time from stimulus (ms)')
    xlim([-5 150])
    ylim([-10 10])
end

%% PLOT CON EXO, tutti i canali
figure()
% for i=1:selfW.nbchan
for i=canali_interessanti
    plot(selfW.times,selfW.average.stima(i,:),'b',extW.times,extW.average.stima(i,:),'r',...
        expExoW.times,expExoW.average.stima(i,:),'k',...
        selfW.times,selfW.average.stima(i,:)+selfW.average.std(i,:),':b',...
        extW.times,extW.average.stima(i,:)+extW.average.std(i,:),':r',...
        expExoW.times,expExoW.average.stima(i,:)+expExoW.average.std(i,:),':k',...
        selfW.times,selfW.average.stima(i,:)-selfW.average.std(i,:),':b',...
        extW.times,extW.average.stima(i,:)-extW.average.std(i,:),':r',...
        expExoW.times,expExoW.average.stima(i,:)-expExoW.average.std(i,:),':k',...
        [0,0],[-100,100],'LineWidth',1)
    legend('SelfExo ± SD','Ext ± SD','ExtExo ± SD')
    % plot(selfW.times,selfW.average.stima(i,:),'b',extW.times,extW.average.stima(i,:),'r',...
    %     expExoW.times,expExoW.average.stima(i,:),'k',[0,0],[-100,100],'LineWidth',1)
    % legend('SelfExo ± SD','Ext ± SD','ExtExo ± SD')
    title('AVERAGING, Canale: '+ selfW.channels(i))
    ylabel('\muV')        
    xlabel('Time (ms)')
    xlim([-100 400])
    ylim([-15 12])
    pause()
end

%% Topoplot, Distribuzione del potenziale 

figure()
time=97;
sgtitle(['@ time: ',num2str(time),'ms'])
subplot(311)
topoplot(selfW.average.stima(:,abs(EEG.times-time)<0.25),selfW.chanlocs,'electrodes','labelpoint');
title('Self Exo (cond.1A)')
subplot(312)
topoplot(extW.average.stima(:,abs(EEG.times-time)<0.25),extW.chanlocs,'electrodes','labelpoint');
title('External Exo (cond.2A)')
subplot(313)
topoplot(expExoW.average.stima(:,abs(EEG.times-time)<0.25),expExoW.chanlocs,'electrodes','labelpoint');
title('Exp. Exo (cond.3A)')

%% Grafico con topoplot
chan = 20;
figure()
sgtitle('Canale: '+ selfW.channels(chan));
step=30;
start=0;
fine=120;
idx_times = find(selfW.times>start & selfW.times<fine);
num_topop = floor((fine-start)/step) +1;
idx_topop = idx_times(1:round(step/selfW.Ts):round(step*(num_topop-1)/selfW.Ts)); 
subplot(7,num_topop,num_topop+1:num_topop*5)
plot(selfW.times,selfW.average.stima(chan,:),'b',extW.times,extW.average.stima(chan,:),'r',...
    expExoW.times,expExoW.average.stima(chan,:),'k',...
    selfW.times,selfW.average.stima(chan,:)+selfW.average.std(i,:),':b',...
    extW.times,extW.average.stima(chan,:)+extW.average.std(chan,:),':r',...
    expExoW.times,expExoW.average.stima(chan,:)+expExoW.average.std(chan,:),':k',...
    selfW.times,selfW.average.stima(chan,:)-selfW.average.std(chan,:),':b',...
    extW.times,extW.average.stima(chan,:)-extW.average.std(chan,:),':r',...
    expExoW.times,expExoW.average.stima(chan,:)-expExoW.average.std(chan,:),':k',...
    [0,0],[-100,100],'LineWidth',1)
legend('SelfExo ± SD','Ext ± SD','ExtExo ± SD')
ylabel('\muV')        
ylim([-6 6])
xlim([start, fine])

for i = 1:num_topop
    % Aggiunta del topoplot ogni 25 ms
    subplot(7, num_topop, i); % crea una seconda subplot per il topoplot
    topoplot(extW.average.stima(:,idx_topop(i)),extW.chanlocs, 'electrodes','off');
    title(['Ext @', num2str(round(selfW.times(idx_topop(i)))), ' ms']);
    subplot(7, num_topop, num_topop*5+i); % crea una seconda subplot per il topoplot
    topoplot(expExoW.average.stima(:,idx_topop(i)),extW.chanlocs, 'electrodes','off');
    title(['ExtExo @', num2str(round(selfW.times(idx_topop(i)))), ' ms']);
    subplot(7, num_topop, num_topop*6+i); % crea una seconda subplot per il topoplot
    topoplot(selfW.average.stima(:,idx_topop(i)),extW.chanlocs, 'electrodes','off');
    title(['SelfExo @', num2str(round(selfW.times(idx_topop(i)))), ' ms']);
end


%% PLOT TUTTE LE CONDIZIONI, canale a scelta ************************************************
canali_interessanti = [20];
% canali_interessanti = 10;

cont=0;
figure()
for i=canali_interessanti
    cont = cont+1;
    % subplot(2,1,cont)
    % plot(selfWO.times,selfWO.average.stima(i,:),'g',extWO.times,extWO.average.stima(i,:),'m',...
    % selfW.times,selfW.average.stima(i,:),'b',extW.times,extW.average.stima(i,:),'r',...
    % expExoW.times,expExoW.average.stima(i,:),'k',...
    % selfWO.times,selfWO.average.stima(i,:)+selfWO.average.std(i,:),':g',...
    % extWO.times,extWO.average.stima(i,:)+extWO.average.std(i,:),':m',...
    % selfWO.times,selfWO.average.stima(i,:)-selfWO.average.std(i,:),':g',...
    % extWO.times,extWO.average.stima(i,:)-extWO.average.std(i,:),':m',...
    % selfW.times,selfW.average.stima(i,:)+selfW.average.std(i,:),':b',...
    % extW.times,extW.average.stima(i,:)+extW.average.std(i,:),':r',...
    % expExoW.bayes.time,expExoW.average.stima(i,:)+expExoW.average.std(i,:),':k',...
    % selfW.times,selfW.average.stima(i,:)-selfW.average.std(i,:),':b',...
    % extW.times,extW.average.stima(i,:)-extW.average.std(i,:),':r',...
    % expExoW.times,expExoW.average.stima(i,:)-expExoW.average.std(i,:),':k',...
    % [0,0],[-100,100],'LineWidth',1)
    % legend('Self ± SD','Ext ± SD''SelfExo ± SD','ExtWithExo ± SD','ExpExo ± SD')
    % sgtitle('Averaging')
    plot(selfWO.times,selfWO.average.stima(i,:),'g',extWO.times,extWO.average.stima(i,:),'m',...
        selfW.times,selfW.average.stima(i,:),'b',extW.times,extW.average.stima(i,:),'r',...
        expExoW.times,expExoW.average.stima(i,:),'k',[0,0],[-100,100],'LineWidth',1)
    legend('Self (1B)','Ext (2B)','SelfExo (1A)','ExtWithExo (2A)','ExpExo (3A)')
    title('Averaging, Canale: '+ selfWO.channels(i))
    ylabel('Deviation from slow trend (\muV)')
    % ylabel('(\muV)')
    xlabel('Time from stimulus (ms)')
    xlim([-5 150])
    % ylim([-15 15])
    ylim([-10,10])
end

%% PLOT TUTTE LE CONDIZIONI, tutti canali
figure()
for i=1:selfW.nbchan
    % plot(selfWO.times,selfWO.average.stima(i,:),'g',extWO.times,extWO.average.stima(i,:),'m',...
    % selfW.times,selfW.average.stima(i,:),'b',extW.times,extW.average.stima(i,:),'r',...
    % expExoW.times,expExoW.average.stima(i,:),'k',...
    % selfWO.times,selfWO.average.stima(i,:)+selfWO.average.std(i,:),':g',...
    % extWO.times,extWO.average.stima(i,:)+extWO.average.std(i,:),':m',...
    % selfWO.times,selfWO.average.stima(i,:)-selfWO.average.std(i,:),':g',...
    % extWO.times,extWO.average.stima(i,:)-extWO.average.std(i,:),':m',...
    % selfW.times,selfW.average.stima(i,:)+selfW.average.std(i,:),':b',...
    % extW.times,extW.average.stima(i,:)+extW.average.std(i,:),':r',...
    % expExoW.bayes.time,expExoW.average.stima(i,:)+expExoW.average.std(i,:),':k',...
    % selfW.times,selfW.average.stima(i,:)-selfW.average.std(i,:),':b',...
    % extW.times,extW.average.stima(i,:)-extW.average.std(i,:),':r',...
    % expExoW.times,expExoW.average.stima(i,:)-expExoW.average.std(i,:),':k',...
    % [0,0],[-100,100],'LineWidth',1)
    % legend('Self ± SD','Ext ± SD''SelfExo ± SD','ExtWithExo ± SD','ExpExo ± SD')
    sgtitle('Averaging')
    plot(selfWO.times,selfWO.average.stima(i,:),'g',extWO.times,extWO.average.stima(i,:),'m',...
        selfW.times,selfW.average.stima(i,:),'b',extW.times,extW.average.stima(i,:),'r',...
        expExoW.times,expExoW.average.stima(i,:),'k',[0,0],[-100,100],'LineWidth',1)
    legend('Self','Ext','SelfExo','ExtWithExo','ExpExo')
    title('Canale: '+ selfW.channels(i))
    ylabel('\muV')        
    xlabel('Time (ms)')
    xlim([-50 200])
    ylim([-8 8])
    pause()
end



%% video distibuzione potenziale nel tempo
figure(1)
chan=10;
for idx=1:3:length(extW.times)
    sgtitle(['Ext, @ time: ',num2str(extW.times(idx)),'ms'])
    subplot(211)
    title('AVERAGING, Canale: '+ extW.channels(chan))
    plot(extW.times,extW.average.stima(chan,:),'r',[extW.times(idx),extW.times(idx)],[-100,100],'k','LineWidth',1)
    xlim([0 250])
    ylim([-10 10])
    subplot(212)
    title('Topoplot')
    topoplot(extW.average.stima(:,idx),extW.chanlocs,'style','map');
    pause(0.001)
end
