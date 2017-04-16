function lines = findLines(GrayImg)

%Use imtool to determine the required threshold to identify the laser.
%mouse over the laser light, the red component is generally >150.
%imtool(imdata);

%threshold only the red layer to get a black/white image
imdata=im2bw(GrayImg,0.01);
figure;imshow(imdata);

%'Skeletonize' the image.
imdata=bwmorph(imdata,'skel', inf);
figure;imshow(imdata);

%help hough
[H,T,R] = hough(imdata);
%Given image has about 4 lines of interest
P = houghpeaks(H,4,'Threshold',.3*max(H(:)));
% Find the actual lines
lines = houghlines(imdata,T,R,P,'FillGap',50,'MinLength',50);
lines.theta;

%% display
figure, imshow(imdata), hold on
max_len = 0;
xy_long = [];
for k = 1:length(lines)
    xy = [lines(k).point1; lines(k).point2];
    plot(xy(:,1),xy(:,2),'LineWidth',2,'Color','green');

    % Plot beginnings and ends of lines
    plot(xy(1,1),xy(1,2),'x','LineWidth',2,'Color','yellow');
    plot(xy(2,1),xy(2,2),'x','LineWidth',2,'Color','red');

    % Determine the endpoints of the longest line segment
    len = norm(lines(k).point1 - lines(k).point2);
    if ( len > max_len)
       max_len = len;
       xy_long = xy;
    end
end

% highlight the longest line segment
plot(xy_long(:,1),xy_long(:,2),'LineWidth',2,'Color','blue');

end