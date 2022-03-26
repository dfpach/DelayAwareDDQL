function [averagePerRAO, avPreamStatsPerRAO,Qnet,vectorPacb, vectorTrao, Ps, PsM, PsH, K, EK, KM, EKM, KH, EKH, D, ED, D95, DM, EDM, D95M, DH, EDH, D95H, counterexpout, memoryexpout] = LTEA_M_H_ACB_DDQL_TraoPacb_LIMPIO(arrivalsM, arrivalsH,Qnet,epsilon,gamma,alpha,Pacbinicio,Traoinicio,counterexp,memoryexp,tamexp,updatetarget)
%-------------------------------------------------
%MODIFIED SEP 2019. DOUBLE DEEP Q LEARNING IMPLEMENTED INSIDE AN ACCESS
%CONTROL SIMULATOR FOR LTE-A RECEIVING M2M AND H2H TRAFFIC

%INPUT VALUES
%arrivalsM-> ARRIVAL FUNCTION OF M2M USERS
%arrivalsH-> ARRIVAL FUNCTION OF h2h USERS
%Qnet-> NETWORK DEFINED IN BASE_FILE
%epsilon-> pEXPLORATION PROBABILITY
%gamma-> fDISCOUNT FACTOR FOR QL
%alpha-> learning rate FOR QL
%Pacbinicio-> INITIAL PACB VALUE
%Traoinicio-> INITIAL TRAO VALUE
%counterexp-> PART OF THE BUFFER WHERE EXPERIENCE IS SAVED (COUNTER)
%memoryexp-> MEMORY BUFFER
%tamexp-> MEMORY BUFFER SIZE
%updatetarget -> NUMBER OF EXPERIENCES FOR TRAINING



% ===== ACB parameters ========
acb.prob = 0.5; % Probability
acb.time = 4e3; % Time [ms]
%====================================
maxRAOs = 2e4;

RACHConfig = rach(54,Traoinicio,3,20,20,48,2,5,4,5,0.1,8,5); 

typeM = 1;
typeH = 2;
% -----------------------------------
K = zeros(RACHConfig.maxNumPreambleTxAttempts,1); % Vector with the distribution
% of preamble transmissions
KM = zeros(RACHConfig.maxNumPreambleTxAttempts,1);
KH = zeros(RACHConfig.maxNumPreambleTxAttempts,1);
D = zeros(maxRAOs*5,1); % Vector with the distribution of access delay [ms]
DM = zeros(maxRAOs*5,1);
DH = zeros(maxRAOs*5,1);
ueArrivals = [arrivalsM;arrivalsH];
[totalUEsM, ~] = size(arrivalsM);
[totalUEsH, ~] = size(arrivalsH);
[totalUEs, numSimulations] = size(ueArrivals);
preambleDetectionProbability = 1-1./(exp(1:RACHConfig.maxNumPreambleTxAttempts));
totalSuccessfulUEs = 0;
totalSuccessfulUEsM = 0;
totalSuccessfulUEsH = 0;
totalFailedUEsH = 0;
statsPerRAO = zeros(maxRAOs,5,numSimulations); % Matrix with the:
% [1 FirstPreamTx, 2 Total Access attempts, 3 Collisions, 4 Successfully
% decoded preambles, 5 successful accesses per RAO]
preambleStatsPerRAO = zeros(maxRAOs,3,numSimulations); %Matrix with the:
% [1 Successful preambles 2 Not used preambles 3 Collided preambles]
successfulUEs =  zeros(numSimulations,1);
successfulUEsM = zeros(numSimulations,1);
successfulUEsH = zeros(numSimulations,1);
failedUEsM = zeros(numSimulations,1);
failedUEsH = zeros(numSimulations,1);

%====================================
% Definition of parameters for Q-learning

