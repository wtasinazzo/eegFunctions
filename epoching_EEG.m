function EEG = epoching_EEG(EEG,settings)
% function EEG = epoching_EEG(EEG,settings)
%
% EEG restituito avrà EEG.data di 3 dimensioni (canale x tempo x epoca). I 
% parametri sono definiti in settings.preprocessing.epoching.
% EEG in uscita è lo stesso che si otterrrebbe con 'pop_epoch'.
% Permette di fare bad epochs removal e baseline correction

disp('   Divisione in epoche ...')
epochParams = settings.preprocessing.epoching;
    
% !!!!! N.B. Fs è espresso in Hz (1/s) mentre times in ms. Quindi Ts != 1/Fs
EEG.Ts = EEG.times(2)-EEG.times(1);

% Creazione nuovo vettore dei tempi, all'interno delle strutture EEG
EEG.times = - epochParams.timeBefore : EEG.Ts : epochParams.timeAfter;

% Salvataggio indici del trigger
idx_trigger= find(EEG.trigger==1);

% Se per qualche errore nell'esperimento ci sono due trigger ravvicinati li
% elimino => elimino quel trial
idx_delete = [];
for idx=1:length(idx_trigger)-1
    if abs(idx_trigger(idx)-idx_trigger(idx+1))<6000 % 6 sec (non ci dovrebbero essere stimolazioni cosi vicine in un trial se tutto funziona bene)
        idx_delete = [idx_delete, idx, idx+1];
    end
end
idx_trigger(idx_delete) = [];

% Aggiornamento variabile che tiene conto del numero di epoche
EEG.trials = length(idx_trigger);

% Aggiornamento variabile che tiene conto del numero di campioni per ogni epoca
EEG.pnts = size(EEG.times,2);

% Aggiornamento xmin ed xmax (tempi in secondi)
EEG.xmin= EEG.times(1)/1000;
EEG.xmax= EEG.times(end)/1000;

% Salvataggio ordine delle varie condizioni
EEG.condizione= ones(1, EEG.trials);% vettore che contiene 1 per self, 2 per ext, 3 per ext_exo
latency_vector= ones(size(EEG.event)); % contiene tutte le EEG.event.latency in un vettore
for i=1:size(EEG.event,2)
    latency_vector(i) = EEG.event(i).latency;
end
for i=1:EEG.trials
    idx_event = find(latency_vector<idx_trigger(i),1,'last')-1; %trovo indice dell'evento in EEG.event
    if EEG.event(idx_event).edftype==773
        EEG.condizione(i)= 1;
    elseif EEG.event(idx_event).edftype==771
        EEG.condizione(i)= 2;
    elseif EEG.event(idx_event).edftype==770
        EEG.condizione(i)= 3;
    end
end

% Creazione del nuovo EEG.data
EEG.nonEpochedData = EEG.data; % variabile temporanea su cui salvo i dati
EEG.data = zeros(EEG.nbchan,length(EEG.times),EEG.trials); % EEG.data diventa 3D: (canale x tempo x epoca)
for j=1:EEG.nbchan %per ogni canale
    for k=1:EEG.trials %per ogni epoca
        idxStart = idx_trigger(k) - epochParams.timeBefore/EEG.Ts; % indice tempo da cui comincio ad estrarre
        idxEnd = idx_trigger(k) + epochParams.timeAfter/EEG.Ts; % indice ultimo tempo da cui estraggo
        EEG.data(j,:,k) = EEG.nonEpochedData(j,idxStart:idxEnd); % la k-esima epoca del canale j
    end
end
clear EEG.nonEpochedData % elimino la variabile temporanea

% Possibilità di rimuovere bad epochs (non fatto nella mia pipeline)
if settings.badEpochsDelete.do 
    disp('   Deleting bad epochs ...')
    threshValue = settings.badEpochsDelete.maxAbsAmplitude;
    EEG = pop_eegthresh(EEG, 1, settings.badEpochsDelete.chans, -threshValue, threshValue, settings.badEpochsDelete.secStart, settings.badEpochsDelete.secEnd, 0, 1);
    EEG.condizione = EEG.condizione(~EEG.reject.rejthresh);
end

% Possibilità di fare baseline correction (sottrarre media prestimolo a tutto il segnale)
if settings.baselineCorr.doBLC
    disp('   Baseline correction ...')
    idx_fine_prestimolo = int16((-EEG.Ts+settings.preprocessing.epoching.timeBefore)/EEG.Ts +1);
    idx_inizio = int16((-settings.baselineCorr.timeBefore+settings.preprocessing.epoching.timeBefore)/EEG.Ts +1);
    for j=1:EEG.nbchan %per ogni canale
        for k=1:EEG.trials %per ogni epoca
            baseline = mean(EEG.data(j,idx_inizio:idx_fine_prestimolo,k));
            EEG.data(j,:,k) = (EEG.data(j,:,k)-baseline);
        end
    end
end
