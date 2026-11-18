program p
implicit none

print *,total(seq(3,0)+seq(3,10)),sum(seq(4,0)**2)
print *,sum(grid(2,2,0)*grid(2,2,1))
contains
pure function seq(n,b) result(y)
integer,intent(in)::n,b
integer::y(-1:n-2),j
do j=1,n
y(j-2)=b+j
end do
end function
pure function grid(n,m,b) result(y)
integer,intent(in)::n,m,b
integer::y(-1:n-2,3:m+2),i,j
do j=1,m
do i=1,n
y(i-2,j+2)=b+i+10*j
end do
end do
end function
pure integer function total(x)
integer,intent(in)::x(:)
total=sum(x)
end function
end program
