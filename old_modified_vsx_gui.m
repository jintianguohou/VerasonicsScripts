function vsx_gui
%% Start of verasonics code
%
% Copyright 2001-2016 Verasonics, Inc.  All world-wide rights and remedies under all intellectual property laws and industrial property laws are reserved.  Verasonics Registered U.S. Patent and Trademark Office.
%
% VSX_GUI  This gui is opened by the main VSX program and allows control of various
% acquisition and processing parameters.

%This needs to be renamed to vsx_gui and put into the utilities folder to
%work correctly and enable many parts of the script.

% Close any previously opened GUI windows.
delete(findobj('tag','UI'));
% Initialize and hide the GUI as it is being constructed.
ScrnSize = get(0,'ScreenSize');
Bkgrnd = [0.8 0.8 0.8];
f = figure('Visible','off',...  %'Units','normalized',...
    'Position',[ScrnSize(3)-500,(ScrnSize(4)-620)/2,450,620],... %'Position',[0.7,0.25,0.25,0.50],...
    'Name','VSX Control',...
    'Color',Bkgrnd,...
    'NumberTitle','off',...
    'MenuBar','none', ...
    'Resize','on', ...
    'tag','UI');
set(f,'CloseRequestFcn',{@closefunc});
set(f,'DefaultUicontrolBackgroundColor',Bkgrnd)

% Are we running with hardware? Get state of VDAS variable and simulateMode.
if evalin('base','exist(''VDAS'',''var'')')
    VDAS = evalin('base','VDAS');
else VDAS = 0;
end

% Determine simulateMode value and whether there is are DisplayWindow frames.
simMode = 0; % set default
nfrms = 0;
dsplywin = 0;
if evalin('base','exist(''Resource'',''var'')')
    if evalin('base','isfield(Resource,''Parameters'')');
        if evalin('base','isfield(Resource.Parameters,''simulateMode'')');
            simMode = evalin('base','Resource.Parameters.simulateMode');
        end
    end
    if evalin('base','isfield(Resource,''DisplayWindow'')')
        dsplywin = 1;
        if evalin('base','isfield(Resource.DisplayWindow,''numFrames'')');
            nfrms = evalin('base','Resource.DisplayWindow(1).numFrames');
        else nfrms = 1;
        end
    end
end

% ***** Create the GUI components *****
% Define UIPos, which contains the default GUI positions - three columns of 10 controls. The x,y
%    locations increment up columns, with each column being a separate page. The origin
%    specified by UIPos is the lower left corner of a virtual box that encloses the control.
UIPos = zeros(10,2,3);
UIPos(:,1,1) = 0.0625;
UIPos(:,1,2) = 0.375;
UIPos(:,1,3) = 0.6875;
UIPos(:,2,1) = 0.0:0.1:0.9;
UIPos(:,2,2) = 0.0:0.1:0.9;
UIPos(:,2,3) = 0.0:0.1:0.9;
assignin('base','UIPos',UIPos);
% Define slider group offsets and sizes. All units are normalized.
SG = struct('TO',[0.0,0.0975],...   % title offset
    'TS',[0.25,0.025],...   % title size
    'TF',0.8,...            % title font size
    'SO',[0.0,0.06],...     % slider offset
    'SS',[0.25,0.031],...   % slider size
    'EO',[0.075,0.031],...   % edit box offset
    'ES',[0.11,0.031]);     % edit box size
assignin('base','SG',SG);
% Define pushbutton offsets and sizes.
PB = struct('FS',0.3,...            % font size
    'BO',[0.025,0.04],...   % button offset
    'BS',[0.2,0.07]);       % button size
assignin('base','PB',PB);
% Define buttonGroup offsets and sizes for a single button.
BG = struct('TFS',0.25,...          % button group title font size
    'BGO',[0,0.025],... % button group offset (BGO(2) is 0.1 - BGS(2))
    'BGS',[0.25,0.075],...   % button group size
    'BI',0.030,...          % button increment (in units of full window)
    'BO',[0.1,0.2],...      % button offset (units relative to BGS box)
    'BS',[0.9,0.4],...      % button size      "    "    "    "     "
    'BFS',0.8);             % button font size
assignin('base','BG',BG);

%
% Titles
Pos = UIPos(10,:,1);
uicontrol('Style','text','String',...
    'Front End',...
    'Units','normalized',...
    'Position',[Pos+[0.0 0.06],0.25,0.03],...
    'FontUnits','normalized',...
    'FontSize',0.8,...
    'Tag','title1',...
    'FontWeight','bold');
uicontrol('Style','text','String',...
    'Processing',...
    'Units','normalized',...
    'Position',[Pos+[0.3175 0.06],0.25,0.03],...
    'FontUnits','normalized',...
    'FontSize',0.8,...
    'Tag','title2',...
    'FontWeight','bold');
uicontrol('Style','text','String',...
    'Display',...
    'Units','normalized',...
    'Position',[Pos+[0.625 0.06],0.25,0.03],...
    'FontUnits','normalized',...
    'FontSize',0.8,...
    'Tag','title3',...
    'FontWeight','bold');

% Transducer connector
if evalin('base','exist(''numBoards'',''var'')')
    nb = evalin('base','numBoards');
    if nb == 4
        tcx = 0.09;
        tcy = 0.94;
        tc = 1;
        if evalin('base','exist(''Resource'',''var'')')&&evalin('base','isfield(Resource.Parameters,''connector'')')
            tc = evalin('base','Resource.Parameters.connector');
        end
        TcString = ['Using Connector ',num2str(tc,'%1.0f')];
        tchndl = uicontrol('Style','text','String',TcString,...
            'Units','normalized',...
            'Position',[tcx tcy 0.2 0.018],...
            'FontUnits','normalized',...
            'FontSize',0.8,...
            'BackgroundColor',[1.0,0.8,0.4]);
    end
end

% TGC Controls
Pos = UIPos(9,:,1);
tgcSldrInc = 0.0325; %Increment between TGC sliders

tgctxt = uicontrol('Style','text','String','TGC',...
    'Units','normalized',...
    'Position',[Pos+SG.TO,SG.TS],...
    'FontUnits','normalized',...
    'FontSize',0.8,...
    'Tag','tgctxt',...
    'FontWeight','bold');


nTGC = 1; % default value
SP = [0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5];
TGCAllSldr(nTGC) = 0; % TGCAllSldr is used to save the slider value
SPAll(nTGC) = 1.0;

% - set sliders to positions specified in TGC.CntlPts, if it exists.
if evalin('base','exist(''TGC'',''var'')')
    TGC = evalin('base','TGC'); 
    SP = double(TGC(1).CntrlPts)/1023;

    % if more than 1 TGC, have a dropdown menu for TGC numbers
    L = length(TGC);
    if  L > 1
        set(tgctxt,'Position',[Pos+SG.TO-[0.05,-0.003],SG.TS]);
        TGCstring = cell(L,1);
        for s = 1:L
            TGCAllSldr(s) = 0; % TGCAllSldr is used to save the slider value
            SPAll(s) = 1;
            TGCstring{s} = num2str(s);
        end
        TGCMenu = uicontrol('Style','popupmenu',...
            'Units','normalized',...
            'Position',[Pos+SG.TO+[0.125,0.01],0.125,0.02],...
            'String',TGCstring,...
            'FontUnits','normalized',...
            'FontSize',0.9,...
            'Tag','TGCnum',...
            'Callback',@TGCselect);
    end
end

    function TGCselect(hObject,~)        
        nTGC = get(hObject,'Value');TGC = evalin('base','TGC');
        tgcValue = double(TGC(nTGC).CntrlPts)/1023;
        SP = tgcValue/SPAll(nTGC);
        set(tgc1,'Value',tgcValue(1)); assignin('base', 'tgc1',TGC(nTGC).CntrlPts(1));
        set(tgc2,'Value',tgcValue(2)); assignin('base', 'tgc2',TGC(nTGC).CntrlPts(2));
        set(tgc3,'Value',tgcValue(3)); assignin('base', 'tgc3',TGC(nTGC).CntrlPts(3));
        set(tgc4,'Value',tgcValue(4)); assignin('base', 'tgc4',TGC(nTGC).CntrlPts(4));
        set(tgc5,'Value',tgcValue(5)); assignin('base', 'tgc5',TGC(nTGC).CntrlPts(5));
        set(tgc6,'Value',tgcValue(6)); assignin('base', 'tgc6',TGC(nTGC).CntrlPts(6));
        set(tgc7,'Value',tgcValue(7)); assignin('base', 'tgc7',TGC(nTGC).CntrlPts(7));
        set(tgc8,'Value',tgcValue(8)); assignin('base', 'tgc8',TGC(nTGC).CntrlPts(8));
        set(tgcAll,'Value',TGCAllSldr(nTGC));
        assignin('base','action','tgc');
    end


