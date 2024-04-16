function EEG = bayesian_average_EEG(EEG,settings,idx_canali)
% function EEG = bayesian_average_EEG(EEG,settings)
%
% Funzione che aggiunge alla struttura EEG di EEGLAB una matrice che contiene
% le average delle epoche per ciascun canale, calcolata con approccio bayesiano.

n_epochs = size(EEG.data,3);
    
idx_fine_prestimolo = int16((-EEG.Ts+settings.preprocessing.epoching.timeBefore)/EEG.Ts +1);
idx_stimolo = int16((0+settings.preprocessing.epoching.timeBefore)/EEG.Ts +1);

EEG.bayes.time = EEG.times(idx_stimolo:end);
N = length(EEG.bayes.time); % lunghezza asse dei tempi 
EEG.bayes.stima = zeros(EEG.nbchan,N); % matrice delle stime bayesiane del SEP per ogni canale (canale x tempo)
EEG.bayes.std = zeros(EEG.nbchan,N); % matrice delle dev.std delle stime

m = settings.bayes.m;
if m<0 % controllo su m
    error('m has to be >=0')
end

% Costruzione di F
if m==0
    F=eye(N);
else
    %costuzione di delta
    r = [1, zeros(1,N-1)];
    c = [1, -1, zeros(1,N-2)];
    delta = toeplitz(c,r);
    F=delta^m;
end
F_1 = inv(F);

if nargin==3
    canali_interessanti=idx_canali;
else
    canali_interessanti=1:EEG.nbchan;
end

for idxCh=canali_interessanti
    % *********************************** Calcolo stima SEP ******************************
    disp(['Bayes, canale ', num2str(idxCh),'/',num2str(EEG.nbchan),' ...'])
    
    % vettori utili per la media pesata delle stime single-trial
    sommapesata = zeros(1,N);
    pesototale = 0;
    
    % matrice (trial x tempo) che in ogni riga contiene la stima single-trial della k-esima epoca
    uhat = zeros(EEG.trials,N); 
    
    % vettore colonna che in ogni riga contiene il peso della stima single-trial del k-esimo trial
    peso = zeros(EEG.trials,1); 
    
    for k=1:n_epochs % per ogni epoca
        disp(['   Epoca: ', num2str(k)])
        
        % Riempio le righe di uhat e peso
        [uhat(k,:),peso(k)] = fastBayesianConsistency(EEG.data(idxCh,idx_stimolo:end,k),EEG.data(idxCh,1:idx_fine_prestimolo,k),settings,F_1); 
        
        pesototale = pesototale+peso(k);
        sommapesata = sommapesata + peso(k)*uhat(k,:);

    end
    
    % SEP stimato per il idxCh-esimo canale 
    EEG.bayes.stima(idxCh,:) = sommapesata/pesototale;
    
    
    % *********************************** Calcolo std stima  ******************************
    % vettori utili per calcolare la std delle stime
    sommapesata = zeros(1,N);
    pesototale = 0;
    
    % Calcolo standard deviation delle stime 
    for k=1:n_epochs % per ogni epoca
        sommapesata = sommapesata + peso(k)*(EEG.data(idxCh,idx_stimolo:end,k)-EEG.bayes.stima(idxCh,:)).^2;
        pesototale = pesototale+ peso(k);
    end
    EEG.bayes.std(idxCh,:) = sqrt(sommapesata/pesototale);
end