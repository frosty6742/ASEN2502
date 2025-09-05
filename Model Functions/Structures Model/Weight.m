function [Weight_Data,CG_Data] = Weight(Design_Input,Count,WingGeo_Data,Airfoil,Material_Data,Component_Data,g,Plot_Weight_Data)
%% Weight Model Summary 
% This function pulls in the material properties from the Data Input file
% (Material_Data table) and creates a weight model estimate for a given
% aircraft configuration based on the Design_Input, WingGeo_Data, and
% Airfoil tables.  Note that you will need to vary this model depending on
% how you choose to fabricate your prototype as the material choices coded
% below may vary for your prototype.

%% Outputs:
%
% Weight_Data:
%   Table containing total weight and a component breakdown of
%   contributions to that total (columns), for each input case (rows)
%
% CG_Data:
%   Table containing overall CG and a component breakdown of contributions
%   to that total (columns), for each input case (rows)s

%% Preallocate variables of interest
Wo = zeros(Count, 1); % Total Weight [N]
W_empty = zeros(Count, 1); % Empty Weight [N]
W_nose = zeros(Count, 1); % Nosecone weight [N]
W_f = zeros(Count, 1); % Fusalage weight [N]
W_w = zeros(Count, 1); % Wing weight [N]
W_h1 = zeros(Count, 1); % Horizontal tail 1 weight [N]
W_v1 = zeros(Count, 1); % Vertical tail 1 weight [N]
W_v2 = zeros(Count, 1); % Vertical tail 2 weight [N]
W_pay = zeros(Count, 1); % Main Payload weight [N]
W_ballast = zeros(Count, 1); % Ballast Weight [N]

%All CG distances relative to nose of aircraft
CG_tot = zeros(Count, 1); % Overall CG [m]
CG_empty = zeros(Count, 1); % Overall Empty CG [m]
CG_nose = zeros(Count, 1); % Nosecone CG [m]
CG_f = zeros(Count, 1); % Fusalage CG [m]
CG_w = zeros(Count, 1); % Wing CG [m]
CG_h1 = zeros(Count, 1); % Horizontal tail 1 CG [m]
CG_v1 = zeros(Count, 1); % Vertical tail 1 CG [m]
CG_v2 = zeros(Count, 1); % Vertical tail 2 CG [m]
CG_pay = zeros(Count, 1); % Payload CG [m]
CG_ballast = zeros(Count, 1); % Ballast CG [m]


