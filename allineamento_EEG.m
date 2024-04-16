function EEG = allineamento_EEG(EEG,time_start,time_end,ordine_polinomio)
% function EEG = allineamento_EEG(EEG,intervallo,ordine_polinomio)
%
% Funzione che modifica le lunghezze delle epoche settandole nell'intervallo
% dato in ingresso con time_start e time_end. Successivamente allinea il
% segnale utilizzando la funzione detrend e con ordine del polinomio dato in input

idx_start = find(EEG.times>=time_start, 1);
idx_end = find(EEG.times>=time_end, 1);
EEG.data = EEG.data(:,idx_start:idx_end,:);
EEG.times = EEG.times(idx_start:idx_end);

for epoca=1:EEG.trials
    for canale=1:EEG.nbchan
        EEG.data(canale,:,epoca) = detrend(EEG.data(canale,:,epoca),ordine_polinomio);
    end
end

