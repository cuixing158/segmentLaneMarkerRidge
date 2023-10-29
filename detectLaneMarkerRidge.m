function birdsEyeBW = detectLaneMarkerRidge(bevImage,approxLaneWidthPixels,mask,sensitivity)
% Brief: find lane marker ridge binary image from birds eye view image `bevImage`
% based on approximating lane pixel width `approxLaneWidthPixels`.
% Details:
%    The principle of this function is adapted from the built-in function 
% `segmentLaneMarkerRidge` to facilitate the detection of lane line features 
% directly in the birds eye image without the need to configure camera 
% extrinsic parameters(Camera mounting height and angle of the three axes 
% of the vehicle's coordinate system).
% 
% Syntax:  
%     birdsEyeBW = detectLaneMarkerRidge(bevImage,approxLaneWidthPixels)
% 
% Inputs:
% bevImage - [m,n] size,[uint8,single,double] type,bird eye view image
%
% approxLaneWidthPixels - [1,1] size,[double] type,approximation lane
% pixels width in birds eye view image.
%
% mask - [m,n] size,[logical,uint8] type,(optional)Input image region of interest, 
% non-zero region indicates the region to be detected and 0 indicates 
% the region not to be considered for detection.
%
% sensitivity - [1,1] size,[double] type,(optional)Sensitivity factor, specified 
% as the comma-separated pair consisting of 'Sensitivity' and a real scalar
% in the range [0, 1]. You can increase this value to detect more lane-like 
% features. However, the higher sensitivity can increase the risk of false
% detections.
% 
% Outputs:
%    birdsEyeBW - same size and type as input bevImage,Bird’s-eye-view 
% image, returned as a binary image that represents lane features.
% 
% Example: 
%   bevImage = imread("birdsEyeImage.png");
%   
%   pixelWidthInBEVImage = 5;% Approximate pixel width of the lane in the bevImage image
%   birdsEyeBW = detectLaneMarkerRidge(bevImage,pixelWidthInBEVImage);
%   imshow(birdsEyeBW)
%
% 
% See also: segmentLaneMarkerRidge

% Author:                          cuixingxing
% Email:                           cuixingxing150@gmail.com
% Created:                         24-Aug-2023 19:27:06
% Version history revision notes:
%                                  None
% Implementation In Matlab R2023a
% Copyright © 2023 TheMatrix.All Rights Reserved.
%#codegen

arguments
    bevImage;
    approxLaneWidthPixels (1,1) double 
    mask = ones(size(bevImage,[1,2]),'uint8')% used to detect mask
    sensitivity (1,1) double =0.25 % same as segmentLaneMarkerRidge Sensitivity para
end

bevImage = im2gray(bevImage);
L = emphasizeLaneFeatures(bevImage, approxLaneWidthPixels);

% Convert sensitivity to threshold and map it to [0.9 1.0] range
thresh = 1-double(sensitivity);
T = mapThresholdToNewRange(thresh);
BW = thresholdLaneFeatureImage(L, mask, T);
birdsEyeBW = cleanupBinaryMask(BW);

end

%--------------------------------------------------------------------------
function L = emphasizeLaneFeatures(I, tau)

Ipad = padarray(I, [0 double(tau)+1], 'replicate');

Ileft  = single(Ipad(:,1:end-2*(tau+1)));
Iright = single(Ipad(:,1+2*(tau+1):end));

L = 2*single(I) - (Ileft+Iright) - (abs(Ileft - Iright));

L = imnormalize(L);

end

%--------------------------------------------------------------------------
function im = imnormalize(im)

small = min(im(:));
big   = max(im(:));
if abs(big-small) < 10*eps
    im = zeros(size(im),'like',im);
else
    im = (im-small) ./ (big-small);
end
end

%--------------------------------------------------------------------------
function BW = thresholdLaneFeatureImage(L, mask, T)

counts = histcounts(L, 0:1/256:1);
cdf = cumsum(counts);

cutoff = T * numel(L);

thresh = find(cdf>=cutoff,1) / numel(counts);

if(isempty(coder.target))
    BW = L > thresh;
else
    BW = L > repmat(thresh, size(L));
end

BW = BW & mask;

end

%--------------------------------------------------------------------------
function BW = cleanupBinaryMask(BW)

numPix = round( (1e-4) * numel(BW) );
numPix = max(numPix,30);

BW = bwareaopen(BW, numPix);
end

%--------------------------------------------------------------------------
function T = mapThresholdToNewRange(ThresholdIn)
% Map the input threshold range [0 1] to [0.9 1]

T = ThresholdIn/10 + 0.9;

end