program main
implicit none
integer,parameter::a(2)=pack(reshape([1,2,3,4],[2,2]),reshape([1,2,3,4],[2,2])>2)
print *,a
end program
