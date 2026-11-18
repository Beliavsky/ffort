program p
implicit none
integer::a(2)
a=seq(3,0)
print *,a
contains
pure function seq(n,b) result(y)
integer,intent(in)::n,b
integer::y(-1:n-2),j
do j=1,n
y(j-2)=b+j
end do
end function
end program
