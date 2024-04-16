function EEG = eeg_ica(EEG,settings)

% Run di fastICA 
EEG = pop_runica(EEG, 'icatype', 'fastica', 'approach', 'symm','maxNumIterations',5000);

disp('   ICLabel ...')
EEG = iclabel(EEG);

% Visualizzazione delle proprietà delle ICs
pop_viewprops(EEG,0,1:size(EEG.icaweights, 1),{'ICLabel','on','freqrange',[2 settings.preprocessing.filt.lp.freqPassata]})


disp('   Component removal ...')
toDelete = []; % vettore contenente componenti da eliminare

% Selezione componenti da eliminare
switch settings.ICA.metodo_di_scelta
    
    case 'Manual'
        % Chiedi all'utente di inserire i numeri separati da virgole
        input_utente = input('Inserisci le componenti che vuoi eliminare, separate da virgole: ', 's');
        
        % Conversione della stringa di input in un vettore di numeri
        input_utente = strsplit(input_utente, ',');
        for i=1:size(input_utente,2)
            toDelete = [toDelete, str2double(input_utente(i))];
        end

    otherwise
        disp('      Metodo non ancora implementato')
end

% Rimozione delle ICs selezionate
EEG = pop_subcomp(EEG, toDelete);
disp(['      Componenti eliminate: ',num2str(toDelete)]);

EEG.data = double(EEG.data);










