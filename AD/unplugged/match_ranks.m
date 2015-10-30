function [y_shuffled, shuffle_idx] = match_ranks(x,y)
% 
% [y_shuffled, sort_idx_y] = match_ranks(x,y)
%
% Re-orders the elements in y such that they have the same rank sequence as
% the elements in vector x. 
%
% In:
%   x - a vector of length N
%   y - a vector of the same length as x
%
% Out:
%   y_shuffeled - A re-ordered version of y, which has the same rank
%                   sequence as x 
%   shuffle_idx - The shuffle indices such that y_shuffled = y(shuffle_idx)
%
%
% As an example, consider the vectors 
%   x = [0.57    0.89    0.67    0.73] and
%   y = [0.56    0.11    0.51    0.63]
% which correspond to the following rank sequences
%   x_ranks = [4 1 3 2] and y_ranks = [2 4 3 1]
% 
% This function reorders y such that y_shuffled has the same rank sequence
% as x, i.e.
%   y_shuffled = [0.11    0.63    0.51    0.56]

% 2015, sven.daehne@tu-berlin.de

[~, sort_idx] = sort(x);
[~, rank_sort_idx] = sort(sort_idx);
[y_sorted, sort_idx_y] = sort(y);
y_shuffled = y_sorted(rank_sort_idx);
shuffle_idx = sort_idx_y(rank_sort_idx);