%% Loop through different configurations
for n = 1:Count
% /////////////////////////////////////////////////////////////////////////
% MODIFY THIS SECTION
% /////////////////////////////////////////////////////////////////////////
    %Weight Factor for Glue & Tape
    Weight_Factor = 1.05; % Percent increase over material weight to account for glue, fastners, etc.

    %Weight of Nosecone
    if Component_Data.m_nose(n) == 0 %Determine if modeling or using fixed measured data from Design Input
        W_nose(n) = 0; %Approximation method assumes this weight in part of fuselage weight (assumes same material)
        CG_nose(n) = 0; %Approximation method assumes this is part of fuselage component
    else
        W_nose(n) = (Component_Data.m_nose(n)/1000)*g; %Direct measurement & input of fabricated weight
        CG_nose(n) = Component_Data.Xcg_nose(n); %Direct measurement and input of CG
    end
    
    %Fuselage Weight & CG Estimate
    if Component_Data.m_fuse(n) == 0 %Determine if modeling or using fixed measured data from Design Input
        Fuse_Material = char(Design_Input.Fuse_Mat(n)); %Pulls material type from design input spreadsheet
        if strcmp(Fuse_Material,'rhoA_foamboard')
            W_f(n)=(Material_Data{1,Fuse_Material}*Design_Input.Swet_f(n)*g)*Weight_Factor; %Foamboard weight based on area not volume
        else
            W_f(n)=(Material_Data{1,Fuse_Material}*Design_Input.Swet_f(n)*Design_Input.Thick_f(n)*g)*Weight_Factor; % Non-foamboard material weight based on volume and density of material [N]
        end
    else
        W_f(n)=(Component_Data.m_fuse(n)/1000)*g; %Direct measurement & input of fabricated weight
    end
    
    if Component_Data.Xcg_fuse(n) == 0
       CG_f(n) = Design_Input.Length_f(n)/2; %Assumes location of fuselage CG is centroid of cylinder (m)
    else
        CG_f(n) = Component_Data.Xcg_fuse(n); %Direct measurement and input of CG
    end

    %Wing Weight Estimate
    if Component_Data.m_wing(n) == 0 %Determine if modeling or using fixed measured data from Design Input
        Wing_Material = char(Design_Input.Wing_Mat(n)); %Pulls material type from design input spreadsheet
        if strcmp(Wing_Material,'rhoA_foamboard')
            W_w(n) = (Material_Data{1,Wing_Material}*Design_Input.Sref_w(n)*g)*Weight_Factor; %Approximates using area of foamboard (assumes flat plate wing)
        else
            W_w(n)=(Material_Data{1,Wing_Material}*Design_Input.Sref_w(n)*Airfoil.Thick_w(n)*WingGeo_Data.MAC_w(n)*g)*Weight_Factor; %Approximates using volume
        end
    else
        W_w(n) = (Component_Data.m_wing(n)/1000)*g; %Direct measurement & input of fabricated weight
    end
    
    if Component_Data.Xcg_wing(n) == 0 %Determine if modeling or using fixed measured data from Design Input
        CG_w(n) = Component_Data.X_LE_wing(n)+WingGeo_Data.x_MAC_w(n)+.3*WingGeo_Data.MAC_w(n); %Assumes location of wing CG is at LE wing root + distance to LE MAC + 30%*MAC (m)
    else
        CG_w(n) = Component_Data.Xcg_wing(n); %Direct measurement and input of CG
    end

    %Horz Tail 1 Weight Estimate
    if Component_Data.m_h1(n) == 0 %Determine if modeling or using fixed measured data from Design Input
        h1_Material = char(Design_Input.h1_Mat(n));
        if strcmp(h1_Material,'rhoA_foamboard')
            W_h1(n)=(Material_Data{1,h1_Material}*Design_Input.Sref_h1(n)*g)*Weight_Factor; %Approximates using area of foamboard (assumes flat plate wing)
        else
            W_h1(n)=(Material_Data{1,h1_Material}*Design_Input.Sref_h1(n)*Design_Input.MAC_h1(n)*Airfoil.Thick_h1(n)*g)*Weight_Factor; %Approximates using volume
        end
    else
        W_h1(n) = (Component_Data.m_h1(n)/1000)*g; %Direct measurement & input of fabricated weight
    end
    
    if Component_Data.Xcg_h1(n) == 0 %Determine if modeling or using fixed measured data from Design Input   
        CG_h1(n) = Component_Data.X_LE_h1(n)+.3*Design_Input.MAC_h1(n); %Assumes location of horz tail CG is at LE horz tail root + 30%*MAC (m)
    else
        CG_h1(n) = Component_Data.Xcg_h1(n); %Direct measurement & input of CG
    end

    %Vert Tail 1 Weight Estimate
    if Component_Data.m_v1(n) == 0 %Determine if modeling or using fixed measured data from Design Input
        v1_Material = char(Design_Input.v1_Mat(n));
        if strcmp(v1_Material,'rhoA_foamboard')
            W_v1(n)=(Material_Data{1,v1_Material}*Design_Input.Sref_v1(n)*g)*Weight_Factor; %Approximates using area of foamboard (assumes flat plate wing)
        else
            W_v1(n)=(Material_Data{1,v1_Material}*Design_Input.Sref_v1(n)*Design_Input.MAC_v1(n)*Airfoil.Thick_v1(n)*g)*Weight_Factor; %Approximates using volume
        end
    else
        W_v1(n) = (Component_Data.m_v1(n)/1000)*g; %Direct measurement & input of fabricated weight
    end
    
    if Component_Data.Xcg_v1(n) == 0 %Determine if modeling or using fixed measured data from Design Input   
        CG_v1(n) = Component_Data.X_LE_v1(n)+.3*Design_Input.MAC_v1(n); %Assumes location of vert tail CG is at LE vert tail root + 30%*MAC (m)
    else
        CG_v1(n) = Component_Data.Xcg_v1(n); %Direct measurement & input of CG
    end

    %Vert Tail 2 Weight Estimate
    if Component_Data.m_v2(n) == 0 %Determine if modeling or using fixed measured data from Design Input
        v2_Material = char(Design_Input.v2_Mat(n));
        if strcmp(v2_Material,'rhoA_foamboard')
            W_v2(n)=(Material_Data{1,v2_Material}*Design_Input.Sref_v2(n)*g)*Weight_Factor; %Approximates using area of foamboard (assumes flat plate wing)
        else
            W_v2(n)=(Material_Data{1,v2_Material}*Design_Input.Sref_v2(n)*Design_Input.MAC_v2(n)*Airfoil.Thick_v2(n)*g)*Weight_Factor; %Approximates using volume
        end
    else
        W_v2(n) = (Component_Data.m_v2(n)/1000)*g; %Direct measurement & input of fabricated weight
    end
        
    if Component_Data.Xcg_v2(n) == 0 %Determine if modeling or using fixed measured data from Design Input   
        CG_v2(n) = Component_Data.X_LE_v2(n)+.3*Design_Input.MAC_v2(n); %Assumes location of vert tail CG is at LE vert tail root + 30%*MAC (m)
    else
        CG_v2(n) = Component_Data.Xcg_v2(n); %Direct measurement & input of CG
    end
        
    %Payload Weight (Must be manually defined as required)
    W_pay(n) = (Component_Data.m_pay(n)/1000)*g; %Payload weight as required (Netwtons)
    CG_pay(n) = Component_Data.Xcg_pay(n); %Payload CG location manually defined in design input file
        
    %Ballast Weight (as required)
    W_ballast(n) = (Component_Data.m_ballast(n)/1000)*g; %Ballast Weight as required (Newtons)
    CG_ballast(n) = Component_Data.Xcg_ballast(n); %Ballast CG location manually defined in design input file


    %Total Empty Weight & CG Location
    W_empty(n)=W_nose(n)+W_f(n)+W_w(n)+W_h1(n)+W_v1(n)+W_v2(n)+W_ballast(n);
    CG_empty(n)=(W_nose(n)*CG_nose(n)+W_f(n)*CG_f(n)+W_w(n)*CG_w(n)+W_h1(n)*CG_h1(n)+W_v1(n)*CG_v1(n)+W_v2(n)*CG_v2(n)+W_ballast(n)*CG_ballast(n))/W_empty(n);
    
    %Total Weight & CG Location w/ payload weight
    Wo(n)=W_empty(n)+W_pay(n);
    CG_tot(n)=(W_empty(n)*CG_empty(n)+W_pay(n)*CG_pay(n))/Wo(n);

    % %Total Weight & CG Location w/ 75% of initial water weight
    % Wo_75(n)=W_empty(n)+W_water_75(n);
    % CG_tot_75(n)=(W_empty(n)*CG_empty(n)+W_water_75(n)*CG_water_75(n))/Wo_75(n);
    % 
    % %Total Weight & CG Location w/ 50% of initial water weight
    % Wo_50(n)=W_empty(n)+W_water_50(n);
    % CG_tot_50(n)=(W_empty(n)*CG_empty(n)+W_water_50(n)*CG_water_50(n))/Wo_50(n);
    % 
    % %Total Weight & CG Location w/ 75% of initial water weight
    % Wo_25(n)=W_empty(n)+W_water_25(n);
    % CG_tot_25(n)=(W_empty(n)*CG_empty(n)+W_water_25(n)*CG_water_25(n))/Wo_25(n);

