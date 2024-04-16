% In questo file vengono settati tutti i valori contenuti in settings, una
% variabile di tipo struct che contiene tutti i valori utilizzati nell'
% analisi dei dati

clc;
clear settings

% frequenza di resampling (ad ora non utilizzata)
settings.preprocessing.resampling.newFreq = 512; 

% Canali di interesse
settings.preprocessing.focusChannels = ["FZ","F1","F2",...
    ... % "F3","F4","F5","F6",...
    "FC1","FC2","FC3","FC4","FC5","FC6",...
    "CZ","C1","C2","C3","C4","C5","C6",...
    "CP1","CP2","CP3","CP4","CP5","CP6",...
    "PZ","P1","P2","P3","P4","P5","P6"];

% Parametri filtraggio
settings.preprocessing.filt.type = "band_pass";

settings.preprocessing.filt.hp.freqPassata = 2;
settings.preprocessing.filt.hp.freqEliminata = 0.5;
settings.preprocessing.filt.hp.ripple = -20*log10(0.9);
settings.preprocessing.filt.hp.attenuazione = -20*log10(0.05);
settings.preprocessing.filt.hp.type = 'high';

settings.preprocessing.filt.lp.freqPassata = 30;
settings.preprocessing.filt.lp.freqEliminata = 35;
settings.preprocessing.filt.lp.ripple = -20*log10(0.9);
settings.preprocessing.filt.lp.attenuazione = -20*log10(0.05);
settings.preprocessing.filt.lp.type = 'low';

% Parametri CleanLine
settings.preprocessing.Cleanline.settings = 'default';
settings.preprocessing.Cleanline.lineFrequencies = 50;

% Parametri CAR
settings.preprocessing.doCAR = true;

% Parametri epoching
settings.preprocessing.epoching.timeBefore = 500; % Tempo pre-stimolo
settings.preprocessing.epoching.timeAfter = 1000; % Tempo post-stimolo

% Parametri cancellazione epoche rumorose
settings.badEpochsDelete.do = false; % Fare o non fare 
settings.badEpochsDelete.maxAbsAmplitude = 30; % massimo valore consentito di ampiezza (in val assoluto, in microV)
settings.badEpochsDelete.secStart = -0.1; % inizio intervallo
settings.badEpochsDelete.secEnd = 0.1; % fine intervallo
settings.badEpochsDelete.chans=[13,15,19,21]; % canali dove cerca 

% Parametri ICA
settings.ICA.doICA = true; % Fare o non fare ICA
settings.ICA.metodo_di_scelta = 'Manual';
settings.ICA.classeBrain = 1; % osservando come è costruito vettore EEG.(...).ICLabel.classes
settings.ICA.classeOther = 7;


% Parametri baseline correction
settings.baselineCorr.doBLC = true; % Fare o non fare baseline correction
settings.baselineCorr.timeBefore = 500; % tempo pre-stimolo in cui inizia intervallo


% Parametri bayesian averaging
settings.bayes.m = 3; % rumore bianco integrato m-volte <-> regolarità attesa del SEP
settings.bayes.ordiniAR = 4:40; % possibili ordini del modello AR che descrive il rumore EEG
settings.bayes.gamma.tol=0.00001;
settings.bayes.gamma.max= 10^5;
settings.bayes.gamma.min= 10^(-5);

save('settings.mat','settings')