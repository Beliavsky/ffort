program main
implicit none
integer::a(3)=[1,2,3],i
do i=1,3
print *,pack(a,a>i)
end do
end program