Pos = Pos+SG.SO;
tgc1 = uicontrol(f,'Style','slider',...
    'Max',1.0,'Min',0,'Value',SP(1),...
    'SliderStep',[0.05 0.2],...
    'Units','normalized',...
    'Position',[Pos,SG.SS],...
    'BackgroundColor',Bkgrnd-0.05,...
    'Tag','tgc1Sldr',...
    'Callback',{@tgc1_Callback});
tgc2 = uicontrol(f,'Style','slider',...
    'Max',1.0,'Min',0,'Value',SP(2),...
    'SliderStep',[0.05 0.2],...
    'Units','normalized',...
    'Position',[Pos+[0 -tgcSldrInc],SG.SS],...
    'Tag','tgc2Sldr',...
    'BackgroundColor',Bkgrnd-0.05,...
    'Callback',{@tgc2_Callback});
tgc3 = uicontrol(f,'Style','slider',...
    'Max',1.0,'Min',0,'Value',SP(3),...
    'SliderStep',[0.05 0.2],...
    'Units','normalized',...
    'Position',[Pos+[0 -2*tgcSldrInc],SG.SS],...
    'Tag','tgc3Sldr',...
    'BackgroundColor',Bkgrnd-0.05,...
    'Callback',{@tgc3_Callback});
tgc4 = uicontrol(f,'Style','slider',...
    'Max',1.0,'Min',0,'Value',SP(4),...
    'SliderStep',[0.05 0.2],...
    'Units','normalized',...
    'Position',[Pos+[0 -3*tgcSldrInc],SG.SS],...
    'Tag','tgc4Sldr',...
    'BackgroundColor',Bkgrnd-0.05,...
    'Callback',{@tgc4_Callback});
tgc5 = uicontrol(f,'Style','slider',...
    'Max',1.0,'Min',0,'Value',SP(5),...
    'SliderStep',[0.05 0.2],...
    'Units','normalized',...
    'Position',[Pos+[0 -4*tgcSldrInc],SG.SS],...
    'Tag','tgc5Sldr',...
    'BackgroundColor',Bkgrnd-0.05,...
    'Callback',{@tgc5_Callback});
tgc6 = uicontrol(f,'Style','slider',...
    'Max',1.0,'Min',0,'Value',SP(6),...
    'SliderStep',[0.05 0.2],...
    'Units','normalized',...
    'Position',[Pos+[0 -5*tgcSldrInc],SG.SS],...
    'Tag','tgc6Sldr',...
    'BackgroundColor',Bkgrnd-0.05,...
    'Callback',{@tgc6_Callback});
tgc7 = uicontrol(f,'Style','slider',...
    'Max',1.0,'Min',0,'Value',SP(7),...
    'SliderStep',[0.05 0.2],...
    'Units','normalized',...
    'Position',[Pos+[0 -6*tgcSldrInc],SG.SS],...
    'Tag','tgc7Sldr',...
    'BackgroundColor',Bkgrnd-0.05,...
    'Callback',{@tgc7_Callback});
tgc8 = uicontrol(f,'Style','slider',...
    'Max',1.0,'Min',0,'Value',SP(8),...
    'SliderStep',[0.05 0.2],...
    'Units','normalized',...
    'Position',[Pos+[0 -7*tgcSldrInc],SG.SS],...
    'Tag','tgc8Sldr',...
    'BackgroundColor',Bkgrnd-0.05,...
    'Callback',{@tgc8_Callback});
Pos = UIPos(6,:,1);
tgcAllTxt = uicontrol(f,'Style','text','String','TGC All Gain',...
    'Units','normalized',...
    'Position',[Pos+SG.TO,SG.TS],...
    'FontUnits','normalized',...
    'FontSize',0.8,...
    'Tag','tgcAllTxt',...
    'FontWeight','bold');
tgcAll = uicontrol(f,'Style','slider',...
    'Max',1.0,'Min',-1.0,'Value',0,...
    'SliderStep',[0.01,0.04],...
    'Units','normalized',...
    'Position',[Pos+SG.SO,SG.SS],...
    'Tag','tgcAllSldr',...
    'BackgroundColor',Bkgrnd-0.05,...
    'Callback',{@tgcAll_Callback});

% High Voltage slider.
%   The slider's min and max range is determined by the limits of the Verasonics
%   TPC and a max voltage limit that can be set in the user's setup script.
%   A HAL call is made to get the hardware limits.  The call is safe to make
%   when hardware is not opened or present, such as when in Simulate Mode. When
%   no hardware is present, a range is still returned.
%
%   The user script may override the "Max" attribute of this slider to impose
%   a high voltage maximum limit that is less than the capability of the detected
%   Verasonics TPC.
%
%   We also get the rangeGranularity so we can avoid double precision errors.
%   For example:
%      set(hivoltsSldr,'Value',56.40001);
%   yields:  "Warning: slider control can not have a Value outside of Min/Max
%   range.  Control will not be rendered until all of its parameter values
%   are valid." Eventhough the value we get from the Verasonics HAL call may
%   display as 56.4000, the digits after that may be non zero due to the nature
%   of using doubles.  So, we add one percent of rangeGranularity as a buffer
%   to the slider Max (and minus one percent from Min) to avoid such errors.
%
% - Check to see if the user has defined one or more TPC profiles.  If more than one,
%   these would be referenced in SeqControl objects with command 'setTPCProfile'.
%   For each profile, check for an associated TPC structure for defining
%   maxHighVoltage and set in Profile array.  If no TPC structure, use Trans.maxHighVoltage.
%
% - Check for user supplied highVoltage limit in Trans or TPC structures.
if (evalin('base','exist(''Trans'',''var'')'))&&(evalin('base','isfield(Trans, ''maxHighVoltage'')'))
    transHV = evalin('base','Trans.maxHighVoltage');
else
    transHV = 56.4;
end
% - Define an array of each profile's high voltage to indicate which profiles are referenced.  A
%   zero value means the profile is not referenced.
Profiles = zeros(1,5);
Profiles(1) = transHV;  % Set profile 1 on as default.
if evalin('base','exist(''SeqControl'',''var'')')
    SC = evalin('base','SeqControl');
    for i = 1:size(SC,2)
        if strcmp(SC(i).command,'setTPCProfile')
            Profiles(SC(i).argument) = transHV; % use transHV as default maxHighVoltage
        end
    end
end
% - Determine TPC voltage range and set maxHighVoltage limit in active Profiles.
% -- 'getTpcHighVoltage' returns default values if hardware not present.
[rangeMin, rangeMax, rangeGranularity] = getTpcHighVoltageRange();
% -- Check for maxHighVoltage set in a TPC structure.
if (evalin('base','exist(''TPC'',''var'')'))
    TPC = evalin('base','TPC');
    for i = 1:size(TPC,2)
        if (Profiles(i)~=0)
            if isfield(TPC(i),'maxHighVoltage')&&~isempty(TPC(i).maxHighVoltage)
                if TPC(i).maxHighVoltage <= Profiles(i), Profiles(i) = TPC(i).maxHighVoltage; end
            end
            if isfield(TPC(i),'highVoltageLimit')&&~isempty(TPC(i).highVoltageLimit)
                if TPC(i).highVoltageLimit <= Profiles(i), Profiles(i) = TPC(i).highVoltageLimit; end
            end
        end
    end
end
% -- If maxHighVoltage limit greater than rangeMax, set limit to rangeMax.
for i = 1:5
    if Profiles(i) ~= 0
        if (Profiles(i) > rangeMax), Profiles(i) = rangeMax; end
    end
end
% - For more than one profile, determine the number to use for the 2nd slider. Profile 5 has
%   priority over profiles 2-4.
hv2 = 0;     % hv2 will get the profile to use for 2nd slider.
if (size(find(Profiles),2) > 1)&&(Profiles(5)==0)
    for i = 2:4
        if Profiles(i) ~= 0, hv2 = i; break, end;
    end
elseif Profiles(5) ~= 0
    hv2 = 5;
end
if evalin('base','exist(''profile5inUse'',''var'')')
    profile5inUse = evalin('base','profile5inUse');
else
    profile5inUse = 0;
end

trackP5 = 0; % set default value for hv1 slider in case there is no P5

% - Render HV control number 1
Pos = UIPos(4,:,1);
hv1txt = uicontrol('Style','text','String','High Voltage P1',...
    'Units','normalized',...
    'Position',[Pos+SG.TO,SG.TS],...
    'FontUnits','normalized',...
    'FontSize',0.8,...
    'Tag','hv1txt',...
    'FontWeight','bold');
