function dw = iarnold(wm,m,key)
dw = wm;
for k = 1:key
    for i = 1:m
        for j = 1:m
            x =2*i - j;
            y = j - i;
            if(x > m)
                x = mod(x,m);
            end;
            if(y > m)
                y = mod(y,m);
            end;
            if(x <= 0)
                x = m + x;
            end;
            if(y <= 0)
                y = m + y;
            end;
            dw(x,y) = wm(i,j);
        end;
    end;
    wm = dw;
end;