PreambleTransM=[0:1:29]; %MAXIMUM VALUE IN THIS CASE IS 29. VALUES HIGHER TO 29 BECOME 29 IN THIS EXAMPLE
Pacb=[0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.4, 0.5, 0.6, 0.7, 0.75, 0.8, 0.85, 0.9, 0.95, 1];
PreambleTransCV=[0:0.2:0.8];% VALUES ARE APROXIMATED TO a 0, 0.2, 0.4 0.6 y 0.8
DeltaNpsref=[1:1:3];%1 GROWS,2 REDUCES, 3 SAME : 3 STATES
Trao=[1, 2, 3, 5, 10, 20];
%El número de elementos de este arreglo hace referencia a cada uno de los
%RAOs que se pueden activaren un periodo de TSIB2=80ms. Máximo para
%Trao=1, serán 80 RAOs. Por defecto empiezan en -1. Si hay menos RAOs los
%valores no usados quedarán como -1.
ReceivedPreambles=-1*ones(1,80);

%Numero de estados
Nstates=length(PreambleTransM)*length(Pacb)*length(PreambleTransCV)*length(DeltaNpsref)*length(Trao);


%The set of actions A, allow to change Pacb.
action= [1:1:(length(Pacb)*length(Trao))];

% secondary  Q matrix: Esta es la que se usa para hacer double QL
SQnet=Qnet;

%todos estos valores se usan para tener referencias entre cada tiempo N
Npsref=0;
Npscur=0;
NpsMref=0;
NpsMcur=0;
NpsCVref=0;
NpsCVcur=0;
DeltaNpsref=0;
DeltaNpscur=0;
actioncur=94;
actionref=94;

[Pacbcur,Traocur]=convierteaccionavars(actioncur); %Esta  funcion convierte la accion en valores de PAcb y Trao

Pacbref=Pacbcur;
Traoref=Traocur;
ReceivedPreamblescur=-1*ones(1,80);
ReceivedPreamblesref=-1*ones(1,80);

TSIB=floor(80/Traocur);
Transpreamblehistory=zeros(TSIB,1);  %Este vector guarda todos los valors de Trao para cada periodo

numSuccessfullyDecodedPreambles=0;
vectorPacb=ones(maxRAOs,1); %Este vector guarda los valores usados de Pacb
vectorTrao=zeros(maxRAOs,1); %Este vector guarda los valores de Trao
RAOlastdecision=0;



%====================================


