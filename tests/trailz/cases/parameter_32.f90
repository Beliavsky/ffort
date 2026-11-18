program p
implicit none
integer(4),parameter::a=96_4
integer,parameter::n=trailz(a)
integer::b(n)
b=n
print *,n,size(b),kind(n)
end program p
