
clear
clc

global mesh_iniziale mesh_modificata sforzi incidenze SF dim_voxel dir_carico

%% PRIMO GIRO

load('k_2_n_200.mat'); %carica la mesh elaborata e compressa dal codice precedente
incidenze = MATRICENOSTRA;
tab=readtable('k2n200.dat'); %carica la FEM relativa alla mesh di cui sopra
%%%%%%% la Fem contiene righe in eccesso, si ricorda di ripulire. %%%%%%%
sforzi = table2array(tab); %trasforma la tabella della FEM in matrice
sforzi(:,1) = [];


numero_cricche = 100; %numero cricche da collocare
Cicli_iniziali = 0;

mesh_iniziale = double(matrice_erosa_c); 


%% calcolo parametri macro e richiesta informazioni su input FEM e mesh
dati_ingresso = inputdlg({'Direzione applicazione carico (x=1,y=2,z=3)','spostamento applicato (espresso in voxel)','Modulo elastico materiale - in GPa','Fattore di compressione (2, 3 o 6)'},...
              'Parametri FEM e MESH'); 
dati_ingresso = str2double(dati_ingresso);
%converte cell in double, altrimenti non si puo' usare la sintassi x(4).
                                                    
dim = size(mesh_iniziale,1);
dir_carico = dati_ingresso(1);
dim_voxel=  0.018*dati_ingresso(4); %dimensione del singolo voxel in millimetri
porosita=size(incidenze,1)/dim^3; %frazione volumetrica della mesh
E_mat = dati_ingresso(3); %modulo elastico in GPa
sforzi = sforzi*E_mat;
sigma_tot = sum(sforzi(:,dir_carico)); 
sigma_eq =  sigma_tot /dim^3; %sforzo di comparazione con lo sforzo sperimentale in GPa
epsilon = dati_ingresso(2)/(dim*dim_voxel);
E = [Cicli_iniziali abs(sigma_eq/epsilon)];

%Parametri sperimentali
E0 = 2.199; %modulo elastico espresso in GPa
delta_sigma = -0.005*2.199; 
epsilon_max = 0.01558; %da letteratura - media delle def max
eq_inter = @(N) 0.230 + 1.015*porosita - 87.4*0.005 - 0.015*10^3*E0 + 0.111*log(N,10) + 0.247*epsilon_max; %equazione interpolante da letteratura
%calcolo fattore alfa per ridimensionamento stato degli sforzi
alfa = delta_sigma/sigma_eq;

sforzi = sforzi*alfa;

Rotate; %porta le corrette rotazioni della matrice per allineare l'asse di carico con l'asse x 
Sforzi4D; 
mesh_modificata = mesh_iniziale;
Ricerca_bordi;
matrice_cricche = Crea_cricche(numero_cricche);


%% etichetta la trabecola con li cricche
k=unique(matrice_cricche(:,1));
k=k';
for i=k
    mat(:,:) = mesh_modificata(i,:,:);
    mesh_modificata(i,:,:) = bwlabel(mat);
end

%% calcola lo spessore della trabecola delle cricche e aggiorna matrice_cricche
for i=1:size(matrice_cricche,1)
    
    x = matrice_cricche(i,1);
    y = matrice_cricche(i,2);
    z = matrice_cricche(i,3);
    matrice_cricche(i,6) = dim_voxel*Spessore(matrice_cricche(i,:),mesh_modificata(x,y,z));
end

%% propagazione cricche
[matrice_cricche_modificata,Cicli_finali] = Paris (matrice_cricche,Cicli_iniziali);

%% eliminazione totale o parziale trabecola
for i=1:size(matrice_cricche_modificata,1)
    elimina_cerchio (matrice_cricche_modificata(i,:));
end

%%
Rotate; %ritraspone le matrici in modo da ritornare alla configurazione originale prima di rinviare la mesh alla FEM

%% file inp per giro successivo
[~,~,~,centroidi]=IncidCoord; 
GiroFEM = 1;
par(GiroFEM) = alfa;
Cicli_iniziali=Cicli_finali;
clear alfa Cicli_finali dati_ingresso i k incidenze mat matrice_compressa matrice_erosa_c MATRICENOSTRA mesh_modificata porosita SF sforzi sigma_eq sigma_tot tab x y z
save('giro1.mat');

%% GIRI SUCCESSIVI
load('giro1.mat');
tab=readtable('k2n64.dat'); %carica la FEM relativa alla mesh di cui sopra
sforzi = table2array(tab); %trasforma la tabella della FEM in matrice
sforzi(:,1) = [];

mesh_iniziale = mat; 
mesh_modificata = Ricerca_bordi(mesh_iniziale);
matrice_cricche = matrice_cricche_modificata;
Cicli_iniziali=Cicli_finali;
Applica_cricche(matrice_cricche);


k=unique(matrice_cricche(:,1));
k=k';
for i=k
    mt(:,:) = mesh_modificata(i,:,:);
    mesh_modificata(i,:,:) = bwlabel(mt);
end

for i=1:size(matrice_cricche,1)
    
    x = matrice_cricche(i,1);
    y = matrice_cricche(i,2);
    z = matrice_cricche(i,3);
    matrice_cricche(i,6) = dim_voxel*Spessore(matrice_cricche(i,:),mesh_modificata(x,y,z));
end


[matrice_cricche_modificata,Cicli_finali] = Paris (matrice_cricche,Cicli_iniziali);

for i=1:size(matrice_cricche_modificata,1)
    elimina_cerchio (matrice_cricche_modificata(i,:),dim_voxel);
end
mat=mesh_iniziale;
save('giro2.mat','mat','matrice_cricche_modificata','Cicli_finali','incidenze');

