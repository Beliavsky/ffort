program p
implicit none
integer,parameter::n=leadz(1_4)
integer,parameter::a(3)=leadz([0_4,1_4,-1_4])
integer::x(n)
x=2
print *,n,a,kind(n),size(x)
end program
