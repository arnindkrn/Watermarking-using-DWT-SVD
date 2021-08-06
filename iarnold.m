function dw = iarnold(wm,m,key)

dw = wm;
p = 8; q = 10;
I = [1 p; q p*q+1];

for k = 1:key
    for x = 1:m
        for y = 1:m
            result = mod(I*[x; y], m);
            dw(result(1) + 1, result(2) + 1) = wm(x,y);
        end;
    end;
    wm = dw;
end;
