############ Not Run

rm(list = ls())

library(dplyr)
library(rjags)
library(coda)
library(lubridate)
library(ggmcmc)
library(latex2exp)
library(scales)
library(ggthemes)
library(ggpubr)
library(ggridges)
library(tibble)
library(kableExtra)
library(censReg)
library(smicd)
library(survival)

# load("data/data.Rda")

update_standard <- 1000000

nstandard  <- 800000

thin <- 200

fileModelCore <- "Jags/modelCore.bug"
fileModel <- "Jags/model.bug"

########## Run models needs data
# jags_Inn <- jags.model(file=fileModelCore,
#                        data = databugs, n.chains =2, n.adapt = 100, quiet = T)
# update(jags_Inn, update_standard)

variable.names <- c("C_WT", "C_WW", "C_TP", "C_A", "C_B",
                    "k_TP", "k_A", "k_B",
                    "f_Lp", "C_Lp_WT", "C_Lp_A", "C_Lp_B",
                    "p150", "F1", "F2",
                    "Q_Lp_WT", "Q_Lp_A", "Q_Lp_B",
                    "u", "E",
                    "PasquillIndex", "a_y", "b_y", "c_y", "a_z", "b_z", "c_z",
                    "lambda", "y", "z", "sig_y", "sig_z", "z_0",
                    "M", "D", "D2",
                    "C_xWT", "C_xA", "C_xB",
                    "I",
                    "t_farmer", "t_resident", "t_passerby",
                    "D_xWT", "D_xA", "D_xB",
                    "D_farmer_xWT", "D_resident_xWT", "D_passerby_xWT",
                    "D_farmer_xA", "D_resident_xA", "D_passerby_xA",
                    "D_farmer_xB", "D_resident_xB", "D_passerby_xB",
                    "rinf", "rcsi",
                    "Pinf_farmer_xWT", "Pinf_resident_xWT", "Pinf_passerby_xWT",
                    "Pinf_farmer_xA", "Pinf_resident_xA", "Pinf_passerby_xA",
                    "Pinf_farmer_xB", "Pinf_resident_xB", "Pinf_passerby_xB",
                    "Pcsi_farmer_xWT", "Pcsi_resident_xWT", "Pcsi_passerby_xWT",
                    "Pcsi_farmer_xA", "Pcsi_resident_xA", "Pcsi_passerby_xA",
                    "Pcsi_farmer_xB", "Pcsi_resident_xB", "Pcsi_passerby_xB",
                    "n.d", "n_episodes_irrigation", "d.d", "duree_episode_irrigation", "n",
                    "Pyinf_farmer_xWT", "Pyinf_resident_xWT", "Pyinf_passerby_xWT",
                    "Pyinf_farmer_xA", "Pyinf_resident_xA", "Pyinf_passerby_xA",
                    "Pyinf_farmer_xB", "Pyinf_resident_xB", "Pyinf_passerby_xB",
                    "Pycsi_farmer_xWT", "Pycsi_resident_xWT", "Pycsi_passerby_xWT",
                    "Pycsi_farmer_xA", "Pycsi_resident_xA", "Pycsi_passerby_xA",
                    "Pycsi_farmer_xB", "Pycsi_resident_xB", "Pycsi_passerby_xB")

# prior_jags <- coda.samples(model=jags_Inn,variable.names=variable.names,
#                            n.iter=nstandard, thin=thin, quiet = T)

# date_cut <- paste0(unique(sort(format(databugs$Concentrations$Date, "%Y/%m"))), "/01")

# data_list <- lapply(date_cut, \(x) cutDate(databugs, x))

# jags_list <- lapply(data_list, \(x)
#                     jags.model(file=fileLog, data = x, n.chains =2, n.adapt = 100, quiet = T))
# lapply(jags_list, \(x) update(x, update_standard))

# results_list <- lapply(jags_list, \(x)
#                        coda.samples(model=x,variable.names=variable.names,
#                                     n.iter=nstandard, thin=200, quiet = T))

# rm(list = ls()[!(ls() %in% c("prior_jags", "results_list", "date_cut", "today"))])
# 
# fileJags <- "data/result.Rda")
# 
# save.image(fileJags)
