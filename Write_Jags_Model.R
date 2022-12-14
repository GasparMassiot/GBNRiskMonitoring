### JAGS Models

model = "
model{
  ### CORE MODEL #########################################

  ### C_WT MODULE ..............................................
  C_WT ~ dnorm(10,1);

  ### BEFORE STEP MODULE ........................................
  C_WW ~ dnorm(15,1);

  ### AFTER STEP MODULE .........................................
  k_TP ~ dnorm(8,1); # N(8,3) mean 8, sd 3
  C_TP = C_WW - k_TP

  ### AFTER FILTER A MODULE .....................................
  k_A ~ dnorm(4,1); # N(4,1)
  C_A = C_TP - k_A

  ### AFTER FILTER B MODULE .....................................
  k_B ~ dnorm(3,1); # N(3,1)
  C_B = C_TP - k_B;

  ### Legionella pneumophila
  # R ~ dnorm(70,1/18.6^2)T(0.1,);
  f_Lp ~ dnorm(0.001,1/0.0002^2)T(0,);

  C_Lp_WT = C_WT + log(f_Lp)/log(10);#-log(R)/log(10);
  C_Lp_A = C_A + log(f_Lp)/log(10);#-log(R)/log(10);
  C_Lp_B = C_B + log(f_Lp)/log(10);#-log(R)/log(10);

  # C_Lp_WT_2 = coef[1]+coef[2]*10**C_Lp_WT_temp;
  # C_Lp_A_2 = coef[1]+coef[2]*10**C_Lp_A_temp;
  # C_Lp_B_2 = coef[1]+coef[2]*10**C_Lp_B_temp;

  # C_Lp_WT ~ dnorm(coef[1]+coef[2]*10**C_Lp_WT_temp,1/(V[1,1]+2*10**C_Lp_WT_temp*V[2,1]+10**(2*C_Lp_WT_temp)*V[2,2]));
  # C_Lp_A ~ dnorm(coef[1]+coef[2]*10**C_Lp_A_temp,1/(V[1,1]+2*10**C_Lp_A_temp*V[2,1]+10**(2*C_Lp_A_temp)*V[2,2]));
  # C_Lp_B ~ dnorm(coef[1]+coef[2]*10**C_Lp_B_temp,1/(V[1,1]+2*10**C_Lp_B_temp*V[2,1]+10**(2*C_Lp_B_temp)*V[2,2]));

  # C_Lp_WT2 = coef[1]+coef[2]*C_Lp_WT_temp;
  # C_Lp_A2 = coef[1]+coef[2]*C_Lp_A_temp;
  # C_Lp_B2 = coef[1]+coef[2]*C_Lp_B_temp;

  # C_Lp_WT ~ dnorm(coef[1]+coef[2]*C_Lp_WT_temp,1/V);
  # C_Lp_A ~ dnorm(coef[1]+coef[2]*C_Lp_A_temp,1/V);
  # C_Lp_B ~ dnorm(coef[1]+coef[2]*C_Lp_B_temp,1/V);

  ### ASPERSION DEVICE MODULE ...................................
  # p150 = proportion de particules < 150µm (sans unité) (de l'ordre de 0.06% d'après le rapport Anses)
  p150 ~ dunif(0.05/100, 0.07/100);
  # F1 = Débit délivré par l'asperseur (m3/h) (autour de 40-50 m3/h)
  F1 ~ dnorm(44,1);
  F2 ~ dnorm(42,1);
  # Q = débit de rejet des microorganismes (µorganismes/s) taille inférieure à 150µm
  Q_Lp_WT = C_Lp_WT/log(10) + log((F1+F2)/(2*10^3)*p150*3600)/log(10);
  Q_Lp_A = C_Lp_A/log(10) + log(F1/10^3*p150*3600)/log(10);
  Q_Lp_B = C_Lp_B/log(10) + log(F2/10^3*p150*3600)/log(10);

  ### ATMOSPHERIC DISPERSION MODULE .............................
  ## Pasquill coefficients ......................................
  aux ~ dbern(0.5);
  Eaux = E/1000;
  # step(e) = 1 if e>=0; 0 otherwise
  PasquillIndex = (1-step(u-2))*((1-step(Eaux-1))*2+(1-step(Eaux-2))*step(Eaux-1)*(aux+1)+step(Eaux-2)*1)+
  (1-step(u-3))*step(u-2)*((1-step(Eaux-1))*3+(1-step(Eaux-2))*step(Eaux-1)*2+step(Eaux-2)*(aux+1))+
  (1-step(u-4))*step(u-3)*((1-step(Eaux-1))*3+(1-step(Eaux-2))*step(Eaux-1)*(aux+2)+step(Eaux-2)*2)+
  (1-step(u-6))*step(u-4)*((1-step(Eaux-1))*4+(1-step(Eaux-2))*step(Eaux-1)*(aux+3)+step(Eaux-2)*3)+
  step(u-6)*((1-step(Eaux-1))*4+(1-step(Eaux-2))*step(Eaux-1)*4+step(Eaux-2)*3);

  a_y = Pasquill[PasquillIndex,1];
  b_y = Pasquill[PasquillIndex,2];
  c_y = Pasquill[PasquillIndex,3];
  a_z = Pasquill[PasquillIndex,4];
  b_z = Pasquill[PasquillIndex,5];
  c_z = Pasquill[PasquillIndex,6];

  ## Legionella concentrations ..................................
  x[1] = 50; x[2] = 100; x[3] = 300; x[4] = 500; x[5] = 1000; x[6]=5000;
  lambda ~ dnorm(1.32E-4, 10000*10000/3.44^2);
  y ~ dunif(0,10) # décallage horizontal
  y0 <- 0; # point de référence
  z ~ dunif(1,2.5)
  z_0 ~ dunif(0.1,0.45) # Rugosité aérodynamique
  aux1 <- y-y0;
  aux2 <- z-z_0;
  aux3 <- z+z_0;
  for (xindex in 1:6){
    ## Facteur d'extinction M à x mètres ........................
    M[xindex] = -lambda*(x[xindex]*exp(-log(u)))/log(10)

    ## Facteur de dispersion atmosphérique D à x mètres s/m3 .....
    D[xindex] = 1/(2*3.14*u*sig_y[xindex]*sig_z[xindex])*exp(-pow(aux1,2)/(2*pow(sig_y[xindex],2)))*(exp(-pow(aux2,2)/(2*pow(sig_z[xindex],2)))+exp(-pow(aux3,2)/(2*pow(sig_z[xindex],2))));
    D2[xindex] = -log(2*3.14*u*sig_y[xindex]*sig_z[xindex])/log(10)-pow(aux1,2)/(2*pow(sig_y[xindex],2))/log(10)+log(exp(-pow(aux2,2)/(2*pow(sig_z[xindex],2)))+exp(-pow(aux3,2)/(2*pow(sig_z[xindex],2))))/log(10);
    sig_y[xindex] = (a_y*pow(x[xindex]/10^3,b_y)+c_y)*10^3;
    sig_z[xindex] = (a_z*pow(x[xindex]/10^3,b_z)+c_z)*10^3;

    ## Concentrations à x mètres µorg/m3 ........................
    C_xA[xindex] <- log(D[xindex])/log(10)+M[xindex]+Q_Lp_A
    C_xB[xindex] <- log(D[xindex])/log(10)+M[xindex]+Q_Lp_B
    C_xWT[xindex] <- log(D[xindex])/log(10)+M[xindex]+Q_Lp_WT
  }

  ### INHALATION MODULE .........................................
  I ~ dnorm(20,0.25) # IR = taux d'inhalation (~20m3/jour)

  ### EXPOSITION MODULE .........................................
  t_passerby ~ dnorm(1, 2)T(0,24*60) # 1 min par jour d'irrigation
  t_resident ~ dnorm(2*2.27, 2)T(0,24*60) # 2s toutes les min pendant les 2.27h passées dehors
  t_farmer ~ dnorm(30, 2)T(0,24*60) # 30min par jour d'irrigation

  for (xindex in 1:6){
    D_xWT[xindex] <- C_xWT[xindex]+log(I)/log(10) # De = dose inhalable par une personne, par jour à x mètres de la source
    D_xA[xindex] <- C_xA[xindex]+log(I)/log(10) # De = dose inhalable par une personne, par jour à x mètres de la source
    D_xB[xindex] <- C_xB[xindex]+log(I)/log(10) # De = dose inhalable par une personne, par jour à x mètres de la source

    D_farmer_xWT[xindex] <- D_xWT[xindex]+log(t_farmer/(60*24))/log(10) # Dose d'exposition par jour pour les travailleurs
    D_passerby_xWT[xindex] <- D_xWT[xindex]+log(t_passerby/(60*24))/log(10) # Dose d'exposition par jour pour les passants
    D_resident_xWT[xindex] <- D_xWT[xindex]+log(t_resident/(60*24))/log(10) # Dose d'exposition par jour pour les residents

    D_farmer_xA[xindex] <- D_xA[xindex]+log(t_farmer/(60*24))/log(10) # Dose d'exposition par jour pour les travailleurs
    D_passerby_xA[xindex] <- D_xA[xindex]+log(t_passerby/(60*24))/log(10) # Dose d'exposition par jour pour les passants
    D_resident_xA[xindex] <- D_xA[xindex]+log(t_resident/(60*24))/log(10) # Dose d'exposition par jour pour les residents

    D_farmer_xB[xindex] <- D_xB[xindex]+log(t_farmer/(60*24))/log(10) # Dose d'exposition par jour pour les travailleurs
    D_passerby_xB[xindex] <- D_xB[xindex]+log(t_passerby/(60*24))/log(10) # Dose d'exposition par jour pour les passants
    D_resident_xB[xindex] <- D_xB[xindex]+log(t_resident/(60*24))/log(10) # Dose d'exposition par jour pour les residents
  }

  ### DOSE RESPONSE MODULE ......................................
  ## PROBABILITY OF INFECTION OVER ONE DAY OF IRRIGATION ........
  rinf ~ dlnorm(-2.934, 1/0.488^2)
  rcsi ~ dlnorm(-9.688, 1/0.296^2)

  f_CFU ~ dnorm(0.001,1/0.0002^2)T(0,);

  for (xindex in 1:6){
    Pinf_farmer_xWT[xindex] <- log(1-exp(-rinf*pow(10,D_farmer_xWT[xindex])*f_CFU))/log(10)
    Pinf_resident_xWT[xindex] <- log(1-exp(-rinf*pow(10,D_resident_xWT[xindex])*f_CFU))/log(10)
    Pinf_passerby_xWT[xindex] <- log(1-exp(-rinf*pow(10,D_passerby_xWT[xindex])*f_CFU))/log(10)

    Pinf_farmer_xA[xindex] <- log(1-exp(-rinf*pow(10,D_farmer_xA[xindex])*f_CFU))/log(10)
    Pinf_resident_xA[xindex] <- log(1-exp(-rinf*pow(10,D_resident_xA[xindex])*f_CFU))/log(10)
    Pinf_passerby_xA[xindex] <- log(1-exp(-rinf*pow(10,D_passerby_xA[xindex])*f_CFU))/log(10)

    Pinf_farmer_xB[xindex] <- log(1-exp(-rinf*pow(10,D_farmer_xB[xindex])*f_CFU))/log(10)
    Pinf_resident_xB[xindex] <- log(1-exp(-rinf*pow(10,D_resident_xB[xindex])*f_CFU))/log(10)
    Pinf_passerby_xB[xindex] <- log(1-exp(-rinf*pow(10,D_passerby_xB[xindex])*f_CFU))/log(10)

    Pcsi_farmer_xWT[xindex] <- log(1-exp(-rcsi*pow(10,D_farmer_xWT[xindex])*f_CFU))/log(10)
    Pcsi_resident_xWT[xindex] <- log(1-exp(-rcsi*pow(10,D_resident_xWT[xindex])*f_CFU))/log(10)
    Pcsi_passerby_xWT[xindex] <- log(1-exp(-rcsi*pow(10,D_passerby_xWT[xindex])*f_CFU))/log(10)

    Pcsi_farmer_xA[xindex] <- log(1-exp(-rcsi*pow(10,D_farmer_xA[xindex])*f_CFU))/log(10)
    Pcsi_resident_xA[xindex] <- log(1-exp(-rcsi*pow(10,D_resident_xA[xindex])*f_CFU))/log(10)
    Pcsi_passerby_xA[xindex] <- log(1-exp(-rcsi*pow(10,D_passerby_xA[xindex])*f_CFU))/log(10)

    Pcsi_farmer_xB[xindex] <- log(1-exp(-rcsi*pow(10,D_farmer_xB[xindex])*f_CFU))/log(10)
    Pcsi_resident_xB[xindex] <- log(1-exp(-rcsi*pow(10,D_resident_xB[xindex])*f_CFU))/log(10)
    Pcsi_passerby_xB[xindex] <- log(1-exp(-rcsi*pow(10,D_passerby_xB[xindex])*f_CFU))/log(10)
  }

  ## PROBABILITY OVER ONE YEAR...................................
  n.d ~ dcat(n.di[])
  n_episodes_irrigation = vn[n.d]

  d.d ~ dcat(d.di[])
  duree_episode_irrigation = vd[d.d]

  n = n_episodes_irrigation*duree_episode_irrigation

  for (xindex in 1:6){
    Pyinf_farmer_xWT[xindex] <- log(1-(pow(1-pow(10,Pinf_farmer_xWT[xindex]),n)))/log(10)
    Pyinf_resident_xWT[xindex] <- log(1-(pow(1-pow(10,Pinf_resident_xWT[xindex]),n)))/log(10)
    Pyinf_passerby_xWT[xindex] <- log(1-(pow(1-pow(10,Pinf_passerby_xWT[xindex]),n)))/log(10)

    Pyinf_farmer_xA[xindex] <- log(1-(pow(1-pow(10,Pinf_farmer_xA[xindex]),n)))/log(10)
    Pyinf_resident_xA[xindex] <- log(1-(pow(1-pow(10,Pinf_resident_xA[xindex]),n)))/log(10)
    Pyinf_passerby_xA[xindex] <- log(1-(pow(1-pow(10,Pinf_passerby_xA[xindex]),n)))/log(10)

    Pyinf_farmer_xB[xindex] <- log(1-(pow(1-pow(10,Pinf_farmer_xB[xindex]),n)))/log(10)
    Pyinf_resident_xB[xindex] <- log(1-(pow(1-pow(10,Pinf_resident_xB[xindex]),n)))/log(10)
    Pyinf_passerby_xB[xindex] <- log(1-(pow(1-pow(10,Pinf_passerby_xB[xindex]),n)))/log(10)

    Pycsi_farmer_xWT[xindex] <- log(1-(pow(1-pow(10,Pcsi_farmer_xWT[xindex]),n)))/log(10)
    Pycsi_resident_xWT[xindex] <- log(1-(pow(1-pow(10,Pcsi_resident_xWT[xindex]),n)))/log(10)
    Pycsi_passerby_xWT[xindex] <- log(1-(pow(1-pow(10,Pcsi_passerby_xWT[xindex]),n)))/log(10)

    Pycsi_farmer_xA[xindex] <- log(1-(pow(1-pow(10,Pcsi_farmer_xA[xindex]),n)))/log(10)
    Pycsi_resident_xA[xindex] <- log(1-(pow(1-pow(10,Pcsi_resident_xA[xindex]),n)))/log(10)
    Pycsi_passerby_xA[xindex] <- log(1-(pow(1-pow(10,Pcsi_passerby_xA[xindex]),n)))/log(10)

    Pycsi_farmer_xB[xindex] <- log(1-(pow(1-pow(10,Pcsi_farmer_xB[xindex]),n)))/log(10)
    Pycsi_resident_xB[xindex] <- log(1-(pow(1-pow(10,Pcsi_resident_xB[xindex]),n)))/log(10)
    Pycsi_passerby_xB[xindex] <- log(1-(pow(1-pow(10,Pcsi_passerby_xB[xindex]),n)))/log(10)
  }

  ### AUGMENTED MODEL FOR DATA INCORPORATION #############

  ### WATER TABLE MODULE ..............................................
  tauofC_WT ~ dgamma(100, 100);
  for (i in 1:n_data_concentration){
    Concentrations[i,1] ~ dnorm(C_WT,tauofC_WT)
  }

  ### BEFORE STEP MODULE ........................................
  tauofC_WW ~ dgamma(100, 100);
  for (i in 1:n_data_concentration){
    Concentrations[i,2] ~ dnorm(C_WW,tauofC_WW);
  }

  ### AFTER STEP MODULE .........................................
  tauofC_TP ~ dgamma(100, 100);
  for (i in 1:n_data_concentration){
    Concentrations[i,3] ~ dnorm(C_TP,tauofC_TP);
  }

  ### AFTER FILTER A MODULE .....................................
  tauofC_A ~ dgamma(100, 100);
  for (i in 1:n_data_concentration){
    Concentrations[i,4] ~ dnorm(C_A,tauofC_A);
  }

  ### AFTER FILTER B MODULE .....................................
  tauofC_B ~ dgamma(100, 100);
  for (i in 1:n_data_concentration){
    Concentrations[i,5] ~ dnorm(C_B,tauofC_B);
  }

  ### ATMOSPHERIC DISPERSION MODULE .............................
  ## Modèle Vent ................................................
  # V = vitesse du vent
  # mu, tau, sigma = moyenne, précision, et écart-type
  # mu_j, tauR, sigmaR = moyenne, précision, et écart-type

  # Modèle d'observations
  for (i in 1:Ntotal) { # 3 années = 1096 jours
    Meteo[i,1:2] ~ dmnorm(VE_Mu[Meteo[i,3],1:2],VE_InvCovMat[1:2,1:2])
  }

  # Lois a priori
  mu[1] ~ dnorm(2,2*8);
  sigma[1] ~ dunif(0.01,1/(sqrt(8)));
  mu[2] ~ dnorm(8,2*8);
  sigma[2] ~ dunif(0.01,1/(sqrt(8)));
  # mu[1] ~ dnorm(0,10);
  # sigma[1] ~ dunif(0.1,0.5);
  # mu[2] ~ dnorm(5,1);
  # sigma[2] ~ dunif(0.1,0.5);
  for ( varIdx in 1:2 ){
    tau[varIdx] <- 1/sigma[varIdx]^2;
    # tau[varIdx] ~ dgamma(0.001,0.001);
    for (j in annee_unique){
      VE_Mu[j,varIdx] ~ dnorm(mu[varIdx] , tau[varIdx]);
    }
    mu_jrep[varIdx] ~ dnorm(mu[varIdx], tau[varIdx]);
  }
  VE_InvCovMat[1:2,1:2] ~ dwish( VE_Rmat[1:2,1:2] , VE_Rscal );
  logVE_rep[1:2] ~ dmnorm(mu_jrep[1:2], VE_InvCovMat[1:2,1:2]);

  u = exp(logVE_rep[1]);
  E = exp(logVE_rep[2]);
}# ending the model ###################################
"
writeLines(model, con="Jags/model.bug")

