%THIS FILE CONVERTS THE STATE NUMBER TO A PACB, TRAO SET

function [Pacb,Trao]=convierteaccionavars(state)

total=16*6;

if state<=total/16
    Pacb=0.05;
elseif state<=total*2/16
    Pacb=0.1;
    state=state-total/16;
elseif state<=total*3/16
    Pacb=0.15;
    state=state-total*2/16;
elseif state<=total*4/16
    Pacb=0.2;
    state=state-total*3/16;
elseif state<=total*5/16
    Pacb=0.25;
    state=state-total*4/16;
elseif state<=total*6/16
    Pacb=0.3;
    state=state-total*5/16;
elseif state<=total*7/16
    Pacb=0.4;
    state=state-total*6/16;
elseif state<=total*8/16
    Pacb=0.5;
    state=state-total*7/16;
elseif state<=total*9/16
    Pacb=0.6;
    state=state-total*8/16;
elseif state<=total*10/16
    Pacb=0.7;
    state=state-total*9/16;
elseif state<=total*11/16
    Pacb=0.75;
    state=state-total*10/16;
elseif state<=total*12/16
    Pacb=0.8;
    state=state-total*11/16;
elseif state<=total*13/16
    Pacb=0.85;
    state=state-total*12/16;
elseif state<=total*14/16
    Pacb=0.9;
    state=state-total*13/16;
elseif state<=total*15/16
    Pacb=0.95;
    state=state-total*14/16;
elseif state<=total*16/16
    Pacb=1;
    state=state-total*15/16;
end

total=6;

if state<=total/6
    Trao=1;
elseif state<=total*2/6
    Trao=2;
    state=state-total/6;
elseif state<=total*3/6
    Trao=3;
    state=state-total*2/6;
elseif state<=total*4/6
    Trao=5;
    state=state-total*3/6;
elseif state<=total*5/6
    Trao=10;
    state=state-total*4/6; 
elseif state<=total*6/6
    Trao=20;
    state=state-total*5/6;       
end


                