program p
implicit none
integer::a(2)
a=grid(1,2,0)
contains
pure function grid(n,m,b) result(y)
integer,intent(in)::n,m,b
integer::y(-1:n-2,3:m+2),i,j
do j=1,m
do i=1,n
y(i-2,j+2)=b+i+10*j
end do
end do
end function
end program
