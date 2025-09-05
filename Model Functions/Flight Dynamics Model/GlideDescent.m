function [GlideData] = GlideDescent(LD, apogee, Design_Input, ATMOS, Weight_Data, WingLiftModel, WingLiftCurve,WingDragCurve, Count,Plot_Glide_Data)
%% GlideDescent Summary:
% This funciton is meant to take in and process L/D data and boost apogee
% to find a best glide range, along with wind data to find actual glide 
% range. These assume no wind and an instantanious change to best glide
% velocity and trim. Note that while there are three oswalds models and
% thus three L/D curves, this function only takes one in. This is because
% at this point, a final oswalds model should be chosen, and the L/D curve
% for that model should be the only one passed in to this funciton.
%
% Also note that the heading for best glide should be the apopgee heading
% (as there is no wind, so no reason for the heading to change), while for
% actual glide we will assume the aircraft immediatly turns directly into
% the true wind (inertial wind direction) and holds that heading

%% Outputs:
% GlideData:
%   A table of scalar values of the best glide range from apogee in [m] and
%   key flight parameters for that best glide range including glide angle
%   (theta), CL for best glide (CL_LDmax), velocity at best glide 
%   (V_LDmax), sink velocity (Vsink), and the AoA required for best glide
%   (AoA_LDmax) for each case input.

%% Preallocate variables of interest
bestGlide = zeros(Count,1); % Best glide range from apogee [m]
LDmax = zeros(Count,1); % L/D max value used []
theta = zeros(Count,1); % Glide angle [degrees]
CL_LDmax = zeros(Count,1); % CL required for best glide []
V_LDmax = zeros(Count,1); % Velocity required for best glide [m/s]
Vsink = zeros(Count,1); % Sink rate at best glide [m/s]
AoA_LDmax = zeros(Count,1); % AoA required for best glide [degrees]
WingLoad = zeros(Count,1); %Wing Loading for each configuration [N/m^2]

%% Loop through different configurations
for n = 1:Count
    % /////////////////////////////////////////////////////////////////////////
    % MODIFY THIS SECTION
    % /////////////////////////////////////////////////////////////////////////
    %% Find L/D max
    [~, iMax] = max(LD{n,:});%Finds index of maximum L/D value
    iPick = iMax;
    LDmax(n) = LD{n,iPick}; %Pulls L/D max for iMax

    %% Find best glide range
    bestGlide(n) = apogee(n)*LDmax(n); %Post-apogee glide range

    %% GLide angle
    theta(n) = atand(1/LDmax(n)); %From horizon, positive is downward [deg]

    %% Find Best Glide CL and Velocity
    % Find 3D Wing L/D max
    WingLD(n,:) = WingLiftCurve{n,:}./WingDragCurve{n,:}; %Calculates Wing only L/D curve
    [~, iMax_Wing] = max(WingLD(n,:));%Finds index of wing maximum L/D value
    %Sets best glide CL and Velocity
    CL_LDmax(n) = WingLiftCurve{n, iMax_Wing}; %Assume model poorly identifies CL where L/D max occurs; using wing CL for wing L/D max as a better approximation
    V_LDmax(n) = sqrt(2*(Weight_Data.W_empty(n)*cosd(theta(n)))/(ATMOS.rho(n)*CL_LDmax(n)*Design_Input.Sref_w(n))); %Calculate velocity for best glide (L/D max)
    Vsink(n) = V_LDmax(n)*sind(theta(n)); %Calculates sink rate at best glide (L/D max)

    AoA_LDmax(n) = CL_LDmax(n)/WingLiftModel.a(n) + WingLiftModel.AoA_0(n); %Uses 3D wing CL for best L/D max rather than whole aircraft predicted CL for L/D max to account for poor modeling of low RE induced drag rise

    %% Find Wing Loading
    WingLoad(n) = (Weight_Data.W_empty(n))/Design_Input.Sref_w(n);
    
    % /////////////////////////////////////////////////////////////////////////
    % END OF SECTION TO MODIFY
    % /////////////////////////////////////////////////////////////////////////
end

%% Convert to tables for output
GlideData = table(bestGlide, LDmax, theta, CL_LDmax, V_LDmax, Vsink, AoA_LDmax, WingLoad);

%% Plots for this function (Figure 1000 - 1099)
    % Some setup to make plots more readable in color, look up the
    % documentation for 'cmap' for other color map options
    cmap = colormap(lines(Count));
    set(0,'DefaultAxesColorOrder',cmap)
    set(gca(),'ColorOrder',cmap);

if Plot_Glide_Data == 1

    % Glide Flight 2D Profile Plots
    figure(1000)
    for n = 1:Count
        plot([0, GlideData.bestGlide(n)], [apogee(n), 0],...
            color = cmap(n, :), DisplayName=[Design_Input.Properties.RowNames{n}, ' best glide'])
        if n == 1
            hold on
        end
    end
    xlabel('Glide distance [m]');
    ylabel('Height [m]');
    title('Best Glide Plots');
    legend();
    grid on
    hold off

    %Reset default color order
    set(0,'DefaultAxesColorOrder','default')
end

end

