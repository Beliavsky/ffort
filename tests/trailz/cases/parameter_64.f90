program p
implicit none
integer(8),parameter::a=96_8
integer,parameter::n=trailz(a)
integer::b(n)
b=n
print *,n,size(b),kind(n)
end program p
