function [InducedDrag_Data, OswaldModel_Names] =...
    InducedDrag(Design_Input,WingLiftModel,WingLiftCurve,WingDragCurve,WingGeo_Data,Parasite_Drag_Data,Count,Benchmark,Plot_Induced_Data)
%% Induced Drag Model Function Summary
% This function evaluates different Oswalds Efficiency Factor models for 
% use in your drag polar model.  It compiles and outputs a variables table
% for three different Oswalds models (mod1, mod2, mod3).  For each Oswalds
% model, the Oswalds Efficiencty Factor (eo_mod1,2,3), and the k1 values
% (k1_mod1,2,3) are outputted in the InducedDrag_Data table.  Note that
% depending on the Oswalds models chosen to evaluate, you may or may not
% need information from teh WingGeo_Data table from the WingGeo function.
% Additionally, this code supports the calculation of the k2 values for
% evaluating non-symmetric airfoil design, but is not required.

%% Outputs:
%
% InducedDrag_Data:
%   Table containing oswalds info and calculated k1 and k2 values for three
%   different models for oswalds (denoted by suffixes _mod1, _mod2, and
%   _mod3)(columns) for each input from the design input spreadsheet (rows)


%% Preallocate variables of interest
eo_mod1 = zeros(Count, 1); % Oswalds for Model #1
eo_mod2 = zeros(Count, 1); % Oswalds for Model #2
eo_mod3 = zeros(Count, 1); % Oswalds for Model #3
k1_mod1 = zeros(Count, 1); % k1 for Model #1
k1_mod2 = zeros(Count, 1); % k1 for Model #2
k1_mod3 = zeros(Count, 1); % k1 for Model #3
k2_mod1 = zeros(Count, 1); % k2 for Model #1
k2_mod2 = zeros(Count, 1); % k2 for Model #2
k2_mod3 = zeros(Count, 1); % k2 for Model #3

% NOTE: k2 values not required if only symmetric airfoils used; however,
% this version of the code includes it as an option

%% Loop through different configurations
for n = 1:Count 
% /////////////////////////////////////////////////////////////////////////
% MODIFY THIS SECTION
% /////////////////////////////////////////////////////////////////////////
    %Find CL min Drag value of wing drag polar to estimate k2
    [CD_min,CD_min_index] = min(WingDragCurve{n,:});
    CL_minD = WingLiftCurve{n,CD_min_index};

    %Cavallo Oswalds Model 1 (Baseline required)
    Model1_Name = 'Cavallo'; %Name of first Oswald's Model
    eo_mod1(n) = 1.78*(1-0.045*Design_Input.AR_w(n)^0.68)-0.64;
    k1_mod1(n) =  1/(pi*eo_mod1(n)*Design_Input.AR_w(n));
    k2_mod1(n) = -2*k1_mod1(n)*CL_minD;

    %Student Option Oswalds Model 2 
    Model2_Name = 'Nita-Scholz'; %Name of second Oswald's Model
    k_ef = 1-2*(Design_Input.Dia_f(n)/WingGeo_Data.b_w(n))^2;%fuselage impacts
    k_eDo = 0.804; %Statistical accounting for shifts in zero lift drag.Jet = 0.873,business jet=0.864,turboprop=0.804, gen aviation=0.804
    k_eM = 1; %compressibility correction for mach; if M<0.3,=1
    eo_mod2(n) = WingLiftModel.e(n)*k_ef*k_eDo*k_eM; %Oswalds Estimate
    k1_mod2(n) =  1/(pi*eo_mod2(n)*Design_Input.AR_w(n));
    k2_mod2(n) = -2*k1_mod2(n)*CL_minD;
   
    %Student Option Oswalds Model 3
    Model3_Name = 'Kroo'; %Name of third Oswald's Model
    s = 1-2*(Design_Input.Dia_f(n)/WingGeo_Data.b_w(n))^2; %Fuselage impacts
    Q = 1/(WingLiftModel.e(n)*s); %Inviscid portion
    P = 0.38*Parasite_Drag_Data.CDo(n); %Viscous portion, 0.38 value based on test data for DC-8, DC-9 aircraft
    eo_mod3(n) = 1/(Q+P*pi*Design_Input.AR_w(n)); %Oswalds Estimate
    k1_mod3(n) =  1/(pi*eo_mod3(n)*Design_Input.AR_w(n));
    k2_mod3(n) = -2*k1_mod3(n)*CL_minD;

% /////////////////////////////////////////////////////////////////////////
% END OF SECTION TO MODIFY
% /////////////////////////////////////////////////////////////////////////   
end

%% Oraganize into table for output
InducedDrag_Data = table(eo_mod1, eo_mod2, eo_mod3, k1_mod1, k1_mod2, k1_mod3, k2_mod1, k2_mod2, k2_mod3);
OswaldModel_Names = table(string(Model1_Name),string(Model2_Name), string(Model3_Name),'VariableNames',["OswaldModel1","OswaldModel2","OswaldModel3"]);

 %Isolated Induced Drag Coefficients
    CDi_w = (WingLiftCurve{1,:}').^2/...
        (pi*WingLiftModel.e(1)*Design_Input.AR_w(1));
    CDi_mod1 = (WingLiftCurve{1,:}').^2.*InducedDrag_Data.k1_mod1(n)...
        +InducedDrag_Data.k2_mod1(1).*((WingLiftCurve{1,:}'));
    CDi_mod2 = (WingLiftCurve{1,:}').^2.*InducedDrag_Data.k1_mod2(n)...
        +InducedDrag_Data.k2_mod2(1).*((WingLiftCurve{1,:}'));
    CDi_mod3 = (WingLiftCurve{1,:}').^2.*InducedDrag_Data.k1_mod3(n)...
        +InducedDrag_Data.k2_mod3(1).*((WingLiftCurve{1,:}'));
    CDi_benchmark = Benchmark.CD-min(Benchmark.CD); % subtract off minCD to get CDi

%% Plots for this function (Figure 400 - 499)
if Plot_Induced_Data == 1
    
    % CDi comparison for different Oswalds Models
    for n=1:Count
        figure(399+n)
        hold on
        plot(WingLiftCurve{n,:},CDi_w,'--');
        plot(WingLiftCurve{n,:},CDi_mod1);
        plot(WingLiftCurve{n,:},CDi_mod2);
        plot(WingLiftCurve{n,:},CDi_mod3);
        %plot(WingLiftCurve{1,:},CDi_benchmark,'--');
        xlabel('Coefficient of Lift (CL) [ ]');
        ylabel('Induced Drag (CDi) [ ]');
        title(['Induced Drag (CDi) Modeling Config: ', Design_Input.Config(n)]);
        %legend('3D Wing',Model1_Name,Model2_Name,Model3_Name,'Benchmark','Location','southeast');
        legend('3D Wing',Model1_Name,Model2_Name,Model3_Name,'Location','southeast');
        grid on
        hold off
    end
    
    % Reset default color order
    set(0,'DefaultAxesColorOrder','default')
end

end