for simulation = 1:numSimulations

    arrivalTime = ueArrivals(:,simulation);
    arrivalTime = reshape(arrivalTime,totalUEs,1);
    UEs = [zeros(totalUEs,1),arrivalTime,zeros(totalUEs,4)]; % UEs matrix with:
    %[1 ArrivalTime, 2 AccessTime, 3 #PreambleTransmissions, 4 SelectedPreamble
    % 5 AC 6 Type]
    UEs(1:totalUEsM,6) = typeM; % for identifying M2M UEs
    UEs(totalUEsM+1:totalUEs,6) = typeH; % for identifying H2H UEs
    
    simulationTime = 0;
    RAO = 0;
    while(successfulUEsM(simulation)+failedUEsM(simulation)<totalUEsM && RAO<maxRAOs) % For each RAO do:
        RAO = RAO+1;
        simulationTime = simulationTime + RACHConfig.raoPeriodicity;
        accessesInRAO = find(UEs(:,2)<=simulationTime); % Find the accessing UEs
        
        %=================================================================
        % Here starts the section for DDQL: Part 1
        
         
        
        if floor(((RAO-RAOlastdecision)-1)/TSIB)==(((RAO-RAOlastdecision)-1)/TSIB) %This conditions says that in this RAO a SIB is sent
           
            %A decision must be made about the PACB and Trao for this cycle
            
            actionvar=rand; 
            
            if actionvar<=epsilon %If this condition is fulfilled then the next action is random
                    
                 actioncur=randi([1 length(action)],1,1);     
                 
            else %Otherwise  the next action is the one that maximizes Q (explorations vs exploitation)

                %The system assigns to actioncur the one that maximizes the
                %value of the NN. i.e. Qnet
                [varinutil actioncur]=max(Qnet([NpsMcur;NpsCVcur;DeltaNpscur;Pacbcur;Traocur]));
               
            end
            
            %Now we update Pacb based on actioncur
                actionref=actioncur; %updates actionref (action of the previous period)
                Pacbref=Pacbcur; %se actualiza porque hace parte de la accion
                Traoref=Traocur; %se actualiza porque hace parte de la accion
                
                %actualizacion de Pacbcur y Traocur
                [Pacbcur,Traocur]=convierteaccionavars(actioncur);
            
                acb.prob=Pacbcur;% updates a var from the simulator
                RACHConfig.raoPeriodicity=Traocur;% updates a var from the simulator
                TSIB=floor(80/Traocur); %updates de period ehwn the SIB must be sent
                Transpreamblehistory=zeros(TSIB,1);
                RAOlastdecision=RAO-1;
                
                %Updates ReceivedPreamblesref
                ReceivedPreamblesref=ReceivedPreamblescur; 
                                 
        else %It is a RAO w/o SIB
            % PACB does not change i.e. no decisions are made, RL does not interfere          
        end

        vectorPacb(RAO)=acb.prob; %update value
        vectorTrao(RAO)=RACHConfig.raoPeriodicity; %update value
        %=================================================================
         
        %THIS PART WAS NOT MODIFIED FOR RL
        
        if(accessesInRAO)
            newArrivals = find(UEs(accessesInRAO,1)==0); % Find the new arrivals
            %             statsPerRAO(RAO,1,simulation) = statsPerRAO(RAO,1,simulation) + ...
            %                 length(newArrivals);
            UEs(accessesInRAO(newArrivals),1) = simulationTime;
            %             % ============= Access Class Barring ===============
            withoutACB = find(UEs(accessesInRAO,3)==0); % Find the UEs subjecto
            % to the ACB scheme
            if(withoutACB)
                UEs(accessesInRAO(withoutACB),2) = simulationTime +...
                    (rand(size(withoutACB))>acb.prob).*...
                    (0.7+0.6.*rand(size(withoutACB))).*acb.time;
            end
            %             statsPerRAO(RAO,6,simulation) = statsPerRAO(RAO,1,simulation) + ...
            %                 length(withoutACB); %arrivals after ACB
            %             % ---------------------------------------------------
            accessesInRAO = find(UEs(:,2)<=simulationTime); % Find the accessing UEs
            firstPreamTx = (UEs(:,2)<=simulationTime & UEs(:,3)==0);
            statsPerRAO(RAO,1,simulation) = statsPerRAO(RAO,1,simulation) + ...
                nnz(firstPreamTx);
            statsPerRAO(RAO,2,simulation) = statsPerRAO(RAO,2,simulation) + ...
                length(accessesInRAO);
            UEs(accessesInRAO,4) = unidrnd(RACHConfig.availablePreambles, ...
                size(accessesInRAO)); % The UEs select a preamble randomly
            UEs(accessesInRAO,3) = UEs(accessesInRAO,3)+1;  % The UEs send the
            % preamble and increase the preamble transmission counter
            selectedPreambles = zeros(size(accessesInRAO));
            for i = 1:length(accessesInRAO)   % Identify the preambles transmitted by only one UE
                selectedPreambles(i) = (sum(UEs(accessesInRAO,4)==UEs(accessesInRAO(i),4)));
            end
            successfulPreambles = (selectedPreambles==1);
            preambleStatsPerRAO(RAO,1,simulation) = sum(successfulPreambles);
            preambleStatsPerRAO(RAO,2,simulation) = RACHConfig.availablePreambles - ...
                length(unique(UEs(accessesInRAO,4)));
            preambleStatsPerRAO(RAO,3,simulation) = RACHConfig.availablePreambles - ...
                preambleStatsPerRAO(RAO,1,simulation) - preambleStatsPerRAO(RAO,2,simulation);
            statsPerRAO(RAO,3,simulation) = statsPerRAO(RAO,3,simulation) + sum(1-successfulPreambles);
            successfullyDecodedPreambles = successfulPreambles.*(rand(size(successfulPreambles))<preambleDetectionProbability(UEs(accessesInRAO,3))');	%Decode the preambles
            numSuccessfullyDecodedPreambles = sum(successfullyDecodedPreambles);
            statsPerRAO(RAO,4,simulation) = statsPerRAO(RAO,4,simulation) + numSuccessfullyDecodedPreambles;
            waitingUG = accessesInRAO(successfullyDecodedPreambles==1); % Find UEs that sent a correctly decoded preamble
            j = unidrnd(numSuccessfullyDecodedPreambles)-1;
            %             failedUEsM = 0;
            for i = 1:min(numSuccessfullyDecodedPreambles,RACHConfig.raoPeriodicity*RACHConfig.uplinkGrantsPerSubframe)
                delayUG = floor((i-1)/RACHConfig.uplinkGrantsPerSubframe)+1; % Assign uplink grants
                HARQmsg3 = 0;
                HARQmsg4 = 0;
                Tmsg4 = 0;
                while(rand()<RACHConfig.harqReTxProbMsg3Msg4 && HARQmsg3<RACHConfig.maxNumMsg3Msg4TxAttempts)	% Msg 3 transmission
                    HARQmsg3 = HARQmsg3+1;
                end
                while(rand()<RACHConfig.harqReTxProbMsg3Msg4 && HARQmsg3<RACHConfig.maxNumMsg3Msg4TxAttempts ...
                        && HARQmsg4<RACHConfig.maxNumMsg3Msg4TxAttempts) % Msg4 transmission
                    HARQmsg4 = HARQmsg4+1;
                end
                contentionResolutionDelay = HARQmsg3*RACHConfig.rttMsg3 +...
                    HARQmsg4*RACHConfig.rttMsg4 + RACHConfig.connectionRequestProcessingDelay...
                    + 2 + Tmsg4;	% Obtain the delay of transmitting Msg3 and Msg4
                if(HARQmsg3<RACHConfig.maxNumMsg3Msg4TxAttempts && HARQmsg4<RACHConfig.maxNumMsg3Msg4TxAttempts...
                        && contentionResolutionDelay<=RACHConfig.contentionResolutionTimer)	% Sucessful access
                    delay = simulationTime + 1 + RACHConfig.preambleProcessingDelay...
                        + delayUG + RACHConfig.rarProcessingDelay + contentionResolutionDelay...
                        - UEs(waitingUG(j+1),1);	% Calculate the overall delay [ms]
                    D(delay) = D(delay)+1;
                    UEs(waitingUG(j+1),2) = 0;
                    successfulUEs(simulation) = successfulUEs(simulation)+1;
                    if(UEs(waitingUG(j+1),6) == typeM)
                        successfulUEsM(simulation) = successfulUEsM(simulation)+1;
                        DM(delay) = DM(delay)+1;
                        KM(UEs(waitingUG(j+1),3)) = KM(UEs(waitingUG(j+1),3))+1;
                    elseif(UEs(waitingUG(j+1),6) == typeH)
                        successfulUEsH(simulation) = successfulUEsH(simulation)+1;
                        DH(delay) = DH(delay)+1;
                        KH(UEs(waitingUG(j+1),3)) = KH(UEs(waitingUG(j+1),3))+1;
                    end
                    statsPerRAO(RAO,5,simulation) = statsPerRAO(RAO,5,simulation)+1;
                    K(UEs(waitingUG(j+1),3)) = K(UEs(waitingUG(j+1),3))+1;
                else
                    UEs(waitingUG(j+1),2) = simulationTime + RACHConfig.backoffIndicator*rand()...
                        + 1 + RACHConfig.preambleProcessingDelay + delayUG + RACHConfig.rarProcessingDelay...
                        + contentionResolutionDelay; % Contention resolution failed, backoff
                end
                j = j+1;
                j = mod(j,numSuccessfullyDecodedPreambles);
            end
            successfulUEAccesses = UEs(:,2)==0; % Find the successful UEs
            %             successfulUEAccessesH = (UEs(:,2)==0 && UEs(:,2)==1);
            %             successfulUEAccessesM = (UEs(:,2)==0 && UEs(:,2)==2);
            UEs(successfulUEAccesses,:) = []; % Erase the successful UEs from the matrix of UEs
            terminateRAP = UEs(:,3) == RACHConfig.maxNumPreambleTxAttempts; % Find the UEs that failed in their last preamble transmission
            terminateRAPM = (UEs(:,3) == RACHConfig.maxNumPreambleTxAttempts)...
                & (UEs(:,6) == typeM);
            terminateRAPH = (UEs(:,3) == RACHConfig.maxNumPreambleTxAttempts)...
                & (UEs(:,6) == typeH);
            failedUEsM(simulation) = failedUEsM(simulation) + nnz(terminateRAPM);
            failedUEsH(simulation) = failedUEsH(simulation) + nnz(terminateRAPH);
            UEs(terminateRAP,:) = []; % Erase the UEs that failed in all their preamble transmissions
            backoffUEs = UEs(:,2)<=simulationTime;
            if(nnz(backoffUEs)>0) % The UEs that failed and that still can perform preamble transmissions perform backof
                UEs(backoffUEs,2) = simulationTime + 1 + RACHConfig.preambleProcessingDelay...
                    + RACHConfig.raoPeriodicity + RACHConfig.backoffIndicator*rand(nnz(backoffUEs),1);
            end
        end
        
        %=================================================================
        % This section was made for RL: Part 2
        
        %First we save the info of preambles sent
        
        if mod((RAO-RAOlastdecision),TSIB)<=0.001   %This is to avoid using == for an issue detected
            Transpreamblehistory(TSIB)=numSuccessfullyDecodedPreambles;
        else
            Transpreamblehistory(mod((RAO-RAOlastdecision),TSIB))=numSuccessfullyDecodedPreambles;
        end
        
    
         if floor(((RAO-RAOlastdecision))/TSIB)==(((RAO-RAOlastdecision))/TSIB) % entra en el RAO antes de entrar al SIB y despues de los accesos
             

                    % we have to set the current state (Pacbcur and Traocur
                    % are already set)
                    
                    NpsMref=NpsMcur; %update
                    NpsCVref=NpsCVcur; %update
                    DeltaNpsref=DeltaNpscur; %update
                    
                    %Assign transpreamblehistory to state vector
        
                    ReceivedPreamblescur=-1*ones(1,80);
                    [filtph coltph]=size(Transpreamblehistory);
                    for i=1:filtph
                        ReceivedPreamblescur(1,i)=Transpreamblehistory(i,1);
                    end
                    
                    %calcular las variables de estado
                    cuentaespacios=0; 
                    sumamedia=0;
                    for i=1:80
                        if ReceivedPreamblescur(1,i)~=-1
                        cuentaespacios=cuentaespacios+1;
                        sumamedia=sumamedia+ReceivedPreamblescur(1,i);
                        else
                        end                      
                    end
                    
                    NpsMcur=sumamedia/cuentaespacios;
                    
                    sumavarianza=0;
                    for i=1:cuentaespacios
                        sumavarianza=sumavarianza+(ReceivedPreamblescur(1,i)-NpsMcur)^2;
                    end
                    
                    NpsCVcur=sumavarianza/cuentaespacios;
                    
                    NpsMcur=round(NpsMcur);
                    
                    if (NpsCVcur>=0) && (NpsCVcur<0.2)
                        NpsCVcur=0;
                    elseif (NpsCVcur>=0.2) && (NpsCVcur<0.4)
                        NpsCVcur=0.2;
                    elseif (NpsCVcur>=0.4) && (NpsCVcur<0.6)
                        NpsCVcur=0.4;
                    elseif (NpsCVcur>=0.6) && (NpsCVcur<0.8)
                        NpsCVcur=0.6;   
                    elseif (NpsCVcur>=0.8)
                        NpsCVcur=1;       
                    end  
                    
                    DifNps=NpsMcur-NpsMref;
                    
                    if DifNps>0
                        DeltaNpscur=1;
                    elseif DifNps==0
                        DeltaNpscur=3;
                    else 
                        DeltaNpscur=2;
                    end
                    
                    
                    
                    
                    % Now we must calculate the reward of the current state
                    % according to the action taken
                    reward = calculaterewardexample(NpsMcur,NpsCVcur,DeltaNpscur,Pacbcur,Traocur);
                                   
                    
                    
                    %Now we must fill the experience memory
                    
                    memoryexp(counterexp,1)=NpsMref;
                    memoryexp(counterexp,2)=NpsCVref;
                    memoryexp(counterexp,3)=DeltaNpsref;
                    memoryexp(counterexp,4)=Pacbref;
                    memoryexp(counterexp,5)=Traoref;
                                                     
                    %Ahora se llenan los estados de cur
                    
                    memoryexp(counterexp,6)=NpsMcur;
                    memoryexp(counterexp,7)=NpsCVcur;
                    memoryexp(counterexp,8)=DeltaNpscur;
                    memoryexp(counterexp,9)=Pacbcur;
                    memoryexp(counterexp,10)=Traocur;                    
                    
                    %Ahora se llenan con reward y actioncur
                    memoryexp(counterexp,11)=reward;
                    memoryexp(counterexp,12)=actioncur;
                    
                    
                    counterexp=counterexp+1;
                    
                    
         else
         end
         
         if counterexp-1==tamexp %el buffer de memoria se llenó
            counterexp=1; % lo resetea
            
            %genera una nueva matriz con las experiencias ordenadas de
            %manera aleatoria
                
            random_mem = memoryexp(randperm(size(memoryexp, 1)), :);
            
            %resetea la matriz memoryexp
            
            [sizememfil sizememcol] = size(memoryexp);
            
            for filamem=1:sizememfil
                for colmem=1:sizememcol
                    memoryexp(filamem,colmem)=0;
                end
            end
                
            
            
         
            %se entrena la NN con un numero de  updatetarget datos
            %esto se hace tantas veces como updatetarget quepa en la
            %memoria
                
                for nentrena=1:(tamexp/updatetarget)
                
                    %calcula los valores de target para cada uno de los
                    %valores de memoria con los cuales va a entrenar
                    
                    for calculatarget=((nentrena-1)*updatetarget)+1:nentrena*updatetarget
                    
                         %1)Encontrar la accion a' que maximiza la matriz online en s' (Qnet)
                
                        [varinutil actionmaxsprima]=max(Qnet([random_mem(calculatarget,6:10)]'));
                
                        %2)Evaluar la accion a' en la matriz de ref SQnet en estado
                        %s'
                
                        Qevaluado=SQnet([random_mem(calculatarget,6:10)]');
                
                        %3) Calcular el target = reward + gamma Q(s',a')
                
                        target=random_mem(calculatarget,11)+gamma*Qevaluado(actionmaxsprima);
                           
                        %hay que generar el vector de salida deseado tomando
                        %target
                        vectorsalida=Qnet([random_mem(calculatarget,1:5)]');
                        %se reemplaza la posicion de a, es decir de Q(s,a),
                        %la accion original, es decir actioncur
                        vectorsalida(random_mem(calculatarget,12))=target;
                                            
                        %Se añade en la memoria los resultados de Q para
                        %cada accion
                        for sizemem=1:96
                           random_mem(calculatarget,sizemem+12)=vectorsalida(sizemem); 
                        end
                 
                    
                    end
                                        
                    %entrenar la red con updatetarget muestras
                    
                    Qnet = train (Qnet, random_mem(((nentrena-1)*updatetarget)+1:nentrena*updatetarget,1:5)',random_mem(((nentrena-1)*updatetarget)+1:nentrena*updatetarget,13:108)');
  
                    %despues de entrenar se actualiza SQnet
                    SQnet=Qnet;
                
                
                
                end
         
         else
         end         
                
        
        
        %=================================================================
        
        
        
    end
    totalSuccessfulUEs = totalSuccessfulUEs + successfulUEs(simulation);
    totalSuccessfulUEsM = totalSuccessfulUEsM + successfulUEsM(simulation);
    totalSuccessfulUEsH = totalSuccessfulUEsH + successfulUEsH(simulation);
    totalFailedUEsH = totalFailedUEsH + failedUEsH(simulation);
end

counterexpout=counterexp;
memoryexpout=memoryexp;
Pacbfinal=Pacbcur;
Npfinal=Npscur;

averagePerRAO = mean(statsPerRAO,3);% Matrix with the mean of:
% [1 Arrivals, 2 Total Access attempts, 3 Collisions, 4 Successfully
% decoded preambles, 5 successful accesses per RAO]

avPreamStatsPerRAO = mean(preambleStatsPerRAO,3); %Matrix with the:
% [1 Successful reambles 2 Not used preambles 3 Collided preambles]

%% ---------- Recalculate TotalUEs and totalUEsH2H
totalUEsH = totalSuccessfulUEsH + totalFailedUEsH; % this because we stop the simulation when the M2M traffic finishes
totalUEs = totalUEsM*numSimulations + totalUEsH; %total number of UEs in the entire simulation

Ps = totalSuccessfulUEs/(totalUEs);  % Calculate the access success probability
disp('Access success probability:')
disp(Ps)

PsM = totalSuccessfulUEsM/(totalUEsM*numSimulations);  % Calculate the access success probability
disp('Access success probability M2M:')
disp(PsM)

PsH = totalSuccessfulUEsH/(totalUEsH);  % Calculate the access success probability
disp('Access success probability H2H:')
disp(PsH)

% =========================================================================

K = K./(sum(successfulUEs));  % Calculate the pmf of preamble transmissions for the successful accesses
EK = (1:RACHConfig.maxNumPreambleTxAttempts)*K;   % Calculate the average number of preamble transmissions for the successful accesses
disp('Average number of preamble transmissions:')
disp(EK)
xiK = 1:0.01:RACHConfig.maxNumPreambleTxAttempts;
Kq = interp1(1:RACHConfig.maxNumPreambleTxAttempts,cumsum(K),xiK);
% ---------------------- Percentiles ------------------
indK95 = find(Kq<=0.95, 1, 'last' ); if(isempty(indK95)), K95 = 0; else, K95 = xiK(indK95); end
indK50 = find(Kq<=0.50, 1, 'last' ); if(isempty(indK50)), K50 = 0; else, K50 = xiK(indK50); end
indK10 = find(Kq<=0.10, 1, 'last' ); if(isempty(indK10)), K10 = 0; else, K10 = xiK(indK10); end

KM = KM./(sum(successfulUEsM));  % Calculate the pmf of preamble transmissions for the successful accesses
EKM = (1:RACHConfig.maxNumPreambleTxAttempts)*KM;   % Calculate the average number of preamble transmissions for the successful accesses
disp('Average number of preamble transmissions M2M:')
disp(EKM)
xiKM = 1:0.01:RACHConfig.maxNumPreambleTxAttempts;
KqM = interp1(1:RACHConfig.maxNumPreambleTxAttempts,cumsum(KM),xiKM);
% ---------------------- Percentiles ------------------
indK95M = find(KqM<=0.95, 1, 'last' ); if(isempty(indK95M)), K95M = 0; else, K95M = xiKM(indK95M); end
indK50M = find(KqM<=0.50, 1, 'last' ); if(isempty(indK50M)), K50M = 0; else, K50M = xiKM(indK50M); end
indK10M = find(KqM<=0.10, 1, 'last' ); if(isempty(indK10M)), K10M = 0; else, K10M = xiKM(indK10M); end

KH = KH./(sum(successfulUEsH));  % Calculate the pmf of preamble transmissions for the successful accesses
EKH = (1:RACHConfig.maxNumPreambleTxAttempts)*KH;   % Calculate the average number of preamble transmissions for the successful accesses
disp('Average number of preamble transmissions H2H:')
disp(EKH)
xiKH = 1:0.01:RACHConfig.maxNumPreambleTxAttempts;
KqH = interp1(1:RACHConfig.maxNumPreambleTxAttempts,cumsum(KH),xiKH);
% ---------------------- Percentiles ------------------
indK95H = find(KqH<=0.95, 1, 'last' ); if(isempty(indK95H)), K95H = 0; else, K95H = xiKH(indK95H); end
indK50H = find(KqH<=0.50, 1, 'last' ); if(isempty(indK50H)), K50H = 0; else, K50H = xiKH(indK50H); end
indK10H = find(KqH<=0.10, 1, 'last' ); if(isempty(indK10H)), K10H = 0; else, K10H = xiKH(indK10H); end
% =========================================================================

D = D./(sum(successfulUEs));  % Calculate the pmf of access delay
Dmax = find(D>0,1,'last');
D(Dmax+1:end) = [];
ED = (1:length(D))*D;   % Calculate the average access delay
disp('Average access delay [ms]:')
disp(ED)
xiD = 1:0.1:Dmax;
Dq = interp1(1:Dmax,cumsum(D),xiD);
% ---------------------- Percentiles ------------------
indD95 = find(Dq<=0.95, 1, 'last' ); if(isempty(indD95)), D95 = 0; else, D95 = xiD(indD95); end
indD50 = find(Dq<=0.50, 1, 'last' ); if(isempty(indD50)), D50 = 0; else, D50 = xiD(indD50); end
indD10 = find(Dq<=0.10, 1, 'last' ); if(isempty(indD10)), D10 = 0; else, D10 = xiD(indD10); end

DM = DM./(sum(successfulUEsM));  % Calculate the pmf of access delay
DmaxM = find(DM>0,1,'last');
DM(DmaxM+1:end) = [];
EDM = (1:length(DM))*DM;   % Calculate the average access delay
disp('Average access delay M2M [ms]:')
disp(EDM)
xiDM = 1:0.1:DmaxM;
DqM = interp1(1:DmaxM,cumsum(DM),xiDM);
% ---------------------- Percentiles ------------------
indD95M = find(DqM<=0.95, 1, 'last' ); if(isempty(indD95M)), D95M = 0; else, D95M = xiDM(indD95M); end
indD50M = find(DqM<=0.50, 1, 'last' ); if(isempty(indD50M)), D50M = 0; else, D50M = xiDM(indD50M); end
indD10M = find(DqM<=0.10, 1, 'last' ); if(isempty(indD10M)), D10M = 0; else, D10M = xiDM(indD10M); end

DH = DH./(sum(successfulUEsH));  % Calculate the pmf of access delay
DmaxH = find(DH>0,1,'last');
DH(DmaxH+1:end) = [];
EDH = (1:length(DH))*DH;   % Calculate the average access delay
disp('Average access delay H2H [ms]:')
disp(EDH)
xiDH = 1:0.1:DmaxH;
DqH = interp1(1:DmaxH,cumsum(DH),xiDH);
% ---------------------- Percentiles ------------------
indD95H = find(DqH<=0.95, 1, 'last' ); if(isempty(indD95H)), D95H = 0; else, D95H = xiDH(indD95H); end
indD50H = find(DqH<=0.50, 1, 'last' ); if(isempty(indD50H)), D50H = 0; else, D50H = xiDH(indD50H); end
indD10H = find(DqH<=0.10, 1, 'last' ); if(isempty(indD10H)), D10H = 0; else, D10H = xiDH(indD10H); end

% filename = strcat('nov16_5000_',num2str(period),'_ltea_acb_05_4.mat');
% % 
% save(filename)
end
