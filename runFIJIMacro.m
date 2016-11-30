function runFIJIMacro ()

    Miji(false)
    %[MacroName,PathMacro]= uigetfile('*','Choose the macro'); 
    %a = strcat(PathMacro,MacroName);
    a = '/sw/pkg/MATLAB/R2015b/TrackingProject/CombineScanR_singleChannelMultiWells.ijm';
    MIJ.run('Install...',strcat('install=',a));
    IJ=ij.IJ();
    IJ.runMacroFile(a);
    
end
