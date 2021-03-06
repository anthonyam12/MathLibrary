function c = getSquares( A )
%GETSQUARES Summary 
%   This function finds the '1' in each row and moves the column that
%   contains it to the first column. The square is then normalized and
%   concatenated to the c vector which is returned.

[m,n] = size(A);
c = zeros(m,n,0);

for i=2:m
    for j=1:n
    if (A(i,j) == 1)
        swap = j;
        break;
    end
    end
    %swap column with '1' to first column
    D = A;
    temp = D(:,1);
    D(:,1) = D(:,swap);
    D(:,swap) = temp;
    
    %swap current row to row one
    temp = D(1,:);
    D(1,:) = D(i,:);
    D(i,:) = temp;
    D = normalize_ls_6(D);

    %add the square to c if not in c
    [h,j,k] = size(c);
    contains = 0;
    for j=1:k
        if isequal(D,c(:,:,j))
            contains = 1;
        end
    end

    if contains == 0
        c = cat(3,D,c);
    end
end

end