sldrMin = rangeMin;
hv1Sldr = uicontrol(f,'Style','slider',...
    'Max',Profiles(1),...
    'Min',sldrMin,...
    'Value',sldrMin,...
    'SliderStep',[0.05 0.2],...
    'Units','normalized',...
    'Position',[Pos+SG.SO,SG.SS],...
    'BackgroundColor',Bkgrnd-0.05,...
    'Interruptible','off',...
    'BusyAction','cancel',...
    'Tag','hv1Sldr',...
    'Callback',{@hv1Sldr_Callback,rangeGranularity});
hv1Value = uicontrol('Style','edit','String',num2str(sldrMin,'%.1f'),...
    'Units','normalized',...
    'Position',[Pos+SG.EO,SG.ES],...
    'Tag','hv1Value',...
    'Callback',{@hv1Value_Callback,hv1Sldr,rangeGranularity},...
    'BackgroundColor',Bkgrnd+0.1);
assignin('base','HV1maxHighVoltage',Profiles(1));

% - If more than one profile, create 2nd high voltage control
%hv2=5; % uncomment to force render.
Profiles(5)=50;
if hv2 ~= 0
    Pos = UIPos(3,:,1);
    string = ['High Voltage P' num2str(hv2)];
    hv2txt = uicontrol('Style','text',...
        'String',string,...
        'Units','normalized',...
        'Position',[Pos+SG.TO,SG.TS],...
        'FontUnits','normalized',...
        'FontSize',0.8,...
        'Tag','hv2txt',...
        'FontWeight','bold');
    hv2Sldr = uicontrol(f,'Style','slider',...
        'Max',Profiles(hv2),...
        'Min',rangeMin,...
        'Value',rangeMin,...
        'SliderStep',[0.05 0.2],...
        'Units','normalized',...
        'Position',[Pos+SG.SO,SG.SS],...
        'BackgroundColor',Bkgrnd-0.05,...
        'Interruptible','off',...
        'BusyAction','cancel',...
        'Tag','hv2Sldr',...
        'Callback',{@hv2Sldr_Callback,rangeGranularity});
    assignin('base','HV2maxHighVoltage',Profiles(hv2)); % set profile maxHV in base for TXEventCheck
    if hv2 == 5
        % check for profile voltage tracking parameter
        if evalin('base','isfield(Resource,''HIFU'')')&&evalin('base','isfield(Resource.HIFU,''voltageTrackP5'')')...
                &&evalin('base','~isempty(Resource.HIFU.voltageTrackP5)')
            trackP5 = evalin('base','Resource.HIFU.voltageTrackP5');
        else
            trackP5 = 0; % default to off if not specified by user
        end
        hv2Value = uicontrol('Style','edit','String',num2str(rangeMin,'%.1f'),...
            'Units','normalized',...
            'Position',[Pos+[0.045 0.03],SG.ES],...
            'Tag','hv2Value',...
            'Callback',{@hv2Value_Callback,hv2Sldr,rangeGranularity},...
            'BackgroundColor',Bkgrnd+0.1);
        hv2Actual = uicontrol('Style','edit','String',num2str(rangeMin,'%.1f'),...
            'Units','normalized',...
            'Position',[Pos+[0.125 0.03],SG.ES],...
            'Enable','inactive',...
            'Tag','hv2Actual',...
            'BackgroundColor',Bkgrnd+0.05);
        if (VDAS==1)&&(simMode==0)
            % Create a timer object that will update the actual push capacitor voltage string.
            hvtmr = timer('TimerFcn',@hvTimerCallback, 'Period', 1.5,'ExecutionMode','fixedSpacing');
            start(hvtmr);
        end
    else
        hv2Value = uicontrol('Style','edit','String',num2str(rangeMin,'%.1f'),...
            'Units','normalized',...
            'Position',[Pos+SG.EO,SG.ES],...
            'Tag','hv2Value',...
            'Callback',{@hv2Value_Callback,hv2Sldr,rangeGranularity},...
            'BackgroundColor',Bkgrnd+0.1);
    end
end

% - RcvData loop control
rcvdataloop = uicontrol('Style','togglebutton',...
    'String','Rcv Data Loop',...
    'Units','normalized',...
    'Position',[UIPos(1,:,1)+[0.0175 0.077],0.20,0.05],...
    'FontUnits','normalized',...
    'FontSize',0.4,...
    'BackgroundColor',Bkgrnd+0.05,...
    'Callback',{@rcvdataloop_Callback});

% - Simulate control
simulate = uicontrol('Style','togglebutton',...
    'String','Simulate',...
    'Units','normalized',...
    'Position',[UIPos(1,:,1)+[0.0175 0.027],0.20,0.05],...
    'FontUnits','normalized',...
    'FontSize',0.4,...
    'BackgroundColor',Bkgrnd+0.05,...
    'Callback',{@simulate_Callback});

% - Add Speed Correction slider only if a Recon is defined.
if evalin('base','exist(''Recon'',''var'')')
    Pos = UIPos(9,:,2);
    speedtxt = uicontrol('Style','text','String','Speed Of Sound',...
        'Units','normalized',...
        'Position',[Pos+SG.TO,SG.TS],...
        'FontUnits','normalized',...
        'FontSize',0.8,...
        'FontWeight','bold');
    speedSldr = uicontrol(f,'Style','slider',...
        'Max',1.4,'Min',0.6,'Value',1.0,...
        'SliderStep',[0.00125 0.0125],...
        'Units','normalized',...
        'Position',[Pos+SG.SO,SG.SS],...
        'BackgroundColor',Bkgrnd-0.05,...
        'Interruptible','off',...
        'BusyAction','cancel',...
        'Callback',{@speedSldr_Callback});
    speedValue = uicontrol('Style','edit','String',num2str(1.0,'%1.3f'),...
        'Units','normalized',...
        'Position',[Pos+SG.EO,SG.ES],...
        'Callback',{@speedValue_Callback,speedSldr},...
        'BackgroundColor',Bkgrnd+0.1);
end

% - Freeze control
freeze = uicontrol('Style','togglebutton',...
    'String','Freeze',...
    'Units','normalized',...
    'Position',[UIPos(1,:,2)+PB.BO,PB.BS],...
    'FontUnits','normalized',...
    'FontSize',PB.FS,...
    'BackgroundColor',Bkgrnd+0.05,...
    'Callback',{@freeze_Callback});

toolStr = {'none','filterTool','showTXPD'};
% Add the following GUI controls only if we have a DisplayWindow specification.
if dsplywin ~= 0
    % - Zoom controls
    Pos = UIPos(9,:,3);
    zoomtxt = uicontrol('Style','text','String','Zoom',...
        'Units','normalized',...
        'Position',[Pos+SG.TO,SG.TS],...
        'FontUnits','normalized',...
        'FontSize',0.8,...
        'FontWeight','bold');
    zoomin = uicontrol('Style','pushbutton',...
        'String','In',...
        'Units','normalized',...
        'Position',[Pos+[0.045 0.055],0.075,0.0375],...
        'FontUnits','normalized',...
        'FontSize',0.5,...
        'BackgroundColor',Bkgrnd+0.05,...
        'Interruptible','off',...
        'BusyAction','cancel',...
        'Callback',{@zoomin_Callback});
    zoomout = uicontrol('Style','pushbutton',...
        'String','Out',...
        'Units','normalized',...
        'Position',[Pos+[0.135 0.055],0.075,0.0375],...
        'FontUnits','normalized',...
        'FontSize',0.5,...
        'BackgroundColor',Bkgrnd+0.05,...
        'Interruptible','off',...
        'BusyAction','cancel',...
        'Callback',{@zoomout_Callback});
    % - Pan controls
    Pos = UIPos(8,:,3)+[0.0,0.01];
    pantxt = uicontrol('Style','text','String','Pan',...
        'Units','normalized',...
        'Position',[Pos+SG.TO,SG.TS],...
        'FontUnits','normalized',...
        'FontSize',0.8,...
        'FontWeight','bold');
    panlft = uicontrol('Style','pushbutton','String','Lft',...
        'Units','normalized',...
        'Position',[Pos+[0.0425 0.045],0.05,0.035],...
        'FontUnits','normalized',...
        'FontSize',0.5,...
        'BackgroundColor',Bkgrnd+0.05,...
        'Interruptible','off',...
        'BusyAction','cancel',...
        'Callback',{@panlft_Callback});
    panrt = uicontrol('Style','pushbutton','String','Rt',...
        'Units','normalized',...
        'Position',[Pos+[0.1625 0.045],0.05,0.035],...
        'FontUnits','normalized',...
        'FontSize',0.5,...
        'BackgroundColor',Bkgrnd+0.05,...
        'Interruptible','off',...
        'BusyAction','cancel',...
        'Callback',{@panrt_Callback});
    panup = uicontrol('Style','pushbutton','String','Up',...
        'Units','normalized',...
        'Position',[Pos+[0.1025 0.062],0.05,0.032],...
        'FontUnits','normalized',...
        'FontSize',0.5,...
        'BackgroundColor',Bkgrnd+0.05,...
        'Interruptible','off',...
        'BusyAction','cancel',...
        'Callback',{@panup_Callback});
    pandn = uicontrol('Style','pushbutton','String','Dn',...
        'Units','normalized',...
        'Position',[Pos+[0.1025 0.03],0.05,0.032],...
        'FontUnits','normalized',...
        'FontSize',0.5,...
        'BackgroundColor',Bkgrnd+0.05,...
        'Interruptible','off',...
        'BusyAction','cancel',...
        'Callback',{@pandn_Callback});
    
    %     pdw1 = 0;  % pdw1 is set to 1 if a Process structure with imageDisplay method is defined.
    if evalin('base','exist(''Process'',''var'')')
        Process = evalin('base','Process');
        % Find values used in the first 'Image/imageDisplay' Process structure for displayWindow 1
        for i = 1:size(Process,2)
            if (strcmp(Process(i).classname,'Image'))&&(strcmp(Process(i).method,'imageDisplay'))
                toolStr = {'none';'filterTool';'showTXPD';'PTool';'ColorMapTool'};
                break;
            end
        end
        
    end
