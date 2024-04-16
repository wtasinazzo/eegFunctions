clear
clc
close all

%%
subjects = [];
x = dir(pwd);
idx_prima_dir = 3; % da me in x la cartella del primo soggetto è la terza
n_soggetti = 6; % numero di soggetti


idx_ultima_dir = idx_prima_dir+n_soggetti-1;
idx_dir = idx_prima_dir:idx_ultima_dir;

%% Soggetti a scelta (sezione da runnare SOLO se voglio un sottogruppo dei soggetti)
% soggetti= [2,3,5,6]; % soggetti di interesse
% idx_dir = [];
% for soggetto=soggetti
%     idx_dir=[idx_dir, idx_prima_dir+soggetto-1];
% end
% n_soggetti = length(idx_dir);

%%
disp('Loading data ...')
load settings.mat
ritorno = pwd;
for i = 1:n_soggetti
    cartella = fullfile(pwd,x(idx_dir(i)).name); % cartella contenente i dati dell'i-esimo soggetto
    cd(cartella);
    subjects.(['subj',num2str(i)]).dati = load("dati_allineati.mat");
    subjects.(['subj',num2str(i)]).dati = subjects.(['subj',num2str(i)]).dati.dati_all;
    cd(ritorno);
end
disp('  Done.')

%% New variables
disp('Creating new variables ...')

% Prendo info generali dal primo dei soggetti
selfEEG = subjects.subj1.dati.without.self;
extEEG = subjects.subj1.dati.without.ext;
selfExoEEG = subjects.subj1.dati.with.self;
extEEGwEXO = subjects.subj1.dati.with.ext;
expExoEEG = subjects.subj1.dati.with.exp_exo;

% Poi aggiungo ad eeg.data i dati eeg di tutti gli altri soggetti
for i =2:n_soggetti
    selfEEG.data = cat(3,selfEEG.data,subjects.(['subj',num2str(i)]).dati.without.self.data);
    extEEG.data = cat(3,extEEG.data, subjects.(['subj',num2str(i)]).dati.without.ext.data);
    selfExoEEG.data = cat(3,selfExoEEG.data, subjects.(['subj',num2str(i)]).dati.with.self.data);
    extEEGwEXO.data = cat(3,extEEGwEXO.data, subjects.(['subj',num2str(i)]).dati.with.ext.data);
    expExoEEG.data = cat(3,expExoEEG.data, subjects.(['subj',num2str(i)]).dati.with.exp_exo.data);
end
disp('  Done.')

%% Grand-averaging
selfEEG = average_EEG(selfEEG,settings);
extEEG = average_EEG(extEEG,settings);
selfExoEEG = average_EEG(selfExoEEG,settings);
extEEGwEXO = average_EEG(extEEGwEXO,settings);
expExoEEG = average_EEG(expExoEEG,settings);

%% Plot
% canali_interessanti=[14,20];
canali_interessanti=10;
cont=0;
figure()
for i=canali_interessanti
    cont=cont+1;
    % subplot(2,1,cont)
    % plot(selfEEG.times,selfEEG.average.stima(i,:),'g',extEEG.times,extEEG.average.stima(i,:),'m',...
    % selfExoEEG.times,selfExoEEG.average.stima(i,:),'b',extEEGwEXO.times,extEEGwEXO.average.stima(i,:),'r',...
    % expExoEEG.times,expExoEEG.average.stima(i,:),'k',...
    % selfEEG.times,selfEEG.average.stima(i,:)+selfEEG.average.std(i,:),':g',...
    % extEEG.times,extEEG.average.stima(i,:)+extEEG.average.std(i,:),':m',...
    % selfEEG.times,selfEEG.average.stima(i,:)-selfEEG.average.std(i,:),':g',...
    % extEEG.times,extEEG.average.stima(i,:)-extEEG.average.std(i,:),':m',...
    % selfExoEEG.times,selfExoEEG.average.stima(i,:)+selfExoEEG.average.std(i,:),':b',...
    % extEEGwEXO.times,extEEGwEXO.average.stima(i,:)+extEEGwEXO.average.std(i,:),':r',...
    % expExoEEG.times,expExoEEG.average.stima(i,:)+expExoEEG.average.std(i,:),':k',...
    % selfExoEEG.times,selfExoEEG.average.stima(i,:)-selfExoEEG.average.std(i,:),':b',...
    % extEEGwEXO.times,extEEGwEXO.average.stima(i,:)-extEEGwEXO.average.std(i,:),':r',...
    % expExoEEG.times,expExoEEG.average.stima(i,:)-expExoEEG.average.std(i,:),':k',...
    % [0,0],[-100,100],'LineWidth',1)
    % legend('Self ± SD','Ext ± SD''SelfExo ± SD','ExtWithExo ± SD','ExpExo ± SD')
    % sgtitle('Grand Averaging')
    plot(selfEEG.times,selfEEG.average.stima(i,:),'g',extEEG.times,extEEG.average.stima(i,:),'m',...
        selfExoEEG.times,selfExoEEG.average.stima(i,:),'b',extEEGwEXO.times,extEEGwEXO.average.stima(i,:),'r',...
        expExoEEG.times,expExoEEG.average.stima(i,:),'k',[0,0],[-100,100],'LineWidth',1)
    legend('Self (1B)','Ext (2B)','SelfExo (1A)','ExtWithExo (2A)','ExpExo (3A)')
    title('Grand-averaging, Canale: '+ selfEEG.channels(i))
    ylabel('Deviation from slow trend (\muV)')
    % ylabel('(\muV)')
    xlabel('Time from stimulus (ms)')
    xlim([-5 250])
    ylim([-10 10])
end

%% Topoplot, Distribuzione del potenziale 
EEG=selfEEG;
figure()
time=100;
% sgtitle(['@ time: ',num2str(time),'ms'])
subplot(231)
topoplot(selfEEG.average.stima(:,abs(EEG.times-time)<0.25),selfEEG.chanlocs,'electrodes','labelpoint');
title('Self (1B)')
subplot(232)
topoplot(extEEG.average.stima(:,abs(EEG.times-time)<0.25),extEEG.chanlocs,'electrodes','labelpoint');
title('External (2B)')
subplot(234)
topoplot(selfExoEEG.average.stima(:,abs(EEG.times-time)<0.25),selfExoEEG.chanlocs,'electrodes','labelpoint');
title('SelfExo (1A)')
subplot(235)
topoplot(extEEGwEXO.average.stima(:,abs(EEG.times-time)<0.25),extEEGwEXO.chanlocs,'electrodes','labelpoint');
title('Ext with Exo (2A)')
subplot(236)
topoplot(expExoEEG.average.stima(:,abs(EEG.times-time)<0.25),expExoEEG.chanlocs,'electrodes','labelpoint');
title('Experimenter Exo (3A)')

