function b = move_to_normal (n)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Anthony Morast -- Senior Research
% 
% This program finds the 1's in each row of a Latin square and moves them
% into the first col. It then find and moves the remaining symbols to their
% "normalized" positions. That is 1 in first column, 2 in second col, etc. 
%
% After the columns are in their proper order the rows are permuted into
% their proper order so that the Latin square is normalized. 
%
% Then if the Latin square is different from the square that was read in,
% the new square and the old square are written out to check if the square
% was originally symmetric. Otherwise, nothing is done, or the square is
% written to s different file to ensure all squares are one or the other. 
%
% NOTE: make script to call this function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fid = fopen('nlsO5.dat');   %file to read nls from 
count = 0;    %number of nls

b = zeros(n,n,0); %vector of arrays initialization

while (~feof(fid))  %get number of nls
    A = fscanf(fid, '%u', [n n]);
    if (isempty(A))
       break; 
    end
    b = cat(3, b, A);  %put nls into vector
    count = count + 1;
end

[h,i,p] = size(b);
if (p > 0)
    bNotEmpty = 1;
else
    bNotEmpty = 0;
end

counter = 1;
filename = 'perm_class';
%loop through each nls
while (bNotEmpty)
    A = b(:,:,1);
 
    %call function that moves the '1' in each row to the (1,1) position and
    %then returns a vactor of 4 matrices... remove from b
    c = getSquares(A);
    %initialize cNotEmpty loop condition
    [q,w,e] = size(c);
    cNotEmpty = 1;
    if (e == 0)
        cNotEmpty = 0;
    end
    used =zeros(n,n,0);
    
    while (cNotEmpty)
        A = c(:,:,1);
        c(:,:,1) = [];
        used = cat (3, used, A);
        %foreach matrix in the vector returned, store them in a master matrix
        %and recall that function on each one redoing these two steps
        d = getSquares(A);
        
        [q,w,e] = size(d);
        [r,t,y] = size(used);
        [u,o,p] = size(c);
        for i=1:e
            contains = 0;
            for j=1:y  %if not used  
                if (isequal(used(:,:,j), d(:,:,i)))
                   contains = 1; 
                   break;
                end
            end
            for j=1:p  %if not in c already
                if (isequal(c(:,:,j),d(:,:,i)))
                    contains = 1;
                    break;
                end
            end
            if ~contains
               c = cat(3,c, d(:,:,i)); 
            end
        end
        %once there are no new matrices found when that function is called exit
        %and write to a file; use next matrix in the b vector
        
        [q,w,e] = size(c);
        cNotEmpty = 1;
        if (e == 0)
            cNotEmpty = 0;
        end
    end

    %exit condition -- removes squares in c from b, this will even tually
    %make b empty
    b = exitCondition(b,used,n);

    [h,i,p] = size(b);
    if (p > 0)
        bNotEmpty = 1;
    else
        bNotEmpty = 0;
    end
    
    %get number of squares to write
    [z,x,v] = size(used);
    
    %create filename
    thisfilename = strcat(filename, int2str(counter));
    thisfilename = strcat(thisfilename,'.dat');  

    %open file
    fid3 = fopen(thisfilename, 'w');
    
    %write to file
    for f=1:v
        fprintf (fid3, '%u %u %u %u %u ',used(:,:,f));
        fprintf (fid3, '\n');
    end
    
    fclose(fid3);
    
    counter = counter + 1;
end

fclose('all');