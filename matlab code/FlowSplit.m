%take in a stream and split it between a purge and recycle stream
function [stream8, stream9]= FlowSplit(stream7, s)

tolerance = 1e-6;
%Make sure that the the stream's componenets are all one phase
if abs(stream7(1)-stream7(8))<tolerance && abs(stream7(2)-stream7(9))<tolerance && abs(stream7(3)-stream7(10))<tolerance && abs(stream7(4)-stream7(11))<tolerance
    stream8 = s*stream7; %split part of the materials to the purge stream
    stream9 = (1-s)*stream7; %split the remaining materials to the recycle stream
%Make sure that the stream does not contain any liquid
elseif stream7(8)<tolerance && stream7(9)<tolerance && stream7(10)<tolerance && stream7(11)<tolerance
    stream8 = s*stream7; %purge stream
    stream9 = (1-s)*stream7; %recycle stream
else
   error('Error')
end
stream8(5)=stream7(5); %redefine T
stream9(5)=stream7(5); %redefine T
stream8(6)=stream7(6); %redefine P
stream9(6)=stream7(6); %redefine P
end
