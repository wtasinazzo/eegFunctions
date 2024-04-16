function EEG = average_EEG(EEG,settings)
% function EEG = average_EEG(EEG,settings)
%
% Funzione che aggiunge alla struttura EEG di EEGLAB una matrice che
% contiene le average delle epoche per ciascun canale e la std delle stime.

n_epochs = size(EEG.data,3);

% Aggiungo nella struttura EEG 3 matrici, contenenti stima del EP, std ed
% ss della stima. Ciascuna matrice ha dimensione (canali x tempo)
N = length(EEG.times); % lunghezza asse dei tempi 
EEG.average.stima = zeros(EEG.nbchan,N);
EEG.average.std = zeros(EEG.nbchan,N);
EEG.average.ss = zeros(EEG.nbchan,N); % sum of squares, per calcolare std

for j=1:EEG.nbchan %per ogni canale
    matrice_tempo_x_epoche = squeeze(EEG.data(j,:,1:n_epochs));
    EEG.average.stima(j,:)= mean(matrice_tempo_x_epoche,2);
    
    for k=1:n_epochs
        EEG.average.ss(j,:) = EEG.average.ss(j,:) + (EEG.data(j,:,k)-EEG.average.stima(j,:)).^2;
    end
EEG.average.std(j,:) = sqrt(EEG.average.ss(j,:) ./ settings.averaging.n_epochs);
end