end

% Tools poppumenu
Pos = UIPos(7,:,3);
toolsTxt = uicontrol('Style','text',...
    'String','Tools',...
    'Units','normalized',...
    'Position',[Pos+[0.015 0.05],0.22,0.06],...
    'HorizontalAlignment','Center',...
    'FontUnits','normalized',...
    'FontSize',0.35,...
    'FontWeight','bold');

toolsMenu = uicontrol('Style','popupmenu',...
    'Units','normalized',...
    'Position',[Pos+[0.01,-0.05],0.25,0.13],...
    'String',toolStr,...
    'FontUnits','normalized',...
    'FontSize',0.15,...
    'Tag','toolsMenu',...
    'Callback',@toolSelect);

    function toolSelect(hObject,~)
        
        toolValue = get(hObject,'Value');
        switch toolValue
            case 1
                close(findobj('tag','filterTool'));
                close(findobj('tag','TXPD'));                
                close(findobj('tag','ColorMapTool'));
                close(findobj('tag','ProcessTool'));
            case 2
                filterTool;
            case 3
                showTXPD
            case 4
                PTool;
            case 5
                ColorMapTool;
        end
    end

Pos = UIPos(6,:,3);
preSetTxt = uicontrol('Style','text',...
    'String','PreSet',...
    'Units','normalized',...
    'Position',[Pos+[0.015 0.07],0.22,0.06],...
    'HorizontalAlignment','Center',...
    'FontUnits','normalized',...
    'FontSize',0.35,...    
    'FontWeight','bold',...
    'Tag','preSetTxt');
preSetSave = uicontrol('Style','pushbutton',...
    'String','Save',...
    'Units','normalized',...
    'Position',[Pos+[0.02 0.06],0.1,0.04],...
    'FontUnits','normalized',...
    'FontSize',0.5,...
    'Tag','preSetSave',...
    'Callback',{@savePreSet});
preSetLoad = uicontrol('Style','pushbutton',...
    'String','Load',...
    'Units','normalized',...
    'Position',[Pos+[0.13 0.06],0.1,0.04],...
    'FontUnits','normalized',...
    'FontSize',0.5,...
    'Tag','preSetLoad',...    
    'Callback',{@loadPreSet});

% - Add Cineloop control if DisplayWindow contains more than one frame.
if nfrms > 1
    Pos = UIPos(1,:,3);
    cinex = 0.6875;
    ciney = 0.06;
    cineNum = nfrms;
    cinetxt = uicontrol('Style','text','String','CineLoop',...
        'Units','normalized',...
        'Position',[Pos+SG.TO,SG.TS],...
        'FontUnits','normalized',...
        'FontSize',0.8,...
        'FontWeight','bold');
    cine = uicontrol('Style','slider',...
        'Max',nfrms,'Min',1,'Value',nfrms,...
        'SliderStep',[1/(nfrms-1) 1/(nfrms-1)],...
        'Units','normalized',...
        'Position',[Pos+SG.SO,SG.SS],...
        'BackgroundColor',Bkgrnd-0.05,...
        'Interruptible','off',...
        'BusyAction','cancel',...
        'Tag','CLSlider',...
        'Callback',{@cine_Callback});
    % -- Cineloop number
    cineValue = uicontrol('Style','edit','String',num2str(cineNum,'%2.0f'),...
        'Units','normalized',...
        'Position',[Pos+[0.02 0.03],0.08,0.03],...
        'Tag','CLValue',...
        'Callback',{@cineValue_Callback,cine},...
        'BackgroundColor',Bkgrnd+0.1);
    % -- Cineloop save button
    cineSave = uicontrol('Style','togglebutton',...
        'String','Save',...
        'Units','normalized',...
        'Position',[Pos+[0.12 0.023],0.10,0.04],...
        'FontUnits','normalized',...
        'FontSize',0.5,...
        'Callback',{@cineSave_Callback});
end

% Make the GUI visible, unless the call has requested that it be hidden.
visibility = 'on';
if((true == evalin('base', 'exist(''Mcr_GuiHide'', ''var'')')) && (1 == evalin('base', 'Mcr_GuiHide')))
    % Caller has requested that we do NOT show the GUI window.
    visibility = 'off';
end
set(f,'Visible', visibility);

    function closefunc(source,eventdata)
        assignin('base', 'exit', 1);
        if exist('hvtmr','var'), stop(hvtmr); delete(hvtmr); end
        delete(f);
    end

% TGC Callback functions
%   The array SP keeps track of the slider positions before applying the SPAll(nTGC) gain factor.
%   This allows returning saturated TGC sliders to original gain curve values if the SPAll(nTGC)
%   gain is lowered.
    function tgc1_Callback(source,eventdata)
        SP(1) = get(tgc1,'Value')/SPAll(nTGC);
        assignin('base', 'tgc1',min(1023,1023*SP(1)*SPAll(nTGC)));
        assignin('base', 'action', 'tgc');
    end
    function tgc2_Callback(source,eventdata)
        SP(2) = get(tgc2,'Value')/SPAll(nTGC);
        assignin('base', 'tgc2',min(1023,1023*SP(2)*SPAll(nTGC)));
        assignin('base', 'action', 'tgc');
    end
    function tgc3_Callback(source,eventdata)
        SP(3) = get(tgc3,'Value')/SPAll(nTGC);
        assignin('base', 'tgc3',min(1023,1023*SP(3)*SPAll(nTGC)));
        assignin('base', 'action', 'tgc');
    end
    function tgc4_Callback(source,eventdata)
        SP(4) = get(tgc4,'Value')/SPAll(nTGC);
        assignin('base', 'tgc4',min(1023,1023*SP(4)*SPAll(nTGC)));
        assignin('base', 'action', 'tgc');
    end
    function tgc5_Callback(source,eventdata)
        SP(5) = get(tgc5,'Value')/SPAll(nTGC);
        assignin('base', 'tgc5',min(1023,1023*SP(5)*SPAll(nTGC)));
        assignin('base', 'action', 'tgc');
    end
    function tgc6_Callback(source,eventdata)
        SP(6) = get(tgc6,'Value')/SPAll(nTGC);
        assignin('base', 'tgc6',min(1023,1023*SP(6)*SPAll(nTGC)));
        assignin('base', 'action', 'tgc');
    end
    function tgc7_Callback(source,eventdata)
        SP(7) = get(tgc7,'Value')/SPAll(nTGC);
        assignin('base', 'tgc7',min(1023,1023*SP(7)*SPAll(nTGC)));
        assignin('base', 'action', 'tgc');
    end
    function tgc8_Callback(source,eventdata)
        SP(8) = get(tgc8,'Value')/SPAll(nTGC);
        assignin('base', 'tgc8',min(1023,1023*SP(8)*SPAll(nTGC)));
        assignin('base', 'action', 'tgc');
    end
    function tgcAll_Callback(source,eventdata)        
        TGCAllSldr(nTGC) = get(tgcAll,'Value');
        SPAll(nTGC) = TGCAllSldr(nTGC);
        SPAll(nTGC) = 1.05*SPAll(nTGC)*SPAll(nTGC) + 1.95*SPAll(nTGC) + 1;  % Convert to gain factor between 0.25 and 4.0
        set(tgc1,'Value',min(1.0,SP(1)*SPAll(nTGC)));
        set(tgc2,'Value',min(1.0,SP(2)*SPAll(nTGC)));
        set(tgc3,'Value',min(1.0,SP(3)*SPAll(nTGC)));
        set(tgc4,'Value',min(1.0,SP(4)*SPAll(nTGC)));
        set(tgc5,'Value',min(1.0,SP(5)*SPAll(nTGC)));
        set(tgc6,'Value',min(1.0,SP(6)*SPAll(nTGC)));
        set(tgc7,'Value',min(1.0,SP(7)*SPAll(nTGC)));
        set(tgc8,'Value',min(1.0,SP(8)*SPAll(nTGC)));
        assignin('base', 'tgc1',min(1023,1023*SP(1)*SPAll(nTGC)));
        assignin('base', 'tgc2',min(1023,1023*SP(2)*SPAll(nTGC)));
        assignin('base', 'tgc3',min(1023,1023*SP(3)*SPAll(nTGC)));
        assignin('base', 'tgc4',min(1023,1023*SP(4)*SPAll(nTGC)));
        assignin('base', 'tgc5',min(1023,1023*SP(5)*SPAll(nTGC)));
        assignin('base', 'tgc6',min(1023,1023*SP(6)*SPAll(nTGC)));
        assignin('base', 'tgc7',min(1023,1023*SP(7)*SPAll(nTGC)));
        assignin('base', 'tgc8',min(1023,1023*SP(8)*SPAll(nTGC)));
        assignin('base', 'action', 'tgc');
    end

