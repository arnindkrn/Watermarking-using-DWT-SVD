function key = check_arnold(m)
x = 1;
y = 1;
k = 1;
a = x;
x = x + y;
y = a + 2*y;
while x~=1 && y~=1
    k = k+1;
    if x > m
        x = mod(x,m);
    end
    if y > m
        y = mod(y,m);
    end
    a = x;
    x = x + y;
    y = a + 2*y;
end
key = 30;
