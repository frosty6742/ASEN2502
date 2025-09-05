function [LD_mod1,LD_mod2,LD_mod3,LD_benchmark] =...
    LD(Design_Input,Benchmark,DragPolar_mod1,DragPolar_mod2,DragPolar_mod3,WingLiftCurve,WingDragCurve,AoA_Count,Count,OswaldModel_Names,Plot_LD_Data)
%% Lift over Drag Analysis function Summary
% This function creates four arrays to compare the lift over drag (LD)
% estimations for three different drag polar models (mod1, mod2, mod3) with
% the benchmark aircraft's truth data L/D.  Each column in the LD.mod1,2,3
% tables represents a differnt configuration from the Design Input
% spreadsheet. Each row of the LD.mod1,2,3 tables is for the discrete
% angles of attack evaluated (from the WingLiftDrag function).
% Note that once a drag polar model is selected for use in your desgin, you
% may comment out the other models if desired.

%% Outputs:
%
% LD_mod1/2/3:
%   Table containing L/D values for each induced drag model (1/2/3) where
%   each table has columns of AoA and rows of case inputs
%
% LD_benchmark:
%   Table containing L/D values for the benchmark data where each table has
%   columns of AoA and rows of case inputs

%% Preallocate variables of interest
% NOTE: These are being stored in a structure where the second level 
% variables are the different models. The arrays within this second level
% are the arrays discussed above
LD_mod1 = zeros(Count,AoA_Count);
LD_mod2 = zeros(Count,AoA_Count);
LD_mod3 = zeros(Count,AoA_Count);
LD_benchmark = zeros(1,AoA_Count);

%% Loop through different configurations
for n = 1:Count 
% /////////////////////////////////////////////////////////////////////////
% MODIFY THIS SECTION
% /////////////////////////////////////////////////////////////////////////
    LD_mod1(n,:)=(WingLiftCurve{n,:})./DragPolar_mod1{n,:}; % brace indexing to make sure our values are in array form and not still a table as this will cause an error
    LD_mod2(n,:)=(WingLiftCurve{n,:})./DragPolar_mod2{n,:};
    LD_mod3(n,:)=(WingLiftCurve{n,:})./DragPolar_mod3{n,:};
% /////////////////////////////////////////////////////////////////////////
% END OF SECTION TO MODIFY
% /////////////////////////////////////////////////////////////////////////
end

%% Convert to tables for output
AoA_Names = {'-5', '-4', '-3', '-2', '-1', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'};
LD_mod1 = array2table(LD_mod1); % Convert to table
LD_mod1.Properties.VariableNames = AoA_Names; % Name column headers for clarity using vector defined above
LD_mod2 = array2table(LD_mod2); 
LD_mod2.Properties.VariableNames = AoA_Names;
LD_mod3 = array2table(LD_mod3);
LD_mod3.Properties.VariableNames = AoA_Names;

%% Calculate the L/D for each coefficient of lift for the benchmark aircraft
LD_benchmark(1,:)=Benchmark.CL(:)./Benchmark.CD(:);
LD_benchmark = array2table(LD_benchmark); % Convert to table for consistency
LD_benchmark.Properties.VariableNames = AoA_Names;

%% Plots for this function (Figure 600 - 699)
if Plot_LD_Data == 1

    %Lift over Drag Analysis Plots
    for n=1:Count
        figure(599+n)
        hold on
        plot(WingLiftCurve{n,:},WingLiftCurve{n,:}./WingDragCurve{n,:},'--');
        plot(WingLiftCurve{n,:},LD_mod1{n,:});
        plot(WingLiftCurve{n,:},LD_mod2{n,:});
        plot(WingLiftCurve{n,:},LD_mod3{n,:});
        %plot(WingLiftCurve{1,:},LD_benchmark{1,:},'--');
        xlabel('Coefficient of Lift (CL) [ ]');
        ylabel('L/D Ratio [ ]');
        title(['Lift over Drag Model Comparisons Config: ',Design_Input.Config(n)]);
        %legend('3D Wing','L/D Cavallo','L/D Nita-Scholz', 'Third model', 'L/D Benchmark','Location','southeast');
        legend({'3D Wing',sprintf('L/D %s',OswaldModel_Names.OswaldModel1(n)),sprintf('L/D %s',OswaldModel_Names.OswaldModel2(n)),sprintf('L/D %s',OswaldModel_Names.OswaldModel3(n))},'Location','southeast');
        grid on
        hold off
    end
% Reset default color order
set(0,'DefaultAxesColorOrder','default')
end

end