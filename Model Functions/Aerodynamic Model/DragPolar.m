function [DragPolar_mod1,DragPolar_mod2,DragPolar_mod3] =...
    DragPolar(Parasite_Drag_Data,InducedDrag_Data,OswaldModel_Names,Design_Input,AoA_Count,WingLiftCurve,WingDragCurve,AirfoilLiftCurve,Airfoil,Benchmark,Count,Plot_DragPolar_Data)
%% Drag Polar Summary
% Creates an array for each drag polar model with total CD value. 
% Columns are each configuration tested, rows are variation with angle of
% attack (-5 to 12 deg).
%
% Allows comparison of different configuration's drag polars (per model).
% Once a drag polar model is chosen, other models can be commented out if
% desired.

%% Outputs:
%
% DragPolar_mod1/2/3:
%   Table containing total drag data (parasite and induced) for each
%   induced drag model (1/2/3), each table has columns of AoA and rows of
%   case inputs

%% Preallocate variables of interest
% NOTE: These are being stored in a structure where the second level 
% variables are the different models. The arrays within this second level
% are the arrays discussed above
DragPolar_mod1 = zeros(Count,AoA_Count); 
DragPolar_mod2 = zeros(Count,AoA_Count);
DragPolar_mod3 = zeros(Count,AoA_Count);


%% Loop through different configurations
for n = 1:Count
% /////////////////////////////////////////////////////////////////////////
% MODIFY THIS SECTION
% /////////////////////////////////////////////////////////////////////////
    DragPolar_mod1(n,:)=Parasite_Drag_Data.CDo(n)+((WingLiftCurve{n,:}').^2).*InducedDrag_Data.k1_mod1(n)+InducedDrag_Data.k2_mod1(n).*((WingLiftCurve{n,:}'));
    DragPolar_mod2(n,:)=Parasite_Drag_Data.CDo(n)+((WingLiftCurve{n,:}').^2).*InducedDrag_Data.k1_mod2(n)+InducedDrag_Data.k2_mod2(n).*((WingLiftCurve{n,:}'));
    DragPolar_mod3(n,:)=Parasite_Drag_Data.CDo(n)+((WingLiftCurve{n,:}').^2).*InducedDrag_Data.k1_mod3(n)+InducedDrag_Data.k2_mod3(n).*((WingLiftCurve{n,:}'));
% /////////////////////////////////////////////////////////////////////////
% END OF SECTION TO MODIFY
% /////////////////////////////////////////////////////////////////////////
end
%% Convert to tables for output
AoA_Names = {'-5', '-4', '-3', '-2', '-1', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'};
DragPolar_mod1 = array2table(DragPolar_mod1); % Convert to table
DragPolar_mod1.Properties.VariableNames = AoA_Names; % Name column headers for clarity using vector defined above
DragPolar_mod2 = array2table(DragPolar_mod2); 
DragPolar_mod2.Properties.VariableNames = AoA_Names;
DragPolar_mod3 = array2table(DragPolar_mod3);
DragPolar_mod3.Properties.VariableNames = AoA_Names;

%% Plots for this function (Figure 500 - 599)
if Plot_DragPolar_Data == 1

    % Drag Polar Comparison Curves per Configuration
    for n=1:Count
        figure(499+n)
        hold on
        plot(AirfoilLiftCurve{n,:},Airfoil{n,(24:41)});
        plot(WingLiftCurve{n,:},WingDragCurve{n,:},'--');
        plot(WingLiftCurve{n,:},DragPolar_mod1{n,:});
        plot(WingLiftCurve{n,:},DragPolar_mod2{n,:});
        plot(WingLiftCurve{n,:},DragPolar_mod3{n,:});
        %plot(Benchmark.CL(:),Benchmark.CD(:),'--'); %Only plot if doing benchmarking; Comment out if assessing design configurations
        xlabel('Coefficient of Lift (CL) [ ]');
        ylabel('Coefficient of Drag (CD) [ ]');
        title('Drag Polar Model Comparison Config: ',Design_Input.Config(n));
        %legend('Airfoil Drag Polar','Wing Drag Polar','Drag Polar-Mod1','Drag Polar-Mod2','Drag Polar-Mod3','Benchmark Drag Polar','Location','northwest');
        
        legend({
            'Airfoil Drag Polar', 
            'Wing Drag Polar', 
            sprintf('Drag Polar- %s', OswaldModel_Names.OswaldModel1(n)), 
            sprintf('Drag Polar- %s', OswaldModel_Names.OswaldModel2(n)), 
            sprintf('Drag Polar- %s', OswaldModel_Names.OswaldModel3(n))
        }, 'Location', 'northwest');

        grid on
        hold off
    end
    
    %Simplified Drag Polar comparisons for multiple configuration changes
    %broken out with different figures for each model assessed (no wing or
    %airfoil curves shown)
    
    % Oswalds Model 1 Drag Polar Comparisons
    figure(520)
    for n = 1:Count
        hold on
        plot(WingLiftCurve{n,:},DragPolar_mod1{n,:}); % brace indexing for plotting tables
        xlabel('Coefficient of Lift (CL)');
        ylabel('Coefficient of Drag (CD)');
        title('Drag Polar Configuration Comparison -', OswaldModel_Names.OswaldModel1(n));
        grid on
        hold off
    end
    legend(Design_Input.Config(:),'Location','northwest');

    % Oswalds Model 2 Drag Polar Comparisons
    figure(530)
    for n = 1:Count
        hold on
        plot(WingLiftCurve{n,:},DragPolar_mod2{n,:}); % brace indexing for plotting tables
        xlabel('Coefficient of Lift (CL)');
        ylabel('Coefficient of Drag (CD)');
        title('Drag Polar Configuration Comparison -', OswaldModel_Names.OswaldModel2(n));
        grid on
        hold off
    end
    legend(Design_Input.Config(:),'Location','northwest');
    
    %Oswalds Model 3 Drag Polar Comparisons
    figure(540)
    for n = 1:Count
        hold on
        plot(WingLiftCurve{n,:},DragPolar_mod3{n,:}); % brace indexing for plotting tables
        xlabel('Coefficient of Lift (CL)');
        ylabel('Coefficient of Drag (CD)');
        title('Drag Polar Configuration Comparison -', OswaldModel_Names.OswaldModel3(n));
        grid on
        hold off
    end
    legend(Design_Input.Config(:),'Location','northwest');

    % Reset default color order
    set(0,'DefaultAxesColorOrder','default')
end

end
