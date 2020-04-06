function resampleconnmat(mat, sections)

% takes in a simmetric connectivity matrix and calculates average connectivity within and across the blocks returning a
% new smaller connectivity matrix

for section_row=1:max(sections)
       
    k_row=find(sections==section_row);

    for section_col=1:max(sections)
    
    k_col=find(sections==section_col);
    
    % If section to itself, calculate average
    % connectivity within section only in the upper triangle
    if section_row==section_col
        temp=mat(k_row, k_col);
        trionly=unpackconnmat(temp);
        newmat(section_row, section_col)=mean(trionly);   
    else
        newmat(section_row, section_col)=mean(mean(mat(k_row, k_col)));   
    end
    
    end
        
end


end