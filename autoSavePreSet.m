function autoSavePreSet(varargin)
        
        if ~ishandle(findobj('tag','UI'))
            msgbox('VSX Control does not exist');
            return
        else
            preFix = evalin('base','displayWindowTitle');
        end        
        preSet.preFix = preFix;
        
        % From the VSX, Trans, Resource, TW, TX and Event are required, so
        % other structures must be checked before saving it
        
        % keep tracking the SWversion since 3.0.7
        Resource = evalin('base','Resource');
        preSet.SWversion = Resource.SysConfig.SWversion;                      
        
        % Trans, all fields are required
        preSet.Trans = evalin('base','Trans');        
        
        % TW and TX, remove TXPD to avoid a huge preset file size
        preSet.TW = evalin('base','TW');
        TX = evalin('base','TX');
        if isfield(TX,'TXPD'), TX = rmfield(TX,'TXPD'); end
        preSet.TX = TX;
        
        % Receive
        if evalin('base','exist(''Receive'',''var'')')            
            preSet.Receive = evalin('base','Receive');
        end
        
        % Image my not be reuired 
        if evalin('base','exist(''PData'',''var'')')
            preSet.PData   = evalin('base','PData');
            preSet.Display.Height  = evalin('base','Resource.DisplayWindow(1).Position(4)');
            
            % Save colormap 
            for winNum = 1:length(Resource.DisplayWindow)
                hDisplay = Resource.DisplayWindow(winNum).figureHandle;
                preSet.Display.cMap{winNum} = get(hDisplay,'Colormap');
            end
            
            % Save custom gamma curve if ColorMapTool is used for
            % adjustment
            if evalin('base','exist(''customGamma'',''var'')')
                preSet.Display.customGamma = evalin('base','customGamma');
            end            
        end
        
        % Recon my not be reuired
        if evalin('base','exist(''Recon'',''var'')')
            preSet.Recon   = evalin('base','Recon');
            preSet.ReconInfo   = evalin('base','ReconInfo');            
        end
        
        % Proces may not be used
        if evalin('base','exist(''Process'',''var'')')            
            preSet.Process = evalin('base','Process');
            % if PTool has been called, compFactorAll should be saved
            if evalin('base','exist(''compFactorAll'',''var'')')
                preSet.compFactorAll = evalin('base','compFactorAll');
            end
        end
        
        % persf and perst for Doppler, if exist
        if evalin('base','exist(''persf'',''var'')'), preSet.Doppler.persf = evalin('base','persf'); end
        if evalin('base','exist(''persp'',''var'')'), preSet.Doppler.persp = evalin('base','persp'); end
        
        % for Personal definition
        if evalin('base','exist(''P'',''var'')') % compatiable with old script
            preSet.P = evalin('base','P');
        end
        
        % for backward compability
        if evalin('base','exist(''SFormat'',''var'')') % compatiable with old script
            preSet.SFormat = evalin('base','SFormat');
        end
        
        TGCAllSldr = findobj('tag','TGCAllSldr');
        
        % TGC 
        if evalin('base','exist(''TGC'')')
            tgcAll = findobj('tag','TGCAllSldr');
            preSet.TGCparam.TGC = evalin('base','TGC');
            preSet.TGCparam.tgcAll = get(tgcAll,'Value');
            preSet.TGCparam.SldrAll = TGCAllSldr;
            preSet.TGCparam.SPAll = SPAll;
        end
        
        % High Voltage P1 and P5
        preSet.hv1Volt = get(hv1Sldr,'Value');
        hv2Sldr = findobj('tag','hv2Sldr');
        if ishandle(hv2Sldr), preSet.hv2Volt = get(hv2Sldr,'Value'); end
        
        % Speed Correction
        Pos = UIPos(9,:,2);
        speed = findobj(f,'Position',[Pos+SG.SO,SG.SS]);
        preSet.speed = get(speed,'Value');
        
        % All VsSlider or VsButtongroup
        UI = evalin('base','UI');
        for i = 1:length(UI)
            if isfield(UI(i),'Control') && ~isempty(UI(i).Control)
                
                VsStyle = UI(i).Control{3};                                
                
                switch VsStyle
                    case 'VsSlider'
                        preSet.UI(i).txt = get(UI(i).handle(1),'String');
                        preSet.UI(i).value = get(UI(i).handle(2),'Value');
                        
                        % check ValueFormat
                        L = strcmpi('ValueFormat',UI(i).Control);
                        k = find(L,1);
                        if ~isempty(k), preSet.UI(i).VF = UI(i).Control{k+1}; else preSet.UI(i).VF = '%3.0f'; end
                        
                    case 'VsButtonGroup'
                        for k = 2:length(UI(i).handle)
                            if strcmp(get(get(UI(i).handle(1),'SelectedObject'),'tag'),get(UI(i).handle(k),'tag'))
                                preSet.UI(i).SelectedButtonNum = k-1;
                            end
                        end                        
                end                
                
            else  % if UI.Control is empty, it's customized UIControl, not Vs- style
                
                if ~isempty(UI(i).handle)
                    UIStyle = get(UI(i).handle,'Style');
                    switch UIStyle
                        case {'slider','radiobutton'}
                            preSet.UI(i).value = get(UI(i).handle,'Value');
                        case 'edit'
                            preSet.UI(i).String = get(UI(i).handle,'String');
                    end
                end
            end            
        end        
        
        assignin('base','preSet',preSet);
        

        %% LINK MODIFICATION
            fileName = strcat(preSet.P.path,preSet.P.filePrefix,'-',int2str(preSet.P.settingsNumber),preSet.P.dateStr,'.mat');
            disp(strcat('Auto-saving Preset: ',fileName));
            
            saved = 0;
            while(~saved)
                try
                    save(fileName,preSet);
                    saved = 1;
                catch %Get a new file name
                    prompt={'The file name is invalid.  Please select a new file name:'};
                    dlgTitle = 'Invalid file name';
                    numLines = 2;
                    defaultAns = {preSet.P.filePrefix};
                    
                    userInput = inputdlg(prompt,dlgTitle,numLines,defaultAns);
                    preSet.P.filePrefix = userInput{1};
                    assignin('base','preSet',preSet);

                end
            end
        cd(mainFolder)
        return
    end