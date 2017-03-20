function tf = IsNewGraphicHandle(h)
% Return TRUE if an object h is New Graphics Object
tf = strncmp(class(h),'matlab.ui',9) || ...
     strncmp(class(h),'matlab.graphics',15);
end 
