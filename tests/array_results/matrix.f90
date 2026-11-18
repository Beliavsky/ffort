program p
implicit none
integer::a(2,3)
a=grid(2,3,0)
print *,a,sum(a,1),sum(grid(2,3,1),2)
print *,size(grid(0,3,1)),size(grid(0,3,1),2),lbound(grid(2,3,1),2),ubound(grid(2,3,1),2)
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
