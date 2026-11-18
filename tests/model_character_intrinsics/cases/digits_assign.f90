program p
implicit none
integer::a(5)
a=digits(0d0)
if(any(a/=53))error stop 1
print *,a
end program
