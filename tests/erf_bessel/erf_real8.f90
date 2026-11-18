program p
implicit none
real(8)::x
integer(8)::n

n=5
x=0.17_8
print *,erf(x),erf(x=x),kind(erf(x))
end program
