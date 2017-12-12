function [ matrice_cricche, N_cicli] = Paris( matrice_cricche,N_cicli )

%Paris Produce l'aumento della lunghezza delle cricche secondo la legge di
%      Paris. Si arresta quando una trabecola fallisce (cond 1 -> sforzo
%      locale > di sforzo critico; cond 2 -> lunghezza cricca > spessore
%      trabecola) o quando una cricca raggiunge meta' dello spessore della
%      trabecola corrispondente. 
%   sigma_medio() riceve: coordinate e spessore trabecola e restituisce lo
%   sforzo medio in direzione dell'asse di carico
%
% Input: matrice_cricche (vedi funz Crea_cricche per definizione)
%        N_cicli numero di cicli da cui parte l'analisi
%
% Output: matrice_cricche aggiornata
%         N_cicli aggiornati
%         coord_trabecola restituisce le coordinate della trabecola per cui
%         si e' interrotto il ciclo
%         stato_trabecola restituisce il tipo di avvenimento per cui si e'
%         interrotto il ciclo (trabecola inattivata o trabecola inattivata
%         a meta')1

global dim_voxel

dK = @(c,dsigma) (pi*c*10^-3)^(1/2) * dsigma*10^3; % funzione che descrive il fattore di intensificazione degli sforzi
C = 0.013; %parametro del materiale
m = 4.5; %parametro del materiale

sigma=zeros(size(matrice_cricche,1));

for i=1:size(matrice_cricche,1)
    sigma(i) = Sforzo_medio(matrice_cricche(i,:),matrice_cricche(i,6)/(2*dim_voxel)); %l'area su cui si calcola lo sforzo medio e' la meta' dello spessore della trabecola
end

while N_cicli<10e6
    
    flag=0;
    
    N_cicli = N_cicli + 1;
    
    for i=1:size(matrice_cricche,1)
        
        if (matrice_cricche(i,7) ~= 2 && matrice_cricche(i,7) ~= 3)
            
            k = dK( matrice_cricche(i,5), 2*sigma(i)); % il Delta_sigma è assunto pari a 2 volte lo sforzo medio
            k_thresold = 0; %parametro locale - variabili a caso
            k1c = 1000; %parametro locale - variabili a caso
            
            if k > k_thresold  && k < k1c 

                matrice_cricche(i,5) = matrice_cricche(i,5) + 10^-3 *C*k^m ; 
                % incrementa lunghezza cricca

                if  (matrice_cricche(i,5) >= matrice_cricche(i,6))
                    % condizione implicita && matrice_cricche(i,7)==1 - se 
                    % la trabecola è già stata modificata deve verificarsi 
                    % la condizone di fallimento.

                    matrice_cricche(i,7) = 2;
                    
                    if N_cicli ~= 1
                        % evita, al primo giro, di far uscire la function
                        % quando alcune cricche hanno lunghezza iniziale 
                        % che supera lo spessore trabecola. Si preferisce
                        % vedere la propagazione delle altre cricche.
                        % nei giri successivi non ha alcun effetto in
                        % quanto N_cicli viene aggiornato.
                   
                        flag=1;
                        
                    end
        
                elseif matrice_cricche(i,5) >= 0.5*matrice_cricche(i,6) ...
                        && matrice_cricche(i,7)==0  
                    % se la lunghezza della cricca raggiunge la metà dello 
                    % spessore minimo della trabecola e non è già stata 
                    % modificata si rielabora la mesh  

                    matrice_cricche(i,7) = 1;
                    
                    if N_cicli ~= 1
                        % evita, al primo giro, di far uscire la function
                        % quando alcune cricche hanno lunghezza iniziale 
                        % che supera  la meta' lo spessore trabecola. 
                        % Si preferisce vedere la propagazione delle altre 
                        % cricche.
                        % Nei giri successivi non ha alcun effetto in
                        % quanto N_cicli viene aggiornato.
                   
                        flag=1;
                        
                    end
                    
                elseif k > k1c
                    % se lo sforzo locale supera lo sforzo critico la trabecola
                    % fallisce immediatamente.
                    
                    matrice_cricche(i,7) = 3;
                    
                    flag = 1;
                    
                end
            end
        end
        
        if flag == 1
            return
        end
        
    end
    
end
end