modelCore = "
model{
  ### CORE MODEL #########################################

  ### C_WT MODULE ..............................................
  C_WT ~ dnorm(10,1);

  ### BEFORE STEP MODULE ........................................
  C_WW ~ dnorm(15,1);

  ### AFTER STEP MODULE .........................................
  k_TP ~ dnorm(8,1); # N(8,3) mean 8, sd 3
  C_TP = C_WW - k_TP

  ### AFTER FILTER A MODULE .....................................
  k_A ~ dnorm(4,1); # N(4,1)
  C_A = C_TP - k_A

  ### AFTER FILTER B MODULE .....................................
  k_B ~ dnorm(3,1); # N(3,1)
  C_B = C_TP - k_B;

  ### Legionella pneumophila
  # R ~ dnorm(70,1/18.6^2)T(0.1,);
  # f_Lp ~ dnorm(0.3580,1/0.03051^2)T(0,);
  f_Lp ~ dnorm(0.001,1/0.0002^2)T(0,);
  C_Lp_WT = C_WT + log(f_Lp)/log(10);#-log(R)/log(10);
  C_Lp_A = C_A+log(f_Lp)/log(10);#-log(R)/log(10);
  C_Lp_B = C_B+log(f_Lp)/log(10);#-log(R)/log(10);

  # C_Lp_WT_2 = coef[1]+coef[2]*10**C_Lp_WT_temp;
  # C_Lp_A_2 = coef[1]+coef[2]*10**C_Lp_A_temp;
  # C_Lp_B_2 = coef[1]+coef[2]*10**C_Lp_B_temp;

  # C_Lp_WT ~ dnorm(coef[1]+coef[2]*C_Lp_WT_temp,1/(V[1,1]+2*C_Lp_WT_temp*V[2,1]+(C_Lp_WT_temp)**2*V[2,2]));
  # C_Lp_A ~ dnorm(coef[1]+coef[2]*C_Lp_A_temp,1/(V[1,1]+2*C_Lp_A_temp*V[2,1]+(C_Lp_A_temp)**2*V[2,2]));
  # C_Lp_B ~ dnorm(coef[1]+coef[2]*C_Lp_B_temp,1/(V[1,1]+2*C_Lp_B_temp*V[2,1]+(C_Lp_B_temp)**2*V[2,2]));

  # C_Lp_WT2 = coef[1]+coef[2]*C_Lp_WT_temp;
  # C_Lp_A2 = coef[1]+coef[2]*C_Lp_A_temp;
  # C_Lp_B2 = coef[1]+coef[2]*C_Lp_B_temp;

  # C_Lp_WT ~ dnorm(coef[1]+coef[2]*C_Lp_WT_temp,1/V);
  # C_Lp_A ~ dnorm(coef[1]+coef[2]*C_Lp_A_temp,1/V);
  # C_Lp_B ~ dnorm(coef[1]+coef[2]*C_Lp_B_temp,1/V);

  ### ASPERSION DEVICE MODULE ...................................
  # p150 = proportion de particules < 150µm (sans unité) (de l'ordre de 0.06% d'après le rapport Anses)
  p150 ~ dunif(0.05/100, 0.07/100);
  # F1 = Débit délivré par l'asperseur (m3/h) (autour de 40-50 m3/h)
  F1 ~ dnorm(44,1);
  F2 ~ dnorm(42,1);
  # Q = débit de rejet des microorganismes (µorganismes/s) taille inférieure à 150µm
  Q_Lp_WT = C_Lp_WT/log(10) + log((F1+F2)/(2*10^3)*p150*3600)/log(10);
  Q_Lp_A = C_Lp_A/log(10) + log(F1/10^3*p150*3600)/log(10);
  Q_Lp_B = C_Lp_B/log(10) + log(F2/10^3*p150*3600)/log(10);

  # QA_sol = C_A*10^3*(F1/3600*(1-p150));

  ### ATMOSPHERIC DISPERSION MODULE .............................
  ## Pasquill coefficients ......................................
  u ~ dlnorm(2,8)
  E ~ dlnorm(8,8)

  aux ~ dbern(0.5);
  Eaux = E/1000;
  # step(e) = 1 if e>=0; 0 otherwise
  PasquillIndex = (1-step(u-2))*((1-step(Eaux-1))*2+(1-step(Eaux-2))*step(Eaux-1)*(aux+1)+step(Eaux-2)*1)+
  (1-step(u-3))*step(u-2)*((1-step(Eaux-1))*3+(1-step(Eaux-2))*step(Eaux-1)*2+step(Eaux-2)*(aux+1))+
  (1-step(u-4))*step(u-3)*((1-step(Eaux-1))*3+(1-step(Eaux-2))*step(Eaux-1)*(aux+2)+step(Eaux-2)*2)+
  (1-step(u-6))*step(u-4)*((1-step(Eaux-1))*4+(1-step(Eaux-2))*step(Eaux-1)*(aux+3)+step(Eaux-2)*3)+
  step(u-6)*((1-step(Eaux-1))*4+(1-step(Eaux-2))*step(Eaux-1)*4+step(Eaux-2)*3);

  a_y = Pasquill[PasquillIndex,1];
  b_y = Pasquill[PasquillIndex,2];
  c_y = Pasquill[PasquillIndex,3];
  a_z = Pasquill[PasquillIndex,4];
  b_z = Pasquill[PasquillIndex,5];
  c_z = Pasquill[PasquillIndex,6];

  ## Legionella concentrations ..................................
  x[1] = 50; x[2] = 100; x[3] = 300; x[4] = 500; x[5] = 1000; x[6]=5000;
  lambda ~ dnorm(1.32E-4, 10000*10000/3.44^2);
  y ~ dunif(0,10) # décallage horizontal
  y0 <- 0; # point de référence
  z ~ dunif(1,2.5)
  z_0 ~ dunif(0.1,0.45) # Rugosité aérodynamique
  aux1 <- y-y0;
  aux2 <- z-z_0;
  aux3 <- z+z_0;
  for (xindex in 1:6){
    ## Facteur d'extinction M à x mètres ........................
    M[xindex] = -lambda*(x[xindex]*exp(-log(u)))/log(10)

    ## Facteur de dispersion atmosphérique D à x mètres s/m3 .....
    D[xindex] = 1/(2*3.14*u*sig_y[xindex]*sig_z[xindex])*exp(-pow(aux1,2)/(2*pow(sig_y[xindex],2)))*(exp(-pow(aux2,2)/(2*pow(sig_z[xindex],2)))+exp(-pow(aux3,2)/(2*pow(sig_z[xindex],2))));
    D2[xindex] = -log(2*3.14*u*sig_y[xindex]*sig_z[xindex])/log(10)-pow(aux1,2)/(2*pow(sig_y[xindex],2))/log(10)+log(exp(-pow(aux2,2)/(2*pow(sig_z[xindex],2)))+exp(-pow(aux3,2)/(2*pow(sig_z[xindex],2))))/log(10);
    sig_y[xindex] = (a_y*pow(x[xindex]/10^3,b_y)+c_y)*10^3;
    sig_z[xindex] = (a_z*pow(x[xindex]/10^3,b_z)+c_z)*10^3;

    ## Concentrations à x mètres µorg/m3 ........................
    C_xA[xindex] <- log(D[xindex])/log(10)+M[xindex]+Q_Lp_A
    C_xB[xindex] <- log(D[xindex])/log(10)+M[xindex]+Q_Lp_B
    C_xWT[xindex] <- log(D[xindex])/log(10)+M[xindex]+Q_Lp_WT
  }

  ### INHALATION MODULE .........................................
  I ~ dnorm(20,0.25) # IR = taux d'inhalation (~20m3/jour)

  ### EXPOSITION MODULE .........................................
  t_passerby ~ dnorm(1, 4)T(0,24*60) # 1 min par jour d'irrigation
  t_resident ~ dnorm(2*2.27, 4)T(0,24*60) # 2s toutes les min pendant les 2.27h passées dehors
  t_farmer ~ dnorm(30, 4)T(0,24*60) # 30min par jour d'irrigation

  for (xindex in 1:6){
    D_xWT[xindex] <- C_xWT[xindex]+log(I)/log(10) # De = dose inhalable par une personne, par jour à x mètres de la source
    D_xA[xindex] <- C_xA[xindex]+log(I)/log(10) # De = dose inhalable par une personne, par jour à x mètres de la source
    D_xB[xindex] <- C_xB[xindex]+log(I)/log(10) # De = dose inhalable par une personne, par jour à x mètres de la source

    D_farmer_xWT[xindex] <- D_xWT[xindex]+log(t_farmer/(60*24))/log(10) # Dose d'exposition par jour pour les travailleurs
    D_passerby_xWT[xindex] <- D_xWT[xindex]+log(t_passerby/(60*24))/log(10) # Dose d'exposition par jour pour les passants
    D_resident_xWT[xindex] <- D_xWT[xindex]+log(t_resident/(60*24))/log(10) # Dose d'exposition par jour pour les residents

    D_farmer_xA[xindex] <- D_xA[xindex]+log(t_farmer/(60*24))/log(10) # Dose d'exposition par jour pour les travailleurs
    D_passerby_xA[xindex] <- D_xA[xindex]+log(t_passerby/(60*24))/log(10) # Dose d'exposition par jour pour les passants
    D_resident_xA[xindex] <- D_xA[xindex]+log(t_resident/(60*24))/log(10) # Dose d'exposition par jour pour les residents

    D_farmer_xB[xindex] <- D_xB[xindex]+log(t_farmer/(60*24))/log(10) # Dose d'exposition par jour pour les travailleurs
    D_passerby_xB[xindex] <- D_xB[xindex]+log(t_passerby/(60*24))/log(10) # Dose d'exposition par jour pour les passants
    D_resident_xB[xindex] <- D_xB[xindex]+log(t_resident/(60*24))/log(10) # Dose d'exposition par jour pour les residents
  }

  ### DOSE RESPONSE MODULE ......................................
  ## PROBABILITY OF INFECTION OVER ONE DAY OF IRRIGATION ........
  rinf ~ dlnorm(-2.934, 1/0.488^2)
  rcsi ~ dlnorm(-9.688, 1/0.296^2)

  f_CFU ~ dnorm(0.001,1/0.0002^2)T(0,);

  for (xindex in 1:6){
    Pinf_farmer_xWT[xindex] <- log(1-exp(-rinf*pow(10,D_farmer_xWT[xindex])*f_CFU))/log(10)
    Pinf_resident_xWT[xindex] <- log(1-exp(-rinf*pow(10,D_resident_xWT[xindex])*f_CFU))/log(10)
    Pinf_passerby_xWT[xindex] <- log(1-exp(-rinf*pow(10,D_passerby_xWT[xindex])*f_CFU))/log(10)

    Pinf_farmer_xA[xindex] <- log(1-exp(-rinf*pow(10,D_farmer_xA[xindex])*f_CFU))/log(10)
    Pinf_resident_xA[xindex] <- log(1-exp(-rinf*pow(10,D_resident_xA[xindex])*f_CFU))/log(10)
    Pinf_passerby_xA[xindex] <- log(1-exp(-rinf*pow(10,D_passerby_xA[xindex])*f_CFU))/log(10)

    Pinf_farmer_xB[xindex] <- log(1-exp(-rinf*pow(10,D_farmer_xB[xindex])*f_CFU))/log(10)
    Pinf_resident_xB[xindex] <- log(1-exp(-rinf*pow(10,D_resident_xB[xindex])*f_CFU))/log(10)
    Pinf_passerby_xB[xindex] <- log(1-exp(-rinf*pow(10,D_passerby_xB[xindex])*f_CFU))/log(10)

    Pcsi_farmer_xWT[xindex] <- log(1-exp(-rcsi*pow(10,D_farmer_xWT[xindex])*f_CFU))/log(10)
    Pcsi_resident_xWT[xindex] <- log(1-exp(-rcsi*pow(10,D_resident_xWT[xindex])*f_CFU))/log(10)
    Pcsi_passerby_xWT[xindex] <- log(1-exp(-rcsi*pow(10,D_passerby_xWT[xindex])*f_CFU))/log(10)

    Pcsi_farmer_xA[xindex] <- log(1-exp(-rcsi*pow(10,D_farmer_xA[xindex])*f_CFU))/log(10)
    Pcsi_resident_xA[xindex] <- log(1-exp(-rcsi*pow(10,D_resident_xA[xindex])*f_CFU))/log(10)
    Pcsi_passerby_xA[xindex] <- log(1-exp(-rcsi*pow(10,D_passerby_xA[xindex])*f_CFU))/log(10)

    Pcsi_farmer_xB[xindex] <- log(1-exp(-rcsi*pow(10,D_farmer_xB[xindex])*f_CFU))/log(10)
    Pcsi_resident_xB[xindex] <- log(1-exp(-rcsi*pow(10,D_resident_xB[xindex])*f_CFU))/log(10)
    Pcsi_passerby_xB[xindex] <- log(1-exp(-rcsi*pow(10,D_passerby_xB[xindex])*f_CFU))/log(10)
  }

  ## PROBABILITY OVER ONE YEAR...................................
  n.d ~ dcat(n.di[])
  n_episodes_irrigation = vn[n.d]

  d.d ~ dcat(d.di[])
  duree_episode_irrigation = vd[d.d]

  n = n_episodes_irrigation*duree_episode_irrigation

  for (xindex in 1:6){
    Pyinf_farmer_xWT[xindex] <- log(1-(pow(1-pow(10,Pinf_farmer_xWT[xindex]),n)))/log(10)
    Pyinf_resident_xWT[xindex] <- log(1-(pow(1-pow(10,Pinf_resident_xWT[xindex]),n)))/log(10)
    Pyinf_passerby_xWT[xindex] <- log(1-(pow(1-pow(10,Pinf_passerby_xWT[xindex]),n)))/log(10)

    Pyinf_farmer_xA[xindex] <- log(1-(pow(1-pow(10,Pinf_farmer_xA[xindex]),n)))/log(10)
    Pyinf_resident_xA[xindex] <- log(1-(pow(1-pow(10,Pinf_resident_xA[xindex]),n)))/log(10)
    Pyinf_passerby_xA[xindex] <- log(1-(pow(1-pow(10,Pinf_passerby_xA[xindex]),n)))/log(10)

    Pyinf_farmer_xB[xindex] <- log(1-(pow(1-pow(10,Pinf_farmer_xB[xindex]),n)))/log(10)
    Pyinf_resident_xB[xindex] <- log(1-(pow(1-pow(10,Pinf_resident_xB[xindex]),n)))/log(10)
    Pyinf_passerby_xB[xindex] <- log(1-(pow(1-pow(10,Pinf_passerby_xB[xindex]),n)))/log(10)

    Pycsi_farmer_xWT[xindex] <- log(1-(pow(1-pow(10,Pcsi_farmer_xWT[xindex]),n)))/log(10)
    Pycsi_resident_xWT[xindex] <- log(1-(pow(1-pow(10,Pcsi_resident_xWT[xindex]),n)))/log(10)
    Pycsi_passerby_xWT[xindex] <- log(1-(pow(1-pow(10,Pcsi_passerby_xWT[xindex]),n)))/log(10)

    Pycsi_farmer_xA[xindex] <- log(1-(pow(1-pow(10,Pcsi_farmer_xA[xindex]),n)))/log(10)
    Pycsi_resident_xA[xindex] <- log(1-(pow(1-pow(10,Pcsi_resident_xA[xindex]),n)))/log(10)
    Pycsi_passerby_xA[xindex] <- log(1-(pow(1-pow(10,Pcsi_passerby_xA[xindex]),n)))/log(10)

    Pycsi_farmer_xB[xindex] <- log(1-(pow(1-pow(10,Pcsi_farmer_xB[xindex]),n)))/log(10)
    Pycsi_resident_xB[xindex] <- log(1-(pow(1-pow(10,Pcsi_resident_xB[xindex]),n)))/log(10)
    Pycsi_passerby_xB[xindex] <- log(1-(pow(1-pow(10,Pcsi_passerby_xB[xindex]),n)))/log(10)
  }
}# ending the model ###################################
"
writeLines(modelCore, con="Jags/modelCore.bug")
