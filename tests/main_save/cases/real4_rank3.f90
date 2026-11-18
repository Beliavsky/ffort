program p
implicit none
real,save :: a(-1:0,2:3,-2:-1)=1.5
a=a+0.5
print *, a==2.0
end program
