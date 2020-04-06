function mat=repackconnmat(vec, numnodes)

% transforms the unpacked connectivity matrx back into a symmetric square

mask=logical(triu(ones(numnodes, numnodes), 1));
mat=zeros(numnodes, numnodes);
mat(mask)=vec;
mat=mat'+mat;

end