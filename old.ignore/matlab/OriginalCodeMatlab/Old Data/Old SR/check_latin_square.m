function  x  = check_latin_square( A, B )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Senior Research
%
% This function checks if the ordered pairs of two latin squares occurs
% exactly once. If every pair occurs once the function returns a 0, if any
% ordered pair occurs more than once the function will return a zero.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[n,m] = size(A);
%declare n x n matrix to store a one if the pair is used and 0 if it is not
check = zeros (n,n);

flag = 0;

for i=1:n
    for j=1:m
        a = A(i,j);
        b = B(i,j);
        if ( check(a,b) == 0 )
            check ( a, b ) = 1;
        elseif ( check (a,b) == 1 )
            flag = 1;
            break;
        end
        if flag ==1
            break;
        end
    end 
end

if flag == 1
    x = 0;
elseif flag == 0
    x = 1;
end

end
