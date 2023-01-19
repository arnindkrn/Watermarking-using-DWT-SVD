function wm = arnold(w,m,key)
wm = w;
for k = 1:key
    for x = 1:m
        for y = 1:m
             x1 = x + y;
             y1 = x + 2*y;
             if x1 > m
                 x1 = mod(x1,m);
             end
             if y1 > m
                 y1 = mod(y1,m);
             end
             if x1 == 0
                 x1 = m;
             end
             if y1 == 0
                 y1 = m;
             end
             wm(x1,y1)= w(x,y);
        end
    end
     w = wm;
end;
