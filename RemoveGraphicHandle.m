function Data = RemoveGraphicHandle(Data)
% Data = RemoveGraphicHandle(Data)
% Remove new graphics objects in a structure and/or cell
%
% Goal: Remove new graphic objects presented in Data, otherwise it crashs
% when loading the Data under earlier versions of MATLAB
% Note: Only use this function if NewGraphicsSystem() returns TRUE

% if ~NewGraphicsSystem()
%     return
% end

verbose = false;

if isstruct(Data)
    fn = fieldnames(Data);
    for i = 1:numel(Data)
        for k = 1:length(fn)
            x = Data(i).(fn{k});
            if isstruct(x) || iscell(x) || IsNewGraphicHandle(x) || isa(x,'function_handle')
                Data(i).(fn{k}) = RemoveGraphicHandle(x);
            end
        end
    end
elseif iscell(Data)
    for k = 1:length(Data)
        x = Data{k};
        if isstruct(x) || iscell(x) || IsNewGraphicHandle(x) || isa(x,'function_handle')
            Data{k} = RemoveGraphicHandle(x);
        end
    end
elseif isa(Data,'function_handle') && ...
       strcmp(getfield(functions(Data),'type'),'anonymous')
        Data = func2str(Data);
elseif IsNewGraphicHandle(Data)
    if verbose
        fprintf('Remove ');
        disp(Data)
    end
    % Replace with empty
    Data = [];
end

end % RemoveGraphicHandle