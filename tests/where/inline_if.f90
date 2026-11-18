program p
implicit none
integer::a(3)=[1,2,3]
if(.true.) where(a>1) a=a*2
print *,a
end program
