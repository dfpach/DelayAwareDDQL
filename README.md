# DelayAwareDDQL
Delay Aware DDQL algorithm for access control in LTE-A for MATLAB. This system uses Double Deep Q-Learning to find the policy that optimizes access control and reduces the access delay changing two parameters: Pacb and Trao.


The original LTE simulator with access control was implemented by Luis Tello https://github.com/lptelloq/LTE-A_RACHprocedure

My contribution is an implementation of Double Deep Q-Learning for access control optimization in a system that can adapt both Pacb and Trao using the LTE-A simulator


To train the system run BASE_FILE.m (You need the files with the traffic for H2H traffic.It normally is a file with a row per mean traffic intensity every 10 minutes. M2M traffic is modelled as a beta function). The file dic1celda5161.txt is one of the files used for H2H traffic

The file BASE_FILE.m  trains the system during 3 days (3 data files)  and calls the simulator called LTEA_M_H_ACB_DDQL_TraoPacb_LIMPIO.m

THE FILE calculaterewardexample.m is the cost function. This can be modified according to your interest

THE FILE convierteaccionavars.m is just a function called by LTEA_M_H_ACB_DDQL_TraoPacb_LIMPIO.m

THE FILE rach.m is also needed


