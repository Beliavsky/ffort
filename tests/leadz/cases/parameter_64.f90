program p
implicit none
integer,parameter::n=leadz(1_8)
integer,parameter::a(3)=leadz([0_8,1_8,-1_8])
integer::x(n)
x=2
print *,n,a,kind(n),size(x)
end program
