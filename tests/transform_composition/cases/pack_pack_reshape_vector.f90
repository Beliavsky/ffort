program main
implicit none
integer::a(3)=[1,2,3]
print *,pack(a,a>1,reshape([7,8,9,10],[4]))
end program
