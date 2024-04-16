function EEG = pre_processing(EEG,settings)
% EEG = pre_proccessing(EEG,settings)
%
% Funzione che chiede in ingresso due strutture: EEG contenente i dati EEG
% misurati, strutturata come in EEGLAB; settings struttura in cui sono
% definiti tutti i parametri necessari al pre-processing.
% In uscita fornisce la struttura EEG modificata con i dati preprocessati
% attraverso: rimozione canali, filtraggio, CleanLine, CAR, ed epoching (che
% permette bad epochs removal e baseline correction)

disp('PRE-PROCESSING ...')

%% ********* 1.1 Rimozione canali non utili *******************
disp('   Rimozione canali ...')
% creo vettore channels nella struttura EEG 
for i=1:EEG.nbchan
    EEG.channels(i)= string(EEG.chanlocs(i).labels);
end

% Selezione indici da mantenere (i canali presenti in .focusChannels)
idxFocusChans = arrayfun(@(x) find(EEG.channels==x,1),settings.preprocessing.focusChannels);

% Salvataggio degli eventi trigger
EEG.trigger = EEG.data(end,:);

% Rimozione canali
EEG.data = EEG.data(idxFocusChans,:);

% Aggiornamento variabili della struttura EEG
EEG.nbchan = length(idxFocusChans);
EEG.chanlocs = EEG.chanlocs(idxFocusChans);
EEG.channels = EEG.channels(idxFocusChans);


%% **************** 1.2 Filtraggio ****************************

disp('   Filtraggio ...')

% **************** Passa-alto **************************
HPfilter = settings.preprocessing.filt.hp;

% Ricerca coefficienti a,b del filtro
HPfilter.Wp = HPfilter.freqPassata /(EEG.srate/2);
HPfilter.Ws = HPfilter.freqEliminata /(EEG.srate/2);
[HPfilter.order,HPfilter.cutoffFreq] = cheb2ord(HPfilter.Wp,HPfilter.Ws,HPfilter.ripple,HPfilter.attenuazione);
[HPfilter.b,HPfilter.a] = cheby2(HPfilter.order,HPfilter.attenuazione,HPfilter.cutoffFreq,HPfilter.type);

% **************** Passa-basso ******************************
LPfilter = settings.preprocessing.filt.lp;

% Ricerca coefficienti a,b del filtro
LPfilter.Wp = LPfilter.freqPassata /(EEG.srate/2);
LPfilter.Ws = LPfilter.freqEliminata /(EEG.srate/2);
[LPfilter.order,LPfilter.cutoffFreq] = cheb2ord(LPfilter.Wp,LPfilter.Ws,LPfilter.ripple,LPfilter.attenuazione);
[LPfilter.b,LPfilter.a] = cheby2(LPfilter.order,LPfilter.attenuazione,LPfilter.cutoffFreq,LPfilter.type);

% ************** Filtraggio *****************

% Filtraggio passa banda
EEG.data = (filtfilt(HPfilter.b,HPfilter.a,(filtfilt(LPfilter.b,LPfilter.a,double(EEG.data')))))';



%% ********* 1.3 CleanLine ***************
% Eseguito solo se non viene già filtrata la frequenza 50Hz
if settings.preprocessing.filt.lp.freqEliminata > settings.preprocessing.Cleanline.lineFrequencies 
    disp('   CleanLine ...')
    switch settings.preprocessing.Cleanline.settings
        case 'default' % in questo caso pop_cleanline viene usata con i suoi parametri di default in EEGLAB
            EEG = pop_cleanline(EEG, 'Bandwidth',2,'ChanCompIndices',1:EEG.nbchan,...
               'SignalType','Channels','ComputeSpectralPower',false,...
               'LineFrequencies',settings.preprocessing.Cleanline.lineFrequencies,...
               'NormalizeSpectrum',false,'LineAlpha',0.01,'PaddingFactor',2,...
               'PlotFigures',false,'ScanForLines',true,'SmoothingFactor',100,...
               'VerboseOutput',0,'SlidingWinLength',4,...
               'SlidingWinStep',1);

        otherwise
            disp('      Metodo non ancora implementato')
    end
end

%% ********* 1.4 Common average reference (CAR) ***************
if settings.preprocessing.doCAR
    disp('   Changing reference to CAR ...')

    avg_reference = mean(EEG.data); % valore medio in ciascun istante
    EEG.data = EEG.data - avg_reference;
end

%% ********* 1.5 Epoching ***************
EEG = epoching_EEG(EEG,settings);




