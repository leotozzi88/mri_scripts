function vec=unpackconnmat(M)

% transforms the upper triangle of a matrix into a vector

mask=logical(triu(ones(size(M)), 1));
vec=M(mask);


end