% RcvData Loop Callback
    function rcvdataloop_Callback(source,eventdata)
        assignin('base','rloopButton',get(source,'Value'));
        assignin('base', 'action', 'rcvloop');
    end

% Simulate Callback
    function simulate_Callback(source,eventdata)
        assignin('base','simButton',get(source,'Value'));
        assignin('base', 'action', 'simulate');
    end

% Freeze Callback
    function freeze_Callback(source,eventdata)
        if evalin('base','isequal(initialized,0)')
            return
        end
        frzstate = get(source,'Value');
        assignin('base','freeze',frzstate);
        if (frzstate == 0)&&(exist('cine','var'))
            set(cine, 'Value', nfrms);
            set(cineValue,'String',num2str(nfrms,'%2.0f'));
        end
    end

% Zoom Callbacks
    function zoomin_Callback(source,eventdata)
        assignin('base', 'action', 'zoomin');
    end

    function zoomout_Callback(source,eventdata)
        assignin('base', 'action', 'zoomout');
    end

% Pan Callbacks
    function panlft_Callback(source,eventdata)
        assignin('base', 'action', 'panlft');
    end

    function panrt_Callback(source,eventdata)
        assignin('base', 'action', 'panrt');
    end

    function panup_Callback(source,eventdata)
        assignin('base', 'action', 'panup');
    end

    function pandn_Callback(source,eventdata)
        assignin('base', 'action', 'pandn');
    end


% preSet Callbacks
    function savePreSet(varargin)
        
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
               
        % TGC 
        if evalin('base','exist(''TGC'')')
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
        
        mainFolder = pwd;
        cd('MatFiles')
        
        %% LINK MODIFICATION