% /////////////////////////////////////////////////////////////////////////
% END OF SECTION TO MODIFY
% /////////////////////////////////////////////////////////////////////////
end

%% Oraganize into tables for output
Weight_Data= table(Wo, W_empty, W_nose, W_f, W_w, W_h1, W_v1, W_v2, W_pay, W_ballast);
CG_Data = table(CG_tot, CG_empty, CG_nose, CG_f, CG_w, CG_h1, CG_v1, CG_v2, CG_pay, CG_ballast);

%% Plots for this function (Figure 700 - 799)
if Plot_Weight_Data == 1

    %Aircraft component weight breakdown
    y = zeros(Count,8);
    y = [W_nose W_f W_w W_h1 W_v1 W_v2 W_pay W_ballast];
    figure(700)
    if Count == 1
        x = Design_Input.Config(1);
        Wbar = bar(x,y,"stacked",'FaceColor','flat');
    else
        Wbar = bar(y,'stacked','FaceColor','flat');
    end
    %Set color for each segment
        Wbar(1).CData = [0.31, 0.31, 0.31];  % dark grey
        Wbar(2).CData = [0.64, 0.08, 0.18];  % red
        Wbar(3).CData = [0.47, 0.67, 0.19];  % green
        Wbar(4).CData = [0.25, 0.44, 0.86];  % blue
        Wbar(5).CData = [0.94, 0.57, 0.18];  % orange
        Wbar(6).CData = [0.66, 0.31, 0.64];  % purple
        Wbar(7).CData = [0.95, 0.77, 0.06];  % yellow
        Wbar(8).CData = [0.09, 0.75, 0.81];  % cyan
    xticklabels(string(Design_Input.Config));
    grid on
    xlabel('Design Configuration');
    ylabel('Weight (N)');
    legend('W nose','W fuse','W wing','W h1','W v1','W v2','W payload','W ballast');
    title('Design Configuration Total Weight Buildup')

end
    % Reset default color order
    set(0,'DefaultAxesColorOrder','default')
end
