program main
implicit none
integer::a(4)=[1,2,3,4]
print *,reshape(source=pack(a,a>2),order=[2,1],shape=[2,2],pad=[8,9])
end program