%         if istring(varargin) && strcmp(varargin,'LINK Auto Save')
%             fileName = strcat(preSet.P.path,preSet.P.filePrefix,'-',int2str(preSet.P.settingsNumber),preSet.P.dateStr,'.mat');
%             disp(strcat('Auto-saving Preset ',fileName));
%             save(fileName, P);
%         else
%             [fn,pn] = uiputfile('*.mat','Save preSet as',[preFix,'_preSet']);
%             if ~isequal(fn,0) % fn will be zero if user hits cancel
%                 fn = strrep(fullfile(pn,fn), '''', '''''');
%                 save(fn, 'preSet');
%                 fprintf('The preSet has been saved at %s \n',fn);
%             else
%                 disp('The preSet is not saved.');
%             end
%         end
%         
%         cd(mainFolder)
%         return
    end

    function loadPreSet(varargin)       

        if evalin('base','isequal(initialized,0)')            
            return
        end           
                               
        if ~ishandle(findobj('tag','UI'))
            msgbox('VSX Control does not exist');
            return
        else
            preFix = evalin('base','displayWindowTitle');
        end
               
        mainFolder = pwd;
        cd('MatFiles')
        
        [FileName,PathName] = uigetfile('*.mat',['Select the preSet file for ',preFix], [pwd,'/',preFix,'_preSet.mat']);
        if PathName == 0 %if the user pressed cancelled, then we exit this callback
            cd(mainFolder);
            return
        else
            buffer = load([PathName, FileName]);
        end
        
        cd(mainFolder);

        if isfield(buffer,'preSet'),
            preSet = buffer.preSet;
        else
            msgbox('There is no preSet file!');
            return
        end        

        UI = evalin('base','UI');        
        assignin('base','preSet',preSet);
        Resource = evalin('base','Resource');

        % From the VSX, Trans, Resource, TW, TX and Event are required, so
        % other structures must be checked before loading it        
        
        % Check SWversion, if not, must before 3.0.7
        % if preSet has SFormat -> 2.11 version
        if isfield(preSet,'SWversion')
            newSW = 1;
        else
            newSW = 0;
        end
        
        % Make sure that the transducer is correct
        if evalin('base','strcmpi(Trans.name,preSet.Trans.name)')
            Trans = preSet.Trans; assignin('base','Trans',Trans);
        else
            msgbox('Incorrect Transducer!');
            return
        end
        
        oldTX = evalin('base','TX');
        TX      = preSet.TX; assignin('base','TX',TX);
        TW      = preSet.TW; assignin('base','TW',TW);
        
        if evalin('base','exist(''Receive'',''var'')')            
            Receive = preSet.Receive; assignin('base','Receive',Receive);
        end
        
        % Image my not be reuired 
        if evalin('base','exist(''PData'',''var'')')
            PData   = preSet.PData; assignin('base','PData',PData);            
            if newSW
                evalin('base','Resource.DisplayWindow(1).Position(4) = preSet.Display.Height;');
            else
                evalin('base','Resource.DisplayWindow(1).Position(4) = preSet.Height;');
            end
            
            if newSW % only new preSet has colormap and 
                % Restore colormap
                for winNum = 1:length(Resource.DisplayWindow)
                    hDisplay = Resource.DisplayWindow(winNum).figureHandle;
                    set(hDisplay,'Colormap',preSet.Display.cMap{winNum});
                end
                
                % Restore custom gamma curve if it's saved in preSet
                if isfield(preSet.Display,'customGamma')
                    assignin('base','customGamma',preSet.Display.customGamma);
                end
            else
                % if the colormap has been changed by SW 3.0.7, restore to
                % the linear gamma curve and remove customGamma in the
                % workspace                
                if evalin('base','exist(''customGamma'',''var'')')
                    evalin('base','clear customGamma');
                    for winNum = 1:length(Resource.DisplayWindow)
                        hDisplay = Resource.DisplayWindow(winNum).figureHandle;
                        cMap = get(hDisplay,'Colormap');
                        Y = (0:(1/255):1)';
                        if isequal(Resource.DisplayWindow(winNum).splitPalette,1)
                            for n = 1:3, cMap(1:128,n) = Y(1:2:256); end
                        else                           
                            for n = 1:3, cMap(:,n) = Y; end
                        end
                        set(hDisplay,'Colormap',cMap);
                    end                    
                end                
            end
        end

        % Recon my not be reuired, only saved since SW 3.0.7
        if evalin('base','exist(''Recon'',''var'')') && newSW
            Recon     = preSet.Recon; assignin('base','Recon',Recon);
            ReconInfo = preSet.ReconInfo; assignin('base','ReconInfo',ReconInfo);
        end        
        
        % Proces may be used
        if evalin('base','exist(''Process'',''var'')')            
            Process = preSet.Process; assignin('base','Process',Process);
            if isfield(preSet,'compFactorAll')
                assignin('base','compFactorAll',preSet.compFactorAll);            
            end
        end              
        
        if evalin('base','exist(''SFormat'',''var'')') % compatiable with old script
            SFormat = preSet.SFormat; assignin('base','SFormat',SFormat);
        end
        
        % for Personal definition
        
        %% LINK addition
        
        if evalin('base','exist(''P'',''var'')') % compatiable with old script
            oldP = evalin('base','P');
            P = preSet.P;
            
            if isfield(oldP,'saveAcquisition') %Check for one of our custom variables
                %Fix the time and date
                P.time = clock;
                P.dateStr = strcat('_',num2str(P.time(2)), '-', num2str(P.time(3)), '-',...
                    num2str(P.time(1)));
                
                %Resync the save toggle button
                if ~(P.saveAcquisition == oldP.saveAcquisition)
                    P.saveAcquisition = oldP.saveAcquisition;
                end
            end
            assignin('base','P',P);
        end
        
        %old verasonics script
%         if evalin('base','exist(''P'',''var'')') % compatiable with old script
%             P = preSet.P; assignin('base','P',P);
%         end     
        
        %% Back to verasonics script
        % TGC and TGC ALL
        if evalin('base','exist(''TGC'')')            
            if newSW
                TGC = preSet.TGCparam.TGC;
                TGCAllSldr = preSet.TGCparam.SldrAll;
                SPAll = preSet.TGCparam.SPAll;                
            else % only the first TGC is saved in old SW, so nTGC will be 1
                nTGC = 1;
                set(findobj('Tag','TGCnum'),'Value',nTGC); % set TGC selection to 1, if more than 1
                TGC = preSet.TGC;
                tgcAllvalue = preSet.tgcAll;
                TGCAllSldr(nTGC) = tgcAllvalue;
                SPAll(nTGC) = 1.05*tgcAllvalue*tgcAllvalue + 1.95*tgcAllvalue + 1;  % Convert to gain factor between 0.25 and 4.0
            end
            assignin('base','TGC',TGC);
            tgcValue = double(TGC(nTGC).CntrlPts)/1023;
            SP = tgcValue/SPAll(nTGC);
            
            set(tgc1,'Value',tgcValue(1)); assignin('base', 'tgc1',TGC(nTGC).CntrlPts(1));
            set(tgc2,'Value',tgcValue(2)); assignin('base', 'tgc2',TGC(nTGC).CntrlPts(2));
            set(tgc3,'Value',tgcValue(3)); assignin('base', 'tgc3',TGC(nTGC).CntrlPts(3));
            set(tgc4,'Value',tgcValue(4)); assignin('base', 'tgc4',TGC(nTGC).CntrlPts(4));
            set(tgc5,'Value',tgcValue(5)); assignin('base', 'tgc5',TGC(nTGC).CntrlPts(5));
            set(tgc6,'Value',tgcValue(6)); assignin('base', 'tgc6',TGC(nTGC).CntrlPts(6));
            set(tgc7,'Value',tgcValue(7)); assignin('base', 'tgc7',TGC(nTGC).CntrlPts(7));
            set(tgc8,'Value',tgcValue(8)); assignin('base', 'tgc8',TGC(nTGC).CntrlPts(8));
            set(tgcAll,'Value',TGCAllSldr(nTGC));
            
            VDAS = evalin('base','VDAS');
            if (VDAS==1)&&(Resource.Parameters.simulateMode==0)
                Result = loadTgcWaveform(nTGC);
                if ~strcmpi(Result, 'SUCCESS'), return; end
            end
        end
        
        % High Voltage 1
        hv1Volt = preSet.hv1Volt;

        evalin('base','tStartHvSldr = tic;'); % set time the slider was moved for error suppression.
        % Attempt to set high voltage.  On error, setTpcProfileHighVoltage() returns voltage range minimum.
        [~, hvset] = setTpcProfileHighVoltage(hv1Volt,1);
        set(hv1Sldr,'Value',hvset);
        set(hv1Value,'String',num2str(hvset,'%.1f'));
        TPC = evalin('base', 'TPC');
        TPC(1).hv = hvset;
        assignin('base', 'TPC', TPC);
        
        % High Voltage 2
        hv2Sldr = findobj('tag','hv2Sldr');
        if ishandle(hv2Sldr)            
            if isfield(preSet,'hv2Volt')
                hv2Volt = preSet.hv2Volt ;
            else
                msgbox('Incorrect setting file!')
                return
            end
            
            if evalin('base','exist(''profile5inUse'',''var'')')
                profile5inUse = evalin('base','profile5inUse');
            else
                profile5inUse = 0;
            end
            
            % Attempt to set high voltage.  On error, setTpcProfileHighVoltage() returns voltage range minimum.
            if profile5inUse ~= 2  % don't call func to set HV if using extenal supply
                [~, hvset] = setTpcProfileHighVoltage(hv2Volt,length(TPC));
                TPC(length(TPC)).hv = hvset;
                assignin('base', 'TPC', TPC);
            else  % for external HIFU power supply, call the extPwrCtrl function to set voltage
                % call external power supply control function
                [PSerrorflag, ~] = extPwrCtrl('SETV', hv2Volt);
                if PSerrorflag
                    error('VSX: Communication error with external power supply.');
                end
                hvset = hv2Volt;
                TPC = evalin('base', 'TPC');
                TPC(5).hv = hvset;
                assignin('base', 'TPC', TPC);
            end
            % Since requested value is not necessarily the value that was set,
            % we set the slider to the resulting value.
            set(findobj('Tag','hv2Value'),'String',num2str(hvset,'%.1f'));
            set(hv2Sldr,'Value',hv2Volt);
        end
        
        % Speed Correction, only if Recon is defined
        if evalin('base','exist(''Recon'',''var'')')            
            set(speedSldr,'Value',preSet.speed);
            set(speedValue,'String',num2str(preSet.speed,'%1.3f'));
            evalin('base','Resource.Parameters.speedCorrectionFactor = preSet.speed;');
        end
        
        % If PTool window is open, reload it
        hPTool = findobj('tag','ProcessTool');
        if ishandle(hPTool),
            posPTool = get(hPTool,'position');
            PTool;
            set(findobj('tag','ProcessTool'),'position',posPTool);
        end
        
        % If ColorMapTool window is open, reload it
        hg = findobj('tag','ColorMapTool');
        if ishandle(hg)
            posGSTool = get(hg,'Position');
            ColorMapTool;
            set(findobj('tag','ColorMapTool'),'position',posGSTool)
        end
            
        % persf and perst for Doppler, if exist
        if evalin('base','exist(''persf'',''var'')'), 
            if newSW
                assignin('base','persf',preSet.Doppler.persf); 
                assignin('base','persp',preSet.Doppler.persp);
            else
                assignin('base','persf',preSet.persf);
                assignin('base','persp',preSet.persp);
            end
        end
        
        oldUI = preSet.UI;
        
        % Update all parameters before VsSlider and VsButtonGruop in case
        % some callbacks have 'set&Run' command without updating the
        % workspace
        Control = [];
        Control.Command = 'update&Run';
        Control.Parameters = {'PData','InterBuffer','ImageBuffer','DisplayWindow','Parameters',...
            'Trans','Media','TW','TX','Receive','TGC','Recon','Process'};
        if evalin('base','exist(''SFormat'',''var'')') % compatiable with old script
            Control.Parameters(end+1) = {'SFormat'};
        end
        
        % All VsSlider and VsButtonGroup        
        for i = 1:length(UI)
            
            if isfield(UI(i),'Control') && ~isempty(UI(i).Control)
                VsStyle = UI(i).Control{3};
                
                % remove computeTXPD in the callback and save into temp
                % callback to prevent redundant TXPD calculation which takes a
                % lot of time
                CBfilename = [UI(i).Control{1},'Callback'];
                fid = fopen([CBfilename,'.m']);
                lineNum = 1;
                tline = fgetl(fid);
                while ischar(tline)
                    CBcell{lineNum,:} = tline; 
                    lineNum = lineNum +1;
                    tline = fgetl(fid);
                end
                fclose(fid);
                
                tempfile = ['tempCallback',num2str(i)];
                CBcell = strrep(CBcell,CBfilename,tempfile);    
                CBcell(~cellfun('isempty',strfind(CBcell,'TXPD'))) = [];
                CBcell(~cellfun('isempty',strfind(CBcell,'waitbar'))) = [];
                CBcell(~cellfun('isempty',strfind(CBcell,'close(h)'))) = [];

                fid = fopen([tempfile,'.m'],'w');
                for j = 1:size(CBcell)
                    fprintf(fid,'%s\n', CBcell{j});
                end                
                fclose(fid);
                clear CBcell;                              
                
                switch VsStyle
                    case 'VsSlider'
                        if strcmpi(oldUI(i).txt,get(UI(i).handle(1),'String'))
                            set(UI(i).handle(2),'Value',oldUI(i).value);
                            set(UI(i).handle(3),'String',num2str(oldUI(i).value,oldUI(i).VF));
                            if strfind(get(UI(i).handle(1),'String'),'Range')
                                assignin('base','action','displayChange');
                            else
                                feval(tempfile,UI(i).handle(2));
                            end                            
                            
                        else
                            error(['Incorrect preSet file! The UIcontrol at ',UI(i).Control{1},' is incorrect!']);
                        end
                        
                    case 'VsButtonGroup'
                        event.EventName = 'SelectionChanged';
                        event.OldValue = UI(i).handle(1);
                        event.NewValue = UI(i).handle(oldUI(i).SelectedButtonNum+1);
                        set(UI(i).handle(1),'SelectedObject',event.NewValue);
                        feval(tempfile,UI(i).handle(1),event);                        
                end
                
                delete([tempfile,'.m']);
            else % customized UIcontrol
                if ~isempty(UI(i).handle)
                    UIStyle = get(UI(i).handle,'Style');
                    switch UIStyle
                        case {'slider','radiobutton'}
                            set(UI(i).handle,'Value',preSet.UI(i).value);
                        case 'edit'
                            set(UI(i).handle,'String',preSet.UI(i).String);
                    end
                end
            end
            
            % modify Control after callbacks, only 'set&Run' is
            % required to be added into Control for runAcq after
            % loading preSet file
            ControlNew = evalin('base','Control');
            
            m = 2; % Control(1) is 'update&Run'
            for k = 1:length(ControlNew);
                if strcmpi(ControlNew(k).Command,'set&Run')
                    Control(m) = ControlNew(k);
                    m = m+1;
                end
            end
            
            assignin('base','Control',[]); 
            evalin('base','Control.Command = [];'); % for next callback
        end
        
        % now recompute TXPD and put in workspace
        if isfield(oldTX,'TXPD') 
            % old software will replace the TXPD
            h = waitbar(0,'Program TX parameters, please wait!');
            steps = size(TX,2);
            for i = 1:size(TX,2)
                TX(i).TXPD = computeTXPD(TX(i),PData);
                waitbar(i/steps)
            end
            close(h);
            assignin('base','TX',TX);            
        end
        
        % add "set&run" to set colormap, only works in new SW
        if newSW
            for winNum = 1:length(Resource.DisplayWindow)
                n=length(Control)+1;
                Control(n).Command = 'set&Run';
                Control(n).Parameters = {'DisplayWindow',winNum,'colormap',preSet.Display.cMap{winNum}};
            end
        end
        assignin('base','Control',Control);
        return
        
    end

% High Voltage 1 Slider Callback
    function hv1Sldr_Callback(source,eventdata,rangeGranularity)
        if (VDAS~=1)||(simMode~=0) || trackP5==1 % disable updates in these cases
            hv = str2double(get(hv1Value,'String'));
            set(hv1Sldr,'Value',hv);
            return;
        end
        hv = get(hv1Sldr,'Value');
        evalin('base','tStartHvSldr = tic;'); % set time the slider was moved for error suppression.
        % Attempt to set high voltage.  On error, setTpcProfileHighVoltage() returns voltage range minimum.
        [result, hvset] = setTpcProfileHighVoltage(hv,1);
        if ~strcmpi(result, 'Success') && ~strcmpi(result, 'Hardware Not Open')
            % ERROR!  Failed to set high voltage.
            error('ERROR!  Failed to set Verasonics TPC high voltage for profile 1 because \"%s\".', result);
        end
        TPC = evalin('base', 'TPC');
        TPC(1).hv = hvset;
        assignin('base', 'TPC', TPC);
        set(hv1Value,'String',num2str(hvset,'%.1f'));
        % Since requested value is not necessarily the value that was obtained,
        % we set the slider to the resulting value.
        set(hv1Sldr,'Value',hv);
    end

% High Voltage 1 Value Callback
    function hv1Value_Callback(source,eventdata,hv1Sldr,rangeGranularity)
        if (VDAS~=1)||(simMode~=0) || trackP5==1 % disable updates in these cases
            hv = get(hv1Sldr,'Value');
            set(hv1Value,'String',num2str(hv,'%.1f'));
            return;
        end
        hv = str2double(get(hv1Value,'String'));
        % Protect against bad user input.  e.g."1.6.6"
        if(isnan(hv))
            hv = get(hv1Sldr,'Value');
        end
        evalin('base','tStartHvSldr = tic;'); % set time the slider was moved for error suppression.
        % Don't allow setting hv outside slider's Min/Max range.  This range
        % should be a subset of the range that setTpcProfileHighVoltage() uses.
        sliderMin = get(hv1Sldr, 'Min');
        sliderMax = get(hv1Sldr, 'Max');
        if hv < sliderMin, hv = sliderMin; end
        if hv > sliderMax, hv = sliderMax; end
        % Attempt to set high voltage.  On error, setTpcProfileHighVoltage() returns voltage range minimum.
        [result, hvset] = setTpcProfileHighVoltage(hv,1);
        if ~strcmpi(result, 'Success') && ~strcmpi(result, 'Hardware Not Open')
            % ERROR!  Failed to set high voltage.
            error('ERROR!  Failed to set Verasonics TPC high voltage for profile 1 because \"%s\".', result);
        end
        TPC = evalin('base', 'TPC');
        TPC(1).hv = hvset;
        assignin('base', 'TPC', TPC);
        % Since hv value is supplied by HAL or hv2Sldr, num2str() below will always
        % succeed in conversion.
        set(hv1Value,'String',num2str(hvset,'%.1f'));
        set(hv1Sldr,'Value',hv);
    end

% High Voltage 2 Slider Callback
    function hv2Sldr_Callback(source,eventdata,rangeGranularity)
        if (VDAS~=1)||(simMode~=0),
            hv = str2double(get(hv2Value,'String'));
            set(hv2Sldr,'Value',hv);
            return;
        end
        hv = get(hv2Sldr,'Value');
        evalin('base','tStartHvSldr = tic;'); % set time the slider was moved for error suppression.
        if (hv2==5)&&(trackP5>0) % If profile 5 active check for tracking feature enabled
            hv = max(get(hv1Sldr, 'Min'), hv); % don't go below slider minimum
            [result, ~] = setTpcProfileHighVoltage(hv,trackP5);
            if ~strcmpi(result, 'Success') && ~strcmpi(result, 'Hardware Not Open')
                % ERROR!  Failed to set high voltage.
                error('ERROR!  Failed to set Verasonics TPC high voltage for profile %d because \"%s\".', int8(trackP5), result);
            end
            TPC = evalin('base', 'TPC');
            TPC(trackP5).hv = hv;
            assignin('base', 'TPC', TPC);
            if trackP5 == 1 % only update hv1 gui if trackP5 points to it and not some other profile
                set(hv1Value,'String',num2str(hv,'%.1f'));
                set(hv1Sldr,'Value',hv);
            end
        end
        % Attempt to set high voltage.  On error, setTpcProfileHighVoltage() returns voltage range minimum.
        if profile5inUse ~= 2  % don't call func to set HV if using extenal supply
            [result, hvset] = setTpcProfileHighVoltage(hv,hv2);
            if ~strcmpi(result, 'Success') && ~strcmpi(result, 'Hardware Not Open')
                % ERROR!  Failed to set high voltage.
                error('ERROR!  Failed to set Verasonics TPC high voltage for profile %d because \"%s\".', int8(hv2), result);
            end
            TPC = evalin('base', 'TPC');
            TPC(hv2).hv = hvset;
            assignin('base', 'TPC', TPC);
        else  % for external HIFU power supply, call the extPwrCtrl function to set voltage
            % call external power supply control function
            [PSerrorflag, ~] = extPwrCtrl('SETV', hv);
            if PSerrorflag
                error('VSX: Communication error with external power supply.');
            end
            hvset = hv;
            TPC = evalin('base', 'TPC');
            TPC(5).hv = hvset;
            assignin('base', 'TPC', TPC);
        end
        % Since requested value is not necessarily the value that was set,
        % we set the slider to the resulting value.
        set(findobj('Tag','hv2Value'),'String',num2str(hvset,'%.1f'));
        set(hv2Sldr,'Value',hv);
    end

% High Voltage 2 Value Callback
    function hv2Value_Callback(source,eventdata,hv2Sldr,rangeGranularity)
        if (VDAS~=1)||(simMode~=0)
            hv = get(hv2Sldr,'Value');
            set(hv2Value,'String',num2str(hv,'%.1f'));
            return;
        end
        hv = str2double(get(hv2Value,'String'));
        % Protect against bad user input.  e.g."1.6.6"
        if(isnan(hv))
            hv = get(hv2Sldr,'Value');
        end
        % Don't allow setting hv outside slider's Min/Max range.  This range
        % should be a subset of the range that setTpcProfileHighVoltage() uses.
        sliderMin = get(hv2Sldr, 'Min');
        sliderMax = get(hv2Sldr, 'Max');
        if hv < sliderMin, hv = sliderMin; end
        if hv > sliderMax, hv = sliderMax; end
        evalin('base','tStartHvSldr = tic;'); % set time the slider was moved for error suppression.
        if (hv2==5)&&(trackP5>0) % If profile 5 active check for tracking feature enabled
            hv = max(get(hv1Sldr, 'Min'), hv); % don't go below slider minimum
            [result, ~] = setTpcProfileHighVoltage(hv,trackP5);
            if ~strcmpi(result, 'Success') && ~strcmpi(result, 'Hardware Not Open')
                % ERROR!  Failed to set high voltage.
                error('ERROR!  Failed to set Verasonics TPC high voltage for profile %d because \"%s\".', int8(trackP5), result);
            end
            TPC = evalin('base', 'TPC');
            TPC(trackP5).hv = hv;
            assignin('base', 'TPC', TPC);
            if trackP5 == 1
                set(hv1Value,'String',num2str(hv,'%.1f'));
                set(hv1Sldr,'Value',hv);
            end
        end
        if profile5inUse ~= 2
            % Attempt to set high voltage.  On error, setTpcProfileHighVoltage() returns voltage range minimum.
            [result, hvset] = setTpcProfileHighVoltage(hv,hv2);
            if ~strcmpi(result, 'Success') && ~strcmpi(result, 'Hardware Not Open')
                % ERROR!  Failed to set high voltage.
                error('ERROR!  Failed to set Verasonics TPC high voltage for profile %d because \"%s\".', int8(hv2), result);
            end
            TPC = evalin('base', 'TPC');
            TPC(hv2).hv = hvset;
            assignin('base', 'TPC', TPC);
        else  % for external HIFU power supply, call the extPwrCtrl function to set voltage
            % call external power supply control function
            [PSerrorflag, ~] = extPwrCtrl('SETV', hv);
            if PSerrorflag
                error('VSX: Communication error with external power supply.');
            end
            hvset = hv;
            TPC = evalin('base', 'TPC');
            TPC(5).hv = hvset;
            assignin('base', 'TPC', TPC);
        end
        % Since hv value is supplied by HAL or hv1Sldr, num2str() below will always
        % succeed in conversion.
        set(hv2Value,'String',num2str(hvset,'%.1f'));
        set(hv2Sldr,'Value',hv);
    end

% Speed Slider Callback
    function speedSldr_Callback(source,eventdata)
        sv = get(speedSldr,'Value');
        assignin('base', 'speedCorrect', sv);
        assignin('base', 'action', 'speed');
        set(speedValue,'String',num2str(sv,'%1.3f'));
    end

% Speed Value Callback
    function speedValue_Callback(speedValue,eventdata,speedSldr)
        sv = str2num(get(speedValue,'String'));
        if (0.6<=sv) && (sv<=1.4)
            assignin('base', 'speedCorrect', sv);
            assignin('base', 'action', 'speed');
            set(speedSldr,'Value', sv);
        else
            sv = get(speedSldr,'Value');
            set(speedValue,'String',num2str(sv,'%1.3f'));
        end
    end

% Cineloop Callback
    function cine_Callback(src,eventdata)
        if get(freeze,'Value')==0    % no action if not in freeze
            set(src,'Value',nfrms);  % reset slider to end
            return
        end
        cv = round(get(src,'Value'));
        rfrm = nfrms - cv;  % rfrm is the number of frames back from nfrms
        DisplayWindow = evalin('base', 'Resource.DisplayWindow(1)');
        if ~isfield(DisplayWindow,'numFrames'), DisplayWindow.numFrames = 1; end
        handle = DisplayWindow.imageHandle;
        cfrm = DisplayWindow.lastFrame - rfrm;
        if DisplayWindow.firstFrame > DisplayWindow.lastFrame  % has buffer wrapped?
            if cfrm < 1, cfrm = DisplayWindow.numFrames + cfrm; end
        else
            if cfrm < 1, cfrm = 1; end
        end
        Control.Command = 'cineDisplay';
        Control.Parameters = cell(1,4);
        Control.Parameters{1} = 'displayWindow';
        Control.Parameters{2} = 1;
        Control.Parameters{3} = 'frameNumber';
        Control.Parameters{4} = round(cfrm);
        runAcq(Control);
        set(findobj('Tag','CLValue'),'String',num2str(cv,'%2.0f'));
    end

% cineValue Callback
    function cineValue_Callback(cineValue,eventdata,cine)
        if get(freeze,'Value')==0  % no action if not in freeze
            return
        end
        cv = str2double(get(cineValue,'String'));
        if (1<=cv) && (cv<=nfrms)
            set(cine, 'Value', cv);
            rfrm = nfrms - cv;  % rfrm is the number of frames back from nfrms
            DisplayWindow = evalin('base', 'Resource.DisplayWindow(1)');
            if ~isfield(DisplayWindow,'numFrames'), DisplayWindow.numFrames = 1; end
            handle = DisplayWindow.imageHandle;
            cfrm = DisplayWindow.lastFrame - rfrm;
            if DisplayWindow.firstFrame > DisplayWindow.lastFrame  % has buffer wrapped?
                if cfrm < 1, cfrm = DisplayWindow.numFrames + cfrm; end
            else
                if cfrm < 1, cfrm = 1; end
            end
            Control.Command = 'cineDisplay';
            Control.Parameters = cell(1,4);
            Control.Parameters{1} = 'displayWindow';
            Control.Parameters{2} = 1;
            Control.Parameters{3} = 'frameNumber';
            Control.Parameters{4} = round(cfrm);
            runAcq(Control);
        else
            cv = get(cine,'Value');
            set(cineValue,'String',num2str(cv,'%2.0f'));
        end
    end

% cineSave Callback
    function cineSave_Callback(src,eventdata)
        if get(freeze,'Value')==0   % no action if not in freeze
            set(src,'Value',0);
            return
        end
        DisplayWindow = evalin('base', 'Resource.DisplayWindow(1)');
        fig = DisplayWindow.figureHandle;
        handle = DisplayWindow.imageHandle;
        cfrm = DisplayWindow.firstFrame;
        if ~evalin('base','exist(''Process'',''var'')'), return, end;
        Process = evalin('base','Process');
        n = 1; % n keeps track of frame no. from first to last.
        while n <= DisplayWindow.numFrames
            Control.Command = 'cineDisplay';
            Control.Parameters = cell(1,4);
            Control.Parameters{1} = 'displayWindow';
            Control.Parameters{2} = 1;
            Control.Parameters{3} = 'frameNumber';
            Control.Parameters{4} = round(cfrm);
            runAcq(Control);
            F(n) = getframe(fig);
            if cfrm == DisplayWindow.lastFrame, break, end;
            n = n+1;
            cfrm = cfrm + 1;
            if cfrm > DisplayWindow.numFrames, cfrm = 1; end
        end
        filename = datestr(now,'dd-mmmm-yyyy_HH-MM-SS');
        
        [fn,pn,~] = uiputfile('*.avi','Save cineloop as',filename);
        if ~isequal(fn,0) % fn will be zero if user hits cancel
            fn = strrep(fullfile(pn,fn), '''', '''''');
            v = VideoWriter(fn);
            open(v),writeVideo(v,F);
            fprintf('The cineloop has been saved at %s \n',fn);
        else
            disp('The cineloop is not saved.');
        end               
        set(src,'Value',0);
    end

% HV timer callback for actual push capacitor voltage; used for both
% internal and external profile 5 power supply configurations.
    function hvTimerCallback(src,eventdata)
        [Result,extCapVoltage] = getHardwareProperty('TpcExtCapVoltage');
        if ~strcmp(Result,'Success')
            error('VSX: Error from getHardwareProperty call to read push capacitor Voltage.');
        end
        set(hv2Actual,'String',num2str(extCapVoltage,'%.1f'));
        if 1-(extCapVoltage/get(hv2Sldr,'Value')) > 0.20 % if 20% low
            set(hv2Actual,'BackgroundColor',[0.7,0.7,1.0]);
        else
            set(hv2Actual,'BackgroundColor',[0.8,0.8,0.8]);
        end
    end

% close PTool and ColorMapTool if open
delete(findobj('tag','ProcessTool'));
delete(findobj('tag','ColorMapTool'));

end
