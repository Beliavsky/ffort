program p
implicit none
real,save :: a(-1:0)=1.5
a=a+0.5
print *, all(a==2.0)
end program
