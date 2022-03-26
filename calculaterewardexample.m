function reward = calculaterewardexample(NpsMcur,NpsCVcur,DeltaNpscur,Pacbcur,Traocur)

%COST FUNCTION IMPLEMENTATION: CHECK THE PAPER FOR THE COST FUNCTION USED
%IN THE EXPERIMENTS

PacbH=0.7;
PacbM=0.5;
PacbB=0.3;

TraoH=10;
TraoM=3;

NH=10;
NM=7;
NB=3;



reward=0;

if Pacbcur==1 && Traocur>=TraoH

    if NpsMcur==0 && DeltaNpscur==3 && NpsCVcur==0
        reward=reward+20;
    else
        reward=reward-100000;
    end

elseif Pacbcur==1 && Traocur<TraoH && Traocur>=TraoM
    if NpsMcur<=NB
                
        if NpsCVcur<0.4
            if DeltaNpscur==1
                reward=reward+20;
            elseif DeltaNpscur==3
                reward=reward+80;
            else
                reward=reward+80;
            end
        else
            if DeltaNpscur==1
                reward=reward+20;
            elseif DeltaNpscur==3
                reward=reward+40;
            else
                reward=reward+40;
            end            
        end
        
    elseif NpsMcur<NM
        
        
        if NpsCVcur<0.4
            if DeltaNpscur==1
                reward=reward+20;
            elseif DeltaNpscur==3
                reward=reward+60;
            else
                reward=reward+60;
            end                        
        else
            if DeltaNpscur==1
                reward=reward+0;
            elseif DeltaNpscur==3
                reward=reward+20;
            else
                reward=reward+20;
            end             
        end
    elseif NpsMcur<=NH
        
        
        if NpsCVcur<0.2
            if DeltaNpscur==1
                reward=reward+0;
            elseif DeltaNpscur==3
                reward=reward+0;
            else
                reward=reward+20;
            end
        else
            if DeltaNpscur==1
                reward=reward+0;
            elseif DeltaNpscur==3
                reward=reward+0;
            else
                reward=reward+0;
            end            
        end
    else
        
        
        if NpsCVcur<0.2
            if DeltaNpscur==1
                reward=reward-100;
            elseif DeltaNpscur==3
                reward=reward-80;
            else
                reward=reward-80;
            end
        else
            if DeltaNpscur==1
                reward=reward-100;
            elseif DeltaNpscur==3
                reward=reward-80;
            else
                reward=reward-80;
            end            
        end
    end

elseif Pacbcur==1 && Traocur<TraoM
    
        reward=reward-100000;
    
elseif Pacbcur>=PacbH && Pacbcur<1 && Traocur>=TraoH
   
    reward=reward-100000;

elseif Pacbcur>=PacbH && Pacbcur<1 && Traocur>=TraoM && Traocur<TraoH
    

reward=reward+0;
    
elseif Pacbcur>=PacbH && Pacbcur<1 && Traocur<TraoM
    
    
    reward=reward-100000;
      
elseif Pacbcur>=PacbM && Pacbcur<PacbH && Traocur>=TraoH

    reward=reward-100000;

elseif Pacbcur>=PacbM && Pacbcur<PacbH && Traocur<TraoH && Traocur>=TraoM
    if NpsMcur<=NB
               
        
        if NpsCVcur<0.4
            if DeltaNpscur==1
                reward=reward+0;
            elseif DeltaNpscur==3
                reward=reward+0;
            else
                reward=reward+0;
            end             
        else
            if DeltaNpscur==1
                reward=reward+0;
            elseif DeltaNpscur==3
                reward=reward+0;
            else
                reward=reward+0;
            end               
        end
    elseif NpsMcur<NM
            
        
        if NpsCVcur<0.4
            if DeltaNpscur==1
                reward=reward+40;
            elseif DeltaNpscur==3
                reward=reward+60;
            else
                reward=reward+80;
            end
        else
            if DeltaNpscur==1
                reward=reward+40;
            elseif DeltaNpscur==3
                reward=reward+60;
            else
                reward=reward+60;
            end            
        end
    elseif NpsMcur<=NH
          
        
        
        if NpsCVcur<0.2
            if DeltaNpscur==1
                reward=reward+0;
            elseif DeltaNpscur==3
                reward=reward+20;
            else
                reward=reward+40;
            end
        else
            if DeltaNpscur==1
                reward=reward+0;
            elseif DeltaNpscur==3
                reward=reward+0;
            else
                reward=reward+20;
            end            
        end    
    else
            
        
        if NpsCVcur<0.2
            if DeltaNpscur==1
                reward=reward-60;
            elseif DeltaNpscur==3
                reward=reward-40;
            else
                reward=reward-40;
            end
        else
            if DeltaNpscur==1
                reward=reward-60;
            elseif DeltaNpscur==3
                reward=reward-40;
            else
                reward=reward-40;
            end            
        end
    end

    
elseif Pacbcur>=PacbM && Pacbcur<PacbH && Traocur<TraoM
    reward=reward-100000;
    
    
    
elseif Pacbcur>=PacbB && Pacbcur<PacbM && Traocur>=TraoH

    reward=reward-100000;
    

elseif Pacbcur>=PacbB && Pacbcur<PacbM && Traocur<TraoH && Traocur>=TraoM
    reward=reward+0;
    
elseif Pacbcur>=PacbB && Pacbcur<PacbM && Traocur<TraoM

    reward=reward-100000;
    

    
    
elseif Pacbcur<PacbB && Traocur>=TraoH

    reward=reward-100000;
    

elseif Pacbcur<PacbB && Traocur<TraoH && Traocur>=TraoM 
    reward=reward+0;

elseif Pacbcur<PacbB && Traocur<TraoM

    
    reward=reward-100000;
    

    
end

