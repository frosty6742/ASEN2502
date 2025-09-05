%%ASEN 2502 Design Engineering Model Baseline Main Script
% Original Authors: John Mah / Preston Tee
% Contributing Authors:
% Current Version:  AY25.01 (DO NOT MERGE THIS BRANCH INTO MAIN BRANCH)
% Changes in Current Version:
    %Updated to reflect ASEN 2502 Design Lab Fall 25

% Date Last Change: 11 August 2025

%% Quick Explainer - Tables
% This code heavily utilizes tables for data organization. You should think
% of a table as a spreadsheet. Tables are also very similar to a 2D array
% of data exept that the columns can be named so that it is clear what data
% is in those columns. There are multiple ways to get the data out of
% columns, through standard indexing, and through dot indexing. 
%
% Standard indexing:
%
% Like when indexing into an array you can get data out of a table by using
% parenthasis, (), which will return another table, which is often a 
% problem for calulations and plotting
%   Example:
%       NewTable = OriginalTable(:,:)
%
% Alternativly, if you index in the same way but with curly braces, {}, a
% standard array will be returned
%   Example:
%       NewArray = OriginalTable{:,:}
%
% Finally, if you would like to access just one column, tables support dot
% indexing using the name of the column header. This takes the form of the 
% name of the variable, then a dot, then the name of the column, This will
% return a standard 1D array of data
%   Example: 
%       NewArray = OriginalTable.ColumnName_1
%
% The tables in this code have been purposly organized such that the rows
% will ALWAYS correspond to the different configuration inputs in the input
% file. In other words, the first input row of the input file (1st row not
% including the header row) will match up with row 1 of the tables in this
% code, the second input will be the 2nd row of tables here, etc. Columns
% will always be variables of interest and will be named appropriately.
%
% More MATLAB documentation on getting data out of tables:
% https://www.mathworks.com/help/matlab/matlab_prog/access-data-in-a-table.html
%
% We have provided the necessary code for packaging the data into tables to
% output from and input to functions in order to keep the size of the
% function headers reasonable. It will be your responsibility to unpack and
% use data passed into functions in tables correctly. Please ensure you
% are using the preallocated varaible names and do not modify the code that
% creates the tables. We want to help you with the math, not with general
% coding

%% Clean Workspace and Housekeeping
clear
% clearvars
close all

% removes warnings for table variable names for a cleaner output
warning('OFF', 'MATLAB:table:ModifiedAndSavedVarnames')

%Add folder and subfolder path for standard Design Input Files, Model
%Functions, and Static Test Stand Data
addpath(genpath('Design Input Files'));
addpath(genpath('Model Functions'));

%% Import and Read Aircraft Design File
Design_Input_Filename = "Design Input File.xlsx";

Design_Input = readtable(Design_Input_Filename,'Sheet','Main_Input','ReadRowNames',true); %Read in Aircraft Geometry File
Count = height(Design_Input); %Number of different aircraft configurations in design input file

% Import Airfoil Data File
Airfoil = readtable(Design_Input_Filename,'Sheet','Airfoil_Data'); %Read in Airfoil Data

% Import Component Weight and Location Data File
Component_Data = readtable(Design_Input_Filename,'Sheet','Component_Data'); %Read in Component Data

% Import Benchmark Aircraft Truth Data
Benchmark = readtable(Design_Input_Filename,'Sheet','Benchmark_Truth'); %Read in Benchmark "Truth" Data for model validation only

% Import Material Properties Data
Material_Data = readtable(Design_Input_Filename,'Sheet','Materials'); %Read in prototyp material densities for weight model

%% Caluations - Atmospheric Conditions and Geometry
% US Standard Atmophere - uses provided MATLAB File Exchange function
    [rho,a,T,P,nu,z]= atmos(Design_Input.altitude_o(:,:)); 
    ATMOS = table(rho,a,T,P,nu,z); % Reorganize atmopheric conditions into a table for ease of passing into functions
    clearvars rho a T P nu z % Clear original variables now that they are in a table
    g = 9.81; %Sets constant acceleration of gravity [m/s]

% Call Wing Geometry Calcuation Function
    Plot_WingGeo_Data = 1; %Set to 0 to suppress plots for this function or 1 to output plots (Fig 100 - 199)
    WingGeo_Data = WingGeo(Design_Input,Count,Plot_WingGeo_Data); %Calculate specific wing geometry from wing configuration parameters

