function [uhat,peso]=fastBayesianConsistency(y_post,y_pre,settings,F_1)
% [uhat,peso] = bayesian(y_post,y_pre,m)
%
% Calcola il potenziale evocato e il peso da utilizzare nella media pesata
% usando y_pre per costruire un modello del rumore EEG, e ipotizzando il PE
% come rumore bianco integrato m volte. Utilizza il criterio di consistenza
% per calcolare il gamma ottimo. uhat avrà media nulla. Questa funzione
% sfrutta la diagonalizzazione delle matrici per rendere più veloce la
% funzione bayesianConsistency

disp('      Ricerca modello AR per EEG ...')
itergamma = 0;
n = length(y_post);

y_post = y_post-mean(y_post);
y_pre = y_pre-mean(y_pre);

p=settings.bayes.ordiniAR;
AIC = zeros(1,length(p));
for k=p
    modello = ar(y_pre,k,'yw');
    AIC(k-settings.bayes.ordiniAR(1)+1) = modello.Report.Fit.AIC;
end
[~, idx_min] = min(AIC);
p_scelto = p(idx_min);
modello = ar(y_pre,p_scelto,'yw');
a = modello.A;
sigma2 = modello.noisevariance;

% disp(['Ordine scelto p:',num2str(p_scelto)])

r = [1, zeros(1,n-1)];
c = [a, zeros(1,n-p_scelto-1)];
A = toeplitz(c,r);

disp('      Ricerca gamma ottimo ...')

B = inv(A'*A);
sqrtB = sqrtm(B);
sqrt_B = inv(sqrtB);

H = sqrt_B * F_1;
[U,D,V] = svd(H);
xi = U'*sqrt_B*y_post';
d = diag(D);

gammamax= settings.bayes.gamma.max;
gammamin= settings.bayes.gamma.min;


while (gammamax-gammamin > 2*settings.bayes.gamma.tol)
    gamma = 10^((log10(gammamin)+log10(gammamax))/2);
    etahat = (d.*xi)./((d.^2)+gamma);
    
    wrss = sum( ( (gamma.*xi) ./ ((d.^2)+gamma)  ).^2); %somma pesata dei quadrati dei residui
    
    q = sum( (d.^2) ./ ((d.^2)+gamma) );

    if wrss<sigma2*(n-q)
        gammamin=gamma;
    else
        gammamax=gamma;
    end
    itergamma=itergamma+1;
    
    if mod(itergamma,50)==0
        disp(['Iterazione: ' num2str(itergamma)])
    end
end
gamma = 10^((log10(gammamin)+log10(gammamax))/2);

disp(['      ',num2str(wrss),' ',num2str(sigma2*(n-q))]);
% disp(['Gamma ottimo:',num2str(gamma)]);

disp('      Calcolo stima e peso...');

% calcolo uhat
C = F_1*V;
uhat = C*etahat;
uhat = uhat';

% diagonale della matrice di covarianza dell'errore di stima in nuove coordinate
W = sigma2./((d.^2)+gamma);

% varianza dell'errore di stima
var_err = zeros(1,n);
for k=1:n
   var_err(k)=sum(W'.*(C(k,:).^2));
end

% energia attesa del vettore errore di stima
expener_err = sum(var_err);

% peso
peso = 1/expener_err;

