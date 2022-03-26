

%Architecture definition

%Number of layers of the de la NN
layers=10;
%architecture of the NN
Qnet=feedforwardnet(layers);
%NN structure
Qnet=train(Qnet,randi([0, layers], [5,100]),randi([0, layers], [96,100]));

%hyperparameters
alpha=0.15;
gamma=0.7;


Pacbinicio=1;
Traoinicio=1;

%Memory size for DQL
tamexp=500;
%Number of experiences for training according to DQL
updatetarget=100;

disp(clock)
tiempoinicial=clock;


%This is a training for 3 days (each day has a different file

%DAY 1
for i=1:144

epsilon= 1-(0.99*(i/144));    %Epsilon variation for training
rng('shuffle')
archivotraficoH2H = textread('/TRAFFIC_FILE_PATH/TRAFFICFILEday1','%s'); %This is a file with traffic intensity for the H2H traffic


traficoH2H(i)=str2double(cell2mat(archivotraficoH2H(i)));
traficoH2H(i)=traficoH2H(i)*4.1581;

    %This if updates the experience buffer unoformly for the 144 experiments
    if i==1
        counterexpin=1;
        memoryexpin=zeros(tamexp,12);
    else
        counterexpin=cxout;
        memoryexpin=mxout;
    end

[averagePerRAO, avPreamStatsPerRAO,Qnet,vectorPacb, vectorTrao, Ps, PsM, PsH, K, EK, KM, EKM, KH, EKH, D, ED, D95, DM, EDM, D95M, DH, EDH, D95H, cxout, mxout] = LTEA_M_H_ACB_DDQL_LIMPIO(1e4.*betarnd(3,4,30000,1), unifrnd(0,10*60*1000,floor(traficoH2H(i)),1),Qnet,epsilon,gamma,alpha,Pacbinicio,Traoinicio,counterexpin,memoryexpin,tamexp,updatetarget);


end

tiempofinal1=clock;
filename="/PATH/RESULTS1.mat";
save(filename);


%DAY 2 
for i=1:144

epsilon= 1-(0.99*(i/144));    
rng('shuffle')
archivotraficoH2H = textread('/PATH/H2HTRAFFICFILEday2.txt','%s');

traficoH2H(i)=str2double(cell2mat(archivotraficoH2H(i)));
traficoH2H(i)=traficoH2H(i)*4.1581;


        counterexpin=cxout;
        memoryexpin=mxout;


[averagePerRAO, avPreamStatsPerRAO,Qnet,vectorPacb, vectorTrao, Ps, PsM, PsH, K, EK, KM, EKM, KH, EKH, D, ED, D95, DM, EDM, D95M, DH, EDH, D95H, cxout, mxout] = LTEA_M_H_ACB_DDQL_TraoPacb_LIMPIO(1e4.*betarnd(3,4,30000,1), unifrnd(0,10*60*1000,floor(traficoH2H(i)),1),Qnet,epsilon,gamma,alpha,Pacbinicio,Traoinicio,counterexpin,memoryexpin,tamexp,updatetarget);



end

tiempofinal2=clock;
filename2="/PATH/RESULTS2.mat";
save(filename2);


%DAY 3

for i=1:144

epsilon= 1-(0.99*(i/144));    
rng('shuffle')
archivotraficoH2H = textread('/PATH/H2HTRAFFICFILEday3.txt','%s');

traficoH2H(i)=str2double(cell2mat(archivotraficoH2H(i)));
traficoH2H(i)=traficoH2H(i)*4.1581;


        counterexpin=cxout;
        memoryexpin=mxout;


[averagePerRAO, avPreamStatsPerRAO,Qnet,vectorPacb, vectorTrao, Ps, PsM, PsH, K, EK, KM, EKM, KH, EKH, D, ED, D95, DM, EDM, D95M, DH, EDH, D95H, cxout, mxout] = LTEA_M_H_ACB_DDQL_TraoPacb_LIMPIO(1e4.*betarnd(3,4,30000,1), unifrnd(0,10*60*1000,floor(traficoH2H(i)),1),Qnet,epsilon,gamma,alpha,Pacbinicio,Traoinicio,counterexpin,memoryexpin,tamexp,updatetarget);



end
% 

tiempofinal3=clock;
filename3="/PATH/RESULTS3.mat";
save(filename3);