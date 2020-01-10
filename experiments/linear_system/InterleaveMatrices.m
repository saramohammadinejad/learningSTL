function M = InterleaveMatrices(varargin)
row = size(varargin{1}, 1);
acc = zeros(length(varargin{1}(:)), nargin);
for i=1:nargin
    acc(:,i) = varargin{i}(:);
end
M = reshape(acc', nargin * row, []);
end