%% Calculations - Aerodynamics Models
% Call Wing Lift & Drag Model Function
    Plot_Wing_Data = 1; %Set to 0 to suppress plots for this function or 1 to output plots (Fig 200 - 299)
    [WingLiftModel,AoA,AoA_Count,AirfoilLiftCurve,WingLiftCurve,WingDragCurve] =...
        WingLiftDrag(Design_Input,Airfoil,Count,Benchmark,Plot_Wing_Data); 

% Call Parasite Drag Buildup Model Function
    Plot_Parasite_Data = 1; %Set to 0 to suppress plots for this function or 1 to output plots (Fig 300 - 399)
    [Parasite_Drag_Data,FF_Table,Q_Table,Re_Table] = ...
        ParasiteDrag(Design_Input,Airfoil,WingGeo_Data,ATMOS,Count,Plot_Parasite_Data);

% Call Induced Drag Model Function
    Plot_Induced_Data = 1; %Set to 0 to suppress plots for this function or 1 to output plots (Fig 400 - 499)
    [InducedDrag_Data,OswaldModel_Names] = ...
        InducedDrag(Design_Input,WingLiftModel,WingLiftCurve,WingDragCurve,WingGeo_Data,Parasite_Drag_Data,Count,Benchmark,Plot_Induced_Data);

% Call Complete Drag Polar Function
Plot_DragPolar_Data = 1; %Set to 0 to suppress plots for this function or 1 to output plots (Fig 500 - 599)
[DragPolar_mod1,DragPolar_mod2,DragPolar_mod3] = ...
    DragPolar(Parasite_Drag_Data,InducedDrag_Data,OswaldModel_Names,Design_Input,AoA_Count,WingLiftCurve,WingDragCurve,AirfoilLiftCurve,Airfoil,Benchmark,Count,Plot_DragPolar_Data);

% Call L/D Analysis Function
    Plot_LD_Data = 1; %Set to 0 to suppress plots for this function or 1 to output plots (Fig 600 - 699)
    [LD_mod1,LD_mod2,LD_mod3,LD_benchmark] = ...
        LD(Design_Input,Benchmark,DragPolar_mod1,DragPolar_mod2,DragPolar_mod3,WingLiftCurve,WingDragCurve,AoA_Count,Count,OswaldModel_Names,Plot_LD_Data);

%% Calculations - Structural Models
% Call Weight Model
    Plot_Weight_Data = 1; %Set to 0 to suppress plots for this function or 1 to output plots (Fig 700 - 799)
    [Weight_Data,CG_Data] = ...
        Weight(Design_Input,Count,WingGeo_Data,Airfoil,Material_Data,Component_Data,g,Plot_Weight_Data);

%% Calculations - Flight Dynamics Models

% Call Glide Flight Dynamics Model (must select one drag polar model L/D
% data for use in this model)
    Plot_Glide_Data = 1; %Set to 0 to suppress plots for this function or 1 to output plots (Fig 1000 - 1099)
    LD_Model = LD_mod1; %You must select one LD model output (from the LD function outputs) to utilize for this analysis
    Height = 14.5; %Launch height of glider (meters above ground level)
    apogee = zeros(Count,1); %Initializes starting height for all configurations in design input file (rows)
    apogee(:) = Height; %Creates array of starting heights for glide
    [GlideData] = GlideDescent(LD_Model, apogee, Design_Input, ATMOS, Weight_Data, WingLiftModel, WingLiftCurve,WingDragCurve,Count,Plot_Glide_Data); %Must select LD of your best model

% Call Static Stability Function
    Plot_Stability_Data = 1; %Set to 0 to suppress plots for this function or 1 to output plots (Fig 1100 - 1199)
    [Total_Weight_Stab,Empty_Weight_Stab,STAB_SM_SUMMARY,STAB_Xcg_SUMMARY,STAB_Xnp_SUMMARY,STAB_Vh_SUMMARY,STAB_Vv_SUMMARY,STAB_GLIDE_h1_SUMMARY]...
    = Stability(Design_Input, Count, CG_Data, WingGeo_Data, GlideData, WingLiftModel, Component_Data,Plot_Stability_Data);

%% Integrated data plots / Design Trade Studies Plots (Figures 2000 - 2099)
%Student Team Developed Plots for Trade Studies
% %


%% Reset default color order
set(0,'DefaultAxesColorOrder','default')